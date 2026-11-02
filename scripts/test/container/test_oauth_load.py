from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
CHECK = ROOT / 'container/ubuntu2604/image/check-oauth-load.pl'


class OAuthLoad(unittest.TestCase):
    def run_fixture(self, first):
        perl = shutil.which('perl')
        if not perl: self.skipTest('Perl unavailable')
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            base = Path(temp)
            for name, content in [
                ('Kernel/System/OpenIDConnect/Configuration.pm', first),
                ('Kernel/System/OpenIDConnect/OAuth2.pm', 'package Kernel::System::OpenIDConnect::OAuth2; sub new {die "must not instantiate"} 1;'),
                ('Kernel/Modules/AdminOAuthTokenStore.pm', 'package Kernel::Modules::AdminOAuthTokenStore; sub new {die "must not instantiate"} 1;')]:
                target = base / name;target.parent.mkdir(parents=True, exist_ok=True);target.write_text(content)
            return subprocess.run([perl, '-I', str(base), str(CHECK)], capture_output=True, text=True,
                                  env={**os.environ, 'PERL_BADLANG': '0'})

    def test_classes_load_without_instantiating_profiles(self):
        result = self.run_fixture('package Kernel::System::OpenIDConnect::Configuration; sub new {die "must not instantiate"} 1;')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('no profiles or tokens accessed', result.stdout)

    def test_missing_jwt_is_named_without_raw_exception(self):
        result = self.run_fixture('die "Can\'t locate Crypt/JWT.pm in PRIVATE-DETAILS";')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing dependency: Crypt::JWT', result.stderr)
        self.assertNotIn('PRIVATE-DETAILS', result.stderr)

    def test_xs_failure_is_named_without_private_path(self):
        result = self.run_fixture('die "Can\'t load /private/auto/CryptX/library for module CryptX at private location";')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('dependency failed to load: CryptX', result.stderr)
        self.assertNotIn('/private', result.stderr)

    def test_guard_is_in_build_and_context(self):
        self.assertIn('!image/check-oauth-load.pl', (ROOT / 'container/ubuntu2604/.dockerignore').read_text())
        self.assertIn("requires 'Crypt::JWT'", (ROOT / 'container/ubuntu2604/cpanfile.extra').read_text())
        self.assertIn('check-oauth-load.pl', (ROOT / 'container/ubuntu2604/Dockerfile').read_text().split('USER otobo', 1)[1])
        self.assertIn('check-oauth-load.pl', (ROOT / 'container/ubuntu2604/image/entrypoint.sh').read_text())


if __name__ == '__main__': unittest.main()
