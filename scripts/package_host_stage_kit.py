"""Package the Linux staging review kit; does not run the staging tool."""
import hashlib
from pathlib import Path
import stat
import zipfile

ROOT = Path(__file__).resolve().parents[1]
FILES = {
    'scripts/container/stage-host-app.sh': 'scripts/container/stage-host-app.sh',
    'scripts/container/host-stage.exclude': 'scripts/container/host-stage.exclude',
    'Kernel/Package/TESSERA-Base-0.0.180.opm': 'TESSERA-Base-0.0.180.opm',
    'Kernel/System/Cache/Redis.pm': 'reference/Kernel/System/Cache/Redis.pm',
    'docs/linux-host-image-staging-review.md': 'docs/linux-host-image-staging-review.md',
    'docs/kubernetes-migration-plan.md': 'docs/kubernetes-migration-plan.md',
    'scripts/test/container/test_host_staging.py': 'scripts/test/container/test_host_staging.py',
}

def main():
    pinned = {
        'Kernel/Package/TESSERA-Base-0.0.180.opm':'3a0411893bb8f9dc07dede542f924e5ae36970b87cefd9d5a255958a64b1d315',
        'Kernel/System/Cache/Redis.pm':'be832371af13f317045d836649ea436709ab5f1c711704bee48038239180183a',
    }
    for path, expected in pinned.items():
        assert hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==expected
    out = ROOT/'outputs/build-180'
    out.mkdir(parents=True, exist_ok=True)
    target = out/'TESSERA-Base-0.0.180-host-stage-kit.zip'
    checksums=[]
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as archive:
        for source, name in FILES.items():
            data=(ROOT/source).read_bytes()
            entry=zipfile.ZipInfo(name)
            entry.create_system=3
            entry.external_attr=(stat.S_IFREG | (0o755 if name.endswith('.sh') else 0o644))<<16
            entry.compress_type=zipfile.ZIP_DEFLATED
            archive.writestr(entry,data)
            checksums.append(f'{hashlib.sha256(data).hexdigest()}  {name}')
        archive.writestr('SHA256SUMS','\n'.join(checksums)+'\n')
    sums=[]
    for path in sorted(out.iterdir()):
        if path.is_file() and path.name!='SHA256SUMS':
            sums.append(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}')
    (out/'SHA256SUMS').write_text('\n'.join(sums)+'\n',encoding='utf-8')
    print(target)

if __name__=='__main__': main()
