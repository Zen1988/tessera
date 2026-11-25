"""Remove manual plural-rule registration for the Lingui 4 candidate."""
import argparse
import re
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
ui = parser.parse_args().source / "awx/ui"
imports = re.compile(
    r"^import[ \t]+\{[^{}]*\}[ \t]+from[ \t]+['\"]make-plural/plurals['\"];[ \t]*\n",
    re.MULTILINE,
)
calls = re.compile(
    r"^[ \t]*i18n\.loadLocaleData\([^;]*\);[ \t]*\n",
    re.MULTILINE,
)
updates = {}
for directory in ("src", "testUtils"):
    for path in sorted((ui / directory).rglob("*.js")):
        source = path.read_text(encoding="utf-8")
        if "make-plural/plurals" not in source and ".loadLocaleData(" not in source:
            continue
        updated = calls.sub("", imports.sub("", source))
        if "make-plural/plurals" in updated or ".loadLocaleData(" in updated:
            raise SystemExit(f"Unrecognized plural registration in {path}")
        updates[path] = updated
for path, source in updates.items():
    path.write_text(source, encoding="utf-8", newline="\n")
    print(path)
