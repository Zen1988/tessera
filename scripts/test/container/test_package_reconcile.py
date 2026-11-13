import json
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tarfile
import sys
from unittest.mock import patch
import unittest

ROOT = Path(__file__).resolve().parents[3]
HELPERS = ROOT / 'container/ubuntu2604/image'

class PackageReconciliation(unittest.TestCase):
    def test_verify_only_never_streams_or_rewrites_bundle(self):
        spec = importlib.util.spec_from_file_location('upload_verify', ROOT / 'container/ubuntu2604/scripts/upload-upgrade-bundle.py')
        upload = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(upload)
        calls = []
        args = ['upload-upgrade-bundle.py', '--namespace', 'tessera', '--pvc', 'existing-bundle',
                '--image', 'tessera:0.0.195-r1-ubuntu26.04', '--bundle', 'local-bundle', '--verify-only']
        with patch.object(sys, 'argv', args), patch.object(upload, 'bundle_files', return_value=[]), patch.object(upload.subprocess, 'run', side_effect=lambda command, **kw: calls.append((command, kw))):
            upload.main()
        self.assertFalse(any('-i' in command for command, _ in calls))
        self.assertTrue(any('/usr/local/lib/tessera/check-package-bundle.py' in command for command, _ in calls))
        self.assertFalse(any('stdin' in kw for _, kw in calls))

    def test_upload_receiver_refuses_overwrite_and_traversal(self):
        spec = importlib.util.spec_from_file_location('upload', ROOT / 'container/ubuntu2604/scripts/upload-upgrade-bundle.py')
        upload = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(upload)
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            root = Path(temp) / 'upgrade'
            program = upload.RECEIVE.replace("pathlib.Path('/bundle/upgrade')", 'pathlib.Path(' + repr(str(root)) + ')')
            stream = io.BytesIO()
            with tarfile.open(fileobj=stream, mode='w') as archive:
                item = tarfile.TarInfo('release.json')
                item.size = 2
                archive.addfile(item, io.BytesIO(b'{}'))
            result = subprocess.run([sys.executable, '-c', program], input=stream.getvalue(), capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((root / 'release.json').read_bytes(), b'{}')
            result = subprocess.run([sys.executable, '-c', program], input=stream.getvalue(), capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            other = Path(temp) / 'malicious'
            program = upload.RECEIVE.replace("pathlib.Path('/bundle/upgrade')", 'pathlib.Path(' + repr(str(other)) + ')')
            stream = io.BytesIO()
            with tarfile.open(fileobj=stream, mode='w') as archive:
                item = tarfile.TarInfo('../escaped')
                item.size = 2
                archive.addfile(item, io.BytesIO(b'{}'))
            result = subprocess.run([sys.executable, '-c', program], input=stream.getvalue(), capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((Path(temp) / 'escaped').exists())

    def test_bundle_identity_and_tampering(self):
        spec = importlib.util.spec_from_file_location('bundle', HELPERS / 'check-package-bundle.py')
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            directory = Path(temp)
            (directory / 'packages').mkdir()
            data = b'<otobo_package><Name>TESSERA-Base</Name><Version>0.0.194</Version></otobo_package>'
            digest = hashlib.sha256(data).hexdigest()
            artifact = directory / 'packages' / (digest + '.opm')
            artifact.write_bytes(data)
            release = {'version': '0.0.194', 'package_sha256': digest}
            manifest = {'schema': 1, 'packages': [{'name': 'TESSERA-Base', 'version': '0.0.194', 'package_sha256': digest}]}
            (directory / 'release.json').write_text(json.dumps(release))
            (directory / 'package-modules.json').write_text(json.dumps(manifest))
            module.validate(directory)
            expected = directory / 'image-metadata'
            expected.mkdir()
            for name in ('release.json', 'package-modules.json'):
                (expected / name).write_bytes((directory / name).read_bytes())
            module.validate(directory, expected)
            (expected / 'release.json').write_text('{}')
            with self.assertRaisesRegex(ValueError, 'does not match runtime image'):
                module.validate(directory, expected)
            export_spec = importlib.util.spec_from_file_location('export_bundle', ROOT / 'container/ubuntu2604/scripts/export-upgrade-bundle.py')
            export = importlib.util.module_from_spec(export_spec)
            export_spec.loader.exec_module(export)
            destination = directory / 'exported'
            export.export(directory, destination)
            self.assertEqual({p.name for p in destination.iterdir()}, {'release.json', 'package-modules.json', 'packages'})
            module.validate(destination)
            with self.assertRaises(ValueError):
                export.export(directory, destination)
            artifact.write_bytes(data + b'changed')
            with self.assertRaisesRegex(ValueError, 'hash mismatch'):
                module.validate(directory)

            artifact.write_bytes(data)
            release['version'] = '0.0.195'
            (directory / 'release.json').write_text(json.dumps(release))
            with self.assertRaisesRegex(ValueError, 'changed during'):
                module.validate(directory)

    def test_runtime_image_excludes_opm_payloads(self):
        dockerfile = (ROOT / 'container/ubuntu2604/Dockerfile').read_text()
        self.assertNotIn('COPY dependencies/packages', dockerfile)
        self.assertNotIn('COPY --chmod=0444 dependencies/package.opm', dockerfile)
        ignored = (ROOT / 'container/ubuntu2604/.dockerignore').read_text().splitlines()
        self.assertNotIn('!dependencies/package.opm', ignored)
        self.assertNotIn('!dependencies/packages/', ignored)

    def test_upgrade_guard_and_failure_contract(self):
        perl = shutil.which('perl')
        if not perl:
            self.skipTest('Perl unavailable')
        fixture = r'''
use strict;use warnings;use JSON::PP;use Digest::SHA qw(sha256_hex);
require shift @ARGV;require shift @ARGV;
my ($Dir,$Case)=@ARGV;
{package Fake;
sub new {bless {rows=>[],journal=>0,version=>'1.0.0',calls=>[]},shift}
sub _RepositoryCacheClear {1}
sub GetDatabaseFunction {1}
sub Prepare {my($s,%p)=@_;$s->{rows}=$p{SQL}=~/SELECT content/?[[$s->{version} eq '2.0.0'?'new':'old']]:$p{SQL}=~/SELECT data_key/?($s->{journal}?[['claim']]:[]):[['Addon',$s->{version}]];1}
sub FetchrowArray {my $s=shift;return if !@{$s->{rows}};@{shift @{$s->{rows}}}}
sub Connect {$_[0]}
sub do {my($s,$sql)=@_;$s->{journal}= $sql=~/INSERT/?1:0;1}
sub PackageParse {(Name=>{Content=>'Addon'},Version=>{Content=>'2.0.0'})}
sub RepositoryGet {$_[0]{version} eq '2.0.0'?'new':'old'}
sub PackageUpgrade {my $s=shift;push @{$s->{calls}},'upgrade';$s->{version}='2.0.0';die "hook failed\n" if $s->{fail};1}
}
my $DB=Fake->new;my $Hash=sha256_hex('new');
my $M={schema=>1,packages=>[{name=>'Addon',version=>'2.0.0',package_sha256=>$Hash}]};
open my $FH,'>:raw',"$Dir/$Hash.opm" or die;print {$FH} 'new';close $FH;
if ($Case eq 'matching') {$DB->{version}='2.0.0'}
if ($Case eq 'ahead') {$DB->{version}='3.0.0'}
if ($Case eq 'artifact') {$DB->{version}='2.0.0';$M->{packages}[0]{package_sha256}='a'x64}
if ($Case eq 'journal') {$DB->{journal}=1;$DB->{version}='2.0.0'}
if ($Case eq 'hook') {$DB->{fail}=1}
if ($Case eq 'missing') {$M->{packages}[0]{name}='Other'}
my $OK=eval {if ($Case eq 'plan') {ReconcilePackages($M,$DB,$DB,$Dir,1)} elsif ($Case eq 'guard' || $Case eq 'missing' || $Case eq 'artifact') {CheckInventory($M,$DB,$DB)}
else {ReconcilePackages($M,$DB,$DB,$Dir);CheckInventory($M,$DB,$DB)};1};
print JSON::PP->new->encode({ok=>$OK?1:0,calls=>scalar @{$DB->{calls}},journal=>$DB->{journal},error=>$@});
'''
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            for case in ['upgrade', 'matching', 'ahead', 'artifact', 'journal', 'hook', 'missing', 'guard', 'plan']:
                with self.subTest(case=case):
                    result = subprocess.run([perl, '-e', fixture, str(HELPERS / 'package-inventory.pl'),
                                             str(HELPERS / 'package-reconcile.pl'), temp, case],
                                            capture_output=True, text=True, env={**os.environ, 'PERL_BADLANG': '0'})
                    self.assertEqual(result.returncode, 0, result.stderr)
                    data = json.loads(result.stdout[result.stdout.index('{'):])
                    self.assertEqual(data['ok'], int(case in ['upgrade', 'matching', 'plan']))
                    self.assertEqual(data['calls'], int(case in ['upgrade', 'hook']))
                    if case == 'hook':
                        self.assertEqual(data['journal'], 1)

if __name__ == '__main__':
    unittest.main()
