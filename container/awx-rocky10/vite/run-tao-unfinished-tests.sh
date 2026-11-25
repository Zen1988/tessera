#!/usr/bin/env bash
set -euo pipefail
source_dir=$(realpath "${1:?Pass the AWX source checkout}")
ui="$source_dir/awx/ui"
inside=/build/awx/awx/ui
image=localhost/tessera-awx-application-build:24.6.1-rocky10-no-cra-r1
row=src/screens/Job/JobOutput
mapfile -t suites < "${2:?Pass the unfinished suite list}"
logs=$(mktemp -d "$PWD/tao-jest-batches.XXXXXX")
printf 'Batch logs in %s\n' "$logs"
for ((offset=0; offset<${#suites[@]}; offset+=25)); do
    batch=()
    for suite in "${suites[@]:offset:25}"; do
        suite=${suite%$'\r'}
        if [[ $suite == "$row/JobOutput.test.js" ]]; then continue; fi
        if [[ $suite != src/*.test.js || $suite == *..* ]]; then
            printf 'Unexpected test path: %s\n' "$suite" >&2
            exit 1
        fi
        batch+=("$suite")
    done
    if ((${#batch[@]} == 0)); then continue; fi
    test_mounts=()
    for suite in "${batch[@]}"; do
        test_mounts+=(-v "$ui/$suite:$inside/$suite:ro,Z")
    done
    printf '%s\n' "${batch[@]}" > "$logs/$offset.suites"
    podman run --rm --pull=never --timeout=180 -w "$inside" \
        -v "$ui/jest.config.cjs:$inside/jest.config.cjs:ro,Z" \
        -v "$ui/$row/JobEvent.js:$inside/$row/JobEvent.js:ro,Z" \
        -v "$ui/$row/JobEventSkeleton.js:$inside/$row/JobEventSkeleton.js:ro,Z" \
        "${test_mounts[@]}" \
        "$image" npm test -- --runInBand --runTestsByPath "${batch[@]}" \
        2>&1 | tee "$logs/$offset.log"
done
