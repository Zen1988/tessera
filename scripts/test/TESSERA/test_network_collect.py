"""Offline contract fixtures; these are not live vendor acceptance tests."""
import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).resolve().parents[3] / 'examples/network/library/tessera_network_collect.py'
spec = importlib.util.spec_from_file_location('collector', path)
c = importlib.util.module_from_spec(spec)
spec.loader.exec_module(c)


class Fake:
    username = 'fixture'; password = 'fixture'; token = 'fixture'
    def __init__(self, fn): self.fn = fn; self.calls = []
    def request(self, path, body=None, headers=None, xml=False):
        self.calls.append((path, body))
        return self.fn(path, body)


class Collection(unittest.TestCase):
    def test_longest_route_and_ecmp(self):
        routes = [{'prefix': '0.0.0.0/0', 'interface': 'wan'}, {'prefix': '10.0.0.0/8', 'interface': 'lan'}]
        self.assertEqual(c.route_interface('10.1.2.3', routes), 'lan')
        routes.append({'prefix': '10.0.0.0/8', 'interface': 'other'})
        with self.assertRaises(ValueError): c.route_interface('10.1.2.3', routes)

    def test_asa(self):
        raw = {'interfaces': 'interface a\n nameif inside\n!\ninterface b\n nameif outside\n!',
               'routes': 'C 10.1.0.0 255.255.255.0 is directly connected, inside\nC 10.2.0.0 255.255.255.0 is directly connected, outside',
               'access_groups': 'access-group ACCESS in interface inside', 'nat': '', 'access_lists': ''}
        _, result = c.asa(raw, '10.1.0.10', '10.2.0.10')
        self.assertEqual(result['SourceZone'], 'inside')
        self.assertEqual(result['DestinationZone'], 'outside')

    def test_panos(self):
        from urllib.parse import parse_qs, urlsplit
        def reply(path, body):
            q = parse_qs(urlsplit(path).query)
            if q['type'] == ['op']:
                return '<response status="success"><result><entry><destination>0.0.0.0/0</destination><interface>ethernet1/1</interface></entry></result></response>'
            content = '<entry name="device-zone"><network><layer3><member>ethernet1/1</member></layer3></network></entry>' if q['xpath'][0].endswith('/zone') else ''
            return '<response status="success"><result>' + content + '</result></response>'
        _, result = c.panos(Fake(reply), 'vsys1', {'virtual_router': 'default'}, '10.1.0.1', '10.2.0.1')
        self.assertEqual(result['SourceZone'], 'device-zone')
        with self.assertRaises(ValueError): c.xml_result('<!DOCTYPE foo><response/>')

    def test_fortios(self):
        def reply(path, body):
            rows = []
            if '/router/ipv4?' in path: rows = [{'ip_mask': '0.0.0.0/0', 'interface': 'port1'}]
            if '/system/interface?' in path: rows = [{'name': 'port1', 'vdom': 'root'}]
            if '/system/zone?' in path: rows = [{'name': 'trusted', 'interface': [{'interface-name': 'port1'}]}]
            return {'status': 'success', 'results': rows}
        _, result = c.fortios(Fake(reply), 'root', {}, '10.1.0.1', '10.2.0.1')
        self.assertEqual(result['DestinationZone'], 'trusted')

    def test_checkpoint(self):
        def reply(path, body):
            if path.endswith('/login'): return {'sid': 'fixture'}
            if path.endswith('/show-object'): return {'object': {'interfaces': [{'name': 'eth1'}]}}
            return {'rulebase': [], 'total': 0, 'to': 0}
        client = Fake(reply)
        _, result = c.checkpoint(client, 'domain', {'gateway_uid': 'gateway', 'access_layer': 'layer', 'policy_package': 'package'}, '10.1.0.1', '10.2.0.1')
        self.assertEqual(result['GatewayUID'], 'gateway')
        self.assertEqual(client.calls[-1][0], '/web_api/logout')

    def test_nsx(self):
        def reply(path, body):
            if '/members/ip-addresses?' in path: return {'results': ['10.0.0.0/8']}
            if '/groups?' in path: return {'results': [{'id': 'group', 'path': '/infra/domains/default/groups/group'}]}
            if '/security-policies?' in path: return {'results': [{'id': 'policy', 'path': '/infra/domains/default/security-policies/policy'}]}
            return {'results': []}
        _, result = c.nsx(Fake(reply), 'default', {}, '10.1.0.1', '10.2.0.1')
        self.assertEqual(result['Enforcement'], 'DistributedFirewall')
        self.assertEqual(len(result['SourceGroups']), 1)
        self.assertNotIn('SourceZone', result)

    def test_invalid_destination_and_context(self):
        for host in ['https://host', 'host/path', 'user:pass@host']:
            with self.assertRaises(ValueError): c.Client(host)
        with self.assertRaises(ValueError): c.identifier('../other')


if __name__ == '__main__': unittest.main()
