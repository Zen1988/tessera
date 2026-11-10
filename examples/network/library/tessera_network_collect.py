#!/usr/bin/python
"""Read-only multi-vendor evidence collector, executed inside AWX.

Credentials are Ansible no_log arguments supplied by inventory/AWX credentials.
No device/manager URL, credential or command is obtained from the request ticket.
"""
import base64
import hashlib
import ipaddress
import json
import re
import ssl
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise ValueError('Manager redirect refused')


class Client:
    def __init__(self, host, username='', password='', token='', ca_file=None):
        if not re.fullmatch(r'[A-Za-z0-9.-]+(?::[0-9]{1,5})?', host or ''):
            raise ValueError('Inventory manager must be a hostname with optional port')
        self.base = 'https://' + host
        self.headers = {'Accept': 'application/json'}
        self.username, self.password, self.token = username, password, token
        self.opener = urllib.request.build_opener(NoRedirect(), urllib.request.HTTPSHandler(context=ssl.create_default_context(cafile=ca_file)))
        self.calls = 0

    def request(self, path, body=None, headers=None, xml=False):
        self.calls += 1
        if self.calls > 128 or not path.startswith('/') or path.startswith('//'):
            raise ValueError('Collection request budget exceeded')
        h = dict(self.headers, **(headers or {}))
        payload = None
        if body is not None:
            payload = json.dumps(body).encode()
            h['Content-Type'] = 'application/json'
        req = urllib.request.Request(self.base + path, data=payload, headers=h)
        with self.opener.open(req, timeout=30) as response:
            raw = response.read(4194305)
        if len(raw) > 4194304:
            raise ValueError('Manager response exceeds 4 MiB')
        return raw.decode() if xml else json.loads(raw)


def identifier(value):
    if not isinstance(value, str) or not re.fullmatch(r'[A-Za-z0-9_.-]{1,100}', value):
        raise ValueError('Invalid inventory context identifier')
    return value


def route_interface(address, routes):
    ip = ipaddress.ip_address(address)
    hits = []
    for r in routes:
        network = ipaddress.ip_network(r['prefix'], strict=False)
        if ip in network:
            hits.append((network.prefixlen, r['interface']))
    if not hits:
        raise ValueError('No route for endpoint')
    longest = max(p for p, _ in hits)
    interfaces = {i for p, i in hits if p == longest and i}
    if len(interfaces) != 1:
        raise ValueError('Ambiguous multipath or unresolved route interface')
    return interfaces.pop()


def zone_findings(source, destination, routes, zones):
    result = {'Unresolved': [], 'RouteBasis': 'Longest-prefix route evidence; ingress requires topology confirmation'}
    for label, ip in [('Source', source), ('Destination', destination)]:
        try:
            interface = route_interface(ip, routes)
            matches = sorted(set(zones.get(interface, [])))
            if len(matches) != 1:
                raise ValueError('Interface has missing or ambiguous zone mapping')
            result[label + 'Interface'] = interface
            result[label + 'Zone'] = matches[0]
        except (ValueError, KeyError, TypeError) as exc:
            result['Unresolved'].append(label + ': ' + str(exc))
    return result


def xml_result(text):
    if '<!DOCTYPE' in text.upper() or '<!ENTITY' in text.upper():
        raise ValueError('XML document declarations refused')
    root = ET.fromstring(text)
    if root.get('status') != 'success':
        raise ValueError('PAN-OS returned unsuccessful response')
    result = root.find('result')
    if result is None:
        raise ValueError('PAN-OS result missing')
    return result


def panos(client, context, options, source, destination):
    vr = identifier(options['virtual_router'])
    def call(params):
        return client.request('/api/?' + urllib.parse.urlencode(params), headers={'X-PAN-KEY': client.token}, xml=True)
    route = call({'type': 'op', 'cmd': '<show><routing><route><virtual-router>' + vr + '</virtual-router></route></routing></show>'})
    base = "/config/devices/entry/vsys/entry[@name='" + context + "']"
    raw = {'routes': route}
    for name, suffix in [('zones', '/zone'), ('security', '/rulebase/security'), ('nat', '/rulebase/nat'), ('pbf', '/rulebase/pbf')]:
        raw[name] = call({'type': 'config', 'action': 'show', 'xpath': base + suffix})
    routes = []
    for e in xml_result(route).findall('.//entry'):
        prefix, interface = e.findtext('destination'), e.findtext('interface')
        if prefix and interface:
            routes.append({'prefix': prefix, 'interface': interface})
    zones = {}
    for e in xml_result(raw['zones']).findall('.//entry'):
        for m in e.findall('./network/layer3/member'):
            zones.setdefault(m.text, []).append(e.get('name'))
    finding = zone_findings(source, destination, routes, zones)
    finding['SecurityRuleCount'] = len(xml_result(raw['security']).findall('.//rules/entry'))
    if xml_result(raw['nat']).findall('.//rules/entry'):
        finding['Unresolved'].append('NAT rules present: translated flow must be evaluated before applying a proposal')
    if xml_result(raw['pbf']).findall('.//rules/entry'):
        finding['Unresolved'].append('Policy-based forwarding requires flow-specific route evaluation')
    finding['PolicyReview'] = 'Local vsys policy collected; inherited Panorama rules and App-ID must be checked before apply'
    return raw, finding


