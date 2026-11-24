"""Create the offline continuation bundle from reviewed immutable OPMs."""
import base64
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    report = json.loads((ROOT / "outputs/base0111-validation.json").read_text())
    files = {}
    entries = report["packages"].copy()
    for entry in entries:
        data = (ROOT / ".artifacts/otobo111/addons" / entry["file"]).read_bytes()
        assert hashlib.sha256(data).hexdigest() == entry["sha256"]
        files[entry["file"]] = data
    path = ROOT / "Kernel/Package/TESSERA-Base-0.1.11.opm"
    data = path.read_bytes()
    assert hashlib.sha256(data).hexdigest() == report["sha256"]
    root = ET.fromstring(data)
    entries.append({
        "name": "TESSERA-Base", "from": "0.1.10", "version": "0.1.11",
        "file": path.name, "sha256": report["sha256"],
        "dependencies": [{"name": x.text, "minimum": x.get("Version")}
                         for x in root.findall("PackageRequired")]})
    files[path.name] = data
    files["continuation-plan.json"] = (json.dumps({
        "framework": "11.1.1", "state_phase": "PACKAGES_UPGRADING", "packages": entries,
    }, indent=2) + "\n").encode()
    for name in ("continue-otobo111-addons.py", "upgrade-otobo111-source.py"):
        files[name] = (ROOT / "scripts" / name).read_bytes().replace(b"\r\n", b"\n")
    files["README.md"] = (ROOT / "docs/deployment/otobo111-addon-continuation.md").read_bytes()
    files["SHA256SUMS"] = "".join(
        hashlib.sha256(data).hexdigest() + "  " + name + "\n"
        for name, data in sorted(files.items())).encode()
    output = ROOT / "outputs/TESSERA-0.1.11-OTOBO-11.1.1-Addon-Continuation.zip"
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, (2026, 11, 24, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    sha = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".zip.sha256").write_text(sha + "  " + output.name + "\n")
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert all(archive.read(n) == d for n, d in files.items())
    print(json.dumps({"artifact": str(output), "sha256": sha, "files": len(files)}))


if __name__ == "__main__":
    main()
