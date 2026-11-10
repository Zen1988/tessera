"""Package only the shared generated-asset storage fix; no image/config/credentials."""
import hashlib
from pathlib import Path
import stat
import zipfile

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / 'container/ubuntu2604'
FILES = ['scripts/loader-cache-patch.py', 'examples/shared-loader-cache/pvc.yaml',
         'examples/shared-loader-cache/README.md']


def main():
    output = ROOT / 'outputs/TESSERA-Shared-Loader-Cache-Kit.zip'
    output.parent.mkdir(parents=True, exist_ok=True)
    contents = {name: (KIT / name).read_bytes() for name in FILES}
    contents['README.md'] = contents['examples/shared-loader-cache/README.md']
    checksums = []
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(contents.items()):
            entry = zipfile.ZipInfo(name)
            entry.create_system = 3
            entry.external_attr = (stat.S_IFREG | (0o755 if name.endswith('.py') else 0o644)) << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(entry, data)
            checksums.append(f'{hashlib.sha256(data).hexdigest()}  {name}')
        archive.writestr('SHA256SUMS', '\n'.join(checksums) + '\n')
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.zip.sha256').write_text(f'{digest}  {output.name}\n', encoding='utf-8')
    print(output)
    print('SHA256', digest)


if __name__ == '__main__':
    main()
