#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX test-stack checkout}")
ui="$source_dir/awx/ui"
kit_dir=$(cd "$(dirname "$0")" && pwd)
test -f "$kit_dir/collect-tao-audit.sh"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2 sh -ec '
        npm view glob@14.0.2 version
        npm view minimatch@11.0.1 version
        node <<\NODE
const fs = require("node:fs");
const path = "package.json";
const manifest = JSON.parse(fs.readFileSync(path, "utf8"));
if (manifest.devDependencies.jest !== "30.2.0") throw new Error("Expected Jest 30.2.0");
manifest.overrides ??= {};
for (const parent of ["@jest/reporters", "jest-config", "jest-runtime"]) {
  const scope = (manifest.overrides[parent] ??= {});
  const old = scope.glob;
  const earlier = old && old["."] === "14.0.2" && old.minimatch === "11.0.1"
    && Object.keys(old).length === 2;
  if (typeof scope !== "object" || (old && old !== "14.0.2" && !earlier)) {
    throw new Error("Review existing override for " + parent);
  }
  scope.glob = "14.0.2";
}
for (const [glob, minimatch] of [["glob@14.0.2", "11.0.1"], ["glob@7.1.7", "3.1.5"]]) {
  const scope = (manifest.overrides[glob] ??= {});
  if (typeof scope !== "object" || (scope.minimatch && scope.minimatch !== minimatch)) {
    throw new Error("Review existing override for " + glob);
  }
  scope.minimatch = minimatch;
}
fs.writeFileSync(path, JSON.stringify(manifest, null, 2) + "\n");
NODE
        npm install --package-lock-only --ignore-scripts --no-audit
        npm ls --package-lock-only --all glob minimatch
    '
bash "$kit_dir/collect-tao-audit.sh" "$source_dir"
