"""Build Base0.1.10 from immutable0.1.9 and reviewed stable migration sources."""
import base64
import hashlib
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BASE_SHA = "604d8b39b4bb027cdece41dbad91b2dc74181f27f72c0c2d126dcd2628b73359"
MIGRATION = ROOT / ".artifacts/stable-migration"
MANIFEST = "var/tessera/compatibility/otobo-11.1.1.json"

PREFLIGHT = r'''
sub _OTOBO111CompatibilityPreflight {
    my ($Self) = @_;
    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home');
    my $Path = "$Home/var/tessera/compatibility/otobo-11.1.1.json";
    open my $FH, '<:raw', $Path or die 'Missing stable compatibility manifest.';
    local $/;
    my $Manifest = $Kernel::OM->Get('Kernel::System::JSON')->Decode(Data => <$FH>);
    close $FH;
    die 'Invalid stable compatibility manifest.' if ref $Manifest ne 'HASH'
        || $Manifest->{target} ne '11.1.1' || ref $Manifest->{entries} ne 'ARRAY';
    for my $Entry (@{$Manifest->{entries}}) {
        next if $Entry->{path} !~ m{\ACustom/};
        my $Native = "$Home/$Entry->{native_path}";
        open my $Core, '<:raw', $Native or die "Missing native compatibility basis: $Native";
        my $NativeData = <$Core>; close $Core;
        die "Native basis changed; compatibility review required: $Native"
            if sha256_hex($NativeData) ne $Entry->{target_native_sha256}
            && sha256_hex($NativeData) ne $Entry->{current_native_sha256};
        my $Source = "$Home/$Entry->{source_location}";
        open my $Payload, '<:raw', $Source or die "Missing merged source: $Source";
        my $SourceData = <$Payload>; close $Payload;
        die "Merged source integrity mismatch: $Source"
            if sha256_hex($SourceData) ne $Entry->{merged_sha256};
        my $Target = "$Home/$Entry->{path}";
        next if !-e $Target;
        die "Symlink override requires review: $Target" if -l $Target;
        open my $Existing, '<:raw', $Target or die "Cannot inspect override: $Target";
        my $Data = <$Existing>; close $Existing;
        my $Digest = sha256_hex($Data);
        die "Unknown administrator override requires merge: $Target"
            if $Digest ne $Entry->{override_sha256}
            && $Digest ne $Entry->{merged_sha256}
            && $Digest ne $Entry->{target_native_sha256};
    }
    return 1;
}
'''


