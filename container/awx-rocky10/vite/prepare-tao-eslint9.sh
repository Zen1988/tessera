#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass a copy of the TAO test-stack checkout}")
kit_dir=$(cd "$(dirname "$0")" && pwd)
ui="$source_dir/awx/ui"
test -f "$ui/.eslintrc.json"
test -f "$ui/package-lock.json"
cp "$kit_dir/eslint.config.cjs" "$kit_dir/tao-eslint-policy.json" "$ui/"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2 sh -ec '
        npm pkg delete devDependencies.eslint-config-airbnb devDependencies.eslint-config-prettier devDependencies.eslint-import-resolver-webpack
        npm install --save-dev --save-exact --package-lock-only --ignore-scripts --no-audit \
          eslint@9 @eslint/compat@1 globals@16 eslint-plugin-import@2 \
          eslint-plugin-react@7 eslint-plugin-react-hooks@5 eslint-plugin-jsx-a11y@6
        npm ci --dry-run --ignore-scripts --no-audit --engine-strict
    '
# Flat config owns ignore patterns. Preserve legacy files in Git history.
git -C "$source_dir" diff --stat HEAD -- awx/ui/package.json awx/ui/package-lock.json
