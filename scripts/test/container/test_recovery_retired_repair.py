import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import subprocess
import shutil
import os
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
spec = importlib.util.spec_from_file_location('recovery_retired_repair', ROOT / 'container/ubuntu2604/scripts/recover-retired-repair.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class Recovery(unittest.TestCase):
    def test_uninstall_contract_rejects_hooks_data_deletion_and_other_files(self):
        perl=shutil.which('perl')
        if not perl: self.skipTest('Perl unavailable')
        base={'Name': {'Content': 'TESSERAMELTCrossObjectRecovery'}, 'Version': {'Content': '0.0.1'},
              'Filelist': [{'Location': 'Kernel/System/TESSERA/MELTCrossObjectRecovery.pm'}]}
        cases=[(base,True)]
        for key,value in [('CodeUninstall',[]),('DatabaseUninstall',{}),('Filelist',[]),('Filelist',[{'Location':'Kernel/Config.pm'}]),('Name',{'Content':'Other'})]:
            changed=copy.deepcopy(base);changed[key]=value;cases.append((changed,False))
        program=m.CONTROL.split("my $Stage=",1)[0]+"my $R=JSON::PP->new->decode(do {local $/;<STDIN>});my $OK=eval {VerifyRepairRetirementContract($R);1};exit($OK?0:1);"
        for value,allowed in cases:
            result=subprocess.run([perl,'-e',program],input=json.dumps(value),text=True,capture_output=True,env={**os.environ,'PERL_BADLANG':'0'})
            self.assertEqual(result.returncode==0,allowed,result.stderr)

    def exercise(self, fail=False):
        labels = {'app': 'web', 'tessera-release-upgrade': 'tessera-release-1794548900'}
        pod = {'containers': [{'name': 'tessera-web', 'image': 'docker.io/library/tessera:0.0.195-r5-ubuntu26.04',
                'volumeMounts': [{'mountPath': '/opt/tessera/upgrade-bundle', 'readOnly': True}], 'args': ['upgrade'], 'env': [{'name': 'TESSERA_UPGRADE_QUIESCED', 'value': '1'}]}],
               'initContainers': [{'name': 'stage-upgrade'}]}
        old = {'metadata': {'name': 'tessera-release-1794548900', 'namespace': 'tessera'},
               'spec': {'template': {'metadata': {'labels': labels}, 'spec': pod}},
               'status': {'conditions': [{'type': 'Failed', 'status': 'True'}]}}
        lock = {'metadata': {'name': 'tessera-release-maintenance', 'resourceVersion': '1',
                  'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper'}},
                'data': {'owner': 'original', 'phase': 'LOCKED'}}
        deployments = []
        for name, count in [('web', 3), ('daemon', 1)]:
            deployments.append({'metadata': {'name': 'tessera-' + name, 'uid': name},
                'spec': {'replicas': count, 'selector': {'matchLabels': {'app': name}},
                         'template': {'spec': {'containers': [{'name': 'tessera-' + name, 'image': 'old194'}]}}}})
        calls = []
        def get(command, **kwargs):
            if command[3]=='logs': return 'repair_artifact_sha256=49fbcb650ae70940e5c250df0628e90b7018f0bf872ea9799fc8897bb65dd21f\nRecovery failed at preflight; preserve claims and Job.\nReviewed repair artifact differs.\n'
            kind = command[4]
            if kind == 'configmap': result = lock
            elif kind == 'deployment': result = next(d for d in deployments if d['metadata']['name'] == command[5])
            elif kind == 'jobs': result = {'items': [old]}
            elif kind in ('pods', 'hpa'): result = {'items': []}
            elif kind == 'job':
                result = old if command[5] in ('tessera-release-1794548900','first-recovery') else {'status': {'conditions': [{'type': 'Failed' if fail else 'Complete', 'status': 'True'}]}}
            else: raise AssertionError(command)
            result=copy.deepcopy(result)
            if kind=='deployment': result['spec']['replicas']=0
            return json.dumps(result)
        def run(command, **kwargs):
            calls.append(command)
            if command[3] == 'replace':
                lock.clear();lock.update(json.loads(kwargs['input']))
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as directory:
            state = Path(directory)
            previous=state/'recovery-retired-repair';previous.mkdir()
            (previous/'maintenance-lock.json').write_text(json.dumps(lock))
            previous_job=copy.deepcopy(old);previous_job['metadata']['name']='first-recovery'
            (previous/'job.json').write_text(json.dumps(previous_job))
            for name, value in [('upgrade-job.json', old), ('maintenance-lock.json', lock),
                                ('web-before.json', deployments[0]), ('daemon-before.json', deployments[1])]:
                (state / name).write_text(json.dumps(copy.deepcopy(value)))
            with patch('sys.argv', ['recovery', '--state-directory', directory]), patch.object(m.subprocess, 'check_output', get), patch.object(m.subprocess, 'run', run):
                if fail:
                    with self.assertRaisesRegex(ValueError, 'Recovery Job failed'): m.main()
                else: m.main()
        self.assertFalse(any('delete' in call for call in calls))
        create = next(i for i, call in enumerate(calls) if call[3] == 'create' and '--dry-run=server' not in call)
        self.assertEqual(sum(call[3] == 'scale' and '--replicas=0' in call for call in calls[:create]), 0)
        activations = [call for call in calls if call[3] == 'set']
        self.assertEqual(len(activations), 0 if fail else 2)
        self.assertEqual(lock['data']['phase'], 'LOCKED' if fail else 'READY')

    def test_success_retains_quiescence_then_restores_saved_replicas(self): self.exercise()
    def test_failure_never_activates_or_unlocks(self): self.exercise(fail=True)


if __name__ == '__main__': unittest.main()
