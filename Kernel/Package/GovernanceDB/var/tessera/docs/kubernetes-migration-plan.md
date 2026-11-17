# TESSERA Linux to Kubernetes migration plan

Implementation update: owner confirms180 is installed on Ubuntu26.04.1. The
complete `container/ubuntu2604/` kit now supplies Dockerfile, installed-source
copying, rebuilt apt/CPAN dependencies and native web/daemon startup; use that
workflow instead of restoring package files or requiring an existing179 image.
Actual image build and live runtime acceptance remain unrun in this workspace.
Internal-only PKI is agreed: RSA8192,3-year certificates, product/private CA for
tessera.local/portal.tessera.local, daemon.tessera.local, redis.tessera.local and
db.tessera.local. Public/customer CA terminates at ingress independently. See
the kit README for issuance/trust/mTLS inputs and unimplemented client TLS gaps.

Planning only, 2026-10-20. No host, DB, Secret, cluster or live deployment change
is authorized by this document. Build180 source/package is prepared; an image and
its operational acceptance remain pending. The supplied rsync script is source
staging, not a Dockerfile or entrypoint. Owner confirms MariaDB will also run
inside Kubernetes. Cluster/storage provider and database HA topology remain
choices to confirm after inventory, not assumed existing infrastructure.

## Target and invariants

Use one signed, immutable, versioned application release/image for Web and Daemon,
with the current TESSERA entrypoint and its web/daemon arguments preserved.
Run schema/package changes through a controlled migration job, not every Pod.
Keep durable business data outside Pod writable layers. MariaDB runs inside
Kubernetes with persistent database storage and separately recoverable backups.
The existing Linux database is the migration source and rollback reference;
it is not the planned steady-state external database. Rehearse database relocation
and application cutover together against restored data before production.
No zero-downtime commitment: agree a maintenance window until rehearsals establish
actual downtime and failure behavior.

Preserve all340 Build180 payloads and all339 Build179 baseline payloads, all
administrator-owned configuration/governance definitions, active ticket/CMDB/
governance instances, history, permissions, orchestration snapshots and evidence.
Do not rerun fresh seed/reset logic against the existing DB. Books remain truth,
processes orchestrate, tickets retain evidence; no governance field renaming or
routing/business logic change is part of this infrastructure migration.

## Storage findings and the attachment question

The LOCAL exported `Kernel/Config/Files/ZZZAAuto.pm:17158` selects
`Kernel::System::Ticket::Article::Backend::MIMEBase::ArticleStorageDB`; check-all
backends is0. Native Ticket.xml also defaults to DB. ArticleStorageDB writes
attachment bytes into `article_data_mime_attachment.content` and original mail
into `article_data_mime_plain.body`; it also supports historical versions.
This is source/export evidence, NOT a live Linux configuration inspection.

OTOBO additionally supports ArticleStorageFS (default path Home/var/article) and
S3; mixed historical storage can exist after prior switches. Changing the selected
backend is not proof that old files were migrated. A native
`Admin::Article::StorageSwitch` command exists, but no conversion is proposed or
run automatically. Assess separately if an explicit FS-to-DB migration is desired.

Governance/CMDB/MELT attachments use VirtualFS. Customer profile photos use it too.
VirtualFS defaults to DB but stores each object's backend in the `virtual_fs`
table. Historical FS objects can remain even when the default becomes DB.
The FS implementation stores data under Home/var/virtualfs. Ticket attachment
storage and VirtualFS must therefore be audited independently.

**Customer attachments belong outside the image in every case.** DB attachments
persist with durable MariaDB; FS attachments need migrated persistent volumes
shared by all readers/writers. Do not delete the old host files after an image
exclusion until persistence and restore validation prove them unnecessary.

