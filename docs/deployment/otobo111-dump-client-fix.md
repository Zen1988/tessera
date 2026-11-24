# Resume the failed continuation backup

The owner confirmed server/session max_allowed_packet128MiB but the dump client's
effective limit16MiB. The installed Base0.1.10 package_repository content is
17,603,341bytes and cannot fit that client limit. The database backup stopped;
no vendor/Base package operation started. Disk capacity is adequate.

This helper-only update explicitly passes --max-allowed-packet=128M to the dump
client in both native upgrade and continuation backup paths. Defaults-file
position, credentials, transactional backup options and failure guards remain.
No OPM, bundle plan, saved state or original backup is replaced.

Extract the helper ZIP into a new dump-client-fix subdirectory of the ORIGINAL
0.1.12 continuation bundle directory. From the new helper directory run:

    sha256sum -c SHA256SUMS
    sudo python3 continue-otobo111-addons.py \
      --state /opt/otobo-update/tessera-11.1.1 \
      --db-defaults-file /root/tessera-upgrade-db.cnf \
      --bundle ..

The --bundle path still points at the original directory holding the pinned
OPMs and continuation-plan.json. Both updated Python files must stay together.
Keep services stopped. The existing receipt has no active/completed package
operations; the failed backup can retry with the same original state/plan.
Only a successful dump followed by gzip validation and a backup checksum
receipt permits upgrades. Do not mark partial dumps complete or reset phases.
If another dump error occurs, inspect it before proceeding.

After successful UPDATED_STOPPED, use the normal saved-state start instructions.

Reference: https://mariadb.com/docs/server/clients-and-utilities/backup-restore-and-import-clients/mariadb-dump
