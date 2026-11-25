# AWX Rocky Linux 10 port: dependency compatibility gate

Owner-selected target: Rocky Linux10. Application baseline: AWX24.6.1 commit
94e5795dfc37b95c576d61f3e3b4e936c021548c. This Containerfile is a diagnostic
dependency build, not a production image, deployment manifest or remediation claim.
No database, credentials or Kubernetes configuration are required by this build.

Four VCS dependencies are pinned to revisions read from the owner's running AWX.
Original PyPI pins remain deliberately unchanged to identify Python3.12/EL10
compatibility failures. Bootstrap versions are explicit compatibility choices,
not a declaration of security acceptance. Do not promote this image to AWX.

On the Linux host, copy Containerfile.compat beside awx-24.6.1, then run as zen:

```bash
cd "$HOME/tessera-awx-build"
test "$(git -C awx-24.6.1 rev-parse HEAD)" = 94e5795dfc37b95c576d61f3e3b4e936c021548c || exit 1
set -o pipefail
podman build --pull=always --jobs=1 --cpu-period=100000 --cpu-quota=200000 \
  --memory=6g --memory-swap=6g \
  -f Containerfile.compat -t localhost/tessera-awx-compat:24.6.1-rocky10-r1 \
  awx-24.6.1 2>&1 | tee rocky10-compat-r1.log
```

Retain the complete log and base-image digest from the build. A failed build is
diagnostic evidence: preserve the first failure rather than removing all pins.
Current Rocky repositories were probed by the owner: Python3.12 available,
Python3.11 absent from queried repositories; libpq-devel and the remaining build
packages have not yet been install-verified. Rootless storage is on /home/zen.

Remaining after this gate: targeted compatibility/security patches, complete AWX
application/frontend build and TESSERA branding, independent EE build, native
imports/startup/scheduling/job/callback tests, scanner review, release inventory,
registry/node distribution and controlled AWX-operator rollout with rollback and
database recovery planning. No native AWX deployment or secret is changed here.

Revision2: owner build installed EL10 development RPMs successfully, then pip24.3.1 failed importing bundled truststore on Python3.12.16 (wrap_bio without server_hostname). Update bootstrap pip to26.3; TLS remains verified. This correction awaits host build verification; no AWX dependency compatibility success yet.
