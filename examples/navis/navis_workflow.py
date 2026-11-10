"""Navis 0.1.0 contract adapter for an AWX preparation job.

No device writes. Navis graph identities select authorized CMDB enrichment rows.
Credentials come from AWX environment injection only.
"""
import hashlib
import ipaddress
import json
import os
import re
import ssl
import sys
import uuid
from urllib.parse import quote, urlsplit
from urllib.request import Request, build_opener, HTTPSHandler, HTTPRedirectHandler

LIMIT = 900000


class ContractError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise ContractError(message)


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(',', ':')).encode()).hexdigest()


def trace_request(flow, build, caller):
    require(isinstance(flow, dict), 'Flow must be an object')
    require(not (set(flow) - {'source', 'destination', 'protocol', 'source_port', 'destination_port', 'application', 'action'}), 'Unexpected flow keys')
    require(flow.get('action') in ('allow', 'deny'), 'Explicit requested action required')
    request = {k: v for k, v in flow.items() if k != 'action'}
    request.update(graph_build_id=str(uuid.UUID(build)), caller_session_id=caller)
    require(bool(re.fullmatch(r'[A-Za-z0-9_-]{1,255}', caller)), 'Unsafe caller session ID')
    addresses = []
    for key in ('source', 'destination'):
        value = request.get(key)
        require(isinstance(value, str) and 0 < len(value) <= 16000, 'Literal IP lists required')
        parts = re.split('[,;]', value)
        require(all(p.strip() for p in parts), 'Empty IP list component')
        values = list(dict.fromkeys(str(ipaddress.ip_address(p.strip())) for p in parts))
        addresses.append(values)
        request[key] = ';'.join(values)
    require(len(addresses[0]) * len(addresses[1]) <= 1000, 'Too many expanded flows')
    protocol = request.get('protocol')
    require(isinstance(protocol, str), 'Protocol required')
    request['protocol'] = protocol = protocol.strip().lower()
    require(protocol in ('tcp', 'udp', 'icmp', 'icmpv6'), 'Unsupported protocol')
    for key in ('source_port', 'destination_port'):
        port = request.get(key)
        require(port is None or type(port) is int and 0 <= port <= 65535, 'Strict integer port required')
        require(protocol not in ('icmp', 'icmpv6') or port is None, 'ICMP has no ports')
    if 'application' in request:
        require(isinstance(request['application'], str) and 0 < len(request['application'].strip()) <= 255, 'Invalid application identity')
    return request


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


class Client:
    def __init__(self, origin, token, ca_file=None):
        url = urlsplit(origin)
        require(url.scheme == 'https' and url.hostname and not url.username and not url.password
                and url.path in ('', '/') and not url.query and not url.fragment, 'HTTPS origin required')
        require(isinstance(token, str) and token and '\n' not in token and '\r' not in token, 'AWX-injected token required')
        self.origin, self.token = origin.rstrip('/'), token
        self.opener = build_opener(HTTPSHandler(context=ssl.create_default_context(cafile=ca_file)), NoRedirect())

    def call(self, method, path, data=None):
        body = None if data is None else json.dumps(data).encode()
        request = Request(self.origin + path, data=body, method=method,
                          headers={'Authorization': 'Bearer ' + self.token, 'Accept': 'application/json', 'Content-Type': 'application/json'})
        # Exactly one attempt, especially for POST. A timeout has uncertain outcome.
        with self.opener.open(request, timeout=120) as response:
            require(response.status == 200, 'Unexpected Navis HTTP status')
            raw = response.read(4194305)
            require(len(raw) <= 4194304, 'Navis response exceeds budget')
            result = json.loads(raw)
            require(isinstance(result, dict), 'Navis response must be an object')
            return result


def tuple_key(row):
    return tuple(row.get(k) for k in ('source', 'destination', 'protocol', 'destination_port'))


def identity_key(namespace, object_class, external_id):
    require(all(isinstance(v, str) and 0 < len(v) <= 255 for v in (namespace, object_class, external_id)),
            'Opaque external identity strings required')
    return namespace, object_class, external_id


def graph_identities(graph, build):
    require(isinstance(graph, dict) and graph.get('build_id') == build
            and graph.get('status') == 'completed', 'Completed matching graph required')
    nodes = graph.get('nodes')
    require(isinstance(nodes, list) and len(nodes) <= 10000, 'Bounded graph nodes required')
    devices, identities = {}, set()
    for node in nodes:
        require(isinstance(node, dict) and node.get('type') == 'device', 'Invalid graph device')
        device = str(uuid.UUID(node.get('id', '')))
        require(device not in devices, 'Duplicate graph device')
        identity = node.get('external_identity')
        require(isinstance(identity, dict), 'Graph external identity required')
        key = None
        if identity.get('status') == 'mapped':
            key = identity_key(identity.get('namespace'), identity.get('object_class'), identity.get('id'))
            require(key not in identities, 'External identity maps to multiple devices')
            identities.add(key)
        devices[device] = key
    return devices


