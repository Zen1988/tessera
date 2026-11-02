# Version-independent toolkit and automatic image revisions

Application release versions and container rebuild revisions are separate.
This toolkit still targets Ubuntu26.04/system Perl/OTOBO11.1; it does not silently
change operating system or support unknown future incompatible OTOBO versions.
It copies the source currently installed on your host, without applying an OPM.

Preparation reads the installed TESSERA-Base version using a SELECT-only query
against the host's package_repository with exact name and install_status=installed.
It does not pick the largest/newest .opm or read historical release filenames.
Exactly one installed version is required. The installed Config.pm/DB credentials
must work on that source host; they are used locally, never copied into the kit.
Captured helper/config/DB diagnostics are not echoed. Failure stops preparation.
The installed version is checked again after copying to detect upgrades during
preparation. Keep source stable; same-version source edits during copying cannot
be detected by a version check alone.

Only package identity/version/provenance/time go into dependencies/release.json.
The build uses THAT prepared version, not whatever is later installed on the
host. If you install185 after staging180, rebuilding that old app/ remains180;
prepare the upgraded source in a fresh kit directory to build185. Existing app/
is still not automatically overwritten. An old prepared kit lacking release.json
must be freshly prepared; no guessing or manually fabricated release metadata.

From a fresh extracted toolkit directory outside /opt/otobo:

```sh
bash scripts/prepare.sh /opt/otobo && bash scripts/build.sh
```

For an installed package version0.0.185:

| Build attempt | Default image tag |
| --- | --- |
| First | tessera:0.0.185-ubuntu26.04 |
| Second | tessera:0.0.185-r1-ubuntu26.04 |
| Third | tessera:0.0.185-r2-ubuntu26.04 |
| First after preparing0.0.186 | tessera:0.0.186-ubuntu26.04 |

Run build.sh again on the SAME prepared source for a new revision; no prepare
needed. Failed/interrupted attempts AFTER revision reservation also consume a
revision: a tag is never reused automatically. Errors before reservation do not.
Existing local Docker image tags are considered, including earlier r1 tags, so
the next revision can be higher than the table example. Never overwrite old
tag/digest references in deployed workloads blindly.

History is saved outside the extracted kit at:

    $HOME/.local/state/tessera-container-kit/

A nonblocking Linux flock serializes allocation and the whole build per image
repository/package version. A second concurrent build reports busy. Keep this
directory across kit upgrades and Docker image cleanup; do not delete/reset it
to force revision reuse. TESSERA_BUILD_STATE_DIR can select a durable trusted
state directory; all builders sharing an image namespace must use coordinated
state/locking or a central release pipeline. Default home-local history plus
local Docker inspection does NOT discover tags pushed only by other hosts or
guarantee global registry uniqueness. Registry immutable tags are recommended.
No registry credentials are read or printed and no image is pushed automatically.

Set an UNTAGGED repository when needed:

```sh
TESSERA_IMAGE_REPOSITORY=registry.example/team/tessera bash scripts/build.sh
```

The old TESSERA_IMAGE=fixed:tag setting is rejected, since a fixed tag bypasses
automatic revisions. BASE_IMAGE/OTOBO_UID/OTOBO_GID options remain. Version and
revision are passed as build args and recorded in OCI/custom labels; Dockerfile
also verifies the version matches the prepared metadata. Version args appear
after dependency installation to avoid coupling APT/CPAN cache to app revisions.

Successful builds write immutable per-revision receipt JSON under artifacts/builds/
and a convenience artifacts/latest-build.json, plus image inspection/ID. Receipts
include package version, revision, image tag/ID and current source inventory hash.
The state ledger records successes/failures. Read the actual last successful tag:

```sh
IMAGE=$(python3 -c 'import json; print(json.load(open("artifacts/latest-build.json"))["tag"])')
printf '%s\n' "$IMAGE"
docker run --rm "$IMAGE" modules
docker save "$IMAGE" | gzip > artifacts/tessera-image.tar.gz
```

Existing generated-config fingerprints, source/credential exclusions, otobo:www-data
permissions, nonroot tests and HTTPS stay in place. Apache now defaults to
SSLVerifyClient none for Cilium's server-verified backend TLS; no Apache override
ConfigMap is needed. The separate backend CA trust ConfigMap is still required.
Version185 above is an example, not a claim that185 is installed or implemented.
The TESSERA application SOPM/OPM remains unchanged by toolkit release automation.
