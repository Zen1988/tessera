# TESSERA Operator — proposed architecture, 2026-10-22

Status: observe-only implementation 0.1.0 now exists in `operator/`, including container recipe, internal `apps` Deployment/RBAC/NetworkPolicy, protocol adapters and tests. No image has been built or deployed in this workspace. Recovery, distributed evidence and scaling remain proposed.
Authoritative application package remains TESSERA-Base 0.0.180. This operator is a separate deliverable with an independent release lifecycle.

## Confirmed direction

- Standalone infrastructure controller, independent of Perl, TESSERA web/daemon, application database, Redis, AWX, PostgreSQL, Elasticsearch, SaltStack and Forgejo availability.
- No operator database and no operator PVC. Keep the image small.
- Independently assess each managed workload and its individual Pods, including when dependent services fail.
- Support service health, planned shutdown/startup, utilization reporting and policy-controlled scaling.
- Infrastructure operations must not invoke StateBook/BlueBook choreography or alter ticket governance snapshots.

## Recommended implementation

Original recommendation was Go with Kubernetes controller libraries and a compiled binary. First implementation uses the available Python runtime, standard-library Kubernetes HTTP client and pinned protocol drivers. User confirms independent application INSIDE Kubernetes, in `apps`, with no external exposure; the earlier outside-cluster interpretation is superseded. The Python slim runtime includes its normal base-image tools; a shell-free Go image remains a later optimization. No kubectl, Ansible, Salt or database servers are added. Measure actual image size and idle/peak resources before setting production limits.

The custom-resource status and leadership design below applies to future mutating controllers. Release 0.1.0 instead uses a mounted ConfigMap, ephemeral status/logs and Kubernetes read-only credentials, with no CRDs or leadership writes. See `operator/README.md` for implemented scope and limitations.

One controller with isolated, bounded adapter workers is the initial design. Independent checks do not require one new operator Pod per target Pod. A slow adapter must not block other adapters: separate deadlines, concurrency budgets, backoff and panic containment. Optional separate adapter Deployments can follow if isolation measurements justify them.

Kubernetes stores desired configuration and bounded reconciliation progress in custom resource spec/status; Kubernetes Leases coordinate active leadership. This avoids an additional database/PVC but still depends on the API server and its etcd. Status records operation ID, phase, observed generation, original replica counts, completed steps and conditions. No secret values or unbounded history in status. Logs, metrics and Events provide diagnostics; Events are not durable audit storage.

Every operation must survive controller restart by observing actual state before retrying. Record intent before mutation, use optimistic concurrency and deterministic operation IDs. External non-idempotent actions require deduplication or explicit uncertain-outcome handling. Missing API access stops mutations; recovery re-observes state. Do not rely on process memory for shutdown progress.

## Service adapters

These are proposed checks to validate against installed versions, charts and effective configuration, not assertions that current endpoints exist.

| Target | Independent observations | Action boundary |
| --- | --- | --- |
| TESSERA web | HTTPS response, representative generated asset delivery, ready endpoints, config availability; distinguish application/dependency failure | Drain admission and existing requests; scale only after shared configuration/assets/session behavior is verified |
| TESSERA daemon | Process heartbeat and work progress, active tasks and queue age | Drain jobs; preserve current single-active-daemon assumption until concurrent execution is verified |
| MariaDB/Galera | Per-member SQL reachability, cluster membership, primary component, synchronized state, replication and storage errors | Delegate native lifecycle to installed owner/operator; never automatically bootstrap a new primary component from ambiguous partition state |
| Redis/Sentinel | Per-instance role, persistence/replication state, Sentinel agreement, actual writable primary endpoint | Sentinel owns election; controller must not independently promote replicas; stop clients before full-cluster shutdown |
| AWX | Supported application readiness and task state, database/broker dependencies | Stop new work and drain running jobs through supported controls; preserve existing AWX operator ownership |
| PostgreSQL | Reachability, primary/replica state, lag, storage and backup conditions | Delegate promotion, membership and shutdown to the installed topology manager |
| Elasticsearch | Member reachability, cluster health, shard allocation/recovery, disk pressure | Quorum-aware maintenance through existing operator; CPU alone cannot justify member removal |
| SaltStack | Master reachability and job/event progress, relevant minion connectivity | Prevent new jobs and drain work through supported controls |
| Forgejo | Supported application readiness, database/storage reachability and active work | Coordinate web/workers and database; preserve repositories and active operations |

