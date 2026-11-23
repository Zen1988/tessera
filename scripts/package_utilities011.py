"""Build Utilities 0.1.1 from immutable 0.1.0, excluding unrelated dirty sources."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BASE_HASH = 'ecedb348d955af2ee0461f367a7234ddd1fc3ceb2698ab1f3288c3ba1a10cb2d'
DIRECT = [
    'Kernel/System/TESSERA/NetworkSimulationAccess.pm',
    'Kernel/System/TESSERA/Utilities.pm',
    'Kernel/Modules/CustomerUtilities.pm', 'Kernel/Modules/AgentUtilities.pm',
    'Kernel/Output/HTML/Templates/Standard/CustomerUtilities.tt',
    'Kernel/Output/HTML/Templates/Standard/AgentUtilities.tt',
    'Kernel/Output/HTML/Templates/Standard/TESSERAUtilitiesShortcuts.tt',
    'Kernel/Config/Files/XML/TESSERAUtilities.xml',
    'var/httpd/htdocs/skins/Customer/default/css/TESSERA.Customer.Utilities.css',
    'var/httpd/htdocs/skins/Agent/default/css/TESSERA.Agent.Utilities.css',
    'var/httpd/htdocs/common/img/TESSERA/utilities.svg',
]
OVERLAYS = [
    'Kernel/Output/HTML/Templates/Standard/CustomerNavigationBar.tt',
    'Kernel/Output/HTML/CustomerDashboard/TileToolBox.pm',
]

def main():
    base_path = ROOT / 'Kernel/Package/TESSERA-Base-0.1.0.opm'
    assert hashlib.sha256(base_path.read_bytes()).hexdigest() == BASE_HASH
    old = ET.parse(base_path).getroot()
    baseline = {f.get('Location'): base64.b64decode(f.text) for f in old.findall('./Filelist/File')}
    package_root = ROOT / 'Kernel/Package/GovernanceDB'
    sopm_path = package_root / 'TESSERA-Base.sopm'
    source = sopm_path.read_text(encoding='utf-8')
    definition = ET.fromstring(source)
    assert definition.findtext('Version') in ('0.1.0','0.1.1')
    for tag in ['DatabaseInstall','DatabaseUpgrade','DatabaseUninstall','CodeInstall','CodeUpgrade','CodeReinstall']:
        assert [ET.tostring(n) for n in definition.findall(tag)] == [ET.tostring(n) for n in old.findall(tag)], tag
    source = source.replace('<Version>0.1.0</Version>','<Version>0.1.1</Version>',1)
    changed = {name: (ROOT/name).read_bytes() for name in DIRECT}
    for name in OVERLAYS:
        changed['var/governancedb/runtime_overlay/'+name] = (ROOT/name).read_bytes()
    changed['var/tessera/docs/utilities.md'] = (ROOT/'docs/utilities.md').read_bytes()
    descriptor = json.loads(baseline['var/governancedb/container_release.json'])
    descriptor['version']='0.1.1'
    descriptor['upgrade_from']=list(dict.fromkeys(descriptor['upgrade_from']+['0.1.0']))
    changed['var/governancedb/container_release.json']=(json.dumps(descriptor,indent=2)+'\n').encode()
    additions = [f'        <File Location="{name}" Permission="660"/>' for name in changed if f'Location="{name}"' not in source]
    if additions: source=source.replace('    <Filelist>','    <Filelist>\n'+'\n'.join(additions),1)
    stage = ROOT / '.artifacts/base011'
    for name,data in (baseline | changed).items():
        target=stage/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    for name,data in changed.items():
        target=package_root/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
    (ROOT/'var/governancedb/container_release.json').write_bytes(changed['var/governancedb/container_release.json'])
    sopm_path.write_text(source,encoding='utf-8',newline='\n')
    staged_sopm=stage/'TESSERA-Base.sopm';staged_sopm.write_text(source,encoding='utf-8',newline='\n')
    spec=importlib.util.spec_from_file_location('opm_builder',ROOT/'scripts/build_opm.py')
    builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
    output=ROOT/'Kernel/Package/TESSERA-Base-0.1.1.opm'
    count=builder.build(staged_sopm,output)
    package=ET.parse(output).getroot()
    payload={f.get('Location'):base64.b64decode(f.text) for f in package.findall('./Filelist/File')}
    assert len(payload)==count and baseline.keys() <= payload.keys()
    assert payload == baseline | changed
    assert all((stage/name).read_bytes()==data for name,data in payload.items())
    for tag in ['DatabaseInstall','DatabaseUpgrade','DatabaseUninstall','CodeInstall','CodeUpgrade','CodeReinstall']:
        assert [ET.tostring(n) for n in package.findall(tag)] == [ET.tostring(n) for n in old.findall(tag)], tag
    digest=hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.opm.sha256').write_text(digest+'  '+output.name+'\n',encoding='ascii')
    report={'version':'0.1.1','baseline_sha256':BASE_HASH,'sha256':digest,'payloads':count,
            'new':sorted(payload.keys()-baseline.keys()),
            'changed':sorted(n for n in baseline if baseline[n]!=payload[n]),
            'unchanged':sum(baseline[n]==payload[n] for n in baseline),
            'hooks_preserved':True,'deployed':False}
    (ROOT/'outputs/base011-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))

if __name__=='__main__': main()
