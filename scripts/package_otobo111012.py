"""Accept only exact reviewed vendor-restored DBExtensions sources in upgrade guards."""
import base64
import hashlib
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BASE_SHA = "06684fb843cddee02327167168264816f982309f67b83bcf0c6a1ffa4a5a7670"
VENDOR_SHA = "61224708c25479522518351aaecdf0d5295869291c2c01788b434de3e2bacd35"


def main():
    old = ROOT / "Kernel/Package/TESSERA-Base-0.1.11.opm"
    assert hashlib.sha256(old.read_bytes()).hexdigest() == BASE_SHA
    baseline = ET.parse(old).getroot()
    original = {f.get("Location"): base64.b64decode(f.text)
                for f in baseline.findall("./Filelist/File")}
    vendor_path = ROOT / ".artifacts/otobo111/addons/DynamicFieldDatabaseExtensions-11.1.2.opm"
    assert hashlib.sha256(vendor_path.read_bytes()).hexdigest() == VENDOR_SHA
    vendor = {f.get("Location"): base64.b64decode(f.text)
              for f in ET.parse(vendor_path).findall("./Filelist/File")}
    manifest_path = "var/tessera/compatibility/otobo-11.1.1.json"
    manifest = json.loads(original[manifest_path])
    manifest["version"] = "0.1.12"
    changed = []
    for row in manifest["entries"]:
        path = row["path"]
        if path not in vendor:
            continue
        sha = hashlib.sha256(vendor[path]).hexdigest()
        if sha in {row["override_sha256"], row["merged_sha256"], row["target_native_sha256"]}:
            continue
        assert path in {
            "Custom/Kernel/Modules/AdminDynamicFieldDB.pm",
            "Custom/Kernel/Output/HTML/Templates/Standard/AdminDynamicFieldDB.tt"}
        row["reviewed_vendor_sources"] = [{
            "name": "DynamicFieldDatabaseExtensions", "version": "11.1.2",
            "package_sha256": VENDOR_SHA, "file_sha256": sha,
            "url": "https://ftp.otobo.org/pub/otobo/packages/" + vendor_path.name}]
        changed.append(path)
    assert len(changed) == 2
    changes = {manifest_path: (json.dumps(manifest, indent=2) + "\n").encode()}
    bootstrap = original["Kernel/System/GovernanceDB/Bootstrap.pm"].decode()
    needle = "            && $Digest ne $Entry->{target_native_sha256};"
    assert bootstrap.count(needle) == 1
    bootstrap = bootstrap.replace(needle, needle[:-1] + """
            && !grep { $Digest eq $_->{file_sha256} } @{$Entry->{reviewed_vendor_sources} || []};""", 1)
    changes["Kernel/System/GovernanceDB/Bootstrap.pm"] = bootstrap.encode()
    descriptor = json.loads(original["var/governancedb/container_release.json"])
    descriptor["version"] = "0.1.12"
    descriptor["upgrade_from"] = list(dict.fromkeys(descriptor["upgrade_from"] + ["0.1.11"]))
    changes["var/governancedb/container_release.json"] = (json.dumps(descriptor, indent=2) + "\n").encode()
    for name in ("releases/0.1.12.md", "releases/README.md", "deployment/otobo111-addon-continuation.md"):
        changes["var/tessera/docs/" + name] = (ROOT / "docs" / name).read_bytes()
    package_root = ROOT / "Kernel/Package/GovernanceDB"
    definition = (package_root / "TESSERA-Base.sopm").read_text(encoding="utf-8")
    assert ET.fromstring(definition).findtext("Version") in ("0.1.11", "0.1.12")
    definition = definition.replace("<Version>0.1.11</Version>", "<Version>0.1.12</Version>", 1)
    name = "var/tessera/docs/releases/0.1.12.md"
    if 'Location="' + name + '"' not in definition:
        definition = definition.replace("    <Filelist>", '    <Filelist>\n        <File Location="' + name + '" Permission="660"/>', 1)
    stage = ROOT / ".artifacts/base0112"
    for name, data in (original | changes).items():
        target = stage / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    for name, data in changes.items():
        for target in (ROOT / name, package_root / name):
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    for target in (stage / "TESSERA-Base.sopm", package_root / "TESSERA-Base.sopm"):
        target.write_text(definition, encoding="utf-8", newline="\n")
    spec = importlib.util.spec_from_file_location("build", ROOT / "scripts/build_opm.py")
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    output = ROOT / "Kernel/Package/TESSERA-Base-0.1.12.opm"
    count = builder.build(stage / "TESSERA-Base.sopm", output)
    result = ET.parse(output).getroot()
    assert {f.get("Location"): base64.b64decode(f.text)
            for f in result.findall("./Filelist/File")} == original | changes
    for tag in ("CodeInstall", "CodeUpgrade", "CodeReinstall", "DatabaseInstall", "DatabaseUpgrade", "DatabaseUninstall"):
        assert [ET.tostring(x) for x in baseline.findall(tag)] == [ET.tostring(x) for x in result.findall(tag)]
    sha = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".opm.sha256").write_text(sha + "  " + output.name + "\n", newline="\n")
    report = json.loads((ROOT / "outputs/base0111-validation.json").read_text())
    report.update(version="0.1.12", sha256=sha, payloads=count,
                  baseline_sha256=BASE_SHA, reviewed_vendor_paths=changed, hooks_preserved=True)
    (ROOT / "outputs/base0112-validation.json").write_text(json.dumps(report, indent=2) + "\n", newline="\n")
    print(json.dumps({"version": "0.1.12", "sha256": sha, "payloads": count}))


if __name__ == "__main__":
    main()
