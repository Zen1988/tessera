# Authoritative SysConfig reconciliation during container upgrades

OTOBO's native XML rebuild updates existing defaults by ID and creates only new
settings, using native locks and setting versions. A cached pre-upgrade setting
list can omit an existing row and incorrectly send it to the insert path. The
result is a unique-name conflict even though only one valid row exists.

The toolkit previously disabled caching for the final standalone configure step.
Package upgrades also invoke XML-to-DB rebuilds earlier in their own process.
The revised release-control now disables in-memory and backend cache reads/writes
in that short-lived upgrade process before any release service or package hook.
It uses the existing Cache::Configure interface. Normal web/daemon cache policy
and saved runtime settings are unchanged.

Each rebuild reads the current DB list and follows native update/versioning.
No blanket INSERT IGNORE, REPLACE, duplicate-error suppression, row deletion or
unconditional SQL upsert is introduced. Compatible administrator modified values
and original setting IDs remain under native handling. Native locking, validation and error handling remain in force; duplicate
errors are not ignored. A real cache round-trip preflight also runs
before the release claim or native package changes.

Regression tests execute the native OTOBO XML reconciliation and default-list
logic: stale nonempty cache reproduces the duplicate insert; upgrade cache policy
selects the existing row and updates its XML while retaining ID and compatible
administrator value; repeated rebuild is a no-op; fresh installs insert once;
real lock conflicts fail before writes.

This is prevention for new image builds. It does not reset or certify an existing
failed package hook. The current Kubernetes0.1.8->0.1.12 attempt remains UPGRADING
with a LabelPrint journal and needs a separate bounded recovery review. Its
current Redis/auth/master/cache probes all passed; that does not prove the
earlier transient cache operation errors or partial hooks are resolved.

Build the updated toolkit into a new automatically allocated image revision.
Retain the new immutable image ID and matching prepared upgrade bundle. Do not
reuse a previously published image tag or clear old journals to make it deploy.
