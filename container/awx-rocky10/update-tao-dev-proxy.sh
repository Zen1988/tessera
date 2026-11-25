#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the updated AWX source checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/package-lock.json"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-r1
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" \
    npm install --save-dev --save-exact --package-lock-only \
    --ignore-scripts --no-audit --force http-proxy-middleware@2.0.12
git -C "$source_dir" diff HEAD -- awx/ui/package.json
bash "$(dirname "$0")/collect-tao-audit.sh" "$source_dir"
