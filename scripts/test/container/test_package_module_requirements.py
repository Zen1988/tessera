import copy
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location('package_modules', ROOT / 'container/ubuntu2604/scripts/package-module-requirements.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
MERGE = ROOT / 'container/ubuntu2604/image/merge-cpanfiles.pl'
EXPORT = ROOT / 'container/ubuntu2604/scripts/export-module-requirements.pl'
CHECK = ROOT / 'container/ubuntu2604/image/check-perl.pl'


def metadata():
    return {'schema': 1, 'packages': [
        {'name': 'TESSERA-Base', 'version': '0.0.187', 'modules': [{'module': 'Crypt::AuthEnc::GCM', 'minimum': '0.087'}, {'module': 'Crypt::PRNG', 'minimum': '0.087'}]},
        {'name': 'AnotherIntegration', 'version': '1.0.0', 'modules': [{'module': 'Crypt::AuthEnc::GCM', 'minimum': '0.091'}, {'module': 'JSON::PP', 'minimum': '0'}]}]}


class PackageModules(unittest.TestCase):
    def test_all_packages_and_minima_preserved_once_per_module(self):
        text = MODULE.generate(metadata())
        self.assertEqual(text.count("requires 'Crypt::AuthEnc::GCM'"), 1)
        self.assertIn("'>= 0.087, >= 0.091'", text)
        self.assertIn("requires 'JSON::PP', '>= 0'", text)

    def test_authoritative_opm_mismatch_denied(self):
        opm = '<otobo_package><Name>TESSERA-Base</Name><Version>0.0.187</Version><ModuleRequired Version="0.087">Crypt::AuthEnc::GCM</ModuleRequired><ModuleRequired Version="0.087">Crypt::PRNG</ModuleRequired></otobo_package>'
        self.assertIn('Crypt::PRNG', MODULE.generate(metadata(), opm))
        with self.assertRaises(ValueError):
            MODULE.generate(metadata(), opm.replace('0.0.187', '0.0.186'))
        with self.assertRaises(ValueError):
            MODULE.generate(metadata(), opm.replace('Version="0.087"', 'Version="0.090"'))

    def test_missing_duplicate_and_injected_data_denied(self):
        bad = metadata(); bad['packages'].append(copy.deepcopy(bad['packages'][0]))
        with self.assertRaises(ValueError): MODULE.generate(bad)
        bad = metadata(); bad['packages'] = bad['packages'][1:]
        with self.assertRaises(ValueError): MODULE.generate(bad)
        for key, value in [('module', "X'; system('bad'); #"), ('minimum', "0'; system('bad')")]:
            bad = metadata(); bad['packages'][0]['modules'][0][key] = value
            with self.assertRaises(ValueError): MODULE.generate(bad)

    def perl(self, args, **kwargs):
        perl = shutil.which('perl')
        if not perl: self.skipTest('Perl unavailable')
        return subprocess.run([perl, *map(str, args)], capture_output=True, text=True,
                              env={**os.environ, 'PERL_BADLANG': '0', **kwargs.pop('env', {})}, **kwargs)

    def test_real_perl_constraint_merge_never_downgrades(self):
        manifests = [{'runtime': {'requires': {'Crypt::PRNG': '>= 0.091', 'perl': 'v5.24'}}},
                     {'runtime': {'requires': {'Crypt::PRNG': '>= 0.087'}}},
                     {'build': {'requires': {'ExtUtils::MakeMaker': '0'}}}]
        code = "use JSON::PP; require shift @ARGV; print TESSERA::MergeCPANfiles::Merge(@{JSON::PP->new->decode(shift @ARGV)});"
        result = self.perl(['-e', code, MERGE.resolve(), json.dumps(manifests)])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count("requires 'Crypt::PRNG'"), 1)
        self.assertIn("requires 'Crypt::PRNG', '0.091'", result.stdout)
        self.assertIn("on 'build'", result.stdout)
        manifests[1]['runtime']['requires']['Crypt::PRNG'] = '< 0.080'
        conflict = self.perl(['-e', code, MERGE.resolve(), json.dumps(manifests)])
        self.assertNotEqual(conflict.returncode, 0)

    def test_concrete_helpers_are_in_docker_context(self):
        context = (ROOT / 'container/ubuntu2604/.dockerignore').read_text().splitlines()
        for relative in ['image/check-integration-deps.pl', 'image/merge-cpanfiles.pl', 'dependencies/cpanfile.packages', 'dependencies/package-modules.json']:
            self.assertIn('!' + relative, context)

    def test_native_metadata_export_and_registry_change(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            source = Path(temp)
            module = source / 'Kernel/System/ObjectManager.pm'; module.parent.mkdir(parents=True)
            module.write_text('''package Kernel::System::ObjectManager;
sub new { print "private-bootstrap-output"; bless {query=>0},shift }
sub Get { $_[0] }
sub GetDatabaseFunction {1}
sub Prepare {my ($s,%p)=@_;if($p{SQL}=~/^SELECT content/){$s->{rows}=[[${$p{Bind}[0]}]];return 1}die "private-SQL" unless $p{SQL}=~/^SELECT name, version FROM package_repository/ && ${$p{Bind}[0]} eq 'installed';$s->{query}++;$s->{rows}=[['TESSERA-Base','0.0.187'],['AnotherIntegration',($ENV{CHANGE} && $s->{query}>1)?'2.0.0':'1.0.0']];1}
sub FetchrowArray {my $s=shift;return if !@{$s->{rows}};return @{shift @{$s->{rows}}}}
sub RepositoryGet { my ($s,%p)=@_;return $p{Name} }
sub PackageParse {my($s,%p)=@_;die "private-parser-error" if $ENV{FAIL};return (Name=>{Content=>$p{String}},Version=>{Content=>$p{String} eq 'TESSERA-Base'?'0.0.187':'1.0.0'},ModuleRequired=>[{Content=>$p{String} eq 'TESSERA-Base'?'Crypt::PRNG':'JSON::PP',Version=>'0.087'}])}
1;
''')
            output = source / 'modules.json'
            good = self.perl([EXPORT, source.resolve(), output.resolve()])
            self.assertEqual(good.returncode, 0, good.stderr)
            self.assertEqual(len(json.loads(output.read_text())['packages']), 2)
            self.assertNotIn('private', good.stdout + good.stderr)
            for env in [{'CHANGE': '1'}, {'FAIL': '1'}]:
                failed = self.perl([EXPORT, source.resolve(), (source / 'failed.json').resolve()], env=env)
                self.assertNotEqual(failed.returncode, 0)
                self.assertNotIn('private', failed.stdout + failed.stderr)

    def test_final_checker_checks_perl_minimum_without_writing_as_runtime_uid(self):
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            source = Path(temp)
            module = source / 'Module/CPANfile.pm'; module.parent.mkdir(parents=True)
            module.write_text('''package Module::CPANfile;
use CPAN::Meta::Requirements;
sub load {bless {},shift} sub prereqs {$_[0]}
sub requirements_for {my $r=CPAN::Meta::Requirements->new;$r->add_minimum(perl=>$ENV{MIN_PERL} || '5.0');$r->add_minimum('JSON::PP'=>0);return $r}
1;
''')
            good = self.perl(['-I', source.resolve(), CHECK, '--check-only'])
            self.assertEqual(good.returncode, 0, good.stderr)
            bad = self.perl(['-I', source.resolve(), CHECK, '--check-only'], env={'MIN_PERL': '99.0'})
            self.assertNotEqual(bad.returncode, 0)
            self.assertIn('perl', bad.stderr)


if __name__ == '__main__': unittest.main()
