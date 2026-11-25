#!/usr/bin/env bash
set -euo pipefail
image=localhost/tessera-awx-application-build:24.6.1-rocky10-r1
source_dir=$(realpath "${1:?Pass the updated AWX source checkout}")
ui="$source_dir/awx/ui"
test -f "$ui/package.json"
test -f "$ui/package-lock.json"
reports=$(mktemp -d "$PWD/tao-audit.XXXXXX")
git -C "$source_dir" diff HEAD -- awx/ui/package.json awx/ui/package-lock.json \
    > "$reports/ui-lockfile.diff"
sha256sum "$ui/package.json" "$ui/package-lock.json" > "$reports/ui-inputs.sha256"
for scope in full prod; do
    options=()
    if [[ $scope == prod ]]; then
        options+=(--omit=dev)
    fi
    status=0
    podman run --rm --pull=never -v "$ui:/workspace:ro,Z" -w /workspace \
        -e npm_config_cache=/tmp/tao-npm-cache "$image" \
        npm audit --package-lock-only --json "${options[@]}" \
        > "$reports/npm-$scope.json" 2> "$reports/npm-$scope.stderr" || status=$?
    printf '%s\n' "$status" > "$reports/npm-$scope.exit"
done
podman run --rm --pull=never "$image" python -m pip list --format=json \
    > "$reports/python-packages.json"
printf 'Reports: %s\n' "$reports"
