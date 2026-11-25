"""Update the locale API used by the AWX translation compiler."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("source", type=Path, help="AWX source checkout")
args = parser.parse_args()
path = args.source / "tools/scripts/compilemessages.py"
source = path.read_bytes()
old = b"encoding = locale.getdefaultlocale()[1] or 'ascii'"
new = b"encoding = locale.getpreferredencoding(False) or 'ascii'"
if source.count(old) == 1 and new not in source:
    updated = source.replace(old, new)
    compile(updated, str(path), "exec")
    path.write_bytes(updated)
    print(f"Updated {path}")
elif old not in source and source.count(new) == 1:
    print(f"Already updated {path}")
else:
    raise SystemExit(f"Unexpected locale code in {path}")
