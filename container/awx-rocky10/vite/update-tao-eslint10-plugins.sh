#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the TAO ESLint 10 checkout}")
baseline_lock=$(realpath "${2:?Pass the working test-stack UI package-lock.json}")
styled_plugin=$(python3 - "$baseline_lock" <<'PY'
import json
import re
import sys
from pathlib import Path

packages = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))["packages"]
assert packages["node_modules/styled-components"]["version"] == "5.3.6"
versions = {
    package["version"]
    for path, package in packages.items()
    if path == "node_modules/babel-plugin-styled-components"
    or path.endswith("/node_modules/babel-plugin-styled-components")
}
if len(versions) > 1:
    raise SystemExit(f"Review multiple styling plugin versions: {sorted(versions)}")
# The original TAO dependency tree used 1.12.0 with styled-components 5.3.6.
version = next(iter(versions), "1.12.0")
assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version)
print(version)
PY
)
printf 'Using babel-plugin-styled-components %s\n' "$styled_plugin"
kit_dir=$(cd "$(dirname "$0")" && pwd)
ui="$source_dir/awx/ui"
test -f "$ui/tao-eslint-policy.json"
backup=$(mktemp -d "$PWD/tao-eslint10-backup.XXXXXX")
cp "$ui/package.json" "$ui/package-lock.json" "$ui/eslint.config.cjs" "$backup/"
printf 'Saved previous files in %s\n' "$backup"
restore_on_failure() {
    status=$?
    if ((status != 0)); then
        for name in package.json package-lock.json eslint.config.cjs; do
            replacement=$(mktemp "$ui/.tao-restore.XXXXXX")
            cp "$backup/$name" "$replacement"
            mv -f "$replacement" "$ui/$name"
        done
    fi
}
trap restore_on_failure EXIT
cp "$kit_dir/eslint.config.cjs" "$ui/"
mv "$ui/package-lock.json" "$backup/previous-lock.json"
podman run --rm --pull=never --userns=keep-id \
    -e npm_config_cache=/tmp/tao-npm-cache \
    -e "TAO_STYLED_PLUGIN=$styled_plugin" \
    -v "$ui:/workspace:Z" -w /workspace \
    localhost/tessera-awx-application-build:24.6.1-rocky10-lingui4-r2 sh -ec '
        npm pkg delete "devDependencies.@babel/eslint-parser" "devDependencies.@babel/eslint-plugin"
        npm install --save-dev --save-exact --package-lock-only --ignore-scripts \
          --no-audit --strict-peer-deps --engine-strict \
          eslint@10 @eslint/compat@2 eslint-plugin-react-hooks@7.1.1 \
          "babel-plugin-styled-components@$TAO_STYLED_PLUGIN" \
          eslint-plugin-react@npm:@eslintplugin/eslint-plugin-react@latest \
          eslint-plugin-jsx-a11y@npm:eslint-plugin-jsx-a11y-x@latest \
          eslint-plugin-import@npm:eslint-plugin-import-x@latest
        npm install --package-lock-only --ignore-scripts --no-audit \
          --strict-peer-deps --engine-strict
        npm ci --dry-run --ignore-scripts --no-audit --strict-peer-deps --engine-strict
        npm ls --package-lock-only --all eslint
    '
