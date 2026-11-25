"""Select the real editor component instead of its generated styled name."""
import argparse
import re
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
directory = parser.parse_args().source / "awx/ui/src/components/CodeEditor"
component = (directory / "VariablesDetail.js").read_text(encoding="utf-8")
editor = re.search(r"^import CodeEditor from '([^']+)';$", component, re.MULTILINE)
if not editor or not re.search(r"styled\(CodeEditor\)|<CodeEditor\b", component):
    raise SystemExit("Could not verify the editor import in VariablesDetail.js")
path = directory / "VariablesDetail.test.js"
source = path.read_text(encoding="utf-8")
old = ".find('VariablesDetail___StyledCodeEditor')"
if not source.count(old):
    raise SystemExit("No generated-name selectors found")
marker = "import VariablesDetail from './VariablesDetail';"
if source.count(marker) != 1 or re.search(r"^import CodeEditor\b", source, re.MULTILINE):
    raise SystemExit("Unexpected VariablesDetail test imports")
updated = source.replace(marker, f"{marker}\nimport CodeEditor from '{editor[1]}';")
path.write_text(updated.replace(old, ".find(CodeEditor)"), encoding="utf-8", newline="\n")
