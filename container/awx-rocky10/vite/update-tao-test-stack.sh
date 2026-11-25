#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass an isolated copy of the audited checkout}")
kit_dir=$(cd "$(dirname "$0")" && pwd)
ui="$source_dir/awx/ui"
test -f "$ui/jest.config.cjs"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2

cp "$kit_dir/tao-jest-environment.cjs" "$ui/"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" sh -ec '
        npm pkg delete devDependencies.jest-environment-jsdom "devDependencies.@babel/polyfill" overrides.jsdom
        npm install --save-dev --save-exact --package-lock-only --ignore-scripts --no-audit \
          jest@30.2.0 babel-jest@30.2.0 @jest/environment-jsdom-abstract@30.2.0 \
          jsdom@29.1.1 core-js@3
        node <<\NODE
const fs = require("node:fs");
const removed = new Set(["whatwg-encoding", "domexception", "abab", "@babel/polyfill"]);
const lock = require("./package-lock.json");
for (const path of Object.keys(lock.packages)) {
  const name = path.replace(/^.*(?:^|\/)node_modules\//, "");
  if (removed.has(name)) throw new Error(name + " still present at " + path);
}
const edits = [
  ["src/setupTests.js", /require\(["\x27]@babel\/polyfill["\x27]\);/g, "require(\"core-js/stable\");"],
  ["jest.config.cjs", /testEnvironment: ["\x27]jsdom["\x27]/g,
    "testEnvironment: \"<rootDir>/tao-jest-environment.cjs\""],
];
const updates = edits.map(([path, old, replacement]) => {
  const source = fs.readFileSync(path, "utf8");
  if ([...source.matchAll(old)].length !== 1) throw new Error("Unexpected " + path);
  return [path, source.replace(old, replacement)];
});
for (const [path, source] of updates) fs.writeFileSync(path, source);
NODE
    '
