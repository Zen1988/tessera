#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX source checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/package-lock.json"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-r1
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" \
    npm install --package-lock-only --ignore-scripts --no-audit --force \
    --save-prod --save-exact dompurify@3.4.17 axios@1.20.0 js-yaml@4.3.2
git -C "$source_dir" diff --stat -- awx/ui/package.json awx/ui/package-lock.json
