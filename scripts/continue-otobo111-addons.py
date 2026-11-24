#!/usr/bin/env python3
"""Continue only the paused package stage; never rerun the OTOBO core migration."""
import argparse
import base64
import gzip
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET

SPEC = importlib.util.spec_from_file_location(
    "native_upgrade", Path(__file__).with_name("upgrade-otobo111-source.py"))
U = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(U)
OLD_BASE_SHA = "234cc138db4d27b4d2f186e69e23049d13eeb89cf8dce95d30f143257e3da192"
INVENTORY = r'''
use strict;use warnings;use Digest::SHA qw(sha256_hex);use JSON::PP qw(encode_json);
use Kernel::System::ObjectManager;
local $Kernel::OM=Kernel::System::ObjectManager->new();
my $P=$Kernel::OM->Get('Kernel::System::Package');$P->_RepositoryCacheClear();
my @Output;
for my $R ($P->RepositoryList()) {
    my $Name=$R->{Name}{Content};my $Version=$R->{Version}{Content};
    my $Content=$P->RepositoryGet(Name=>$Name,Version=>$Version);
    utf8::encode($Content) if utf8::is_utf8($Content);
    my %Check=$P->AnalyzePackageFrameworkRequirements(Framework=>$R->{Framework},NoLog=>1);
    push @Output,{name=>$Name,version=>$Version,status=>$R->{Status},sha256=>sha256_hex($Content),
        compatible=>$Check{Success}?1:0};
}
print encode_json(\@Output);
'''


def inventory(home):
    result = U.as_otobo(home, "perl", "-I.", "-ICustom", "-IKernel/cpan-lib",
                        "-e", INVENTORY, capture=True)
    rows = json.loads(result.stdout)
    if len({r["name"] for r in rows}) != len(rows):
        raise RuntimeError("Ambiguous package registry")
    if any(r["status"] != "installed" for r in rows):
        raise RuntimeError("A package has incomplete installed status; inspect before continuing")
    return {r["name"]: r for r in rows}


def version_key(value):
    if not re.fullmatch(r"\d+(?:\.\d+)+", value):
        raise RuntimeError("Unsupported package version: " + value)
    parts = [int(x) for x in value.split(".")]
    while parts and parts[-1] == 0:
        parts.pop()
    return tuple(parts)


def load_bundle(bundle):
    plan = json.loads((bundle / "continuation-plan.json").read_text())
    packages = []
    for entry in plan["packages"]:
        path = bundle / entry["file"]
        if path.name != entry["file"] or U.digest(path) != entry["sha256"]:
            raise RuntimeError("Invalid package path/checksum")
        data = path.read_bytes()
        root = ET.fromstring(data)
        if root.findtext("Name") != entry["name"] or root.findtext("Version") != entry["version"]:
            raise RuntimeError("Package identity mismatch")
        frameworks = root.findall("Framework")
        if not frameworks or any(x.text != "11.1.x" for x in frameworks):
            raise RuntimeError("Package is not explicitly compatible with11.1")
        for f in frameworks:
            if f.get("Minimum") and version_key(f.get("Minimum")) > version_key("11.1.1"):
                raise RuntimeError("Package framework minimum exceeds this host")
            if f.get("Maximum") and version_key(f.get("Maximum")) < version_key("11.1.1"):
                raise RuntimeError("Package framework maximum excludes this host")
        deps = [{"name": x.text, "minimum": x.get("Version")} for x in root.findall("PackageRequired")]
        if deps != entry["dependencies"]:
            raise RuntimeError("Package dependency metadata differs from plan")
        packages.append((entry, data))
    if len({p["name"] for p, _ in packages}) != len(packages):
        raise RuntimeError("Duplicate planned package")
    return plan, packages


def validate_plan(current, packages):
    planned = {p["name"]: p for p, _ in packages}
    for name, row in current.items():
        if not row["compatible"] and name not in planned:
            raise RuntimeError("Unreviewed incompatible package: " + name)
    proposed = {name: row["version"] for name, row in current.items()}
    for entry, _ in packages:
        name = entry["name"]
        if name not in current or current[name]["version"] not in (entry["from"], entry["version"]):
            raise RuntimeError("Unexpected installed version for " + name)
        if current[name]["version"] == entry["version"] and current[name]["sha256"] != entry["sha256"]:
            raise RuntimeError("Target registry content differs for " + name)
        proposed[name] = entry["version"]
    for entry, _ in packages:
        for dep in entry["dependencies"]:
            if dep["name"] not in proposed or version_key(proposed[dep["name"]]) < version_key(dep["minimum"]):
                raise RuntimeError("Unsatisfied dependency: " + dep["name"])


def check_receipt(receipt, plan_hash):
    if receipt.get("plan_sha256") != plan_hash:
        raise RuntimeError("Continuation plan differs from saved attempt")
    if receipt.get("active"):
        raise RuntimeError("Interrupted package operation requires inspection: " + receipt["active"])


