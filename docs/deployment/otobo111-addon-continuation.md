# Continue the paused native OTOBO11.1.1 upgrade

The core migration and Base0.1.10 installation already completed. ReinstallAll
failed because it reinstalls registered versions; it does not discover and
upgrade11.0-only packages to their11.1 successors.

This continuation pins official compatible releases:

| Package | Installed | Target |
| --- | --- | --- |
| ITSMConfigItemMultitenancy | 11.0.2 | 11.1.1 |
| ITSMConfigItemLabelPrint | 11.0.4 | 11.1.1 |
| ITSMChangeManagement | 11.0.3 | 11.1.1 |
| ITSMIncidentProblemManagement | 11.0.2 | 11.1.2 |
| TimeAccounting | 11.0.6 | 11.1.3 |

Other installed11.1 packages remain at their verified versions. This is a
targeted compatibility migration, not an unreviewed online UpgradeAll.
Dependencies are checked against actual installed/proposed versions before writes.
The current CMDB11.1.2 and ITSMCore11.1.4 satisfy these declarations.

Base0.1.11 contains reviewed multitenancy overlap merges. Customer entitlement
and TESSERA reserved capabilities remain mandatory; no anonymous CI detail
grant is introduced. Native agent tenant-group restrictions remain in force.

Keep the existing state/backups and application services stopped. After reboot,
check the packet limit; SET GLOBAL alone does not survive restart. A128MiB
server limit is sufficient for the bundled packages. The root-private client
file /root/tessera-upgrade-db.cnf remains local and is never included in bundles.

Extract the continuation ZIP into a fresh directory, then run:

    sudo python3 continue-otobo111-addons.py \
      --state /opt/otobo-update/tessera-11.1.1 \
      --db-defaults-file /root/tessera-upgrade-db.cnf \
      --bundle .

The helper checks core/config/package/backup identities, stopped writers,
framework compatibility and dependencies, and creates an additional private
application/database backup before upgrading. It journals each package operation;
an interrupted/in-progress hook is rejected on retry and requires inspection.
Completed steps may be skipped only after registry hash verification.

It never runs DBUpdate-to-11.1, restores old registry metadata, forces packages,
relabels vendor framework requirements or deletes governance data.
After compatible add-ons and Base upgrade, ReinstallAll runs, Base is reapplied
last, all merged runtime targets are checked and configuration/cache/assets rebuilt.
Successful completion leaves UPDATED_STOPPED.

If Apache/cron were masked for shutdown, unmask them without starting them:

    sudo systemctl unmask apache2.service cron.service

Only after continuation success:

    sudo python3 upgrade-otobo111-source.py start \
      --state /opt/otobo-update/tessera-11.1.1

The bundle includes the updated start helper. Native Ubuntu only; Kubernetes
requires its separately planned core DB migration and rollout.

Official sources:

- https://ftp.otobo.org/pub/otobo/packages-itsm/
- https://ftp.otobo.org/pub/otobo/packages/
