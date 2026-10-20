import contextlib
from datetime import datetime,timezone,timedelta
import importlib.util
import io
from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[3]
KIT=ROOT/'container/ubuntu2604'
spec=importlib.util.spec_from_file_location('audit_app',KIT/'image/audit-app.py')
audit=importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)
BLOCKS=re.findall(r"<<'PY'\n(.*?)\nPY",(KIT/'scripts/pki.sh').read_text(),re.S)

def fixture(root):
    for name in audit.REQUIRED:
        p=root/name
        if name in ('Kernel','Kernel/cpan-lib'): p.mkdir(parents=True,exist_ok=True)
        else: p.parent.mkdir(parents=True,exist_ok=True); p.write_text('fixture source')

def pki_block(number,*args):
    previous=sys.argv
    out=io.StringIO()
    try:
        sys.argv=['embedded',*map(str,args)]
        with contextlib.redirect_stdout(out):
            exec(compile(BLOCKS[number],'pki-python','exec'),{'__name__':'__main__'})
    finally: sys.argv=previous
    return out.getvalue().strip()

class ImageKitTest(unittest.TestCase):
    def test_complete_source_passes(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); fixture(root)
            p=root/'var/governancedb/runtime_overlay/Kernel/Modules/Example.pm'
            p.parent.mkdir(parents=True); p.write_text('fixture overlay')
            errors,inventory=audit.audit(root)
            self.assertEqual(errors,[])
            self.assertIn('var/governancedb/runtime_overlay/Kernel/Modules/Example.pm',inventory)
            self.assertEqual(p.read_text(),'fixture overlay')

    def test_config_rejected_without_content(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); fixture(root)
            (root/'Kernel/Config.pm').write_text('fixture-password-never-print')
            errors,_=audit.audit(root)
            self.assertTrue(any('Kernel/Config.pm' in e for e in errors))
            self.assertNotIn('fixture-password-never-print','\n'.join(errors))

    def test_customer_files_rejected(self):
        for path in ('var/article/old-file','var/virtualfs/photo','var/spool/job','var/log/application.log'):
            with tempfile.TemporaryDirectory() as d:
                root=Path(d); fixture(root)
                p=root/path; p.parent.mkdir(parents=True); p.write_text('fixture data')
                self.assertTrue(audit.audit(root)[0])

    def test_private_key_header_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); fixture(root)
            (root/'integration.conf').write_bytes(b'\n-----BEGIN PRIVATE KEY-----\nfixture')
            self.assertTrue(any('private key header' in e for e in audit.audit(root)[0]))

    def test_development_samples_cannot_enter_image(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); fixture(root)
            sample=root/'scripts/test/sample/SMIME/SMIMEPrivateKey-4.asc'
            sample.parent.mkdir(parents=True)
            sample.write_bytes(b'-----BEGIN PRIVATE KEY-----\nfixture-only\n')
            errors,_=audit.audit(root)
            self.assertTrue(any('host config/data/key/compiled-library file: scripts/test/' in e for e in errors))
            self.assertTrue(any('private key header' in e for e in errors))
            self.assertNotIn('fixture-only','\n'.join(errors))

    def test_runtime_scripts_remain_allowed(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); fixture(root)
            for name in ('scripts/apache2-perl-preload_otobo_psgi.pl','scripts/database/otobo-schema.mysql.sql'):
                p=root/name; p.parent.mkdir(parents=True,exist_ok=True); p.write_text('runtime fixture')
            self.assertEqual(audit.audit(root)[0],[])

    def test_compiled_host_library_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); fixture(root)
            (root/'Kernel/cpan-lib/host.so').write_bytes(b'fixture ABI')
            self.assertTrue(audit.audit(root)[0])

    def test_required_custom_loader(self):
        with tempfile.TemporaryDirectory() as d:
            root=Path(d); fixture(root)
            (root/'Custom/Kernel/System/Cache/Redis.pm').unlink()
            self.assertTrue(any('required source missing' in e for e in audit.audit(root)[0]))

    def test_requested_ubuntu_dependencies(self):
        docker=(KIT/'Dockerfile').read_text()
        self.assertIn('BASE_IMAGE=ubuntu:26.04',docker)
        packages=set((KIT/'apt-packages.txt').read_text().split())
        self.assertTrue({'libredis-perl','libgd-perl','libgd-dev','libjpeg-dev','libpng-dev'}<=packages)
        self.assertNotIn('Package::Reinstall',docker)
        self.assertNotIn('Config.pm.dist',docker)

    def test_prepare_has_no_package_restoration(self):
        source=(KIT/'scripts/prepare.sh').read_text()
        self.assertNotIn('base64',source)
        self.assertNotIn('--delete',source)
        self.assertIn('--docker-cpanfile',source)
        self.assertIn('source.exclude',source)

    def test_pki_bits_and_calendar_lifetime(self):
        source=(KIT/'scripts/pki.sh').read_text()
        self.assertEqual(source.count('rsa_keygen_bits:8192'),2)
        self.assertEqual(len(BLOCKS),3)
        days=int(pki_block(0))
        self.assertIn(days,(1095,1096))
        self.assertIn('-aes-256-cbc',source)
        self.assertNotIn('-passin pass:',source)

    def test_portal_sans_and_eku(self):
        with tempfile.TemporaryDirectory() as d:
            output=Path(d)/'extensions.cnf'
            pki_block(1,'tessera.local,portal.tessera.local','both',output)
            text=output.read_text()
            self.assertIn('DNS:tessera.local,DNS:portal.tessera.local',text)
            self.assertIn('serverAuth,clientAuth',text)
            self.assertIn('CA:FALSE',text)

    def test_other_component_sans(self):
        with tempfile.TemporaryDirectory() as d:
            for name in ('daemon','redis','db'):
                output=Path(d)/(name+'.cnf')
                pki_block(1,name+'.tessera.local','server',output)
                self.assertIn('DNS:'+name+'.tessera.local',output.read_text())

    def test_invalid_dns_and_missing_server_san(self):
        with tempfile.TemporaryDirectory() as d:
            for name in ('portal.tessera.local\nCA:TRUE','../escape','*.tessera.local','-'):
                with self.assertRaises(SystemExit): pki_block(1,name,'server',Path(d)/'bad.cnf')

    def test_client_only_certificate(self):
        with tempfile.TemporaryDirectory() as d:
            output=Path(d)/'client.cnf'
            pki_block(1,'-','client',output)
            self.assertIn('extendedKeyUsage=clientAuth',output.read_text())
            self.assertNotIn('subjectAltName',output.read_text())

    def test_leaf_capped_by_ca_expiry(self):
        expiry=(datetime.now(timezone.utc)+timedelta(days=30)).replace(microsecond=0)
        result=pki_block(2,expiry.strftime('%b %d %H:%M:%S %Y GMT'))
        self.assertEqual(result,expiry.strftime('%Y%m%d%H%M%SZ'))

    def test_expired_ca_refused(self):
        expired=datetime.now(timezone.utc)-timedelta(days=1)
        with self.assertRaises(SystemExit): pki_block(2,expired.strftime('%b %d %H:%M:%S %Y GMT'))

    def test_internal_mtls_proxy(self):
        conf=(KIT/'image/nginx-internal-tls.conf').read_text()
        self.assertIn('ssl_verify_client on;',conf)
        self.assertIn('portal.tessera.local',conf)
        self.assertNotIn('ssl_verify_client off',conf)
        self.assertIn('/run/tessera-tls/tls.key',conf)

if __name__=='__main__': unittest.main()
