# Explicit recovery179 to184

The owner authorized stopping all application replicas and proceeding after live
diagnostics established installed package179, no database release receipt,
valid184 image package/hash/parser, and a terminal failed original upgrade Job.
The original180-r1 runtime image had been running against package179. Ordinary184
metadata permits180-183, which was the rejection; no native migration began.

`container/ubuntu2604/scripts/recover-179-to-184.py` is a standalone, one-attempt
operational compatibility correction. It does not edit shipped184 metadata/OPM,
falsify the installed version, disable fingerprint verification or grant write
permission to live web Pods. It directly uses the existing ReleaseUpgrade gate
with the single explicitly reviewed origin179 and target184. After success the
ordinary184 runtime gate verifies the normal READY receipt and package hash.

Audit: authoritative179 and184 DatabaseUpgrade sections contain the same
versioned TableCreate entries at158/8, which native version filtering skips from
179.179 already includes ztsm_async_execution.184's post-upgrade StorageEnsure
explicitly adds nullable request_data and dispatch_data columns if absent,
preserving rows. Existing FAQ/bootstrap/callback ensure hooks still execute
through native PackageUpgrade and strict ReleasePackage. This is not arbitrary
schema diffing or a promise that site-specific hooks cannot fail.

The helper requires the original private recovery directory, matching Deployment
UIDs/configuration, terminal failed source Job, no active release/diagnostic Jobs,
no HPA ownership and the saved maintenance owner. It claims recovery with a
resourceVersion-checked update, saves current replicas/configuration privately,
scales both application Deployments to zero and waits for live Pods to disappear.
Redis/database resources are not scaled or deleted. The one writable upgrade
Job requires receipt absent and installed179 again before any migration, verifies
image identity/hash, uses durable UPGRADING/CONFIGURING/READY phases, rebuilds
configuration and checks both history columns. Native/config failures retain
claims and stopped workloads; no automatic retry/rollback is attempted. The
helper reacts to Failed, rather than waiting only for Complete until timeout.

Only Job success permits184 image activation, restoration of the captured replica
counts and rollout waits. Namespace maintenance is marked READY only after both
rollouts succeed. No rollback to180 is safe to infer after a migration failure;
inspect the new receipt/Job first. Do not use this helper to resume a partial
upgrade or on a different target version. Unrelated writers/GitOps must remain
quiescent as with the original controlled helper.

Local validation:61 Perl assertions across179 recovery, normal release gate and
CAS tests; recovery manifest preservation/rejection checks and Perl compile;
two mocked Kubernetes workflow tests verify quiescence before Job creation,
activation only on success, and retained locks/no activation on failure. Actual
native179-to184 migration and portal/daemon acceptance remain to run on the site.

Run on the original k8s administration host holding the private state directory:

```bash
python3 "$HOME/recover-179-to-184.py" \
  --state-directory "$HOME/tessera-upgrade-184-20261027-134653"
```

The script creates a private `recovery179-to184` subdirectory; an existing one
blocks rerunning. Preserve it and all original evidence. Future release metadata
should encode reviewed origins at build time; this explicit incident-recovery
tool is not a general replacement for the normal release workflow.
