#!/usr/bin/env python3
"""Validate installed OPM dependency metadata and emit a data-only cpanfile."""
import argparse
import hashlib
import json
from pathlib import Path
import re


def generate(metadata, authoritative_opm=None):
    if not isinstance(metadata, dict) or metadata.get('schema') != 1:
        raise ValueError('Invalid package dependency metadata')
    packages = metadata.get('packages')
    if not isinstance(packages, list) or not 1 <= len(packages) <= 1000:
        raise ValueError('Missing installed package dependencies')
    names = set()
    requirements = {}
    tessera = None
    for package in packages:
        if not isinstance(package, dict) or not isinstance(package.get('name'), str) or not package['name'] or package['name'] in names:
            raise ValueError('Missing or ambiguous installed package identity')
        if not isinstance(package.get('version'), str) or not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._+-]{0,99}', package['version']):
            raise ValueError('Invalid installed package version')
        names.add(package['name'])
        if package['name'] == 'TESSERA-Base':
            tessera = package
        modules = package.get('modules')
        if not isinstance(modules, list) or len(modules) > 1000:
            raise ValueError('Invalid package module requirement list')
        for entry in modules:
            if not isinstance(entry, dict):
                raise ValueError('Invalid module requirement')
            module, minimum = entry.get('module'), entry.get('minimum', '0')
            if not isinstance(module, str) or not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)*', module):
                raise ValueError('Invalid required Perl module name')
            if not isinstance(minimum, str) or not re.fullmatch(r'v?[0-9]+(?:[._][0-9]+)*', minimum):
                raise ValueError('Unsupported required module minimum version')
            requirements.setdefault(module, set()).add(minimum)
    if tessera is None:
        raise ValueError('Installed TESSERA-Base dependency record missing')
    if authoritative_opm is not None:
        import xml.etree.ElementTree as ET
        definition = ET.fromstring(authoritative_opm)
        expected = {(item.text or '', item.get('Version', '0')) for item in definition.findall('ModuleRequired')}
        observed = {(entry['module'], entry.get('minimum', '0')) for entry in tessera['modules']}
        if definition.findtext('Name') != 'TESSERA-Base' or definition.findtext('Version') != tessera['version'] or expected != observed:
            raise ValueError('Dependencies differ from captured authoritative TESSERA OPM')
    lines = ['# Generated from every installed package ModuleRequired declaration.']
    # One declaration per module: Module::CPANfile replaces duplicate declarations.
    # Let CPAN::Meta::Requirements interpret the combined Perl version constraints.
    lines += [f"requires '{module}', '{', '.join('>= ' + v for v in sorted(minima))}';"
              for module, minima in sorted(requirements.items())]
    return '\n'.join(lines) + '\n'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('metadata', type=Path)
    parser.add_argument('opm', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    raw = args.metadata.read_bytes()
    if len(raw) > 4 * 1024 * 1024:
        raise ValueError('Package dependency metadata exceeds budget')
    text = generate(json.loads(raw), args.opm.read_bytes())
    args.output.write_text(text, encoding='utf-8', newline='\n')
    print(f'Captured installed package module requirements; metadata SHA256 {hashlib.sha256(raw).hexdigest()}')


if __name__ == '__main__':
    main()