def main():
    baseline_path = ROOT / "Kernel/Package/TESSERA-Base-0.1.9.opm"
    assert hashlib.sha256(baseline_path.read_bytes()).hexdigest() == BASE_SHA
    baseline = ET.parse(baseline_path).getroot()
    payload = {f.get("Location"): base64.b64decode(f.text)
               for f in baseline.findall("./Filelist/File")}
    report_path = ROOT / ".artifacts/stable-review/host-report.json"
    if report_path.exists():
        rows = json.loads(report_path.read_text())
    else:
        # Reviewed canonical source/manifest are committed; transient merge work
        # directories are not needed to reproduce a package after handoff.
        rows = json.loads((ROOT / MANIFEST).read_text())["entries"]
    changes, entries = {}, []
    for row in rows:
        entry = dict(row)
        entry["reviewed"] = True
        path = row["path"]
        if path == "README.md":
            location = path
            merged = payload[path]
        else:
            location = ("var/governancedb/runtime_overlay/" + path[7:]
                        if path.startswith("Custom/") else path)
            source = MIGRATION / "merged" / path
            if not source.exists():
                source = ROOT / location
            merged = source.read_bytes().replace(b"\r\n", b"\n")
            assert b"<<<<<<<" not in merged
            changes[location] = merged
        entry["source_location"] = location
        entry["merged_sha256"] = hashlib.sha256(merged).hexdigest()
        entries.append(entry)
    # Use authoritative bootstrap, excluding the paused beta-warning experiment.
    bootstrap = payload["Kernel/System/GovernanceDB/Bootstrap.pm"].decode().replace("\r\n", "\n")
    needle = "sub InstallDefaults {\n    my ( $Self, %Param ) = @_;\n"
    assert needle in bootstrap
    bootstrap = bootstrap.replace(needle, needle + "\n    $Self->_OTOBO111CompatibilityPreflight();\n", 1)
    bootstrap += "\n" + PREFLIGHT
    changes["Kernel/System/GovernanceDB/Bootstrap.pm"] = bootstrap.encode()
    descriptor = json.loads(payload["var/governancedb/container_release.json"])
    descriptor["version"] = "0.1.10"
    descriptor["upgrade_from"] = list(dict.fromkeys(descriptor["upgrade_from"] + ["0.1.9"]))
    changes["var/governancedb/container_release.json"] = (json.dumps(descriptor, indent=2) + "\n").encode()
    changes[MANIFEST] = (json.dumps({
        "target": "11.1.1", "package": "TESSERA-Base", "version": "0.1.10",
        "native_commit": "18feea896ab92138b5e8c4cd785ab4e198eccb1b",
        "baseline_package_sha256": BASE_SHA,
        "entries": entries,
    }, indent=2) + "\n").encode()
    for name in ("releases/0.1.10.md", "releases/README.md", "deployment/otobo-11.1-source-upgrade.md"):
        source = ROOT / "docs" / name
        changes["var/tessera/docs/" + name] = source.read_bytes()
    package_root = ROOT / "Kernel/Package/GovernanceDB"
    definition = (package_root / "TESSERA-Base.sopm").read_text(encoding="utf-8")
    current = ET.fromstring(definition)
    assert current.findtext("Version") in ("0.1.9", "0.1.10")
    hooks = ("DatabaseInstall", "DatabaseUpgrade", "DatabaseUninstall",
             "CodeInstall", "CodeUpgrade", "CodeReinstall")
    for tag in hooks:
        assert [ET.tostring(n) for n in current.findall(tag)] == [ET.tostring(n) for n in baseline.findall(tag)]
    definition = definition.replace("<Version>0.1.9</Version>", "<Version>0.1.10</Version>", 1)
    definition = definition.replace("<Framework>11.1.x</Framework>",
                                    '<Framework Minimum="11.1.1">11.1.x</Framework>', 1)
    additions = [f'        <File Location="{name}" Permission="660"/>'
                 for name in changes if f'Location="{name}"' not in definition]
    if additions:
        definition = definition.replace("    <Filelist>", "    <Filelist>\n" + "\n".join(additions), 1)
    stage = ROOT / ".artifacts/base0110"
    for name, data in (payload | changes).items():
        path = stage / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    for name, data in changes.items():
        for destination in (package_root / name, ROOT / name):
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(data)
    (package_root / "TESSERA-Base.sopm").write_text(definition, encoding="utf-8", newline="\n")
    (stage / "TESSERA-Base.sopm").write_text(definition, encoding="utf-8", newline="\n")
    spec = importlib.util.spec_from_file_location("opm", ROOT / "scripts/build_opm.py")
    builder = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(builder)
    output = ROOT / "Kernel/Package/TESSERA-Base-0.1.10.opm"
    count = builder.build(stage / "TESSERA-Base.sopm", output)
    actual = ET.parse(output).getroot()
    assert {f.get("Location"): base64.b64decode(f.text)
            for f in actual.findall("./Filelist/File")} == payload | changes
    for tag in hooks:
        assert [ET.tostring(n) for n in actual.findall(tag)] == [ET.tostring(n) for n in baseline.findall(tag)]
    sha = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".opm.sha256").write_text(sha + "  " + output.name + "\n")
    report = {"version": "0.1.10", "sha256": sha, "payloads": count,
              "baseline_sha256": BASE_SHA, "review_entries": len(entries),
              "changed": sorted(k for k in payload if payload[k] != (payload | changes)[k]),
              "new": sorted(changes.keys() - payload.keys()), "hooks_preserved": True,
              "native_target": "11.1.1", "deployed": False}
    (ROOT / "outputs/base0110-validation.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({"sha256": sha, "payloads": count, "review_entries": len(entries)}))


if __name__ == "__main__":
    main()
