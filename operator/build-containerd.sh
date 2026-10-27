#!/usr/bin/env sh
set -eu
cd "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
image="${TESSERA_OPERATOR_IMAGE:-docker.io/library/tessera-operator:0.3.5}"
address="${BUILDKIT_HOST:-unix:///run/tessera-buildkit/buildkitd.sock}"
command -v buildctl >/dev/null 2>&1 || { echo 'buildctl is required; see CONTAINERD.md.' >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo 'sha256sum is required.' >&2; exit 1; }
case "$image" in
  *[!a-zA-Z0-9_./:@-]*|'') echo 'Invalid image reference.' >&2; exit 1 ;;
esac
mkdir -p dist
archive=dist/tessera-operator-image.oci.tar
if [ -e "$archive" ] || [ -e "$archive.partial" ]; then
    echo 'An archive or partial build already exists in dist. Preserve it and use a fresh kit directory.' >&2
    exit 1
fi
buildctl --addr "$address" debug workers
# The final Dockerfile stage consumes the verification stage, enforcing its tests.
buildctl --addr "$address" build \
    --no-cache \
    --frontend dockerfile.v0 \
    --local context=. --local dockerfile=. \
    --opt platform=linux/amd64 --opt target=runtime \
    --opt image-resolve-mode=pull \
    --output "type=oci,name=$image,dest=$archive.partial" \
    --metadata-file dist/build-metadata.json
test -s "$archive.partial"
mv "$archive.partial" "$archive"
sha256sum "$archive" > "$archive.sha256"
printf '%s\n' "$image" > dist/image-reference.txt
printf '%s\n' 'Built OCI image archive with embedded test gate.' \
    'Import and final-image runtime validation are separate; see CONTAINERD.md.'
