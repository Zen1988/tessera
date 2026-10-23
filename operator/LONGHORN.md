# Longhorn stalled recovery — 0.3.2

Longhorn owns replica replication and rebuilding. TESSERA persistently watches the recovery that Longhorn reports and identifies prolonged absence of observable progress. Optional longhorn-stall-recovery policy uses the existing apps Lease/ConfigMap; no operator DB/PVC. Not activated by image upgrade alone. Longhorn policy plus PostgreSQL, Redis and Galera can coexist (four policies). Existing reconciliation checks one policy per monitoring cycle; with four policies, a policy is sampled about every four cycles. Threshold detection and repair occur on those samples, not exact wall-clock deadlines.

Default stall threshold is 900 seconds, raised to at least native replica-replenishment-wait-interval plus300seconds. Require at least3observations. Timer survives leadership changes/restarts. A gap over600seconds resets observations, avoiding a false stall inferred from an unavailable API. Volume UID changes reset evidence. Track active running engine UID, RW replica count and rebuildStatus progress. High-water marks prevent progress oscillation from endlessly resetting the timer; resourceVersion churn is not progress. Report conditions, attachment state and unknown engine evidence. An intentionally unused detached volume is idle. A configured desired attachment that never reaches attached is tracked as failure.

Automatic repair currently covers ONE repeatedly crashing longhorn-manager Pod only when:
- Stalled degraded volume is attached, currentNodeID agrees with the node of the failed manager, status.ownerID names that node, and the active engine reports at least one RW replica.
- Exactly one manager in the verified longhorn-manager DaemonSet is not Ready, with >=3 CrashLoopBackOff restarts for its longhorn-manager container. At least2other manager Pods are Ready.
- All involved Kubernetes nodes are Ready, heartbeat fresh, no pressure/network failure. Target is not already deleting.

Persist repair intent, then request UID/resourceVersion-precondition policy/v1 eviction. PDB applies. Native DaemonSet replaces manager; Longhorn resumes controller reconciliation and owns rebuilding. One attempt per six-hour cooldown, maximum20receipts; uncertain mutation outcome consumes attempt rather than repeating a restart loop. An accepted eviction is NOT successful volume recovery. Subsequent volume status observations must show recovery; the operator continues tracking the volume until then.

No restarts of healthy managers for slow storage, no engine/instance-manager restarts, no volume/replica writes/deletions, no salvage/force-detach, no capacity changes, no removal of attachment/finalizer safeguards. Full disks, unavailable nodes, failed healthy-copy evidence, all-replicas-faulted or attachment disputes produce explicit stalled reports rather than a guessed repair. This is a bounded repair for a failed native controller, not a generic fix for every storage failure. No application I/O verification claim.

## Enable after importing/building0.3.2

Retain existing ConfigMap ledger and Lease. Apply optional namespace permissions, append policy preserving other policies, then restart current Deployment to load configuration:

```sh
kubectl apply -f recovery-longhorn-rbac.yaml
python3 configure-redis.py --policy longhorn-policy-ncs.json
kubectl -n apps rollout restart deployment/tessera-operator
kubectl -n apps rollout status deployment/tessera-operator
```

Deployment must already have --recovery-config /etc/tessera-operator/recovery.json (existing PostgreSQL deployment does). No generic observe manifest reapply/configreset. If enabling from scratch, optional recovery-ncs-rbac.yaml creates the sharedledger/Lease without overwriting their data. HA image imports are required on all3nodes before removing originalnodepin.

Read recovery/longhorn-recovery in each Pod's /status; only Lease holder runs this policy. A standby leadership report is not a Longhorn failure. Source tested locally, not live Longhorn acceptance tested or image-built by the agent.