def fortios(client, context, options, source, destination):
    header = {'Authorization': 'Bearer ' + client.token}
    def get(path, fields=None):
        query = {'vdom': context}
        if fields:
            query['format'] = fields
        data = client.request(path + '?' + urllib.parse.urlencode(query), headers=header)
        if data.get('status') not in (None, 'success') or data.get('limit_reached'):
            raise ValueError('FortiOS response failed or was truncated')
        if 'results' not in data:
            raise ValueError('FortiOS results missing')
        return data
    raw = {
        'routes': get('/api/v2/monitor/router/ipv4'),
        'zones': get('/api/v2/cmdb/system/zone', 'name|interface'),
        'interfaces': get('/api/v2/cmdb/system/interface', 'name|vdom|ip'),
        'policies': get('/api/v2/cmdb/firewall/policy', 'policyid|name|srcintf|dstintf|srcaddr|dstaddr|service|action|status|nat'),
        'vip': get('/api/v2/cmdb/firewall/vip', 'name|extip|mappedip|extintf'),
        'policy_routes': get('/api/v2/cmdb/router/policy', 'seq-num|input-device|output-device|src|dst'),
    }
    routes = [{'prefix': r['ip_mask'], 'interface': r['interface']} for r in raw['routes']['results'] if 'ip_mask' in r and 'interface' in r]
    zones = {i['name']: [i['name']] for i in raw['interfaces']['results'] if i.get('vdom', context) == context}
    for z in raw['zones']['results']:
        for member in z.get('interface', []):
            zones[member['interface-name']] = [z['name']]
    finding = zone_findings(source, destination, routes, zones)
    finding['SecurityRuleCount'] = len(raw['policies']['results'])
    if raw['vip']['results'] or any(p.get('nat') == 'enable' for p in raw['policies']['results']):
        finding['Unresolved'].append('NAT/VIP present: evaluate translated flow before apply')
    if raw['policy_routes']['results']:
        finding['Unresolved'].append('Policy routes present: flow-specific lookup required')
    finding['PolicyReview'] = 'Address/service groups, SD-WAN and policy order require validation before apply'
    return raw, finding


def checkpoint(client, context, options, source, destination):
    # Management-domain policy scope is not a firewall security zone.
    login = {'user': client.username, 'password': client.password, 'domain': context}
    session = client.request('/web_api/login', login)
    sid = session.get('sid')
    if not sid:
        raise ValueError('Check Point login did not return a session')
    header = {'X-chkp-sid': sid}
    def show(command, data):
        return client.request('/web_api/' + command, data, header)
    def pages(command, body, key):
        items = []; offset = 0
        for _ in range(20):
            data = show(command, dict(body, offset=offset, limit=100, **{'details-level': 'full'}))
            batch = data.get(key)
            if not isinstance(batch, list) or not isinstance(data.get('total'), int):
                raise ValueError('Incomplete Check Point collection')
            items.extend(batch)
            offset = data.get('to', offset + len(batch))
            if offset >= data['total']:
                return items
            if not batch:
                break
        raise ValueError('Check Point paging exceeded bound')
    try:
        raw = {
            'gateway': show('show-object', {'uid': options['gateway_uid'], 'details-level': 'full'}),
            'rules': pages('show-access-rulebase', {'name': options['access_layer'], 'use-object-dictionary': False}, 'rulebase'),
            'nat': pages('show-nat-rulebase', {'package': options['policy_package']}, 'rulebase'),
        }
    finally:
        show('logout', {})
    gateway = raw['gateway'].get('object', raw['gateway'])
    finding = {'PolicyLayer': options['access_layer'], 'PolicyPackage': options['policy_package'],
               'GatewayUID': options['gateway_uid'], 'SecurityRuleCount': len(raw['rules']),
               'Interfaces': gateway.get('interfaces', []), 'Unresolved': [],
               'PolicyReview': 'Gateway targets, inline layers, groups and NAT require rulebase evaluation before apply'}
    if not finding['Interfaces']:
        finding['Unresolved'].append('Management object did not expose gateway interface topology')
    if raw['nat']:
        finding['Unresolved'].append('NAT rulebase must be evaluated for the requested flow')
    return raw, finding


