# 0.3.5: resume stalled unfencing without resetting the operation

Live0.3.4 recognized the missing WAL, preserved the original PVC and completed native join, then stalled in unfencing with generic HTTPError. Owner verifies jobsGET/podlogsGET/podsLIST allowed, correct native Job ownership/Complete and join container; fence still present. Exact failing HTTP code remains unknown. Do not claim missing RBAC or completed recovery.

0.3.5 restricts the120-second log query to explicit failure detection only. Completed join logs remain byte/line bounded but have no time filter, retaining older archive/basebackup evidence. Fence updates re-read the Cluster resourceVersion immediately before PUT, check cluster UID/nativeprimary/systemID/fence unchanged and preserve concurrent metadata/status. HTTP failures report numeric status and fixed resource category only; no response bodies/URLs/credentials. Conflicts retry through ordinary next reconciliation, never replay uncertain writes. Existing ledger/operation/Lease/PVC/nativeJob retained. No new RBAC, manual ownership repair or arbitrary removal of fences.

Build/import the new0.3.5 image on all eligible nodes, then image-only rollout using the commands below. The current operation resumes at unfencing within its existing two-hour action budget. If that budget expires, inspect and design a checked resume; never reset timestamps or ledger blindly. Verify completed phase,3Ready and streaming, with original archive path recorded, before removing older images.

# 0.3.5: running replica blocked on missing WAL

Recognizes the live zero-restart Running/NotReady case using current-container logs from the last 120 seconds. Requires structured CNPG PostgreSQL records for this Pod: a walreceiver FATAL naming exactly one removed 24-digit WAL segment plus startup waiting for WAL. The same segment must persist through at least three observations across 120 seconds. Startup-only, stale/unstructured logs, changing segments and healthy Pods do not authorize replacement. Existing crash-loop timeline-divergence and Galera handling remain.

The existing native-primary/system-ID/timeline/streaming-survivor/node checks, UID checks, fencing, retained-PVC metadata, graceful eviction and native CNPG handoff remain mandatory. An available archive may still recover the replica during observation; readiness stops replacement. This does not establish that no external WAL archive exists. The policy authorizes replacement from verified survivors after sustained failure, preserving the original volume for investigation. No WAL reset or manual promotion.

Upgrade an existing 0.3.3 deployment by building/importing 0.3.5 on every eligible node, then changing only its image. Preserve recovery.json, recovery ledger, Lease, affinity and replica count. No new RBAC is needed for this patch. Do not reapply the generic installation manifest to an existing installation.

```sh
sudo env PATH="/usr/local/bin:$PATH" sh build-containerd.sh
sha256sum -c dist/tessera-operator-image.oci.tar.sha256
sudo ctr --namespace k8s.io images import dist/tessera-operator-image.oci.tar
# Repeat image import on each eligible node before rollout.
kubectl -n apps set image deployment/tessera-operator observer=docker.io/library/tessera-operator:0.3.5
kubectl -n apps rollout status deployment/tessera-operator --timeout=180s
kubectl -n apps get configmap tessera-recovery-state -o jsonpath='{.data.state\.json}'
kubectl -n postgres get pods -o wide
```

Image build, deployment and actual replica recovery must be verified on the administration host; the source ZIP is not a built image. Keep original volumes/receipts. Do not automatically reset an expired or previously completed operation; inspect the existing ledger first.

# Automatic recovery — 0.3.5 implementation and activation

Status: implemented with fake-API regression tests; Linux build, real WebSocket exec, native controller/PDB behavior and isolated recovery acceptance are required. The deployed0.1.0 image remains observe-only until this new image/config/RBAC is installed. This is not universal recovery or a guarantee of zero data loss.

## Two supported automatic actions

**CNPG timeline-divergent replica:** after three consecutive observations over at least120seconds, a registered fatal timeline error and repeated CrashLoop, identify exactly one failed member of a three-member cluster. Verify every node Ready/fresh Lease/no pressure, operator API access and independently query both surviving nodes through the Kubernetes exec API. Require one SQLprimary agreeing with current/target primary, expected system ID, matching timelines, confirmed streaming receiver and surviving replica replay lag<=16MiB. Apply CNPG's native fence annotation, preserve every mounted PVC by removing only the verified cluster owner reference and marking `cnpg.io/pvcStatus: detached`, then request graceful PDB-respecting eviction with UID/resourceVersion preconditions. No PVC is deleted. CNPG may reuse the same logical instance name and PVC: its native join procedure can rename the previous pgdata directory and write a fresh base backup beside it. That is same-volume retention, not an independent backup. Native CNPG provisions a replacement. If its completed join Job reused the retained PVC, verify Job ownership/completion, matching PVC identity and logs recording the old-directory rename plus successful base backup, then restore only the verified Cluster owner reference. CNPG itself marks the PVC ready and creates its database Pod. Completed Job Pods are excluded from membership checks; same-name replacement is recognized by new Pod UID. Remove this operation's fence after the old Pod disappears and verify all three members and replication before declaring completion. Preserved original data remains available for forensic reconciliation; the replacement does not merge divergent transactions back into the chosen primary history. This policy authorizes the native elected healthy primary as the continuing operational branch while retaining the other data.

