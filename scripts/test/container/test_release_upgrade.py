import base64
import copy
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
KIT = ROOT / 'container/ubuntu2604'


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


stage = module('upgrade_stage', KIT / 'image/upgrade-stage.py')
deploy = module('upgrade_deploy', KIT / 'scripts/upgrade-deploy.py')
release = module('upgrade_release', KIT / 'scripts/release.py')


def deployment():
    return {'spec': {'replicas': 2, 'selector': {'matchLabels': {'app': 'web'}},
        'template': {'metadata': {'labels': {'app': 'web'}}, 'spec': {
            'securityContext': {'runAsUser': 10001, 'fsGroup': 33},
            'serviceAccountName': 'existing-sa', 'nodeSelector': {'purpose': 'existing'},
            'volumes': [{'name': 'config', 'secret': {'secretName': 'target-config'}},
                        {'name': 'generated', 'persistentVolumeClaim': {'claimName': 'existing-rwx'}}],
            'containers': [{'name': 'web', 'image': 'old:180', 'imagePullPolicy': 'Never',
                'securityContext': {'readOnlyRootFilesystem': True},
                'env': [{'name': 'UNCHANGED', 'value': 'yes'}],
                'ports': [{'containerPort': 8443}], 'readinessProbe': {'exec': {'command': ['ready']}},
                'volumeMounts': [{'name': 'config', 'mountPath': '/opt/otobo/Kernel/Config.pm', 'subPath': 'Config.pm', 'readOnly': True},
                    {'name': 'generated', 'mountPath': '/opt/otobo/Kernel/Config/Files'}]}]}}}}


