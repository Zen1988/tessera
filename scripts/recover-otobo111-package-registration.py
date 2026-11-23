#!/usr/bin/env python3
"""Recover the verified packet-limit failure before Base 0.1.10 upgrade hooks."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time

OLD_SHA = "604d8b39b4bb027cdece41dbad91b2dc74181f27f72c0c2d126dcd2628b73359"
NEW_SHA = "234cc138db4d27b4d2f186e69e23049d13eeb89cf8dce95d30f143257e3da192"
NATIVE_PACKAGE_SHA = "371e1acae90d9bde6042ff2b6e6e5610ce5b5276208b25881ab8d6d8a9278844"
SPEC = importlib.util.spec_from_file_location(
    "native_upgrade", Path(__file__).with_name("upgrade-otobo111-source.py"))
UPGRADE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(UPGRADE)

# RepositoryAdd only stores package metadata/content; no PackageInstall,
# PackageReinstall, files, SQL install/upgrade blocks or package hooks run here.
RESTORE_PROGRAM = r'''
use strict;use warnings;
use Digest::SHA qw(sha256_hex);
use Encode qw(decode FB_CROAK);
use Kernel::System::ObjectManager;
local $Kernel::OM=Kernel::System::ObjectManager->new();
binmode STDIN, ':raw';
my $Bytes=do {local $/;<STDIN>};
die "Saved OPM checksum mismatch\n" if sha256_hex($Bytes) ne $ARGV[0];
my $Old=decode('UTF-8',$Bytes,FB_CROAK);
my $P=$Kernel::OM->Get('Kernel::System::Package');
my %Definition=$P->PackageParse(String=>$Old);
die "Unexpected saved package identity\n" if $Definition{Name}{Content} ne 'TESSERA-Base'
    || $Definition{Version}{Content} ne '0.1.9';
my $D=$Kernel::OM->Get('Kernel::System::DB');
$D->Prepare(SQL=>q{SELECT column_name FROM information_schema.statistics
    WHERE table_schema=DATABASE() AND table_name='article_version'
    AND index_name='article_version_source_article_id' ORDER BY seq_in_index})
    or die "Cannot verify completed native schema migration\n";
my @Columns;
while (my @R=$D->FetchrowArray()) {push @Columns,$R[0]}
die "Stable native schema checkpoint is missing\n"
    if join(',',@Columns) ne 'source_article_id,article_delete';
$D->Prepare(SQL=>q{SELECT engine FROM information_schema.tables
    WHERE table_schema=DATABASE() AND table_name='package_repository'})
    or die "Cannot verify registry storage engine\n";
my @Engine=$D->FetchrowArray();
die "Registry restore requires transactional InnoDB storage\n"
    if !@Engine || lc($Engine[0]) ne 'innodb';
my $Handle=$D->Connect();
$Handle->begin_work or die "Cannot begin metadata transaction\n";
my $OK=eval {
    my $Name='TESSERA-Base';
    $D->Prepare(SQL=>'SELECT version, install_status FROM package_repository WHERE name = ? FOR UPDATE',
        Bind=>[\$Name]) or die "Cannot inspect registry\n";
    my @Rows;
    while (my @R=$D->FetchrowArray()) {push @Rows,[@R]}
    die "Registry contains an unexpected or partially installed version; inspect before retry\n"
        if @Rows && (@Rows!=1 || $Rows[0][0] ne '0.1.9' || $Rows[0][1] ne 'installed');
    if (!@Rows) {
        $P->RepositoryAdd(String=>$Old) or die "Native RepositoryAdd failed\n";
        my $Status='installed';my $Version='0.1.9';
        $D->Do(SQL=>'UPDATE package_repository SET install_status = ? WHERE name = ? AND version = ?',
            Bind=>[\$Status,\$Name,\$Version]) or die "Cannot restore installed metadata status\n";
    }
    my $Stored=$P->RepositoryGet(Name=>$Name,Version=>'0.1.9');
    die "Restored package content unavailable\n" if !defined $Stored;
    utf8::encode($Stored) if utf8::is_utf8($Stored);
    die "Restored content differs from exact saved OPM\n" if sha256_hex($Stored) ne $ARGV[0];
    $Handle->commit or die "Metadata commit failed\n";
    1;
};
if (!$OK) {my $Error=$@;eval {$Handle->rollback};die $Error}
$P->_RepositoryCacheClear();
print "Verified Base0.1.9 registry metadata; no install or upgrade hooks executed.\n";
'''


def inputs(args):
    if not args.migration_completed:
        raise RuntimeError("This recovery requires the already observed 'Migration finished' result")
    state = args.state.resolve()
    info = json.loads((state / "state.json").read_text())
    if info["phase"] not in ("APPLYING", "PACKAGES_UPGRADING"):
        raise RuntimeError("Only the known package-registration failure can use this recovery")
    if (info["from"] != "11.1.0 beta2" or info["target"] != "11.1.1"
            or info["opm_sha256"] != OLD_SHA
            or info["tessera_package_sha256"] != NEW_SHA or info["db_name"] != "tessera"
            or info["tessera_target"] != "0.1.10" or info["commit"] != UPGRADE.COMMIT
            or info["archive_sha256"] != UPGRADE.ARCHIVE_SHA):
        raise RuntimeError("State does not match this verified 0.1.9 -> 0.1.10 incident")
    home = Path(info["home"])
    if UPGRADE.version(home) != "11.1.1" or UPGRADE.digest(home / "Kernel/Config.pm") != info["config_sha256"]:
        raise RuntimeError("Native version/configuration differs from the recovery checkpoint")
    if (home / "Custom/Kernel/System/Package.pm").exists():
        raise RuntimeError("Custom package manager requires separate review")
    if UPGRADE.digest(home / "Kernel/System/Package.pm") != NATIVE_PACKAGE_SHA:
        raise RuntimeError("Native Package implementation differs from the verified failure path")
    old = (state / "TESSERA-installed.opm").read_bytes()
    if hashlib.sha256(old).hexdigest() != OLD_SHA or UPGRADE.digest(args.tessera_package) != NEW_SHA:
        raise RuntimeError("Original/target OPM checksum mismatch")
    report = json.loads((state / "compatibility-review.json").read_text())
    data, files, entries = UPGRADE.compatibility_package(args.tessera_package, report)
    for entry in entries:
        if entry["path"] == "README.md":
            continue
        path = home / entry["path"]
        if not path.is_file() or UPGRADE.digest(path) != entry["merged_sha256"]:
            raise RuntimeError("Staged merged runtime changed: " + entry["path"])
    checksums = json.loads((state / "backup-sha256.json").read_text())
    if set(checksums) != {"otobo-files.tar", "database.sql.gz"}:
        raise RuntimeError("Original complete backup receipt missing")
    for name, sha in checksums.items():
        if UPGRADE.digest(state / name) != sha:
            raise RuntimeError("Original backup checksum mismatch: " + name)
    return state, info, home, old, data, files, entries


def restore_metadata(home, old):
    subprocess.run(["runuser", "-u", "otobo", "--", "perl", "-I.", "-ICustom",
                    "-IKernel/cpan-lib", "-e", RESTORE_PROGRAM, OLD_SHA],
                   cwd=home, input=old, check=True)


def recover(args):
    state, info, home, old, data, files, entries = inputs(args)
    # Reuse the stopped-writer/snapshot checks without recapturing startup state.
    args.db_name = "tessera"
    UPGRADE.validate_backup_resume(home, state, info, args, data)
    UPGRADE.packet_preflight(home, data)
    original = state / ("state.before-registration-recovery-" + str(time.time_ns()) + ".json")
    with original.open("x", encoding="utf-8") as saved:
        saved.write(json.dumps(info, indent=2) + "\n")
    info["phase"] = "PACKAGES_UPGRADING"
    info["registration_recovery"] = "verified-0.1.9-metadata-only"
    UPGRADE.save(state / "state.json", info)
    restore_metadata(home, old)
    # Crucially: no source copy, backup replay, DBUpdate-to-11.1 or fresh install.
    UPGRADE.upgrade_packages(home, data, files, entries)
    UPGRADE.finish_configuration(home, state, info)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--tessera-package", type=Path, required=True)
    parser.add_argument("--migration-completed", action="store_true")
    parser.add_argument("--services", default="apache2.service,cron.service,postfix.service,otobo-web.service,otobo-daemon.service")
    args = parser.parse_args()
    if sys.platform != "linux" or os.geteuid() != 0:
        parser.error("Run as root on the native Ubuntu source host")
    import fcntl
    os.umask(0o077)
    with open("/run/lock/tessera-otobo-source-upgrade.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        recover(args)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print("STOP: " + str(error), file=sys.stderr)
        sys.exit(1)
