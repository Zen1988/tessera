# Planned single-host shutdown: handover before persistence

Confirmed direction, 2026-10-26. Design only; no executable shutdown coordinator or host hook is installed.

The host shutdown entry point must request maintenance while Kubernetes, networking, native topology managers and storage are still available. Transfer active responsibilities to surviving hosts before the departing instances perform their slow final persistence and volume cleanup. Service continuity and readiness to power off are separate milestones.

## Required sequence

1. Persist an operation ID and exact target node UID; serialize host maintenance and reject concurrent topology recovery on affected services. Cordon the target and check surviving capacity, control-plane quorum, service quorum, healthy replicas and storage placement. Do not start with a blanket drain.
2. Inventory actual roles on that host, including database primaries, Redis primary, operator leadership and network VIP ownership. Use installed native owners; not every component has a transferable primary role. Galera Primary component is not a single elected server primary.
3. Request service-specific planned handover to eligible members on other hosts. Observe synchronization and confirmed demotion/isolation of the old writer. Do not independently promote alongside Sentinel or a database operator. Replication catch-up required for safe handover cannot be skipped because persistence is slow.
4. Verify authoritative new ownership, client routing/reconnection and usable service on surviving hosts. Merely accepting a handover request or reporting a Ready Pod is insufficient. Existing connections must not continue writing to an obsolete primary. Redis client primary routing remains an explicit acceptance prerequisite.
5. Mark service handover complete. Drain the departing workload instances through their native owners and PDB-respecting eviction. Allow final RDB/AOF/checkpoint writes, Pod termination and volume unmount/detach to finish while service runs elsewhere. Never assume the same RWO volume can be mounted concurrently on another host; Longhorn evacuation is a separate storage operation.
6. Mark safe to power off only after required persistence, workload and storage completion checks. Keep kubelet/container runtime, networking and storage alive until this point. A timeout blocks planned power-off with a recorded reason; no forced deletion, forced promotion, NOSAVE fallback or fabricated success.

## Host integration and restart safety

Provide a deliberate maintenance/shutdown command backed by an external-to-the-departing-host coordinator. Persist intent and observed phase in Kubernetes using optimistic concurrency and idempotent operation IDs. Resume after process restart by observing native state before retrying; an uncertain command result requires observation, not blind replay. Coordinate existing automatic recovery to prevent competing actions.

A systemd integration must run before kubelet/containerd and network/storage teardown and must be validated against the installed host units and shutdown path. A late final shutdown script is insufficient. Hook failure must not be advertised as reliably vetoing every raw OS shutdown; define a tested maintenance entry point and fallback behavior. Abrupt power loss remains a separate recovery path. Do not install a privileged host agent or invoke power-off until the actual integration is verified.

Single-host maintenance keeps service available on survivors. Full-cluster shutdown instead quiesces clients and stops services in dependency order; there is no surviving host for handover.

## Implementation and acceptance still required

- Verify installed native planned-switchover interfaces and permissions for Redis/Sentinel, CNPG, MariaDB, VIP controllers and operator Lease leadership. Current recovery adapters do not supply this maintenance protocol.
- Verify host OS/systemd units, actual shutdown entry point, operator image distribution, effective Redis client routing and Longhorn maintenance policy. Do not infer these from proposed manifests.
- Implement a persisted maintenance state machine, topology-specific adapters and bounded host client; preserve upgrades and existing recovery receipts.
- Rehearse slow persistence, lagging replica, missing quorum, failed routing, uncertain handover response, coordinator restart, duplicate invocation and concurrent maintenance. Verify traffic continues before old-instance flush completes and power-off remains blocked until cleanup is safe.

References: [Redis coordinated failover](https://redis.io/docs/latest/commands/failover/), [Redis replication and persistence](https://redis.io/docs/latest/manual/replication/), [Kubernetes node shutdown](https://kubernetes.io/docs/concepts/cluster-administration/node-shutdown/). These describe native behavior, not proof of compatibility with the installed topology manager.
