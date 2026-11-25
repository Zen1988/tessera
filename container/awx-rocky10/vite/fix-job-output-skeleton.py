"""Forward the placeholder row ref and update Enzyme's row selector."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
directory = parser.parse_args().source / "awx/ui/src/screens/Job/JobOutput"
plans = {
    "JobEventSkeleton.js": [
        (
            "function JobEventSkeleton({ counter, contentLength, style, measure }) {",
            "const JobEventSkeleton = React.forwardRef(function JobEventSkeleton(\n"
            "  { counter, contentLength, style, measure },\n  ref\n) {",
            1,
        ),
        ("<div style={style}>", "<div ref={ref} style={style}>", 1),
        ("\n}\n\nexport default JobEventSkeleton;", "\n});\n\nexport default JobEventSkeleton;", 1),
    ],
    "JobOutput.test.js": [
        ("import JobOutput from './JobOutput';", "import JobOutput from './JobOutput';\nimport JobEvent from './JobEvent';", 1),
        ("waitForElement(wrapper, 'JobEvent',", "waitForElement(wrapper, JobEvent,", 4),
    ],
}
event_source = (directory / "JobEvent.js").read_text(encoding="utf-8")
if "React.forwardRef(function JobEvent(" not in event_source:
    raise SystemExit("Apply fix-job-event-ref.py first")
updates = {}
for name, changes in plans.items():
    path = directory / name
    source = path.read_text(encoding="utf-8")
    if all(source.count(new) == count for _, new, count in changes):
        continue
    for old, new, count in changes:
        if source.count(old) != count:
            raise SystemExit(f"Unexpected source in {name}: {old!r}")
        source = source.replace(old, new)
    updates[path] = source
for path, source in updates.items():
    path.write_text(source, encoding="utf-8", newline="\n")
    print(f"Updated {path}")
