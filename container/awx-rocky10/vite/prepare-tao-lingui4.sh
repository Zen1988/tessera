#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass a copy of the verified no-CRA checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/vite.config.mjs"
test -f "$ui/package-lock.json"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-no-cra-r2

podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" sh -ec '
        npm pkg set "dependencies.@lingui/react=4.14.1" \
          "devDependencies.@lingui/cli=4.14.1" \
          "devDependencies.@lingui/macro=4.14.1" \
          "devDependencies.@lingui/loader=4.14.1"
        npm install --package-lock-only --ignore-scripts --no-audit
        node -e "const packages = require(process.argv[1]).packages; if (Object.keys(packages).some(path => path.split(String.fromCharCode(47)).pop() === process.argv[2])) throw new Error(process.argv[2] + \" remains in the lockfile\")" ./package-lock.json node-gettext
    '
git -C "$source_dir" diff --stat HEAD -- awx/ui/package.json awx/ui/package-lock.json
