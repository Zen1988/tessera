#!/usr/bin/env python3
"""Seed image definitions without copying filesystem metadata; rebuild then stamp."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

SOURCE = Path('/opt/tessera/config-files.dist')
DESTINATION = Path('/opt/otobo/Kernel/Config/Files')
DIGEST = Path('/opt/tessera/config-definitions.sha256')
MARKER = '.tessera-config-definitions.sha256'
GENERATED = ('ZZZAAuto.pm', 'ZZZACL.pm', 'ZZZProcessManagement.pm')


def source_files(source):
    """Validate the entire source before modifying the mounted destination."""
    source = Path(source)
    if source.is_symlink() or not source.is_dir():
        raise ValueError('Packaged configuration source must be a directory')
    files = []
    def walk_error(error):
        raise error
    for current, dirs, names in os.walk(source, onerror=walk_error):
        for name in dirs + names:
            path = Path(current) / name
            if path.is_symlink():
                raise ValueError('Packaged configuration must not contain symlinks')
        for name in sorted(names):
            path = Path(current) / name
            if not path.is_file():
                raise ValueError('Packaged configuration must contain regular files')
            with path.open('rb') as stream:
                # Read all bytes as the effective runtime user, not just stat permissions.
                while stream.read(1024 * 1024):
                    pass
            files.append(path.relative_to(source))
    if not files:
        raise ValueError('Packaged configuration source is empty')
    return sorted(files)


def directory(path):
    if path.is_symlink():
        raise ValueError('Configuration destination must not contain symlinks')
    # Existing NFS directories keep their owner, permissions and timestamps.
    path.mkdir(mode=0o750, exist_ok=True)
    if not path.is_dir():
        raise ValueError('Configuration destination requires a directory')


def configure(source, destination, digest, command, cwd):
    source, destination, digest = map(Path, (source, destination, digest))
    files = source_files(source)
    fingerprint = digest.read_bytes()
    if len(fingerprint.strip()) != 64 or any(c not in b'0123456789abcdef' for c in fingerprint.strip()):
        raise ValueError('Packaged configuration fingerprint is invalid')
    directory(destination)
    # Preflight every target path, including its parents, before seeding.
    for relative in files:
        parent = destination
        for part in relative.parts[:-1]:
            parent = parent / part
            if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
                raise ValueError('Unsafe configuration destination directory')
        target = destination / relative
        if target.is_symlink() or (target.exists() and not target.is_file()):
            raise ValueError('Unsafe configuration destination file')
    marker = destination / MARKER
    if marker.is_symlink():
        raise ValueError('Configuration fingerprint must not be a symlink')
    # A failed reconfigure must not leave an old success marker behind.
    marker.unlink(missing_ok=True)
    for relative in files:
        parent = destination
        for part in relative.parts[:-1]:
            parent = parent / part
            directory(parent)
        target = destination / relative
        flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC | getattr(os, 'O_NOFOLLOW', 0)
        # New files belong to the runtime user and are owner-writable; existing
        # files retain their mode/ownership. No chmod/chown/utime/copystat calls.
        with (source / relative).open('rb') as incoming:
            with os.fdopen(os.open(target, flags, 0o640), 'wb') as outgoing:
                shutil.copyfileobj(incoming, outgoing)
    subprocess.run(command, cwd=cwd, check=True)
    for name in GENERATED:
        generated = destination / name
        if generated.is_symlink() or not generated.is_file():
            raise ValueError('Rebuild did not produce all required configuration files')
        with generated.open('rb'):
            pass
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='wb', prefix='.tessera-config-', dir=destination, delete=False) as output:
            temporary = Path(output.name)
            output.write(fingerprint)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, marker)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    try:
        if sys.argv[1:] == ['check-source']:
            files = source_files(SOURCE)
            if any(os.access(SOURCE / p, os.W_OK) for p in [Path('.'), *files]):
                raise ValueError('Packaged definitions must not be writable by the runtime user')
            print(f'Packaged configuration readable and immutable for UID {os.geteuid()}: {len(files)} files')
        elif not sys.argv[1:]:
            configure(SOURCE, DESTINATION, DIGEST,
                      ['/usr/bin/perl', 'bin/otobo.Console.pl', 'Maint::Config::Rebuild',
                       '--deploy-acls', '--deploy-processes'], '/opt/otobo')
            print('TESSERA: Configuration rebuilt and fingerprint published')
        else:
            raise ValueError('Unsupported configure helper arguments')
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        # Do not echo exception details or captured configuration contents.
        print('TESSERA: Configuration failed; check source readability, volume access and rebuild result '
              f'({type(error).__name__}). No new success fingerprint published.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
