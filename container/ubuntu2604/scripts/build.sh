#!/usr/bin/env bash
set -euo pipefail
KIT=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$KIT"
[[ -d app && -s dependencies/cpanfile && -s dependencies/cpanfile.packages && -s dependencies/package-modules.json && -s dependencies/host-summary.json ]] || { echo 'Preparation is incomplete. Run prepare.sh successfully in a fresh kit before build.sh.' >&2; exit 1; }
command -v docker >/dev/null || { echo 'Docker Engine/buildx required' >&2; exit 1; }
python3 image/audit-app.py app --inventory dependencies/source-sha256.json
exec python3 scripts/release.py build
