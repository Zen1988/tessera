#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the ESLint 10 checkout}")
mode=${2:-lint}
case "$mode" in
    lint) report=eslint-effective.json ;;
    --preview-fixes) report=eslint-autofix.patch ;;
    *) printf 'Expected --preview-fixes or no second argument\n' >&2; exit 2 ;;
esac
ui="$source_dir/awx/ui"
reports=$(mktemp -d "$PWD/tao-eslint10.XXXXXX")
printf 'Reports: %s\n' "$reports"
sha256sum "$ui/package.json" "$ui/package-lock.json" > "$reports/ui-inputs.sha256"
podman run --rm --pull=never --timeout=300 \
    -v "$ui:/source:ro,Z" \
    localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2 \
    bash -euo pipefail -c '
        mkdir /tmp/tao-lint
        tar -C /source --exclude=./node_modules --exclude=./build -cf - . |
            tar -xf - -C /tmp/tao-lint
        cd /tmp/tao-lint
        npm ci --no-audit --strict-peer-deps --engine-strict >&2
        node --input-type=module <<\NODE
import assert from "node:assert/strict";
import { resolve } from "node:path";
import config from "./vite.config.mjs";

const sourcePlugin = config.plugins.find(plugin => plugin.name === "tao-awx-source");
const result = await sourcePlugin.transform(
  `export default <div css="color: red" />;`,
  resolve("src/tao-css-probe.jsx"),
);
assert.match(result.code, /from ["\x27]styled-components["\x27]/);
assert.match(result.code, /color:\s*red/);
assert.doesNotMatch(result.code, /\bcss\s*:/);
console.error("Verified Vite styled-components css prop transform");
NODE
        node <<\NODE
const config = require("./eslint.config.cjs").find(entry => entry.plugins);
const missing = Object.keys(config.rules).filter(rule => {
  const separator = rule.lastIndexOf("/");
  if (separator < 0) return false;
  return !config.plugins[rule.slice(0, separator)]?.rules?.[rule.slice(separator + 1)];
});
if (missing.length) {
  console.error("Missing plugin rules:\n" + missing.join("\n"));
  process.exitCode = 1;
}
NODE
        ./node_modules/.bin/eslint --print-config src/index.js > effective.json
        node <<\NODE
const expected = require("./tao-eslint-policy.json").rules;
const actual = require("./effective.json").rules;
const levels = { off: 0, warn: 1, error: 2 };
for (const [rule, options] of Object.entries(expected)) {
  const severity = Array.isArray(options) ? options[0] : options;
  if (actual[rule]?.[0] !== (levels[severity] ?? severity)) {
    throw new Error("Missing rule or changed severity: " + rule);
  }
}
console.error("Verified rule names and severities:", Object.keys(expected).length);
NODE
        if [[ "$1" == "--preview-fixes" ]]; then
            npm run prelint >&2
            git init -q
            git add -f -- src testUtils
            lint_status=0
            ./node_modules/.bin/eslint --ext .js --ext .jsx src testUtils --fix >&2 ||
                lint_status=$?
            if (( lint_status > 1 )); then
                exit "$lint_status"
            fi
            git diff --check -- src testUtils >&2
            git diff --no-ext-diff --no-color -- src testUtils
        else
            cat effective.json
            npm run lint >&2
        fi
    ' bash "$mode" > "$reports/$report" 2> "$reports/lint.log"