| Data | Planned location | Migration/acceptance requirement |
| --- | --- | --- |
| Tickets, governance, CMDB, risk, users, process state | Durable MariaDB | Consistent backup, restore rehearsal, counts and representative workflow checks |
| Ticket attachments/raw mail using DB | MariaDB including version tables | Retrieve old/new, inline images, original email and versioned/deleted history as supported |
| Ticket attachments using FS | Persistent shared article storage | Copy actual resolved ArticleDataDir; access from Web and Daemon; preserve paths/ownership |
| VirtualFS attachments/photos using DB | MariaDB virtual_fs and content tables | Check per-record backend, validate attachments/photos with existing references |
| VirtualFS FS objects | Persistent shared var/virtualfs | Copy content plus DB metadata; validate reads after node/Pod replacement |
| S3 objects if configured | Existing durable bucket/service | Inventory namespace/endpoints/policies, backups and runtime credential access |
| Config.pm/non-secret settings | External managed config mount | Preserve effective settings; no literal credentials; controlled configuration rollout |
| MariaDB/Redis/API credentials | External Secret files | Whole-directory read-only mounts, least privilege, no image/Git values |
| Generated SysConfig/ACL/process files | Controlled generation/deployment output | Recreate from authoritative settings, coherent version for every Pod before readiness |
| Redis cache | Dedicated service | Confirm cache-only use; authenticated access; do not assume sessions/jobs are disposable |
| Sessions, jobs and outgoing-mail state | Audit actual configured backends | Preserve durable state, avoid losing queued work during cutover |
| tmp/PIDs/compiled disposable caches | Per-Pod writable ephemeral volume | Recreate with correct ownership; uploads in progress can be interrupted by restart |
| Logs/audit | Central durable logging/retention | Preserve security references and existing audit retention; no credential dumps |
| Required source, templates, static JS/CSS, defaults/overlays | Versioned application image | Verify release hashes; no customer data in image |

Do not assume Redis contains only cache, or that every spool is disposable. The
live inventory must identify all jobs/mail/in-flight state before exclusions are
used as a cutover data migration plan. Excluding a path from an IMAGE does not
authorize abandoning its existing data.

