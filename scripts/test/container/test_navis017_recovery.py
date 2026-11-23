import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('navis_resume017', ROOT / 'container/ubuntu2604/scripts/recover-navis017.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class ResumeConfig(unittest.TestCase):
    def exercise(self, failure=None):
        image = 'docker.io/library/tessera:0.1.7-ubuntu26.04'
        snapshots = [{'metadata': {'name': 'tessera-'+kind, 'uid': kind}, 'spec': {
            'replicas': replicas, 'selector': {'matchLabels': {'app': 'tessera-'+kind}},
            'template': {'spec': {'containers': [{'name': 'tessera-'+kind, 'image': 'old196'}]}}}}
            for kind, replicas in [('web', 3), ('daemon', 1)]]
        saved = {'metadata': {'name': 'tessera-release-1795404303', 'namespace': 'tessera'}, 'spec': {'backoffLimit': 0, 'template': {
            'metadata': {'labels': {'app': 'tessera-web', 'tessera-release-upgrade': 'tessera-release-1795404303'}}, 'spec': {
            'initContainers': [{'name': 'stage-upgrade'}], 'containers': [{'name': 'tessera-web', 'image': image,
                'args': ['upgrade'], 'env': [{'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}],
                'volumeMounts': [{'name': 'tessera-upgrade-bundle', 'mountPath': '/opt/tessera/upgrade-bundle', 'readOnly': True}]}],
            'volumes': [{'name': 'tessera-upgrade-bundle', 'persistentVolumeClaim': {'claimName': 'bundle'}}]}}}}
        failed = copy.deepcopy(saved);failed['status'] = {'conditions': [{'type': 'Failed', 'status': 'True'}]}
        lock = {'metadata': {'resourceVersion': '1', 'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}}, 'data': {'phase': 'LOCKED', 'owner': 'old-owner'}}
        initial_lock = copy.deepcopy(lock)
        calls = []
        class FakeClient:
            prefix = ['kubectl', '-n', 'tessera']
            def get(self, *args):
                if args[0] == 'job':
                    if args[1] == 'tessera-release-1795404303': return copy.deepcopy(failed)
                    if failure == 'ownership-after-job': lock['data']['owner'] = 'other'
                    return {'status': {'conditions': [{'type': 'Failed' if failure == 'native' else 'Complete', 'status': 'True'}]}}
                if args[0] == 'jobs': return {'items': [failed] if failure != 'active' else [dict(failed, status={'active': 1})]}
                if args[0] == 'configmap': return copy.deepcopy(lock)
                if args[0] == 'deployment':
                    d = copy.deepcopy(next(x for x in snapshots if x['metadata']['name'] == args[1]));d['spec']['replicas'] = 1 if failure == 'writers' else 0;return d
                if args[0] in ('pods', 'hpa'): return {'items': []}
                if args[0] == 'pvc': return {'metadata': {'uid': 'bundle-uid', **({'deletionTimestamp': 'now'} if failure == 'pvc' else {})}}
                raise AssertionError(args)
            def write(self, obj, verb='create', dry=False):
                calls.append(('write', verb, dry, copy.deepcopy(obj)))
                if verb == 'replace': lock.clear();lock.update(copy.deepcopy(obj))
            def run(self, *args): calls.append(('run', *args))
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            state = Path(temp)
            for name, value in [('upgrade-job.json', saved), ('maintenance-lock.json', initial_lock), ('web-before.json', snapshots[0]), ('daemon-before.json', snapshots[1])]:
                (state / name).write_text(json.dumps(value))
            if failure == 'ownership': lock['data']['owner'] = 'different'
            cleanup = []
            with patch.object(m.before, 'active_runners', return_value=[]):
                def run(): m.resume(FakeClient(), state, 'tessera-release-1795404303', ROOT / 'container/ubuntu2604/image/configure.py', cleanup=lambda *a: cleanup.append(a))
                if failure:
                    with self.assertRaises(ValueError): run()
                else:
                    run()
                    self.assertEqual(lock['data']['phase'], 'READY')
                    self.assertEqual([c[-1] for c in calls if c[:2] == ('run','scale')], ['--replicas=3','--replicas=1'])
                    self.assertEqual(len(cleanup), 0)
                    jobs = [c[3] for c in calls if c[:3] == ('write', 'create', False) and c[3]['kind']=='Job']
                    self.assertEqual(len(jobs), 1)
                    pod = jobs[0]['spec']['template']['spec'];code = pod['containers'][0]['args'][0]
                    self.assertIn('recover-navis017.pl', code)
                    self.assertIn('Navis017Recovery.pm', str(pod['volumes']))
                    self.assertIn('ApplicationNavisInstaller.pm', str(pod['volumes']))
                    self.assertNotIn('PackageUpgrade(', code)
                    self.assertTrue(pod['containers'][0]['volumeMounts'][-1]['readOnly'])
                    self.assertEqual(pod['containers'][0]['image'], image)
                    with self.assertRaises((ValueError, FileExistsError)): run()  # no automatic repeat
            if failure:
                self.assertFalse(any(c[:2] in [('run','set'),('run','scale')] for c in calls))
                self.assertEqual(lock['data']['phase'], 'LOCKED')
            if failure in ('ownership','active','writers','pvc'): self.assertEqual(calls, [])

    def test_success_restores_exact_saved_counts_without_hooks(self): self.exercise()
    def test_changed_owner_stops_before_mutation(self): self.exercise('ownership')
    def test_active_release_stops_before_mutation(self): self.exercise('active')
    def test_application_writers_stop_before_mutation(self): self.exercise('writers')
    def test_deleting_current_bundle_stops_before_mutation(self): self.exercise('pvc')
    def test_configuration_failure_keeps_lock_and_never_activates(self): self.exercise('native')
    def test_owner_change_after_job_prevents_activation(self): self.exercise('ownership-after-job')

if __name__ == '__main__': unittest.main()