**Galera transient failed rejoin:** recognize a narrow set of gcomm/Primary-view join errors, verify exactly three known member Pods and fresh nodes, query the other two members over verified TLS using the named root Secret, require matching configured UUID, Primary component, connected/ready/Synced and size>=2. Gracefully evict only the failing member so the existing StatefulSet/MariaDB operator performs rejoin/SST. Preserve existing PVCs. Verify all members before completion. No new primary component is forced, no safe_to_bootstrap/grastate changes and no forced recovery from an empty UUID/unknown seqno. Unknown errors and total Galera quorum loss do not trigger this single-member routine; the installed MariaDB operator's native whole-cluster recovery must be separately verified/configured.

No automatic service scaling, arbitrary shell execution, log-to-command generation, forced Pod deletion, disk wiping, database promotion, volume finalizer removal or PVC deletion is implemented. Redis/Sentinel/AWX recovery adapters remain pending. Native Kubernetes restart/reattach and native database failover continue independently.

## Persistence and credentials

Precreated `apps/tessera-recovery-state` ConfigMap stores operation intent/phase, target and cluster UIDs, source authority and preserved PVCs. Precreated `apps/tessera-recovery-leader` Lease coordinates active recovery. Resource-version compare-and-swap applies to writes; leadership is renewed before each mutation. Process restart resumes from phase and current actual state, including an eviction accepted before its response was lost. API/leadership uncertainty stops actions. No operator DB/PVC required. Named receipts are bounded to20 and no preserved volume is automatically purged; retention/capacity requires operational planning. A six-hour cooldown and two-hour per-operation budget prevent endless disruptive loops.

PostgreSQL uses a fixed read-only local SQL command as the postgres OS/database account through authenticated TLS Kubernetes WebSocket exec. No PostgreSQL superuser password is created or assumed; `awx-db-auth` is an application credential and is not used for recovery. `pods/exec` is administrative capability even though the code uses only fixed SQL; the optional Role is scoped to the postgres namespace. Never grant this recovery identity to untrusted workloads.

MariaDB root Secret confirmed by owner: `mariadb/tessera-mariadb-root`. Only exact named Secret GET is allowed; never list Secrets. `tessera-mariadb-ca-bundle` is a public CA bundle; signing CA private keys are not used. Key names, member TLS SANs, native CRD group and Galera UUID still require live verification before activation. This first Galera client does not supply client certificates; if the server requires mTLS, leave this policy disabled until client-certificate support is added. CA bytes are temporarily written to memory-backed /tmp for driver verification; passwords are kept in memory and never logged, placed in argv or embedded in image. Exceptions/log text are not echoed into recovery status.

## Build and install PostgreSQL recovery

