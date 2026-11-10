# Directory synchronization and customer self service — Base185

This release adds an administrator Directory self service page, an editable
TESSERA sync script, daemon scheduling, external authentication routing and
mandatory first-login responsibility/default setup for directory-owned users.
It does not configure a real directory, change the installed authentication
provider, deploy the package or import live users automatically.

## Configure the feature

1. Install the new immutable `TESSERA-Base-0.0.185.opm` through the normal native
   upgrade process. Keep the existing database. Fresh install, upgrade and
   reinstallation use existing SystemData and native object APIs; no new tables,
   Dynamic Fields or replacement governance classes are introduced. The native
   package dependency check requires Net::LDAP and CryptX GCM/PRNG modules.
   The container toolkit's cpanfile.extra now includes Net::LDAP0.68 and
   CryptX0.087; make those dependencies available on the installation/build host
   before installing the OPM, then rebuild the runtime image through the normal
   toolkit. Never bypass the native dependency checks with force installation.
2. Mount a protected encryption key as `/run/tessera-secrets/ad-sync-key` for
   **both web and daemon**. The existing TESSERA Secrets reader is reused. File
   content must be64 hexadecimal characters, optionally followed by one newline,
   representing32 random bytes. Generate it outside the image/repository using
   an approved secret-management tool. Store it in the deployment's protected
   Secret store; do not paste it into scripts, tickets, SysConfig or this page.
   Back up the key with appropriate custody: the encrypted bind password cannot
   be recovered without it. Key changes require re-entering the bind password.
3. Set `Customer::AuthModule` to
   `Kernel::System::CustomerAuth::TESSERAIdentity` in the target configuration and
   remove additional `Customer::AuthModule1` through10 fallback backends.
   Restart/reload workers through the normal deployment process. This is an
   explicit site authentication cutover: the package does not overwrite an
   existing administrator-owned LDAP/SSO login configuration. Import is refused
   until the sole router is configured. Existing local-user authentication uses
   the native DB backend when the configured provider mode is LDAP.
4. Open **Admin → Directory self service**. Enter AD hostname, read-only bind
   username/password, separate group and user search bases, LDAP group filter,
   verified CA PEM path, customer company ID, identity login attribute and
   provider mode. Credentials are saved as AES-256-GCM ciphertext in SystemData;
   the password is never rendered back. Blank password means preserve it.
   Only active administrators have backend/UI access. Supply your approved
   license/responsibility text; this release does not invent legal terms.
5. Select an active `SUPPORT::*` GovernanceRole assignment classification.
   Reserved `TESSERA::*` capabilities and resolver roles cannot be granted by
   this sync. Leave automatic profile creation off to review group mappings.
   External membership assignments are enabled by default in the first form.

## Discovery, profiles and assignments

Retrieve filtered groups to see their names, DNs and current mappings. AD group
objectGUID is the stable mapping key; names/DNs are not identities. For each
unmapped group choose an existing SupportProfile, or use **Create SupportProfile
and map**. An optional automatic-create setting creates profiles for all
unmapped groups matching the configured filter. New profiles use the exported
SupportProfile type `Support`. Existing same-name profiles require explicit
mapping; they are not silently adopted. Existing mappings survive repeat sync
and package upgrades. Source identity settings cannot change after importing
users; migrate a source through a reviewed future migration instead.

Each mapping chooses a SUPPORT role and either **External membership sync**
(default) or **Manual assignment management**. Mapped groups use the existing
exported fields on SupportAssignment:

- `ZTSMSupportAssignment-UserAccount` references **CustomerUser**, not a UserAccount CI.
- `ZTSMSupportAssignment-SupportProfile` references the selected SupportProfile.
- `ZTSMSupportAssignment-Role` references the reviewed classification.

All members of groups in the configured discovery scope are provisioned into
the native `CustomerUser` DB source, including unmapped groups. Membership is
deduplicated by stable directory identity/login. Existing directory-owned users
have first/last name, email and configured company updated. Other mapped contact
columns and administrator-set customer validity are preserved; stored password
hashes are never passed back through the password setter. This is not a full
domain-wide user import: users outside the filtered groups are outside this job.
Unmapped groups are reported for administrator selection and grant no assignment.
Manual-mode groups still import CustomerUsers but do not add/remove assignments.
Existing local customers cannot be taken over merely by matching their login;
conflicts require operator review and abort the transaction.

The importer stores provenance/ownership in SystemData. Repeated sync reuses
the same user and assignment identities. Existing manually created matching
assignments are never adopted as source-owned or overwritten. A complete,
unfiltered run can set a missing source-owned assignment Inactive. Returning
membership reactivates only that same source-owned record. Modified owned
records, duplicate assignments, missing fields or conflicting identities abort
rather than guessing. Roles/profiles must remain active. Manual-mode mapping
records preserve previously owned assignments for manual management.

No ticket governance snapshots, StateBook positions or BlueBook chapters are
modified. The central customer ConfigItem permission service now rejects
inactive SupportAssignments and inactive referenced governance objects; retiring
a membership therefore cannot leave CMDB access granted through that record.
Company IDs are no longer treated as aliases for CustomerUser identities in
entitlement checks or default-team selection. Existing incorrectly company-bound
assignment records are preserved but must be explicitly corrected to a real
CustomerUser before they can grant that account access.
Other authorization/resolver consumers must continue to apply their own active
scope checks; no universal external account deprovisioning claim is made.

## Editable TESSERA automation

