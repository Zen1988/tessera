# Recover the reviewed testing0.1.8 to0.1.12 upgrade

The owner explicitly waived backup for this testing server. This helper is bound
to failed Job tessera-release-1795491815, its original image/bundle/private state,
UPGRADING0.1.12 from0.1.8 receipt and the exact hookless LabelPrint11.1.1 artifact.
It does not provide general stale-lock takeover or arbitrary package replay.

From the original build folder, extract the ZIP into recovery012 and verify its
SHA256SUMS. Run the script with the original deployment state:

    python3 recovery012/scripts/recover-release012.py \
      --namespace tessera --job tessera-release-1795491815 \
      --state-directory artifacts/deploy-0.1.12-20261124-034249-f923e75245 \
      --test-no-backup

It first creates a separate DB-read-only preflight Job. This checks prerequisites
before maintenance ownership transfers or any recovery/database migration writes.
A preflight failure can be corrected and retried while the original receipt and
package journal remain unchanged. Temporary cache smoke probes are the only
preflight writes. After preflight passes, recovery itself is one-attempt.

It checks the failed/saved Job identity, maintenance ownership, inactive runners,
stopped and unchanged deployments, no HPA, and retained bundle PVC. Recovery code
is mounted in a new immutable ConfigMap; the existing image/bundle stay intact.
It claims a unique private recovery directory and a durable database recovery
receipt. Any error keeps maintenance/claims/evidence; no automatic hook retry.

The database preflight binds image/bundle/old Base hashes, exact LabelPrint
journal/registry/OPM, source compatibility guards, mounted Config.pm checksum,
packet capacity and actual Redis roundtrip. Before package continuation it runs
the pinned official OTOBO11.1.1 migration tasks in native order. Native DB task
implementations retain their existing table/column/index existence checks.
The Docker-specific task that edits Config.pm is skipped because this deployment
uses an external read-only Config.pm; that checksum must remain unchanged.
Cache bypass is reapplied before each task since native tasks discard objects.
This is a recorded native migration step for the separate Kubernetes database.

LabelPrint11.1.1 is pinned and must contain no Code/Database programs. Its native
same-version reinstall repairs files/configuration with cache bypass. File hashes,
registry and the existing SysConfig row ID are verified before its exact journal
is completed with a conditional delete. Completed package upgrades are not rerun;
remaining packages follow the original native reconciler and durable journals.

Only matching package inventory, rebuilt config/fingerprint, execution-history
schema, unchanged Config.pm and final dependencies allow READY. Then the Python
helper restores the original image/replica counts and waits for rollout before
marking maintenance READY. Original failed Job, bundle PVC and recovery evidence
are retained. Preserve the saved recovery directory on failure; do not retry it,
clear journals, edit version records, or run deploy-release again.
