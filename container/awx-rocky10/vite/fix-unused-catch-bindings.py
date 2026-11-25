from pathlib import Path
import re
import sys


TARGETS = {
    "components/JobList/JobList.js": [(112, "e")],
    "components/LaunchPrompt/steps/PreviewStep.js": [(49, "e")],
    "components/LaunchPrompt/steps/useOtherPromptsStep.js": [(56, "error")],
    "screens/ActivityStream/ActivityStreamDescription.js": [(127, "err"), (554, "err")],
    "screens/Dashboard/shared/LineChart.js": [(25, "error")],
    "screens/Job/JobOutput/JobOutput.js": [(468, "e")],
    "screens/Metrics/LineChart.js": [(17, "error")],
    "screens/SubscriptionUsage/ChartComponents/UsageChart.js": [(25, "error")],
    "screens/TopologyView/MeshGraph.js": [(124, "error")],
    "util/yaml.js": [(36, "e")],
}


if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 fix-unused-catch-bindings.py <TAO checkout>")

source = Path(sys.argv[1]) / "awx/ui/src"
updates = {}
for name, bindings in TARGETS.items():
    path = source / name
    original = path.read_bytes()
    lines = original.splitlines(keepends=True)
    for number, binding in bindings:
        if number > len(lines):
            raise SystemExit(f"{path}:{number}: line missing")
        line = lines[number - 1]
        catch = rb"^([ \t]*(?:}[ \t]*)?catch)[ \t]*"
        pattern = catch + rb"\(" + binding.encode() + rb"\)[ \t]*(?=\{)"
        updated, count = re.subn(pattern, rb"\1 ", line)
        if count == 0 and not re.match(catch + rb"\{", line):
            raise SystemExit(f"{path}:{number}: expected catch binding {binding}")
        lines[number - 1] = updated
    updated = b"".join(lines)
    if updated != original:
        updates[path] = updated

for path, contents in updates.items():
    path.write_bytes(contents)
    print(f"Updated {path}")
