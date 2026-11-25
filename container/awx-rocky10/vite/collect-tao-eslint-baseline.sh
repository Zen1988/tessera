#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX test-stack checkout}")
ui="$source_dir/awx/ui"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2
reports=$(mktemp -d "$PWD/tao-eslint.XXXXXX")
inside=/build/awx/awx/ui

# Use the known ESLint 8 installation to expand inherited rules from the checkout.
podman run --rm --pull=never --network=none --timeout=60 -w "$inside" \
    -v "$ui/.eslintrc.json:$inside/.eslintrc.json:ro,Z" \
    -v "$ui/.eslintignore:$inside/.eslintignore:ro,Z" "$image" \
    ./node_modules/.bin/eslint --print-config src/index.js \
    > "$reports/eslint-effective.json"
node_check='const c = require(process.argv[1]); if (!c.rules || !c.parser) process.exit(1)'
podman run --rm --pull=never --network=none \
    -v "$reports:/reports:ro,Z" "$image" \
    node -e "$node_check" /reports/eslint-effective.json
printf 'Lint baseline: %s/eslint-effective.json\n' "$reports"
