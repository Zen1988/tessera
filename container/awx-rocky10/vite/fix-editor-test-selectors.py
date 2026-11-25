"""Replace generated editor name selectors with the actual component type."""
import argparse
import os
import re
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
src = parser.parse_args().source.resolve() / "awx/ui/src"
detail = src / "components/CodeEditor/VariablesDetail.js"
editor = re.search(
    r"^import CodeEditor from '([^']+)';$", detail.read_text(encoding="utf-8"), re.MULTILINE
)
if not editor:
    raise SystemExit("Cannot identify the CodeEditor import in VariablesDetail.js")
old = ".find('VariablesDetail___StyledCodeEditor')"
for path in sorted(src.rglob("*.test.js")):
    text = path.read_text(encoding="utf-8")
    if old not in text:
        continue
    if re.search(r"\b(?:import|const|let|var|function)\s+CodeEditor\b", text):
        raise SystemExit(f"Existing CodeEditor binding or reference in {path}")
    specifier = editor[1]
    if specifier.startswith("."):
        specifier = Path(os.path.relpath(detail.parent / specifier, path.parent)).as_posix()
        if not specifier.startswith("."):
            specifier = "./" + specifier
    # Keep existing import ordering. Insert directly after the React import.
    text, count = re.subn(
        r"^(import React[^\n]* from 'react';)$",
        lambda match: f"{match[0]}\nimport CodeEditor from '{specifier}';",
        text,
        count=1,
        flags=re.MULTILINE,
    )
    if count != 1:
        raise SystemExit(f"React import not found in {path}")
    path.write_text(text.replace(old, ".find(CodeEditor)"), encoding="utf-8", newline="\n")
    print(path.relative_to(src))
