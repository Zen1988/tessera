"""Sentinel-authorized replica replacement. Never promotes, wipes, or force-deletes."""
import base64
import ssl
from collections import Counter
from recovery import Blocked, age, conditions, result, utc


def validate(policy):
    import re
    required = {'name', 'kind', 'namespace', 'cluster', 'master_name', 'member_dns',
                'sentinel_hosts', 'credentials', 'redis_port', 'sentinel_port', 'tls'}
    if set(policy) != required:
        raise ValueError('explicit Redis recovery configuration required')
    for key in ('name', 'namespace', 'cluster', 'master_name'):
        if not isinstance(policy[key], str) or not re.fullmatch(r'[a-zA-Z0-9._-]{1,63}', policy[key]):
            raise ValueError('invalid Redis policy name')
    if not re.fullmatch(r'[a-z0-9.{}-]+', policy['member_dns']) or policy['member_dns'].count('{pod}') != 1:
        raise ValueError('Redis member TLS DNS template required')
    hosts = policy['sentinel_hosts']
    if not isinstance(hosts, list) or len(hosts) != 3 or len(set(hosts)) != 3 or any(not isinstance(h, str) or not re.fullmatch(r'[a-z0-9.-]{1,253}', h) for h in hosts):
        raise ValueError('three distinct Sentinel TLS DNS names required')
    for key in ('redis_port', 'sentinel_port'):
        if type(policy[key]) is not int or not 1 <= policy[key] <= 65535:
            raise ValueError('invalid Redis port')
    if type(policy['tls']) is not bool:
        raise ValueError('Redis transport must explicitly select TLS or plaintext')
    ref = policy['credentials']
    keys = {'secret', 'password_key', 'sentinel_password_key'}
    if policy['tls']:
        keys |= {'ca_key', 'cert_key', 'private_key'}
    if set(ref) != keys or any(not isinstance(v, str) or not re.fullmatch(r'[a-zA-Z0-9._-]{1,253}', v) for v in ref.values()):
        raise ValueError('explicit TLS and credential Secret keys required')


class Probe:
    def __init__(self, api, policy):
        import tempfile
        from pathlib import Path
        self.policy = policy
        ref = policy['credentials']
        data = api.get(f"/api/v1/namespaces/{policy['namespace']}/secrets/{ref['secret']}")['data']
        self.directory = None
        self.ca = self.cert = self.key = None
        try:
            if policy['tls']:
                self.directory = tempfile.TemporaryDirectory(prefix='tessera-redis-')
                self.ca, self.cert, self.key = [str(Path(self.directory.name) / x) for x in ('ca', 'cert', 'key')]
                for path, key in ((self.ca, 'ca_key'), (self.cert, 'cert_key'), (self.key, 'private_key')):
                    Path(path).write_bytes(base64.b64decode(data[ref[key]], validate=True))
                    Path(path).chmod(0o600)
            self.password = base64.b64decode(data[ref['password_key']], validate=True).decode()
            self.sentinel_password = base64.b64decode(data[ref['sentinel_password_key']], validate=True).decode()
        except Exception:
            self.close()
            raise

    def close(self):
        if self.directory is not None:
            self.directory.cleanup()

    def client(self, host, sentinel=False):
        import redis
        transport = {'ssl': False}
        if self.policy['tls']:
            transport = dict(ssl=True, ssl_ca_certs=self.ca, ssl_certfile=self.cert, ssl_keyfile=self.key,
                ssl_cert_reqs=ssl.CERT_REQUIRED, ssl_check_hostname=True)
        return redis.Redis(host=host, port=self.policy['sentinel_port' if sentinel else 'redis_port'],
            password=self.sentinel_password if sentinel else self.password,
            socket_connect_timeout=2, socket_timeout=2, decode_responses=True, **transport)

    def info(self, pod):
        client = self.client(self.policy['member_dns'].replace('{pod}', pod['metadata']['name']))
        try:
            return client.info('replication')
        finally:
            client.close()

    def primary(self):
        votes = []
        observed = []
        for host in self.policy['sentinel_hosts']:
            client = self.client(host, True)
            try:
                row = client.sentinel_master(self.policy['master_name'])
                raw_flags = row.get('flags', '')
                flags = set(raw_flags.split(',')) if isinstance(raw_flags, str) else set(raw_flags)
                if 'master' not in flags or flags & {'s_down', 'o_down', 'disconnected', 'failover_in_progress'}:
                    continue
                observed.append((str(row['ip']), int(row['port']), int(row['config-epoch'])))
                answer = client.execute_command('SENTINEL', 'CKQUORUM', self.policy['master_name'])
                if not str(answer).startswith('OK'):
                    continue
                votes.append((str(row['ip']), int(row['port']), int(row['config-epoch'])))
            except Exception:
                continue
            finally:
                client.close()
        if not votes or Counter(votes).most_common(1)[0][1] < 2:
            raise Blocked('Sentinel majority and failover quorum not confirmed')
        if len(set(observed)) != 1:
            raise Blocked('reachable Sentinels disagree on primary or epoch')
        return votes[0]


