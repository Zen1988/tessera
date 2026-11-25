#!/usr/bin/env bash
set -euo pipefail
image=${1:-localhost/tessera-awx-application-build:24.6.1-rocky10-vite-r3}
podman run --rm -i --pull=never --network=none --workdir /tmp "$image" python - <<'PY'
import json
import re
from pathlib import Path
from importlib.util import find_spec

import django
from django.conf import settings
from django.template import Context, Engine

build = Path(find_spec("awx").origin).parent / "ui" / "build"
static = build / "static"
settings.configure(STATIC_URL="/static/")
django.setup()
engine = Engine(libraries={"static": "django.templatetags.static"})
nonce = "tao-ui-check"
html = engine.from_string((build / "index.html").read_text()).render(
    Context({"csp_nonce": nonce})
)
assert f'nonce="{nonce}"' in html, "Django nonce did not render"
assert 'type="module"' in html, "Vite entry is absent"
assert 'id="app"' in html, "React mount point is absent"
assets = re.findall(r'(?:src|href)="/static/([^"]+)"', html)
assert any(path.endswith(".js") for path in assets), "No entry script"
assert any(path.endswith(".css") for path in assets), "No stylesheet"
for path in assets:
    assert (static / path).is_file(), f"Installed asset missing: {path}"
brand = json.loads((static / "media/default.strings.json").read_text())
assert brand["BRAND_NAME"] == "TESSERA Automation Orchestrator"
for name in ("logo-login.svg", "logo-header.svg", "favicon.ico"):
    assert (static / "media" / name).is_file(), f"Brand asset missing: {name}"
print(f"Installed AWX template and {len(assets)} linked assets verified")
PY