Each adapter reports healthy, degraded, unavailable, unknown or intentionally stopped with reason and freshness. Dependency outage must not be reported as a healthy service, nor trigger cascading restarts of every client. Read-only checks are distinct from privileged lifecycle credentials. Use native APIs/protocols with TLS verification, Secret references and narrow RBAC; avoid arbitrary executable commands in custom resources.

## Correlated infrastructure and membership checks

Confirmed follow-up: detect members that started outside their intended service cluster and attempt controlled recovery, using node status and the operator's own network status as evidence before acting. Kubernetes cluster membership and database/replication membership are separate observations.

Collect timestamped evidence at these layers:

- Observer: operator API connectivity, DNS resolution, connections to configured independent reference endpoints, local connection errors and credential/TLS failures. Failure from this observer alone cannot establish target failure.
- Node: Ready/Unknown conditions, heartbeat/Lease freshness, pressure conditions, shutdown/maintenance signals and target placement. API-reported status may be stale; a missing heartbeat does not prove a node or its database process is stopped.
- Network: compare DNS versus direct endpoint reachability, Service versus individual Pod paths, application versus replication ports, and observations from different nodes/failure domains. Use authenticated probes with explicit deadlines. An optional unprivileged probe DaemonSet supplies node-local perspectives without a database or PVC; it is a proposed component, not an assumed deployment. Avoid requiring host networking or privileged packet access by default.
- Workload/storage: process health, restarts, deletion state, mount/attachment errors and service-reported I/O failures. Bound PVC does not prove storage is writable.
- Service membership: expected cluster identity, membership, primary/quorum authority, replication health and synchronization using the correct adapter. Redis/Sentinel replication and Redis Cluster membership require distinct adapters; PostgreSQL topology depends on its actual manager.

Recovery sequence: suspect -> corroborate -> isolate client traffic -> establish authority and fence conflicting writers where required -> graceful stop -> supported restart/rejoin -> verify synchronization -> restore traffic. Merely removing a Service endpoint is not fencing: existing connections and direct clients may remain. Never promote another writer on the assumption that an unreachable instance has stopped. Use supported native topology-manager controls and verify their results; if fencing cannot be established where required, block recovery.

Automatic stop/rejoin is permitted only for explicitly managed members with confirmed wrong/nonmembership and corroborated authoritative surviving topology, under configured recovery policy. Preserve persistent data. Failure to establish quorum, conflicting identities, divergent history or uncertain fencing produces a visible blocked condition. Rebootstrap, destructive reseeding and choosing an authoritative copy require separate explicit recovery policy; do not infer permission from a restart policy.

Apply consecutive-failure thresholds, evidence freshness limits, bounded retries, one affected member at a time per topology, recovery cooldown and post-action checks. Re-observe authority immediately before mutation. During observer/network/control-plane uncertainty, stop destructive recovery and automatic failover requests. A healthy operator self-check never proves the whole network is healthy; independent perspectives reduce uncertainty without eliminating it.

Acceptance must include operator-only network isolation, one-node isolation, asymmetric partitions, DNS-only failure, stale node status, wrong-cluster startup, unavailable storage, surviving process on an unreachable node and competing recovery attempts. Expected behavior is no restart storm, no duplicate writer, preserved volumes and bounded recovery or an explicit blocked reason.

## Planned shutdown and startup

An explicit maintenance request must precede node power-off. A dependency graph determines order; do not embed one universal list of service names. Validate no cycles and include external integrations and current workload owners.

1. Record the operation, target identities, original desired replicas and maintenance ownership. Coordinate GitOps, HPA and native operators so they do not recreate intentionally stopped workloads. Refuse competing lifecycle ownership.
2. Stop admitting new requests/jobs, then drain web requests, daemon jobs and other producers using adapter-specific deadlines.
3. Stop consumers/applications in reverse dependency order. Quiesce writers before stopping backing services.
4. Shut down stateful clusters through topology-specific procedures, preserving quorum while required and recording the evidence needed for safe full-cluster restart. Backup/checkpoint requirements are service policy, not a generic SAVE command.
5. Report ready for infrastructure shutdown only when required steps have succeeded. Timeouts produce a blocked maintenance condition, not automatic force deletion or fabricated success.
6. An external administrator/cluster lifecycle system powers down infrastructure. Storage, networking and the control plane remain available until workload shutdown finishes.
7. Startup restores infrastructure and dependencies first, then consumers/producers after real health checks; restore recorded desired capacity without fighting autoscalers.

