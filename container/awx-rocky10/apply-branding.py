"""Apply TESSERA branding to the pinned AWX source before its UI build."""
import argparse
import json
from pathlib import Path
import shutil

parser = argparse.ArgumentParser()
parser.add_argument('--source', type=Path, required=True)
args = parser.parse_args()
root = args.source.resolve()
ui = root / 'awx' / 'ui'
assets = Path(__file__).resolve().parent / 'branding'
brand = 'TESSERA Automation Orchestrator'

def unique(name):
    matches = [p for p in ui.rglob(name)
               if not {'node_modules', 'build', '.git'}.intersection(p.parts)]
    if len(matches) != 1:
        raise SystemExit(f'Expected one source {name}; found {len(matches)}: {matches}')
    return matches[0]

if not ui.is_dir():
    raise SystemExit('Expected AWX24.6.1 source with awx/ui directory')
strings = unique('default.strings.json')
login = unique('logo-login.svg')
header = unique('logo-header.svg')
favicon = unique('favicon.ico')
data = json.loads(strings.read_text(encoding='utf-8'))
if data.get('BRAND_NAME') not in ('AWX', 'Ansible AWX', brand):
    raise SystemExit('Unexpected existing brand; review before replacement')
copies = [(assets / 'logo-login.svg', login),
          (assets / 'logo-header.svg', header),
          (assets / 'favicon.ico', favicon)]
for src, dst in copies:
    if not src.is_file():
        raise SystemExit(f'Missing asset: {src}')
# Complete preflight before writing. Preserve every unrelated string entry.
data['BRAND_NAME'] = brand
strings.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')
for src, dst in copies:
    shutil.copyfile(src, dst)
for path in (strings, login, header, favicon):
    print(path.relative_to(root))
print('Source branding applied. Rebuild AWX UI/application to include these assets.')
