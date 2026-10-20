# Build 180 image revision r1 — configuration permissions

Application/OPM version remains 0.0.180; corrected image tag is
`tessera:0.0.180-r1-ubuntu26.04`. No application/database schema migration,
Redis HA change or PVC replacement is introduced.

Root cause: the original Dockerfile copied config-files.dist before normalizing
source permissions under /opt/otobo, leaving the separate distribution copy with
host-only modes. cp -a also tried to preserve mounted-directory metadata, which
is unnecessary and may fail on Longhorn RWX/NFS. DEBIAN_FRONTEND or a new user
alone does not grant that user access to previously copied files.

The build now makes distribution directories root:www-data0550 and files0440.
These contain only packaged configuration definitions: Config.pm, generated
ZZZ files and credential-bearing User overrides are excluded before build.
The runtime user can read but cannot modify this immutable image source.
After USER otobo, Docker build reads every definition and runs8 configure
fixture regressions as the configured UID (default10001). The fixture rebuild
does not use a database and does not claim real OTOBO deployment acceptance.

configure.py copies file CONTENTS without chmod/chown/utime/copystat, preserving
existing destination permissions/ownership. New directories request0750 and new
files0640 under the runtime UID/group, subject to umask. Existing custom/User
files are retained; no deletion/synchronization of unrelated files. Symlinks in
source or destination copy paths are rejected. Restrict all shared-volume writers
to trusted application/configuration identities; only one configure Job may run.
No root-run init container, chmod777 or recursive volume permission change.

The old fingerprint is removed before content changes. Rebuild failure leaves
no successful marker; only after the native rebuild exits successfully and all
required generated files exist/readable is the packaged fingerprint published
with atomic rename. Startup still compares it with the image fingerprint.
The volume needs runtime-user read/write/traverse plus create/unlink/rename access
in the config directory. If pre-existing files belong to another UID and are
not writable, resolve that specific ownership/access problem with the storage
administrator; the helper will not silently change their permissions.

## Rebuild on the Linux image-build host

Extract the r1 kit to a NEW directory outside /opt/otobo, or update the files
listed below in your existing kit. If using a fresh directory, run prepare once.
If app/ and dependency inventories already exist in the existing kit, no repeated
prepare is required. Preserve the previous image tag/digest for rollback.

```sh
bash scripts/build.sh
# default: tessera:0.0.180-r1-ubuntu26.04
docker run --rm --entrypoint python3 tessera:0.0.180-r1-ubuntu26.04 \
  /usr/local/lib/tessera/configure.py check-source
```

Do not retag the old image as r1 or apply the current source-only ZIP to a live
application directory. Existing /opt/otobo source is not changed by the build.
Image source ownership is set by Dockerfile, shared-volume access by its storage
configuration (otobo:www-data, UID10001/GID33 by default). Application source
is owned otobo:www-data with read-only0550/0440 modes and executable bin files0550.
Only required writable runtime/cache/config directories use0750. No whole-volume
permission change is performed. Apache Group is www-data. The example Pod patch
uses runAsUser10001, runAsGroup33 and fsGroup33; align configure/debug Pods too.
Earlier manifests using group10001 must be reviewed before running r1: do not
rely on implicit supplementary groups to read root:www-data0440 definitions.

## Verify on the actual Longhorn RWX mount before real configure

Use an existing or isolated debug Pod with the NEW image and the intended RWX
volume at /opt/otobo/Kernel/Config/Files. Confirm it runs as UID10001, not root.
Do not repoint the existing web/daemon deployments automatically.

```sh
kubectl exec -n tessera tessera-daemon-debug -- id
kubectl exec -n tessera tessera-daemon-debug -- \
  python3 /usr/local/lib/tessera/configure.py check-source
kubectl exec -n tessera tessera-daemon-debug -- env \
  TESSERA_REQUIRE_TEST_UID=10001 \
  TESSERA_CONFIGURE_HELPER=/usr/local/lib/tessera/configure.py \
  TMPDIR=/opt/otobo/Kernel/Config/Files \
  python3 /opt/tessera/tests/test-configure.py
```

The tests create/remove only unique tessera-configure-test-* scratch directories
on that PVC. They use a disposable rebuild fixture, not real SysConfig/DB writes.
If you changed the build UID, change the required test UID accordingly.
All8 tests must pass in the nonroot Linux Pod; do not accept permission skips.
Then run the controlled configure Job with external Config/credentials and the
SAME RWX mount. That real step runs Maint::Config::Rebuild and deploys SysConfig,
ACLs and processes in the configured database. Back up DB/generated config and
verify intended DB before it; this is not automatic startup on every replica.
Check the Job succeeds and the fingerprint matches before starting daemon.
Never manually fabricate a success fingerprint.

## HTTPS placement and permissions

Certificate generation remains OUTSIDE the build context. A Kubernetes Secret
mount at /run/tessera-tls contains portal tls.crt, tls.key and public ca.crt.
Use group-readable0440 with fsGroup matching the runtime group; the app needs
read access, not write access. Mount the whole directory read-only, no subPath.
The encrypted CA PRIVATE key stays offline and is never mounted into web/daemon.
Image contents include Apache/TLS configuration, not private certificates/keys.
Certificate renewal still requires controlled Apache reload or rollout.

## Changed implementation files and rollback

- Dockerfile: immutable distribution permissions, runtime-user build checks,
  image revision label and regression-test copy.
- image/configure.py (new): content-only seed/rebuild/fingerprint lifecycle.
- image/entrypoint.sh: invokes configure.py, startup fingerprint validation retained.
- .dockerignore: explicitly allows the new helper and regression script.
- scripts/build.sh: new r1 default tag/build revision.
- scripts/test-configure.py (new):8 portable/Unix regression cases, opt-in UID check.
- README.md and this document: revised instructions and acceptance limits.
- Repository test discovery wrapper, source-kit packager and project continuity.

No Redis modules, Apache routes, TLS keys, OPM/SOPM payloads, database schema or
Kubernetes workloads are changed. Rolling back an image alone does not undo a
real configuration deployment: retain a consistent DB/config-volume backup and
restore matching image/config state in a controlled rollback. Do not delete or
recreate Redis/Longhorn PVCs to resolve this image packaging defect.
