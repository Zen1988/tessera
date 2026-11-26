"""Verify this backup without extracting it. Run: python tao/verify-backup.py"""
import hashlib
import json
from pathlib import Path, PurePosixPath
import tarfile

root = Path(__file__).resolve().parent
for line in (root / 'SHA256SUMS').read_text().splitlines():
    expected, name = line.split(None, 1)
    path = root / name.strip().lstrip('*')
    assert path.parent == root, f'Unexpected checksum path: {name}'
    assert hashlib.sha256(path.read_bytes()).hexdigest() == expected, name
    print('Verified', path.name)
with tarfile.open(root / 'application-source.tar.gz') as archive:
    members = archive.getmembers()
    for member in members:
        path = PurePosixPath(member.name)
        assert not path.is_absolute() and '..' not in path.parts, member.name
    for line in (root / 'source-inputs.sha256').read_text().splitlines():
        expected, name = line.split(None, 1)
        name = name.strip()
        stream = archive.extractfile('./' + name)
        assert stream is not None, name
        assert hashlib.sha256(stream.read()).hexdigest() == expected, name
    def read(name):
        return archive.extractfile('./' + name).read()
    assert json.loads(read('awx/ui/.linguirc'))['compileNamespace'] == 'es'
    assert b'./locales/${locale}/messages.mjs`' in read('awx/ui/src/i18nLoader.js')
    vendors = [m for m in members if m.isfile() and
               m.name.startswith('./awx/ui/vendor/') and m.name.endswith('.tgz')]
    assert len(vendors) == 5, 'Expected five vendor packages'
    lock = json.loads(read('awx/ui/package-lock.json'))
    assert not any(p.get('deprecated') for p in lock['packages'].values())
print('All recorded source hashes, translation configuration and vendor packages verified')
