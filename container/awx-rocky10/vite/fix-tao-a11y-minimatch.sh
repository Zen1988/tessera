#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the ESLint 10 checkout}")
ui="$source_dir/awx/ui"
kit_dir=$(cd "$(dirname "$0")" && pwd)
test -f "$kit_dir/collect-tao-audit.sh"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2 sh -ec '
        npm pkg set "overrides.eslint-plugin-jsx-a11y.minimatch=11.0.1"
        npm update minimatch --package-lock-only --ignore-scripts --no-audit --strict-peer-deps --engine-strict
        npm ci --dry-run --ignore-scripts --no-audit --strict-peer-deps --engine-strict
        npm ls --package-lock-only --all minimatch
    '
bash "$kit_dir/collect-tao-audit.sh" "$source_dir"
