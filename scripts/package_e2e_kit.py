"""Bundle the current OPM, source-only container toolkit and public test fixtures."""
import hashlib
from pathlib import Path
import stat
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    version = ET.parse(ROOT / 'Kernel/Package/GovernanceDB/TESSERA-Base.sopm').getroot().findtext('Version')
    package = ROOT / f'Kernel/Package/TESSERA-Base-{version}.opm'
    toolkit = ROOT / 'outputs/TESSERA-Ubuntu26.04-Container-Toolkit.zip'
    files = {package.name: package, toolkit.name: toolkit}
    for name in ('container-version-upgrade.md', 'tessera-182-end-to-end.md', 'awx-integration.md', 'netxms-integration.md', 'tessera-184-network-assessment.md', 'network-cmdb-enforcement-contract.md'):
        files['docs/' + name] = ROOT / 'docs' / name
    for p in (ROOT / 'examples/awx').iterdir():
        if p.is_file() and p.suffix in {'.yml', '.json'}:
            files['examples/awx/' + p.name] = p
    for p in (ROOT / 'examples/netxms').iterdir():
        if p.is_file() and p.suffix in {'.yml', '.json'}:
            files['examples/netxms/' + p.name] = p
    files['webservices/TESSERANetXMS.yml'] = ROOT / 'var/webservices/examples/TESSERANetXMS.yml'
    for p in (ROOT / 'examples/network').rglob('*'):
        if p.is_file() and p.suffix in {'.yml', '.json', '.py'}:
            files['examples/network/' + p.relative_to(ROOT / 'examples/network').as_posix()] = p
    output = ROOT / f'outputs/TESSERA-{version}-End-to-End-Test-Kit.zip'
    sums = []
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, path in sorted(files.items()):
            payload = path.read_bytes()
            entry = zipfile.ZipInfo(name)
            entry.create_system = 3
            entry.external_attr = (stat.S_IFREG | 0o644) << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(entry, payload)
            sums.append(f'{hashlib.sha256(payload).hexdigest()}  {name}')
        archive.writestr('SHA256SUMS', '\n'.join(sums) + '\n')
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.zip.sha256').write_text(f'{digest}  {output.name}\n', encoding='ascii')
    print(f'Bundled {len(files)} public release/test artifacts: {output}')
    print('SHA256', digest)


if __name__ == '__main__':
    main()
