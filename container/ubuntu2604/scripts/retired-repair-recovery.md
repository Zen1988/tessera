# Revision2: historical installed repair artifact and prior preflight stop

This revision pins the observed target artifact49fbcb650ae70940e5c250df0628e90b7018f0bf872ea9799fc8897bb65dd21f
and additionally verifies its parsed identity, exactly one expected repair module,
and absence of CodeUninstall/DatabaseUninstall. A different artifact or destructive
uninstall contract stops before uninstall. The target artifact differs from the
local reviewed package; equivalence is not assumed from name/version alone.

It requires the first recovery's saved state and terminal failure logs showing
artifact mismatch at preflight before retirement. Uses its saved maintenance owner
and a new recovery-retired-repair-v2 directory; old evidence remains intact.
The temporary dry-run includes the existing repair as an exact skipped package,
ignoring only its obsolete forward installation dependencies because it will be
removed. Native uninstall still checks reverse dependencies without Force.

# One-time repair retirement and195 continuation

Authorized scope: target TESSERAMELTCrossObjectRecovery0.0.1 was a one-time
repair and is already uninstalled from the source. Failed Job1794548900 stopped
on the extra target package during preflight, with Base194 and no package journals.

Extract into the existing target toolkit directory on the host containing the
original artifacts/deploy-*/upgrade-job.json and saved pre-maintenance manifests.
Run python3 scripts/recover-retired-repair.py. It auto-detects the exact failed
Job state; alternatively pass --state-directory artifacts/deploy-195-<timestamp>.
No image rebuild or new bundle upload required.

The helper requires original namespace maintenance ownership, failed terminal
Job, no other active upgrade/diagnostic Job, unchanged stopped web/daemon and no
live application Pods/HPA. It verifies image195-r5, receipt UPGRADING195/from194,
Base194, absence of per-package journals, exact reviewed repair OPM fingerprint
and a complete dry-run plan including the extra repair. No Force/version rewrite.

Under CAS ownership of existing claims it records an uninstall journal, invokes
native PackageUninstall of only the reviewed repair, checks removal and retains
all recovered/preserved DynamicField data (reviewed package has no uninstall
code/database deletion hooks). It never installs/runs CodeInstall recovery.
Then it performs full native package reconciliation, configuration and READY
verification, activates r5 and restores original saved replica counts. Only
after both rollouts does it mark namespace maintenance READY.

One attempt only. Failure leaves Jobs, target PVC, namespace/database claims,
per-package journals and private artifacts/deploy-*/recovery-retired-repair/.
Do not rerun or clear locks/restore old replicas blindly; inspect the printed
failure stage, Job logs and diagnostic state. If the installed recovery package
fingerprint differs, it stops BEFORE uninstall; review target artifact explicitly.

Local syntax, planner and orchestration fixtures do not replace native target
MariaDB/Linux package-hook acceptance. This operation necessarily changes the
target database/configuration through native uninstall/upgrade routines.
