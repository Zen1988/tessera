#!/usr/bin/env python3
"""Installed-source version capture and serialized, append-only image revisions."""
import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import base64
import xml.etree.ElementTree as ET

KIT = Path(__file__).resolve().parents[1]
SUFFIX = 'ubuntu26.04'


def version(value):
    if not isinstance(value, str) or not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+', value):
        raise ValueError('Missing or invalid prepared TESSERA-Base version; run preparation in a fresh kit')
    return value


def detect(source):
    # Capture all output privately; publish only a validated version, never errors
    # from the installed configuration, database or custom modules.
    result = subprocess.run(['/usr/bin/perl', str(KIT / 'scripts/installed-version.pl'), str(Path(source).resolve())],
                            capture_output=True, text=True, env={k: v for k, v in os.environ.items()
                                                               if k not in ('PERL5OPT', 'PERL5LIB')})
    if result.returncode:
        raise ValueError('Cannot read installed TESSERA-Base version; verify source-host DB access and package installation')
    return version(result.stdout.strip())


def atomic_json(path, data):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=path.parent, delete=False) as output:
            temporary = Path(output.name)
            json.dump(data, output, indent=2, sort_keys=True)
            output.write('\n')
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def upgrade_bundle(source, package_version, output):
    source, output = Path(source), Path(output)
    descriptor = json.loads((source / 'var/governancedb/container_release.json').read_text())
    if descriptor.get('package') != 'TESSERA-Base' or descriptor.get('version') != package_version:
        raise ValueError('Install the release with container upgrade support before preparing this toolkit')
    origins = descriptor.get('upgrade_from')
    if not isinstance(origins, list) or any(version(v) == package_version for v in origins):
        raise ValueError('Invalid supported upgrade paths')
    artifact = output.parent / 'package.opm'
    subprocess.run(['/usr/bin/perl', str(KIT / 'scripts/export-package.pl'), str(source.resolve()), package_version, str(artifact.resolve())],
                   check=True, capture_output=True, env={k: v for k, v in os.environ.items() if k not in ('PERL5OPT', 'PERL5LIB')})
    content = artifact.read_bytes()
    root = ET.fromstring(content)
    if root.findtext('Name') != 'TESSERA-Base' or root.findtext('Version') != package_version:
        raise ValueError('Exported package does not match installed release')
    # Verify source preparation includes the actual installed package payload.
    for entry in root.findall('./Filelist/File'):
        name = entry.get('Location', '')
        relative = Path(name)
        if relative.is_absolute() or '..' in relative.parts or '\\' in name:
            raise ValueError('Unsafe package location')
        if entry.get('Encode') != 'Base64' or (source / relative).read_bytes() != base64.b64decode(entry.text or ''):
            raise ValueError('Installed source differs from its authoritative package payload')
    return {'package_sha256': hashlib.sha256(content).hexdigest(), 'upgrade_from': origins}


def tag(repository, package_version, revision):
    version(package_version)
    if not re.fullmatch(r'[a-z0-9][a-z0-9._:/-]*', repository) or '://' in repository or '@' in repository:
        raise ValueError('Use an untagged image repository, without credentials or URL scheme')
    # A colon is allowed in registry host:port, not in the final repository name.
    if ':' in repository.rsplit('/', 1)[-1]:
        raise ValueError('TESSERA_IMAGE_REPOSITORY must not include a tag')
    revision_part = '' if revision == 0 else f'-r{revision}'
    return f'{repository}:{package_version}{revision_part}-{SUFFIX}'


def next_revision(repository, package_version, previous, images):
    if type(previous) is not int or previous < -1:
        raise ValueError('Build revision history is invalid; preserve it and investigate before rebuilding')
    pattern = re.compile(re.escape(f'{repository}:{package_version}') + r'(?:-r([1-9][0-9]*))?-' + SUFFIX + r'\Z')
    used = [previous]
    for image in images:
        match = pattern.fullmatch(image)
        if match:
            used.append(int(match[1] or 0))
    return max(used) + 1


def runtime_inventory(image):
    data = json.loads(subprocess.check_output(['docker', 'run', '--rm', image, '/bin/cat',
                                              '/opt/tessera/dependencies/perl-runtime.json'], text=True))
    if not isinstance(data, dict) or any(not isinstance(data.get(key), str) for key in ('executable', 'version', 'archname', 'policy')) \
            or data.get('executable') != '/usr/bin/perl' or data.get('policy') != 'target-os-system-perl' \
            or not re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+', data.get('version', '')) \
            or not re.fullmatch(r'[A-Za-z0-9_.-]{1,160}', data.get('archname', '')):
        raise ValueError('Built image Perl runtime inventory is invalid')
    return {key: data[key] for key in ('executable', 'version', 'archname', 'policy')}


