#!/usr/bin/env python3
"""Export only migration artifacts; never include the staged application tree."""
import importlib.util
from pathlib import Path
import shutil
import sys

KIT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('bundle_check', KIT / 'image/check-package-bundle.py')
check = importlib.util.module_from_spec(spec)
spec.loader.exec_module(check)


def export(source, destination):
    source, destination = Path(source), Path(destination)
    check.validate(source)
    if destination.exists():
        raise ValueError('Upgrade bundle already exists; use a fresh preparation directory')
    destination.mkdir(parents=True, mode=0o750)
    for name in ('release.json', 'package-modules.json'):
        shutil.copyfile(source / name, destination / name)
    shutil.copytree(source / 'packages', destination / 'packages')
    check.validate(destination)


if __name__ == '__main__':
    export(sys.argv[1], sys.argv[2])
