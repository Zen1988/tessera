#!/usr/bin/env python3
"""Prepare an isolated writable application tree at the same runtime mount path."""
from pathlib import Path
import os
import shutil
import sys


def validate_source(source):
    source = Path(source)
    if source.is_symlink() or not source.is_dir():
        raise ValueError('Invalid upgrade source')
    if any(p.is_symlink() for p in source.rglob('*')):
        raise ValueError('Upgrade source cannot contain symlinks')


def stage(source, destination):
    source, destination = Path(source), Path(destination)
    validate_source(source)
    if source.is_symlink() or not source.is_dir() or destination.is_symlink():
        raise ValueError('Invalid upgrade workspace')
    destination.mkdir(parents=True, exist_ok=True)
    if any(destination.iterdir()):
        raise ValueError('Upgrade workspace must be empty')
    for root, dirs, files in os.walk(source):
        relative = Path(root).relative_to(source)
        for name in dirs + files:
            if (Path(root) / name).is_symlink():
                raise ValueError('Upgrade source cannot contain symlinks')
        target = destination / relative
        target.mkdir(parents=True, exist_ok=True, mode=0o750)
        for name in files:
            if relative == Path('Kernel') and name.startswith('Config.pm'):
                continue  # target configuration is mounted separately
            incoming, outgoing = Path(root) / name, target / name
            with incoming.open('rb') as src, outgoing.open('xb') as dst:
                shutil.copyfileobj(src, dst)
            executable = relative.parts and (relative.parts[0] == 'bin' or relative.parts[:2] == ('local', 'bin'))
            outgoing.chmod(0o750 if executable else 0o640)


if __name__ == '__main__':
    try:
        if len(sys.argv) == 3 and sys.argv[1] == 'check-source':
            validate_source(sys.argv[2])
        elif len(sys.argv) == 1:
            stage('/opt/otobo', '/work/application')
        else:
            raise ValueError('Invalid upgrade-stage arguments')
    except Exception:
        raise SystemExit('TESSERA upgrade workspace preparation failed') from None