def runtime_preflight(home, base_data):
    payload = {f.get("Location"): base64.b64decode(f.text)
               for f in ET.fromstring(base_data).findall("./Filelist/File")}
    original = json.loads(payload["var/tessera/compatibility/otobo-11.1.1.json"])["entries"]
    overlaps = json.loads(payload["var/tessera/compatibility/otobo-11.1.1-addons.json"])["overlaps"]
    for row in original + overlaps:
        target = home / row["path"]
        for path in [target, *target.parents]:
            if path == home:
                break
            if path.is_symlink():
                raise RuntimeError("Symlink runtime target needs review: " + row["path"])
        if row in original:
            allowed = {row["override_sha256"], row["merged_sha256"], row["target_native_sha256"]}
            allowed.update(x["file_sha256"] for x in row.get("reviewed_vendor_sources", []))
        else:
            allowed = set(row["allowed_sha256"])
        if target.exists() and U.digest(target) not in allowed:
            raise RuntimeError("Unknown runtime override needs review: " + row["path"])
        if row["path"].startswith("Custom/") and row in original:
            if U.digest(home / row["native_path"]) not in {
                    row["current_native_sha256"], row["target_native_sha256"]}:
                raise RuntimeError("Native compatibility basis changed: " + row["native_path"])


def stopped(home, state, info):
    if not (state / "otobo.crontab").is_file():
        raise RuntimeError("Original saved crontab is missing")
    for name in set(info["active_services"]) | {"apache2.service", "cron.service", "otobo-web.service", "otobo-daemon.service", "postfix.service"}:
        if subprocess.run(["systemctl", "is-active", "--quiet", name]).returncode == 0:
            raise RuntimeError("Keep application services stopped: " + name)
    cron = subprocess.run(["crontab", "-u", "otobo", "-l"], stdout=subprocess.PIPE)
    if cron.returncode not in (0, 1) or cron.stdout.strip():
        raise RuntimeError("otobo cron is not stopped")
    daemon = subprocess.run(["runuser", "-u", "otobo", "--", str(home / "bin/otobo.Daemon.pl"),
                             "status"], cwd=home, stdout=subprocess.DEVNULL)
    if daemon.returncode != 1:
        raise RuntimeError("Cannot verify stopped daemon")


def checkpoint_backup(home, directory, info, credentials):
    marker = directory / "backups.json"
    if marker.exists():
        hashes = json.loads(marker.read_text())
        if set(hashes) != {"before-addons-files.tar", "before-addons-db.sql.gz"}:
            raise RuntimeError("Incomplete continuation backup receipt")
        for name, sha in hashes.items():
            if U.digest(directory / name) != sha:
                raise RuntimeError("Continuation backup checksum mismatch")
        return
    if not re.fullmatch(r"[A-Za-z0-9_]+", info["db_name"]):
        raise RuntimeError("Unsupported database identifier")
    for path in (home / "var/article", home / "Kernel/Config.pm", home / "Custom"):
        if path.is_symlink():
            raise RuntimeError("External/symlink data needs a site-specific backup plan")
    tree_size = sum(p.stat().st_size for p in home.rglob("*") if p.is_file())
    db_size = int(U.run(["mariadb", "--defaults-extra-file=" + str(credentials), "-Nse",
        "SELECT COALESCE(SUM(data_length+index_length),0) FROM information_schema.tables "
        "WHERE table_schema='" + info["db_name"] + "'"], capture=True).stdout.strip())
    if shutil.disk_usage(directory).free < tree_size + 2 * db_size + 2 * 1024**3:
        raise RuntimeError("Insufficient space for continuation backups")
    archive = directory / "before-addons-files.tar.partial"
    U.run(["tar", "--acls", "--xattrs", "--numeric-owner", "-cpf",
           archive, "-C", home.parent, home.name])
    archive.replace(directory / "before-addons-files.tar")
    path = directory / "before-addons-db.sql.gz.partial"
    with path.open("wb") as stream:
        process = subprocess.Popen(U.database_dump_command(
            ["--defaults-extra-file=" + str(credentials)], info["db_name"]), stdout=subprocess.PIPE)
        with gzip.GzipFile(fileobj=stream, mode="wb") as output:
            shutil.copyfileobj(process.stdout, output)
        if process.wait():
            raise RuntimeError("Continuation database backup failed; no package upgrade started")
    with gzip.open(path, "rb") as stream:
        while stream.read(1024 * 1024):
            pass
    path.replace(directory / "before-addons-db.sql.gz")
    U.save(marker, {name: U.digest(directory / name)
                   for name in ("before-addons-files.tar", "before-addons-db.sql.gz")})


