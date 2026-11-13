import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('resume_before', ROOT / 'container/ubuntu2604/scripts/resume-before-upgrade.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class Resume(unittest.TestCase):
    def exercise(self, failure=None):
        snapshots = []
        for kind, replicas in [('web', 3), ('daemon', 1)]:
            snapshots.append({'metadata': {'name': 'tessera-' + kind, 'uid': kind},
                              'spec': {'replicas': replicas, 'selector': {'matchLabels': {'app': 'tessera-' + kind}},
                                       'template': {'spec': {'containers': [{'name': 'tessera-' + kind, 'image': 'old195'}]}}}})
        saved = {'metadata': {'name': 'planned-upgrade', 'namespace': 'tessera'}, 'spec': {'backoffLimit': 0, 'template': {
            'metadata': {'labels': {'app': 'tessera-web', 'tessera-release-upgrade': 'planned-upgrade'}},
            'spec': {'initContainers': [{'name': 'stage-upgrade'}],
                     'containers': [{'name': 'tessera-web', 'image': 'new196', 'args': ['upgrade'],
                                     'env': [{'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}],
                                     'volumeMounts': [{'name': 'tessera-upgrade-bundle', 'mountPath': '/opt/tessera/upgrade-bundle', 'readOnly': True}]}],
                     'volumes': [{'name': 'tessera-upgrade-bundle', 'persistentVolumeClaim': {'claimName': 'bundle'}}]}}}}
        lock = {'metadata': {'resourceVersion': '1', 'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}},
                'data': {'owner': 'original', 'phase': 'LOCKED'}}
        pvc = {'metadata': {'uid': 'bundle-uid', 'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper', 'tessera-upgrade-bundle': 'true'}}}
        calls = []
        created = False
        old_evidence = {'metadata': {'name': 'failed-evidence', 'labels': {'tessera-release-upgrade': 'old'}, 'ownerReferences': [{'kind': 'Job'}]},
                        'status': {'phase': 'Failed', 'containerStatuses': [{'state': {'terminated': {'exitCode': 25}}}]}}
        def read(command, **kw):
            kind = command[4]
            if kind == 'job':
                if not created and failure != 'existing':
                    return ''
                return json.dumps({'status': {'conditions': [{'type': 'Failed' if failure == 'native' else 'Complete', 'status': 'True'}]}})
            if kind == 'jobs':
                value = {'items': []}
            elif kind == 'configmap':
                value = lock
            elif kind == 'deployment':
                value = copy.deepcopy(next(d for d in snapshots if d['metadata']['name'] == command[5]))
                value['spec']['replicas'] = 0 if command[5] == 'tessera-web' else 1
            elif kind == 'hpa':
                value = {'items': []}
            elif kind == 'pvc':
                value = pvc
            elif kind == 'pods':
                value = {'items': [old_evidence]}
            else:
                raise AssertionError(command)
            return json.dumps(value)
        def run(command, **kw):
            nonlocal created
            calls.append(command)
            if command[3] == 'replace':
                lock.clear()
                lock.update(json.loads(kw['input']))
            if command[3] == 'create' and '--dry-run=server' not in command:
                created = True
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            state = Path(temp)
            for filename, value in [('upgrade-job.json', saved), ('maintenance-lock.json', lock), ('web-before.json', snapshots[0]), ('daemon-before.json', snapshots[1])]:
                (state / filename).write_text(json.dumps(value))
            with patch('sys.argv', ['resume', '--state-directory', temp]), patch.object(m, 'active_runners', return_value=['123'] if failure == 'runner' else []), patch.object(m.subprocess, 'check_output', side_effect=read), patch.object(m.subprocess, 'run', side_effect=run), patch.object(m.helper, 'cleanup_bundle') as cleanup:
                if failure:
                    with self.assertRaises(ValueError):
                        m.main()
                    cleanup.assert_not_called()
                else:
                    m.main()
                    cleanup.assert_called_once()
        self.assertEqual(lock['data']['phase'], 'READY' if not failure else 'LOCKED')
        activations = [c for c in calls if c[3] == 'set']
        self.assertEqual(len(activations), 0 if failure else 2)
        if not failure:
            self.assertTrue(any('--replicas=3' in c for c in calls))
            self.assertTrue(any('--replicas=1' in c for c in calls))
            self.assertFalse(any('wait' in c and '--for=delete' in c for c in calls), 'old terminated Job evidence must not block')
        if failure in ('runner', 'existing'):
            self.assertFalse(any(c[3] in ('replace', 'create', 'scale', 'set') for c in calls))

    def test_resume_restores_saved_three_web_one_daemon(self):
        self.exercise()

    def test_existing_job_refuses_replay(self):
        self.exercise('existing')

    def test_active_original_runner_refuses_takeover(self):
        self.exercise('runner')

    def test_native_failure_preserves_claim_and_never_activates(self):
        self.exercise('native')


if __name__ == '__main__':
    unittest.main()
