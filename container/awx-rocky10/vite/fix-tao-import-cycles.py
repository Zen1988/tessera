from pathlib import Path
import sys


if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 fix-tao-import-cycles.py <TAO checkout>")

source = Path(sys.argv[1]) / "awx/ui/src"
replacements = (
    (
        "components/Schedule/ScheduleList/ScheduleListItem.js",
        b"import { ScheduleToggle } from '..';",
        b"import ScheduleToggle from '../ScheduleToggle';",
    ),
    (
        "screens/Credential/shared/CredentialPlugins/"
        "CredentialPluginPrompt/CredentialPluginPrompt.js",
        b"import { CredentialPluginTestAlert } from '..';",
        b"import CredentialPluginTestAlert from '../CredentialPluginTestAlert';",
    ),
)

updates = {}
for name, old, new in replacements:
    path = source / name
    original = path.read_bytes()
    if original.count(old) + original.count(new) != 1:
        raise SystemExit(f"Unexpected import in {path}")
    if old in original:
        updates[path] = original.replace(old, new)

for path, contents in updates.items():
    path.write_bytes(contents)
    print(f"Updated {path}")
