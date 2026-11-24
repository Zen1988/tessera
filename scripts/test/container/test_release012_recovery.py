import base64
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('release012_recovery', ROOT / 'container/ubuntu2604/scripts/recover-release012.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class ResumeConfig(unittest.TestCase):
    def exercise(self, failure=None):
        image = 'docker.io/library/tessera:0.1.12-ubuntu26.04'
        snapshots = [{'metadata': {'name': 'tessera-'+kind, 'uid': kind}, 'spec': {
            'replicas': replicas, 'selector': {'matchLabels': {'app': 'tessera-'+kind}},
            'template': {'spec': {'containers': [{'name': 'tessera-'+kind, 'image': 'old196'}]}}}}
            for kind, replicas in [('web', 3), ('daemon', 1)]]
        saved = {'metadata': {'name': 'tessera-release-1795491815', 'namespace': 'tessera'}, 'spec': {'backoffLimit': 0, 'template': {
            'metadata': {'labels': {'app': 'tessera-web', 'tessera-release-upgrade': 'tessera-release-1795491815'}}, 'spec': {
            'initContainers': [{'name': 'stage-upgrade'}], 'containers': [{'name': 'tessera-web', 'image': image,
                'args': ['upgrade'], 'env': [{'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}],
                'volumeMounts': [{'name': 'tessera-upgrade-bundle', 'mountPath': '/opt/tessera/upgrade-bundle', 'readOnly': True}]}],
            'volumes': [{'name': 'tessera-upgrade-bundle', 'persistentVolumeClaim': {'claimName': 'bundle'}}]}}}}
        failed = copy.deepcopy(saved);failed['status'] = {'conditions': [{'type': 'Failed', 'status': 'True'}]}
        lock = {'metadata': {'resourceVersion': '1', 'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}}, 'data': {'phase': 'LOCKED', 'owner': 'old-owner'}}
        initial_lock = copy.deepcopy(lock)
        calls = []
        created = set()
        class FakeClient:
            prefix = ['kubectl', '-n', 'tessera']
            def get(self, *args):
                if args[0] == 'job':
                    if args[1] == 'tessera-release-1795491815': return copy.deepcopy(failed)
                    if failure == 'ownership-after-job': lock['data']['owner'] = 'other'
                    fail = (failure == 'native' and not args[1].endswith('-check')) or failure == 'preflight'
                    return {'status': {'conditions': [{'type': 'Failed' if fail else 'Complete', 'status': 'True'}]}}
                if args[0] == 'jobs': return {'items': [failed] if failure != 'active' else [dict(failed, status={'active': 1})]}
                if args[0] == 'configmap': return copy.deepcopy(lock)
                if args[0] == 'deployment':
                    d = copy.deepcopy(next(x for x in snapshots if x['metadata']['name'] == args[1]));d['spec']['replicas'] = 1 if failure == 'writers' else 0;return d
                if args[0] in ('pods', 'hpa'): return {'items': []}
                if args[0] == 'pvc': return {'metadata': {'uid': 'bundle-uid', **({'deletionTimestamp': 'now'} if failure == 'pvc' else {})}}
                raise AssertionError(args)
            def write(self, obj, verb='create', dry=False):
                identity=(obj.get('kind'),obj['metadata'].get('name'))
                if verb=='create' and identity in created:
                    raise ValueError('AlreadyExists')
                if verb=='create' and not dry: created.add(identity)
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
                def run(): m.resume(FakeClient(), state, 'tessera-release-1795491815', ROOT / 'container/ubuntu2604/image/configure.py', cleanup=lambda *a: cleanup.append(a))
                if failure:
                    with self.assertRaises(ValueError): run()
                else:
                    run()
                    self.assertEqual(lock['data']['phase'], 'READY')
                    self.assertEqual([c[-1] for c in calls if c[:2] == ('run','scale')], ['--replicas=3','--replicas=1'])
                    self.assertEqual(len(cleanup), 0)
                    jobs = [c[3] for c in calls if c[:3] == ('write', 'create', False) and c[3]['kind']=='Job']
                    self.assertEqual(len(jobs), 2)
                    self.assertTrue(any(e.get('name')=='TESSERA_RECOVERY_CHECK_ONLY' for e in jobs[0]['spec']['template']['spec']['containers'][0]['env']))
                    self.assertEqual(jobs[1]['spec']['activeDeadlineSeconds'],3600)
                    pod = jobs[1]['spec']['template']['spec'];code = base64.b64decode(pod['containers'][0]['args'][0]).decode()
                    self.assertIn('recover-release012.pl', code)
                    self.assertIn('upgrade-cache.pl', str(pod['volumes']))
                    self.assertIn('framework-11.1.1.json', str(pod['volumes']))
                    self.assertNotIn('PackageUpgrade(', code)
                    self.assertTrue(pod['containers'][0]['volumeMounts'][-1]['readOnly'])
                    self.assertEqual(pod['containers'][0]['image'], image)
                    with self.assertRaises((ValueError, FileExistsError)): run()  # no automatic repeat
            if failure:
                self.assertFalse(any(c[:2] in [('run','set'),('run','scale')] for c in calls))
                self.assertEqual(lock['data']['phase'], 'LOCKED')
            if failure in ('ownership','active','writers','pvc'): self.assertEqual(calls, [])

    def test_success_restores_exact_saved_counts_after_recovery_job(self): self.exercise()
    def test_changed_owner_stops_before_mutation(self): self.exercise('ownership')
    def test_active_release_stops_before_mutation(self): self.exercise('active')
    def test_application_writers_stop_before_mutation(self): self.exercise('writers')
    def test_deleting_current_bundle_stops_before_mutation(self): self.exercise('pvc')
    def test_configuration_failure_keeps_lock_and_never_activates(self): self.exercise('native')
    def test_owner_change_after_job_prevents_activation(self): self.exercise('ownership-after-job')
    def test_preflight_failure_does_not_transfer_or_activate(self): self.exercise('preflight')
    def test_unreviewed_job_refused(self):
        with self.assertRaises(ValueError):
            m.resume(None,Path('/unused'),'another-job',None)

class Preclaim(unittest.TestCase):
    def exercise(self, mode):
        name='tessera-release012-recovery-bbb4eb07c318'
        original={'metadata':{'uid':'original'},'spec':{'value':'same'}}
        manifest={'metadata':{'name':name},'spec':{'reviewed':True}}
        code={'metadata':{'name':name+'-code'},'data':{'source':'same'},'immutable':True}
        class Client:
            def get(self,*args):
                if args[0]=='jobs': return {'items':[{'metadata':{'name':name}}] if mode=='job-exists' else []}
                if args[0]=='job': return {'status':{'conditions':[{'type':'Complete','status':'True'}]},'spec':{'template':{'spec':{'containers':[{'env':[{'name':'TESSERA_RECOVERY_CHECK_ONLY','value':'1'}]}]}}}}
                if args[0]=='configmap': return dict(code,data={'changed':'code'}) if mode=='code-drift' else code
                raise AssertionError(args)
        with tempfile.TemporaryDirectory(dir=ROOT/'.artifacts') as temp:
            out=Path(temp)/'recover-release012';out.mkdir()
            for filename,value in [('failed-job.json',original),('upgrade-job.json',manifest),('bundle-pvc.json',{}),('rebuild-code.json',code)]:
                (out/filename).write_text(json.dumps(value))
            if mode=='claimed': (out/'maintenance-lock.json').write_text('{}')
            if mode=='success':
                m.preflight.preserve_unclaimed(Client(),out,original,lambda n:manifest)
                self.assertFalse(out.exists())
                self.assertEqual(len(list(Path(temp).glob('recover-release012-preclaim-r2-*'))),1)
            else:
                with self.assertRaises(ValueError): m.preflight.preserve_unclaimed(Client(),out,original,lambda n:manifest)
                self.assertTrue(out.exists())
    def test_preserves_only_exact_unclaimed_staging(self): self.exercise('success')
    def test_refuses_any_claim_or_existing_job_or_code_drift(self):
        for mode in ('claimed','job-exists','code-drift'):
            with self.subTest(mode=mode): self.exercise(mode)

if __name__ == '__main__': unittest.main()

