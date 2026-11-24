#!/usr/bin/env python3
"""One-attempt recovery of the reviewed testing0.1.8->0.1.12 partial upgrade."""
import argparse
import base64
import copy
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import time
import uuid

HERE = Path(__file__).resolve().parent

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

helper = load('config_resume_deploy', HERE / 'upgrade-deploy.py')
common = load('config_resume_common', HERE / 'recover-179-to-184.py')
before = load('config_resume_before', HERE / 'resume-before-upgrade.py')
diagnostic = load('config_resume_diagnostic', HERE / 'diagnose-release.py')
preflight = load('release012_preflight', HERE / 'recovery-preflight.py')

CONTROL = r'''require '/opt/tessera-release012-recovery/recover-release012.pl';'''

class Client:
    def __init__(self, namespace): self.prefix = ['kubectl', '-n', namespace]
    def get(self, *args): return json.loads(subprocess.check_output(self.prefix + ['get', *args, '-o', 'json'], text=True))
    def run(self, *args): subprocess.run(self.prefix + list(args), check=True)
    def write(self, obj, verb='create', dry=False):
        subprocess.run(self.prefix + [verb] + (['--dry-run=server'] if dry else []) + ['-f', '-'],
                       input=json.dumps(obj), text=True, check=True)

def find_state(job, root=Path('artifacts')):
    matches = []
    for path in root.glob('*/upgrade-job.json'):
        saved = json.loads(path.read_text())
        if saved.get('metadata', {}).get('name') == job: matches.append(path.parent)
    if len(matches) != 1: raise ValueError('Need the unique original private state directory for this Job; use --state-directory')
    return matches[0].resolve()

