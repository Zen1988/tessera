#!/usr/bin/env sh
set -eu
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
image="${TESSERA_OPERATOR_IMAGE:-tessera-operator:0.3.3}"
command -v docker >/dev/null 2>&1 || { echo 'Docker with Linux containers is required.' >&2; exit 1; }
docker info >/dev/null
if docker image inspect "$image" >/dev/null 2>&1; then
    echo 'Image tag already exists locally. Set TESSERA_OPERATOR_IMAGE to a new immutable revision.' >&2
    exit 1
fi
mkdir -p dist
docker build --pull --no-cache --iidfile dist/image.id -t "$image" .
# Verify nonroot image execution and configuration validation without credentials/network.
docker run --rm --read-only --network none --cap-drop ALL \
    --security-opt no-new-privileges \
    --tmpfs /tmp:rw,noexec,nosuid,size=16m \
    --mount "type=bind,src=$(pwd)/config.example.json,dst=/etc/tessera-operator/config.json,readonly" \
    "$image" --validate
docker image inspect "$image" > dist/image-inspect.json
docker save -o dist/tessera-operator-image.tar "$image"
sha256sum dist/tessera-operator-image.tar > dist/tessera-operator-image.tar.sha256
printf '%s\n' "Built and smoke-tested $image; archive in dist/tessera-operator-image.tar"
