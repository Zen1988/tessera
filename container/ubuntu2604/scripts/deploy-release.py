#!/usr/bin/env python3
"""Deploy with a unique temporary bundle PVC and success-only cleanup."""
import argparse
from datetime import datetime, timezone
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import uuid

KIT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('bundle_check', KIT / 'image/check-package-bundle.py')
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', required=True)
    parser.add_argument('--namespace', default='tessera')
    parser.add_argument('--web', default='tessera-web')
    parser.add_argument('--daemon', default='tessera-daemon')
    parser.add_argument('--container', default='tessera-web')
    parser.add_argument('--bundle', type=Path, default=Path('artifacts/upgrade-bundle'))
    parser.add_argument('--storage-class')
    parser.add_argument('--storage', default='2Gi')
    parser.add_argument('--uid', type=int, default=10001)
    parser.add_argument('--gid', type=int, default=33)
    parser.add_argument('--image-pull-secret', action='append', default=[])
    args = parser.parse_args()
    for name in [args.namespace, args.web, args.daemon, args.container, *args.image_pull_secret] + ([args.storage_class] if args.storage_class else []):
        if not re.fullmatch(r'[a-z0-9][a-z0-9.-]*', name):
            parser.error('Invalid Kubernetes name')
    if not re.fullmatch(r'[a-z0-9][a-z0-9._:/@-]*(?:@sha256:[a-f0-9]{64}|:[0-9]+\.[0-9]+\.[0-9]+(?:-r[1-9][0-9]*)?-ubuntu26\.04)', args.image):
        parser.error('Use the versioned runtime image or pinned digest')
    if not re.fullmatch(r'[1-9][0-9]*(?:Mi|Gi|Ti)', args.storage):
        parser.error('Use a positive Mi/Gi/Ti storage request')
    check.validate(args.bundle)
    release = json.loads((args.bundle / 'release.json').read_text())
    version = release['version']
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', version):
        parser.error('Invalid prepared release version')
    suffix = uuid.uuid4().hex[:10]
    name = 'tessera-upgrade-bundle-' + suffix
    state = Path('artifacts') / ('deploy-' + version + '-' + datetime.now(timezone.utc).strftime('%Y%m%d-%H%M%S') + '-' + suffix)
    record = Path('artifacts') / ('bundle-' + suffix + '.json')
    record.parent.mkdir(parents=True, exist_ok=True)
    pvc = {'apiVersion': 'v1', 'kind': 'PersistentVolumeClaim',
           'metadata': {'name': name, 'namespace': args.namespace, 'labels': {
               'app.kubernetes.io/managed-by': 'tessera-release-helper', 'tessera-upgrade-bundle': 'true'}},
           'spec': {'accessModes': ['ReadWriteOnce'], 'resources': {'requests': {'storage': args.storage}}}}
    if args.storage_class:
        pvc['spec']['storageClassName'] = args.storage_class
    with record.open('x', encoding='utf-8') as output:
        os.chmod(output.name, 0o600)
        json.dump({'pvc': pvc, 'image': args.image, 'state_directory': str(state)}, output, indent=2)
    print('Temporary bundle PVC:', name, '\nDeployment state:', state, flush=True)
    try:
        subprocess.run(['kubectl', '-n', args.namespace, 'create', '-f', '-'], input=json.dumps(pvc), text=True, check=True)
        upload = [sys.executable, str(KIT / 'scripts/upload-upgrade-bundle.py'), '--namespace', args.namespace,
                  '--pvc', name, '--image', args.image, '--bundle', str(args.bundle), '--uid', str(args.uid), '--gid', str(args.gid)]
        for secret in args.image_pull_secret:
            upload += ['--image-pull-secret', secret]
        subprocess.run(upload, check=True)
        subprocess.run([sys.executable, str(KIT / 'scripts/upgrade-deploy.py'), '--namespace', args.namespace,
                        '--web', args.web, '--daemon', args.daemon, '--container', args.container,
                        '--image', args.image, '--upgrade-bundle-pvc', name,
                        '--state-directory', str(state), '--cleanup-bundle'], check=True)
    except Exception:
        print('Deployment/upload stopped. Retain PVC', name, 'and state/evidence', state, record)
        raise


if __name__ == '__main__':
    main()
