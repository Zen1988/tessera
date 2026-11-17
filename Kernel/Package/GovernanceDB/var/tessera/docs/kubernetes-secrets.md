# Kubernetes credentials for TESSERA

Build180 adds a Custom-only compatibility override for the native Redis module.
See `docs/build-180-redis-integration.md` and the `Config-redis180.pl` example.
The179 custom modules and configurations remain supported unchanged. The native
core file is untouched; PasswordSecret explicitly enables file authentication.

Opt-in implementation; existing configuration is unchanged until explicitly edited.
No OTOBO core module is replaced. Kubernetes owns storage/delivery; TESSERA owns
loading and the optional Redis connection lifecycle. No zero-downtime claim.

## Files and configuration

Deploy `Custom/Kernel/System/TESSERA/Secrets.pm`, package
`Kernel::System::TESSERA::Secrets`. Public function:

```perl
require Kernel::System::TESSERA::Secrets;
$Self->{'DatabasePw'} = Kernel::System::TESSERA::Secrets::Read('db-password');
```

Use the complete guarded example in `docs/examples/kubernetes/Config-secrets.pl`.
It includes Redis integration through `Custom/Kernel/System/TESSERA/SecretRedis.pm`,
package `Kernel::System::TESSERA::SecretRedis`. `PasswordSecret` is a new option
owned exclusively by that backend, not a native OTOBO field. No Dynamic Fields,
governance objects, schema, routing or bootstrap defaults are introduced.

The loader accepts one ASCII name, 1–128 characters: first alphanumeric, then
alphanumeric, underscore or hyphen. No configurable root, environment override,
absolute paths, slashes, dots, traversal, fallback or optional-secret mode.
Reads are raw bytes, nonempty, at most 64 KiB, without NUL. A trailing newline
is part of the credential; provision exact bytes (do not use `echo`). Errors
identify the validated key and a generic failure, never values, OS errors or
untrusted filenames. The loader retains no values between calls.

Kubernetes key/`..data` symlinks are resolved to a generation inside the mount.
Outside targets and nonregular files are rejected. Linux opens use O_NOFOLLOW
and O_NONBLOCK. Resolution/open racing with old-generation removal fails closed;
a subsequent call can succeed. Mount and all parent directories must be trusted,
not writable by the application. This is a trusted kubelet projection boundary,
not a sandbox against root or a hostile writer replacing intermediate directories.

## Kubernetes mount and permissions

`docs/examples/kubernetes/secret-mount.patch.yaml` contains Web and Daemon
Deployment patches. Adapt deployment/container names and UID/GID to the actual
image (`id otobo`); 1000 is an example, not an asserted OTOBO identity. Include
the same mount for init/upgrade jobs and any CLI worker that loads Config.pm.
Remove unused API keys from `items`; every listed key is required.

Create the mutable Secret from secured files supplied by your secret manager:

```sh
kubectl create secret generic tessera-runtime-credentials \
  --from-file=db-password=/secure/input/db-password \
  --from-file=redis-password=/secure/input/redis-password \
  --from-file=api-token=/secure/input/api-token
```

No Secret manifest containing values belongs in the repository or image. Update
the existing Secret through the deployment's secret-management system; do not
delete/recreate it during rotation. Use Kubernetes RBAC and encryption at rest.

