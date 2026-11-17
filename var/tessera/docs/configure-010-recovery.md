# Configuration-only continuation for 0.1.0

Use this only for the failed 0.1.0 release whose read-only diagnostic shows an exact matching installed package artifact, a CONFIGURING receipt, no package journals and all package-plan entries skipped. The reported duplicate SysConfig setting INSERT can be reproduced when an external cached setting list omits a row already present in the database. This is a reproduced failure mode, not proof of the live Redis failure's cause.

Extract TESSERA-0.1.0-Config-Rebuild-Recovery.zip into the original prepared build directory. Keep its private artifacts/deploy-* directory and the current bundle PVC. Stop the original waiting local upgrade helper with Ctrl-C if still running. Run:

```bash
python3 scripts/resume-config010.py --namespace tessera --job tessera-release-1794798990
```

The helper finds the unique original artifacts/*/upgrade-job.json for that Job. If it cannot, supply --state-directory with the original private state directory; do not reconstruct snapshots from the currently stopped deployments. It requires the original maintenance ownership, terminal failed Job, quiesced deployments, no other active release Job, no HPA and an available bundle.

One immutable ConfigMap supplies the updated configure.py to one Job using the existing image. The native release service claims its CONFIGURING receipt atomically and rechecks installed package hashes and journals before configuration. No package upgrade hooks are permitted. The native config console runs with external cache reads disabled for this process, preserving database rows, native rebuild locking, ACL/process deployment and success fingerprint checks. Redis errors may still require separate investigation.

After configuration succeeds, the helper activates the same 0.1.0 image, restores exact saved replica counts and waits for both rollouts before marking namespace maintenance READY. It retains the failed source Job. Bundle cleanup is deferred if any retained Pod still references it. Failure retains maintenance ownership and evidence; do not rerun automatically or delete the maintenance ConfigMap.

If stopped, report the helper output and the configuration Job logs. No live recovery success is claimed by the local tests.
