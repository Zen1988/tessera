#!/usr/bin/env python3
"""Collect only the 15 unresolved source overrides from the supplied host report."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tarfile

PATHS = (
    "Custom/Kernel/Modules/AdminCustomerUser.pm",
    "Custom/Kernel/Modules/AdminDynamicField.pm",
    "Custom/Kernel/Modules/AdminService.pm",
    "Custom/Kernel/Modules/AgentTicketZoom.pm",
    "Custom/Kernel/Output/HTML/Templates/Standard/AdminDynamicField.tt",
    "Custom/Kernel/Output/HTML/Templates/Standard/AdminService.tt",
    "Custom/Kernel/Output/HTML/Templates/Standard/AgentTicketZoom.tt",
    "Custom/Kernel/Output/HTML/TicketZoom/TicketInformation.pm",
    "Custom/Kernel/System/Console/Command/Admin/Service/Add.pm",
    "Custom/Kernel/System/CustomerUser.pm",
    "Custom/Kernel/System/CustomerUser/DB.pm",
    "Custom/Kernel/System/CustomerUser/LDAP.pm",
    "Custom/Kernel/System/DynamicField/Driver/BaseDatabase.pm",
    "Custom/Kernel/System/DynamicField/Driver/Lens.pm",
    "Custom/Kernel/System/Service.pm",
)


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--home", type=Path, default=Path("/opt/otobo"))
    p.add_argument("--report", type=Path,
                   default=Path("/opt/otobo-update/tessera-11.1.1/compatibility-review.json"))
    p.add_argument("--output", type=Path, default=Path("tessera-custom-review.tar.gz"))
    args = p.parse_args()
    home = args.home.resolve()
    report = {r["path"]: r for r in json.loads(args.report.read_text())}
    files = []
    manifest = []
    for relative in PATHS:
        path = home / relative
        if not path.is_file() or path.resolve() != path.absolute():
            raise SystemExit("Missing source or symlink requires review: " + relative)
        data = path.read_bytes()
        sha = hashlib.sha256(data).hexdigest()
        if relative not in report or sha != report[relative]["override_sha256"]:
            raise SystemExit("Source changed since preparation: " + relative)
        files.append((relative, path))
        manifest.append({"path": relative, "sha256": sha, "bytes": len(data)})
    # Create exclusively: never replace an existing archive or follow its symlink.
    os.umask(0o077)
    with args.output.open("xb") as stream:
        with tarfile.open(fileobj=stream, mode="w:gz") as archive:
            for relative, path in files:
                archive.add(path, arcname=relative, recursive=False)
            import io
            data = (json.dumps(manifest, indent=2) + "\n").encode()
            entry = tarfile.TarInfo("source-manifest.json")
            entry.size = len(data)
            entry.mode = 0o600
            archive.addfile(entry, io.BytesIO(data))
    print("Created " + str(args.output.resolve()))
    print("Files: 15 source overrides + manifest; no Config.pm, database or runtime data.")
    print("SHA256: " + hashlib.sha256(args.output.read_bytes()).hexdigest())


if __name__ == "__main__":
    main()
