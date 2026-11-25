#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the updated AWX source checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/package-lock.json"
image=localhost/tessera-awx-application-build:24.6.1-rocky10-r1
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -v "$ui:/workspace:Z" -w /workspace "$image" sh -ec '
        npm view tmp@0.2.7 version
        npm pkg set "overrides.external-editor.tmp=0.2.7"
        npm install --package-lock-only --ignore-scripts --no-audit --force
        npm ls --package-lock-only --all tmp
    '
bash "$(dirname "$0")/collect-tao-audit.sh" "$source_dir"
