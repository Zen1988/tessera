# Local customer-master and linked-agent accounts (Base192)

The customer is the primary person/profile/password record. An explicitly linked native agent record provides the separate technical ID, groups, roles and ticket execution identity OTOBO needs. This does not merge customer and agent permission models, sessions, preferences or MFA enrollment. It does not infer that matching usernames are the same person.

This release implements the owner's local-user-first test flow. AD/LDAP/OIDC-backed identities are deliberately rejected by the local linker, including externally imported accounts stored in customer_user. Shared AD authentication and explicit directory-driven secondary agent provisioning remain a separate implementation/acceptance phase; no AD behavior is claimed by local tests.

## Install and opt in

Install Base192 normally; it includes the Base190 Elasticsearch ownership fix and Base191 provider endpoints. Fresh/upgrade/reinstall add missing tessera_local_identity and tessera_local_identity_audit tables without changing existing users, passwords, grants or authentication configuration. The feature defaults disabled. Existing third-party Custom/Kernel/System/User.pm customizations are not overwritten: the install stops for an explicit compatibility merge. The installer also checks the native User.pm against the reviewed 11.1 basis and stops on an unreviewed framework revision. Native User.pm is left untouched; the password-routing customization deploys through the existing runtime overlay.

First verify an independent emergency local administrator login and keep that account unlinked. Root (agent ID1) and the currently acting administrator cannot be linked. Use a disposable local customer for the first test. The local test flow supports the primary, writable native customer_user DB source, default users agent table and native customer password columns. Foreign DB/read-only/nonlocal/auth-fallback configurations are rejected.

After installation, explicitly configure the sole agent authentication router in Kernel/Config.pm (example packaged under var/tessera/examples/identity/local-auth-config.example.pl):

    $Self->{'TESSERA::LocalIdentity::Enabled'} = 1;
    $Self->{'AuthModule'} = 'Kernel::System::Auth::TESSERALocalIdentity';
    $Self->{'AuthModule::UseSyncBackend'} = '';

Remove additional AuthModule1..10 entries; do not add fallback agent auth modules. Do not configure a sync backend for this router. Keep existing AuthTwoFactorModule settings: native agent MFA still executes after the password backend returns. Keep Customer::AuthModule as the native CustomerAuth::DB or the already-configured TESSERAIdentity local-compatible router, without additional Customer::AuthModule1..10 backends. The TESSERAIdentity OIDC mode is not supported for this local flow. Do not replace an existing external customer authentication configuration merely to run this test.

Restart all web/daemon workers consistently so the Custom User password hook and event module load. The page's readiness check requires the enabled setting, exact sole agent router, explicit disabled sync and loaded password hook. Installation and this page never switch authentication automatically. Test the unlinked emergency agent before linking anyone. With the router configured, unlinked agents retain native DB authentication; linked agents never fall back to their old agent password. This is a local-test router, not a generic replacement for existing LDAP/SSO agent authentication chains.

## One person, explicit agent access

1. Create the local customer using the standard Customers administration form, including its local password; or select an existing local customer.
2. Open Admin -> People and agent access (Action=AgentTESSERALocalIdentity). Search/select the customer and Load person. The main customer profile/password editor remains linked from this page.
3. Check "This customer also has agent access". Select approved agent groups (the selected direct groups grant read/write) and/or agent roles. No users/admin/IPC group or role is automatically assigned; customer SupportAssignments and entitlements do not become agent grants.
4. Save. An unused login creates its secondary agent record. If a native agent with that login already exists, enter its exact agent ID and confirm it belongs to this customer; automatic takeover by matching login is rejected. The independent agent password is randomized before publishing the link, never copied from the customer or exposed. Root/current administrator links are rejected.
5. Link identity uses the immutable native customer row ID and agent ID, so deletion/reuse of a login cannot inherit an old link. Linked agent login remains a separate native field; login renames/merges and related SupportAssignment/API-key migrations are not automated by this first flow. Avoid renaming during the initial acceptance test.

Repeated Save updates the existing pair rather than creating another agent. Only selected managed agent group/role assignments are retired when removed from this form; assignments outside the managed selection are preserved. Disabling agent access preserves the customer, link and history and invalidates the secondary agent. It does not turn the person into a new identity or delete evidence. Re-enabling access still requires explicit valid customer and agent grants.

## Password and profile behavior

Agent authentication for a linked local person checks the current primary customer password using native CustomerAuth::DB. It never compares a copied hash or falls back to the agent-local password on failure. Invalid master/agent, disabled link, routing errors or a source that becomes externally managed deny linked authentication.

Native customer password changes immediately affect subsequent agent logins. The Custom User hook also forwards linked agent SetPassword and native AdminUser UserUpdate password resets to the primary customer's native SetPassword; a failed primary write prevents the agent reset. Unlinked users retain native password-writing behavior. No plaintext password or password hash is stored in the identity link, audit JSON, scripts or profile synchronization data.

CustomerUserUpdate events synchronize first/last name, title, email and customer validity to an explicitly linked secondary agent. They do not create links, add grants, copy passwords or modify governance. Automatic profile synchronization never re-enables an invalid secondary agent; reactivation requires an explicit administrator Save in People and agent access. Login authentication independently rechecks master validity and source even if profile synchronization fails. CustomerUser::SetPassword does not need a synchronization event: it is already the shared password source.

Native per-interface password-policy/history/expiry preferences and MFA/session handling remain separate in this phase; this feature does not claim a unified password-policy UI, shared sessions, single sign-on or automatic invalidation of every already-issued session on password change. Use the main customer editor as the preferred local password administration surface and validate existing policies in both interfaces before production adoption.

Identity/grant/profile publication and audit are transactional under a MariaDB advisory lock, with InnoDB required for affected users/preferences/group/role/link/audit tables. A failed operation rolls back and clears native caches. The link/audit tables are retained on uninstall for evidence. Do not roll back to an independent native agent auth module or disable the password-routing feature while active links remain: use a reviewed account migration. This build does not install an automatic unlink/migration that would reactivate an old credential.

## Local acceptance

Use a new disposable customer and explicitly approved limited agent group. Verify: customer and agent login with its initial password; change customer password and prove the old password fails/new password succeeds in both portals; change the linked agent password and repeat; reset it through native AdminUser and repeat; profile/email/validity propagation; agent-only disable leaves customer login available; remove managed grants; repeated Save creates no duplicates; existing-agent collisions/root/current-admin/CSRF/nonadmin paths deny; external identities deny; unlinked emergency admin remains usable. Verify failure rollback and live concurrent writes on MariaDB, native password policy/MFA/session behavior, and loaded modules across all Kubernetes replicas. No live authentication configuration was changed by the build and no real account/password was created or linked here.

Local automated validation exercises the native customer SHA-256 password verifier, password-write hooks, routing/grant/collision/rollback boundaries, template/CSRF behavior and selector callbacks with isolated storage doubles. The local Windows environment lacks the native Crypt::PasswdMD5 dependency; only its unused MD5 import is stubbed for SHA-256/syntax tests. Production native DB, bcrypt/legacy hash, MFA/session and browser acceptance remain pending.
