# Review of the Linux host staging script

UPDATE: owner confirms180 is already installed. For building directly from that
installation use the new `container/ubuntu2604/` complete image kit. It copies
the installed source without restoring package files or replacing core Redis.
The earlier stage-host-app.sh/host-stage-kit below are baseline-reconstruction
tools and are not required for this installed-host image workflow.

The supplied script stages application files; it does not build an image or
preserve an entrypoint by itself. Keep the existing TESSERA Dockerfile/entrypoint
and verify their web/daemon startup handling independently. Copying /opt/otobo
also does not capture Linux packages, external Perl libraries, native-library ABI,
runtime UID/GID or libraries outside that tree. Match those in the container base.

## Required corrections

1. Exclude `var/article` and `var/virtualfs`: native OTOBO can keep customer attachments there.
   Mount/restore those separately along with other persistent data; do not bake
   them into an image. Exclude generated reports/statistics and old package,
   backup, cache, log, spool, PID and session directories too.
   Local exported config selects ArticleStorageDB, and VirtualFS defaults to DB,
   but those facts do not prove the live host or historical objects use DB only.
   See `docs/kubernetes-migration-plan.md` for verification and persistence gates.
2. Exclude live generated `Kernel/Config/Files/ZZZ*.pm` and `User/` overrides.
   They may contain host configuration, integration passwords, ACLs and process
   runtime exports. Preserve the authoritative DB/config separately. Rebuild
   native SysConfig and deploy the required native ACL/process configuration in
   the controlled startup/upgrade procedure before readiness. Excluding these
   files without that procedure can break the application. Do not strip XML
   configuration definitions, book/program defaults or trusted source modules.
3. Exclude the host's `var/governancedb/runtime_overlay` copy, but restore the
   **package-owned overlay from the verified180 OPM**.110 package payloads live
   there. Blanket exclusion without restoration loses release content and can
   break later bootstrap/upgrade/reinstall. Restore all340 package files, not
   just the three Redis modules, to retain all179 enhancements.
4. Do not reuse an old app directory. `rsync --delete` normally leaves excluded
   destination files alone: a Config.pm, .env or key from an earlier run can
   survive even when now excluded. The revised script requires a fresh target
   and stages privately with no recursive deletion of existing user data.
5. Exclude nested credential stores (.ssh/.aws/.kube/.gnupg), .env variants,
   database dumps and common backup copies. Do not follow host symlinks into
   arbitrary locations. The revised script rejects external/looping links and
   symlinks on release write paths. Do not silently dereference them; arrange
   external dependencies explicitly in the container base.
6. Keep both Custom TESSERA modules and Custom/Kernel/System/Cache/Redis.pm.
   Restore the unmodified native core Redis.pm in the stage from the included
   approved reference. Do not change the live host's recovered patch automatically.
   Custom must precede core in both runtime launchers.
7. PEM/key exclusions are a conservative default, not a complete credential
   detector. Public CAs and signature-verification public keys may be required.
   Reintroduce only reviewed public trust material from a controlled source;
   keep private keys/certificates with private material in external mounts.

## Keep versus exclude

| Keep as release source | Exclude from host staging |
| --- | --- |
| Kernel, Custom, bin, required scripts and CPAN libraries | Host Config.pm and copies/backups |
| Kernel/Config/Files/XML definitions | Host-generated ZZZ*.pm and User overrides |
| Packaged var/governancedb defaults/policies/runtime_seed | Live overrides and credentials; restore approved overlay from OPM |
| Packaged static JS/CSS/templates/images | Generated css-cache/js-cache, customer uploads, reports |
| Approved public CA/signature trust anchors | Private keys, kubeconfig, cloud credentials, .env variants |

Do not blanket-exclude all YAML/JSON: TESSERA ships governance programs and
bootstrap defaults in these formats. Do not blanket-exclude all Custom or var:
both contain required release content. Conversely, filename exclusions cannot
prove arbitrary retained Perl/YAML/JSON/text files are credential-free. Review
host-added integrations, auth backends, mail/SMTP/API/LDAP settings, proxy config,
import/export data, local backups and public web uploads privately. Do not print
secret values into terminal history or logs. Existing published image layers
must be checked separately; deleting a credential in a later layer does not
remove it from an earlier layer.

## Revised staging tool

Use `scripts/container/stage-host-app.sh` with the adjacent `host-stage.exclude`.
It requires Linux bash, rsync, sudo, realpath and Python3 and an empty/new kit's
app destination. It pins the actual180 OPM hash and original core Redis reference,
restores and byte-verifies all340 payloads, rejects unsafe links, checks for
obvious private-key headers and produces a file-hash inventory outside app.
Header scanning is only an additional check, not secret-scanning certification.
Pinned hashes establish expected content, not independent publisher approval;
verify the release signature through the existing production release workflow.

The complete transfer kit is
`outputs/build-180/TESSERA-Base-0.0.180-host-stage-kit.zip`. Unpack it into a
dedicated directory on the existing host, then run as a regular user:

```sh
bash scripts/container/stage-host-app.sh \
  "$PWD" "$PWD/TESSERA-Base-0.0.180.opm" \
  "$PWD/reference/Kernel/System/Cache/Redis.pm"
```

The source remains `/opt/otobo`; only the private kit staging directory is
written. Existing `app` causes refusal, even if empty or a symlink. Failed stages
are retained privately for inspection, never copied into the final app folder.
The tool stops before Docker build, DB updates or deployment. The .app180.*
inventory identifies the snapshot; it contains file names/hashes, no file values.
Run during a stable code-deployment window or from a trusted filesystem snapshot;
the copy is not a transactional snapshot of a changing installation.

After private secret review, build with the actual existing Dockerfile. Prefer
explicit `COPY app/ ...` and explicit reviewed entrypoint files. Do not use
`COPY . ...`: it can include inventories, incomplete stages, archives and other
kit content. Preserve existing ENTRYPOINT/CMD and web/daemon arguments. Set
runtime code ownership/modes deliberately; the script's operator ownership is
for staging, not the container runtime identity.

Create writable/persistent directories with runtime-user ownership at container
startup or by mounts. Verify Config.pm is mounted, /run/tessera-secrets uses
read-only whole-directory mounts, all generated config is rebuilt/deployed, and
both Web/Daemon can read credentials. Test actual Redis AUTH/cache operations and
native dependencies before declaring the image ready.

## Validation scope

The existing180 OPM and application modules are unchanged by this review.
This Windows session does not run rsync against the Linux host or build an image.
Embedded Python restoration is fixture-tested using the real180 package;
five fixture tests pass and one Unix symlink case is skipped on this Windows host.
The available Windows MSYS Bash failed before parsing because of its runtime
environment; Bash/rsync execution is therefore not validated here.
Linux sudo/rsync/permissions, full source scanning, config regeneration and image
startup remain acceptance checks on the host. No live host/DB/Pod was changed.
