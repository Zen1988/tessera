from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[3]
CHECK = ROOT / 'container/ubuntu2604/image/check-integration-deps.pl'


class CryptoDependencies(unittest.TestCase):
    def test_real_crypto_roundtrip(self):
        perl = shutil.which('perl')
        if not perl:
            self.skipTest('Perl runtime unavailable')
        probe = subprocess.run([perl, '-MCrypt::AuthEnc::GCM', '-MCrypt::PRNG', '-e', 'exit 0'], capture_output=True)
        if probe.returncode:
            self.skipTest('Real CryptX unavailable on this test host')
        result = subprocess.run([perl, str(CHECK)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('tamper rejection OK', result.stdout)

    def test_missing_module_is_actionable_and_fails(self):
        perl = shutil.which('perl')
        if not perl:
            self.skipTest('Perl runtime unavailable')
        with tempfile.TemporaryDirectory(dir=ROOT / '.artifacts') as temp:
            fake = Path(temp) / 'Crypt/AuthEnc/GCM.pm'
            fake.parent.mkdir(parents=True)
            fake.write_text('die "private runtime diagnostic";\n')
            result = subprocess.run([perl, '-I', temp, str(CHECK)], capture_output=True, text=True,
                                    env={**os.environ, 'PERL_BADLANG': '0'})
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Crypt::AuthEnc::GCM >= 0.087', result.stderr)
            self.assertIn('CryptX distribution', result.stderr)
            self.assertNotIn('private runtime diagnostic', result.stderr)

    def test_build_checks_install_and_final_runtime(self):
        cpanfile = (ROOT / 'container/ubuntu2604/cpanfile.extra').read_text()
        self.assertIn("requires 'Crypt::AuthEnc::GCM', '0.087'", cpanfile)
        self.assertIn("requires 'Crypt::PRNG', '0.087'", cpanfile)
        install = (ROOT / 'container/ubuntu2604/image/install-perl.sh').read_text()
        self.assertIn('PERL5LIB=/opt/otobo/local/lib/perl5 /usr/bin/perl /usr/local/lib/tessera/check-integration-deps.pl', install)
        dockerfile = (ROOT / 'container/ubuntu2604/Dockerfile').read_text()
        self.assertIn('RUN /usr/bin/perl /usr/local/lib/tessera/check-integration-deps.pl', dockerfile.split('USER otobo', 1)[1])

    def test_app_local_dependency_loading_and_source_audit_order(self):
        kit = ROOT / 'container/ubuntu2604'
        dockerfile = (kit / 'Dockerfile').read_text()
        self.assertLess(dockerfile.index('COPY --chown=0:0 app/'), dockerfile.index('RUN python3 /usr/local/lib/tessera/audit-app.py'))
        self.assertLess(dockerfile.index('RUN python3 /usr/local/lib/tessera/audit-app.py'), dockerfile.index('RUN /usr/local/lib/tessera/install-perl.sh'))
        self.assertIn(':/opt/otobo/local/lib/perl5', dockerfile)
        install = (kit / 'image/install-perl.sh').read_text()
        self.assertIn('/usr/bin/perl /usr/bin/cpanm --local-lib=/opt/otobo/local ', install)
        apache = (kit / 'image/apache/application.conf').read_text()
        self.assertLess(apache.index('PerlOptions +Parent'), apache.index('PerlSwitches -I/opt/otobo/local/lib/perl5'))
        self.assertLess(apache.index('PerlSwitches -I/opt/otobo/local/lib/perl5'), apache.index('PerlPostConfigRequire'))
        for content in (dockerfile, install, apache):
            self.assertNotIn('/opt/tessera-perl', content)


if __name__ == '__main__':
    unittest.main()
