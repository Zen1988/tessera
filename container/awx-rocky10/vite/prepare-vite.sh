#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX candidate checkout}")
kit_dir=$(cd "$(dirname "$0")" && pwd)
ui="$source_dir/awx/ui"
test "$(git -C "$source_dir" rev-parse HEAD)" = 94e5795dfc37b95c576d61f3e3b4e936c021548c
cp "$kit_dir/vite.config.mjs" "$kit_dir/render-awx-entry.mjs" "$ui/"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-r2 sh -ec '
        node --version
        npm install --save-dev --save-exact --package-lock-only \
          --ignore-scripts --no-audit --force vite@7
        npm pkg set "scripts.build=vite build && node render-awx-entry.mjs"
    '