def authority(controller, policy, probe, pods, target):
    address, port, epoch = probe.primary()
    # Require advertised Pod IP, not guessed DNS/IP equivalence.
    primaries = [p for p in pods if p.get('status', {}).get('podIP') == address]
    if len(primaries) != 1 or port != policy['redis_port']:
        raise Blocked('Sentinel primary is outside verified member inventory')
    primary = primaries[0]
    if primary['metadata']['name'] == target:
        raise Blocked('failed member is still Sentinel primary; native failover must finish')
    survivors = [p for p in pods if p['metadata']['name'] != target]
    rows = {}
    # Read primary offset last so concurrent writes do not make a healthy replica appear ahead.
    survivors.sort(key=lambda pod: pod['metadata']['name'] == primary['metadata']['name'])
    for pod in survivors:
        controller.node_ok(pod)
        if pod['metadata'].get('deletionTimestamp') or conditions(pod).get('Ready', {}).get('status') != 'True':
            raise Blocked('surviving Redis member is not ready')
        rows[pod['metadata']['name']] = probe.info(pod)
    master = rows.get(primary['metadata']['name'], {})
    if master.get('role') != 'master' or not master.get('master_replid'):
        raise Blocked('Redis primary role or replication identity not confirmed')
    for name, row in rows.items():
        if name == primary['metadata']['name']:
            continue
        if row.get('role') != 'slave' or row.get('master_host') != address or int(row.get('master_port', 0)) != port or row.get('master_link_status') != 'up' or int(row.get('master_sync_in_progress', 1)) != 0 or row.get('master_replid') != master['master_replid']:
            raise Blocked('surviving Redis replica does not confirm authoritative replication')
        lag = int(master['master_repl_offset']) - int(row['slave_repl_offset'])
        if not 0 <= lag <= 16777216:
            raise Blocked('Redis replication lag exceeds policy')
    if len(rows) != 2:
        raise Blocked('two live Redis survivors required')
    return [address, port, epoch, master['master_replid']]


