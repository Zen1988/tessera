#!/usr/bin/env bash
set -euo pipefail
image=${1:-localhost/tessera-awx-application-build:24.6.1-rocky10-vite-r3}
podman run --rm -i --pull=never --network=none --workdir /tmp "$image" \
    env DJANGO_SETTINGS_MODULE=awx.settings.defaults \
        SKIP_SECRET_KEY_CHECK=yes SKIP_PG_VERSION_CHECK=yes bash -e <<'SH'
mkdir -p /var/log/tower
awx-manage collectstatic --noinput --clear
python - <<'PY'
import re
from importlib.util import find_spec
from pathlib import Path

build = Path(find_spec("awx").origin).parent / "ui" / "build"
root = Path("/var/lib/awx/public/static")
html = (build / "index.html").read_text()
paths = re.findall(r"{% static '([^']+)' %}", html)
assert any(p.endswith(".js") for p in paths)
assert any(p.endswith(".css") for p in paths)
for name in paths + ["media/default.strings.json", "media/logo-login.svg", "media/logo-header.svg"]:
    collected = root / name
    assert collected.is_file(), f"Missing collected asset: {name}"
    assert collected.read_bytes() == (build / "static" / name).read_bytes(), name
print("Django collectstatic verified the installed Vite entry and brand assets")
PY
SH
