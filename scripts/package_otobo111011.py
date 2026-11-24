"""Build Base0.1.11 from immutable0.1.10 with reviewed official add-on overlaps."""
import base64
import hashlib
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BASE_SHA = "234cc138db4d27b4d2f186e69e23049d13eeb89cf8dce95d30f143257e3da192"
OVERLAPS = (
    "Kernel/Modules/CustomerITSMConfigItem.pm",
    "Kernel/Modules/CustomerITSMConfigItemSearch.pm",
    "Kernel/System/Elasticsearch.pm",
    "Kernel/System/ITSMConfigItem/Permission.pm",
)
ADDONS = (
    ("ITSMConfigItemMultitenancy", "11.0.2", "11.1.1", "packages-itsm"),
    ("ITSMConfigItemLabelPrint", "11.0.4", "11.1.1", "packages-itsm"),
    ("ITSMChangeManagement", "11.0.3", "11.1.1", "packages-itsm"),
    ("ITSMIncidentProblemManagement", "11.0.2", "11.1.2", "packages-itsm"),
    ("TimeAccounting", "11.0.6", "11.1.3", "packages"),
)
PINS = {
    "ITSMConfigItemMultitenancy-11.0.2.opm": "13c185c78a7c39d25edeeba1f36d07b77a406e396c0b4641582f61763c809e6e",
    "ITSMConfigItemMultitenancy-11.1.1.opm": "28f6aca2a5fb311a72575582d0e831b9e5eb8e68479c1d28b1eee8db1f1f64fb",
    "ITSMConfigItemLabelPrint-11.1.1.opm": "8546fd85ffd059aadd48afaf8a2c5a0987017c6da6558685eb5ec6d17ae328f9",
    "ITSMChangeManagement-11.1.1.opm": "ee58cebdc28fc715b5603c88aaf7963a37934965410faf2aef209f9ea7a9dd18",
    "ITSMIncidentProblemManagement-11.1.2.opm": "429833562ac3ba257c04d8b7d1ebd30bc4a144c25831eca4b17c08097536fa27",
    "TimeAccounting-11.1.3.opm": "62c838cdeda9cf8976a7933a70f9784639f8c12fa9cea33973e5f0e404fecd4a",
}
MANIFEST = "var/tessera/compatibility/otobo-11.1.1-addons.json"
GUARD = r'''
sub _OTOBO111AddonPreflight {
    my ($Self) = @_;
    my $Home=$Kernel::OM->Get('Kernel::Config')->Get('Home');
    open my $FH,'<:raw',"$Home/var/tessera/compatibility/otobo-11.1.1-addons.json"
        or die 'Missing add-on compatibility manifest.';
    local $/;my $M=$Kernel::OM->Get('Kernel::System::JSON')->Decode(Data=><$FH>);close $FH;
    die 'Invalid add-on compatibility manifest.' if ref $M ne 'HASH' || ref $M->{overlaps} ne 'ARRAY';
    for my $E (@{$M->{overlaps}}) {
        open my $S,'<:raw',"$Home/$E->{source_location}" or die 'Missing reviewed merged add-on source.';
        my $Content=<$S>;close $S;
        die "Merged add-on source integrity mismatch: $E->{path}" if sha256_hex($Content) ne $E->{merged_sha256};
        my $Target="$Home/$E->{path}";
        die "Symlink add-on override requires review: $Target" if -l $Target;
        next if !-e $Target;
        open my $T,'<:raw',$Target or die 'Cannot inspect add-on override.';
        my $Current=<$T>;close $T;
        my %Allowed=map {$_=>1} @{$E->{allowed_sha256}};
        die "Unknown add-on override requires merge: $Target" if !$Allowed{sha256_hex($Current)};
    }
    return 1;
}
'''


def payload(path):
    root = ET.parse(path).getroot()
    return root, {f.get("Location"): base64.b64decode(f.text)
                  for f in root.findall("./Filelist/File")}