def prepare(request, action, trace, recommendations, snapshot, graph, namespace):
    """Produce simulation intents; never an approval or an apply-ready plan."""
    require(trace.get('code') == 'TRACE_RESULT_READY', 'Unexpected trace code')
    require(trace.get('caller_session_id') == request['caller_session_id'], 'Trace caller mismatch')
    require(trace.get('graph_build_id') == request['graph_build_id'], 'Trace graph mismatch')
    uuid.UUID(trace.get('trace_session_id', ''))
    require(recommendations.get('caller_session_id') == request['caller_session_id']
            and recommendations.get('trace_session_id') == trace['trace_session_id'], 'Recommendation session mismatch')
    require(isinstance(snapshot, list) and len(snapshot) <= 1000, 'Bounded authorized CMDB snapshot required')
    require(isinstance(namespace, str) and 0 < len(namespace) <= 255, 'Registered CMDB namespace required')
    devices = graph_identities(graph, request['graph_build_id'])
    mapped = {}
    for row in snapshot:
        require(isinstance(row, dict), 'Invalid CMDB snapshot row')
        require('navis_device_id' not in row, 'Legacy manual device association is unsupported')
        key = identity_key(row.get('namespace'), row.get('Class'), row.get('ConfigItemID'))
        require(key[:2] == (namespace, 'NetworkNode'), 'Authorized NetworkNode namespace/class required')
        require(key not in mapped, 'Duplicate CMDB enrichment identity')
        require(row.get('platform') in ('panos', 'aci', 'nsx') and isinstance(row.get('context'), dict)
                and row['context'], 'Platform/context enrichment required')
        mapped[key] = row
    results = trace.get('results')
    require(isinstance(results, list) and results, 'Missing trace flows')
    expected = {(s, d, request['protocol'], request.get('destination_port'))
                for s in request['source'].split(';') for d in request['destination'].split(';')}
    require(len(results) == len(expected) and {tuple_key(r) for r in results} == expected, 'Trace flow mismatch')
    summaries = []
    for row in results:
        verdict = row.get('connection_verdict') or {}
        status = verdict.get('status', 'unknown')
        summaries.append({'flow': dict(zip(('source', 'destination', 'protocol', 'destination_port'), tuple_key(row))),
                          'status': status if status in ('allowed', 'blocked', 'unknown') else 'unknown',
                          'missing': verdict.get('missing', [])})
    outcome = {'Status': 'REVIEW_REQUIRED', 'Simulation': True, 'ApplyReady': False,
               'CallerSessionID': request['caller_session_id'], 'TraceSessionID': trace['trace_session_id'],
               'GraphBuildID': request['graph_build_id'], 'RequestDigest': digest(request),
               'CMDBSnapshotDigest': digest(snapshot), 'GraphIdentityDigest': digest(graph), 'RequestedAction': action,
               'Summary': summaries, 'Plans': [], 'Issues': []}
    code = recommendations.get('code')
    require(code in ('RECOMMENDATION_PENDING', 'RECOMMENDATIONS_AVAILABLE', 'RECOMMENDATIONS_UNAVAILABLE'), 'Unknown recommendation code')
    if code != 'RECOMMENDATIONS_AVAILABLE':
        outcome['Status'] = code
        return outcome
    rows = recommendations.get('recommendations')
    require(isinstance(rows, list) and 0 < len(rows) <= 256, 'Invalid recommendation rows')
    seen = set()
    for outer in rows:
        draft = outer.get('result')
        if outer.get('status') != 'ready' or not isinstance(draft, dict):
            outcome['Issues'].append('Recommendation is not a ready draft')
            continue
        # Navis currently proposes allow only. Do not transform allow into deny.
        if action != 'allow' or draft.get('action') != action or draft.get('status') != 'draft':
            outcome['Issues'].append('Requested action unsupported or draft incomplete')
            continue
        require(tuple_key(draft) in expected, 'Recommendation flow mismatch')
        key = devices.get(str(uuid.UUID(draft.get('device_id', ''))))
        row = mapped.get(key) if key and key[:2] == (namespace, 'NetworkNode') else None
        if row is None:
            outcome['Issues'].append('Recommendation lacks a unique caller-scoped NetworkNode identity or authorized CMDB enrichment')
            continue
        # Preserve the draft verbatim. Vendor context may require explicit CMDB
        # enrichment; the simulator does not guess zones, EPGs or NSX groups.
        fingerprint = digest(draft)
        require(fingerprint not in seen, 'Duplicate draft')
        seen.add(fingerprint)
        outcome['Plans'].append({'PlanID': fingerprint, 'Target': {'Application': 'tessera', 'ObjectType': 'CMDB',
                                 'Namespace': key[0], 'Class': key[1], 'ConfigItemID': key[2]},
                                 'Platform': row['platform'], 'Context': row['context'], 'Draft': draft})
    if not outcome['Plans']:
        outcome['Issues'].append('No simulatable vendor plans')
    return outcome


