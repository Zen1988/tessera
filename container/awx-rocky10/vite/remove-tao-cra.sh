#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass an isolated copy of the AWX Vite checkout}")
kit_dir=$(cd "$(dirname "$0")" && pwd)
ui="$source_dir/awx/ui"
test -f "$ui/vite.config.mjs"
test -f "$ui/package-lock.json"
mkdir -p "$ui/testUtils"
cp "$kit_dir/jest.config.cjs" "$kit_dir/vite.dev.config.mjs" "$ui/"
cp "$kit_dir/tao-style-stub.cjs" "$kit_dir/tao-asset-stub.cjs" "$ui/testUtils/"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-vite-r3 sh -ec '
        npm pkg delete "overrides.react-scripts" scripts.eject scripts.start-instrumented scripts.prestart-instrumented \
          devDependencies.react-scripts "devDependencies.@cypress/instrument-cra"
        npm pkg set "scripts.start=vite --config vite.dev.config.mjs" \
          "scripts.test=TZ=UTC jest --config jest.config.cjs --watchAll=false" \
          "scripts.test-screens=TZ=UTC jest --config jest.config.cjs screens --watchAll=false" \
          "scripts.test-general=TZ=UTC jest --config jest.config.cjs --testPathIgnorePatterns=src/screens/ --watchAll=false" \
          "scripts.test-watch=TZ=UTC jest --config jest.config.cjs --watch"
        npm install --save-dev --save-exact --package-lock-only --ignore-scripts \
          --no-audit --force jest@29.7.0 babel-jest@29.7.0 \
          jest-environment-jsdom@29.7.0 @babel/preset-env@7
        node -e "const lock = require(process.argv[1]); if (Object.keys(lock.packages).some(path => path.split(String.fromCharCode(47)).pop() === process.argv[2])) process.exit(1)" ./package-lock.json react-scripts
    '