1. Transfer/extract the0.3.5kit into a fresh directory. Run `sudo env PATH="/usr/local/bin:$PATH" sh build-containerd.sh`, verify archive SHA and import it with `sudo ctr --namespace k8s.io images import dist/tessera-operator-image.oci.tar`. Validate using the CONTAINERD.md command with tag0.3.5. Keep the original built0.1.0 image/archive available for rollback.
2. Distribute/import the same new OCI archive on all three eligible nodes **before** applying the HA patch. This patch replaces the old one-node affinity with required Pod anti-affinity and creates two operator replicas on distinct nodes; without image distribution a node may report ErrImageNeverPull. Keep Never pull policy for these locally imported images. A registry is an alternative. Node-level failure of an operator replica is handled by Kubernetes/leadership expiry; an operator Pod on a powered-off node cannot perform recovery itself.
3. Apply the optional PostgreSQL recovery permissions/state resources: `kubectl apply -f recovery-ncs-rbac.yaml`. The ledger ConfigMap manifest intentionally omits data, so repeated declarative apply preserves controller-owned progress; the Lease manifest omits holder/renewal fields for the same reason. Never add an empty state.json to these manifests or reset existing state during upgrades. Export/backup the live ledger for audit.
4. Add only the policy key to the existing ConfigMap: `kubectl -n apps patch configmap tessera-operator --type merge --patch-file recovery-config-patch.json`. This preserves existing observe config. Review the known system ID in this file; it comes from verified live cluster evidence.
5. `kubectl -n apps patch deployment tessera-operator --type strategic --patch-file recovery-deployment-patch.yaml`, then rollout status. This explicitly enables unattended actions for this one PostgreSQL cluster. Do not subsequently apply generic observe manifests over the recovery Deployment/config.
6. Inspect `/status` for mode automatic-recovery and the recovery check, and `kubectl -n apps get configmap tessera-recovery-state -o jsonpath='{.data.state\.json}'` for durable phase. Completion must show3Ready database members plus verified SQL/streaming. Preserve old detached PVC and record its operation ID. Do not delete it just because replacement is Ready.

To stop new actions: remove the `--recovery-config` arguments from the Deployment and roll it out. This does not unwind an existing fence or reattach a preserved PVC; inspect persisted state and use the native operator's documented controls. Do not blindly remove fences owned by other administrators or reset receipts. Keep the ledger/Lease resources during upgrades/reinstalls.

## Enable Galera only after verified inputs

Do not guess the password key or cluster UUID. Read only Secret key names and native recovery configuration first. Then add a policy to `recovery.json` and apply `recovery-galera-rbac.yaml`:

```json
{
  "name": "mariadb-rejoin",
  "kind": "galera-rejoin",
  "namespace": "mariadb",
  "cluster": "tessera-mariadb",
  "expected_identity": "VERIFIED-GALERA-UUID",
  "member_dns": "{pod}.tessera-mariadb-internal.mariadb.svc.cluster.local",
  "credentials": {
    "secret": "tessera-mariadb-root", "password_key": "VERIFIED-KEY",
    "ca_secret": "tessera-mariadb-ca-bundle", "ca_key": "VERIFIED-CA-KEY"
  }
}
```

Member DNS/TLS SAN coverage and CRD group `k8s.mariadb.com/v1alpha1` are assumptions to validate against actual objects; no Galera automatic policy is enabled by the supplied PostgreSQL config patch. Do not use wildcard Secret access to compensate for a wrong name.

## Limits and validation

API outage, unknown node liveness, pressure, split brain, no agreed primary component, unrecognized log, identity change, PDB denial, retention budget, failed credential/TLS checks or unavailable replacement storage produces an explicit non-action/blocked result. A root password cannot resolve which divergent copy is authoritative. For total-cluster loss, tested backups and native recovery/bootstrap procedures are still required. Existing asynchronous replication cannot guarantee zero RPO.

Test before production acceptance: split brain, no surviving quorum, node partition, stale Lease, wrong Secret/TLS, changing primary, PVC ownership mismatch, controller kill after every mutation, lost eviction response, concurrent leaders, PDB denial, failed replacement and replacement streaming. Unit tests/fake APIs do not substitute for these native integration tests. This first release has no external distributed network-probe agent; corroboration uses API/node Leases, both surviving SQL instances and actual replication connectivity.

Native behavior references: https://github.com/cloudnative-pg/cloudnative-pg/blob/v1.30.1/internal/cmd/plugin/destroy/destroy.go ; https://github.com/cloudnative-pg/cloudnative-pg/blob/v1.30.1/pkg/utils/labels_annotations.go ; https://github.com/mariadb-operator/mariadb-operator/blob/main/docs/api_reference.md .

Kubernetes 1.37 WebSocket exec requires both get and create on pods/exec; the optional recovery Role grants both, separately from Pod/log read access. This does not make exec a read-only RBAC capability. See https://www.kubernetes.dev/resources/keps/4006/ .

0.3.5 fixes the live 0.2.0 hand-off stall. Upgrade image and apply updated optional RBAC (adds native Job GET), keeping the existing recovery configuration, ledger and Lease unchanged. Do not re-run fresh activation, reset state or delete the retained PVC. The existing operation resumes at unfencing. Archive paths are recorded in the ledger; same-volume retained directories should be exported to independent storage. This cluster currently has no CSI snapshot API resources, so no independent snapshot is claimed. For stronger future preservation, snapshot/backup infrastructure must be installed and tested before selecting that policy.
