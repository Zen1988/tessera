#!/usr/bin/env sh
set -eu
kit=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d)
# Only generated temporary fixtures are used; no real daemon or image store.
mkdir "$fixture/bin" "$fixture/success" "$fixture/failure"
cp "$kit/build-containerd.sh" "$fixture/success/"
cp "$kit/build-containerd.sh" "$fixture/failure/"
cat > "$fixture/bin/buildctl" <<'FAKE'
#!/usr/bin/env sh
set -eu
if [ "${FAIL_BUILD:-0}" = 1 ] && [ "$3" = build ]; then exit 7; fi
for argument in "$@"; do
    case "$argument" in
        type=oci,*) destination=${argument##*dest=}; printf '%s\n' 'FAKE TEST ARCHIVE' > "$destination" ;;
    esac
done
FAKE
chmod 0755 "$fixture/bin/buildctl"
export PATH="$fixture/bin:$PATH"
sh "$fixture/success/build-containerd.sh" > "$fixture/success.log"
test -s "$fixture/success/dist/tessera-operator-image.oci.tar"
test ! -e "$fixture/success/dist/tessera-operator-image.oci.tar.partial"
(cd "$fixture/success" && sha256sum -c dist/tessera-operator-image.oci.tar.sha256)
if sh "$fixture/success/build-containerd.sh" > "$fixture/duplicate.log" 2>&1; then
    echo 'ERROR: existing archive was overwritten' >&2
    exit 1
fi
if FAIL_BUILD=1 sh "$fixture/failure/build-containerd.sh" > "$fixture/failure.log" 2>&1; then
    echo 'ERROR: failed build was accepted' >&2
    exit 1
fi
test ! -e "$fixture/failure/dist/tessera-operator-image.oci.tar"
printf '%s\n' '3 build-wrapper scenarios passed (fake builder only).'
