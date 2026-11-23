"""Assemble 0.1.2 from immutable 0.1.1, carrying only reviewed change-decision deltas."""
from pathlib import Path
import base64
import hashlib
import importlib.util
import json
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
BASE_HASH='52d3cc1fb398dbdcad77384fa05f39e4540842ea5965f7bf445db84ea77e2048'
DIRECT=[
 'Kernel/System/GovernanceDB/Bootstrap.pm',
 'Kernel/System/TESSERA/ChangeClassification.pm',
 'Kernel/System/TESSERA/ChangeClassificationInstaller.pm',
 'Kernel/System/TESSERA/ChangeClassificationScreen.pm',
 'Kernel/System/DynamicField/Driver/TESSERAChangeDropdown.pm',
 'Kernel/System/Ticket/Event/ChangeDecisionDefaults.pm',
 'Kernel/Modules/CustomerChangeAnnouncement.pm',
 'Kernel/Modules/CustomerChangeClassification.pm',
 'Kernel/Modules/AgentTicketChangeClassification.pm',
 'Kernel/Output/HTML/TicketMenu/ChangeClassification.pm',
 'Kernel/Output/HTML/Templates/Standard/CustomerChangeAnnouncement.tt',
 'Kernel/Output/HTML/Templates/Standard/ChangeClassificationEdit.tt',
 'Kernel/Config/Files/XML/TESSERAChangeClassification.xml',
 'var/httpd/htdocs/skins/Customer/default/css/TESSERA.ChangeAnnouncements.css',
 'var/httpd/htdocs/skins/Agent/default/css/TESSERA.ChangeAnnouncements.css',
 'var/governancedb/runtime_overlay/Kernel/Output/HTML/CustomerDashboard/TileTicketList.pm',
 'var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/Dashboard/TileTicketList.tt',
]

def main():
 base=ROOT/'Kernel/Package/TESSERA-Base-0.1.1.opm'
 assert hashlib.sha256(base.read_bytes()).hexdigest()==BASE_HASH
 old=ET.parse(base).getroot()
 baseline={f.get('Location'):base64.b64decode(f.text) for f in old.findall('./Filelist/File')}
 package_root=ROOT/'Kernel/Package/GovernanceDB'
 source=(package_root/'TESSERA-Base.sopm').read_text(encoding='utf-8')
 definition=ET.fromstring(source);assert definition.findtext('Version') in ('0.1.1','0.1.2')
 for tag in ['DatabaseInstall','DatabaseUpgrade','DatabaseUninstall','CodeInstall','CodeUpgrade','CodeReinstall']:
  assert [ET.tostring(n) for n in definition.findall(tag)]==[ET.tostring(n) for n in old.findall(tag)],tag
 source=source.replace('<Version>0.1.1</Version>','<Version>0.1.2</Version>',1)
 changed={name:(ROOT/name).read_bytes() for name in DIRECT}
 # The root calendar contains unrelated prior working changes; patch package authority.
 name='Kernel/System/TESSERA/TicketCalendar.pm'
 changed[name]=baseline[name].replace(b"['Change', 'Change::Major']",b"['Change']").replace(b'Change(?:::Major)?|Incident',b'Change|Incident')
 assert b'Change::Major' not in changed[name]
 changed['var/tessera/docs/change-classification.md']=(ROOT/'docs/change-classification.md').read_bytes()
 descriptor=json.loads(baseline['var/governancedb/container_release.json']);descriptor['version']='0.1.2'
 descriptor['upgrade_from']=list(dict.fromkeys(descriptor['upgrade_from']+['0.1.1']))
 changed['var/governancedb/container_release.json']=(json.dumps(descriptor,indent=2)+'\n').encode()
 adds=[f'        <File Location="{n}" Permission="660"/>' for n in changed if f'Location="{n}"' not in source]
 if adds:source=source.replace('    <Filelist>','    <Filelist>\n'+'\n'.join(adds),1)
 stage=ROOT/'.artifacts/base012'
 for name,data in (baseline|changed).items():
  target=stage/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
 for name,data in changed.items():
  target=package_root/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
 (ROOT/'var/governancedb/container_release.json').write_bytes(changed['var/governancedb/container_release.json'])
 (package_root/'TESSERA-Base.sopm').write_text(source,encoding='utf-8',newline='\n')
 staged=stage/'TESSERA-Base.sopm';staged.write_text(source,encoding='utf-8',newline='\n')
 spec=importlib.util.spec_from_file_location('opm_builder',ROOT/'scripts/build_opm.py');builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
 out=ROOT/'Kernel/Package/TESSERA-Base-0.1.2.opm';count=builder.build(staged,out)
 package=ET.parse(out).getroot();payload={f.get('Location'):base64.b64decode(f.text) for f in package.findall('./Filelist/File')}
 assert payload==baseline|changed and len(payload)==count
 for tag in ['DatabaseInstall','DatabaseUpgrade','DatabaseUninstall','CodeInstall','CodeUpgrade','CodeReinstall']:
  assert [ET.tostring(n) for n in package.findall(tag)]==[ET.tostring(n) for n in old.findall(tag)],tag
 assert 'Change::Major' not in json.loads(payload['var/governancedb/active_ticket_types.json'])['TicketTypes']
 for n in ['var/governancedb/runtime_overlay/Kernel/Output/HTML/CustomerDashboard/TileTicketList.pm','Kernel/System/TESSERA/TicketCalendar.pm']:
  assert b"Types     => ['Change::Major']" not in payload[n]
 digest=hashlib.sha256(out.read_bytes()).hexdigest();out.with_suffix('.opm.sha256').write_text(digest+'  '+out.name+'\n',encoding='ascii')
 report={'version':'0.1.2','baseline_sha256':BASE_HASH,'sha256':digest,'payloads':count,'new':sorted(payload.keys()-baseline.keys()),
  'changed':sorted(n for n in baseline if baseline[n]!=payload[n]),'unchanged':sum(baseline[n]==payload[n] for n in baseline),'hooks_preserved':True,'deployed':False}
 (ROOT/'outputs/base012-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,indent=2))

if __name__=='__main__':main()
