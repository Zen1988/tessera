#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX candidate checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/jest.config.cjs"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-vite-r3 sh -ec '
        node <<\NODE
const fs = require("node:fs");
const source = fs.readFileSync("src/setupTests.js", "utf8");
const old = /require\(["\x27]@babel\/polyfill["\x27]\);/g;
if ([...source.matchAll(old)].length !== 1) throw new Error("Unexpected AWX test setup");
NODE
        npm install --save-dev --save-exact --package-lock-only --ignore-scripts \
          --no-audit core-js@3 regenerator-runtime@0.14
        node <<\NODE
const fs = require("node:fs");
const path = "src/setupTests.js";
const source = fs.readFileSync(path, "utf8");
fs.writeFileSync(path, source.replace(
  /require\(["\x27]@babel\/polyfill["\x27]\);/,
  "require(\"core-js/stable\");\nrequire(\"regenerator-runtime/runtime\");"
));
NODE
        npm uninstall --package-lock-only --ignore-scripts --no-audit @babel/polyfill
    '
