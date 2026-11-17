# Base183 missing documentation and examples

## Evidence (2026-10-27)

Owner verified the exported installed Base183 OPM against /opt/otobo:12 missing files,0 different files. All missing paths are beneath new top-level docs/ or examples/:8 AWX/NetXMS fixtures and4 Markdown guides. All other377 packaged payloads match. Preparation's full artifact verification correctly stopped; no hash check should be bypassed. A guarded missing-doc/example restoration was supplied as recovery, but execution/success has not been confirmed.

## Local source trace

The latest SOPM and generated Base183 OPM explicitly declare these paths. They are not declared under Custom. Kernel/System/Package.pm and the bundled otobo-11.1.0-beta2 reference agree on the relevant behavior:

- PackageParse's FilesNotAllowed list (around2543) does not reject docs/ or examples/.
- _FileInstall (around4099) concatenates Home and the exact declared Location. It creates each missing directory with mkdir, then writes the payload. There is no automatic relocation into Custom.
- Custom/Kernel has special module-refresh behavior for explicit overrides; it is not a general package installation root.
- _FileSystemCheck (around4402) checks existing bin/ and Kernel/ paths, not permission to create new top-level directories.
- Install (around596), reinstall (around723) and upgrade (around1052) call _FileInstall without checking each returned success. Directory/write errors can be logged while the outer flow continues; an installed registry version alone does not certify a complete filesystem deployment.
- otobo-11.1.0-beta2/bin/otobo.SetPermissions.pl, SetFilePermissions (around244), sets ordinary directories to02775, owned by the OTOBO user and web group. It explicitly gives the application root0755 (around280). Thus a web process which is not that root directory's owner cannot create new top-level directories even while writable existing package directories pass checks.
- TESSERA::ReleasePackage makes _FileInstall failures fatal for the controlled container upgrade path. It does not replace the ordinary native web Package Manager, so it does not fix source-host installations through that interface.

## Conclusion and limits

The strongest explanation is a source-host web installation running without write permission on /opt/otobo, combined with newly introduced top-level docs/ and examples/ paths and ignored native helper failures. This explains the exact missing-file grouping, but is not yet a confirmed host diagnosis: actual deployed Package.pm, installation method/user, ownership/ACLs and installation logs have not been obtained. Do not claim OTOBO forbids arbitrary package paths or requires all extensions under Custom. Do not chmod the application root writable by the web group as a workaround.

## Next corrective work

Obtain read-only host evidence: stat /opt/otobo and existing doc/, var/, Custom/, docs/, examples/; identify Apache worker user; inspect matching package-install mkdir/write errors. Preserve logs even if recovery creates the missing directories.

For the next release, place packaged documentation and integration fixtures under suitable existing writable package parents (verify doc/ and var/ on the actual source environment), updating all manifest locations and references. Alternatively omit genuinely non-runtime materials from OPM and distribute them solely in the public test kit, with explicit compatibility handling. Choose one supported layout after host confirmation; do not silently move the whole application into Custom or rewrite immutable183 artifacts. Preserve administrator files and explicitly consider old package-owned locations during upgrade.

Add packaging preflight for new top-level roots and tests for fresh install, upgrade and same-version reinstall under the actual non-root installation identity. Missing directories and denied writes must be detected before claiming successful installation. Keep container full payload verification and controlled upgrade checks. Manual repair is recovery only, not the long-term release procedure.

No application/package code, OPM, DB, permissions or deployed filesystem changed during this trace. Only project documentation was updated.
