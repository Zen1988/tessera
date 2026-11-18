#!/usr/bin/env python3
"""No-DB configure regression tests; can use a scratch directory on the real RWX PVC."""
import importlib.util
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
import shutil
from unittest.mock import patch

HELPER = Path(os.environ.get('TESSERA_CONFIGURE_HELPER',
                            Path(__file__).resolve().parents[1] / 'image/configure.py'))
spec = importlib.util.spec_from_file_location('configure_helper', HELPER)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)


class ConfigureTest(unittest.TestCase):
    def setUp(self):
        # TMPDIR may point at a disposable RWX test directory. Never the live
        # Kernel/Config/Files root. Only our unique temporary subtree is modified.
        self.temporary = tempfile.TemporaryDirectory(prefix='tessera-configure-test-')
        self.root = Path(self.temporary.name)
        self.source = self.root / 'source'
        self.target = self.root / 'target'
        (self.source / 'XML').mkdir(parents=True)
        self.definition = self.source / 'XML/CacheRedis.xml'
        self.definition.write_bytes(b'<fixture>public-definition</fixture>\n')
        self.digest = self.root / 'fingerprint'
        self.digest.write_text('a' * 64 + '\n')
        self.target.mkdir()
        self.marker = self.target / helper.MARKER
        self.command = [sys.executable, '-c',
                        'from pathlib import Path; '
                        f'd=Path({str(self.target)!r}); '
                        f'[ (d/n).write_text("fixture generated") for n in {helper.GENERATED!r} ]']

    def tearDown(self):
        self.definition.chmod(0o600)
        self.temporary.cleanup()

    def configure(self, command=None):
        helper.configure(self.source, self.target, self.digest,
                         self.command if command is None else command, self.root)

    def test_readonly_source_no_metadata_operations_and_idempotency(self):
        self.definition.chmod(0o444)
        (self.target / 'XML').mkdir(mode=0o770)
        initial_mode = stat.S_IMODE((self.target / 'XML').stat().st_mode)
        (self.target / 'User').mkdir()
        (self.target / 'User/site.pm').write_text('preserved administrator override')
        # Model RWX/NFS refusing metadata setters. Ordinary content I/O remains allowed.
        with patch.object(os, 'chmod', side_effect=PermissionError('metadata denied')), \
             patch.object(os, 'utime', side_effect=PermissionError('metadata denied')), \
             patch.object(helper.shutil, 'copystat', side_effect=PermissionError('metadata denied')):
            if hasattr(os, 'chown'):
                with patch.object(os, 'chown', side_effect=PermissionError('metadata denied')):
                    self.configure()
                    self.configure()
            else:
                self.configure()
                self.configure()
        self.assertEqual(self.marker.read_bytes(), self.digest.read_bytes())
        self.assertEqual((self.target / 'XML/CacheRedis.xml').read_bytes(), self.definition.read_bytes())
        self.assertEqual(stat.S_IMODE((self.target / 'XML').stat().st_mode), initial_mode)
        self.assertEqual((self.target / 'User/site.pm').read_text(), 'preserved administrator override')
        if os.name == 'posix':
            self.assertEqual((self.target / 'XML/CacheRedis.xml').stat().st_uid, os.geteuid())
            self.assertTrue(os.access(self.target / 'XML/CacheRedis.xml', os.W_OK))

    def test_failed_rebuild_invalidates_old_stamp(self):
        self.marker.write_text('old success')
        with self.assertRaises(subprocess.CalledProcessError):
            self.configure([sys.executable, '-c', 'raise SystemExit(7)'])
        self.assertFalse(self.marker.exists())

    def test_success_command_without_generated_files_is_not_success(self):
        with self.assertRaises(ValueError):
            self.configure([sys.executable, '-c', 'pass'])
        self.assertFalse(self.marker.exists())

    def test_copy_failure_does_not_run_rebuild_or_stamp(self):
        self.marker.write_text('old success')
        with patch.object(helper.shutil, 'copyfileobj', side_effect=PermissionError('copy denied')), \
             patch.object(helper.subprocess, 'run') as rebuild:
            with self.assertRaises(PermissionError):
                self.configure()
            rebuild.assert_not_called()
        self.assertFalse(self.marker.exists())

    def test_marker_published_only_after_rebuild(self):
        real_run = subprocess.run
        def check(*args, **kwargs):
            self.assertFalse(self.marker.exists())
            return real_run(*args, **kwargs)
        self.marker.write_text('old success')
        with patch.object(helper.subprocess, 'run', side_effect=check):
            self.configure()
        self.assertEqual(self.marker.read_bytes(), self.digest.read_bytes())

    def test_invalid_packaged_digest_rejected(self):
        self.digest.write_text('not a valid digest')
        with self.assertRaises(ValueError):
            self.configure()
        self.assertFalse(self.marker.exists())

    @unittest.skipUnless(shutil.which('perl'), 'requires Perl to execute the actual native-console wrapper')
    def test_native_console_wrapper_fresh_scope_arguments_and_exit_code(self):
        modules = self.root / 'modules/Kernel/System'
        modules.mkdir(parents=True)
        (self.root / 'modules/Kernel/MinimalPerlVersion.pm').write_text('package Kernel::MinimalPerlVersion; 1;')
        (modules / 'ObjectManager.pm').write_text(r'''
package Kernel::System::ObjectManager;
sub new {bless {},$_[0]}
sub Get {$_[0]}
sub event {open my $F,'>>',$ENV{FIXTURE_EVENTS} or die;print $F $_[1],"\n";close $F}
sub Configure {my($S,%P)=@_;die 'External cache enabled' if $P{CacheInBackend} || $P{CacheInMemory};$S->{Fresh}=1;$S->event('fresh')}
sub Run {my($S,@A)=@_;die 'No fresh scope' if !$S->{Fresh};die 'Wrong native arguments' if join(',',@A) ne 'Maint::Config::Rebuild,--deploy-acls,--deploy-processes';$S->event('native');return $ENV{FIXTURE_EXIT}}
sub DESTROY {$_[0]->event('events')}
1;
''')
        events = self.root / 'events'
        env = dict(os.environ, FIXTURE_EVENTS=str(events))
        for status in (0, 7):
            events.unlink(missing_ok=True)
            env['FIXTURE_EXIT'] = str(status)
            result = subprocess.run([shutil.which('perl'), '-I' + str(self.root / 'modules'), '-e', helper.REBUILD_PROGRAM,
                                     'Maint::Config::Rebuild', '--deploy-acls', '--deploy-processes'], env=env, capture_output=True)
            self.assertEqual(result.returncode, status, result.stderr)
            self.assertEqual(events.read_text().splitlines(), ['fresh', 'native', 'events'])

    @unittest.skipUnless(os.name == 'posix' and os.geteuid() != 0, 'requires nonroot POSIX permissions')
    def test_unreadable_source_rejected_before_rebuild(self):
        self.definition.chmod(0)
        with patch.object(helper.subprocess, 'run') as rebuild:
            with self.assertRaises(PermissionError):
                self.configure()
            rebuild.assert_not_called()
        self.assertFalse(self.marker.exists())

    @unittest.skipUnless(os.name == 'posix', 'requires POSIX symlink support')
    def test_destination_symlink_cannot_overwrite_external_file(self):
        outside = self.root / 'do-not-touch'
        outside.write_text('outside remains unchanged')
        (self.target / 'XML').mkdir()
        (self.target / 'XML/CacheRedis.xml').symlink_to(outside)
        with self.assertRaises(ValueError):
            self.configure()
        self.assertEqual(outside.read_text(), 'outside remains unchanged')


if __name__ == '__main__':
    if os.environ.get('TESSERA_REQUIRE_TEST_UID'):
        expected = int(os.environ['TESSERA_REQUIRE_TEST_UID'])
        if not hasattr(os, 'geteuid') or os.geteuid() != expected:
            raise SystemExit(f'Tests must run as UID {expected}')
        print(f'Configure regression tests running as UID {os.geteuid()}', flush=True)
    unittest.main(verbosity=2)