def recovery_manifest(original, namespace, name):
    result = diagnostic.diagnostic_job(original, namespace, name)
    pod = result['spec']['template']['spec']
    labels = result['spec']['template']['metadata']['labels']
    labels.pop('tessera-release-diagnostic', None)
    labels['tessera-release012-continuation'] = 'true'
    main = pod['containers'][0]
    main['command'] = ['/bin/bash', '-c', diagnostic.SHELL, 'recover-release012']
    main['args'] = [base64.b64encode(CONTROL.encode()).decode()]
    main.setdefault('env', []).extend([{'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}, {'name': 'TESSERA_TEST_NO_BACKUP', 'value': '1'}])
    if any(v['name'] == 'tessera-release012-recovery' for v in pod['volumes']): raise ValueError('Recovery mount already exists')
    pod['volumes'].append({'name': 'tessera-release012-recovery', 'configMap': {'name': name + '-code', 'defaultMode': 0o444}})
    main['volumeMounts'].append({'name': 'tessera-release012-recovery', 'mountPath': '/opt/tessera-release012-recovery', 'readOnly': True})
    pod['volumes'][-1]['configMap']['items'] = [
        {'key': name, 'path': name} for name in (
            'configure.py', 'recover-release012.pl', 'upgrade-cache.pl', 'framework-11.1.1.json')]
    result['spec']['activeDeadlineSeconds'] = 3600
    return result

def resume(client, state, job_name, source, cleanup=None):
    if job_name != 'tessera-release-1795491815': raise ValueError('Only the reviewed failed0.1.12 Job may recover')
    state = Path(state).resolve()
    if before.active_runners(state): raise ValueError('Stop the original waiting local upgrade helper with Ctrl-C first')
    def saved(name): return json.loads((state / name).read_text())
    original, claim = saved('upgrade-job.json'), saved('maintenance-lock.json')
    main, pvc = before.validate_manifest(original)
    if original['metadata']['name'] != job_name:
        raise ValueError('Saved state does not match the failed Job')
    namespace = original['metadata']['namespace']
    failed = client.get('job', job_name)
    if not common.terminal(failed, 'Failed'): raise ValueError('Original Job must be terminal Failed')
    observed_main = failed['spec']['template']['spec']['containers'][0]
    if observed_main['image'] != main['image'] or observed_main.get('args') != ['upgrade']:
        raise ValueError('Failed Job command/image differs from saved state')
    if main['image'] != 'docker.io/library/tessera:0.1.12-ubuntu26.04':
        raise ValueError('Requires the original reviewed0.1.12 image')
    _, observed_pvc = before.validate_manifest(failed)
    if observed_pvc != pvc or any(observed_main.get(k) != main.get(k) for k in ('name', 'env', 'envFrom', 'volumeMounts', 'securityContext', 'workingDir')):
        raise ValueError('Failed Job environment/mounts differ from private state')
    lock = client.get('configmap', helper.LOCK_NAME)
    if lock.get('metadata', {}).get('labels', {}).get('app.kubernetes.io/managed-by') != 'tessera-release-helper' or lock.get('data') != claim.get('data') or lock['data'].get('phase') != 'LOCKED':
        raise ValueError('Original maintenance ownership no longer matches')
    for item in client.get('jobs')['items']:
        if item['spec']['template']['metadata'].get('labels', {}).get('tessera-release-upgrade') and not (common.terminal(item, 'Complete') or common.terminal(item, 'Failed')):
            raise ValueError('Another release/diagnostic Job is active')
    workloads = []
    for filename in ('web-before.json', 'daemon-before.json'):
        old = saved(filename); current = client.get('deployment', old['metadata']['name'])
        common.same_target(current, old)
        if current['spec'].get('replicas', 1) != 0 or current['spec']['template']['spec']['containers'][0]['image'] != old['spec']['template']['spec']['containers'][0]['image']:
            raise ValueError('Workloads must remain quiesced with unchanged images')
        if helper.workload_pods(client.get('pods', '-l', helper.selector(old))['items']): raise ValueError('Application writers remain')
        workloads.append(old)
    names = {item['metadata']['name'] for item in workloads}
    if any(h['spec']['scaleTargetRef']['name'] in names for h in client.get('hpa')['items']): raise ValueError('HPA ownership must be resolved')
    bundle = client.get('pvc', pvc)
    if bundle['metadata'].get('deletionTimestamp'): raise ValueError('Current bundle is being deleted; preserve it before recovery')
    for old in workloads:
        print('Will restore', old['metadata']['name'], 'replicas:', old['spec'].get('replicas', 1), flush=True)
    out = state / 'recover-release012';
    if out.exists(): preflight.preserve_unclaimed(client, out, failed, lambda old_name: recovery_manifest(failed, namespace, old_name))
    def save(name, value):
        with (out / name).open('x', encoding='utf-8') as stream:
            os.chmod(stream.name, 0o600);json.dump(value, stream, indent=2)
    name = 'tessera-release012-recovery-' + uuid.uuid4().hex[:12]
    manifest = recovery_manifest(failed, namespace, name)
    code = {'apiVersion': 'v1', 'kind': 'ConfigMap', 'immutable': True, 'metadata': {'name': name + '-code', 'namespace': namespace,
            'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}}, 'data': {key: Path(path).read_text(encoding='utf-8') for key,path in {
        'configure.py': source,
        'recover-release012.pl': HERE.parent/'image/recover-release012.pl',
        'upgrade-cache.pl': HERE.parent/'image/upgrade-cache.pl',
        'framework-11.1.1.json': HERE.parent/'image/framework-11.1.1.json'}.items()}}
    def validate_quiet():
        observed = client.get('configmap', helper.LOCK_NAME)
        if observed.get('data') != claim.get('data'):
            raise ValueError('Original maintenance ownership changed')
        for old in workloads:
            current = client.get('deployment', old['metadata']['name'])
            common.same_target(current, old)
            if current['spec'].get('replicas', 1) != 0 or current['spec']['template']['spec']['containers'][0]['image'] != old['spec']['template']['spec']['containers'][0]['image']:
                raise ValueError('Target workloads changed during preflight')
            if helper.workload_pods(client.get('pods', '-l', helper.selector(old))['items']):
                raise ValueError('Application writers remain')
        if any(h['spec']['scaleTargetRef']['name'] in names for h in client.get('hpa')['items']):
            raise ValueError('HPA ownership changed')
        for other in client.get('jobs')['items']:
            if other['spec']['template']['metadata'].get('labels', {}).get('tessera-release-upgrade') and not (common.terminal(other, 'Complete') or common.terminal(other, 'Failed')):
                raise ValueError('Another release/diagnostic Job is active')
        return observed
    lock = preflight.run(client, state, manifest, code, validate_quiet)
    out.mkdir(mode=0o700, exist_ok=False)
    save('failed-job.json', failed);save('upgrade-job.json', manifest);save('bundle-pvc.json', bundle);save('rebuild-code.json', code)
    client.write(manifest, dry=True)
    lock['data']['owner'] = uuid.uuid4().hex
    save('maintenance-lock.json', lock);client.write(lock, verb='replace')
    def owned():
        current = client.get('configmap', helper.LOCK_NAME)
        if current.get('data') != lock['data']: raise ValueError('Maintenance ownership changed')
        return current
    owned();client.write(manifest)
    print('Release012 recovery Job:', name, '\nPrivate continuation state:', out, flush=True)
    deadline = time.monotonic() + 3660
    while time.monotonic() < deadline:
        status = client.get('job', name)
        if common.terminal(status, 'Failed'):
            client.run('logs', 'job/' + name, '-c', main['name'], '--tail=100')
            raise ValueError('Release012 recovery Job failed; preserve all claims and evidence')
        if common.terminal(status, 'Complete'): break
        time.sleep(3)
    else: raise ValueError('Release012 recovery Job not terminal; inspect before retry')
    owned()
    for old in workloads:
        target = 'deployment/' + old['metadata']['name']; container = old['spec']['template']['spec']['containers'][0]['name']
        owned();client.run('set', 'image', target, container + '=' + main['image'])
        owned();client.run('scale', target, '--replicas=' + str(old['spec'].get('replicas', 1)))
        client.run('rollout', 'status', target, '--timeout=600s')
    owned()
    print('Original failed Job, recovery Job and bundle PVC retained:', pvc, flush=True)
    ready = helper.maintenance_lock(owned(), namespace, lock['data']['owner'], 'READY')
    save('maintenance-ready.json', ready);client.write(ready, verb='replace')
    print('Release0.1.12 READY; exact saved replicas restored. Failed source Job retained. State:', out, flush=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--namespace', default='tessera');parser.add_argument('--job', required=True)
    parser.add_argument('--state-directory', type=Path)
    parser.add_argument('--test-no-backup', action='store_true', required=True,
                        help='Owner-approved test-server recovery without backup')
    args = parser.parse_args()
    if any(not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', v) for v in (args.namespace, args.job)): parser.error('Invalid Kubernetes name')
    state = args.state_directory or find_state(args.job)
    saved = json.loads((state / 'upgrade-job.json').read_text())
    if saved['metadata']['namespace'] != args.namespace: raise ValueError('Namespace differs from private state')
    resume(Client(args.namespace), state, args.job, HERE.parent / 'image/configure.py')

if __name__ == '__main__':
    try: main()
    except (Exception, KeyboardInterrupt) as error:
        raise SystemExit('Release012 recovery stopped: ' + str(error) + '. Preserve state/Job/bundle; no automatic retry.') from None
