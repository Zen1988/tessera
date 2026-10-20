"""Assemble Build180 from a byte-verified179 baseline; no container/deploy calls."""
import argparse
import base64
import copy
import difflib
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BASE_HASH = 'ba2145433ce1e97ea6f3262108c7b21abc0969dce0e08d6cb5ddae8e036d4bf1'
REF_HASH = 'fcf16a14e5608b098413ba9e66b80cbc3268270da594bb578afefee9bbe0dfa3'
CUSTOM = [
    'Custom/Kernel/System/Cache/Redis.pm',
    'Custom/Kernel/System/TESSERA/Secrets.pm',
    'Custom/Kernel/System/TESSERA/SecretRedis.pm',
]
EXTRAS = [
    'docs/build-180-redis-integration.md', 'docs/kubernetes-secrets.md',
    'docs/examples/kubernetes/Config-redis180.pl',
    'docs/examples/kubernetes/Config-secrets.pl',
    'docs/examples/kubernetes/secret-mount.patch.yaml',
    'scripts/test/TESSERA/Secrets.t', 'scripts/test/TESSERA/SecretRedis.t',
    'scripts/test/TESSERA/RedisCustomOverride.t', 'scripts/test/TESSERA/SecretsLive.t',
    'scripts/container/build180.Dockerfile', 'scripts/container/build180.dockerignore',
    'scripts/build_opm.py', 'scripts/package_build180.py',
]

def digest(data):
    return hashlib.sha256(data).hexdigest()

def read_package(path):
    tree = ET.parse(path).getroot()
    files = tree.findall('./Filelist/File')
    payload = {f.attrib['Location']: base64.b64decode(f.text) for f in files}
    assert len(payload) == len(files), 'duplicate package entries'
    for name in payload:
        assert not Path(name).is_absolute() and '..' not in Path(name).parts
    return tree, payload

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--reference', required=True, type=Path)
    args = parser.parse_args()
    reference = args.reference.read_bytes()
    assert digest(reference) == REF_HASH, 'recovered reference identity changed'
    old_path = ROOT / 'Kernel/Package/TESSERA-Base-0.0.179.opm'
    new_path = ROOT / 'Kernel/Package/TESSERA-Base-0.0.180.opm'
    assert digest(old_path.read_bytes()) == BASE_HASH, '179 baseline identity changed'
    old, a = read_package(old_path)
    new, b = read_package(new_path)
    assert old.findtext('Version') == '0.0.179' and new.findtext('Version') == '0.0.180'
    assert len(a) == 339 and len(b) == 340
    assert set(b) - set(a) == {CUSTOM[0]} and not set(a) - set(b)
    assert all(a[p] == b[p] for p in a), 'prior179 payload changed'
    permissions = lambda tree: {f.attrib['Location']: f.attrib['Permission'] for f in tree.findall('./Filelist/File')}
    old_permissions, new_permissions = permissions(old), permissions(new)
    assert all(new_permissions[p] == old_permissions[p] for p in a), 'prior payload permission changed'
    for p, data in b.items():
        assert (ROOT / 'Kernel/Package/GovernanceDB' / p).read_bytes() == data, p
    for p in CUSTOM:
        assert (ROOT / p).read_bytes() == b[p], 'Custom source mirror differs'
    # Ignore only version and filelist; all hooks/schema/metadata must match.
    reduced = []
    for tree in (old, new):
        tree = copy.deepcopy(tree)
        tree.remove(tree.find('Version'))
        tree.remove(tree.find('Filelist'))
        for node in tree.iter():
            if node.text and not node.text.strip(): node.text = None
            node.tail = None
        reduced.append(ET.tostring(tree))
    assert reduced[0] == reduced[1], 'non-file package metadata or DB hooks changed'
    out = ROOT / 'outputs/build-180'
    out.mkdir(parents=True, exist_ok=True)
    context = out / 'container'
    context.mkdir(exist_ok=True)
    for p in CUSTOM:
        target = context / p
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(b[p])
    for source, target in [
        ('scripts/container/build180.Dockerfile', 'Dockerfile'),
        ('scripts/container/build180.dockerignore', '.dockerignore'),
        ('Kernel/Package/TESSERA-Base-0.0.180.opm', new_path.name),
    ]:
        (context / target).write_bytes((ROOT / source).read_bytes())
    # Reject stale or accidental unlisted context files instead of shipping them.
    expected = set(CUSTOM) | {'Dockerfile', '.dockerignore', new_path.name}
    actual = {p.relative_to(context).as_posix() for p in context.rglob('*') if p.is_file()}
    assert actual == expected, 'unexpected container context files'
    (out / new_path.name).write_bytes(new_path.read_bytes())
    diff = ''.join(difflib.unified_diff(
        reference.decode('utf-8').splitlines(True), b[CUSTOM[0]].decode('utf-8').splitlines(True),
        fromfile='recovered/Redis.pm', tofile=CUSTOM[0]))
    (out / 'recovered-redis-to-custom.diff').write_text(diff, encoding='utf-8', newline='\n')
    manifest = {
        'version': '0.0.180', 'baseline_sha256': BASE_HASH,
        'opm_sha256': digest(new_path.read_bytes()), 'recovered_reference_sha256': REF_HASH,
        'baseline_payloads': 339, 'release_payloads': 340,
        'added_payloads': [CUSTOM[0]], 'changed_prior_payloads': [], 'removed_payloads': [],
        'database_migration_added': False, 'container_image_built': False,
        'signed': False, 'live_deployment_modified': False,
        'context_files': {p: digest((context/p).read_bytes()) for p in sorted(expected)},
        'payloads': {p: digest(v) for p,v in sorted(b.items())},
    }
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
    with zipfile.ZipFile(out / 'TESSERA-Base-0.0.180-source.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for p, data in sorted(b.items()): archive.writestr('source/'+p, data)
        for p in EXTRAS: archive.write(ROOT/p, 'release/'+p)
        archive.write(ROOT/'Kernel/Package/GovernanceDB/TESSERA-Base.sopm', 'source/TESSERA-Base.sopm')
        archive.write(out/'manifest.json', 'manifest.json')
        archive.write(out/'recovered-redis-to-custom.diff', 'recovered-redis-to-custom.diff')
    with zipfile.ZipFile(out / 'TESSERA-Base-0.0.180-container-context.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
        for p in sorted(expected): archive.write(context/p, p)
    checksums = []
    for path in sorted(out.iterdir()):
        if path.is_file() and path.name != 'SHA256SUMS':
            checksums.append(f'{digest(path.read_bytes())}  {path.name}')
    (out/'SHA256SUMS').write_text('\n'.join(checksums)+'\n', encoding='utf-8')
    print('Verified339 prior payloads; added1 Custom override; no new DB hooks/schema.')
    print('OPM SHA256:', manifest['opm_sha256'])
    print('Release artifacts:', out)

if __name__ == '__main__':
    main()
