#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX source checkout}")
cd "$source_dir"
git rev-parse HEAD
git status --short

for file in awx/ui/public/index.html awx/ui/package.json awx/ui/jsconfig.json \
    awx/ui/src/setupProxy.js awx/ui/src/setupCSP.js awx/ui/src/setupTests.js; do
    if [[ -f "$file" ]]; then
        printf '\n--- %s ---\n' "$file"
        cat "$file"
    fi
done

printf '\n--- Build integration and CRA-specific usage ---\n'
git grep -nE 'ReactComponent as|process\.env\.|@babel/polyfill|serviceWorker|ui/build|index\.html|PUBLIC_URL' \
    -- awx/ui/src awx/ui/public awx/settings awx/ui/views.py Makefile MANIFEST.in || true
