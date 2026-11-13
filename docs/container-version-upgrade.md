# 2026-11-13 — Separate one-time upgrade bundle

Runtime images contain installed application files plus small release/package
inventory metadata. They do not contain OPM archives. Preparation generates
artifacts/upgrade-bundle/ separately, holding exact OPMs and matching metadata.
Transfer this directory, the runtime image and the refreshed deployment scripts;
do not transfer the entire temporary app/build tree or source database.
Keep the bundle with its matching image for later deployment/recovery.

Use a fresh extraction and prepare/build. Source Base194 or195 is supported;
no Base195 installation is implied. Existing images must be rebuilt to remove
archives from their layers; deleting them at runtime would not reduce image size.

Target procedure (replace namespace/image with the actual built image):

```bash
kubectl -n tessera create -f examples/upgrade-bundle-pvc.yaml
python3 scripts/upload-upgrade-bundle.py --namespace tessera \
  --pvc tessera-upgrade-bundle --image REGISTRY/tessera:0.0.194-ubuntu26.04 \
  --bundle artifacts/upgrade-bundle
python3 scripts/upgrade-deploy.py --namespace tessera --web WEB_DEPLOYMENT \
  --daemon DAEMON_DEPLOYMENT --container WEB_CONTAINER \
  --image REGISTRY/tessera:0.0.194-ubuntu26.04 \
  --upgrade-bundle-pvc tessera-upgrade-bundle --state-directory release-state
```

The PVC example uses the default StorageClass and2Gi; size it for the actual
bundle. The upload helper uses the target runtime image and no application/DB
secrets; --uid/--gid can match custom runtime ownership and --image-pull-secret
can name an existing registry secret. It safely streams only bundle artifacts,
refuses an existing upload directory, verifies hashes and matches the image's
small metadata before deployment. A failed upload leaves partial evidence;
inspect it and use a fresh dedicated PVC rather than overwrite it blindly.
Cluster scheduling/admission/storage restrictions must also permit this helper Pod.

The existing deployment helper still quiesces web/daemon and holds the durable
release claim. Only its upgrade Job mounts the bundle read-only. It uses native
PackageUpgrade (native install delegation for missing packages), in dependency
order, including when Base already matches. Matching artifacts skip. Database,
configuration, file and code hooks remain native. No Force, version-only SQL
updates, automatic uninstall or downgrade. Final inventory verification precedes
configuration/READY. Startup web/daemon/ready/smoke only checks full inventory and
actual target OPM hashes; it never needs the upgrade bundle or runs migrations.

After successful upgrade and application acceptance, retain the local bundle as
a release artifact; delete the completed upgrade Job and dedicated temporary PVC
when their recovery evidence is no longer needed. Normal Deployments have no
bundle mount. On failure preserve the Job, PVC, state files and release/package
journal claims; do not delete markers or blindly use --resume-config. Native
package metadata can advance before hooks finish; inspect effects or restore a
consistent backup before reviewed recovery.

Limits: initialized target Base still required, no empty database/core framework
upgrade, numeric dotted add-on versions only, extra/ahead/same-version differing
packages require explicit reconciliation. Native compatibility/conflict/vendor
migration requirements still apply. Stored artifact equality does not certify
all original add-on files under legitimate custom overlays; source snapshot audit
and Base payload checks remain. Legacy179 recovery scripts target old embedded-
OPM images; use the new controlled bundle flow for new images. Live Linux/
MariaDB/Kubernetes acceptance remains pending.

# Container release upgrade — 0.0.182 implementation status

182 now implements the controlled target upgrade path for testing: source installed-OPM export and payload verification, immutable image package/hash metadata, target registry/artifact startup verification, durable database CAS release phases and a single native upgrade Job. The new toolkit scripts/upgrade-deploy.py validates its Job, quiesces the specified web/daemon Deployments, waits for old Pods to disappear, runs the upgrade/configuration and activates the new image only after success. It preserves target configuration/volumes and imports no source business records. Source preparation and Job staging reject symlinks; no integrity checks are skipped.

