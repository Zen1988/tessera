"""Create a version-pinned offline authoring reference from OPM and native schemas."""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import subprocess
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', default='0.1.5')
    args = parser.parse_args()
    package = ROOT / 'Kernel/Package' / f'TESSERA-Base-{args.version}.opm'
    tree = ET.parse(package).getroot()
    assert tree.findtext('Version') == args.version
    payload = {n.get('Location'): base64.b64decode(n.text) for n in tree.findall('./Filelist/File')}
    stage = ROOT / '.artifacts' / f'offline-authoring-{args.version}'
    stage.mkdir(parents=True, exist_ok=True)
    origins = {}

    def put(name, data, origin):
        target = stage / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data if isinstance(data, bytes) else data.encode('utf-8'))
        origins[name] = origin

    for name, data in payload.items():
        if (name.startswith('Kernel/System/TESSERA/')
                or name.startswith('Kernel/System/ProcessManagement/TransitionAction/ZTSM')
                or name.startswith('Kernel/System/ProcessManagement/TransitionValidation/ZTSM')
                or name.startswith(('Kernel/GenericInterface/Invoker/AWX/', 'Kernel/GenericInterface/Invoker/TESSERA/'))
                or name == 'Kernel/GenericInterface/Transport/HTTP/TESSERAIntegration.pm'
                or name in {'Kernel/Config/Files/XML/TESSERAIntegration.xml', 'Kernel/Config/Files/XML/TESSERAAWX.xml', 'Kernel/Config/Files/XML/TESSERACustomerNetworkSimulation.xml'}
                or name == 'Kernel/System/GovernanceDB/Bootstrap.pm'
                or name.startswith(('var/governancedb/policy/', 'var/governancedb/script/'))
                or name in {'var/governancedb/default_classes.json', 'var/governancedb/default_configitem.json',
                            'var/governancedb/default_general_catalog.yml', 'var/governancedb/script_block_fields.json',
                            'var/governancedb/active_ticket_types.json', 'var/governancedb/container_release.json'}):
            put(name, data, 'OPM:' + name)
    # Native definitions only: never include Config.pm, customer objects, keys or live service exports.
    exports = {
        'DynamicFields.yml': 'Export/Export_DynamicFields_2026-10-19 03_59_47.yml',
        'ConfigItem.yml': 'Export/ConfigItem_2026-10-19-01.yml',
        'GovernanceObject.yml': 'Export/GovernanceObject_2026-10-19-02.yml',
        'GeneralCatalog.yml': 'Export/GeneralCatalog_2026-10-19.yml',
        'TicketTypes.yml': 'Export/Export_Types_2026-10-12 02_53_13.yml',
    }
    for target, source in exports.items():
        put('exports/' + target, (ROOT / source).read_bytes(), source)
    perl = ['perl', '-I', str(ROOT), '-I', str(ROOT / 'Kernel/cpan-lib')]
    converted = subprocess.run(perl + ['-MYAML::XS=LoadFile', '-MJSON::PP', '-e',
        'print JSON::PP->new->canonical->utf8->encode(LoadFile($ARGV[0]));',
        str(stage / 'exports/DynamicFields.yml')], capture_output=True, check=True)
    fields = json.loads(converted.stdout)['DynamicFields']
    index = {name: {key: field.get(key) for key in ['Name', 'Label', 'ObjectType', 'FieldType', 'Config', 'ValidID']}
             for name, field in fields.items()}
    put('exports/field-index.json', json.dumps(index, ensure_ascii=False, indent=2) + '\n', 'Derived native export index; not a live export')
    package_fields = {}
    for filename, kind in [('default_classes.json', 'GovernanceObject'), ('default_configitem.json', 'ITSMConfigItem')]:
        data = json.loads(payload['var/governancedb/' + filename])
        classes = data.get('Classes', []) if isinstance(data, dict) else data
        for cls in classes:
            if not isinstance(cls, dict):
                continue
            for name, field in cls.get('DynamicFields', {}).items():
                package_fields.setdefault(name, []).append({'ObjectType': kind, 'Class': cls.get('Name'),
                    'Definition': field, 'Origin': 'OPM:var/governancedb/' + filename})
    put('exports/package-field-index.json', json.dumps(package_fields, ensure_ascii=False, indent=2) + '\n',
        'Authoritative package class defaults; not actual live administrator definitions')
    put('exports/managed-fields.json', json.dumps({
        'ChangeType': {'ObjectType': 'Ticket', 'FieldType': 'Dropdown', 'Default': 'Normal',
                       'Values': ['Normal', 'Standard', 'Emergency'], 'Source': 'Kernel/System/TESSERA/ChangeClassificationInstaller.pm'},
        'ChangeClassification': {'ObjectType': 'Ticket', 'FieldType': 'Dropdown', 'Default': 'Not-Assessed',
                       'Values': ['Normal', 'Not-Assessed', 'Major'], 'Source': 'Kernel/System/TESSERA/ChangeClassificationInstaller.pm'},
        'Navis': {'ObjectType': 'GovernanceObject', 'FieldType': 'Text', 'Class': 'Application', 'Purpose': 'Optional stable topology name; not a UUID', 'Source': 'Kernel/System/TESSERA/ApplicationNavisInstaller.pm'},
        'FAQApplication': {'ObjectType': 'FAQ', 'FieldType': 'GovernanceObject', 'ReferenceClass': 'Application',
                       'Multiple': True, 'EmptyMeans': 'All portal users', 'Source': 'Kernel/System/GovernanceDB/Bootstrap.pm'},
    }, indent=2) + '\n', 'Managed runtime additions; verify included installer source and deployed schema before use')
    xml = ET.Element('tessera-field-reference', {'native-import': 'false', 'source': 'DynamicFields.yml'})
    for name, field in sorted(index.items()):
        node = ET.SubElement(xml, 'field', {'name': name, 'object': str(field.get('ObjectType', '')),
                                          'type': str(field.get('FieldType', ''))})
        ET.SubElement(node, 'configuration-json').text = json.dumps(field.get('Config'), ensure_ascii=False)
    put('exports/dynamicfields-reference.xml', ET.tostring(xml, encoding='utf-8', xml_declaration=True),
        'Derived navigation reference, NOT native import XML')
    for directory in ['scriptengine', 'architecture', 'integrations', 'operations', 'development', 'guides', 'releases', 'reference/navis']:
        for source in (ROOT / 'docs' / directory).glob('*'):
            if source.suffix in ('.md', '.json') and source.is_file():
                put('docs/' + directory + '/' + source.name, source.read_bytes(), 'Repository documentation')
    for name in ['README.md', 'catalogue.md', 'ordered-script-blocks.md', 'policy-script-security-foundation.md',
                 'async-execution-contract.md', 'change-classification.md', 'utilities.md', 'customer-network-simulation.md',
                 'integration-onboarding.md', 'awx-managed-onboarding.md', 'netxms-integration.md',
                 'awx-integration.md', 'container-version-upgrade.md']:
        if (ROOT / 'docs' / name).exists():
            put('docs/' + name, (ROOT / 'docs' / name).read_bytes(), 'Repository documentation')
    put('AGENTS.md', f'''# TESSERA offline authoring contract — Base{args.version}

Work offline. Read README.md, MANIFEST.json, docs/scriptengine/workflow.md and language.md first.
Use exact included OPM source/defaults, then native schema exports, then prose. Dated exports are not live site truth.
Never invent field/class/catalogue/service names or IDs. Preserve FieldAsssignment and Contract-SupportProfie spellings.
Identify caller, programming object, runtime target, storage Set and typed return before writing source.
Unknown/ambiguous/overflow/unauthorized outcomes fail closed. No SQL/shell/arbitrary HTTP or credential literals.
TESSERA::* capabilities never execute resolver programs. A script parser is not authorization or publication approval.
Use source and tools/validate.pl for real parsing/Set assembly; use tools/verify.py for file integrity.
Deliver source, ordered blocks, exact dependencies, negative tests and runtime review/installation notes.
Verify managed additions such as Application Navis against installer source; do not claim absent adapters or automation schedulers exist. Check documented limitations.
No internet, package install, live connection or mutation is required to read and author with this pack.
''', 'Generated authoring entry point')
    put('README.md', f'''# TESSERA offline ScriptEngine pack — Base{args.version}

Start at AGENTS.md, then docs/scriptengine/README.md. This archive supplies exact interpreter source,
package recipes/defaults and dated native model exports. The source OPM SHA256 is in MANIFEST.json.

Run `python3 tools/verify.py` to verify all included payloads. Optional native parser/Set check:
`perl tools/validate.pl selection var/governancedb/script/governance_role_requester.yml ScriptEngine`.
Perl/YAML::XS must already be installed; no dependencies are fetched. Full runtime evaluation needs the
matching Tessera environment. `yaml` validation mode checks safe loading, not evaluation semantics.

exports/field-index.json and dynamicfields-reference.xml are derived references, not native import formats.
Package bootstrap/defaults/managed installers take precedence over dated schemas. No live site/customer/
credential data is included. Application Navis label persistence is included; complete discovery automation remains pending
where documented. Do not treat this pack as a deployment bundle or execution grant.
''', 'Generated pack overview')
    put('tools/verify.py', '''from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[1]
doc=json.loads((root/'MANIFEST.json').read_text(encoding='utf-8'))
for name,row in doc['files'].items():
 p=(root/name).resolve();assert p.is_relative_to(root),name
 assert p.is_file() and hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'],name
print('Verified',len(doc['files']),'files for Base'+doc['version'])
''', 'Generated integrity verifier')
    put('tools/validate.pl', r'''use strict;use warnings;
use FindBin;use lib "$FindBin::Bin/..";
use Encode qw(decode FB_CROAK);use JSON::PP ();
use Kernel::System::TESSERA::ScriptEngine;
use Kernel::System::TESSERA::ScriptBlocks qw(SplitSource Assemble);
my ($Kind,$File,$Field)=@ARGV;$Field ||= 'ScriptEngine';
die "Usage: perl tools/validate.pl selection|yaml source.yml [SetName]\n" if !$File || ($Kind ne 'selection' && $Kind ne 'yaml');
open my $F,'<:raw',$File or die "Cannot open source\n";local $/;my $Source=decode('UTF-8',<$F>,FB_CROAK);close $F;
my $E=Kernel::System::TESSERA::ScriptEngine->new();my $Doc=$E->ScriptSourceLoad(Source=>$Source);
if ($Kind eq 'selection') {my $R=$E->ScriptParse(Script=>$Doc);die "$R->{Error}\n" if !$R->{Success};}
my $Rows=SplitSource(Field=>$Field,Source=>$Source);
die "Set assembly changed source\n" if Assemble(Field=>$Field,Rows=>$Rows) ne $Source;
print JSON::PP->new->canonical->encode({Success=>1,Validation=>$Kind eq 'selection'?'ScriptParse plus Set round-trip':'Safe YAML loading plus Set round-trip only',Blocks=>scalar @$Rows,SourceCharacters=>length($Source),RuntimeEvaluation=>0}),"\n";
''', 'Generated actual-engine validator (no live evaluation)')
    files = {name: {'sha256': hashlib.sha256((stage / name).read_bytes()).hexdigest(), 'origin': origin}
             for name, origin in sorted(origins.items())}
    manifest = {'version': args.version, 'package': package.name,
                'package_sha256': hashlib.sha256(package.read_bytes()).hexdigest(),
                'navis_contract': json.loads((ROOT / 'docs/reference/navis/PROVENANCE.json').read_text()),
                'export_scope': 'Dated schema definitions plus authoritative packaged defaults/installer source; no live values',
                'files': files}
    (stage / 'MANIFEST.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    subprocess.run(['python', str(stage / 'tools/verify.py')], check=True)
    subprocess.run(perl + [str(stage / 'tools/validate.pl'), 'selection',
                         str(stage / 'var/governancedb/script/governance_role_requester.yml')], check=True)
    output = ROOT / 'outputs' / f'TESSERA-{args.version}-ScriptEngine-Offline-Pack.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in sorted([*files, 'MANIFEST.json']):
            archive.writestr(name, (stage / name).read_bytes())
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.zip.sha256').write_text(digest + '  ' + output.name + '\n', encoding='ascii')
    print(json.dumps({'archive': str(output), 'sha256': digest, 'files': len(files) + 1,
                      'native_fields': len(fields)}))


if __name__ == '__main__':
    main()
