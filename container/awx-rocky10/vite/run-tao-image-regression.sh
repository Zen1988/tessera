#!/usr/bin/env bash
set -euo pipefail
image=${1:?Pass the built TAO application image}
start=${2:-1}
if [[ ! $start =~ ^([1-9]|1[0-9]|2[0-2])$ ]]; then
    printf 'Starting shard must be between 1 and 22\n' >&2
    exit 2
fi
logs=$(mktemp -d "$PWD/tao-image-jest.XXXXXX")
printf 'Shard logs in %s\n' "$logs"
podman image inspect --format '{{.Id}}' "$image" > "$logs/image-id.txt"
for ((shard=start; shard<=22; shard++)); do
    printf 'Running Jest shard %s/22\n' "$shard"
    podman run --rm --pull=never --network=none --timeout=180 \
        -w /build/awx/awx/ui "$image" \
        npm test -- --runInBand "--shard=$shard/22" \
        2>&1 | tee "$logs/shard-$shard.log"
done
