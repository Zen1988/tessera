import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location('navis_workflow', ROOT / 'examples/navis/navis_workflow.py')
N = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(N)


def fixture():
    build = '20000000-0000-4000-8000-000000000001'
    session = '40000000-0000-4000-8000-000000000001'
    flow = dict(source='192.0.2.10', destination='198.51.100.5', protocol='tcp', destination_port=443, action='allow')
    trace = dict(code='TRACE_RESULT_READY', graph_build_id=build, trace_session_id=session,
                 results=[dict(source=flow['source'], destination=flow['destination'], protocol='tcp', destination_port=443,
                               status='blocked', connection_verdict=dict(status='unknown', missing=['return_path']))])
    rows, snapshot, nodes = [], [], []
    contexts = [dict(vsys='vsys1', source_zone='trust', destination_zone='dmz'),
                dict(tenant='tenant-a', source_epg='app', destination_epg='db', contract='web'),
                dict(domain='default', source_group='/infra/domains/default/groups/app',
                     destination_group='/infra/domains/default/groups/db', applied_to='/infra/domains/default/groups/db', policy='tessera')]
    for i, platform in enumerate(('panos', 'aci', 'nsx'), 1):
        device = f'30000000-0000-4000-8000-{i:012}'
        draft = dict(device_id=device, source=flow['source'], destination=flow['destination'], protocol='tcp',
                     destination_port=443, action='allow', status='draft', source_zone='trust', destination_zone='dmz',
                     source_zone_status='resolved', destination_zone_status='resolved', ingress_interface='in',
                     egress_interface='out', reason='synthetic candidate denial')
        rows.append(dict(status='ready', result=draft))
        ci = '000012313213' if i == 1 else str(12312312320 + i)
        nodes.append(dict(id=device, type='device', external_identity=dict(status='mapped', namespace='CMDB', object_class='NetworkNode', id=ci)))
        snapshot.append(dict(namespace='CMDB', ConfigItemID=ci, Class='NetworkNode',
                             platform=platform, context=contexts[i-1]))
    return dict(execution_uid='a' * 40, mode='fixture', graph_build_id=build, identity_namespace='CMDB', flow=flow, cmdb_snapshot=snapshot,
                fixture=dict(graph=dict(build_id=build, status='completed', nodes=nodes, connections=[], projection_status='device_identity_only'), trace=trace, recommendations=dict(code='RECOMMENDATIONS_AVAILABLE', trace_session_id=session,
                                                               recommendations=rows)))


