# Redis recovery 0.3.5

Implemented: Sentinel-authorized replacement of one failed replica in a three-member StatefulSet. TLS requires certificate verification, DNS identity checking and configured client certificates. Credentials and CA/client certificate material come from one explicitly named Kubernetes Secret; values are never logged. Redis and Sentinel may use different password keys in that Secret. ACL usernames other than default are not supported yet.

Activation requires verified master name, headless service names, ports and Secret key names. redis-policy.example.json deliberately contains invalid placeholders and is not enabled by default. Append a completed policy to the EXISTING recovery.json policies array, preserving PostgreSQL configuration and the operation ledger. Do not apply the PostgreSQL-only config patch over an activated Redis configuration.

Required optional namespace tessera Role/RoleBinding for apps/tessera-operator:
- apps/statefulsets GET, resourceNames [tessera-redis-ha]
- core/pods GET/LIST (inventory and exact StatefulSet owner UID verification)
- core/pods/eviction CREATE
- core/secrets GET, resourceNames [the verified credential Secret name]
Existing observer permissions provide nodes and node leases. There is no Pod DELETE, PVC UPDATE/DELETE, Sentinel promotion or arbitrary Redis write permission in this adapter. Redis credential should allow INFO and Sentinel credential SENTINEL MASTER/CKQUORUM only.

Before eviction: require two surviving members on healthy fresh-heartbeat nodes; at least two of three configured Sentinels confirm the same primary IP, port and configuration epoch and CKQUORUM succeeds; no reachable successful Sentinel disagrees; primary INFO confirms master, surviving replica confirms that primary, same replication ID, active link, no synchronization and <=16 MiB offset lag. The failed member must not be current primary. Require three observations across at least 120 seconds, and target node must also be healthy. Persist operation before UID/resourceVersion-precondition eviction through policy/v1. Native operator/StatefulSet and Sentinel own rejoin and failover. Verify a new Pod UID is Ready and follows the current primary before completion. Fifteen-minute action budget, six-hour cooldown, bounded receipts and existing CAS Lease/ConfigMap are used. Primary/epoch changes stop action rather than guessing authority.

Limits: not yet live validated. No Redis primary promotion, whole-cluster restoration, independent backup, corruption repair, SHUTDOWN NOSAVE, force Pod deletion or hard node fencing. A Pod stuck terminating is reported explicitly; elapsed time or an unreachable node does not prove its Redis process has stopped. To support automatic dead-host replacement, integrate a verified power/hypervisor fencing provider and storage detach confirmation first. This release does NOT solve that original shutdown scenario yet. Network/API outages are infrastructure incidents and block Kubernetes actions. An in-cluster controller cannot repair a completely unavailable API by writing to that API.

API virtual IP incident: 10.0.1.60 is kube-vip. From node2, use read-only checks:

```sh
ip route get 10.0.1.60
ip neigh show 10.0.1.60
kubectl --server=https://10.0.1.62:6443 --request-timeout=5s get --raw=/readyz
kubectl --server=https://10.0.1.61:6443 --request-timeout=5s get --raw=/readyz
kubectl --server=https://10.0.1.63:6443 --request-timeout=5s get --raw=/readyz
```

These are per-command endpoint overrides; existing kubeconfig is preserved and TLS verification remains enabled. A certificate SAN error is distinct from routing/API readiness failure. If a direct API works, inspect kube-vip pods, logs, leader lease, node routing and VIP advertisement through that working endpoint. Do not restart all control-plane nodes or remove storage finalizers as a diagnostic step.

## 0.3.5 deployment and API availability

Observed NCS deployment is password-authenticated plaintext, not TLS: Sentinel logs explicitly say without TLS, local Redis plaintext INFO succeeds, and there are no certificate mounts. New explicit tls=false policy redis-policy-ncs.json matches that deployment; TLS is never downgraded automatically. Policy uses tessera-redis-auth/password, mymaster, and the observed per-Pod headless service names. Native Opstree status and all Sentinels agree on pod1, IP172.30.1.1. Pod2 confirms replication. Pod0 still needs a current protocol check; Kubernetes Ready alone cannot establish topology.

0.3.5 supports string/set Sentinel flags (redis-py8), checks reachable disagreements even without CKQUORUM, fixes indefinite cooldown extension, checks all-ready role topology, and includes state-machine eviction/replacement tests. Build gate copies the policy test fixture. Optional recovery-redis-rbac.yaml grants only named Secret GET, named StatefulSet GET, Pod inventory and eviction. configure-redis.py appends to existing recovery.json using resourceVersion precondition, preserving PostgreSQL policy and the independent recovery ledger. Run using Python3 on the kubectl host, from the kit directory. It does not activate container args or restart the Deployment itself.

The operator uses the in-cluster Kubernetes API service by default, not SSH kubeconfig. TESSERA_API_ENDPOINTS adds three explicit CA/hostname-verified HTTPS control-plane IPs. Safe GET requests fail over on transport failures and API5xx; authentication/RBAC/404 errors are not masked. Writes select an endpoint via a read first and are never replayed after an ambiguous timeout. Persisted recovery state reconciles uncertain results. Direct IPs must be in the API certificate SANs; no insecure TLS bypass. All endpoints still require functioning API/etcd quorum and Pod-to-host connectivity. This does not fix kube-vip or survive total control-plane loss.

After importing the SAME image on ALL THREE hosts into containerd namespace k8s.io, apply only the HA strategic merge patch to the existing Deployment:

```sh
kubectl -n apps patch deployment tessera-operator --type=strategic --patch-file ha-ncs-deployment-patch.yaml
kubectl -n apps rollout status deployment/tessera-operator
kubectl -n apps get pods -l app.kubernetes.io/name=tessera-operator -o wide
```

The patch retains existing container args/config mounts, sets3replicas, replaces the original single-node pin with required hostname anti-affinity across the3known nodes, includes control-plane toleration, uses imagePullPolicyNever, and adds API fallbacks. RollingUpdate maxSurge0/maxUnavailable1 avoids a fourth Pod blocked by required anti-affinity on a three-node cluster. If a host fails, its replacement stays Pending when the2survivors already have instances; existing survivors keep observing. One CAS Lease holder performs recovery; takeover waits for the120-second stale leadership threshold. This is a Deployment with3replicas, not a DaemonSet; new nodes need explicit scope/replica adjustment.

Redis adapter code is implemented but not yet image-built/deployed/live-validated. Before activation, apply optionalRedisRBAC and verify authenticated protocol access from the operator network. The image alone does not enable Redis recovery. Preserve existing recovery ledger and Lease during upgrades.

## Remaining requested recovery work

MariaDB/Galera single-member rejoin code exists but deployment identity/Secret key/TLS verification and live acceptance remain pending. Whole-component bootstrap requires native recovery position evidence; it is not implemented by this release. Longhorn/MetalLB currently observe only. inspect-recovery.sh collects the installed configuration and status needed to design native-controller recovery; it does not read Secret values. No Longhorn force-detach, salvage, PVC deletion, database bootstrap or speaker restart is implemented by this release. User confirms future VMware deployment and objective is service restoration on surviving nodes, not node replacement. No VMware credentials/provider are configured. An inaccessible writer is not evidence of stopped execution; any future forced takeover needs verified isolation and storage ownership evidence.