An in-cluster operator cannot guarantee recovery during total power loss or API/control-plane failure. Deployment on a management cluster is an option for independent orchestration, but still requires reachable target APIs and cannot compensate for unavailable disks. Local SIGTERM handling, bounded preStop hooks and kubelet graceful-node-shutdown configuration remain necessary fallback controls. Do not add a finalizer that requires unavailable application dependencies merely to permit deletion.

## Redis incident and persistence policy

The reported save failure is plausible but not diagnosed from logs here. Collect Redis version/image/chart, previous/current logs, Pod deletion timestamp, node/kubelet events, lifecycle hooks, finalizers, grace period, effective RDB/AOF configuration and volume state. Redis refusing shutdown and Kubernetes retaining a terminating Pod can involve different causes; inspect both.

Classify every Redis deployment by actual consumers/data: rebuildable cache versus sessions, queues, locks or other state. Only an explicitly verified disposable-cache deployment may use a policy that disables persistence or skips the final RDB save. SHUTDOWN NOSAVE is not a universal storage bypass: AOF flushing and replication behavior must be checked against the installed version/configuration. Never automatically use FORCE, remove finalizers, delete PVCs or force-delete database Pods to clear a dashboard condition. Sentinel HA does not replace persistence or guarantee retained acknowledged writes.

Current project memory says the application cache client uses a direct endpoint rather than Sentinel discovery. Validate a primary-only routing mechanism and reconnection behavior before claiming Redis failover support; a Service alone does not identify the current primary.

## Utilization and scaling

Read CPU/memory through the resource metrics API when available; expose unknown/stale conditions when absent. Application queue depth, request latency, connection pressure and service-native metrics may inform policy through an optional metrics provider; the operator must start without that provider.

Prefer Kubernetes HPA as the single replica writer for eligible stateless workloads. The operator can configure bounded policies and report recommendations. If a custom scaler is later necessary, explicitly transfer ownership; never run two competing replica controllers. Use minimum/maximum replicas, cooldown, stabilization, resource requests and capacity checks. Freeze or coordinate scaling during maintenance.

Initial automatic scaling candidate: verified horizontally safe TESSERA web. Daemon remains one active instance. Database members, Redis/Sentinel and Elasticsearch require topology-specific membership logic; utilization alone does not authorize scaling. PVC expansion is a separate storage operation.

## Delivery sequence and acceptance

1. Inventory real manifests, service versions, chart/operator ownership, health endpoints, Redis consumers/persistence, shutdown procedure and RBAC. Resolve ambiguous identities before any writes.
2. Build standalone Go controller with observe-only adapters, status/metrics, deadlines, restart-safe reconciliation and a minimal image. Start with web, daemon and Redis/Sentinel; extend adapters independently.
3. Reproduce the Redis shutdown failure in an isolated environment; correct the workload's persistence/termination configuration based on evidence.
4. Add explicit maintenance state machine and topology-specific shutdown/startup adapters with mutation disabled by default until configured.
5. Add bounded stateless scaling after verifying shared assets/configuration/session behavior. Add optional remaining service adapters.

Acceptance includes: application DB/Redis/PVC outage does not stop the operator; one hanging check does not block others; controller restart between each shutdown step resumes safely; duplicate requests do not repeat harmful actions; competing operators/GitOps/HPA are detected; split brain/stale metrics/API outage produce no unsafe mutation; shutdown timeout is visible; Redis Sentinel and Galera recover correctly in isolated rehearsals; no stateful data loss or secret disclosure; full-cluster and unexpected-power-loss limits are documented honestly. Resource/image measurements and installed Kubernetes-version compatibility are required before deployment.

## Primary references

- https://redis.io/docs/latest/commands/shutdown/
- https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination
- https://kubernetes.io/docs/concepts/cluster-administration/node-shutdown/
- https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/
