# Native backup failure: MariaDB system-table upgrade required

The source host's dump failed with1558: mysql.proc was created by10.11.13 but
the running server is13.0.2. Credentials and the configured DB name tessera
were verified. OTOBO writers were stopped and the application tar was created,
but the DB dump failed before application source replacement or OTOBO migration.
Keep the original upgrade state, crontab and application archive.

The initial SELECT1 preflight did not exercise routine metadata. The updated
helper checks routine/event metadata before shutdown on new attempts.
--resume-backup accepts only BACKING_UP and rechecks the original version,
configuration, installed package, merged report and compatibility package.
It requires local writers to remain stopped and a readable original application
tar. It preserves original services/daemon/crontab and renames the partial dump
before retrying. It cannot resume APPLYING or later migration phases.

## Repair MariaDB first

Extract this helper update into the existing ~/upgrade directory, replacing
upgrade-otobo111-source.py. The0.1.10 OPM is unchanged and need not be transferred
again. Verify BACKUP-RECOVERY-SHA256SUMS if desired.

    sudo bash repair-mariadb-system-tables.sh /root/tessera-upgrade-db.cnf

The script uses the already tested private client file, resolves the real datadir,
checks backup space, stops MariaDB and makes a root-private cold copy under
/opt/otobo-update/mariadb-system-repair.* (plus /etc/mysql). It restarts MariaDB,
runs mariadb-upgrade --force, then verifies routine/event metadata for tessera.
OTOBO application services remain stopped. A failed cold copy leaves MariaDB
stopped rather than running the system-table upgrade without the backup.
Do not remove the backup after success; retain it through upgrade acceptance.

This assumes the standalone local MariaDB source host and no external/encrypted
tablespaces outside its datadir/config backup. Sites with external DB storage
or encryption keys need their tested physical/VM backup procedure instead.
The scripts have not performed this repair on the host from the agent environment.

## Resume only the failed backup

Only after the MariaDB repair completes successfully:

    sudo python3 upgrade-otobo111-source.py apply \
      --resume-backup \
      --state /opt/otobo-update/tessera-11.1.1 \
      --db-name tessera \
      --db-defaults-file /root/tessera-upgrade-db.cnf \
      --tessera-package ./TESSERA-Base-0.1.10.opm \
      --confirm-modules

Do not manually change phase to PREPARED or create a replacement state: that
would lose the original startup/cron snapshot. Do not skip routines/events to
make an incomplete backup appear successful. An error retains maintenance.
Once apply completes successfully:

    sudo python3 upgrade-otobo111-source.py start \
      --state /opt/otobo-update/tessera-11.1.1

Verify fresh agent/customer login and the documented native acceptance cases.
Kubernetes is not touched.

## References

- [MariaDB error1558](https://mariadb.com/docs/server/reference/error-codes/mariadb-error-codes-1500-to-1599/e1558)
- [mariadb-upgrade and backup guidance](https://mariadb.com/docs/server/clients-and-utilities/deployment-tools/mariadb-upgrade)
