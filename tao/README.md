# TESSERA TAO source preservation and rebuild

This directory is the extracted backup downloaded from the build host. To verify
it directly after cloning this repository, run `python tao/verify-backup.py` from
the repository root. Verification uses only the Python standard library and does
not extract or execute application code. See VERIFICATION.json for the review receipt.

The supplied upstream-commit.txt is empty because this host checkout did not expose
Git revision metadata. The recorded application image ID is
34b72f5ee214ff82942f9d3fea0a5cd544056e82a57b0f2688fd625c0732fbee;
source-inputs.sha256 verifies the archived source inputs independently.

This source snapshot includes the corrected ES translation loader and owner branding.
It is source preservation, not proof that a new image was deployed or browser-accepted.

Keep the outer archive and its adjacent .sha256 file in durable backed-up storage.
Also retain the final application/runtime image archives and their verified image IDs.
The source archive does not contain the Podman base images, downloaded RPMs, Python
wheels or complete npm cache. Rebuilding may require network access and those base
images; this is not a fully offline or bit-for-bit reproducible build bundle.

## Restore

Verify the outer archive using its adjacent .sha256 receipt. Extract into a new
directory, then run `sha256sum -c SHA256SUMS` there. Extract application-source.tar.gz
into a new source directory and run `sha256sum -c ../source-inputs.sha256` from that
source root (adjust the receipt path to its actual location). Extract build-tools.tar.gz
separately; it contains the build recipes and maintenance helpers.

The application archive excludes Git history, node_modules, UI build output, coverage
and Python bytecode. It retains the complete modified application source, requirements,
translation PO files, lockfiles, vendor archives and source branding.

## Future changes

Create a separate working copy. Preserve package.json, package-lock.json and every
file in awx/ui/vendor together. The five local packages include patched Lingui CLI,
PatternFly and three compatibility adapters. Do not replace the lockfile with an
unrestricted dependency refresh. Preserve the Python requirements and pinned VCS
revisions from the compatibility image recipe.

Use the existing compatible base image localhost/tessera-awx-compat:24.6.1-rocky10-r8,
or rebuild and independently validate that base before changing the application.
The application build recipe is build-tools/Containerfile.application-build; its
driver and asset checks are in build-tools/vite. Run npm ci, catalog compilation,
the production probe-tao-i18n.mjs, relevant tests/lint, then rebuild the application.
The production probe requires compileNamespace es and imports messages.mjs, not the
old CommonJS messages.js. Validate both compiled catalogs and the final browser UI.

Runtime assembly files are in build-tools/runtime. The build-runtime.sh driver
pins application i18n-r1, ID34b72f5ee214ff82942f9d3fea0a5cd544056e82a57b0f2688fd625c0732fbee.
For a new build, update
that pin to the newly verified application image and ID in a new versioned recipe;
do not accidentally package the old application. Use canonical runtime repository
localhost/tessera-tao and a fresh version tag for each rollout.

For the owner's local distribution model: podman save --format docker-archive,
then sudo ctr -n k8s.io images import on every eligible node. Update the AWX custom
resource awx/tessera-awx image and image_version, rather than generated Deployments.
Current policy is IfNotPresent. Verify rollout, login text/branding, authentication,
job launch/output and callbacks. Retain prior image and resource configuration.