@contextmanager
def locked(path):
    import fcntl  # Linux build host; policy/selection unit tests also run on Windows.
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a') as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError('Another build is using this repository/version; retry after it finishes') from None
        try:
            yield
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def build():
    if os.environ.get('TESSERA_IMAGE'):
        raise ValueError('Use TESSERA_IMAGE_REPOSITORY without a tag; image revisions are now automatic')
    metadata_path = KIT / 'dependencies/release.json'
    if not metadata_path.is_file():
        raise ValueError('Prepared version metadata missing; use prepare.sh in a fresh kit, do not guess from old OPM files')
    metadata = json.loads(metadata_path.read_text())
    if metadata.get('package') != 'TESSERA-Base':
        raise ValueError('Prepared package identity is invalid')
    package_version = version(metadata.get('version'))
    dependency_policy = os.environ.get('TESSERA_DEPENDENCY_POLICY', 'latest')
    if dependency_policy not in ('latest', 'cached'):
        raise ValueError('TESSERA_DEPENDENCY_POLICY must be latest or cached')
    repository = os.environ.get('TESSERA_IMAGE_REPOSITORY', 'tessera')
    tag(repository, package_version, 0)  # validate before Docker/state operations
    state_root = Path(os.environ.get('TESSERA_BUILD_STATE_DIR',
                                     Path.home() / '.local/state/tessera-container-kit'))
    key = hashlib.sha256(repository.encode()).hexdigest()[:24] + '-' + package_version
    state_path = state_root / (key + '.json')
    with locked(state_root / (key + '.lock')):
        state = json.loads(state_path.read_text()) if state_path.exists() else {
            'repository': repository, 'package_version': package_version, 'last_revision': -1, 'attempts': []}
        if state.get('repository') != repository or state.get('package_version') != package_version:
            raise ValueError('Build state identity mismatch')
        if not isinstance(state.get('attempts'), list):
            raise ValueError('Build revision history is invalid')
        images = subprocess.check_output(['docker', 'image', 'ls', '--format', '{{.Repository}}:{{.Tag}}'], text=True).splitlines()
        revision = next_revision(repository, package_version, state['last_revision'], images)
        image = tag(repository, package_version, revision)
        record = {'tag': image, 'revision': revision, 'status': 'building',
                  'started_at': datetime.now(timezone.utc).isoformat(),
                  'dependency_policy': dependency_policy}
        refresh = record['started_at'] + '-revision-' + str(revision) if dependency_policy == 'latest' else 'cached'
        record['dependency_refresh'] = refresh
        state['last_revision'] = revision
        state['attempts'].append(record)
        atomic_json(state_path, state)  # failed/interrupted attempts never reuse a tag
        print(f'Building installed TESSERA-Base {package_version}: {image}', flush=True)
        try:
            subprocess.run(['docker', 'build', '--pull',
                            '--build-arg', 'TESSERA_DEPENDENCY_REFRESH=' + refresh,
                            '--build-arg', 'BASE_IMAGE=' + os.environ.get('BASE_IMAGE', 'ubuntu:26.04'),
                            '--build-arg', 'OTOBO_UID=' + os.environ.get('OTOBO_UID', '10001'),
                            '--build-arg', 'OTOBO_GID=' + os.environ.get('OTOBO_GID', '33'),
                            '--build-arg', 'TESSERA_VERSION=' + package_version,
                            '--build-arg', 'TESSERA_IMAGE_REVISION=' + ('base' if revision == 0 else f'r{revision}'),
                            '--tag', image, '.'], cwd=KIT, check=True)
            subprocess.run(['docker', 'run', '--rm', image, 'modules'], check=True)
            inspection = json.loads(subprocess.check_output(['docker', 'image', 'inspect', image], text=True))
            record.update(status='success', image_id=inspection[0]['Id'],
                          package_version=package_version, repository=repository,
                          perl_runtime=runtime_inventory(image),
                          source_inventory_sha256=hashlib.sha256((KIT / 'dependencies/source-sha256.json').read_bytes()).hexdigest())
            receipt = KIT / 'artifacts/builds' / f'{key}-revision-{revision}.json'
            atomic_json(receipt, record)
            atomic_json(KIT / 'artifacts/latest-build.json', record)
            atomic_json(KIT / 'artifacts/image-inspect.json', inspection)
            (KIT / 'artifacts/image-id.txt').write_text(record['image_id'] + '\n')
        except BaseException:
            record['status'] = 'failed'
            atomic_json(state_path, state)
            raise
        atomic_json(state_path, state)
        print(f'Built {image}\nReceipt: {receipt}\nReal DB/Redis/TLS/persistence acceptance remains required.')
        print(f'Export: docker save {image} | gzip > tessera-{package_version}-revision-{revision}.tar.gz')


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest='action', required=True)
    check = commands.add_parser('detect')
    check.add_argument('source')
    capture = commands.add_parser('capture')
    capture.add_argument('source')
    capture.add_argument('expected_version')
    capture.add_argument('output', type=Path)
    commands.add_parser('build')
    args = parser.parse_args()
    try:
        if args.action == 'detect':
            print(detect(args.source))
        elif args.action == 'capture':
            observed = detect(args.source)
            if observed != version(args.expected_version):
                raise ValueError('Installed package changed during preparation; use a fresh kit after upgrades finish')
            atomic_json(args.output, {'package': 'TESSERA-Base', 'version': observed,
                                     **upgrade_bundle(Path(args.source), observed, args.output),
                                     'version_source': 'installed-package-registry',
                                     'prepared_at': datetime.now(timezone.utc).isoformat()})
        else:
            build()
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        # Docker emits its own build output. Never print captured host/inspect output.
        if isinstance(error, FileNotFoundError):
            message = f'Required file not found: {error.filename}'
        else:
            message = str(error) if isinstance(error, ValueError) else type(error).__name__
        print(f'TESSERA toolkit: {message}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
