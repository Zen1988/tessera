"""Build Base0.1.9 from immutable0.1.8 with reviewed simulation/docs deltas."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BASE = '9c9a4554d098204190ebc3b22d51348756b342e9021655e089e9b3ee4093ea55'
FILES = [
    'Kernel/System/TESSERA/CustomerNetworkSimulation.pm',
]


def main():
    old = ROOT / 'Kernel/Package/TESSERA-Base-0.1.8.opm'
    assert hashlib.sha256(old.read_bytes()).hexdigest() == BASE
    baseline = ET.parse(old).getroot()
    payload = {f.get('Location'): base64.b64decode(f.text) for f in baseline.findall('./Filelist/File')}
    changes = {name: (ROOT / name).read_bytes() for name in FILES}
    for source in (ROOT / 'docs').rglob('*'):
        if source.is_file() and source.suffix in ('.md', '.json', '.svg'):
            changes['var/tessera/docs/' + source.relative_to(ROOT / 'docs').as_posix()] = source.read_bytes()
    descriptor = json.loads(payload['var/governancedb/container_release.json'])
    descriptor['version'] = '0.1.9'
    descriptor['upgrade_from'] = list(dict.fromkeys(descriptor['upgrade_from'] + ['0.1.8']))
    changes['var/governancedb/container_release.json'] = (json.dumps(descriptor, indent=2) + '\n').encode()
    package_root = ROOT / 'Kernel/Package/GovernanceDB'
    sopm = package_root / 'TESSERA-Base.sopm'
    definition = sopm.read_text(encoding='utf-8')
    parsed = ET.fromstring(definition)
    assert parsed.findtext('Version') in ('0.1.8', '0.1.9')
    hooks = ['DatabaseInstall', 'DatabaseUpgrade', 'DatabaseUninstall', 'CodeInstall', 'CodeUpgrade', 'CodeReinstall']
    for tag in hooks:
        assert [ET.tostring(n) for n in parsed.findall(tag)] == [ET.tostring(n) for n in baseline.findall(tag)], tag
    definition = definition.replace('<Version>0.1.8</Version>', '<Version>0.1.9</Version>', 1)
    additions = [f'        <File Location="{name}" Permission="660"/>' for name in changes
                 if f'Location="{name}"' not in definition]
    if additions:
        definition = definition.replace('    <Filelist>', '    <Filelist>\n' + '\n'.join(additions), 1)
    stage = ROOT / '.artifacts/base019'
    for name, data in (payload | changes).items():
        target = stage / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    for name, data in changes.items():
        target = package_root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    (ROOT / 'var/governancedb/container_release.json').write_bytes(changes['var/governancedb/container_release.json'])
    sopm.write_text(definition, encoding='utf-8', newline='\n')
    (stage / 'TESSERA-Base.sopm').write_text(definition, encoding='utf-8', newline='\n')
    spec = importlib.util.spec_from_file_location('opm', ROOT / 'scripts/build_opm.py')
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    output = ROOT / 'Kernel/Package/TESSERA-Base-0.1.9.opm'
    count = builder.build(stage / 'TESSERA-Base.sopm', output)
    result = ET.parse(output).getroot()
    actual = {f.get('Location'): base64.b64decode(f.text) for f in result.findall('./Filelist/File')}
    assert actual == payload | changes and len(actual) == count
    for tag in hooks:
        assert [ET.tostring(n) for n in result.findall(tag)] == [ET.tostring(n) for n in baseline.findall(tag)], tag
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.opm.sha256').write_text(digest + '  ' + output.name + '\n', encoding='ascii')
    report = {'version': '0.1.9', 'baseline_sha256': BASE, 'sha256': digest, 'payloads': count,
              'changed': sorted(name for name in payload if payload[name] != actual[name]),
              'new': sorted(actual.keys() - payload.keys()),
              'unchanged': sum(payload[name] == actual[name] for name in payload),
              'hooks_preserved': True, 'deployed': False,
              'navis_requirement': 'Navis0.1.1 ed4ba3e312bd24b0afabc2a2b2949e0aaa9c75a8; migrations through021'}
    (ROOT / 'outputs/base019-validation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'sha256': digest, 'payloads': count, 'changed': len(report['changed']), 'new': len(report['new'])}))


if __name__ == '__main__':
    main()
