#!/usr/bin/env python3
"""Validate the complete prepared OPM inventory without loading Config.pm or DB."""
import hashlib
import json
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


def validate(directory, expected=None):
    directory = Path(directory)
    manifest = json.loads((directory / 'package-modules.json').read_text())
    release = json.loads((directory / 'release.json').read_text())
    if manifest.get('schema') != 1 or not manifest.get('packages'):
        raise ValueError('Missing package inventory; prepare a fresh toolkit')
    seen = set()
    for package in manifest['packages']:
        name, version, digest = (package.get(key, '') for key in ('name', 'version', 'package_sha256'))
        if name in seen or not re.fullmatch(r'[A-Za-z0-9_.-]+', name) or not re.fullmatch(r'[0-9]+(?:\.[0-9]+)*', version) or not re.fullmatch(r'[a-f0-9]{64}', digest):
            raise ValueError('Invalid or ambiguous package identity')
        seen.add(name)
        data = (directory / 'packages' / (digest + '.opm')).read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError('Bundled package hash mismatch: ' + name)
        root = ET.fromstring(data)
        if root.findtext('Name') != name or root.findtext('Version') != version:
            raise ValueError('Bundled package identity mismatch: ' + name)
        if name == 'TESSERA-Base' and (version != release['version'] or digest != release['package_sha256']):
            raise ValueError('TESSERA release changed during inventory capture')
    if 'TESSERA-Base' not in seen:
        raise ValueError('TESSERA package missing from inventory')
    if expected is not None:
        for name in ('release.json', 'package-modules.json'):
            if json.loads((directory / name).read_text()) != json.loads((Path(expected) / name).read_text()):
                raise ValueError('Upgrade bundle does not match runtime image: ' + name)


if __name__ == '__main__':
    validate(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None)