def main():
    old = ROOT / "Kernel/Package/TESSERA-Base-0.1.10.opm"
    assert hashlib.sha256(old.read_bytes()).hexdigest() == BASE_SHA
    baseline, original = payload(old)
    changes = {}
    addon_dir = ROOT / ".artifacts/otobo111/addons"
    for name, sha in PINS.items():
        assert hashlib.sha256((addon_dir / name).read_bytes()).hexdigest() == sha, name
    vendor_old = payload(addon_dir / "ITSMConfigItemMultitenancy-11.0.2.opm")[1]
    vendor_new = payload(addon_dir / "ITSMConfigItemMultitenancy-11.1.1.opm")[1]
    overlaps = []
    for relative in OVERLAPS:
        location = "var/governancedb/runtime_overlay/" + relative
        path = "Custom/" + relative
        source = ROOT / location
        merged = source.read_bytes().replace(b"\r\n", b"\n")
        if original[location].replace(b"\r\n", b"\n") == merged:
            merged = original[location]
        assert b"<<<<<<<" not in merged
        changes[location] = merged
        overlaps.append({
            "path": path, "source_location": location,
            "merged_sha256": hashlib.sha256(merged).hexdigest(),
            "allowed_sha256": list(dict.fromkeys(hashlib.sha256(d).hexdigest()
                for d in (original[location], vendor_old[path], vendor_new[path], merged))),
        })
    packages = []
    for name, previous, version, directory in ADDONS:
        path = addon_dir / f"{name}-{version}.opm"
        root, data = payload(path)
        assert root.findtext("Name") == name and root.findtext("Version") == version
        assert root.find("Framework").text == "11.1.x"
        packages.append({
            "name": name, "from": previous, "version": version, "file": path.name,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "url": f"https://ftp.otobo.org/pub/otobo/{directory}/{path.name}",
            "dependencies": [{"name": x.text, "minimum": x.get("Version")}
                             for x in root.findall("PackageRequired")],
        })
    changes[MANIFEST] = (json.dumps({
        "version": "0.1.11", "framework": "11.1.1",
        "baseline_package_sha256": BASE_SHA, "packages": packages, "overlaps": overlaps,
    }, indent=2) + "\n").encode()
    compatibility = json.loads(original["var/tessera/compatibility/otobo-11.1.1.json"])
    compatibility["version"] = "0.1.11"
    changes["var/tessera/compatibility/otobo-11.1.1.json"] = (json.dumps(compatibility, indent=2) + "\n").encode()
    bootstrap = original["Kernel/System/GovernanceDB/Bootstrap.pm"].decode()
    needle = "    $Self->_OTOBO111CompatibilityPreflight();"
    assert needle in bootstrap
    changes["Kernel/System/GovernanceDB/Bootstrap.pm"] = (
        bootstrap.replace(needle, needle + "\n    $Self->_OTOBO111AddonPreflight();", 1)
        + "\n" + GUARD).encode()
    descriptor = json.loads(original["var/governancedb/container_release.json"])
    descriptor["version"] = "0.1.11"
    descriptor["upgrade_from"] = list(dict.fromkeys(descriptor["upgrade_from"] + ["0.1.10"]))
    changes["var/governancedb/container_release.json"] = (json.dumps(descriptor, indent=2) + "\n").encode()
    for name in ("releases/0.1.11.md", "releases/README.md", "deployment/otobo111-addon-continuation.md"):
        changes["var/tessera/docs/" + name] = (ROOT / "docs" / name).read_bytes()
    package_root = ROOT / "Kernel/Package/GovernanceDB"
    definition = (package_root / "TESSERA-Base.sopm").read_text(encoding="utf-8")
    assert ET.fromstring(definition).findtext("Version") in ("0.1.10", "0.1.11")
    definition = definition.replace("<Version>0.1.10</Version>", "<Version>0.1.11</Version>", 1)
    if '<PackageRequired Version="11.1.1">ITSMConfigItemMultitenancy</PackageRequired>' not in definition:
        definition = definition.replace("    <Filelist>",
            '    <PackageRequired Version="11.1.1">ITSMConfigItemMultitenancy</PackageRequired>\n    <Filelist>', 1)
    additions = [f'        <File Location="{name}" Permission="660"/>'
                 for name in changes if f'Location="{name}"' not in definition]
    if additions:
        definition = definition.replace("    <Filelist>", "    <Filelist>\n" + "\n".join(additions), 1)
    stage = ROOT / ".artifacts/base0111"
    for name, data in (original | changes).items():
        p = stage / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)
    for name, data in changes.items():
        for target in (ROOT / name, package_root / name):
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    for target in (stage / "TESSERA-Base.sopm", package_root / "TESSERA-Base.sopm"):
        target.write_text(definition, encoding="utf-8", newline="\n")
    spec = importlib.util.spec_from_file_location("build", ROOT / "scripts/build_opm.py")
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    output = ROOT / "Kernel/Package/TESSERA-Base-0.1.11.opm"
    count = builder.build(stage / "TESSERA-Base.sopm", output)
    result, actual = payload(output)
    assert actual == original | changes
    for tag in ("DatabaseInstall", "DatabaseUpgrade", "DatabaseUninstall", "CodeInstall", "CodeUpgrade", "CodeReinstall"):
        assert [ET.tostring(x) for x in baseline.findall(tag)] == [ET.tostring(x) for x in result.findall(tag)]
    sha = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".opm.sha256").write_text(sha + "  " + output.name + "\n")
    report = {"version": "0.1.11", "sha256": sha, "payloads": count, "hooks_preserved": True,
              "baseline_sha256": BASE_SHA, "packages": packages, "overlaps": overlaps, "deployed": False}
    (ROOT / "outputs/base0111-validation.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"sha256": sha, "payloads": count, "addons": len(packages)}))


if __name__ == "__main__":
    main()
