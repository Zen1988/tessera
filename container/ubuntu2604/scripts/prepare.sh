#!/usr/bin/env bash
set -euo pipefail
KIT=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
[[ $# -le 2 ]] || { echo 'Usage: prepare.sh [/opt/otobo] [/path/to/existing-entrypoint.sh]' >&2; exit 1; }
SOURCE=$(realpath -e -- "${1:-/opt/otobo}")
for tool in rsync python3 realpath perl; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }; done
[[ -d "$SOURCE/Kernel" && -f "$SOURCE/bin/otobo.CheckModules.pl" ]] || { echo 'Not an installed OTOBO source tree' >&2; exit 1; }
[[ "$KIT" != "$SOURCE" && "$KIT" != "$SOURCE/"* ]] || { echo 'Kit must be outside the application source' >&2; exit 1; }
[[ ! -e "$KIT/app" && ! -L "$KIT/app" ]] || { echo 'app already exists; build it or use a fresh kit (no automatic overwrite)' >&2; exit 1; }
if [[ $# == 2 ]]; then
    [[ -f "$2" ]] || { echo 'Supplied site entrypoint missing' >&2; exit 1; }
    cp -- "$2" "$KIT/image/site-entrypoint.sh"
    chmod 0755 "$KIT/image/site-entrypoint.sh"
fi
STAGE=$(mktemp -d "$KIT/.source.XXXXXXXX")
PRIVILEGE=()
if (( EUID != 0 )); then command -v sudo >/dev/null; PRIVILEGE=(sudo); fi
"${PRIVILEGE[@]}" rsync -rlptog --no-specials --no-devices \
    --chown="$(id -u):$(id -g)" --exclude-from="$KIT/scripts/source.exclude" "$SOURCE/" "$STAGE/"
python3 "$KIT/image/audit-app.py" "$STAGE" --inventory "$KIT/dependencies/source-sha256.json"
mkdir -p "$KIT/dependencies"
# Generate requirements from this installed version, not from another checkout.
env -u PERL5OPT -u PERL5LIB /usr/bin/perl "$STAGE/bin/otobo.CheckModules.pl" --docker-cpanfile > "$KIT/dependencies/cpanfile.new"
grep -q 'requires ' "$KIT/dependencies/cpanfile.new" || { echo 'Dependency generation failed' >&2; exit 1; }
mv -- "$KIT/dependencies/cpanfile.new" "$KIT/dependencies/cpanfile"
python3 - "$KIT/dependencies/host-summary.json" <<'PY'
import json,platform,subprocess,sys
release={}
for line in open('/etc/os-release'):
    if '=' in line:
        k,v=line.strip().split('=',1)
        if k in ('ID','VERSION_ID','VERSION_CODENAME'): release[k]=v.strip('"')
release['architecture']=platform.machine()
release['system_perl']=subprocess.check_output(['/usr/bin/perl','-e','print $^V'],text=True)
with open(sys.argv[1],'w') as output: output.write(json.dumps(release,indent=2)+'\n')
if release.get('ID')!='ubuntu' or release.get('VERSION_ID')!='26.04':
    raise SystemExit('This kit targets Ubuntu26.04. Source is copied privately; check base compatibility before continuing.')
PY
mv -T -n -- "$STAGE" "$KIT/app"
[[ ! -d "$STAGE" ]] || { echo 'Another app appeared; private stage retained' >&2; exit 1; }
printf '\nInstalled source copied unchanged apart from exclusions. No OPM restored or installed.\n'
printf 'Next: review app/ and integration dependencies, then bash scripts/build.sh\n'
