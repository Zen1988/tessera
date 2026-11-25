"""Give WorkflowOutputNavigation a real parent ref in its Jest test."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path)
path = (
    parser.parse_args().source / "awx/ui/src/components/WorkflowOutputNavigation"
    / "WorkflowOutputNavigation.test.js"
)
source = path.read_text(encoding="utf-8")
changes = (
    (
        "    const ref = jest\n"
        "      .spyOn(React, 'useRef')\n"
        "      .mockReturnValueOnce({ current: 'div' });",
        "    const ref = React.createRef();",
    ),
    (
        "          <WorkflowOutputNavigation relatedJobs={jobs} parentRef={ref} />",
        "          <div ref={ref}>\n"
        "            <WorkflowOutputNavigation relatedJobs={jobs} parentRef={ref} />\n"
        "          </div>",
    ),
)
if all(source.count(new) == 1 for _, new in changes):
    print(f"Already updated {path}")
else:
    for old, new in changes:
        if source.count(old) != 1:
            raise SystemExit(f"Unexpected source in {path}: {old!r}")
        source = source.replace(old, new, 1)
    path.write_text(source, encoding="utf-8", newline="\n")
    print(f"Updated {path}")
