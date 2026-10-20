#!/usr/bin/env bash
set -euo pipefail
# Run as a regular user on the existing Linux host; sudo reads protected source.
# Usage: stage-host-app.sh KIT_DIR BUILD180_OPM CLEAN_CORE_REDIS_PM
# CLEAN_CORE_REDIS_PM is the unchanged core file from this release's reference
# kit, NOT the live host's Kubernetes-patched core Redis.pm.
[[ $# == 3 ]] || { echo 'Usage: stage-host-app.sh KIT_DIR BUILD180_OPM CLEAN_CORE_REDIS_PM' >&2; exit 1; }
for tool in rsync python3 realpath sudo; do
    command -v "$tool" >/dev/null || { echo "Required tool unavailable: $tool" >&2; exit 1; }
done
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
KIT_DIR=$(realpath -e -- "$1")
OPM=$(realpath -e -- "$2")
CORE_REDIS=$(realpath -e -- "$3")
[[ -d "$KIT_DIR" && "$KIT_DIR" != / && "$KIT_DIR" != /opt && "$KIT_DIR" != /opt/otobo && "$KIT_DIR" != /opt/otobo/* ]] || {
    echo 'Kit directory must be outside /opt/otobo and not a system root' >&2; exit 1;
}
[[ -d /opt/otobo/Kernel ]] || { echo '/opt/otobo/Kernel not found' >&2; exit 1; }
[[ -f "$SCRIPT_DIR/host-stage.exclude" ]] || { echo 'Exclusion file missing' >&2; exit 1; }
[[ ! -e "$KIT_DIR/app" && ! -L "$KIT_DIR/app" ]] || {
    echo 'Refusing to reuse app; choose a fresh kit directory' >&2; exit 1;
}
# Verify before copying. No credential values are printed by these checks.
python3 - "$OPM" "$CORE_REDIS" <<'PY'
import hashlib, pathlib, sys
expected = ('3a0411893bb8f9dc07dede542f924e5ae36970b87cefd9d5a255958a64b1d315',
            'be832371af13f317045d836649ea436709ab5f1c711704bee48038239180183a')
for name, digest in zip(sys.argv[1:], expected):
    if hashlib.sha256(pathlib.Path(name).read_bytes()).hexdigest() != digest:
        raise SystemExit('Release/reference identity mismatch; staging stopped')
PY
STAGING=$(mktemp -d -- "$KIT_DIR/.app180.XXXXXXXX")
printf 'Private staging directory: %s\n' "$STAGING"
# Never reuse a previous stage: --delete does not remove excluded stale files.
# Preserve symlinks without dereferencing; reject external ones below.
sudo rsync -rlptog --no-devices --no-specials \
    --chown="$(id -u):$(id -g)" \
    --exclude-from="$SCRIPT_DIR/host-stage.exclude" \
    /opt/otobo/ "$STAGING/"
python3 - "$STAGING" "$OPM" "$CORE_REDIS" <<'PY'
import base64, hashlib, os, pathlib, shutil, sys, xml.etree.ElementTree as ET
root = pathlib.Path(sys.argv[1]).resolve()
def contained(path):
    try:
        path.resolve().relative_to(root)
    except (ValueError, RuntimeError):
        raise SystemExit('External or looping symlink in stage; inspect privately')
# Do not traverse any link during package restoration, even internal ones: a
# package path must not redirect a write into a different application path.
for directory, dirs, files in os.walk(root, followlinks=False):
    for name in dirs + files:
        path = pathlib.Path(directory) / name
        if path.is_symlink(): contained(path)
tree = ET.parse(sys.argv[2])
files = tree.findall('./Filelist/File')
if tree.findtext('Version') != '0.0.180' or len(files) != 340:
    raise SystemExit('Unexpected package structure')
for entry in files:
    relative = pathlib.PurePosixPath(entry.attrib['Location'])
    if relative.is_absolute() or '..' in relative.parts:
        raise SystemExit('Unsafe package path')
    path = root.joinpath(*relative.parts)
    for ancestor in [path, *path.parents]:
        if ancestor == root: break
        if ancestor.is_symlink():
            raise SystemExit('Symlink on package write path; inspect privately')
    path.parent.mkdir(parents=True, exist_ok=True)
    data = base64.b64decode(entry.text)
    path.write_bytes(data)
    # Use runtime-readable, non-executable source files in the image context.
    path.chmod(int(entry.attrib['Permission'], 8) | 0o044)
    if path.read_bytes() != data: raise SystemExit('Package restoration mismatch')
# Revert the recovered core patch in the STAGE ONLY; Custom now owns auth.
target = root / 'Kernel/System/Cache/Redis.pm'
for ancestor in [target, *target.parents]:
    if ancestor == root: break
    if ancestor.is_symlink(): raise SystemExit('Symlink on core write path')
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(sys.argv[3], target)
target.chmod(0o644)
if (root/'Kernel/Config.pm').exists() or (root/'Kernel/Config.pm').is_symlink():
    raise SystemExit('SECURITY ERROR: Config.pm staged')
# Structural checks only: this is not proof that arbitrary source lacks secrets.
for directory, dirs, names in os.walk(root, followlinks=False):
    for name in names:
        path = pathlib.Path(directory)/name
        if path.is_symlink(): continue
        if not path.is_file(): raise SystemExit('Nonregular file in stage')
        with path.open('rb') as stream:
            sample = stream.read(4096)
        if any(marker in sample.splitlines() for marker in (
            b'-----BEGIN PRIVATE KEY-----', b'-----BEGIN RSA PRIVATE KEY-----',
            b'-----BEGIN EC PRIVATE KEY-----', b'-----BEGIN OPENSSH PRIVATE KEY-----',
            b'-----BEGIN ENCRYPTED PRIVATE KEY-----')):
            raise SystemExit('SECURITY ERROR: private-key material detected; inspect privately')
manifest = {}
for directory, dirs, names in os.walk(root, followlinks=False):
    for name in sorted(names):
        p=pathlib.Path(directory)/name
        if not p.is_symlink():
            h=hashlib.sha256()
            with p.open('rb') as f:
                for chunk in iter(lambda:f.read(1048576), b''): h.update(chunk)
            manifest[p.relative_to(root).as_posix()]=h.hexdigest()
import json
inventory = root.parent/(root.name+'.inventory.json')
inventory.write_text(json.dumps(manifest,indent=2)+'\n')
inventory.chmod(0o600)
print('Restored and verified all340 Build180 payloads; core Redis reference restored in stage only.')
PY
# No-clobber publication; refuse a destination created by another staging run.
mv -T -n -- "$STAGING" "$KIT_DIR/app"
[[ ! -d "$STAGING" ]] || { echo 'app appeared concurrently; stage retained privately' >&2; exit 1; }
printf '\nStaged size:\n'
du -sh -- "$KIT_DIR/app"
printf '\nSTOP: review inventory and staged content for deployment-specific secrets.\n'
printf 'Config/ACL/process generation, volume permissions, dependencies and startup still require Linux acceptance.\n'
# This script does not run Docker, modify /opt/otobo, change DBs or deploy Pods.
