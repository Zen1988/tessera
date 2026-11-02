import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('recovery179', ROOT / 'container/ubuntu2604/scripts/recover-179-to-184.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class Recovery(unittest.TestCase):
    def exercise(self, fail=False):
        labels = {'app': 'web', 'tessera-release-upgrade': 'old'}
        pod = {'containers': [{'name': 'tessera-web', 'image': 'docker.io/library/tessera:0.0.184-ubuntu26.04',
                'args': ['upgrade'], 'env': [{'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}]}],
               'initContainers': [{'name': 'stage-upgrade'}]}
        old = {'metadata': {'name': 'old', 'namespace': 'tessera'},
               'spec': {'template': {'metadata': {'labels': labels}, 'spec': pod}},
               'status': {'conditions': [{'type': 'Failed', 'status': 'True'}]}}
        lock = {'metadata': {'name': 'tessera-release-maintenance', 'resourceVersion': '1',
                  'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}},
                'data': {'owner': 'original', 'phase': 'LOCKED'}}
        deployments = []
        for name, count in [('web', 3), ('daemon', 1)]:
            deployments.append({'metadata': {'name': 'tessera-' + name, 'uid': name},
                'spec': {'replicas': count, 'selector': {'matchLabels': {'app': name}},
                         'template': {'spec': {'containers': [{'name': 'tessera-' + name}]}}}})
        calls = []
        def get(command, **kwargs):
            kind = command[4]
            if kind == 'configmap': result = lock
            elif kind == 'deployment': result = next(d for d in deployments if d['metadata']['name'] == command[5])
            elif kind == 'jobs': result = {'items': [old]}
            elif kind in ('pods', 'hpa'): result = {'items': []}
            elif kind == 'job':
                result = old if command[5] == 'old' else {'status': {'conditions': [{'type': 'Failed' if fail else 'Complete', 'status': 'True'}]}}
            else: raise AssertionError(command)
            return json.dumps(result)
        def run(command, **kwargs):
            calls.append(command)
            if command[3] == 'replace':
                lock.clear();lock.update(json.loads(kwargs['input']))
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as directory:
            state = Path(directory)
            for name, value in [('upgrade-job.json', old), ('maintenance-lock.json', lock),
                                ('web-before.json', deployments[0]), ('daemon-before.json', deployments[1])]:
                (state / name).write_text(json.dumps(copy.deepcopy(value)))
            with patch('sys.argv', ['recovery', '--state-directory', directory]), patch.object(m.subprocess, 'check_output', get), patch.object(m.subprocess, 'run', run):
                if fail:
                    with self.assertRaisesRegex(ValueError, 'Recovery Job failed'): m.main()
                else: m.main()
        self.assertFalse(any('delete' in call for call in calls))
        create = next(i for i, call in enumerate(calls) if call[3] == 'create' and '--dry-run=server' not in call)
        self.assertEqual(sum(call[3] == 'scale' and '--replicas=0' in call for call in calls[:create]), 2)
        activations = [call for call in calls if call[3] == 'set']
        self.assertEqual(len(activations), 0 if fail else 2)
        self.assertEqual(lock['data']['phase'], 'LOCKED' if fail else 'READY')

    def test_success_quiesces_then_activates(self): self.exercise()
    def test_failure_never_activates_or_unlocks(self): self.exercise(fail=True)


if __name__ == '__main__': unittest.main()