class WorkflowTest(unittest.TestCase):
    def test_all_vendors_and_uncertainty_preserved(self):
        result = N.run(fixture())
        self.assertEqual(result['Summary'][0]['status'], 'unknown')
        self.assertFalse(result['ApplyReady'])
        self.assertEqual(len(result['Plans']), 3)
        for plan in result['Plans']:
            self.assertEqual(plan['Target']['Application'], 'tessera')
            self.assertEqual(N.simulate(plan)['Status'], 'SIMULATED')
            self.assertFalse(N.simulate(plan)['Changed'])

    def test_input_immutable(self):
        data = fixture()
        before = copy.deepcopy(data)
        N.run(data)
        self.assertEqual(before, data)

    def test_literal_ips_ipv6_strict_ports(self):
        data = fixture()
        flow = dict(data['flow'], source='2001:db8::1;2001:db8::1', destination='2001:db8::2')
        request = N.trace_request(flow, data['graph_build_id'], 'safe')
        self.assertEqual(request['source'], '2001:db8::1')
        self.assertNotIn('action', request)
        for change in ({'source': '192.0.2.0/24'}, {'destination': 'host.local'}, {'source': '192.0.2.1;'},
                       {'destination_port': True}, {'source_port': '443'}, {'protocol': 'any'}, {'protocol': 'icmp'},
                       {'URL': 'https://unexpected'}, {'action': 'permit'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                N.trace_request(dict(data['flow'], **change), data['graph_build_id'], 'safe')

    def test_ambiguous_mapping_and_wrong_class(self):
        for key, value in [('Class', 'Computer'), ('navis_device_id', 'legacy-manual'), ('ConfigItemID', 123), ('namespace', 'cmdb')]:
            data = fixture()
            data['cmdb_snapshot'][0][key] = value
            with self.assertRaises(ValueError):
                N.run(data)
        data = fixture()
        data['cmdb_snapshot'].append(copy.deepcopy(data['cmdb_snapshot'][0]))
        with self.assertRaises(ValueError):
            N.run(data)

    def test_missing_mapping_never_infers_device(self):
        data = fixture()
        data['cmdb_snapshot'] = []
        self.assertEqual(N.run(data)['Plans'], [])

    def test_session_build_and_flow_mismatch(self):
        for branch, key, value in [('trace', 'graph_build_id', 'wrong'), ('recommendations', 'trace_session_id', 'wrong')]:
            data = fixture()
            data['fixture'][branch][key] = value
            with self.assertRaises(ValueError):
                N.run(data)
        data = fixture()
        data['fixture']['trace']['results'][0]['destination'] = '192.0.2.2'
        with self.assertRaises(ValueError):
            N.run(data)

    def test_unavailable_pending_incomplete_deny(self):
        for code in ('RECOMMENDATION_PENDING', 'RECOMMENDATIONS_UNAVAILABLE'):
            data = fixture()
            data['fixture']['recommendations']['code'] = code
            self.assertEqual(N.run(data)['Status'], code)
            self.assertEqual(N.run(data)['Plans'], [])
        for change in ('incomplete', 'deny'):
            data = fixture()
            if change == 'incomplete':
                for row in data['fixture']['recommendations']['recommendations']:
                    row['result']['status'] = 'incomplete'
            else:
                data['flow']['action'] = 'deny'
            self.assertEqual(N.run(data)['Plans'], [])

    def test_enrichment_and_unresolved_zone(self):
        plans = N.run(fixture())['Plans']
        for plan in plans:
            plan['Context'] = {}
            self.assertEqual(N.simulate(plan)['Status'], 'ENRICHMENT_REQUIRED')
        plan = N.run(fixture())['Plans'][0]
        plan['Draft']['source_zone_status'] = 'ambiguous'
        self.assertEqual(N.simulate(plan)['Status'], 'ENRICHMENT_REQUIRED')

    def test_live_call_contract_once_no_id_rewrite(self):
        data = fixture()
        data['mode'] = 'navis'
        trace, recs = copy.deepcopy(data['fixture']['trace']), copy.deepcopy(data['fixture']['recommendations'])
        trace['caller_session_id'] = recs['caller_session_id'] = 'tessera-' + data['execution_uid']
        client = Mock()
        client.call.side_effect = [data['fixture']['graph'], trace, recs]
        result = N.run(data, client)
        self.assertEqual(result['Mode'], 'navis')
        self.assertEqual([c.args[0] for c in client.call.call_args_list], ['GET', 'POST', 'GET'])
        self.assertIn('/v1/graph-builds/', client.call.call_args_list[0].args[1])
        client.call.reset_mock()
        client.call.side_effect = TimeoutError('sensitive')
        with self.assertRaises(TimeoutError):
            N.run(data, client)
        self.assertEqual(client.call.call_count, 1)
        client.call.reset_mock()
        trace['caller_session_id'] = 'wrong'
        client.call.side_effect = [data['fixture']['graph'], trace, recs]
        with self.assertRaises(ValueError):
            N.run(data, client)

    def test_origin_restrictions(self):
        for url in ('http://host', 'https://user:pass@host', 'https://host/path', 'https://host?query=1'):
            with self.assertRaises(ValueError):
                N.Client(url, 'token')

    def test_get_only_pending_retrieval_uses_original_caller(self):
        data = fixture()
        old = data['execution_uid']
        data['mode'] = 'recommendations'
        data['trace_execution_uid'] = old
        data['execution_uid'] = 'b' * 40
        data['saved_trace'] = dict(data['fixture']['trace'], caller_session_id='tessera-' + old)
        recs = dict(data['fixture']['recommendations'], caller_session_id='tessera-' + old)
        client = Mock()
        client.call.side_effect = [data['fixture']['graph'], recs]
        result = N.run(data, client)
        self.assertEqual(result['CallerSessionID'], 'tessera-' + old)
        self.assertEqual(client.call.call_count, 2)
        self.assertTrue(all(c.args[0] == 'GET' for c in client.call.call_args_list))

    def test_graph_identity_is_authoritative_and_opaque(self):
        data = fixture()
        self.assertEqual(N.run(data)['Plans'][0]['Target']['ConfigItemID'], '000012313213')
        for value in ('ID:With/Punctuation', 'id:with/punctuation', '0000'):
            data['fixture']['graph']['nodes'][0]['external_identity']['id'] = value
            data['cmdb_snapshot'][0]['ConfigItemID'] = value
            self.assertEqual(N.run(data)['Plans'][0]['Target']['ConfigItemID'], value)
        data['cmdb_snapshot'][0]['ConfigItemID'] = 'different-id'
        self.assertEqual(len(N.run(data)['Plans']), 2)

    def test_missing_ambiguous_wrong_scope_graph_identity_blocks_target(self):
        for change in ({'status': 'missing'}, {'status': 'ambiguous'}, {'namespace': 'OTHER'},
                       {'object_class': 'device'}, {'namespace': 'cmdb'}):
            data = fixture()
            data['fixture']['graph']['nodes'][0]['external_identity'].update(change)
            self.assertEqual(len(N.run(data)['Plans']), 2)
        data = fixture()
        data['fixture']['graph']['nodes'] = []
        self.assertEqual(N.run(data)['Plans'], [])

    def test_graph_structure_build_and_duplicate_identity(self):
        for field, value in [('build_id', 'wrong'), ('status', 'pending')]:
            data = fixture()
            data['fixture']['graph'][field] = value
            with self.assertRaises(ValueError):
                N.run(data)
        for duplicate in ('node', 'identity'):
            data = fixture()
            nodes = data['fixture']['graph']['nodes']
            if duplicate == 'node':
                nodes.append(copy.deepcopy(nodes[0]))
            else:
                nodes[1]['external_identity'] = copy.deepcopy(nodes[0]['external_identity'])
            with self.assertRaises(ValueError):
                N.run(data)

    def test_graph_failure_prevents_trace_post(self):
        data = fixture()
        data['mode'] = 'navis'
        client = Mock()
        client.call.return_value = dict(data['fixture']['graph'], status='pending')
        with self.assertRaises(ValueError):
            N.run(data, client)
        self.assertEqual(client.call.call_count, 1)
        self.assertEqual(client.call.call_args.args[0], 'GET')

    def test_cli_simulation_and_sanitized_failure(self):
        run = subprocess.run([sys.executable, str(SPEC.origin)], input=json.dumps(fixture()), text=True, capture_output=True)
        self.assertEqual(run.returncode, 0, run.stderr)
        self.assertEqual(len(json.loads(run.stdout)['Plans']), 3)
        data = fixture()
        data['flow']['source'] = 'secret-invalid-host'
        run = subprocess.run([sys.executable, str(SPEC.origin)], input=json.dumps(data), text=True, capture_output=True)
        self.assertEqual(run.returncode, 1)
        self.assertNotIn('secret-invalid-host', run.stdout + run.stderr)
        self.assertEqual(json.loads(run.stdout)['Status'], 'FAILED_OR_UNCERTAIN')


if __name__ == '__main__':
    unittest.main()
