# Recovery for failed0.1.7 Navis installer hook

Scope: Job tessera-release-1795404303, image/package0.1.7, receipt UPGRADING from0.1.3, exactly one matching Base journal, all26 installed package versions/artifact hashes match image, missing Navis field. Requires original build folder/private artifacts state and quiesced workloads with unchanged images/maintenance owner.

This helper completes0.1.7; it does not deploy0.1.8 or require an image rebuild.

1. Verify the ZIP checksum on your Kubernetes host.
2. From the ORIGINAL tessera-build.PmlvYdwn folder, extract this ZIP to overlay the helper files. Keep artifacts/ and the original upgrade-bundle unchanged. Stop any original still-waiting local upgrade helper with Ctrl-C.
3. Run once:

python3 scripts/recover-navis017.py --namespace tessera --job tessera-release-1795404303

The helper finds the unique matching original artifacts/*/upgrade-job.json. If needed, add --state-directory artifacts/<the-original-state-folder>.

Behavior: verifies original failed Job, saved manifest, image/bundle mounts, lock ownership, no active release Jobs/HPA/application writers and original replica intent. An immutable ConfigMap supplies the exact reviewed missing-field fix only to a recovery process. The runtime database/package artifacts remain0.1.7. Full installed artifact inventory and pinned original installer/bootstrap/post-hook are checked. Cache backend set/read/delete/cleanup must work before native recovery claim/hook execution. No cache credentials or Config.pm are changed. An unresolved Redis error stops preflight with original package journal intact.

After successful preflight, a native CAS claims the existing UPGRADING receipt. The exact pinned native post-upgrade hook is re-executed with the corrected installer; this includes idempotent FAQ/governance bootstrap and asynchronous storage/provider completion. No PackageUpgrade, file/database-install replay or version-record editing occurs. Native package completion cache/loader/event steps run. Only after verified post-hook completion is the exact matching package journal deleted by raw-value CAS. The receipt becomes CONFIGURING, native inventory/schema/configuration rebuild succeeds, then a final cache set/read/delete verification and native release verification publish READY. Only a successful Job allows the Python wrapper to activate the existing0.1.7 image and restore exact saved replica counts. The maintenance lock becomes READY after rollout.

The original failed Job, recovery Job, code ConfigMap, bundle PVC and private recovery evidence are retained. Do not delete any field/journal/lock manually. If the helper stops, paste its output and recovery Job logs; do not repeat it or switch images. A failed configuration leaves CONFIGURING for reviewed continuation; hook failure leaves the package journal. This is deliberately not a general stale-lock takeover or automatic retry facility.

Local checks:57 recovery-state/native-adapter assertions,7 mocked Kubernetes orchestration cases, native OTOBO XML parser verification of the pinned hook, Perl/Python syntax checks. No live deployment/recovery performed by the author. Redis root cause remains independently unresolved until preflight/output confirms its state.