def step(controller, policy, probe_factory=Probe):
    controller.lead()
    record, ledger = controller.load()
    ns = policy['namespace']
    sts = controller.api.get(f"/apis/apps/v1/namespaces/{ns}/statefulsets/{policy['cluster']}")
    if sts['metadata'].get('deletionTimestamp') or sts.get('spec', {}).get('replicas') != 3:
        raise Blocked('Redis recovery requires a live three-member StatefulSet')
    pods = [p for p in controller.api.items(f'/api/v1/namespaces/{ns}/pods') if any(o.get('kind') == 'StatefulSet' and o.get('uid') == sts['metadata']['uid'] for o in p['metadata'].get('ownerReferences', []))]
    state = ledger.get(policy['name'])
    if state and state['phase'] == 'completed' and age(state['updated_at']) >= 21600:
        history = ledger.setdefault('history', [])
        if len(history) >= 20:
            raise Blocked('recovery receipt capacity reached; export receipts before further recovery')
        history.append(state)
        del ledger[policy['name']]
        controller.save(record, ledger)
        state = None
    if state and state['cluster_uid'] != sts['metadata']['uid']:
        raise Blocked('Redis StatefulSet identity changed')
    if state and state['phase'] != 'completed' and age(state['first_seen']) > 900:
        raise Blocked('Redis recovery exceeded 15-minute budget; infrastructure or fencing required')
    probe = probe_factory(controller.api, policy)
    try:
        if state and state['phase'] in ('evicting', 'waiting', 'completed'):
            current = next((p for p in pods if p['metadata']['name'] == state['target']), None)
            if not current or current['metadata']['uid'] == state['pod_uid']:
                if state['phase'] == 'completed':
                    raise Blocked('previously recovered Redis member is no longer present')
                if current and current['metadata'].get('deletionTimestamp'):
                    raise Blocked('Redis termination pending; no force deletion without node fencing')
                # An eviction response may have been lost; retry with UID preconditions below.
                if state['phase'] == 'waiting':
                    raise Blocked('waiting for native Redis replacement')
            elif conditions(current).get('Ready', {}).get('status') == 'True':
                source = authority(controller, policy, probe, pods, state['target'])
                controller.node_ok(current)
                row = probe.info(current)
                if row.get('role') != 'slave' or row.get('master_link_status') != 'up' or row.get('master_host') != source[0] or int(row.get('master_port', 0)) != source[1] or row.get('master_replid') != source[3] or int(row.get('master_sync_in_progress', 1)) != 0:
                    raise Blocked('replacement Redis replica is not synchronized')
                primary = next(p for p in pods if p.get('status', {}).get('podIP') == source[0])
                latest = probe.info(primary)
                if latest.get('role') != 'master' or latest.get('master_replid') != source[3] or not 0 <= int(latest['master_repl_offset']) - int(row['slave_repl_offset']) <= 16777216:
                    raise Blocked('replacement Redis replication lag or primary identity is uncertain')
                if state['phase'] != 'completed':
                    state.update(phase='completed', updated_at=utc())
                    ledger[policy['name']] = state
                    controller.save(record, ledger)
                return result('recovery/' + policy['name'], 'healthy', 'Redis replica recovery verified', {'operation': state['id']})
            else:
                raise Blocked('replacement Redis member is not ready')
        if len(pods) != 3:
            raise Blocked('Redis member inventory is incomplete')
        failed = [p for p in pods if p['metadata'].get('deletionTimestamp') or conditions(p).get('Ready', {}).get('status') != 'True']
        if not failed:
            roles = [probe.info(member).get('role') for member in pods]
            if roles.count('master') != 1 or roles.count('slave') != 2:
                raise Blocked('Redis role topology is not one primary and two replicas')
            for member in pods:
                authority(controller, policy, probe, pods, member['metadata']['name']) if probe.info(member).get('role') != 'master' else None
            return result('recovery/' + policy['name'], 'healthy', 'Redis primary and replicas verified')
        if len(failed) != 1:
            return result('recovery/' + policy['name'], 'unknown' if failed else 'healthy', 'no single failed Redis member eligible')
        pod = failed[0]
        controller.node_ok(pod)
        if pod['metadata'].get('deletionTimestamp'):
            raise Blocked('Redis termination pending; no force deletion without node fencing')
        name = pod['metadata']['name']
        source = authority(controller, policy, probe, pods, name)
        if state and state['phase'] == 'completed':
            raise Blocked('Redis recovery cooldown; previous receipt retained')
        if not state:
            import uuid
            state = {'id': str(uuid.uuid4()), 'target': name, 'pod_uid': pod['metadata']['uid'],
                'cluster_uid': sts['metadata']['uid'], 'source': source, 'first_seen': utc(),
                'updated_at': utc(), 'phase': 'confirmed', 'confirmations': 1}
        elif state['target'] != name or state['pod_uid'] != pod['metadata']['uid'] or state['source'] != source:
            raise Blocked('Redis target or primary epoch changed; no action')
        else:
            state['confirmations'] += 1
            if state['confirmations'] >= 3 and age(state['first_seen']) >= 120:
                state['phase'] = 'evicting'
                ledger[policy['name']] = state
                controller.save(record, ledger)  # Persist intent before eviction.
                controller.mutate('POST', f'/api/v1/namespaces/{ns}/pods/{name}/eviction',
                    {'apiVersion': 'policy/v1', 'kind': 'Eviction', 'metadata': {'name': name, 'namespace': ns},
                     'deleteOptions': {'preconditions': {'uid': state['pod_uid'], 'resourceVersion': pod['metadata']['resourceVersion']}}})
                state['phase'] = 'waiting'
        state['updated_at'] = utc()
        ledger[policy['name']] = state
        controller.save(record, ledger)
        return result('recovery/' + policy['name'], 'degraded', 'automatic Redis recovery ' + state['phase'], {'operation': state['id']})
    finally:
        probe.close()
