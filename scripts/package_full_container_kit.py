"""Package source/build scripts only. Never include app/config/PKI/private data."""
import hashlib
from pathlib import Path
import stat
import zipfile

ROOT=Path(__file__).resolve().parents[1]
KIT=ROOT/'container/ubuntu2604'
ROOT_FILES={'Dockerfile','Dockerfile.tlsproxy','.dockerignore','.gitignore',
    'apt-packages.txt','apt-extra.txt','cpanfile.extra','README.md'}
SUFFIXES={'.sh','.py','.pl','.conf','.cnf','.exclude','.yaml','.md'}

def main():
    out=ROOT/'outputs/TESSERA-180-r1-Ubuntu26.04-Container-Kit.zip'
    out.parent.mkdir(parents=True,exist_ok=True)
    included={}
    for p in KIT.rglob('*'):
        if not p.is_file() or p.is_symlink(): continue
        relative=p.relative_to(KIT)
        if relative.as_posix()=='image/site-entrypoint.sh': continue
        allowed=(relative.as_posix() in ROOT_FILES or
            (relative.parts[0] in {'image','scripts','examples'} and p.suffix in SUFFIXES))
        if allowed:
            assert p.suffix not in {'.key','.pem','.pfx','.p12'}
            included[relative.as_posix()]=p.read_bytes()
    for source in ['docs/kubernetes-migration-plan.md']:
        included[source]=(ROOT/source).read_bytes()
    assert len(included)>15 and all(not n.startswith(('app/','dependencies/','artifacts/')) for n in included)
    sums=[]
    with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as archive:
        for name,data in sorted(included.items()):
            entry=zipfile.ZipInfo(name)
            entry.create_system=3
            mode=0o755 if name.endswith(('.sh','.pl','.py')) else 0o644
            entry.external_attr=(stat.S_IFREG|mode)<<16
            entry.compress_type=zipfile.ZIP_DEFLATED
            archive.writestr(entry,data)
            sums.append(f'{hashlib.sha256(data).hexdigest()}  {name}')
        archive.writestr('SHA256SUMS','\n'.join(sums)+'\n')
    with zipfile.ZipFile(out) as archive: assert archive.testzip() is None
    digest=hashlib.sha256(out.read_bytes()).hexdigest()
    out.with_suffix('.zip.sha256').write_text(f'{digest}  {out.name}\n',encoding='utf-8')
    print(f'Packaged {len(included)} source files; no app/credentials/certificates/private keys included')
    print(out)
    print('SHA256',digest)

if __name__=='__main__': main()