Use the updated fresh toolkit after installing182 on the original Linux host. Supported test origins are180/181; an already182 target does not rerun native package/schema installation. Missing/ambiguous/ahead/unsupported target metadata and package-hash mismatch block activation. Native package metadata may advance before hooks finish, so a durable UPGRADING or CONFIGURING phase also blocks startup. No stale upgrade is automatically replayed. The Job uses an isolated writable app workspace at the normal /opt/otobo path, preserving native package file/hook behavior without changing the immutable image filesystem.

See **docs/tessera-182-end-to-end.md** for deployment commands, failure recovery, callback, inventory and automation acceptance. Native Linux/MariaDB/Kubernetes acceptance remains to run; local tests are fixture-based. The requirements below describe the original gap and design and are retained as history, not a statement that182 lacks the new runner.

## Historical requirement/design

Owner direction, 2026-10-26: install181 on the original Linux source host and build an image from that installed release. Do not copy its database schema dump or database records into Kubernetes. The deployment should detect whether the existing Kubernetes database is behind the image release and apply only the necessary supported upgrades in place.

## Current implementation boundary

prepare.sh detects the source host's installed TESSERA-Base package version through its package registry and captures release metadata. Docker builds the installed files without contacting the target database or running package installation. Runtime startup checks shared generated-config files and their definition fingerprint. configure.py runs Maint::Config::Rebuild with ACL/process deployment. None of these implements target database package/schema version comparison plus native package upgrade. A matching configuration fingerprint is not proof of schema/package compatibility.

181 versus180 adds AWX invoker/config/example/documentation/console files and extends ScriptEngine. All DatabaseInstall/DatabaseUpgrade/DatabaseUninstall and CodeInstall/CodeUpgrade/CodeReinstall sections were unchanged. There is no new schema migration in181, but target package metadata and SysConfig registration/deployment still need to be handled correctly. Installing181 on the original host does not upgrade the Kubernetes database. The source host's generated configuration or package registry must not be treated as evidence of the target's installed state.

## Required next implementation

1. Carry the immutable intended release identity and verified authoritative package artifacts in an upgrade-capable release bundle/image. Current file-only preparation is insufficient for arbitrary skipped package migrations. Verify any intermediate upgrade requirements rather than inferring a supported path from version arithmetic.
2. Read actual target package metadata and relevant native framework/schema compatibility information using the target configuration. Compare with the intended image release. Missing/ambiguous metadata, unknown upgrade paths, downgrade attempts or hash disagreement stop activation; do not guess or compare arbitrary table shapes to generate ALTER statements.
3. A single deployment-level upgrade Job obtains a database-wide migration lock visible to every upgrader, rechecks target state after locking and uses supported native package upgrade routines and package-declared migrations against the existing target database. Individual web/daemon Pods must not concurrently migrate. No independently invented governance fields or unapproved migration table are introduced until the durable lock/receipt contract is verified.
4. Quiesce writers/daemon and establish actual old/new compatibility before any migration. Mixed-version operation is not automatically safe. Preserve target operational records and administrator-owned configuration. Release-declared idempotent defaults/metadata/migration records are distinct from copying source-host business data. Explicitly review any bootstrap hooks/defaults before execution; unchanged hooks are not necessarily side-effect-free.
5. Rebuild/deploy target SysConfig/ACL/process configuration in the controlled shared configuration step, then verify target version/compatibility and publish success only after the required native steps complete. New runtime Pods remain unready until the intended release is verified. Ordinary Pod replacement for an already compatible release is read-only/no-op for migrations.
6. Recover from partial failure using authoritative native upgrade state and idempotent migration steps. Do not claim transactional rollback for DDL/package hooks; uncertain partially applied upgrades stop runtime activation and require defined recovery. Same-version image rebuilds/reinstalls must preserve existing target data and avoid duplicate defaults. Do not automatically run destructive down-migrations on image rollback.

## Required validation

Test an already-current target,180to181, supported skipped versions, fresh installation as a separate explicit bootstrap, repeated same-version deployment, concurrent upgrade Jobs, interruption between steps, mismatched artifact hashes, unknown/ahead target versions, failed native upgrade/config deployment, old daemon still running and preservation of target business data/admin configuration. Use isolated databases before production activation. Current toolkit has not passed these upgrade tests and must not be described as implementing automatic target database upgrades.

This records the requested behavior and current gap. No target upgrade runner, database mutation, schema/data migration, image build or deployment is performed by this document.
