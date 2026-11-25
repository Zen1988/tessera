# Pinned AWX source and branded frontend build

Prerequisite: owner's successful dependency image
localhost/tessera-awx-compat:24.6.1-rocky10-r8 (observed ID78a43bbb7208),
AWX source commit94e5795dfc37b95c576d61f3e3b4e936c021548c and source
branding successfully applied. Existing host requirements edits are retained.

Extract this kit to application-build-r1 beside the source directory. Run:

```bash
cd "$HOME/tessera-awx-build"
set -o pipefail
podman build --pull=never --jobs=1 \
  --cpu-period=100000 --cpu-quota=200000 \
  --memory=7g --memory-swap=7g \
  -f "$PWD/application-build-r1/Containerfile.application-build" \
  -t localhost/tessera-awx-application-build:24.6.1-rocky10-r1 \
  "$PWD/awx-24.6.1" 2>&1 | tee rocky10-application-build-r1.log
```

This builds the pinned legacy frontend (the UI used by the owner), packages
and installs AWX, verifies installed package identity away from the source tree,
checks branded strings in built output and reruns dependency/import checks.
It does not rerun the large dependency compilation. Node22 compatibility with
this older frontend/toolchain is not yet verified. Host logs establish results.
The source package build uses installed setuptools/scm without isolation.

Upstream make sdist would additionally clone ansible-ui main for ui_next.
This stage deliberately avoids that moving-source fetch. Experimental ui_next
packaging/preservation requires a separately pinned decision before final runtime.
No global dependency updates, deprecated OpenSSL provider fallback or disabled
TLS verification are configured automatically.

This is the application BUILD stage, not the final lean operator runtime image.
It contains source/compiler/tooling. Do not point the live AWX resource at it.
After host acceptance, assemble runtime paths/entrypoints/supervisor/rsyslog,
native-user permissions/static files and runtime packages; review Python3.12
startup/async compatibility, SAML fork replacement, scanners and job/callback
behavior before operator rollout. No cluster/data/credential mutations here.
