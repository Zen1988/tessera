# Docker full-platform bootstrap, reconciliation and upgrades

Confirmed requirement, 2026-10-19. Design only; no image or runtime changes yet.

## Distribution and startup

The startup job owns initialization of the complete shipped platform: OTOBO core, declared ITSM dependencies, CMDB, and TESSERA. It must work when the application database does not exist or contains no application tables, not just when TESSERA tables are missing. Database server provisioning is a separate container/deployment responsibility; application database creation uses explicitly configured bootstrap credentials and only the configured database name. Normal application credentials must not require server-wide database creation privileges.

Classify startup state before changing anything:

- Database server unreachable or authentication denied: report/retry readiness within bounds; never infer that the database is absent.
- Application database absent: create the configured database when bootstrap credentials permit, then initialize the entire platform.
- Verified empty application database: install core schema and initial data, then declared ITSM/CMDB packages in dependency order, then TESSERA schema/defaults, then expose the organization wizard.
- Recognized partial installation: resume recorded installation stages after validating actual state. Do not replay core initial inserts into a populated database.
- Recognized existing installation: run component-specific migrations and missing-structure/default reconciliation in dependency order, preserving business data.
- Nonempty unrecognized database: stop with diagnostics rather than guessing ownership or overwriting tables.

Ship a component/version/dependency manifest with the image and the actual authoritative core schema/initial-data and package install/upgrade artifacts. Bootstrap through native installer/package APIs where available so package registration, hooks, configuration and required seed records are coherent; creating tables alone is insufficient. Initial bootstrap and later repair must cover all shipped components rather than assuming ITSM/CMDB were installed manually.

Use a server-level or equivalent deployment lock before the application database and migration journal exist, then durable component/stage tracking once core storage is available. A lost connection or restart must not create parallel installers. The full installation path must also initialize required native configuration and administrator enrollment through a protected setup flow, without publishing default/shared credentials. Customer access and background execution remain unavailable until platform initialization and required setup complete.

Distribute future TESSERA releases as complete versioned Docker images. Database, attachments and instance configuration remain persistent outside the replaceable image. Updating the image must deliver the new application code as well as its schema/default-data manifest; a mounted old application tree must not silently hide the new release.

On initial deployment and subsequent starts, run one startup upgrade job before admitting web requests, imports, schedulers or execution workers. Use a database-backed lock so concurrent replicas cannot apply the same changes. Other services wait for successful completion and an explicit readiness result. A failed check or migration leaves services unready with actionable diagnostics; do not run indefinitely or mark partial application complete.

The job checks the actual deployed schema and definitions, rather than trusting only a version marker. Create missing required tables, columns, indexes, Dynamic Fields, GeneralCatalog entries, governance class definitions, CMDB class definitions and declared system bootstrap objects from the authoritative release manifest. Database columns and application Dynamic Fields are distinct checks. Validate existing types/constraints as well as presence: incompatibility requires an explicit migration, not a blind overwrite.

Use ordered versioned migration steps for changes to existing structures or values. Record applied steps and durable progress; interrupted jobs must safely resume or report repair required. Account for database DDL that cannot roll back. Repeated startup with an up-to-date database must make no data changes. Reject unsupported database-newer-than-image downgrades instead of attempting to undo schema implicitly.

## Ownership and preservation

### Active-only release configuration

User confirms the distributable configuration must contain essential ticket types and only currently active CMDB classes/roles/categories, governance object classes/roles/categories, and relevant active GeneralCatalog entries. Build this manifest from a verified current authoritative export, using each object's native validity semantics rather than guessed names or hardcoded numeric validity IDs. Missing or ambiguous validity must be reported, not silently treated as active. Do not include inactive, deprecated or historical definitions as seed content merely because they occur in older exports or bootstrap code.

