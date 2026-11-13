#!/usr/bin/env python3
"""Upload the separate OPM bundle to a dedicated temporary upgrade PVC."""
import argparse
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile
import uuid

KIT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('bundle_check', KIT / 'image/check-package-bundle.py')
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)

# No shell, host paths or source configuration is accepted by the receiver.
RECEIVE = '''import pathlib,re,sys,tarfile
root=pathlib.Path('/bundle/upgrade')
root.mkdir(mode=0o750,exist_ok=False)
with tarfile.open(fileobj=sys.stdin.buffer,mode='r|') as archive:
 for item in archive:
  if not item.isfile() or not re.fullmatch(r'(release.json|package-modules.json|package.opm|packages/[a-f0-9]{64}\\.opm)',item.name):
   raise ValueError('Invalid bundle entry')
  target=root/item.name
  target.parent.mkdir(mode=0o750,parents=True,exist_ok=True)
  with target.open('xb') as output:
   source=archive.extractfile(item)
   import shutil
   shutil.copyfileobj(source,output)
'''


def bundle_files(directory):
    directory = Path(directory)
    if directory.is_symlink() or any(p.is_symlink() for p in directory.rglob('*')):
        raise ValueError('Bundle symlinks are forbidden')
    check.validate(directory)
    return [directory / name for name in ('release.json', 'package-modules.json')] + sorted((directory / 'packages').glob('*.opm'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('namespace', 'pvc', 'image', 'bundle'):
        parser.add_argument('--' + name, required=True)
    parser.add_argument('--uid', type=int, default=10001)
    parser.add_argument('--gid', type=int, default=33)
    parser.add_argument('--image-pull-secret', action='append', default=[])
    parser.add_argument('--verify-only', action='store_true', help='Validate a previously uploaded bundle without writing or overwriting it')
    args = parser.parse_args()
    for name in (args.namespace, args.pvc, *args.image_pull_secret):
        if not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', name):
            parser.error('Invalid Kubernetes name')
    files = bundle_files(args.bundle)
    name = 'tessera-bundle-upload-' + uuid.uuid4().hex[:12]
    pod = {'apiVersion': 'v1', 'kind': 'Pod', 'metadata': {'name': name, 'namespace': args.namespace},
           'spec': {'restartPolicy': 'Never', 'automountServiceAccountToken': False,
                    'securityContext': {'runAsUser': args.uid, 'runAsGroup': args.gid, 'fsGroup': args.gid, 'runAsNonRoot': True},
                    'containers': [{'name': 'upload', 'image': args.image,
                                    'command': ['/usr/bin/python3', '-c', 'import time;time.sleep(1800)'],
                                    'securityContext': {'readOnlyRootFilesystem': True, 'allowPrivilegeEscalation': False, 'capabilities': {'drop': ['ALL']}},
                                    'volumeMounts': [{'name': 'bundle', 'mountPath': '/bundle'}]}],
                    'volumes': [{'name': 'bundle', 'persistentVolumeClaim': {'claimName': args.pvc}}]}}
    prefix = ['kubectl', '-n', args.namespace]
    if args.image_pull_secret:
        pod['spec']['imagePullSecrets'] = [{'name': name} for name in args.image_pull_secret]
    subprocess.run(prefix + ['create', '-f', '-'], input=json.dumps(pod), text=True, check=True)
    try:
        subprocess.run(prefix + ['wait', '--for=condition=Ready', 'pod/' + name, '--timeout=180s'], check=True)
        if not args.verify_only:
            with tempfile.TemporaryFile() as stream:
                with tarfile.open(fileobj=stream, mode='w') as archive:
                    for path in files:
                        archive.add(path, arcname=path.relative_to(args.bundle).as_posix(), recursive=False)
                stream.seek(0)
                subprocess.run(prefix + ['exec', '-i', name, '--', '/usr/bin/python3', '-c', RECEIVE], stdin=stream, check=True)
        subprocess.run(prefix + ['exec', name, '--', '/usr/bin/python3', '/usr/local/lib/tessera/check-package-bundle.py', '/bundle/upgrade', '/opt/tessera/dependencies'], check=True)
    finally:
        subprocess.run(prefix + ['delete', 'pod', name, '--wait=true'], check=False)
    print('Bundle uploaded. Pass --upgrade-bundle-pvc', args.pvc, 'to upgrade-deploy.py. Retain PVC until acceptance/recovery is complete.')


if __name__ == '__main__':
    main()