class UpgradeTest(unittest.TestCase):
    def test_stage_copies_code_not_host_config_and_is_writable(self):
        with tempfile.TemporaryDirectory() as d:
            source, target = Path(d) / 'source', Path(d) / 'destination'
            (source / 'Kernel').mkdir(parents=True)
            (source / 'bin').mkdir()
            (source / 'Kernel/Config.pm').write_text('target secret fixture')
            (source / 'Kernel/Code.pm').write_text('code')
            (source / 'bin/otobo.Console.pl').write_text('console')
            (source / 'local/lib/perl5/Crypt').mkdir(parents=True)
            (source / 'local/lib/perl5/Crypt/JWT.pm').write_text('image-built dependency')
            (source / 'local/bin').mkdir()
            (source / 'local/bin/dependency-tool').write_text('tool')
            stage.stage(source, target)
            self.assertEqual((target / 'local/lib/perl5/Crypt/JWT.pm').read_text(), 'image-built dependency')
            self.assertEqual((target / 'local/bin/dependency-tool').read_text(), 'tool')
            if os.name != 'nt':
                self.assertEqual((target / 'local/bin/dependency-tool').stat().st_mode & 0o777, 0o750)
                self.assertEqual((target / 'local/lib/perl5/Crypt/JWT.pm').stat().st_mode & 0o777, 0o640)
            self.assertFalse((target / 'Kernel/Config.pm').exists())
            self.assertEqual((target / 'Kernel/Code.pm').read_text(), 'code')
            self.assertTrue(os.access(target / 'Kernel/Code.pm', os.W_OK))
            with self.assertRaises(ValueError):
                stage.stage(source, target)

    def test_job_uses_writable_workspace_and_existing_target_mounts(self):
        original = deployment()
        before = copy.deepcopy(original)
        j = deploy.job(original, 'web', 'tessera:182', 'release-test', 'tessera')
        self.assertEqual(original, before)
        pod = j['spec']['template']['spec']
        self.assertEqual(j['spec']['backoffLimit'], 0)
        self.assertEqual(pod['restartPolicy'], 'Never')
        self.assertEqual(pod['containers'][0]['args'], ['upgrade'])
        self.assertNotIn('readinessProbe', pod['containers'][0])
        self.assertEqual(pod['securityContext'], before['spec']['template']['spec']['securityContext'])
        self.assertEqual(pod['serviceAccountName'], 'existing-sa')
        self.assertTrue(pod['containers'][0]['securityContext']['readOnlyRootFilesystem'])
        self.assertEqual(pod['initContainers'][0]['volumeMounts'], [{'name': 'tessera-upgrade-work', 'mountPath': '/work/application'}])
        self.assertNotIn('env', pod['initContainers'][0])
        self.assertEqual(pod['containers'][0]['volumeMounts'][1:], before['spec']['template']['spec']['containers'][0]['volumeMounts'])

    def test_job_refuses_missing_target_mounts_and_sidecars(self):
        for change in ('mount', 'sidecar', 'root'):
            d = deployment()
            if change == 'mount':
                d['spec']['template']['spec']['containers'][0]['volumeMounts'] = []
            elif change == 'sidecar':
                d['spec']['template']['spec']['containers'].append({'name': 'unverified'})
            else:
                d['spec']['template']['spec']['containers'][0]['volumeMounts'].append({'name': 'root', 'mountPath': '/opt/otobo'})
            with self.assertRaises(ValueError):
                deploy.job(d, 'web', 'new:182', 'test', 'tessera')

    def test_bundle_exports_only_package_and_checks_every_payload(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'var/governancedb').mkdir(parents=True)
            descriptor = {'package': 'TESSERA-Base', 'version': '0.0.182', 'upgrade_from': ['0.0.180', '0.0.181']}
            (root / 'var/governancedb/container_release.json').write_text(json.dumps(descriptor))
            (root / 'code.pm').write_bytes(b'code')
            output = root / 'release.json'
            package = '<otobo_package><Name>TESSERA-Base</Name><Version>0.0.182</Version><Filelist><File Location="code.pm" Encode="Base64">' + base64.b64encode(b'code').decode() + '</File></Filelist></otobo_package>'
            def export(*args, **kwargs):
                (root / 'package.opm').write_text(package)
            with patch.object(release.subprocess, 'run', side_effect=export):
                bundle = release.upgrade_bundle(root, '0.0.182', output)
                self.assertEqual(len(bundle['package_sha256']), 64)
                self.assertEqual(bundle['upgrade_from'], ['0.0.180', '0.0.181'])
                (root / 'code.pm').write_text('different')
                with self.assertRaises(ValueError):
                    release.upgrade_bundle(root, '0.0.182', output)

    def test_selector_rejects_unhandled_expressions(self):
        d = deployment()
        self.assertEqual(deploy.selector(d), 'app=web')
        d['spec']['selector']['matchExpressions'] = [{'key': 'x'}]
        with self.assertRaises(ValueError):
            deploy.selector(d)

    def test_deployment_failure_leaves_writers_stopped_and_saved_state(self):
        with tempfile.TemporaryDirectory() as d:
            calls = []
            def read(command, **kwargs):
                if command[3:5] == ['get', 'configmap']:
                    return ''
                if command[3:5] == ['get', 'hpa'] or command[3:5] == ['get', 'pods']:
                    return json.dumps({'items': []})
                result = deployment()
                if command[5] == 'daemon':
                    result['spec']['replicas'] = 1
                    result['spec']['selector']['matchLabels'] = {'app': 'daemon'}
                    result['spec']['template']['spec']['containers'][0]['name'] = 'daemon'
                return json.dumps(result)
            def run(command, **kwargs):
                calls.append(command)
                if '--for=condition=complete' in command:
                    raise subprocess.CalledProcessError(1, command)
            arguments = ['upgrade-deploy.py', '--namespace', 'tessera', '--web', 'web', '--daemon', 'daemon',
                '--container', 'web', '--image', 'tessera:0.0.182-ubuntu26.04', '--state-directory', str(Path(d) / 'state')]
            with patch.object(sys, 'argv', arguments), patch.object(deploy.subprocess, 'check_output', side_effect=read), patch.object(deploy.subprocess, 'run', side_effect=run):
                with self.assertRaises(subprocess.CalledProcessError):
                    deploy.main()
            self.assertTrue((Path(d) / 'state/upgrade-job.json').is_file())
            self.assertEqual(sum('--replicas=0' in c for c in calls), 2)
            self.assertFalse(any('image' in c for c in calls))
            self.assertFalse(any('--replicas=2' in c or '--replicas=1' in c for c in calls))
            self.assertTrue((Path(d) / 'state/maintenance-lock.json').is_file())
            self.assertFalse((Path(d) / 'state/maintenance-ready.json').exists())

    def test_maintenance_lock_has_no_automatic_takeover(self):
        lock = deploy.maintenance_lock(None, 'tessera', 'first', 'LOCKED')
        lock['metadata']['resourceVersion'] = '10'
        with self.assertRaises(ValueError):
            deploy.maintenance_lock(lock, 'tessera', 'second', 'LOCKED')
        with self.assertRaises(ValueError):
            deploy.maintenance_lock(lock, 'tessera', 'second', 'READY')
        ready = deploy.maintenance_lock(lock, 'tessera', 'first', 'READY')
        ready['metadata']['resourceVersion'] = '11'
        second = deploy.maintenance_lock(ready, 'tessera', 'second', 'LOCKED')
        self.assertEqual(second['metadata']['resourceVersion'], '11')
        self.assertEqual(second['data']['owner'], 'second')

    def test_completed_upgrade_evidence_does_not_block_repeat_deployment(self):
        completed = {'metadata': {'name': 'old-upgrade', 'labels': {'tessera-release-upgrade': 'old'}, 'ownerReferences': [{'kind': 'Job'}]}, 'status': {'phase': 'Succeeded'}}
        live = {'metadata': {'name': 'live-web'}, 'status': {'phase': 'Running'}}
        failed = copy.deepcopy(completed)
        failed['status']['phase'] = 'Failed'
        self.assertEqual(deploy.workload_pods([completed, live, failed]), [live, failed])


if __name__ == '__main__':
    unittest.main()
