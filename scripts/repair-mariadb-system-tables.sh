#!/usr/bin/env bash
# Existing OTOBO application maintenance must remain in place throughout repair.
set -Eeuo pipefail
[[ $EUID == 0 ]] || { echo "Run as root" >&2; exit 1; }
credentials=/root/tessera-upgrade-db.cnf
if (( $# > 0 )); then credentials=$1; fi
[[ -f "$credentials" && ! -L "$credentials" ]] || { echo "Missing private client file" >&2; exit 1; }
[[ $(stat -c %u -- "$credentials") == 0 && $(stat -c %a -- "$credentials") == 600 ]] ||
    { echo "Client file must be root-owned mode600" >&2; exit 1; }
for tool in mariadb mariadb-upgrade systemctl cp realpath mktemp du df flock python3; do
    command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }
done
exec 9>/run/lock/tessera-otobo-source-upgrade.lock
flock -n 9 || { echo "Another native upgrade/repair is running" >&2; exit 1; }
python3 - <<'PY'
import json
from pathlib import Path
state = json.loads(Path("/opt/otobo-update/tessera-11.1.1/state.json").read_text())
if state["phase"] != "BACKING_UP":
    raise SystemExit("This repair helper requires the recorded BACKING_UP maintenance state")
PY
db_data=$(mariadb --defaults-extra-file="$credentials" -Nse 'SELECT @@datadir')
db_data=$(realpath -e -- "$db_data")
[[ -d "$db_data" && "$db_data" != / ]] || { echo "Invalid database directory" >&2; exit 1; }
mkdir -p -- /opt/otobo-update
backup_dir=$(mktemp -d /opt/otobo-update/mariadb-system-repair.XXXXXXXX)
chmod 700 -- "$backup_dir"
case "$backup_dir/" in "$db_data/"*) echo "Backup must be outside datadir" >&2; exit 1;; esac
required=$(du -sb -- "$db_data" | cut -f1)
available=$(df -B1 --output=avail -- "$backup_dir" | tail -1)
(( available > required + 1073741824 )) || { echo "Insufficient space for cold database copy" >&2; exit 1; }
echo "Cold backup destination: $backup_dir"
trap 'echo "Repair stopped. Keep OTOBO services stopped. Preserve $backup_dir and the original upgrade state." >&2' ERR
mariadb --defaults-extra-file="$credentials" -Nse 'SELECT @@version, @@datadir' > "$backup_dir/server-version.txt"
systemctl stop mariadb.service
if systemctl is-active --quiet mariadb.service; then
    echo "MariaDB did not stop" >&2
    exit 1
fi
# A failed cold copy leaves MariaDB stopped; never copy a running datadir.
cp -a --reflink=auto --sparse=always -- "$db_data" "$backup_dir/datadir"
if [[ -d /etc/mysql ]]; then cp -a -- /etc/mysql "$backup_dir/server-config"; fi
systemctl start mariadb.service
mariadb-upgrade --defaults-extra-file="$credentials" --force
mariadb --defaults-extra-file="$credentials" -Nse \
    "SHOW FUNCTION STATUS WHERE Db='tessera'; SHOW EVENTS FROM tessera" >/dev/null
echo "MariaDB system-table upgrade completed. Cold backup retained: $backup_dir"
echo "OTOBO remains in maintenance. Use the updated helper with --resume-backup."
