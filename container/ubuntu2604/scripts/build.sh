#!/usr/bin/env bash
set -euo pipefail
KIT=$(cd -- "$(dirname -- "$0")/.." && pwd -P)
cd "$KIT"
[[ -d app && -s dependencies/cpanfile && -s dependencies/host-summary.json ]] || { echo 'Preparation is incomplete. Run prepare.sh successfully before build.sh.' >&2; exit 1; }
command -v docker >/dev/null || { echo 'Docker Engine/buildx required' >&2; exit 1; }
python3 image/audit-app.py app --inventory dependencies/source-sha256.json
TAG=${TESSERA_IMAGE:-tessera:0.0.180-ubuntu26.04}
docker build --pull \
    --build-arg "BASE_IMAGE=${BASE_IMAGE:-ubuntu:26.04}" \
    --build-arg "OTOBO_UID=${OTOBO_UID:-10001}" \
    --build-arg "OTOBO_GID=${OTOBO_GID:-10001}" \
    --tag "$TAG" .
docker run --rm "$TAG" modules
mkdir -p artifacts
docker image inspect "$TAG" > artifacts/image-inspect.json
docker image inspect --format '{{.Id}}' "$TAG" > artifacts/image-id.txt
printf '\nBuilt %s. Real DB/Redis, web/daemon, TLS and persistence acceptance still required.\n' "$TAG"
printf 'Optional transfer: docker save %q | gzip > artifacts/tessera-180-image.tar.gz\n' "$TAG"
