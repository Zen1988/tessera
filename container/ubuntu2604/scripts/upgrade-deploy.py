#!/usr/bin/env python3
"""Quiesce existing deployments, run one native upgrade Job, then activate image."""
import argparse
import copy
import json
import os
from pathlib import Path
import re
import subprocess
import time
import uuid

LOCK_NAME = 'tessera-release-maintenance'


def cleanup_bundle(prefix, state, name, container, pvc, uid):
    """Archive evidence before deleting this completed Job and its dedicated PVC.

    Caller retains LOCKED maintenance ownership until this returns. Cleanup
    failure never changes successful rollout status or deletes unverified data.
    """
    try:
        def get(*parts):
            return json.loads(subprocess.check_output(prefix + ['get', *parts, '-o', 'json'], text=True))
        current = get('pvc', pvc)
        labels = current['metadata'].get('labels', {})
        if current['metadata']['uid'] != uid or labels.get('app.kubernetes.io/managed-by') != 'tessera-release-helper' or labels.get('tessera-upgrade-bundle') != 'true':
            raise ValueError('Bundle PVC identity or ownership differs')
        finished = get('job', name)
        if finished.get('status', {}).get('active', 0) or not any(c.get('type') == 'Complete' and c.get('status') == 'True' for c in finished.get('status', {}).get('conditions', [])):
            raise ValueError('Upgrade Job is not terminal Complete')
        evidence = {'job': finished, 'bundle_pvc': current}
        for filename, content in [('upgrade-completed.json', json.dumps(evidence, indent=2)),
                                  ('upgrade-completed.log', subprocess.check_output(prefix + ['logs', 'job/' + name, '-c', container], text=True))]:
            with (Path(state) / filename).open('x', encoding='utf-8') as output:
                os.chmod(output.name, 0o600)
                output.write(content)
        # Foreground deletion waits for the completed Pod to release its mount.
        subprocess.run(prefix + ['delete', 'job', name, '--cascade=foreground', '--wait=true', '--timeout=120s'], check=True)
        for pod in get('pods')['items']:
            if any(v.get('persistentVolumeClaim', {}).get('claimName') == pvc for v in pod.get('spec', {}).get('volumes', [])):
                raise ValueError('Another Pod still references bundle PVC')
        if get('pvc', pvc)['metadata']['uid'] != uid:
            raise ValueError('Bundle PVC was replaced')
        subprocess.run(prefix + ['delete', 'pvc', pvc, '--wait=false'], check=True)
        print('Temporary upgrade bundle cleanup requested; evidence saved in', state)
        return True
    except Exception:
        print('Upgrade succeeded; automatic cleanup deferred. Preserve/inspect Job', name, 'and PVC', pvc, 'with saved state', state)
        return False


