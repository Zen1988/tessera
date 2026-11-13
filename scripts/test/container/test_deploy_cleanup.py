import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
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


deploy = module('cleanup_deploy', KIT / 'scripts/upgrade-deploy.py')
release = module('unique_release', KIT / 'scripts/deploy-release.py')


class Cleanup(unittest.TestCase):
    def exercise(self, failure=None):
        calls = []
        pvc = {'metadata': {'uid': 'original-uid', 'labels': {'app.kubernetes.io/managed-by': 'tessera-release-helper', 'tessera-upgrade-bundle': 'true'}}}
        job = {'status': {'conditions': [{'type': 'Complete', 'status': 'True'}]}}
        if failure == 'ownership':
            pvc['metadata']['labels'] = {}
        if failure == 'uid':
            pvc['metadata']['uid'] = 'replacement'
        if failure == 'job':
            job['status'] = {'conditions': [{'type': 'Failed', 'status': 'True'}]}
        def read(command, **kw):
            calls.append(command)
            if command[3] == 'logs':
                if failure == 'logs':
                    raise subprocess.CalledProcessError(1, command)
                return 'upgrade completed\n'
            kind = command[4]
            if kind == 'pvc':
                return json.dumps(pvc)
            if kind == 'job':
                return json.dumps(job)
            if kind == 'pods':
                pods = [{'spec': {'volumes': [{'persistentVolumeClaim': {'claimName': 'bundle'}}]}}] if failure == 'pod' else []
                return json.dumps({'items': pods})
            raise AssertionError(command)
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            with patch.object(deploy.subprocess, 'check_output', side_effect=read), patch.object(deploy.subprocess, 'run', side_effect=lambda c, **kw: calls.append(c)):
                result = deploy.cleanup_bundle(['kubectl', '-n', 'tessera'], Path(temp), 'release-job', 'web', 'bundle', 'original-uid')
            if not failure:
                self.assertEqual((Path(temp) / 'upgrade-completed.log').read_text(), 'upgrade completed\n')
                self.assertTrue((Path(temp) / 'upgrade-completed.json').exists())
        deleted = [c[4] for c in calls if c[3] == 'delete']
        self.assertEqual(result, failure is None)
        if failure is None:
            self.assertEqual(deleted, ['job', 'pvc'])
            self.assertLess(next(i for i, c in enumerate(calls) if c[3] == 'logs'), next(i for i, c in enumerate(calls) if c[3] == 'delete'))
        else:
            self.assertNotIn('pvc', deleted)
            if failure != 'pod':
                self.assertNotIn('job', deleted)

    def test_success_archives_before_deleting_job_then_pvc(self):
        self.exercise()

    def test_failed_unowned_replaced_or_referenced_resources_are_retained(self):
        for failure in ['ownership', 'uid', 'job', 'logs', 'pod']:
            with self.subTest(failure=failure):
                self.exercise(failure)

    def test_wrapper_unique_pvc_and_success_cleanup_flag(self):
        self.wrapper(False)

    def test_wrapper_upload_failure_never_starts_upgrade_or_deletes_evidence(self):
        self.wrapper(True)

    def wrapper(self, fail):
        calls = []
        def run(command, **kw):
            calls.append((command, kw))
            if fail and any('upload-upgrade-bundle.py' in part for part in command):
                raise subprocess.CalledProcessError(1, command)
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            previous = Path.cwd()
            os.chdir(temp)
            try:
                bundle = Path('artifacts/upgrade-bundle')
                bundle.mkdir(parents=True)
                (bundle / 'release.json').write_text(json.dumps({'version': '0.0.196'}))
                args = ['deploy-release.py', '--image', 'docker.io/library/tessera:0.0.196-ubuntu26.04']
                with patch.object(sys, 'argv', args), patch.object(release.check, 'validate'), patch.object(release.subprocess, 'run', side_effect=run):
                    if fail:
                        with self.assertRaises(subprocess.CalledProcessError):
                            release.main()
                    else:
                        release.main()
                        release.main()
                pvcs = [json.loads(kw['input']) for _, kw in calls if 'input' in kw]
                self.assertEqual(pvcs[0]['metadata']['labels']['tessera-upgrade-bundle'], 'true')
                if not fail:
                    self.assertNotEqual(pvcs[0]['metadata']['name'], pvcs[1]['metadata']['name'])
                upgrades = [c for c, _ in calls if any('upgrade-deploy.py' in p for p in c)]
                self.assertEqual(len(upgrades), 0 if fail else 2)
                for command in upgrades:
                    self.assertIn('--cleanup-bundle', command)
                self.assertFalse(any('delete' in c for c, _ in calls))
            finally:
                os.chdir(previous)


if __name__ == '__main__':
    unittest.main()
