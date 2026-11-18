# Build 180 — Custom Redis file authentication

Application package prepared; no container image has been built, signed, pushed
or deployed. Existing TESSERA179 image digest/entrypoint remain unavailable and
no local container builder is installed. No live Kubernetes changes made.

## Reference and implementation

Owner-supplied recovered reference: C:/Users/Zen/OneDrive/Desktop/Redis.pm.
SHA256: fcf16a14e5608b098413ba9e66b80cbc3268270da594bb578afefee9bbe0dfa3.
The recovered patch reads the fixed file and supplies the password constructor
argument for non-Fast Redis. Its native cache operation bodies are retained in
Custom/Kernel/System/Cache/Redis.pm, package Kernel::System::Cache::Redis.
The core Kernel/System/Cache/Redis.pm is untouched. Both179 Custom TESSERA
modules remain byte-identical.

PasswordSecret explicitly enables the179 secret reader and shared authenticated
connection implementation for both Redis and Redis::Fast. Native validation
logging, key namespacing, Storable wrapping, TTL/EX, database selection, Delete,
namespace cleanup/KeepTypes and failure returns remain. Each backend operation
checks the current credential; changes replace the connection between operations.
Authenticated failures discard the client and emit generic errors instead of raw
AUTH exceptions. Ambiguous writes are never retried. Missing, malformed or empty
secret names fail closed. Without PasswordSecret, native unauthenticated behavior
is preserved. Expired-only cleanup remains the native no-op.

The recovered unbounded direct read and newline removal are replaced with the
existing179 loader contract: validated names, in-mount resolution, regular files,
bounded exact bytes, no value logging. A trailing newline IS part of the password;
provision exact bytes. PasswordSecret => 'redis-password' selects the fixed
/run/tessera-secrets/redis-password. No hardcoded credential is introduced.
The override calls the179 package-private SecretRedis::_Client implementation;
ship all three files together and run both backend regression suites on updates.

## Baseline and artifacts

Complete179 OPM SHA256:
ba2145433ce1e97ea6f3262108c7b21abc0969dce0e08d6cb5ddae8e036d4bf1.
All339 prior payloads are preserved byte-for-byte.180 adds only the Custom Redis
compatibility override, for340 payloads. Existing hooks, schema and unrelated
metadata are unchanged except version. No new DB migration or application reset.
Governance, CMDB, orchestration, risk, calendar, security advisory and portal
preservation is checked at the artifact level; live behavior remains to validate.

outputs/build-180 contains the full OPM, source ZIP, sanitized container context,
recovered-to-Custom diff, manifest and SHA256SUMS. Source ZIP includes all340
package source payloads plus release tooling/docs/tests; it is not a container
image. Reassemble using scripts/package_build180.py with --reference pointing to
the recovered Redis.pm. Manifest verifies baseline identity and changed files.
The new package needs its own signature for the CODESECURITY release workflow;
no production signing key was accessed. Native OTOBO verification is separate.

## Configuration and container deployment

Use docs/examples/kubernetes/Config-redis180.pl inside the externally mounted
Config.pm. It selects Cache::Module => Kernel::System::Cache::Redis and
Cache::Redis->{PasswordSecret} => redis-password. Preserve existing server,
database and unrelated settings. Prior179 Kernel::System::TESSERA::SecretRedis
configurations remain supported. Both launchers must put Custom before core in
@INC. Verify the loaded Redis.pm path in each actual runtime process.
On first activation restart Web and Daemon processes through the controlled
deployment procedure: an already loaded core Perl package is not hot-replaced
by installing a new Custom file. This is distinct from subsequent Secret rotation.

Apply the read-only whole-directory Secret mounts and runtime-group permissions
in docs/kubernetes-secrets.md to Web and Daemon; no subPath. No Secret value,
Config.pm, generated cache or runtime log is included in the build context.

Container template command, after obtaining the VERIFIED179 image digest:

    docker build --build-arg BASE_IMAGE='<existing179-image>@sha256:<digest>' -t '<registry>/tessera:0.0.180' outputs/build-180/container

The Dockerfile inherits ENTRYPOINT, CMD, USER, environment and working directory;
it does not replace web/daemon argument handling. It copies only three modules
to /opt/otobo/Custom and the upstream first-copy tree at
/opt/otobo_install/otobo_next/Custom, plus the full OPM to a release directory.
Verify those paths against the existing TESSERA entrypoint BEFORE building.
No Package Manager, database or install hooks run during image build. Persisted
code volumes can mask image updates; use the existing controlled update process.
A new image alone cannot be assumed to upgrade an existing code volume.

Inspect inherited179 layers for existing credentials/config/logs/caches before
asserting image-wide absence. Context exclusions do not audit the base image.
Before release compare image ENTRYPOINT/CMD/USER with179, exercise web and daemon
arguments under real runtime users, and record the image digest/archive. No image
digest or successful image startup is claimed by this source release.

## Validation and acceptance

All three Custom modules compile. Three local suites report82 assertions:
75 pass and7 Linux-only skips. The opt-in live suite was not run. New29 assertions
cover Custom module resolution, native serialization/TTL/database selection,
rotation, exact bytes, no fallback, redaction/no replay, recovery, Fast and legacy
unauthenticated compatibility. Clients are mocked; this does not prove real AUTH.

    prove -ICustom scripts/test/TESSERA/Secrets.t scripts/test/TESSERA/SecretRedis.t scripts/test/TESSERA/RedisCustomOverride.t
    TESSERA_SECRET_LIVE_TEST=1 perl -I. -ICustom -IKernel/cpan-lib scripts/test/TESSERA/SecretsLive.t

Live tests accept either configured backend and require PasswordSecret. Run Linux
projection/unreadability tests non-root, actual Redis AUTH/cache roundtrips and
both Web/Daemon startup/job checks in isolated staging as their effective runtime
users. Verify invalid credentials, mounted rotation, recovery, TTL/cleanup and
Fast with the shipped client version if used. Rotation mode remains operator-
driven as documented in the179 guide. No zero-downtime claim. MariaDB credential
rotation still requires controlled process replacement.

## Rollback

Keep prior image/signed179 and credentials in secure custody. During credential
overlap restore matching image/config/code volumes using the established update
procedure. Before removing the180 Custom override, switch back to179's
Kernel::System::TESSERA::SecretRedis backend: native core Redis does not supply
file authentication. No DB migration rollback is needed. Never restore literal
passwords into Config.pm.

## Changed files

- Custom/Kernel/System/Cache/Redis.pm and identical package source mirror.
- Kernel/Package/GovernanceDB/TESSERA-Base.sopm: version180 plus one File entry.
- Kernel/Package/TESSERA-Base-0.0.180.opm.
- scripts/test/TESSERA/RedisCustomOverride.t (new).
- scripts/test/TESSERA/SecretsLive.t (accept both supported backends).
- docs/examples/kubernetes/Config-redis180.pl (new).
- scripts/container/build180.Dockerfile and build180.dockerignore (new).
- scripts/package_build180.py (release assembler).
- This report, docs/kubernetes-secrets.md, PROJECT_STATUS.md and PROJECT_NEXT.md.
- Generated allowlisted artifacts under outputs/build-180/.

All other179 package payloads, including both TESSERA secret modules, are
unchanged. The supplied Desktop reference and core modules are untouched.
