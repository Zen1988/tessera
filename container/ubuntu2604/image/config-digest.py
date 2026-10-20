#!/usr/bin/env python3
import hashlib
from pathlib import Path
import sys
root=Path(sys.argv[1])
digest=hashlib.sha256()
for p in sorted(root.rglob('*')):
    if p.is_file():
        digest.update(p.relative_to(root).as_posix().encode()+b'\0'+p.read_bytes()+b'\0')
print(digest.hexdigest())
