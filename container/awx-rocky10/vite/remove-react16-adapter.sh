#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX Vite checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/vite.config.mjs"
test -f "$ui/package-lock.json"
status=0
git -C "$source_dir" grep -nF enzyme-adapter-react-16 -- awx/ui \
    ':(exclude)awx/ui/package.json' ':(exclude)awx/ui/package-lock.json' || status=$?
if [[ $status != 1 ]]; then
    printf '%s\n' 'Adapter reference found or source search failed. Review before removal.' >&2
    exit 1
fi
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-r2 \
    npm uninstall --package-lock-only --ignore-scripts --no-audit --force enzyme-adapter-react-16
git -C "$source_dir" diff --stat HEAD -- awx/ui/package.json awx/ui/package-lock.json
