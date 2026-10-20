"""Actual OpenSSL chain fixture; production CA creation stays interactive/on-host."""
import importlib.util
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[3]
KIT=ROOT/'container/ubuntu2604'
CANDIDATE=Path('C:/Program Files/Git/mingw64/bin/openssl.exe')
OPENSSL=shutil.which('openssl') or (str(CANDIDATE) if CANDIDATE.exists() else None)
spec=importlib.util.spec_from_file_location('image_kit_tests',Path(__file__).with_name('test_ubuntu_image_kit.py'))
helpers=importlib.util.module_from_spec(spec); spec.loader.exec_module(helpers)

@unittest.skipUnless(OPENSSL,'OpenSSL not available')
class CertificateChainTest(unittest.TestCase):
    def test_actual_server_client_chain_and_name_checks(self):
        with tempfile.TemporaryDirectory() as directory:
            p=Path(directory)
            (p/'request.cnf').write_text('[req]\ndistinguished_name=dn\n[dn]\n')
            env={**os.environ,'TESSERA_PKI_DIR':p.as_posix(),'OPENSSL_CONF':str(p/'request.cnf')}
            def run(*args,secret_input=None,ok=True):
                result=subprocess.run([OPENSSL,*map(str,args)],input=secret_input,
                    capture_output=True,text=True,env=env,timeout=240)
                if ok: self.assertEqual(result.returncode,0,'OpenSSL operation failed: '+result.stderr[-1500:])
                return result
            # Small disposable CA for fixture speed. Production pki.sh explicitly
            # generates an encrypted RSA8192 root; the REAL leaf tested is8192.
            run('genpkey','-algorithm','RSA','-pkeyopt','rsa_keygen_bits:2048',
                '-aes-256-cbc','-pass','stdin','-out',p/'ca.key',secret_input='fixture-only-passphrase\n')
            run('req','-new','-x509','-key',p/'ca.key','-passin','stdin','-days','1',
                '-subj','/O=Fixture/CN=Disposable Test CA',
                '-addext','basicConstraints=critical,CA:TRUE,pathlen:0',
                '-addext','keyUsage=critical,keyCertSign,cRLSign','-out',p/'ca.crt',
                secret_input='fixture-only-passphrase\n')
            (p/'newcerts').mkdir(); (p/'index.txt').write_text(''); (p/'serial').write_text('01\n')
            config=re.search(r"<<'CONF'\n(.*?)\nCONF",(KIT/'scripts/pki.sh').read_text(),re.S).group(1)
            (p/'openssl.cnf').write_text(config)
            helpers.pki_block(1,'tessera.local,portal.tessera.local','both',p/'extensions.cnf')
            run('genpkey','-algorithm','RSA','-pkeyopt','rsa_keygen_bits:8192','-out',p/'tls.key')
            run('req','-new','-key',p/'tls.key','-subj','/O=TESSERA/CN=portal','-out',p/'tls.csr')
            expiry=run('x509','-in',p/'ca.crt','-noout','-enddate').stdout.strip().split('=',1)[1]
            end=helpers.pki_block(2,expiry)
            run('ca','-batch','-notext','-config',p/'openssl.cnf','-passin','stdin',
                '-extensions','leaf','-extfile',p/'extensions.cnf','-enddate',end,
                '-in',p/'tls.csr','-out',p/'tls.crt',secret_input='fixture-only-passphrase\n')
            text=run('x509','-in',p/'tls.crt','-noout','-text').stdout
            self.assertIn('8192 bit',text)
            run('verify','-CAfile',p/'ca.crt','-purpose','sslserver','-verify_hostname','portal.tessera.local',p/'tls.crt')
            run('verify','-CAfile',p/'ca.crt','-purpose','sslclient',p/'tls.crt')
            self.assertNotEqual(run('verify','-CAfile',p/'ca.crt','-verify_hostname','wrong.tessera.local',p/'tls.crt',ok=False).returncode,0)
            # A self-signed unrelated trust anchor must not validate this leaf.
            run('req','-new','-x509','-newkey','rsa:2048','-nodes','-days','1',
                '-keyout',p/'other.key','-out',p/'other.crt','-subj','/CN=Unrelated Fixture CA')
            self.assertNotEqual(run('verify','-CAfile',p/'other.crt',p/'tls.crt',ok=False).returncode,0)
            self.assertEqual(run('x509','-in',p/'tls.crt','-noout','-enddate').stdout,
                             run('x509','-in',p/'ca.crt','-noout','-enddate').stdout)

if __name__=='__main__': unittest.main()
