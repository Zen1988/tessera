# TESSERA Operator 0.3.3

Independent in-cluster infrastructure observer in namespace `apps`, built on Ubuntu 26.04 LTS with Python in a dedicated virtual environment. No TESSERA/Perl runtime, own database or PVC. Default deployment is observe-only. Optional automatic PostgreSQL/Galera recovery is implemented in recovery.py and activated separately using RECOVERY.md; it adds privileged scoped permissions. No primary promotion, forced bootstrap, shutdown orchestration or scaling is implemented. No Service, Ingress, Gateway, NodePort, hostPort or LoadBalancer is created. Ingress NetworkPolicy denies Pod ingress; validate your CNI enforces it and permits kubelet probes. Existing additive allow policies can broaden access. The status endpoint is unauthenticated and contains infrastructure metadata: do not expose it.

## Implemented observations

- Kubernetes API and operator-side DNS connectivity, node readiness/pressure and node Lease freshness, per-Pod readiness/restarts/overdue termination, PVC phase/conditions and attachment errors.
- CPU/memory usage quantities from the optional Kubernetes metrics API, with stale samples marked unknown; no metrics database dependency or scaling writes.
- Longhorn `longhorn.io/v1beta2` node readiness, volume robustness and manager namespace Pods. Missing CRDs/permissions are unknown, not healthy.
- MetalLB controller/speaker desired versus ready counts, IP pool/L2 configuration counts and LoadBalancer address assignment in monitored namespaces. Assigned addresses do not prove L2/BGP reachability or MetalLB ownership. Data-plane verification remains unknown.
- MariaDB/Galera member identity, primary component, sync/connected/ready flags and minimum members.
- Redis member role, replica upstream health, primary replica count and persistence error status; individual Sentinel primary view and CKQUORUM. Compare configured per-member results; this release does not automatically establish cross-member consensus or track legitimate failover changes to expected roles.
- PostgreSQL physical cluster system identifier, expected role and replica WAL receiver streaming. Does not establish topology-manager authority, lag bounds or newest data.
- AWX HTTPS `/api/v2/ping/` response/version/instance count. Job execution and dependency health remain explicitly unverified.

Each adapter has its own process, timeout and bounded concurrency. A timed-out/hung DNS/driver/API operation is killed; failures do not initiate recovery. Dependency failures do not fail the observer readiness probe. Result timestamps and freshness are returned at `/status`; `/livez` checks loop progress and `/readyz` checks completed observation freshness. Results/logs are ephemeral; no durable audit history. No CRD/controller writes or leader election are needed for this read-only release. Multiple replicas would duplicate observations.

## Build image

For the owner's containerd-only x86_64 host, follow **[CONTAINERD.md](CONTAINERD.md)** and use `build-containerd.sh`. It exports an OCI archive through BuildKit and provides explicit `ctr` import/final-runtime validation commands. The Docker path below remains available for other builders.

From this directory on a host with a Linux container builder:

`sh build.sh` builds the image, runs the embedded 78-test gate, validates the final nonroot image with networking disabled, and exports `dist/tessera-operator-image.tar` plus SHA256 and image metadata. Override the tag with `TESSERA_OPERATOR_IMAGE`; an existing local tag is rejected. It never pushes or applies manifests. Resource limits are initial estimates, not measured production sizing. The manual equivalent is:

```sh
python -m unittest discover -s tests -v
docker build --pull --no-cache -t tessera-operator:0.3.3 .
docker run --rm --read-only --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --mount type=bind,src="$PWD/config.example.json",dst=/etc/tessera-operator/config.json,readonly \
  tessera-operator:0.3.3 --validate
docker save -o tessera-operator-0.3.3.tar tessera-operator:0.3.3
```

For your registry, tag/push deliberately, then set the resulting image reference/digest in `k8s.yaml`. Alternatively import the saved archive into every eligible node's container runtime. No registry address, credentials or live cluster context is assumed here. Dependencies are version-pinned; the Ubuntu base tag and APT packages are moving upstream inputs. Record the resolved image/base digests and scan the built image before deployment. This repository does not claim a reproducible digest or a completed image build without a builder receipt. User accepts Alpine or Ubuntu; this first image uses Ubuntu 26.04 LTS with only Python/venv/CA packages installed without recommended packages. Python was selected for the first functional implementation because Python is available in the workspace; Go remains a possible later size optimization. Actual image size and memory require Linux measurement.

## Configure and install

For the owner's verified three-node inventory, `k8s-ncs-observe.yaml` is a prepared initial deployment: creates `apps`, reads the actual application/operator namespaces using scoped Roles, uses the imported image with `imagePullPolicy: Never`, and requires node `k8s.ncs.local` by node name (plus the specific control-plane NoSchedule toleration). No image rebuild needed. It does not provide failover while the image exists on one node. No protocol targets are enabled because TLS/auth/cluster identities are unverified; Pod/PVC/node/Longhorn/MetalLB/metrics observations work independently of database credentials. Namespace existence, taints/admission and CNI behavior are still subject to server dryrun/live acceptance. After transferring the YAML, run `kubectl apply --dry-run=server -f k8s-ncs-observe.yaml`, then apply deliberately, check rollout and logs. Do not apply the generic manifest over this deployment afterward: it would replace namespace config and scheduling/image policy.