Include current definitions and required field/catalog mappings for the selected active classes and roles, not just catalog labels. Validate references transitively before publishing the image. If an active definition depends on an inactive object/catalog entry, report the conflict and resolve it in the source configuration; do not silently import or reactivate the inactive dependency. Essential ticket types must be enumerated from the current authoritative runtime configuration, not invented from historical names. Report native core/package defaults that conflict with this active-only configuration policy so they are handled explicitly in the release build.

This is a release configuration selection rule, not permission to export customer tickets, assets, organizations, credentials, SupportAssignments or other instance-specific records. Any reusable governance object seed instances require an explicit system-default designation under the ownership manifest; active status alone does not authorize copying business data. Asset and governance class schemas remain distinct from their instances.

On upgrades, absence from the new active-only seed manifest does not authorize deletion or reactivation of previously deployed records. Preserve historical references and administrator ownership; any required retirement/migration is a separate explicit versioned operation. Runtime startup reconciliation uses the filtered release manifest and must not restore excluded legacy definitions through older ensure routines.

The image manifest declares what is required, what can be created automatically, and what is administrator-owned. Reuse latest SOPM/OPM definitions and verified current exports. Do not infer missing fields/objects from historical samples or create arbitrary replacement names.

Create required system defaults only when absent. Preserve existing administrator-owned GovernanceRole definitions and other customized data under the established merge contract. Do not treat missing customer-specific assets, Application, Organization, Books or other instance records as permission to restore example data. Missing instance data either belongs to the organization wizard or an explicitly authorized import/recovery operation. Deleted historical business data cannot be reconstructed from schema checks alone.

Ticket, asset and governance reset remain separate explicit agent operations. Startup reconciliation must not reverse a deliberate reset by recreating customer records. A governance reset must define which required system defaults survive or are re-established and which instance records are recreated through setup. A setup completion/progress record is needed, with schema chosen during implementation rather than invented here.

## Organization wizard

First page asks organization name and description and creates the first Organization record through the existing backend. Next page offers additional Organization creation, repeatable until the operator continues. Use server-side validation, authorization, CSRF protection and retry-safe submission. Retain created IDs across wizard navigation; first organization does not mean primary key 1. After restart, resume incomplete setup without duplicating organizations. An image upgrade must not restart completed onboarding or overwrite the organization's details.

## Current source evidence

- Authoritative TESSERA-Base 0.0.174 SOPM includes DatabaseInstall, DatabaseUpgrade and post-install/upgrade bootstrap hooks.
- GovernanceDB::Bootstrap::InstallDefaults already ensures some tables, catalogs, definitions and Dynamic Fields. It also deploys overlays/SysConfig and performs runtime repairs, so calling the entire method on every startup without auditing its effects is not an accepted reconciliation implementation.
- The bundled OTOBO Docker entrypoint explicitly says an existing installation is not automatically updated and requires copy/update tasks. TESSERA needs an intentional image/code-volume and migration integration rather than assuming replacing an image updates a persisted code tree.
- Bundled core sources include scripts/database/otobo-schema.xml, scripts/database/otobo-initial_insert.xml and native Installer.pm database creation logic. These establish available native installation inputs, not an implemented unattended whole-platform installer.

## Implementation and acceptance sequence

1. Inventory authoritative schema/default declarations, ownership and existing bootstrap effects; select the actual Docker build/compose layout and database version.
2. Implement a shared reconciliation planner and ordered migration runner with lock, applied-step journal, bounded retries and readiness gate. Reuse audited existing ensure routines.
3. Implement organization setup with durable progress and backend object APIs, then connect the agent wizard and startup onboarding routing.
4. Verify absent database, empty database, unavailable server, bad credentials, unrecognized nonempty database, core-only installation, interrupted core/package bootstrap, existing full installation upgrade, repeated same-image start, missing core/ITSM/CMDB/TESSERA table/column/default repair, incompatible structure rejection, concurrent startup, interrupted migration, preserved custom roles/configuration, deliberate reset and persistent attachment retention. Check old mounted code cannot override the intended release.

No runtime readiness or automatic-repair claims are accepted until these scenarios pass against the actual Docker/database deployment.
