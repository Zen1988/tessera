# New setup: organization stage

Prepared in TESSERA-Base 0.0.178. Not installed or live-verified.

After installing the package, agents with native admin write permission can open Admin -> New setup (under Governance settings), or Action=AgentTESSERANewSetup. The first page asks organization name and description. Saving creates a native Organization governance object with the exported Active status, under the authenticated actor. The first record uses the normal governance number/ID generator, not a hardcoded ID. Plain text description is converted through native HTMLUtils for rich-text storage.

The next page asks whether to add another organization and lists those created through this wizard. Repeat organization creation or finish organization setup. Completion is explicit; it does not mean the remaining deployment/security setup features are complete. Completed organization setup is read-only, and duplicate submissions return the prior result. The wizard does not reset an existing environment or overwrite existing organizations. An existing organization with the submitted exact name is rejected rather than recreated; setup progress does not adopt existing records implicitly.

## Storage and security

Package installation creates tessera_setup_state and initializes singleton row1 once. Upgrade/reinstall ensures missing storage and preserves existing progress. This is a setup journal, not a governance Dynamic Field. Progress is global to the instance and survives a browser/session restart. Saved organization IDs identify native governance records; deleting the journal does not delete those records. First organization means the first created by this flow, not database ID1.

Creation and progress update run in one database transaction under the singleton row's FOR UPDATE lock. A request key is bound to the authenticated actor and submitted contents, so a repeated POST cannot create another organization. New submissions with a name already added by setup are rejected. Server-side admin checks protect reading and mutation; forms require POST, the current session token and native challenge-token verification, even if global CSRF protection is disabled. All displayed user input is escaped. GET opens/reads the wizard without creating business records.

Deployment uses the current MariaDB/MySQL platform and InnoDB transactions. New storage has InnoDB in the runtime ensure path; core governance tables must also be transactional for atomic rollback. Native governance events execute during object creation; external event side effects cannot be undone by database rollback. SQLite tests validate transaction behavior using a mocked governance API and remove FOR UPDATE syntax; they do not prove MariaDB concurrent locking, native event handlers or live browser/SysConfig acceptance.

## Validation and remaining work

NewSetup.t has42 assertions: initial/additional organization creation, preexisting-name rejection, repeat POSTs, authorization, rollback on journal failure, completion, plain-text encoding, real TT escaping/rendering, endpoint method/token checks and storage repair/preservation. Five active-seed/bootstrap suites add66 checks.

Next connect ticket-prefix/reset configuration, separate ticket/asset/governance reset tools, CSR lifecycle, Central ingestion and confidential disclosure as separately implemented setup steps. Those actions are not represented by working buttons in this release. Whole-platform first-run Docker bootstrap and automatic onboarding redirect remain separate pending work. No reset, certificate deployment, account provisioning or production database change was executed during this implementation.