def maintenance_lock(current, namespace, owner, phase):
    if current:
        if current.get('metadata', {}).get('labels', {}).get('app.kubernetes.io/managed-by') != 'tessera-release-helper':
            raise ValueError('Maintenance ConfigMap is not owned by this helper')
        if phase == 'LOCKED' and current.get('data', {}).get('phase') != 'READY':
            raise ValueError('Another release is active or needs recovery')
        if phase == 'READY' and current.get('data', {}).get('owner') != owner:
            raise ValueError('Maintenance ownership changed')
    elif phase != 'LOCKED':
        raise ValueError('Maintenance claim missing')
    metadata = {'name': LOCK_NAME, 'namespace': namespace,
                'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}}
    if current:
        metadata['resourceVersion'] = current['metadata']['resourceVersion']
    return {'apiVersion': 'v1', 'kind': 'ConfigMap', 'metadata': metadata,
            'data': {'phase': phase, 'owner': owner}}


def job(web, container_name, image, name, namespace, bundle_pvc=None):
    pod = copy.deepcopy(web['spec']['template']['spec'])
    matches = [c for c in pod['containers'] if c['name'] == container_name]
    if len(matches) != 1 or len(pod['containers']) != 1:
        raise ValueError('This helper requires the verified single-container web Deployment')
    main = matches[0]
    paths = {m['mountPath'] for m in main.get('volumeMounts', [])}
    if not {'/opt/otobo/Kernel/Config.pm', '/opt/otobo/Kernel/Config/Files'} <= paths:
        raise ValueError('Target Config.pm and shared generated-config mounts are required')
    if any(m['mountPath'] == '/opt/otobo' for m in main.get('volumeMounts', [])):
        raise ValueError('Unexpected existing application root mount')
    if any(v['name'] == 'tessera-upgrade-work' for v in pod.get('volumes', [])):
        raise ValueError('Upgrade volume name already used')
    main['image'] = image
    main.pop('command', None)
    main['args'] = ['upgrade']
    for field in ('ports', 'livenessProbe', 'readinessProbe', 'startupProbe', 'lifecycle'):
        main.pop(field, None)
    main['env'] = [e for e in main.get('env', []) if e['name'] != 'TESSERA_UPGRADE_QUIESCED'] + [
        {'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}]
    main['volumeMounts'] = [{'name': 'tessera-upgrade-work', 'mountPath': '/opt/otobo'}] + main['volumeMounts']
    pod['containers'] = [main]
    pod['volumes'] = pod.get('volumes', []) + [{'name': 'tessera-upgrade-work', 'emptyDir': {}}]
    if bundle_pvc:
        if any(v['name'] == 'tessera-upgrade-bundle' for v in pod['volumes']) or any(m['mountPath'].startswith('/opt/tessera/upgrade-bundle') for m in main['volumeMounts']):
            raise ValueError('Upgrade bundle mount already used')
        pod['volumes'].append({'name': 'tessera-upgrade-bundle', 'persistentVolumeClaim': {'claimName': bundle_pvc, 'readOnly': True}})
        main['volumeMounts'].append({'name': 'tessera-upgrade-bundle', 'mountPath': '/opt/tessera/upgrade-bundle', 'subPath': 'upgrade', 'readOnly': True})
    pod['initContainers'] = [{'name': 'stage-upgrade', 'image': image,
        'imagePullPolicy': main.get('imagePullPolicy', 'IfNotPresent'),
        'command': ['/usr/bin/python3', '/usr/local/lib/tessera/upgrade-stage.py'],
        'volumeMounts': [{'name': 'tessera-upgrade-work', 'mountPath': '/work/application'}],
        'securityContext': copy.deepcopy(main.get('securityContext', {})),
        'resources': copy.deepcopy(main.get('resources', {}))}]
    pod['restartPolicy'] = 'Never'
    labels = copy.deepcopy(web['spec']['template']['metadata'].get('labels', {}))
    labels['tessera-release-upgrade'] = name
    return {'apiVersion': 'batch/v1', 'kind': 'Job', 'metadata': {'name': name, 'namespace': namespace},
        'spec': {'backoffLimit': 0, 'activeDeadlineSeconds': 1800,
            'template': {'metadata': {'labels': labels}, 'spec': pod}}}


def selector(deployment):
    s = deployment['spec']['selector']
    if s.get('matchExpressions') or not s.get('matchLabels'):
        raise ValueError('Explicit matchLabels selectors are required')
    return ','.join(f'{k}={v}' for k, v in sorted(s['matchLabels'].items()))


def workload_pods(items):
    # Retained Job evidence shares app labels. Failed Job Pods are also safe
    # evidence only when their containers are proven terminated. Do not hide
    # active/unknown/terminating Pods or failed Deployment-owned application Pods.
    def evidence(pod):
        meta = pod.get('metadata', {})
        if meta.get('deletionTimestamp') or not meta.get('labels', {}).get('tessera-release-upgrade') or not any(o.get('kind') == 'Job' for o in meta.get('ownerReferences', [])):
            return False
        status = pod.get('status', {})
        if status.get('phase') == 'Succeeded':
            return True
        containers = status.get('containerStatuses', [])
        all_containers = containers + status.get('initContainerStatuses', [])
        return status.get('phase') == 'Failed' and bool(containers) and all(c.get('state', {}).get('terminated') is not None for c in all_containers)
    return [pod for pod in items if not evidence(pod)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for arg in ('namespace', 'web', 'daemon', 'container', 'image', 'state-directory'):
        parser.add_argument('--' + arg, required=True)
    parser.add_argument('--upgrade-bundle-pvc', required=True)
    parser.add_argument('--cleanup-bundle', action='store_true', help='After successful rollouts, archive Job evidence and remove its managed temporary bundle PVC')
    args = parser.parse_args()
    if args.web == args.daemon:
        parser.error('Web and daemon must be separate Deployments')
    for value in (args.namespace, args.web, args.daemon, args.container, args.upgrade_bundle_pvc):
        if not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', value):
            parser.error('Invalid Kubernetes name')
    if not re.fullmatch(r'[a-z0-9][a-z0-9._:/@-]*', args.image):
        parser.error('Use an immutable image tag or digest without credentials')
    if not re.search(r'(?:@sha256:[a-f0-9]{64}|:[0-9]+\.[0-9]+\.[0-9]+(?:-r[1-9][0-9]*)?-ubuntu26\.04)$', args.image):
        parser.error('Use the versioned toolkit image tag or a pinned sha256 digest')
    state = Path(args.state_directory)
    state.mkdir(mode=0o700, parents=True, exist_ok=False)
    os.chmod(state, 0o700)
    def run(*parts, read=False):
        call = ['kubectl', '-n', args.namespace, *parts]
        if read:
            return json.loads(subprocess.check_output(call, text=True))
        subprocess.run(call, check=True)
    web = run('get', 'deployment', args.web, '-o', 'json', read=True)
    daemon = run('get', 'deployment', args.daemon, '-o', 'json', read=True)
    bundle_uid = None
    if args.cleanup_bundle:
        bundle = run('get', 'pvc', args.upgrade_bundle_pvc, '-o', 'json', read=True)
        labels = bundle['metadata'].get('labels', {})
        if labels.get('app.kubernetes.io/managed-by') != 'tessera-release-helper' or labels.get('tessera-upgrade-bundle') != 'true':
            raise ValueError('Cleanup requires a dedicated helper-managed upgrade bundle PVC')
        bundle_uid = bundle['metadata']['uid']
    if len(daemon['spec']['template']['spec']['containers']) != 1:
        raise ValueError('This helper requires the verified single-container daemon Deployment')
    hpas = run('get', 'hpa', '-o', 'json', read=True)
    if any(i['spec']['scaleTargetRef']['name'] in (args.web, args.daemon) for i in hpas['items']):
        raise ValueError('Resolve HPA ownership before release maintenance')
    name = 'tessera-release-' + str(int(time.time()))
    manifest = job(web, args.container, args.image, name, args.namespace, args.upgrade_bundle_pvc)
    for label, value in (('web-before', web), ('daemon-before', daemon), ('upgrade-job', manifest)):
        path = state / (label + '.json')
        with path.open('x', encoding='utf-8') as out:
            os.chmod(path, 0o600)
            json.dump(value, out, indent=2)
    # Validate the exact Job with the API before reducing availability.
    run('create', '--dry-run=server', '-f', str(state / 'upgrade-job.json'), '-o', 'name')
    def read_lock():
        raw = subprocess.check_output(['kubectl', '-n', args.namespace, 'get', 'configmap', LOCK_NAME,
                                       '--ignore-not-found', '-o', 'json'], text=True)
        return json.loads(raw) if raw.strip() else None
    owner = uuid.uuid4().hex
    previous_lock = read_lock()
    locked = maintenance_lock(previous_lock, args.namespace, owner, 'LOCKED')
    lock_file = state / 'maintenance-lock.json'
    with lock_file.open('x', encoding='utf-8') as out:
        os.chmod(lock_file, 0o600)
        json.dump(locked, out, indent=2)
    # Atomic create or resourceVersion-checked replace holds ownership through
    # image activation, not just the database Job. No expiry/automatic takeover.
    run('replace' if previous_lock else 'create', '-f', str(lock_file))
    for deployment, original in ((args.web, web), (args.daemon, daemon)):
        run('scale', 'deployment/' + deployment, '--replicas=0')
        old_pods = workload_pods(run('get', 'pods', '-l', selector(original), '-o', 'json', read=True)['items'])
        if old_pods:
            run('wait', '--for=delete', *['pod/' + p['metadata']['name'] for p in old_pods], '--timeout=600s')
        remaining = workload_pods(run('get', 'pods', '-l', selector(original), '-o', 'json', read=True)['items'])
        if remaining:
            raise ValueError('Old Pods still exist; no upgrade has been started')
    # No automatic rollback/resume on failure; the private state files provide
    # the original images/replicas and the exact failed Job for recovery.
    run('create', '-f', str(state / 'upgrade-job.json'))
    run('wait', '--for=condition=complete', 'job/' + name, '--timeout=1800s')
    for deployment, original in ((args.web, web), (args.daemon, daemon)):
        if len(original['spec']['template']['spec']['containers']) != 1:
            raise ValueError('Expected verified single-container Deployment')
        container = original['spec']['template']['spec']['containers'][0]['name']
        run('set', 'image', 'deployment/' + deployment, container + '=' + args.image)
        run('scale', 'deployment/' + deployment, '--replicas=' + str(original['spec'].get('replicas', 1)))
        run('rollout', 'status', 'deployment/' + deployment, '--timeout=600s')
    held = read_lock()
    maintenance_lock(held, args.namespace, owner, 'READY')  # verify ownership before cleanup
    if held['data'].get('phase') != 'LOCKED':
        raise ValueError('Maintenance must remain locked until cleanup finishes')
    if args.cleanup_bundle:
        cleanup_bundle(['kubectl', '-n', args.namespace], state, name, args.container, args.upgrade_bundle_pvc, bundle_uid)
    ready = maintenance_lock(read_lock(), args.namespace, owner, 'READY')
    with (state / 'maintenance-ready.json').open('x', encoding='utf-8') as out:
        os.chmod(state / 'maintenance-ready.json', 0o600)
        json.dump(ready, out, indent=2)
    run('replace', '-f', str(state / 'maintenance-ready.json'))
    print('Release Job completed and images activated. Run portal/API/daemon acceptance. State:', state)


if __name__ == '__main__':
    try:
        main()
    except Exception:
        raise SystemExit('Release deployment stopped. Inspect the saved private state and Kubernetes Job; no automatic rollback or retry was attempted.') from None
