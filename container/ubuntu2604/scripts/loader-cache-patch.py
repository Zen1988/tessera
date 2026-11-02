#!/usr/bin/env python3
"""Generate a narrow strategic merge patch from a Deployment; never apply it."""
import argparse
import json
import re
import sys

VOLUME = 'tessera-loader-cache'
INIT = 'tessera-loader-cache-init'
HOME = '/opt/otobo/var/httpd/htdocs'


def generate(deployment, container=None, claim=VOLUME, uid=10001, gid=33, skins=()):
    if deployment.get('kind') != 'Deployment':
        raise ValueError('Input must be a Deployment JSON document')
    pod = deployment['spec']['template']['spec']
    containers = pod['containers']
    candidates = [c for c in containers if c['name'] == container] if container else (
        [c for c in containers if c.get('args', [])[:1] == ['web']] or containers)
    if len(candidates) != 1:
        raise ValueError('Specify --container with the existing web container name')
    web = candidates[0]
    if not web.get('image'):
        raise ValueError('Existing web image is missing')
    if not re.fullmatch(r'[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?', claim) or len(claim) > 253:
        raise ValueError('Invalid PVC name')
    if uid <= 0 or gid <= 0:
        raise ValueError('Use nonroot runtime UID/GID')
    context = dict(pod.get('securityContext', {}), **web.get('securityContext', {}))
    if context.get('runAsUser', uid) != uid or context.get('runAsGroup', gid) != gid:
        raise ValueError('Existing runtime UID/GID differs; use matching --uid/--gid')
    for volume in pod.get('volumes', []):
        if volume['name'] == VOLUME and volume.get('persistentVolumeClaim', {}).get('claimName') != claim:
            raise ValueError('Reserved volume name already refers to another volume; review before changing it')
    paths = [(f'{HOME}/js/js-cache', 'js')]
    for skin in dict.fromkeys(['Agent/default', 'Customer/default', *skins]):
        if not re.fullmatch(r'(Agent|Customer)/[A-Za-z0-9][A-Za-z0-9_-]*', skin):
            raise ValueError('Skin must be Agent/name or Customer/name, without traversal')
        paths.append((f'{HOME}/skins/{skin}/css-cache', 'css-' + skin.replace('/', '-')))
    directories = ' '.join('/loader-cache/' + subpath for _, subpath in paths)
    command = (f'umask 027; mkdir -p {directories}; '
               f'for path in {directories}; do '
               'test -d "$path" && test -w "$path" && test -x "$path" || '
               '{ echo "TESSERA: Shared loader cache access denied; check PVC ownership/fsGroup" >&2; exit 1; }; done')
    # Keep the application image, config/secret mounts, args, resources, probes,
    # labels, replicas and public routing. Only cache mounts are replaced by path.
    return {'spec': {'template': {'spec': {
        'securityContext': {'fsGroup': pod.get('securityContext', {}).get('fsGroup', gid),
                            'fsGroupChangePolicy': pod.get('securityContext', {}).get('fsGroupChangePolicy', 'OnRootMismatch')},
        'initContainers': [{
            'name': INIT, 'image': web['image'],
            'imagePullPolicy': web.get('imagePullPolicy', 'IfNotPresent'),
            'command': ['/bin/sh', '-ec'], 'args': [command],
            'securityContext': {'runAsNonRoot': True, 'runAsUser': uid, 'runAsGroup': gid,
                                'allowPrivilegeEscalation': False, 'readOnlyRootFilesystem': True,
                                'capabilities': {'drop': ['ALL']},
                                'seccompProfile': {'type': 'RuntimeDefault'}},
            'resources': {'requests': {'cpu': '10m', 'memory': '16Mi'},
                          'limits': {'cpu': '100m', 'memory': '64Mi'}},
            'volumeMounts': [{'name': VOLUME, 'mountPath': '/loader-cache', 'readOnly': False}],
        }],
        'containers': [{'name': web['name'], 'volumeMounts': [
            {'name': VOLUME, 'mountPath': path, 'subPath': subpath,
             'subPathExpr': None, 'readOnly': False} for path, subpath in paths]}],
        'volumes': [{'name': VOLUME, 'persistentVolumeClaim': {'claimName': claim}}],
    }}}}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--container')
    parser.add_argument('--claim', default=VOLUME)
    parser.add_argument('--uid', type=int, default=10001)
    parser.add_argument('--gid', type=int, default=33)
    parser.add_argument('--skin', action='append', default=[])
    args = parser.parse_args()
    try:
        deployment = json.load(sys.stdin)
        result = generate(deployment, args.container, args.claim, args.uid, args.gid, args.skin)
        json.dump(result, sys.stdout, indent=2)
        sys.stdout.write('\n')
    except (ValueError, KeyError, TypeError):
        # Input Deployment may contain secrets; do not echo it or exception values.
        print('TESSERA: Cannot generate cache patch; check Deployment/container/UID/GID/PVC/skin inputs.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
