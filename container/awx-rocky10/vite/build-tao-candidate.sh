#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the tested no-CRA AWX checkout}")
containerfile=$(realpath "${2:?Pass the AWX application Containerfile}")
kit_dir=$(cd "$(dirname "$0")" && pwd)
ui="$source_dir/awx/ui"
image=${3:-localhost/tessera-awx-application-build:24.6.1-rocky10-no-cra-r2}
logs=$(mktemp -d "$PWD/tao-candidate.XXXXXX")
printf 'Candidate logs in %s\n' "$logs"
grep -Fq 'resetMocks: true' "$ui/jest.config.cjs"
for row in JobEvent JobEventSkeleton; do
    grep -Fq React.forwardRef "$ui/src/screens/Job/JobOutput/$row.js"
done
grep -Fq '.find(CodeEditor)' "$ui/src/screens/ActivityStream/ActivityStreamDetailButton.test.js"
sha256sum "$ui/package.json" "$ui/package-lock.json" > "$logs/ui-inputs.sha256"
podman build --pull=never --jobs=1 \
    --cpu-period=100000 --cpu-quota=200000 --memory=7g --memory-swap=7g \
    -f "$containerfile" -t "$image" "$source_dir" 2>&1 | tee "$logs/build.log"
bash "$kit_dir/check-installed-ui.sh" "$image" 2>&1 | tee "$logs/installed-ui.log"
bash "$kit_dir/check-collected-ui.sh" "$image" 2>&1 | tee "$logs/collected-ui.log"
podman image inspect --format '{{.Id}}' "$image" | tee "$logs/image-id.txt"