def nsx(client, context, options, source, destination):
    auth = base64.b64encode((client.username + ':' + client.password).encode()).decode()
    header = {'Authorization': 'Basic ' + auth}
    def pages(path):
        result = []; cursor = None; seen = set()
        for _ in range(20):
            query = {'page_size': 100}
            if cursor:
                query['cursor'] = cursor
            data = client.request(path + '?' + urllib.parse.urlencode(query), headers=header)
            if not isinstance(data.get('results'), list):
                raise ValueError('NSX list response missing')
            result.extend(data['results'])
            cursor = data.get('cursor')
            if not cursor:
                return result
            if cursor in seen:
                break
            seen.add(cursor)
        raise ValueError('NSX paging exceeded bound')
    base = '/policy/api/v1/infra/domains/' + context
    groups = pages(base + '/groups')
    policies = pages(base + '/security-policies')
    membership = {source: [], destination: []}
    for group in groups:
        gid = urllib.parse.quote(group['id'], safe='')
        members = pages(base + '/groups/' + gid + '/members/ip-addresses')
        for address in membership:
            for member in members:
                try:
                    if ipaddress.ip_address(address) in ipaddress.ip_network(member, strict=False):
                        membership[address].append(group['path']); break
                except (ValueError, TypeError):
                    raise ValueError('Unsupported NSX membership representation')
    rules = {}
    for policy in policies:
        pid = urllib.parse.quote(policy['id'], safe='')
        rules[policy['path']] = pages(base + '/security-policies/' + pid + '/rules')
    raw = {'groups': groups, 'policies': policies, 'rules': rules, 'membership': membership}
    finding = {'Enforcement': 'DistributedFirewall', 'Domain': context,
        'SourceGroups': membership[source], 'DestinationGroups': membership[destination],
        'PolicyPaths': [p['path'] for p in policies], 'Unresolved': [],
        'PolicyReview': 'Review DFW category/order/applied-to, exclusions, service definitions and realized state before apply'}
    if not membership[source] or not membership[destination]:
        finding['Unresolved'].append('Endpoint group membership is unresolved in this NSX domain')
    return raw, finding


def asa(raw, source, destination):
    # ASA is collected with network_cli in the declared security context.
    routes = []; zones = {}; name = None
    for block in raw['interfaces'].split('!'):
        name_match = re.search(r'^\s*nameif\s+(\S+)', block, re.M)
        if name_match:
            name = name_match.group(1); zones[name] = [name]
    # Only explicit single-line IPv4 routes are normalized. Unrecognized output
    # is retained and cannot silently become a zone decision.
    for line in raw['routes'].splitlines():
        match = re.search(r'\b(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+).*?,\s*([\w.-]+)\s*$', line)
        if match:
            net, mask, interface = match.groups()
            routes.append({'prefix': str(ipaddress.ip_network(net + '/' + mask, strict=False)), 'interface': interface})
    finding = zone_findings(source, destination, routes, zones)
    finding['ACLBindings'] = re.findall(r'^access-group\s+(\S+)\s+(in|out)\s+interface\s+(\S+)', raw['access_groups'], re.M)
    finding['PolicyReview'] = 'ACL/object-group order and NAT semantics require verification before apply'
    if raw.get('nat', '').strip():
        finding['Unresolved'].append('NAT output present: translation must be evaluated before apply')
    return raw, finding


def collect(params):
    candidate = params['candidate']
    platform = candidate['Platform']; context = identifier(candidate['Context'])
    source = str(ipaddress.ip_address(params['source'])); destination = str(ipaddress.ip_address(params['destination']))
    if platform == 'asa':
        raw, findings = asa(params['asa_output'], source, destination)
    else:
        client = Client(params['host'], params.get('username', ''), params.get('password', ''), params.get('token', ''), params.get('ca_file'))
        collectors = {'panos': panos, 'fortios': fortios, 'checkpoint': checkpoint, 'nsx': nsx}
        if platform not in collectors:
            raise ValueError('Unsupported platform')
        raw, findings = collectors[platform](client, context, params.get('options', {}), source, destination)
    serialized = json.dumps(raw, sort_keys=True).encode()
    if len(serialized) > 512000:
        raise ValueError('Device evidence exceeds callback budget')
    return dict(candidate, Status='COLLECTED', CollectedAt=int(time.time()), Findings=findings,
                EvidenceHash=hashlib.sha256(serialized).hexdigest(), Raw=raw)


def main():
    from ansible.module_utils.basic import AnsibleModule
    module = AnsibleModule(argument_spec={
        'candidate': {'type': 'dict', 'required': True}, 'source': {'type': 'str', 'required': True},
        'destination': {'type': 'str', 'required': True}, 'host': {'type': 'str', 'default': ''},
        'username': {'type': 'str', 'default': '', 'no_log': True}, 'password': {'type': 'str', 'default': '', 'no_log': True},
        'token': {'type': 'str', 'default': '', 'no_log': True}, 'ca_file': {'type': 'path'},
        'options': {'type': 'dict', 'default': {}}, 'asa_output': {'type': 'dict', 'default': {}}}, supports_check_mode=True)
    try:
        module.exit_json(changed=False, evidence=collect(module.params))
    except Exception as exc:
        # Never expose exception bodies containing HTTP tokens/configuration.
        module.fail_json(msg='Read-only network collection failed: ' + type(exc).__name__)


if __name__ == '__main__':
    main()