Kubernetes storage access modes depend on the storage provider. Shared FS across
Web/Daemon on different nodes requires supported multi-node access; ReadWriteOnce
is node-scoped and not a general shared-filesystem guarantee. Do not use emptyDir
or hostPath as the sole durable store for customer attachments. See
[Persistent volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

## Phase1 — read-only discovery

Run discovery on the existing host as its actual runtime user, with a secure
private report. Record no password values, Config.pm dumps or Secret manifests.

- Resolve effective ArticleStorage, ArticleDataDir, CheckAllStorageBackends and
  VirtualFS backend, including Config.pm, generated config and Custom overrides.
- Count/size var/article and var/virtualfs (and alternate configured paths), and
  check mounts/symlinks. Inventory historical attachment references, not just
  whether a default directory looks empty.
- A DBA can read `SELECT backend, COUNT(*) FROM virtual_fs GROUP BY backend;`.
  Investigate all backend types. Obtain article storage counts/content sizes
  from the native tables without exporting attachment content into a report.
- Read an old and a recent attachment through normal authorized application
  APIs, including original email/inline content, CMDB/governance/MELT and photos.
- Record Linux distribution, CPU architecture, Perl version/ABI, OS/CPAN/native
  dependencies, runtime identities, image/base if one exists, actual entrypoint,
  current web/daemon commands, proxies, ports and resource consumption.
- Inventory MariaDB version/collation/time zone/schema/package versions,
  external DB connections, Redis, search index, email receiving/sending,
  scheduled jobs, LDAP/SSO/API endpoints, DNS, TLS/CA trust and licensing.
- Map existing code volumes, generated config/cache paths, static uploaded
  content, backup scripts, queue state and integration file exchange folders.
- Record package/source differences and approved local modifications. A source
  copy must not silently discard unrecorded customizations or embed host secrets.

Exit evidence: storage/backend matrix, source/dependency inventory, active worker
inventory, backup/restore procedure, capacity and unresolved decisions list.

## Phase2 — produce the immutable image

Use the revised host staging tool and pinned180 package. Restore all package
payloads, including110 runtime-overlay files. Keep native Redis unmodified in
the staged tree and auth in Custom. Do not copy Config.pm, customer data,
generated host configuration, credentials, logs or caches into image layers.
Review retained host integrations and inherited layers for secrets privately.

Create/obtain the actual existing Dockerfile and entrypoint; no assumed replacement.
The base must match Linux/Perl/native dependencies. Verify both web and daemon
arguments, SIGTERM forwarding, graceful exit, working directory and UID/GID.
Do not bake a mutable full /opt/otobo PVC into the target design: it can hide
new image code and undermine release identity. If the existing entrypoint relies
on first-copy code volumes, design and test that evolution explicitly.

Compile all3 Redis modules, verify340 release payloads and process source/load
paths, test cache behavior and generated configuration in the actual image.
Record image digest, dependency inventory, OPM/source hashes, release signature
and trusted verification metadata. A checksum alone is not publisher approval.

## Phase3 — staging Kubernetes environment

Create manifests/Helm values after cluster, ingress, storage class and database
topology are confirmed. Database placement is confirmed in-cluster. Proposed resources:

- Namespace, least-privilege service accounts and network policy.
- Web Deployment/Service and the selected TLS/ingress mechanism.
- Daemon Deployment with one active scheduler initially; use Recreate or another
  verified non-overlap strategy. Do not autoscale or assume daemon leader election.
- Controlled bootstrap/upgrade Job; job retries must be idempotent and protected
  by an application/database lock. Kubernetes Job completion is not exactly-once
  execution of package hooks. Keep install credentials separate from runtime DB user.
- In-cluster MariaDB service and a separately managed stateful database workload,
  PVCs, backup/PITR design and tested recovery. A StatefulSet alone is not DB HA/backup.
- Redis service with explicit credentials and persistence/HA decisions based on
  audited data use; search service only if actually required/configured.
- Config/Secret mounts and durable volume claims only for verified FS needs.
- Writable ephemeral paths for disposable cache/tmp/PIDs; persistent spool paths
  wherever the inventory establishes durable queue/file-exchange requirements.
- Resource requests/limits, disruption controls, graceful shutdown and startup,
  readiness and liveness probes. Liveness tests local process health; readiness
  gates actual initialization and required dependencies. Avoid restart storms on
  a shared database outage. Do not accept a login-page200 as complete readiness.

Keep mounted Config.pm semantics. If a file subPath is retained for Config.pm,
that config requires a rollout for changes; credential files must still use a
whole-directory mount without subPath. Kubernetes Secret projection updates are
eventually consistent; updates are not simultaneous across Pods. See
[Secrets](https://kubernetes.io/docs/concepts/configuration/secret/).

Generated SysConfig/ACL/process handling is an explicit implementation gap:
identify supported regeneration/deployment commands, when DB access is available,
how writes are scoped, and how all Pod replicas use the same deployment version.
Do not simply exclude generated files and mark startup complete. An existing
database must never trigger fresh schema or seed replay on connection failure.

### In-cluster MariaDB design and acceptance

- Select an explicitly supported MariaDB version compatible with the current
  source DB and shipped OTOBO/DBD::MariaDB. Preserve charset, collation, time zone,
  SQL settings, grants, routines/events where used and attachment-size limits.
  Do not silently combine a major DB-version upgrade with the first migration.
- Choose the database controller/operator versus a managed StatefulSet explicitly.
  One primary is a possible initial topology, not an HA guarantee. If HA is
  required, design replication/quorum/failover and test writer routing/split-brain
  prevention; increasing Pod replicas alone does not create a MariaDB cluster.
- Store the datadir on durable PVC-backed storage, never emptyDir, the image or
  the Pod writable layer. Verify filesystem semantics, fsync/durability, latency,
  capacity/expansion, node attachment/recovery and storage health. Database block
  volumes and optional shared application-attachment storage have different needs;
  do not share one database datadir between independent MariaDB servers.
- Use stable cluster service discovery with a designated writer endpoint. Apply
  network access limits for Web, Daemon, migration/backup jobs and monitoring;
  do not expose MariaDB through public application ingress. Verify DB transport
  encryption and trust against the chosen image/client configuration.
- Separate least-privilege runtime, migration and backup accounts. Keep root/admin
  credentials outside Config.pm and application Pods. Select and validate the
  MariaDB image's supported file-secret/bootstrap mechanism; do not assume every
  image supports the same *_FILE variables. Initial datadir creation, restoring
  an existing database and application schema migration are distinct operations.
- Back up outside the database PVC and preferably outside the cluster failure
  domain, with encryption, access controls and agreed retention. Select consistent
  logical/physical backup and binlog/PITR procedures appropriate to RPO/RTO.
  A PVC snapshot alone is not a verified recoverable MariaDB backup. Restore into
  a fresh datadir and test old/new attachment bytes as well as business records.
- Test graceful stop, Pod replacement, node failure/reattachment, disk pressure,
  backup/restore and any chosen HA failover. Define limits/probes to avoid killing
  MariaDB during legitimate recovery, and prevent application readiness until DB
  recovery and required upgrade work complete. Validate PVC reclaim/deletion
  behavior so a release uninstall does not silently destroy the only DB copy.

Database topology, operator/image/version, storage class/capacity, backup target,
retention and RPO/RTO are still open decisions. No database workload is created
by this plan.

## Phase4 — rehearsal using a restored environment

Restore a consistent DB and any FS/S3 data to isolated staging. Disable external
mail, production webhooks and duplicate schedulers before starting the clone.
Apply required upgrade steps once, then start Web/Daemon with runtime credentials.
Never run two independent orchestration schedulers against copied production
state with external effects still enabled.

Acceptance includes agent/customer login, permissions and reserved capabilities,
ticket creation, articles/attachments/inline content, CMDB/governance/MELT,
StateBook/BlueBook orchestration and snapshot preservation, hold/resume, risk and
advisory evaluations, calendars, search and configured mail/integrations.
Verify worker execution does not duplicate child tickets or scheduled effects.

Upload/download representative old and new attachments and photos; compare
content checksums privately. Restart Web and Daemon, delete/recreate a Pod and
reschedule onto a different node, then repeat retrieval and worker checks.
If data vanishes after replacement, persistence acceptance fails. Test attachment
size/proxy limits and upload/session behavior across multiple Web Pods.

Test Secret readability under BOTH runtime identities, real Redis AUTH and native
cache roundtrips, missing/bad secrets, projection changes/recovery and credential
overlap/rollback. DB rotation requires process replacement. Validate security
errors/audit and trusted proxy/client-IP handling. Measure startup, load, resource
use, backup/restore time, failure recovery and cutover duration.
Initial rollout uses one Web/Daemon replica until shared state and concurrency
are verified. Scale Web later with session/config/storage guarantees; Daemon
scaling needs its own scheduler/worker analysis.

Kubernetes can overlap old and new Web versions during RollingUpdate. Use that
only if schema, configuration and runtime behavior support mixed versions; use
a maintenance/Recreate plan otherwise. See
[Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
and [probes](https://kubernetes.io/docs/concepts/workloads/pods/probes/).

## Phase5 — planned cutover

1. Approve storage placement, migration window, RPO/RTO, release/image digest,
   tested backups, rollback owner and go/no-go evidence.
2. Announce maintenance and reduce traffic/DNS TTL only if that is the chosen
   traffic-switch mechanism. Quiesce old web writes, daemon, cron, mail intake
   and integration writers. Account for queued/in-progress work.
3. Take final consistent DB backup/sync and any required FS content delta while
   preserving metadata/content alignment. Record counts and checkpoints.
4. Restore the final source data into in-cluster MariaDB and any required FS
   storage, verify consistency, then configure Web/Daemon to use its writer
   service. Run controlled migrations
   only if actually needed; retain administrator-owned data/configuration.
5. Start Kubernetes Web/Daemon with new mounts and real readiness gates. Keep
   the old scheduler stopped: there must be only one active orchestration owner.
6. Perform agreed smoke tests, particularly an old attachment, new attachment,
   authentication, permissions and one safe representative worker operation.
7. Switch ingress/DNS/load-balancer routing explicitly, then resume mail and
   integrations once. Monitor errors, job lag, DB/cache, storage, audit and login.
8. Recheck data after Pod restart/node movement before accepting the migration.
   Keep source-host backups and rollback environment until retention approval.

No automatic live deployment or credential mutation is performed by this plan.

## Rollback and durability

Before cutover agree the exact no-return point. Reverting an image or DNS does
not undo DB/schema changes or synchronize writes made after cutover. If the new
system accepted writes, quiesce both sides, reconcile durable state and choose a
consistent authoritative DB/storage snapshot before resuming old services.
Do not bring the old daemon online concurrently. Test image compatibility with
the migrated DB; keep a backup restoration path when schema rollback is unsafe.

Backups cover MariaDB (including blobs/history), non-DB files/object storage,
managed config, Secret recovery, release images/signatures and operational
restore instructions. PVC retention/reclaim and bucket/versioning policy are
explicit choices; cluster deletion must not silently destroy the only data copy.
Schedule restore drills and monitor storage growth. Business RPO/RTO targets,
backup frequency, retention and recovery ownership remain to be agreed.

## Decisions and remaining deliverables

MariaDB placement is confirmed in Kubernetes. Confirm cluster/provider/version,
storage driver/RWX capability, MariaDB topology/image/version/storage/backup target,
actual attachment/VirtualFS backends and legacy content, ingress/DNS/TLS, identity
and mail dependencies, registry/signature policy, availability/scale goals,
maintenance window and RPO/RTO. No infrastructure purchases are implied.

Then produce: approved Dockerfile/entrypoint and versioned image; actual Helm or
manifest set; storage/backend inventory; tested bootstrap/upgrade/config job;
backup/restore scripts; staged validation results; cutover/rollback runbook;
monitoring/operations handover. Until those exist,180 is a source release with a
container recipe, not a validated complete Kubernetes distribution.
