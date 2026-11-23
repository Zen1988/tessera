#!/usr/bin/env python3
"""Controlled native Ubuntu OTOBO beta -> 11.1.1 update; never a K8s updater."""
import argparse
import base64
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
import urllib.request
import xml.etree.ElementTree as ET

VERSION = "11.1.1"
# Official RotherOSS annotated tag rel-11_1_1 resolves to this commit.
COMMIT = "18feea896ab92138b5e8c4cd785ab4e198eccb1b"
ARCHIVE_URL = "https://codeload.github.com/RotherOSS/otobo/tar.gz/refs/tags/rel-11_1_1"
ARCHIVE_SHA = "347cfa9734f9b11f718bd2a8dd8b796256e3c6f98dc8924dc1bb7e82ac67a8b6"


def digest(path):
    with open(path, "rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def run(argv, home=None, capture=False):
    return subprocess.run([str(x) for x in argv], cwd=home, check=True,
                          stdout=subprocess.PIPE if capture else None)


def as_otobo(home, *argv, capture=False):
    return run(["runuser", "-u", "otobo", "--", *argv], home, capture)


def console(home, *argv):
    # Native InterfaceConsole treats a leading option as a request for command List.
    as_otobo(home, home / "bin/otobo.Console.pl", *argv, "--no-ansi")


def save(path, data):
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    path.chmod(0o600)


def package_export(home):
    # The actual installed repository is authoritative, not an arbitrary local OPM.
    perl = r'''
use strict; use warnings; use Kernel::System::ObjectManager;
local $Kernel::OM=Kernel::System::ObjectManager->new();
my $P=$Kernel::OM->Get('Kernel::System::Package');
my @P=grep {$_->{Name}->{Content} eq 'TESSERA-Base'} $P->RepositoryList();
die "Expected one installed TESSERA-Base package\n" if @P!=1
    || $P[0]->{Status} ne 'installed';
my $S=$P->RepositoryGet(Name=>'TESSERA-Base',Version=>$P[0]->{Version}->{Content});
die "Cannot export installed TESSERA package\n" if !$S;
binmode STDOUT, ':raw'; utf8::encode($S) if utf8::is_utf8($S); print $S;
'''
    return as_otobo(home, "perl", "-I.", "-ICustom", "-IKernel/cpan-lib",
                    "-e", perl, capture=True).stdout


def version(home):
    text = (home / "RELEASE").read_text()
    match = re.search(r"^VERSION\s*=\s*(.+)$", text, re.M)
    if not match:
        raise RuntimeError("Cannot identify installed OTOBO version")
    return match[1].strip()


def file_map(root):
    return {p.relative_to(root).as_posix(): p for p in root.rglob("*") if p.is_file()}


def audit(home, stage, opm):
    """Bind each shadow/conflict to exact old/new/custom bytes for human review."""
    target = file_map(stage)
    entries = {}
    for f in ET.fromstring(opm).find("Filelist"):
        name = f.attrib["Location"]
        prefix = "var/governancedb/runtime_overlay/"
        native = name[len(prefix):] if name.startswith(prefix) else name
        if native in target:
            deployed = home / ("Custom/" + native if name.startswith(prefix) else name)
            entries[deployed.relative_to(home).as_posix()] = (native, "package")
    custom = home / "Custom"
    if custom.exists():
        for name in file_map(custom):
            if name in target:
                entries["Custom/" + name] = (name, "custom")
    result = []
    for deployed, (native, owner) in sorted(entries.items()):
        current = home / native
        override = home / deployed
        new = target[native]
        # A packaged path missing on disk is not silently treated as compatible.
        if not current.is_file() or not override.is_file() or digest(current) != digest(new):
            result.append({
                "path": deployed, "native_path": native, "owner": owner,
                "current_native_sha256": digest(current) if current.is_file() else None,
                "target_native_sha256": digest(new),
                "override_sha256": digest(override) if override.is_file() else None,
                "reviewed": False,
            })
    return result


def verify_archive(archive):
    if digest(archive) != ARCHIVE_SHA:
        raise RuntimeError("Archive differs from the inspected official 11.1.1 tagged source")


def prepare(args):
    home, state = args.home.resolve(), args.state.resolve()
    if state.exists() or state.is_relative_to(home):
        raise RuntimeError("Use a new state directory outside /opt/otobo")
    current = version(home)
    if not re.fullmatch(r"11\.1\.0 beta[123]", current):
        raise RuntimeError("This helper supports 11.1.0 beta1/2/3 only; found " + current)
    state.mkdir(parents=True, mode=0o700)
    state.chmod(0o700)
    archive = state / "otobo-11.1.1-source.tar.gz"
    if args.archive:
        shutil.copyfile(args.archive, archive)
    else:
        with urllib.request.urlopen(ARCHIVE_URL, timeout=60) as source, archive.open("wb") as out:
            shutil.copyfileobj(source, out)
    verify_archive(archive)
    unpack = state / "source"
    unpack.mkdir()
    with tarfile.open(archive) as source:
        # Python >=3.12 data filter rejects absolute/traversal/special-device entries.
        source.extractall(unpack, filter="data")
    roots = list(unpack.iterdir())
    if len(roots) != 1 or version(roots[0]) != VERSION:
        raise RuntimeError("Unexpected source archive layout/version")
    stage = roots[0]
    opm = package_export(home)
    ET.fromstring(opm)
    (state / "TESSERA-installed.opm").write_bytes(opm)
    (state / "TESSERA-installed.opm").chmod(0o600)
    report = audit(home, stage, opm)
    save(state / "compatibility-review.json", report)
    save(state / "state.json", {
        "phase": "PREPARED", "home": str(home), "stage": str(stage),
        "from": current, "target": VERSION, "commit": COMMIT,
        "archive_sha256": ARCHIVE_SHA,
        "opm_sha256": digest(state / "TESSERA-installed.opm"),
        "config_sha256": digest(home / "Kernel/Config.pm"),
    })
    # Dependency report is deliberately non-installing.
    result = subprocess.run(["perl",
                             str(stage / "bin/otobo.CheckModules.pl"), "--list"],
                            cwd=home, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    (state / "module-check.txt").write_bytes(result.stdout)
    print(f"Prepared {current} -> {VERSION}. Conflicts requiring review: {len(report)}")
    print(f"Review: {state}/compatibility-review.json")
    print("No service stopped, database changed, or live file replaced.")


def compatible(current, reviewed):
    # No wildcard, omitted item, stale bytes or extra entry can grant approval.
    expected = [dict(item, reviewed=True) for item in current]
    return reviewed == expected


def compatibility_package(path, current):
    data = path.read_bytes()
    package = ET.fromstring(data)
    if package.findtext("Name") != "TESSERA-Base" or package.findtext("Version") != "0.1.10":
        raise RuntimeError("Expected the reviewed TESSERA-Base 0.1.10 compatibility package")
    files = {}
    for entry in package.findall("./Filelist/File"):
        name = entry.attrib["Location"]
        if name in files:
            raise RuntimeError("Duplicate compatibility payload")
        files[name] = base64.b64decode(entry.text or "", validate=False)
    manifest = json.loads(files["var/tessera/compatibility/otobo-11.1.1.json"])
    if manifest["target"] != VERSION or manifest["version"] != "0.1.10":
        raise RuntimeError("Incorrect compatibility target")
    entries = manifest["entries"]
    # The approval binds every actual report field, not just its path.
    approved = [{key: entry[key] for key in row}
                for row, entry in zip(current, entries)]
    if len(entries) != len(current) or not compatible(current, approved):
        raise RuntimeError("Installed files do not match the reviewed compatibility package")
    for entry in entries:
        name = entry["path"]
        if (not name.startswith("Custom/Kernel/") and name not in (
                "Kernel/System/DynamicField/Driver/Agent.pm",
                "Kernel/System/DynamicField/Driver/BaseEntity.pm", "README.md")):
            raise RuntimeError("Unexpected compatibility target")
        if ".." in Path(name).parts or Path(name).is_absolute():
            raise RuntimeError("Unsafe compatibility target")
        source = files[entry["source_location"]]
        if hashlib.sha256(source).hexdigest() != entry["merged_sha256"]:
            raise RuntimeError("Merged compatibility payload checksum mismatch")
    return data, files, entries


def with_package(home, data, operation):
    fd, temporary_opm = tempfile.mkstemp(prefix="tessera-core-update-", suffix=".opm",
                                        dir=home / "var/tmp")
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
        shutil.chown(temporary_opm, user="otobo")
        console(home, operation, temporary_opm)
    finally:
        Path(temporary_opm).unlink(missing_ok=True)


def upgrade_packages(home, data, files, entries):
    with_package(home, data, "Admin::Package::Upgrade")
    console(home, "Admin::Package::ReinstallAll")
    # Repair of another package can restore its old shared Custom implementation.
    with_package(home, data, "Admin::Package::Reinstall")
    for entry in entries:
        if digest(home / entry["path"]) != entry["merged_sha256"]:
            raise RuntimeError("Post-reinstall merged runtime mismatch: " + entry["path"])
    if hashlib.sha256(package_export(home)).hexdigest() != hashlib.sha256(data).hexdigest():
        raise RuntimeError("Installed TESSERA repository does not match the supplied package")


def backup_mode(info, requested):
    if requested:
        if info["phase"] != "BACKING_UP":
            raise RuntimeError("Backup resume requires BACKING_UP; migration phases cannot be resumed this way")
        return True
    if info["phase"] != "PREPARED":
        raise RuntimeError("Not PREPARED; do not retry a partially applied update")
    return False


def validate_backup_resume(home, state, info, args, package_data):
    required = ("active_services", "cron_present", "daemon_running",
                "tessera_package_sha256", "db_name")
    if any(key not in info for key in required) or not isinstance(info["active_services"], list):
        raise RuntimeError("Incomplete original maintenance state")
    if info["db_name"] != args.db_name or hashlib.sha256(package_data).hexdigest() != info["tessera_package_sha256"]:
        raise RuntimeError("Backup retry must use the original database and compatibility package")
    if not (state / "otobo.crontab").is_file():
        raise RuntimeError("Original saved crontab is missing")
    units = set(info["active_services"]) | set(args.services.split(","))
    for unit in units:
        if not re.fullmatch(r"[A-Za-z0-9@_.-]+", unit):
            raise RuntimeError("Invalid saved service")
        if subprocess.run(["systemctl", "is-active", "--quiet", unit]).returncode == 0:
            raise RuntimeError("Keep application writers stopped before backup resume: " + unit)
    cron = subprocess.run(["crontab", "-u", "otobo", "-l"], stdout=subprocess.PIPE)
    if cron.returncode not in (0, 1) or cron.stdout.strip():
        raise RuntimeError("Cannot confirm otobo cron remains stopped")
    daemon = subprocess.run(["runuser", "-u", "otobo", "--",
        str(home / "bin/otobo.Daemon.pl"), "status"], cwd=home, stdout=subprocess.DEVNULL)
    if daemon.returncode != 1:
        raise RuntimeError("Cannot confirm otobo daemon remains stopped")
    archive = state / "otobo-files.tar"
    if archive.is_symlink() or not archive.is_file():
        raise RuntimeError("Original application file backup is missing")
    with tarfile.open(archive) as saved:
        members = saved.getmembers()
        if not members or any(Path(m.name).parts[0] != home.name for m in members):
            raise RuntimeError("Unexpected application backup contents")


def preserve_failed_dump(state):
    partial = state / "database.sql.gz"
    if partial.exists():
        partial.rename(state / ("database.failed-" + str(time.time_ns()) + ".sql.gz"))


def apply(args):
    state = args.state.resolve()
    info = json.loads((state / "state.json").read_text())
    home, stage = Path(info["home"]), Path(info["stage"])
    resume = backup_mode(info, getattr(args, "resume_backup", False))
    verify_archive(state / "otobo-11.1.1-source.tar.gz")
    # Recheck extracted source against the verified archive, including staged modifications.
    with tarfile.open(state / "otobo-11.1.1-source.tar.gz") as source:
        for member in source.getmembers():
            if member.isfile():
                relative = Path(member.name).parts[1:]
                if relative and hashlib.sha256(source.extractfile(member).read()).hexdigest() != digest(stage.joinpath(*relative)):
                    raise RuntimeError("Staged official source has been changed")
    if version(home) != info["from"] or digest(home / "Kernel/Config.pm") != info["config_sha256"]:
        raise RuntimeError("Installed version/config changed; prepare again")
    opm = package_export(home)
    if hashlib.sha256(opm).hexdigest() != info["opm_sha256"]:
        raise RuntimeError("Installed TESSERA changed; prepare again")
    current = audit(home, stage, opm)
    merged_opm, merged_files, merged_entries = compatibility_package(args.tessera_package, current)
    if not args.confirm_modules:
        raise RuntimeError("Resolve module-check.txt, then supply --confirm-modules")
    for tool in ("tar", "mariadb-dump", "mariadb", "systemctl", "runuser", "crontab", "gnuplot"):
        if not shutil.which(tool):
            raise RuntimeError("Missing required tool: " + tool)
    if not re.fullmatch(r"[A-Za-z0-9_]+", args.db_name):
        raise RuntimeError("Unsupported database name")
    app_database = as_otobo(home, "perl", "-I.", "-ICustom", "-IKernel/cpan-lib",
        "-MKernel::Config", "-e",
        "my $C=Kernel::Config->new(); print $C->Get('Database');", capture=True).stdout.decode()
    if app_database != args.db_name:
        raise RuntimeError("--db-name must match the application's configured database")
    db_options = []
    if args.db_defaults_file:
        credential = args.db_defaults_file.resolve()
        if credential.stat().st_mode & 0o077 or credential.stat().st_uid != 0:
            raise RuntimeError("Database defaults file must be private (chmod 600)")
        db_options = ["--defaults-extra-file=" + str(credential)]
    # Default: local MariaDB root Unix-socket authentication; no credential guessing.
    run(["mariadb", *db_options, "--database", args.db_name, "-Nse", "SELECT 1"], capture=True)
    nontransactional = run(["mariadb", *db_options, "-Nse",
        "SELECT COUNT(*) FROM information_schema.tables "
        f"WHERE table_schema='{args.db_name}' AND table_type='BASE TABLE' "
        "AND (engine IS NULL OR engine<>'InnoDB')"], capture=True).stdout.strip()
    if nontransactional != b"0":
        raise RuntimeError("Non-InnoDB tables require a site-specific consistent database backup")
    # SELECT 1 alone does not exercise mysql.proc or mysql.event.
    run(["mariadb", *db_options, "-Nse",
         f"SHOW FUNCTION STATUS WHERE Db='{args.db_name}'; SHOW EVENTS FROM {args.db_name}"],
        capture=True)
    if resume:
        validate_backup_resume(home, state, info, args, merged_opm)
    for path in (home / "var/article", home / "Kernel/Config.pm", home / "Custom"):
        if path.is_symlink():
            raise RuntimeError(f"External/symlink data needs a site-specific backup plan: {path}")
    # Reject symlink destinations before copying upstream files over a live tree.
    for rel in set(file_map(stage)) | {entry["path"] for entry in merged_entries}:
        path = home / rel
        while path != home:
            if path.is_symlink():
                raise RuntimeError("Upstream destination is a symlink: " + str(path))
            path = path.parent
    tree_size = sum(p.stat().st_size for p in home.rglob("*") if p.is_file())
    db_size = int(run(["mariadb", *db_options, "-Nse",
        "SELECT COALESCE(SUM(data_length+index_length),0) FROM information_schema.tables "
        f"WHERE table_schema='{args.db_name}'"], capture=True).stdout.strip())
    if shutil.disk_usage(state).free < tree_size + 2 * db_size + 2 * 1024**3:
        raise RuntimeError("Insufficient backup space; use a larger --state filesystem")
    if not resume:
        active = []
        for unit in args.services.split(","):
            if not re.fullmatch(r"[A-Za-z0-9@_.-]+", unit):
                raise RuntimeError("Invalid systemd unit")
            if subprocess.run(["systemctl", "is-active", "--quiet", unit]).returncode == 0:
                active.append(unit)
        cron = subprocess.run(["crontab", "-u", "otobo", "-l"], stdout=subprocess.PIPE)
        if cron.returncode not in (0, 1):
            raise RuntimeError("Cannot read otobo crontab")
        (state / "otobo.crontab").write_bytes(cron.stdout)
        daemon_running = subprocess.run(["runuser", "-u", "otobo", "--",
            str(home / "bin/otobo.Daemon.pl"), "status"], cwd=home,
            stdout=subprocess.DEVNULL).returncode == 0
        info.update(phase="STOPPING", active_services=active, db_name=args.db_name,
                    cron_present=cron.returncode == 0, daemon_running=daemon_running,
                    tessera_target="0.1.10", tessera_package_sha256=hashlib.sha256(merged_opm).hexdigest())
        save(state / "state.json", info)
        for unit in active:
            run(["systemctl", "stop", unit])
        as_otobo(home, home / "bin/Cron.sh", "stop")
        as_otobo(home, home / "bin/otobo.Daemon.pl", "stop")
    # On any error from here, leave services stopped and retain backups/state.
    info["phase"] = "BACKING_UP"
    save(state / "state.json", info)
    if resume:
        preserve_failed_dump(state)
    else:
        run(["tar", "--acls", "--xattrs", "--numeric-owner", "-cpf",
             state / "otobo-files.tar", "-C", home.parent, home.name])
    with (state / "database.sql.gz").open("wb") as output:
        process = subprocess.Popen(["mariadb-dump", *db_options, "--single-transaction",
            "--routines", "--events", "--triggers", "--hex-blob", "--databases", args.db_name],
            stdout=subprocess.PIPE)
        with gzip.GzipFile(fileobj=output, mode="wb") as compressed:
            shutil.copyfileobj(process.stdout, compressed)
        if process.wait():
            raise RuntimeError("Database backup failed; no live source replacement attempted")
    with gzip.open(state / "database.sql.gz", "rb") as check:
        while check.read(1024 * 1024):
            pass
    save(state / "backup-sha256.json", {
        name: digest(state / name) for name in ("otobo-files.tar", "database.sql.gz")})
    info["phase"] = "APPLYING"
    save(state / "state.json", info)
    # Native in-place overlay preserves articles, cron, Custom and package payloads.
    # Never copy an old Config/Files tree over the new upstream XML definitions.
    protected_config = (home / "Kernel/Config.pm").read_bytes()
    shutil.copytree(stage, home, dirs_exist_ok=True, symlinks=True)
    if (home / "Kernel/Config.pm").read_bytes() != protected_config:
        raise RuntimeError("Config.pm changed unexpectedly; keep services stopped")
    # The migration itself must run against the merged stable runtime, not old
    # Custom shadows. No live source is touched until both backups are complete.
    for entry in merged_entries:
        if entry["path"] == "README.md":
            continue
        destination = home / entry["path"]
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(merged_files[entry["source_location"]])
    run([home / "bin/otobo.SetPermissions.pl"])
    # Beta -> final includes migrations added after beta2. Do not skip as a patch update.
    as_otobo(home, home / "scripts/DBUpdate-to-11.1.pl")
    upgrade_packages(home, merged_opm, merged_files, merged_entries)
    for command in ("Maint::Config::Rebuild", "Maint::Cache::Delete",
                    "Maint::Loader::CacheCleanup", "Maint::Loader::CacheGenerate",
                    "Maint::Translations::Deploy"):
        console(home, command)
    console(home, "Admin::Package::List", "--show-deployment-info")
    if digest(home / "Kernel/Config.pm") != info["config_sha256"] or version(home) != VERSION:
        raise RuntimeError("Final source/config check failed")
    info["phase"] = "UPDATED_STOPPED"
    save(state / "state.json", info)
    print("Update completed; services remain stopped for operator review.")
    print("Review package output/log, then run the start subcommand.")


def start(args):
    state = args.state.resolve()
    info = json.loads((state / "state.json").read_text())
    if info["phase"] != "UPDATED_STOPPED":
        raise RuntimeError("Only a fully completed update can be started")
    home = Path(info["home"])
    if info["cron_present"]:
        run(["crontab", "-u", "otobo", state / "otobo.crontab"])
    if info["daemon_running"] and "otobo-daemon.service" not in info["active_services"]:
        as_otobo(home, home / "bin/otobo.Daemon.pl", "start")
    for unit in info["active_services"]:
        run(["systemctl", "start", unit])
    info["phase"] = "STARTED_PENDING_ACCEPTANCE"
    save(state / "state.json", info)
    print("Services started. Verify login, ticket workflow, CMDB, integration and package status.")
    print("Build the new Kubernetes image only after source-host acceptance.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="action", required=True)
    p = subs.add_parser("prepare", help="Download/pin source and audit; no downtime")
    p.add_argument("--home", type=Path, default=Path("/opt/otobo"))
    p.add_argument("--state", type=Path, required=True)
    p.add_argument("--archive", type=Path, help="Optional exact pinned GitHub source archive")
    p = subs.add_parser("apply", help="Quiesce, back up, migrate, reinstall; leave stopped")
    p.add_argument("--state", type=Path, required=True)
    p.add_argument("--db-name", required=True)
    p.add_argument("--tessera-package", type=Path, required=True,
                   help="Reviewed TESSERA-Base-0.1.10.opm; approves only matching exact source hashes")
    p.add_argument("--db-defaults-file", type=Path)
    p.add_argument("--confirm-modules", action="store_true")
    p.add_argument("--resume-backup", action="store_true",
                   help="Retry only failed BACKING_UP; preserve original service/crontab state")
    p.add_argument("--services", default="apache2.service,cron.service,postfix.service,otobo-web.service,otobo-daemon.service")
    p = subs.add_parser("start", help="Start only services active before update")
    p.add_argument("--state", type=Path, required=True)
    args = parser.parse_args()
    if sys.platform != "linux" or sys.version_info < (3, 12) or os.geteuid() != 0:
        parser.error("Run as root on native Ubuntu with Python >=3.12; not inside Kubernetes")
    os.umask(0o077)
    # One native update process at a time, including service restart.
    import fcntl
    with open("/run/lock/tessera-otobo-source-upgrade.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        {"prepare": prepare, "apply": apply, "start": start}[args.action](args)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, subprocess.CalledProcessError, ValueError) as error:
        print("STOP: " + str(error), file=sys.stderr)
        sys.exit(1)
