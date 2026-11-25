#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass a copy of the Lingui 4 checkout}")
ui="$source_dir/awx/ui"
kit_dir=$(cd "$(dirname "$0")" && pwd)
test -f "$ui/package-lock.json"
test -f "$kit_dir/collect-tao-audit.sh"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2

podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" sh -ec '
        node -e "if (require(process.argv[1]).devDependencies[process.argv[2]] !== process.argv[3]) throw new Error(\"Expected the tested Lingui 4 manifest\")" ./package.json @lingui/cli 4.14.1
        npm view esbuild@0.25.0 version
        npm pkg set "overrides.@lingui/cli.esbuild=0.25.0"
        npm update --package-lock-only --ignore-scripts --no-audit \
          @adobe/css-tools @babel/runtime-corejs3 ajv micromatch diff esbuild
        npm ls --package-lock-only --all esbuild @adobe/css-tools @babel/runtime-corejs3 ajv micromatch diff
    '
bash "$kit_dir/collect-tao-audit.sh" "$source_dir"