Mount the whole directory read-only, **without subPath**. Secret projections
update eventually, not synchronously with the API write. Immutable Secrets
cannot rotate in place. See [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
and [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/).

Use root-owned files with runtime-group read access, normally mode 0440 and
`fsGroup` set to the runtime group. The runtime must be able to traverse the
mount and generation directories. Confirm actual modes/group as the non-root
runtime user in **both** Pod types; cluster policy may affect ownership. Do not
chmod/chown read-only projections from the application. Keep module code
root-owned and runtime-readable, not runtime-writable (e.g. 0644, directories0755).
Never inspect values with cat, shell tracing, config dumps or debug logs.

## Connection lifecycle findings

Inspected local `otobo-11.1.0-beta2` sources and current repository counterparts:

* `bin/psgi-bin/otobo.psgi:64–66` and `bin/otobo.Daemon.pl:31` include Custom
  before application loading. Package paths therefore retain the `Kernel::`
  namespace. Check every deployment-specific launcher; use `-I/opt/otobo/Custom`
  for a standalone script. No ObjectManager is required by the secret loader.
* `Kernel/System/DB.pm:new` copies DatabasePw into PW. `Connect` caches
  DBIx::Connector objects in a lexical state hash keyed partly by password;
  reconnection retains constructor credentials. Config reload or discarding a
  single OM object is not a reliable refresh of all references/connectors.
  Replacing handles during a transaction risks lost state. No DB monkey-patch,
  automatic disconnect, transaction replay or unsafe live refresh was added.
  **Database rotation requires controlled Web and Daemon process replacement.**
* Native DB constructor interprets wholly brace-wrapped passwords as legacy
  ciphertext, and false string `0` may invoke fallback. The Config example
  rejects both. Avoid TestDatabasePw and explicit constructor passwords
  overriding the production configuration. Native DB Debug>2 prints PW:
  prohibit that setting, DBI tracing and config/object dumps in deployment.
  The loader cannot prevent unrelated core debug code from exposing memory.
* `Kernel/System/Cache/Redis.pm:new` snapshots server/database/client choice;
  `_Connect` creates Redis or Redis::Fast with server only. There is no native
  password setting. Its persistent client does not reread Config or files.
* The optional TESSERA Redis backend preserves serialization, TTL, namespaces
  and cleanup behavior, and reads the mounted password before every backend
  operation. On change it drops its old reference, authenticates a replacement,
  then selects the database. Exceptions are generic; missing/bad credentials
  fail closed, with no old-password fallback. Ambiguous writes are not retried.
  The password constructor option is documented by [Redis](https://metacpan.org/pod/Redis)
  and [Redis::Fast](https://metacpan.org/release/SHOGO/Redis-Fast-0.39/view/lib/Redis/Fast.pm).
  It retains the active password for comparison/client authentication, unlike
  the stateless loader. This is necessary connection state. RedisFast uses
  the same constructor contract but needs live validation with the shipped version.
* Disable `Cache::InMemory` for persistent workers if each cache operation must
  reach the rotating backend. No refresh occurs while idle. Native outer cache
  semantics can still satisfy data from other layers; authenticate at readiness
  independently. An AUTH change between file read and operation can fail that
  operation. Scheduled rotation needs an overlapping valid-credential window.
* Other Redis consumers and API integrations do not automatically adopt this
  backend. Each must explicitly use Read at a safe client/request boundary.
  Config.pm assignments load values into memory; they are not live callbacks.

These findings concern the bundled beta2 source, not certification of every
released OTOBO 11.1 patch/image. Validate the exact deployment artifact.

## Deployment, rotation and rollback

1. Ship both modules in the image/code volume **before** enabling Config.pm.
   Package installation alone cannot bootstrap a database credential needed to
   run Package Manager. TESSERA-Base179 includes the modules, but first-start
   images must copy them ahead of startup. Existing persisted code volumes may
   mask image files: verify module presence/permissions in both Pod types.
2. Provision the Secret with credentials already accepted by MariaDB/Redis;
   apply the mounts. Validate non-root reads without emitting data. Run the
   tests below against an isolated deployment before enabling production.
3. Back up the current deployment/config securely. Apply guarded Config example
   without literal credentials; roll Web/Daemon processes to activate it.
   Validate database SELECT1, Redis round trip, portal, daemon jobs and readiness.
   Keep non-secret configuration and administrator SysConfig settings intact;
   check effective Cache::Module against generated-config overrides.
4. For Redis rotation: make old and new credentials valid at the server using
   your supported Redis ACL/credential procedure, update the mutable Secret,
   wait for every Pod projection to converge, exercise backend operations and
   verify authentication, then revoke old credentials. No restart is needed
   by this backend design, but real rotation remains a staging acceptance gate.
5. For MariaDB: arrange a server-supported overlap/alternate-account strategy,
   update projected credentials (and non-secret username if needed), verify
   convergence before new processes start, then perform a controlled rollout
   of Web and Daemon with workload draining. Test new connections and jobs
   before revoking the old credential. Do not assume password changes terminate
   existing sessions. If overlap is unavailable, schedule an interruption.
6. Rollback during overlap: restore the prior Secret from secure custody and
   wait for projection. Redis reconnects on its next operation; database users
   require a process rollout. Restore matching server acceptance before rollback.
   Roll back image/config together if removing the modules; never remove modules
   still required by Config.pm. Do not restore literal passwords into Config.pm.

Installation/upgrade/reinstall only replace two inert files; no hooks activate
this mechanism, change credentials or modify existing data. No live deployment
was performed. This change embeds no operational credentials in module/config
examples or package additions. Synthetic test strings are fixtures. The existing
image, live Config.pm, history/layers and external deployment secrets were not
available for audit; an image-wide no-plaintext assertion is not established.

## Verification and acceptance

```sh
prove -ICustom scripts/test/TESSERA/Secrets.t scripts/test/TESSERA/SecretRedis.t
# Run on Linux as a non-root runtime user for projection/unreadability checks.
TESSERA_SECRET_LIVE_TEST=1 perl -I. -ICustom -IKernel/cpan-lib scripts/test/TESSERA/SecretsLive.t
# Isolated staging only; rotate Redis/server and mounted key at READY:
TESSERA_SECRET_LIVE_TEST=1 TESSERA_SECRET_ROTATION_TEST=1 \
  perl -I. -ICustom -IKernel/cpan-lib scripts/test/TESSERA/SecretsLive.t
```

Live test performs SELECT1 and writes/deletes a unique short-lived test cache key;
it prints no credentials. Test has no server-admin rotation privileges; the
operator must coordinate rotation externally. Run the noninteractive test again
after a database rollout to prove fresh-process authentication. Also verify
missing key blocks startup, unreadable file fails, invalid credentials never
fallback, ordinary portal/daemon behavior, failed rollout/rollback, real Secret
propagation in both deployments, RedisFast if used, and logs contain no secrets.
Do not revoke old credentials until all acceptance checks pass. Local tests use
mocked Redis clients; they do not prove network behavior or zero downtime.
