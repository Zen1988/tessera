#!/usr/bin/env python3
"""Structural source audit. Reports paths/reasons, never matched secret values."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re

REQUIRED = ('Kernel','Kernel/cpan-lib','bin/otobo.Daemon.pl','bin/otobo.Console.pl',
    'bin/psgi-bin/otobo.psgi','bin/otobo.CheckModules.pl',
    'Custom/Kernel/System/TESSERA/Secrets.pm',
    'Custom/Kernel/System/TESSERA/SecretRedis.pm','Custom/Kernel/System/Cache/Redis.pm')
RUNTIME = ('var/article','var/virtualfs','var/tmp','var/log','var/run','var/spool',
           'var/sessions','var/stats','var/packages','local','vendor','scripts/test')
PRIVATE = re.compile(rb'(?m)^-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----\r?$')

def audit(root):
    root=Path(root).resolve()
    errors=[]
    inventory={}
    for required in REQUIRED:
        if not (root/required).exists(): errors.append('required source missing: '+required)
    for current, dirs, files in os.walk(root,followlinks=False):
        for name in dirs+files:
            p=Path(current)/name
            relative=p.relative_to(root).as_posix()
            if name in ('.git','.ssh','.aws','.kube','.gnupg','.cpanm'):
                errors.append('credential/VCS directory: '+relative)
            if p.is_symlink():
                try: p.resolve().relative_to(root)
                except (ValueError,RuntimeError): errors.append('external/looping symlink: '+relative)
        for name in files:
            p=Path(current)/name
            relative=p.relative_to(root).as_posix()
            if p.is_symlink(): continue
            if not p.is_file(): errors.append('nonregular file: '+relative); continue
            blocked=(relative.startswith('Kernel/Config.pm')
                or relative.startswith('Kernel/Config/Files/User/')
                or relative.startswith('Kernel/Config/Files/.tessera-')
                or (relative.startswith('Kernel/Config/Files/') and p.name.startswith('ZZZ') and p.suffix=='.pm')
                or any(relative==d or relative.startswith(d+'/') for d in RUNTIME)
                or name.startswith('.env') or p.suffix.lower() in ('.pem','.key','.p12','.pfx','.so','.sqlite','.sqlite3')
                or name in ('.netrc','.my.cnf','.pgpass')
                or any(part in ('css-cache','js-cache') for part in p.relative_to(root).parts))
            if blocked: errors.append('host config/data/key/compiled-library file: '+relative)
            digest=hashlib.sha256()
            carry=b''
            with p.open('rb') as stream:
                for chunk in iter(lambda:stream.read(1048576),b''):
                    digest.update(chunk)
                    if PRIVATE.search(carry+chunk): errors.append('private key header: '+relative)
                    carry=chunk[-128:]
            inventory[relative]=digest.hexdigest()
    return errors,inventory

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('root',type=Path)
    parser.add_argument('--inventory',type=Path)
    args=parser.parse_args()
    errors,inventory=audit(args.root)
    if errors: raise SystemExit('\n'.join(errors))
    if args.inventory:
        args.inventory.parent.mkdir(parents=True,exist_ok=True)
        args.inventory.write_text(json.dumps(inventory,sort_keys=True,indent=2)+'\n')
    print(f'Structural audit passed: {len(inventory)} files; manual integration-secret review still required')

if __name__=='__main__': main()