The supplied manifest starts with no protocol targets: Kubernetes/Longhorn/MetalLB observations run, and missing database/AWX endpoints are reported unknown. This avoids guessed service names and credentials. Existing `apps`, `longhorn-system`, `metallb-system` and `kube-node-lease` namespaces are required; adjust names/scoped RoleBindings to actual installations. Add a Role/RoleBinding for each extra monitored namespace; do not grant cluster-wide Secret access. No new namespace is created.

1. Inspect real service/member names, versions, chart/operator owners, TLS CAs, topology IDs and endpoint permissions. Use stable **per-member** DNS targets, not a load-balanced service for membership assertions. Add each relevant member/Sentinel to `targets`, following `config.example.json`.
2. Mount existing monitoring-only Secrets as read-only files in the Deployment. Passwords/tokens belong in Secret files, never ConfigMap/image/CLI. The sample references `/credentials/<adapter>/...`; add Secret volumes/mounts with restrictive file modes readable by UID/GID65532. No Secret data is supplied or read through the Kubernetes API. Projected files are re-read each check.
3. All protocol connections verify server TLS and hostname. No plaintext or skip-verification mode exists. Configure actual internal TLS endpoint/CA; a missing TLS setup is not silently downgraded. Redis client uses TLS on the configured port, which may differ from the sample. No mutual TLS client-certificate configuration yet.
4. Provide minimal SQL permissions: MariaDB connection and `SHOW GLOBAL STATUS`; PostgreSQL connection, read-only queries plus explicitly authorized `pg_control_system()` execution and WAL receiver visibility (monitoring role as appropriate to installed PostgreSQL). Do not use database administrator credentials. Redis requires INFO; Sentinel requires `SENTINEL MASTER` and `SENTINEL CKQUORUM`. Keep all write/admin commands denied. AWX token is optional when ping is permitted anonymously; use read-only authorization if required.
5. Edit `ConfigMap.data.config.json`, build/import image, then inspect `kubectl diff -f k8s.yaml` and `kubectl apply --dry-run=server -f k8s.yaml` before applying deliberately. Existing namespace egress policies must allow API443, DNS and configured target ports. The supplied ingress policy intentionally leaves egress to existing cluster policy; it does not claim full traffic isolation.
6. Apply `kubectl apply -f k8s.yaml`, then `kubectl -n apps rollout status deployment/tessera-operator`. Restart the Deployment after changing config (config is validated once at startup). Mounted tokens/passwords refresh per request/check.

Inspect internally:

```sh
kubectl -n apps logs deployment/tessera-operator --tail=5
kubectl -n apps port-forward deployment/tessera-operator 8080:8080 --address 127.0.0.1
# In another terminal, only on the local machine:
curl http://127.0.0.1:8080/status
```

Every endpoint is read-only; POST/DELETE are unsupported. Probe readiness means the observer works, not that all infrastructure is healthy. Unknown covers missing configuration, denied access, missing CRDs, deadline and unverified layers. Independent node-local perspectives, auto-discovery of service topology and utilization-based scaling remain future work. Optional policy-bound recovery is described in RECOVERY.md; the observe manifest does not enable it. Node status and network observations from one Pod cannot prove an isolated writer stopped.

## Acceptance before enabling any recovery

Run isolated tests for API loss, DNS loss, permission denial, unavailable DB/PVC, stalled adapter, stale leases, wrong cluster identity, role change, TLS failure, Redis persistence errors, Galera partition, PostgreSQL nonstreaming replica and operator restart. Confirm no target is mutated; other adapters keep reporting; no credentials occur in logs/status; status becomes stale if the loop stalls. Confirm resource usage at actual target counts, node replacement and probe/CNI behavior. No live cluster acceptance or image-runtime test has been performed solely by source unit tests.

## Source references

- Kubernetes service accounts: https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/
- Galera status: https://mariadb.com/docs/galera-cluster/reference/galera-cluster-status-variables
- PostgreSQL control data: https://www.postgresql.org/docs/current/functions-info.html
- MetalLB allocation: https://metallb.io/usage/
- Longhorn API definitions: https://github.com/longhorn/longhorn-manager/blob/master/k8s/crds.yaml
- AWX ping implementation: https://github.com/ansible/awx/blob/devel/awx/api/views/__init__.py

Security rebuilds pull the current Ubuntu base, disable build-layer reuse and upgrade installed APT packages before installing the runtime. This reduces stale-package findings but cannot guarantee a clean VA scan; scan the final image digest with your approved scanner. Ubuntu 26.04 is the current LTS choice; see https://ubuntu.com/about/release-cycle .

Longhorn stalled recovery is available as a separately enabled policy in0.3.3. See LONGHORN.md for progress timing, native-controller repair conditions and limits. This supplements Longhorn's own replica rebuilding; it does not implement volume force-detach or salvage.
