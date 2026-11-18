# Upgrade recovery

Preserve the original private state directory, image/bundle identity, namespace maintenance owner, native Job logs, installed package hash and DB receipt. Do not expose secrets or private state publicly.

| Stage | Direction |
| --- | --- |
| Before native Job | Matching guarded pre-upgrade continuation after identity verification |
| Native work in progress/uncertain | Inspect existing Job and receipt; no second installer |
| CONFIGURING after install | Matching config-only recovery; do not replay hooks |
| READY awaiting rollout | Reconcile saved rollout/replica intent |
| Both rollouts successful | Verify health/receipt and owned success-only cleanup |

These are triage directions, not permission to execute an old incident command. See [version-upgrade reference](../container-version-upgrade.md). The owner confirmed the earlier 0.1.0 configuration-resume completed; do not replay it.

Never falsify versions/fingerprints, reset maintenance claims, remove application/database PVCs or delete evidence to force progress.

