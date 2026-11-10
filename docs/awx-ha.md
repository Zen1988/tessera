# AWX availability across the three existing Kubernetes nodes

## Confirmed two-node rollout deadlock and correction

Live events now confirm k8s3 NotReady/untolerated taint and both remaining nodes excluded by required anti-affinity. Both Deployments have default25% surge/25% unavailable. For two desired replicas that means one surge Pod but zero allowed unavailable, so old Pods occupy both usable hostnames and new Pods cannot schedule. The earlier native-CR patch alone is insufficient for this degraded-cluster rollout.

Use operator/awx-ha/rollout-strategy-patch.json to set maxSurge0/maxUnavailable1, web first and task only after web succeeds. This narrowly changes Deployment rollout policy, not CR-owned replicas or Pod placement. Upstream AWX Deployment templates inspected expose no strategy setting; do not invent an AWX CR field. This is an explicit exception to the general instruction below against patching generated Deployments: the CR still owns replicas/affinity. Installed operator reconciliation behavior must be verified; retain the policy in the deployment management source if supported rather than assuming it can never be reverted. No operator version change required for the Kubernetes strategy field itself.

```sh
kubectl -n awx patch deployment tessera-awx-web --type=merge --patch-file rollout-strategy-patch.json
kubectl -n awx rollout status deployment/tessera-awx-web --timeout=600s
# Continue only after web rollout succeeds and two web replicas are available.
kubectl -n awx patch deployment tessera-awx-task --type=merge --patch-file rollout-strategy-patch.json
kubectl -n awx rollout status deployment/tessera-awx-task --timeout=600s
kubectl -n awx get deployments,pods -o wide
kubectl -n awx get deployments tessera-awx-web tessera-awx-task -o jsonpath='{range .items[*]}{.metadata.name}{" strategy="}{.spec.strategy}{"\\n"}{end}'
```

This allows one unavailable desired replica per component during rollout; it does not guarantee health of the surviving replica. Task replacement may interrupt active jobs: use an idle period. No force deletion, finalizer change, taint bypass or volume operation is part of this correction. Down-node terminating Pods may remain until separate node cleanup; require two current-revision Ready Pods on different Ready nodes before accepting the rollout. These commands are prepared for owner execution; no mutation or success has been observed by the agent.

Owner requests at least two replicas on the three-node cluster. The observed deployment had one web Pod and one task Pod, both on k8s3.ncs.local. When that node became NotReady both deployments had zero available replicas. AWX subsequently recovered after a few minutes; the observed NodeNotReady age of about 4m50s is consistent with default300s eviction tolerations, but actual tolerations/eviction timing are not yet verified. PostgreSQL Pod readiness on that failed node was stale evidence, not proof of continued service.

Desired configuration: two AWX web replicas and two AWX task replicas. Required hostname anti-affinity applies separately to each component, so the two web Pods occupy different nodes and the two task Pods occupy different nodes. Web and task may share a node. All three nodes remain eligible subject to existing placement/resource/storage rules; two replicas per component occupy two of the three nodes, not every node. Losing one node should leave at least one web and one task Pod scheduled elsewhere. This is service redundancy, not a guarantee that a job executing on the lost node continues without interruption.

The native AWX custom resource owns the configuration. Do not scale or patch its generated Deployments directly: operator reconciliation may replace those changes. No TESSERA OPM/operator image change is needed. The standalone TESSERA Operator still has only AWX ping observation, not an AWX recovery controller.

## Inspect the installed configuration first

Run on a surviving Kubernetes administration host:

```sh
kubectl -n awx get awx
kubectl -n awx get hpa
kubectl -n awx get deployments -o wide
kubectl -n awx get deployments tessera-awx-web tessera-awx-task -o jsonpath='{range .items[*]}{.metadata.name}{"\nselector="}{.spec.selector}{"\nnodeSelector="}{.spec.template.spec.nodeSelector}{"\naffinity="}{.spec.template.spec.affinity}{"\ntolerations="}{.spec.template.spec.tolerations}{"\nvolumes="}{.spec.template.spec.volumes}{"\n\n"}{end}'
kubectl -n awx get pvc -o wide
kubectl get nodes -o wide
kubectl explain awx.spec.web_replicas
kubectl explain awx.spec.task_replicas
kubectl explain awx.spec.web_affinity
kubectl explain awx.spec.task_affinity
```

After confirming the actual AWX resource name (expected tessera-awx from Deployment names), inspect only relevant settings, not Secret values:

```sh
kubectl -n awx get awx tessera-awx -o jsonpath='replicas={.spec.replicas}{"\nweb_replicas="}{.spec.web_replicas}{"\ntask_replicas="}{.spec.task_replicas}{"\nweb_manage_replicas="}{.spec.web_manage_replicas}{"\ntask_manage_replicas="}{.spec.task_manage_replicas}{"\naffinity="}{.spec.affinity}{"\nweb_affinity="}{.spec.web_affinity}{"\ntask_affinity="}{.spec.task_affinity}{"\nnode_selector="}{.spec.node_selector}{"\nweb_node_selector="}{.spec.web_node_selector}{"\ntask_node_selector="}{.spec.task_node_selector}{"\nprojects_persistence="}{.spec.projects_persistence}{"\nprojects_existing_claim="}{.spec.projects_existing_claim}{"\nprojects_storage_access_mode="}{.spec.projects_storage_access_mode}{"\n"}'
```

