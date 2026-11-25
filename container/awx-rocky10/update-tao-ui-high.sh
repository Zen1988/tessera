#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the updated AWX source checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/package-lock.json"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-r1

# Refresh compatible releases, including parents that may loosen older pins.
# Leave changes across major versions for review after the resulting audit.
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" \
    npm update --package-lock-only --ignore-scripts --no-audit --force \
    @babel/core @babel/plugin-transform-modules-systemjs \
    body-parser brace-expansion braces browserslist compression cross-spawn \
    express flatted http-proxy-middleware js-yaml minimatch nanoid node-forge \
    path-to-regexp picomatch postcss serialize-javascript source-map-js tmp ws \
    webpack-dev-server webpack-dev-middleware

git -C "$source_dir" diff --stat -- awx/ui/package.json awx/ui/package-lock.json
bash "$(dirname "$0")/collect-tao-audit.sh" "$source_dir"
