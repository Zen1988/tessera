from pathlib import Path
import sys


if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 fix-schedule-ouia.py <TAO checkout>")

path = Path(sys.argv[1]) / (
    "awx/ui/src/components/Schedule/ScheduleDetail/ScheduleDetail.js"
)
original = path.read_bytes()
updated = original
for selector in (b"schedule-frequency-details", b"schedule-exception-details"):
    old = b'<div ouia-component-id="' + selector + b'">'
    new = b'<div data-ouia-component-id="' + selector + b'">'
    if original.count(old) + original.count(new) != 1:
        raise SystemExit(f"Unexpected ScheduleDetail markup for {selector.decode()}")
    updated = updated.replace(old, new)

if updated != original:
    path.write_bytes(updated)
    print(f"Updated {path}")
else:
    print(f"Already updated {path}")