The page stores an actual ScriptEngine program, not Python/Perl source:

```yaml
VERSION: 1
CALL WEB SERVICE:
  - SERVICE: Directory
    INVOKER: SyncMembership
    AS: SYNC
    WITH: {}
RETURN:
  VALUE: EXTERNAL.SYNC.Processed
```

Both manual and scheduled runs evaluate this script with an injected,
administrator-authorized internal provider. Exactly one approved sync call is
permitted; the existing language's read-only expressions/searches remain
available. `WITH` supports `GroupNameContains` (literal case-insensitive name
substring) and `AutoCreateProfiles` (cannot enable it unless the administrator
also enabled automatic creation). A filtered run can add memberships but never
retire missing memberships. The entire database sync remains uncommitted until
the script completes successfully; invalid RETURN results roll it back too.
No arbitrary endpoint, credential, target-field name, role resolver execution
or network privilege is exposed through script input.

**Run TESSERA sync script now** queues a native AsynchronousExecutor daemon task
with a single parallel slot. Refresh for the last completed report. Scheduler
and queued failures produce sanitized daemon errors, without LDAP raw messages
or credentials. The periodic cron check runs hourly at minute17; enabled source
configuration defaults to a24-hour interval. It uses the administrator who saved
the source and revalidates that actor's active admin permission on every run.
Disabled scheduling means no periodic import. No Codex automation is created.

## Authentication and first login

The router identifies imported customers from persisted sync provenance, not
from a requester-controlled preference. For LDAP mode it authenticates those
users against AD over verified StartTLS and never tries a local password after
external failure. Service-account credentials are used only for directory
lookup; the entered user's password is bound against the uniquely resolved user
DN. Imported local DB passwords are unshared random values, not AD passwords.
Account lookup excludes disabled AD accounts. No AD password is copied/stored.

For OpenIDConnect mode, the router delegates to native OTOBO OIDC and accepts
only a successfully verified identity matching an imported user. Configure the
existing OIDC issuer/client/redirect/claim settings and trust through normal
administration; login attribute must match the verified OIDC login claim.
OIDC mode uses external pre-authentication for the portal, with no DB fallback.
This release does not add SAML or implement a new SSO verifier. OIDC side effects,
logout/redirect behavior and identity mapping require real provider acceptance.

After external authentication, directory-owned users must accept the current
responsibility text. The hash/version and time are stored in customer preferences.
Changing the text requires renewed acceptance. Next they select the default
Application and an already assigned active SupportProfile (team). With no team
assignment they can save an application default; only manual assignment or
approved external sync can supply the team. No active applications means the
administrator must configure the catalog before onboarding can finish.
Existing independent CustomerAccept/password-policy notices remain in force;
the onboarding gate allows those native acceptance pages without redirect loops.

The preference writer uses the existing exported `ZUser-Application`,
`ZUser-SupportProfile`, `ZUser-Environment` and `ZUser-Location` fields. It has
no assignment-creation path. Empty/stale required defaults reopen onboarding;
selecting a preference never creates membership, company access, entitlement
or a GovernanceRole capability. Inactive assignments are excluded from team
choices. Existing local users are not forcibly enrolled by this package.

At TicketCreate, empty exported `ZTicket-Application` and `ZTicket-Location`
can receive the customer's valid defaults. Explicit request values and started
governance snapshots are preserved. The existing role-director/default script
path consumes `ZUser-SupportProfile`; this release does not invent a ticket
SupportProfile field or bypass SupportAssignment/entitlement validation.
Process ActivityDialog/ScriptSet definitions may still need their own field
defaults to show values *before* submission; a saved ticket default is not a
claim that every existing SR/CR form has been restyled or rebound automatically.

## Scope and acceptance

One AD source is configured in this first release. Each LDAP search requires
complete critical paging, rejects referrals/partial results/repeated cookies and
caps each search at10000 entries and51 pages. A full run is limited to1000
groups,10000 unique users and50000 membership edges. Bind/connect/search deadlines are
bounded. Nested membership is optional using AD matching-rule-in-chain; direct
memberOf excludes primaryGroupID-only membership. Do not infer primary-group or
cross-domain/forest membership. No LDAP writes, raw group member-range parsing,
automatic company creation, arbitrary customer-field mapping, local identity
adoption or general account deletion/deactivation are implemented.

All database changes use native APIs under a shared database advisory lock and
transaction. Supported runtime is the current TESSERA MariaDB backend.
Role/entitlement/data caches are cleared on rollback. Same-version reinstall
preserves source settings, encrypted password, group mappings, ownership and
customer consent/defaults. No records are seeded on installation; no destructive
uninstall data cleanup is added. Preserve database/key backups before upgrades.

Local tests cover encryption/tamper rejection, actual ScriptEngine calls,
identity/provisioning conflicts, repeated sync, managed retirement/reactivation,
manual preservation, incomplete directory/failed-script rollback, LDAP paging
and filter shapes, first-login sequence, no preference-to-assignment writes,
request-default snapshot preservation and HTML template rendering/escaping.
Live AD TLS/bind/paging/large groups, native MariaDB transaction/event/cache
behavior, daemon execution, OIDC login/logout, browser accessibility/responsiveness
and fresh/upgrade/reinstall package acceptance remain required. No live deployment
or working production sync is claimed by these offline tests.

Implementation references: [Net::LDAP TLS/search](https://metacpan.org/pod/Net::LDAP),
[CryptX GCM](https://metacpan.org/pod/Crypt::AuthEnc::GCM).