def execute(home, state, info, directory, receipt, packages):
    receipt_path = directory / "receipt.json"
    for entry, data in packages:
        name = entry["name"]
        current = inventory(home)
        if name in receipt["completed"]:
            if current[name]["version"] != entry["version"] or current[name]["sha256"] != entry["sha256"]:
                raise RuntimeError("Completed package drift: " + name)
            continue
        if current[name]["version"] != entry["from"]:
            raise RuntimeError("Unjournaled package change requires inspection: " + name)
        receipt["active"] = "upgrade:" + name
        U.save(receipt_path, receipt)
        U.with_package(home, data, "Admin::Package::Upgrade")
        observed = inventory(home)[name]
        if observed["version"] != entry["version"] or observed["sha256"] != entry["sha256"]:
            raise RuntimeError("Package upgrade verification failed: " + name)
        receipt["completed"].append(name)
        receipt["active"] = None
        U.save(receipt_path, receipt)
    # Reinstall compatible packages only, then restore TESSERA's combined overlaps.
    receipt["active"] = "reinstall-all"
    U.save(receipt_path, receipt)
    U.console(home, "Admin::Package::ReinstallAll")
    base_entry, base_data = packages[-1]
    receipt["active"] = "reinstall-base"
    U.save(receipt_path, receipt)
    U.with_package(home, base_data, "Admin::Package::Reinstall")
    payload = {f.get("Location"): base64.b64decode(f.text)
               for f in ET.fromstring(base_data).findall("./Filelist/File")}
    original = json.loads(payload["var/tessera/compatibility/otobo-11.1.1.json"])["entries"]
    overlaps = json.loads(payload["var/tessera/compatibility/otobo-11.1.1-addons.json"])["overlaps"]
    for row in original + overlaps:
        if U.digest(home / row["path"]) != row["merged_sha256"]:
            raise RuntimeError("Final merged target mismatch: " + row["path"])
    final = inventory(home)
    validate_plan(final, packages)
    if any(not row["compatible"] for row in final.values()):
        raise RuntimeError("An incompatible package remains")
    info["tessera_target"] = base_entry["version"]
    info["tessera_package_sha256"] = base_entry["sha256"]
    info["addon_continuation"] = str(directory)
    U.save(state / "state.json", info)
    receipt["active"] = "configuration"
    U.save(receipt_path, receipt)
    U.finish_configuration(home, state, info)
    receipt["active"] = None
    receipt["finished"] = True
    U.save(receipt_path, receipt)


def continue_upgrade(args):
    state, bundle = args.state.resolve(), args.bundle.resolve()
    info = json.loads((state / "state.json").read_text())
    if info["phase"] != "PACKAGES_UPGRADING":
        raise RuntimeError("This continuation requires the saved completed-core package stage")
    home = Path(info["home"])
    if U.version(home) != "11.1.1" or U.digest(home / "Kernel/Config.pm") != info["config_sha256"]:
        raise RuntimeError("Native core/configuration changed")
    credentials = args.db_defaults_file.resolve()
    if credentials.stat().st_uid != 0 or credentials.stat().st_mode & 0o077:
        raise RuntimeError("Root database client file must be private")
    plan, packages = load_bundle(bundle)
    if packages[-1][0]["name"] != "TESSERA-Base" or packages[-1][0]["version"] != "0.1.12":
        raise RuntimeError("Reviewed Base0.1.12 must be last")
    current = inventory(home)
    if current["TESSERA-Base"]["version"] == "0.1.10" and current["TESSERA-Base"]["sha256"] != OLD_BASE_SHA:
        raise RuntimeError("Installed Base0.1.10 differs from the verified artifact")
    validate_plan(current, packages)
    stopped(home, state, info)
    runtime_preflight(home, packages[-1][1])
    for _, data in packages:
        U.packet_preflight(home, data)
    hashes = json.loads((state / "backup-sha256.json").read_text())
    if set(hashes) != {"otobo-files.tar", "database.sql.gz"}:
        raise RuntimeError("Incomplete original backup receipt")
    for name, sha in hashes.items():
        if U.digest(state / name) != sha:
            raise RuntimeError("Original backup receipt differs")
    directory = state / "addon-continuation-0.1.12"
    directory.mkdir(mode=0o700, exist_ok=True)
    plan_hash = U.digest(bundle / "continuation-plan.json")
    receipt_path = directory / "receipt.json"
    if receipt_path.exists():
        receipt = json.loads(receipt_path.read_text())
        check_receipt(receipt, plan_hash)
    else:
        if any(current[p["name"]]["version"] != p["from"] for p, _ in packages):
            raise RuntimeError("Initial registry differs from the reviewed paused versions")
        receipt = {"plan_sha256": plan_hash, "completed": [], "active": None}
        U.save(directory / "inventory-before.json", current)
        U.save(receipt_path, receipt)
    checkpoint_backup(home, directory, info, credentials)
    execute(home, state, info, directory, receipt, packages)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", type=Path, required=True)
    parser.add_argument("--db-defaults-file", type=Path, required=True)
    parser.add_argument("--bundle", type=Path, default=Path("."))
    args = parser.parse_args()
    if sys.platform != "linux" or os.geteuid() != 0 or os.environ.get("KUBERNETES_SERVICE_HOST"):
        parser.error("Run as root on the native Ubuntu source host")
    import fcntl
    os.umask(0o077)
    with open("/run/lock/tessera-otobo-source-upgrade.lock", "a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        continue_upgrade(args)


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as error:
        print("STOP: " + str(error), file=sys.stderr)
        sys.exit(1)