def simulate(plan):
    """Vendor-specific required context; output is an intent, not API syntax."""
    platform, context, draft = plan['Platform'], plan['Context'], plan['Draft']
    fields = {'panos': ('vsys', 'source_zone', 'destination_zone'),
              'aci': ('tenant', 'source_epg', 'destination_epg', 'contract'),
              'nsx': ('domain', 'source_group', 'destination_group', 'applied_to', 'policy')}[platform]
    missing = [k for k in fields if not isinstance(context.get(k), str) or not context[k].strip()]
    # Zone names from CMDB are explicit operator-reviewed enrichment, never
    # assumed equal to the CMDB NetworkZone governance object.
    if platform == 'panos':
        for k in ('source_zone', 'destination_zone'):
            if draft.get(k) != context.get(k) or draft.get(k + '_status') != 'resolved':
                missing.append(k + '_resolution')
    if draft.get('protocol') in ('tcp', 'udp') and draft.get('destination_port') is None:
        missing.append('destination_port')
    return {'PlanID': plan['PlanID'], 'Target': plan['Target'], 'Platform': platform,
            'Status': 'ENRICHMENT_REQUIRED' if missing else 'SIMULATED',
            'Changed': False, 'Verified': False, 'Missing': missing,
            'RuleReference': None if missing else 'simulation-' + plan['PlanID'][:16],
            'Operation': {'panos': 'security_rule', 'aci': 'contract_filter', 'nsx': 'dfw_rule'}[platform]}


def run(payload, client=None):
    execution = payload['execution_uid']
    require(isinstance(execution, str) and bool(re.fullmatch('[a-fA-F0-9]{40}', execution)), 'Durable execution UID required')
    original = payload.get('trace_execution_uid', execution) if payload.get('mode') == 'recommendations' else execution
    require(isinstance(original, str) and bool(re.fullmatch('[a-fA-F0-9]{40}', original)), 'Original trace execution UID required')
    caller = 'tessera-' + original
    request = trace_request(payload['flow'], payload['graph_build_id'], caller)
    mode = payload.get('mode')
    require(mode in ('fixture', 'navis', 'recommendations'), 'Explicit fixture, navis or recommendations mode required')
    if mode == 'fixture':
        graph = payload['fixture']['graph']
        trace, recommendations = payload['fixture']['trace'], payload['fixture']['recommendations']
        # Fixtures are supplied separately and labelled; never repair live IDs.
        trace = dict(trace, caller_session_id=caller)
        recommendations = dict(recommendations, caller_session_id=caller)
    else:
        require(client is not None, 'Navis client required')
        graph = client.call('GET', '/v1/graph-builds/' + request['graph_build_id'] + '/graph')
        graph_identities(graph, request['graph_build_id'])
        trace = payload['saved_trace'] if mode == 'recommendations' else client.call('POST', '/v1/traces', request)
        recommendations = client.call('GET', '/v1/trace-sessions/' + quote(caller, safe='') + '/recommendations')
    result = prepare(request, payload['flow']['action'], trace, recommendations, payload['cmdb_snapshot'], graph,
                     payload['identity_namespace'])
    result['Mode'] = mode
    # Retain the original synchronous trace: Navis has no stored-trace GET API.
    result['Request'] = request
    result['Trace'] = trace
    result['Recommendations'] = recommendations
    result['Graph'] = graph
    return result


def main():
    caller = None
    try:
        raw = sys.stdin.buffer.read(4194305)
        require(len(raw) <= 4194304, 'Input exceeds budget')
        payload = json.loads(raw)
        require(isinstance(payload, dict), 'Input object required')
        if sys.argv[1:] == ['--simulate']:
            print(json.dumps(simulate(payload)))
            return 0
        caller = 'tessera-' + str(payload.get('execution_uid', ''))
        client = Client(os.environ['NAVIS_URL'], os.environ['NAVIS_TOKEN'], os.environ.get('NAVIS_CA_FILE')) if payload.get('mode') in ('navis', 'recommendations') else None
        result = run(payload, client)
        require(len(json.dumps(result).encode()) < LIMIT, 'Result exceeds callback budget')
        print(json.dumps(result))
    except Exception:
        # No raw input, URL, token, server body or exception in stdout/stderr.
        print(json.dumps({'Status': 'FAILED_OR_UNCERTAIN', 'CallerSessionID': caller,
                          'Simulation': True, 'ApplyReady': False, 'Plans': [],
                          'Issues': ['Reconcile Navis POST outcome before rerun; inspect restricted operator diagnostics']}))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
