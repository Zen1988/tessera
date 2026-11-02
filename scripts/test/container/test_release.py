import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import io
from contextlib import nullcontext
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
SCRIPT = ROOT / 'container/ubuntu2604/scripts/release.py'
spec = importlib.util.spec_from_file_location('toolkit_release', SCRIPT)
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


class ReleaseTest(unittest.TestCase):
    def test_missing_file_reports_path_without_traceback(self):
        error = FileNotFoundError(2, 'missing', '/opt/otobo/var/governancedb/container_release.json')
        stderr = io.StringIO()
        with patch.object(release.sys, 'argv', ['release.py', 'detect', '/opt/otobo']), \
                patch.object(release, 'detect', side_effect=error), \
                patch.object(release.sys, 'stderr', stderr):
            self.assertEqual(release.main(), 1)
        self.assertIn('Required file not found: /opt/otobo/var/governancedb/container_release.json', stderr.getvalue())
        self.assertNotIn('Traceback', stderr.getvalue())

    def test_first_build_then_revisions_and_new_package(self):
        self.assertEqual(release.next_revision('tessera', '0.0.185', -1, []), 0)
        self.assertEqual(release.tag('tessera', '0.0.185', 0), 'tessera:0.0.185-ubuntu26.04')
        self.assertEqual(release.tag('tessera', '0.0.185', 1), 'tessera:0.0.185-r1-ubuntu26.04')
        self.assertEqual(release.next_revision('tessera', '0.0.185', 1, []), 2)
        self.assertEqual(release.next_revision('tessera', '0.0.186', -1,
                                             ['tessera:0.0.185-r8-ubuntu26.04']), 0)

    def test_existing_images_protect_fresh_kit_and_state(self):
        images = ['tessera:0.0.185-ubuntu26.04', 'tessera:0.0.185-r9-ubuntu26.04',
                  'other:0.0.185-r99-ubuntu26.04', 'tessera:0.0.185-r300-otheros']
        self.assertEqual(release.next_revision('tessera', '0.0.185', -1, images), 10)
        self.assertEqual(release.next_revision('tessera', '0.0.185', 12, images), 13)

    def test_registry_port_and_untrusted_version_inputs(self):
        self.assertEqual(release.tag('registry.local:5000/team/tessera', '0.1.0', 2),
                         'registry.local:5000/team/tessera:0.1.0-r2-ubuntu26.04')
        for value in ('185;touch /tmp/x', '', '0.0.185/secret', None):
            with self.assertRaises(ValueError):
                release.version(value)
        for repository in ('tessera:fixed', 'https://registry/tessera', 'user:password@registry/tessera'):
            with self.assertRaises(ValueError):
                release.tag(repository, '0.0.185', 0)

    def test_version_detection_never_publishes_captured_diagnostics(self):
        with patch.object(release.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, 'private fixture', 'private fixture')):
            with self.assertRaises(ValueError) as result:
                release.detect('/fixture')
        self.assertNotIn('private fixture', str(result.exception))
        with patch.object(release.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '0.0.185\n', '')):
            self.assertEqual(release.detect('/fixture'), '0.0.185')

    def test_build_labels_receipts_repeat_and_failed_attempt(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            kit = root / 'kit'
            (kit / 'dependencies').mkdir(parents=True)
            (kit / 'dependencies/release.json').write_text(json.dumps({'package': 'TESSERA-Base', 'version': '0.0.185'}))
            (kit / 'dependencies/source-sha256.json').write_text('{}')
            calls = []
            fail = [False]
            def run(command, **kwargs):
                calls.append(command)
                if fail[0] and command[:2] == ['docker', 'build']:
                    raise subprocess.CalledProcessError(1, command)
                return subprocess.CompletedProcess(command, 0)
            def output(command, **kwargs):
                if command[:3] == ['docker', 'image', 'ls']:
                    return ''
                if command[:2] == ['docker', 'run']:
                    return json.dumps({'executable': '/usr/bin/perl', 'version': 'v5.40.1', 'archname': 'x86_64-linux-gnu-thread-multi', 'policy': 'target-os-system-perl'})
                return json.dumps([{'Id': 'sha256:fixture'}])
            environment = dict(os.environ, TESSERA_IMAGE_REPOSITORY='tessera', TESSERA_BUILD_STATE_DIR=str(root / 'state'))
            environment.pop('TESSERA_IMAGE', None)
            with patch.dict(os.environ, environment, clear=True), patch.object(release, 'KIT', kit), \
                 patch.object(release, 'locked', return_value=nullcontext()), \
                 patch.object(release.subprocess, 'run', side_effect=run), \
                 patch.object(release.subprocess, 'check_output', side_effect=output):
                release.build()
                receipt = json.loads((kit / 'artifacts/latest-build.json').read_text())
                self.assertEqual(receipt['tag'], 'tessera:0.0.185-ubuntu26.04')
                self.assertIn('TESSERA_VERSION=0.0.185', calls[0])
                self.assertIn('TESSERA_IMAGE_REVISION=base', calls[0])
                self.assertTrue(any(arg.startswith('TESSERA_DEPENDENCY_REFRESH=') and arg != 'TESSERA_DEPENDENCY_REFRESH=cached' for arg in calls[0]))
                self.assertEqual(receipt['dependency_policy'], 'latest')
                self.assertEqual(receipt['perl_runtime']['executable'], '/usr/bin/perl')
                fail[0] = True
                with self.assertRaises(subprocess.CalledProcessError):
                    release.build()
                fail[0] = False
                release.build()
                latest = json.loads((kit / 'artifacts/latest-build.json').read_text())
                self.assertEqual(latest['tag'], 'tessera:0.0.185-r2-ubuntu26.04')
                state = json.loads(next((root / 'state').glob('*.json')).read_text())
                self.assertEqual([r['status'] for r in state['attempts']], ['success', 'failed', 'success'])
                self.assertEqual(len(list((kit / 'artifacts/builds').glob('*.json'))), 2)
                build_calls = [call for call in calls if call[:2] == ['docker', 'build']]
                refreshes = [next(arg for arg in call if arg.startswith('TESSERA_DEPENDENCY_REFRESH=')) for call in build_calls]
                self.assertEqual(len(set(refreshes)), 3)
                with patch.dict(os.environ, {'TESSERA_DEPENDENCY_POLICY': 'cached'}):
                    release.build()
                self.assertIn('TESSERA_DEPENDENCY_REFRESH=cached', calls[-2])

    def test_installed_registry_reader_exact_single_installed_version(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            module = root / 'Kernel/System/ObjectManager.pm'
            module.parent.mkdir(parents=True)
            module.write_text('''package Kernel::System::ObjectManager;
sub new { print "private-fixture-must-not-leak"; bless {}, shift }
sub Get { bless { rows => [split /,/, $ENV{TESSERA_FIXTURE_VERSIONS} || ""] }, 'FixtureDB' }
package FixtureDB;
sub Prepare { my ($s,%p)=@_; die "private-fixture" unless $p{SQL} =~ /^SELECT version FROM package_repository/ && ${$p{Bind}[0]} eq 'TESSERA-Base' && ${$p{Bind}[1]} eq 'installed'; return 1 }
sub FetchrowArray { my $s=shift; return if !@{$s->{rows}}; return (shift @{$s->{rows}}) }
1;
''')
            helper = ROOT / 'container/ubuntu2604/scripts/installed-version.pl'
            environment = {k: v for k, v in os.environ.items() if k not in ('PERL5OPT', 'PERL5LIB')}
            for values, success in [('0.0.185', True), ('', False), ('0.0.184,0.0.185', False), ('invalid', False)]:
                result = subprocess.run(['perl', str(helper), str(root.resolve())], capture_output=True, text=True,
                                        env=dict(environment, TESSERA_FIXTURE_VERSIONS=values, LC_ALL='C'))
                self.assertEqual(result.returncode == 0, success)
                self.assertNotIn('private-fixture', result.stdout + result.stderr)
                if success:
                    self.assertEqual(result.stdout.strip(), '0.0.185')

    @unittest.skipUnless(os.name == 'posix', 'requires Linux flock')
    def test_lock_refuses_concurrent_allocator(self):
        with tempfile.TemporaryDirectory() as temporary:
            lock = Path(temporary) / 'release.lock'
            with release.locked(lock):
                with self.assertRaises(ValueError):
                    with release.locked(lock):
                        self.fail('second allocator acquired the lock')
