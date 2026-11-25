"""Forward the react-virtualized measurement ref to the AWX job event row."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
args = parser.parse_args()
path = args.source / "awx/ui/src/screens/Job/JobOutput/JobEvent.js"
source = path.read_text(encoding="utf-8")
edits = (
    ("function JobEvent({", "const JobEvent = React.forwardRef(function JobEvent({"),
    ("  jobStatus,\n}) {", "  jobStatus,\n}, ref) {"),
    ("<div style={style} type={event.type}>", "<div ref={ref} style={style} type={event.type}>"),
    ("\n}\n\nexport default JobEvent;", "\n});\n\nexport default JobEvent;"),
)
if all(source.count(new) == 1 for _, new in edits):
    print(f"Already updated {path}")
else:
    for old, new in edits:
        if source.count(old) != 1:
            raise SystemExit(f"Unexpected JobEvent source: {old!r}")
        source = source.replace(old, new, 1)
    path.write_text(source, encoding="utf-8", newline="\n")
    print(f"Updated {path}")
