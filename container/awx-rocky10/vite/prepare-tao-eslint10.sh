#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass a copy of the TAO flat-config checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/eslint.config.cjs"
test -f "$ui/tao-eslint-policy.json"
test -f "$ui/package-lock.json"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2

podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" sh -ec '
        node --version
        npm install --save-dev --save-exact --package-lock-only --ignore-scripts \
          --no-audit --strict-peer-deps --engine-strict eslint@10 @eslint/compat@2
        npm ci --dry-run --ignore-scripts --no-audit --strict-peer-deps --engine-strict
        npm ls --package-lock-only --all eslint
    '
git -C "$source_dir" diff --stat HEAD -- awx/ui/package.json awx/ui/package-lock.json