Check that:

- Installed CRD/operator supports the fields and object-valued affinity. Confirm operator image/version from the Deployment. Current upstream defaults manage web/task replicas; an explicit false value or an HPA requires reconciling replica ownership before changing counts.
- At least two eligible Ready nodes have capacity, the required images and existing appropriate tolerations for this all-control-plane cluster. Do not add blanket tolerations or remove selectors without examining their purpose.
- Existing node selectors/affinity do not pin all replicas to one hostname. Preserve meaningful placement constraints. When adding component affinity, preserve the effective existing component affinity or inherited generic affinity: component values override the generic affinity in the upstream templates.
- Actual Deployment labels match the candidate's selectors. Existing affinity arrays require merging, not replacement. The candidate patch assumes no existing effective affinity; **do not apply it unchanged when such rules exist**.
- Any project/custom PVC mounted by multiple replicas supports cross-node access (normally RWX for a shared claim). No AWX PVCs appeared in the earlier snapshot, but actual Pod volumes and project persistence still need verification. Never change an existing claim's access mode/delete a PVC as a shortcut. hostPath/local storage or RWO project/custom claims need a separate migration/design.
- PostgreSQL's primary/read-write endpoint actually fails over to a surviving instance; all Pods Running in stale API output is insufficient. The AWX database configuration must use that endpoint rather than an individual database Pod.
- The Cilium Gateway/backend Service includes healthy surviving web endpoints and removes failed endpoints. A surviving web Pod alone cannot guarantee uninterrupted browser/API access during database or network convergence.

## Candidate patch

`operator/awx-ha/ha-patch.example.json` changes only web/task replicas and their separate required hostname anti-affinity rules. It uses verified upstream AWX field names and observed Deployment names to construct candidate selectors; it is **prepared, not applied or verified against the installed CR**. Review/merge current effective affinity before using it. No fixed hostname list is introduced. Save a private backup of current relevant settings before mutation; full resource exports can contain sensitive custom configuration and should stay on the admin host.

After inspection and merging any existing constraints, the reviewed file can be submitted using the native resource:

```sh
kubectl -n awx patch awx tessera-awx --type=merge --patch-file ha-patch.reviewed.json --dry-run=server -o yaml
kubectl -n awx patch awx tessera-awx --type=merge --patch-file ha-patch.reviewed.json
kubectl -n awx get awx tessera-awx
kubectl -n awx get deployments,pods -o wide
```

Do not treat the initial Deployment status immediately after CR patching as acceptance: the AWX Operator must first reconcile it. Once desired replicas and Pod anti-affinity appear in both generated Deployments, wait for their rollout:

```sh
kubectl -n awx rollout status deployment/tessera-awx-web --timeout=600s
kubectl -n awx rollout status deployment/tessera-awx-task --timeout=600s
kubectl -n awx get pods -o wide
kubectl -n awx get events --sort-by=.metadata.creationTimestamp | tail -n 40
kubectl -n awx get endpointslices -o wide
```

Repeated application of the same reviewed patch is declarative/idempotent. It neither creates duplicate resources nor rewrites credentials, database configuration or PVCs. Reverting is a narrow patch restoring the saved replica and component-affinity values (use null to remove newly introduced override fields); never replay a stale full-resource backup over unrelated new settings. If GitOps owns the AWX resource, make the same change in its source of truth so it is not reverted.

Required anti-affinity keeps a second replica Pending rather than placing both replicas of a component on one remaining node. That preserves the intended placement rule; one surviving replica can continue service while capacity returns. A PodDisruptionBudget is an optional separate maintenance policy and does not prevent physical node loss.

## Acceptance

Verify two Ready web Pods on different nodes and two Ready task Pods on different nodes; authenticate through https://awx.ncs.local and run a harmless test job. Then repeat a controlled single-node loss and confirm surviving web/task readiness, gateway availability, database read/write access and ability to launch/complete a new job. Inspect any in-flight interrupted jobs independently; no automatic replay of uncertain non-idempotent work. Do not claim zero downtime or job continuity merely from replica counts.

References: [AWX independent replica scaling](https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/advanced-configuration/scaling-the-web-and-task-pods-independently.html), [AWX scheduling fields](https://docs.ansible.com/projects/awx-operator/en/latest/user-guide/advanced-configuration/assigning-awx-pods-to-specific-nodes.html), [native web Deployment template](https://github.com/ansible/awx-operator/blob/devel/roles/installer/templates/deployments/web.yaml.j2). Installed CRD/operator verification takes precedence over upstream development examples.

## Received live preflight — 2026-10-26

The supplied read-only output confirms awx/tessera-awx, no HPA/PVCs in the namespace, the expected component selectors and empty effective nodeSelector/affinity for both Deployments. Their mounted volumes are Secret/ConfigMap/emptyDir, including task projects, so no cross-node project PVC restriction is visible. operator/awx-ha/ha-patch.reviewed.json is prepared with two web/task replicas and explicit native replica management. Run server dry-run and confirm all six fields are retained before applying; no live mutation or installed CRD acceptance has been performed here. Existing capacity, tolerations and image availability can still affect placement. Verify reconciliation before treating rollout status as acceptance.
