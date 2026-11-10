"""Package the standalone preparation project; never mutate an OPM."""
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def package():
    files = sorted(p for p in (ROOT / 'examples/navis').iterdir() if p.is_file() and p.suffix in ('.py', '.yml', '.json'))
    files += [ROOT / p for p in ('docs/navis-firewall-preparation.md', 'docs/integration-onboarding.md', 'scripts/package_navis_kit.py',
              'scripts/test/TESSERA/test_navis_workflow.py', 'scripts/test/TESSERA/NavisPreparation.t')]
    target = ROOT / 'outputs/TESSERA-Navis-Firewall-Preparation-Kit.zip'
    target.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, path.relative_to(ROOT).as_posix())
    checksum = hashlib.sha256(target.read_bytes()).hexdigest()
    target.with_suffix('.zip.sha256').write_text(checksum + '  ' + target.name + '\n', encoding='ascii')
    print(f'{target.name}: {len(files)} files, SHA256 {checksum}')


if __name__ == '__main__':
    package()
