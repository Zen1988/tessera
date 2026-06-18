# TESSERA Project Status

Last Updated: 2026-06-18

## Current Focus

- Customer runtime execution actions on `CustomerTicketZoom`.
- Runtime stakeholder injection for active execution child tickets.
- Runtime duplication of a parent governance request for an additional external party.
- BlueBook neutral closure handling for `closed no action` and `closed duplicate`.
- Assessor Assessment task outcomes on `CustomerTicketZoom`.
- Implementer Task completion outcome handling on `CustomerTicketZoom`.
- Mandatory BlueBook outcome roll-up using `ZTicket-Outcome`.
- Follow-up/PurpleBook corrective execution from active child tickets.
- Template-driven child ticket hydration from BlueBook records.
- ZTSM first-class Template and RiskStatement governance concepts.
- Keep governance truth separate from execution evidence.

## Completed Work

- Added customer ZTSM runtime action `AddRequiredSupportProfile`.
- Added action visibility on active child execution tickets only:
  - Ticket Type `Assessment`
  - Ticket Type `Endorsement`
  - Ticket Type `Approval`
  - `StateType` must not be `closed`
  - Ticket must carry `ZTicket-Parent`, `ZTicket-BlueBook`, `ZTicket-BlueLevel`, and `ZTicket-Chapter`
  - Current customer user must own `ZTicket-Owner`
- Added support profile prompt using existing SupportProfile governance objects.
- Added runtime creation of an additional mandatory child execution ticket:
  - Same parent governance ticket
  - Same BlueBook
  - Same BlueLevel
  - Same chapter
  - Same execution ticket type
  - Selected support profile stored in existing `ZTicket-Profile` and `ZTicket-OwnerGroup`
  - `ZTicket-Mandatory` set to `1`
  - `ZTicket-RequiredWeightage` set to `1`
- Added duplicate protection for the same parent, BlueBook, BlueLevel, chapter, ticket type, and support profile.
- Added article snapshots on both the source child ticket and the new child ticket.
- Added customer ZTSM runtime action `CreateExternalPartyRequest`.
- Added action visibility for a separate external-party request:
  - Root governance tickets can be duplicated by the requester while `StateType` is not `closed`.
  - Active child execution tickets can trigger duplication of their parent request when the current customer user owns `ZTicket-Owner`.
  - Closed tickets do not allow the action.
- Added target service prompt for the external-party request.
- Added runtime creation of a new root governance ticket:
  - Same ticket type as the duplicated parent request, such as `ServiceRequest`.
  - Same requester, queue, priority, SLA, and copied ticket Dynamic Fields from the parent request.
  - Target service is selected in the action prompt.
  - Ticket Dynamic Fields are copied through the Dynamic Field backend so DynamicField Set values are copied as structured values.
  - Process management runtime fields are not copied, so the new ticket does not inherit the old process activity.
- Updated `ZTSMServiceLibrarian` so a ticket that already has `ZTicket-StateBook` skips ServiceSupportMap/governance resolution.
- Invoked `ZTSMServiceLibrarian` for the new external-party request after Dynamic Fields are copied.
- Added article snapshots on both the source ticket and the new external-party request ticket.
- Added BlueBook neutral closure propagation in `ZTSMChapterDirector`:
  - `closed no action` and `closed duplicate` are treated as neutral closed task outcomes.
  - If the neutral-closed task is mandatory and is the only child ticket in the same parent, BlueBook, and BlueLevel, the parent ticket is closed with the same state.
  - If other child tickets exist in the same BlueLevel, the neutral-closed task only fulfills its own participation weightage and the BlueBook continues to wait for the other tasks.
- Added assessor-owned Assessment task outcomes:
  - `Submit Assessment` closes the Assessment child as `closed successful` and uses the risk assessment workspace.
  - `Close Duplicate` closes the Assessment child as `closed duplicate`.
  - `Close No Action` closes the Assessment child as `closed no action`.
  - All three outcomes require the current customer user to own `ZTicket-Owner`.
- Added implementer-owned Task completion action:
  - Visible only for Ticket Type `Task`.
  - Current customer user must own `ZTicket-Owner`.
  - Prompts for `ZTicket-Outcome`.
  - Prompts for details and stores them in `ZTicket-Result`.
  - Allows one uploaded attachment and writes it to the generated task completion article.
  - Writes an article snapshot for every Task completion.
  - Maps Task outcome to ticket state:
    - Successful `0` -> `closed successful`
    - No Action `1` -> `closed no action`
    - Partial Success `2` -> `closed successful`
    - Failed `-1` -> `closed unsuccessful`
    - Rollback `-2` -> `closed rollback`
- Updated runtime action dialog form to support `multipart/form-data` uploads.
- Added mandatory BlueLevel outcome roll-up in `ZTSMChapterDirector`:
  - Only mandatory child tickets are considered.
  - Parent `ZTicket-Outcome` is updated from mandatory child outcomes.
  - Failed/Rollback mandatory outcomes are hard stops and close the parent as failed/rollback.
  - Partial Success writes parent `ZTicket-Outcome = 2` and allows BlueBook flow to continue.
  - Success/No Action outcomes are non-negative completion outcomes.
- Bumped `GovernanceDB.sopm` package version to `0.0.72`.
- Generated `Kernel/Package/GovernanceDB-0.0.72.opm` for upgrade testing.
- Added BlueBook record support for `ZBlue-PurpleBook` and `ZBlue-Template`.
- Added customer runtime action `Follow-up`:
  - Visible on owned active child tickets of type `Assessment`, `Endorsement`, `Approval`, `Implementation`, and `Verification`.
  - Requires the current BlueBook record to contain `ZBlue-PurpleBook`.
  - Sets the current child ticket state to `follow-up`.
  - Spawns the configured PurpleBook as child execution tickets under the current child ticket.
  - Preserves the original child ticket `ZTicket-BlueLevel` so it can still return to its original parent BlueBook level.
  - Writes a follow-up article with the acting owner and created corrective tickets.
- Added Verification completion action:
  - Visible only for owned active `Verification` tickets.
  - Prompts for success/failed result, details stored in `ZTicket-Result`, and a mandatory artifact upload.
  - Successful verification sets `ZTicket-Outcome = 0` and closes `closed successful`.
  - Failed verification starts Follow-up when `ZBlue-PurpleBook` is configured; otherwise it sets `ZTicket-Outcome = -1` and closes `closed unsuccessful`.
  - Writes a verification article and attachment.
- Updated `ZTSMChapterDirector` for PurpleBook return flow:
  - When a PurpleBook under a `follow-up` parent completes successfully, the original child ticket returns to `in-progress`.
  - When a mandatory PurpleBook task fails, existing failed-first logic closes the original child and immediately evaluates its original parent level.
- Added Template hydration during child creation in both `ZTSMBlueBookRuntime` and `ZTSMBlueBookReader`:
  - `ZBlue-Template` can be empty.
  - Template description is written to the generated child ticket as an article.
  - `ZTemplate-RiskAssessment` rows are mapped into existing `ZRM-RiskAssessment`.
  - Risk statement defaults are applied from the Risk Statement governance object where present.
  - Inherent and residual calculated risk scores are computed from likelihood and impact.
- Bumped `GovernanceDB.sopm` package version to `0.0.73`.
- Generated `Kernel/Package/GovernanceDB-0.0.73.opm` for upgrade testing.
- Synced implementation across:
  - `Kernel/Modules/CustomerTicketZTSMAction.pm`
  - `Kernel/Modules/CustomerTicketZoom.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/*`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/*`
  - `ZTSMOverlay/files/Kernel/Modules/*`
  - `Kernel/Package/GovernanceDB/Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `ZTSMOverlay/files/Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `ZTSMOverlay/files/Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `Kernel/System/ZTSMBlueBookRuntime.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/ZTSMBlueBookRuntime.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ZTSMBlueBookRuntime.pm`
  - `ZTSMOverlay/files/Kernel/System/ZTSMBlueBookRuntime.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `ZTSMOverlay/files/Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt`
  - `ZTSMOverlay/files/Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt`

## Architectural Decisions

- Additional stakeholder injection is a runtime execution action, not a StateBook transition.
- Additional stakeholder injection is not BlueBook choreography; BlueBook already defines the planned sequence.
- The action is controlled by Ticket Type, not lifecycle state.
- Allowed hardcoded Ticket Types for now: `Assessment`, `Endorsement`, `Approval`.
- Future control can move to SysConfig or a governance object, but current implementation intentionally keeps the rule local and explicit.
- The action must not modify governance snapshots, lifecycle position, StateBook position, or BlueBook position.
- The additional task duplicates execution evidence only; it does not duplicate governance truth.
- Closed execution child tickets must not allow additional mandatory stakeholders, to avoid hanging a gate after work has already completed.
- Existing BlueBook level completion logic blocks progression while any child in the same parent, BlueBook, and BlueLevel remains open, so the new mandatory child naturally prevents lifecycle advancement until completed.
- External-party request creation is a separate root/governance request clone, not a child execution duplicate.
- External-party request creation goes back through ServiceLibrarian after cloning, because the selected service can represent a different vendor or party.
- If the cloned request already carries `ZTicket-StateBook`, ServiceLibrarian must treat the snapshot as already chosen and must not resolve governance again.
- Parent/request Dynamic Fields are copied through Dynamic Field backend APIs, not string-rendered values, so DynamicField Set data stays structured.
- `closed no action` and `closed duplicate` are not failure states.
- A neutral closure only propagates upward when it represents the whole mandatory BlueLevel; otherwise it behaves as completion evidence for its own child ticket.
- Assessment neutral closure is an assessor task outcome, not a requester action.
- Assessment neutral closure uses the same owner enforcement as normal Assessment submission.
- Task completion is an implementer task outcome, not a requester action.
- `ZTicket-Result` is the Task details field.
- Parent request status evidence is represented by `ZTicket-Outcome`; hard-stop negative outcomes additionally close the parent ticket state.
- Follow-up is a runtime corrective execution action, not a StateBook transition.
- PurpleBook is read from the current BlueBook record using `ZBlue-PurpleBook`; no ticket Dynamic Field was introduced for PurpleBook.
- Template is read from the current BlueBook record using `ZBlue-Template`; no ticket Dynamic Field was introduced for Template.
- PurpleBook child tickets use their PurpleBook as `ZTicket-BlueBook` and the original child ticket as `ZTicket-Parent`.
- Successful PurpleBook completion returns the original child to `in-progress`; it does not resume StateBook directly.
- Failed mandatory PurpleBook completion propagates through the original child so the original parent BlueBook receives failed-first handling.
- Template risk assessment hydration uses existing `ZRM-*` ticket fields because the current risk assessment workspace stores ticket risk rows there.
- Mandatory outcome precedence:
  - Rollback outranks Failed.
  - Failed outranks Partial Success.
  - Partial Success outranks Successful/No Action but does not stop BlueBook flow.
  - Only mandatory child tickets affect parent outcome roll-up.

## Rejected Approaches

- Do not enable by `ZState-CurrentState`; Ticket Type is the cleaner action-control layer.
- Do not make this a StateBook transition.
- Do not make this a BlueBook transition.
- Do not recalculate governance or rebuild snapshots when adding the stakeholder.
- Do not introduce new Dynamic Field names for this behavior.
- Do not allow additions on closed child tickets.
- Do not make external-party request creation a BlueBook or StateBook transition.
- Do not duplicate child execution tickets for the external-party request; create a new root request and let runtime orchestration handle it.
- Do not force ServiceSupportMap re-resolution when `ZTicket-StateBook` is already present.
- Do not treat `closed no action` or `closed duplicate` as mandatory failure.
- Do not close the parent/root ticket when other tasks exist in the same BlueBook level.
- Do not expose `closed duplicate` or `closed no action` as generic outcomes for Endorsement or Approval yet; current requirement is Assessment/Assessor only.
- Do not use Task free-text remarks as the canonical result; store Task details in `ZTicket-Result`.
- Do not let non-mandatory child outcomes drive parent outcome roll-up.
- Do not show Follow-up when the BlueBook record has no `ZBlue-PurpleBook`.
- Do not store PurpleBook or Template on new `ZTicket-*` fields.
- Do not let PurpleBook spawning overwrite the original child ticket BlueLevel.

## Known Issues / Follow-Up

- `PROJECT_STATUS.md` was empty before this update; older project memory is not present here.
- The current action hardcodes allowed Ticket Types in module defaults. Move to SysConfig or governance object control later if needed.
- Latest generated OPM is `Kernel/Package/GovernanceDB-0.0.81.opm`.
- `Kernel/Package/GovernanceDB-0.0.81.opm` SHA256: `F36B48B6BB7068B6B1D3F17ED92CF9B5CDA4A3E8793A32509DDE87F0F169E22B`.
- Runtime verification is still needed for the target service list and external-party request clone flow inside OTOBO.
- Runtime verification is still needed for sole mandatory `closed no action` / `closed duplicate` propagation.
- Runtime verification is still needed that only the Assessment owner sees and can submit `Submit Assessment`, `Close Duplicate`, and `Close No Action`.
- Runtime verification is still needed that only the Task owner sees and can submit `Complete Task`.
- Runtime verification is still needed for Task attachment upload into the generated article.
- Runtime verification is still needed for parent `ZTicket-Outcome` roll-up across mandatory BlueLevel children.
- Runtime verification is still needed for Follow-up visibility on each configured child type.
- Runtime verification is still needed for PurpleBook spawn and successful return to `in-progress`.
- Runtime verification is still needed for failed PurpleBook propagation to the original parent level.
- Runtime verification is still needed for Template hydration into `ZRM-RiskAssessment`.
- Runtime verification is still needed for Verification artifact upload and failed-with-PurpleBook behavior.

## Next Priorities

- Verify the action in an OTOBO runtime using an active `Assessment`, `Endorsement`, or `Approval` child ticket.
- Confirm SupportProfile search/list permissions in the customer portal environment.
- Verify `CreateExternalPartyRequest` from both a root requester ticket and an active child owner ticket.
- Confirm cloned DynamicField Set values render correctly on the new request.
- Verify neutral closure behavior:
  - Sole mandatory BlueLevel child closes parent with the same neutral state.
  - Multi-task BlueLevel continues until remaining tasks complete.
- Verify assessor outcome buttons on an owned Assessment ticket:
  - `Submit Assessment`
  - `Close Duplicate`
  - `Close No Action`
- Verify Task completion on an owned Task ticket:
  - Outcome dropdown from `ZTicket-Outcome`
  - Details saved to `ZTicket-Result`
  - Attachment written to the task completion article
  - Parent mandatory outcome roll-up
- Install or upgrade using `Kernel/Package/GovernanceDB-0.0.81.opm` and perform runtime verification.
- Verify Follow-up on owned `Assessment`, `Endorsement`, `Approval`, `Implementation`, and `Verification` child tickets.
- Verify an empty `ZBlue-PurpleBook` does not expose Follow-up and failed Verification closes `closed unsuccessful`.
- Verify `ZTemplate-RiskAssessment` creates multiple `ZRM-RiskAssessment` rows when the Template carries multiple risk statements.
- Consider adding SysConfig for `AddRequiredSupportProfileTypes` after the hardcoded behavior is accepted.

## 2026-06-17 Runtime Test Feedback Update

### Completed Work

- Shortened customer runtime action labels:
  - `Add Required Support Profile` now displays as `Amend`.
  - `Create External Party Request` now displays as `Clone`.
  - Assessment neutral outcomes now display as `Duplicate` and `No Action`.
- Moved Assessment neutral outcomes out of the top activity button row:
  - `Duplicate` and `No Action` are now submitted from the Risk Assessment workspace footer.
  - `Submit Assessment` remains the primary assessment submission.
- Made `InActionMenu` effective on `CustomerTicketZoom`:
  - Utility/runtime actions such as `Amend`, `Clone`, requester hold/cancel, follow-up, task completion, and verification completion can render under the header action menu instead of cluttering the main activity row.
- Changed Clone selection from service selection to direct ServiceSupportMap selection:
  - Customer selects a `ServiceSupportMap` governance object.
  - Backend reads `ZTSMServiceSupportMap-Service`, `ZTSMServiceSupportMap-Application`, `ZTSMServiceSupportMap-Environment`, `ZTSMServiceSupportMap-Location`, `ZTSMServiceSupportMap-StateBook`, and `ZTSMServiceSupportMap-ApprovalModel`.
  - New cloned parent request receives the selected service and governance snapshot fields from the selected ServiceSupportMap.
  - New clone stores `ZTicket-Parent` pointing back to the ticket where Clone was triggered.
- Changed clone field copying to skip runtime/governance execution fields:
  - Process fields, `ZState-*`, `ZBlue-*`, current StateBook/ApprovalModel, BlueBook execution fields, owner fields, outcome/result fields, hold state, and execution participation fields are not copied into the new parent request.
- Made duplicate Amend support-profile detection non-fatal:
  - Existing matching support-profile child returns success instead of showing `Could not add required support profile`.
  - Matching now considers GovernanceObjectID, LastVersionID, and Name where available.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Bumped `GovernanceDB.sopm` package version to `0.0.74`.
- Generated `Kernel/Package/GovernanceDB-0.0.74.opm` for install/upgrade testing.
- Verified generated OPM parses as XML and contains 154 embedded package files plus `CodeInstall` and `CodeUpgrade`.
- Verified Perl syntax for `CustomerTicketZTSMAction.pm` and `CustomerTicketZoom.pm`.

### Architectural Decisions

- Clone is a governance-request clone, but the requester must select the exact ServiceSupportMap rather than a generic service.
- Clone does not reuse the original request's StateBook snapshot; it writes a fresh governance snapshot from the selected ServiceSupportMap.
- Clone must not copy BlueBook execution position, owner/assignment state, process runtime fields, hold state, or child-execution fields into the new parent request.
- Assessment `Duplicate` and `No Action` are assessor-owned outcome submissions for the current assessment child, not separate top-level requester actions.
- `Amend` remains a runtime execution action that adds execution evidence only; it does not alter governance truth.

### Known Issues / Follow-Up

- Runtime verification is needed for Clone using direct ServiceSupportMap selection.
- Runtime verification is needed that cloned parent/SR/CR tickets carry `ZTicket-Parent` back to the trigger ticket and receive StateBook/ApprovalModel from the selected ServiceSupportMap.
- Runtime verification is needed that `Amend` no longer errors when the requested support profile already exists.
- Runtime verification is needed that Assessment footer buttons submit `Duplicate`, `No Action`, and `Submit Assessment` correctly.
- Local `otobo.Console.pl Dev::Package::Build --help` is still blocked because the bundled console refuses to run outside the OTOBO user context; `Kernel/Package/GovernanceDB-0.0.74.opm` was generated mechanically from the authoritative SOPM and package file list instead.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.76.opm`; install/upgrade 0.0.76 and retest the exact customer screenshots/workflows:
  - Assessment workspace footer buttons.
  - Amend support-profile creation/duplicate behavior.
  - Clone ServiceSupportMap selection and new request governance hydration.

## 2026-06-17 Template / First-Class ZTSM Update

### Completed Work

- Added `Template` as a first-class GovernanceDB class in `default_classes.json`.
- Added `RiskStatement` as a first-class GovernanceDB class in `default_classes.json`.
- Added `Reference` category to GovernanceDB defaults.
- Added `ZBlue-Template` and `ZBlue-PurpleBook` back into default `ZBlue-Record` so upgrade can repair the BlueBook DynamicField Set.
- Added full default `ZTemplate-*` DynamicField definitions for `ZTemplate-RiskAssessment`.
- Added runtime GovernanceObject resolution for Template and RiskStatement values:
  - Accepts numeric GovernanceObjectID.
  - Accepts GO number.
  - Accepts rendered labels such as `Template: Std-Fw-Assessment`.
- Made `Amend` and `Clone` visible activity-row actions again while keeping longer utility actions in the menu.
- Bumped `GovernanceDB.sopm` package version to `0.0.75`.
- Generated `Kernel/Package/GovernanceDB-0.0.75.opm` for install/upgrade testing.

### Architectural Decisions

- Template is now a ZTSM first-class governance concept, not a manually maintained local object shape.
- RiskStatement is now a ZTSM first-class governance concept used by Template risk assessment hydration.
- BlueBook records reference Template through `ZBlue-Template`; no `ZTicket-*` Template field is introduced.
- Upgrade repair is idempotent and class-name based, avoiding environment-specific class IDs from exports.

### Known Issues / Follow-Up

- Runtime verification is still needed that upgraded `ZBlue-Record` keeps `ZBlue-Template` and `ZBlue-PurpleBook`.
- Runtime verification is still needed that `Std-Fw-Assessment` hydrates all expected risk rows into `ZRM-RiskAssessment`.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.76.opm`; install/upgrade 0.0.76 instead.
- Reopen the Assessment child and confirm the template creates the expected risk rows.
- Confirm `Amend` and `Clone` are visible again after upgrade.

## 2026-06-17 Bootstrap Upgrade Repair

### Completed Work

- Repaired `Kernel/System/GovernanceDB/Bootstrap.pm` catalog seeding so `_CatalogItemEnsure` resolves existing GeneralCatalog rows through `ItemList` before attempting `ItemAdd`.
- Avoided calling `GeneralCatalog::ItemGet` for missing catalog items during bootstrap, preventing the upgrade error `Item not found in database!` and the related empty SQL `IN ()` failure.
- Kept catalog creation idempotent by re-reading after `ItemAdd` returns false, so repeated install/upgrade runs do not fail when the item already exists.
- Bumped `GovernanceDB.sopm` package version to `0.0.76`.
- Generated `Kernel/Package/GovernanceDB-0.0.76.opm`.
- `Kernel/Package/GovernanceDB-0.0.76.opm` SHA256: `4FB38F2FD1328F58BB07C28FFD10B063E2A53822050D438AF85CC2B002162F01`.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.77.opm`; install/upgrade 0.0.77 and retest bootstrap first.

## 2026-06-17 Amend / Clone Runtime Repair

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.77`.
- Repaired Amend duplicate detection so it no longer passes SupportProfile names into `ZTicket-OwnerGroup` TicketSearch reference validation; it now searches stable ticket context first and compares owner group locally.
- Guarded SupportAssignment reference searches so only numeric SupportProfile IDs are submitted to reference-field search validators.
- Repaired Clone / external-party request input handling so submitted ServiceSupportMap names are resolved to GovernanceObject IDs and Service values are resolved to Service IDs before ticket creation.
- Adjusted custom runtime dialog CSS in the CustomerTicketZoom runtime overlay so Amend and Clone fieldsets align like the assessment view.
- Repaired GovernanceObject version zoom/list status handling so missing `ZTSMStatusID` no longer calls `GeneralCatalog::ItemGet` with an empty ID.
- Passed `ConfigItemHandled` during GovernanceObject version DynamicField writes to prevent ITSM ConfigItem hooks from treating GovernanceObject version IDs as ConfigItem IDs.
- Added idempotent bootstrap seeding for GovernanceObject history types, including `AttachmentAddPost` and `AttachmentDeletePost`.
- Generated `Kernel/Package/GovernanceDB-0.0.77.opm`.
- `Kernel/Package/GovernanceDB-0.0.77.opm` SHA256: `40927AF6A4E27AF0D61BAA0CB4D5C8A3B496E8E7FEBC9DE7860C2F31B442A6EF`.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.78.opm`; install/upgrade 0.0.78 because 0.0.77 embedded base64 file content without `Encode="Base64"` and can install corrupted module files.
- Retest Amend with a SupportProfile name such as `ICA IaaS Ext ATFM Cloud Team`.
- Retest Clone with a ServiceSupportMap name such as `ICA-SSC-NETWORK-FIREWALL-ADD`.
- Retest GovernanceObject version zoom/list after upgrade to confirm history type and ConfigItem hook errors are gone.

## 2026-06-17 OPM Encoding / Template / Clone Filter Repair

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.78`.
- Rebuilt the generated OPM with `Encode="Base64"` on all 154 embedded file nodes, repairing the 0.0.77 install corruption that produced raw base64 Perl files and `Identifier too long`.
- Repaired Template risk hydration so `ZTemplate-RiskAssessment` rows can be read from both keyed row hashes and DynamicField Set row shapes using `DF` plus `Value` or `Content`.
- Updated Clone ServiceSupportMap selection to filter against the root request service, so an Assessment child only offers maps for the same parent request service.
- Added Clone backend enforcement so a submitted ServiceSupportMap whose service differs from the root request service is rejected.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.78.opm`.
- `Kernel/Package/GovernanceDB-0.0.78.opm` SHA256: `1E04DE7C78D3A9E866FE24C88314027CD934B75A727F6B542E61749DC477575F`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.78.opm`.
- If 0.0.77 already installed raw base64 files and the package manager page cannot load, the environment may need a direct 0.0.78 console/package repair path to overwrite those files.
- Retest Template hydration from `Std-Fw-Assessment`; it should create the expected multiple `ZRM-RiskAssessment` rows.
- Retest Clone ServiceSupportMap selection from an Assessment child; it should show only maps for the same root request service.
- Retest Clone ticket creation and verify the new parent request keeps `ZTicket-Parent` back to the trigger ticket.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.79.opm`; install/upgrade 0.0.79 instead.
- Retest the customer portal workflows in this order: dashboard refresh, Assessment template hydration, Clone same-service map filter, Clone creation, Amend support-profile add/duplicate behavior.

## 2026-06-17 Runtime Regression Repair 0.0.79

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.79`.
- Repaired customer dashboard workable-ticket SupportProfile lookup so it no longer searches `ZTSMSupportAssignment-UserAccount` through the DynamicField `Agent` backend; it now lists SupportAssignment objects and compares users locally.
- Repaired `ZTSMBlueBookReader` record parsing so `ZBlue-Template` is read from DynamicField Set row shapes using `DF` plus `Value` or `Content`.
- Repaired `ZTicket-Profile` ticket reference configuration so it allows both `Governance Role` and `Support Profile`.
- Hardened Clone action:
  - Submitted ServiceSupportMap labels are normalized before lookup.
  - ServiceSupportMap governance reference fields are resolved to GovernanceObject IDs before writing ticket fields.
  - Optional copied DynamicField write failures are logged and skipped instead of aborting the clone.
  - Backend same-service rejection now logs the source and selected service IDs.
- Hardened Amend action:
  - Submitted SupportProfile labels are normalized before lookup.
  - DynamicField write failures now log the exact field, ticket ID, and value.
- Synced changed files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.79.opm`.
- `Kernel/Package/GovernanceDB-0.0.79.opm` SHA256: `37FF076BF63B5924B433A996CAD87F3A540057E14C5287D631BE1DAFFD8C727D`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.79.opm`.
- Restart PSGI/web workers after upgrade if subroutine redefinition or reload warnings continue after package install.
- Retest dashboard refresh from CustomerTicketZoom back to CustomerDashboard; the previous `DynamicField::Driver::Agent` load failure should no longer be triggered by the dashboard tile.
- Retest Amend. If it still fails, the OTOBO log should now show the exact failing DynamicField/value.
- Retest Clone. If it still fails, the OTOBO log should now show whether the blocker is map lookup, service mismatch, ticket create, or governance field write.
- Retest Template hydration on a newly spawned Assessment child, because existing child tickets will not be backfilled automatically.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.80.opm`; install/upgrade 0.0.80 and restart PSGI/web workers before retesting.

## 2026-06-17 Driver Repair / Lazy Template Hydration 0.0.80

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.80`.
- Added clean `Kernel/System/DynamicField/Driver/Agent.pm` to the package file list so upgrade can overwrite a corrupted installed Agent dynamic-field backend.
- Added `Kernel::System::ZTSMBlueBookRuntime::TemplateIDForTicket`.
- Added Assessment lazy hydration:
  - When the Assessment workspace loads and `ZRM-RiskAssessment` is empty, it resolves template through `ZTicket-BlueBook`, `ZTicket-BlueLevel`, and `ZTicket-Chapter`.
  - It writes template rows back to the existing `ZRM-RiskAssessment` DynamicField Set before rendering the assessor form.
- Added template application during Amend-created duplicate child ticket creation, so additional SupportProfile children inherit the BlueBook record template.
- Hardened Template DynamicField Set parsing so wrapper hashes containing `Values`, `Value`, `Content`, `Items`, or `Rows` arrays are normalized to row arrays before mapping into `ZRM-*`.
- Generated `Kernel/Package/GovernanceDB-0.0.80.opm`.
- `Kernel/Package/GovernanceDB-0.0.80.opm` SHA256: `158C516BCD6AB41AB6003AB4300F8E2DB6BF2A6D13F9E85A6F0F53C9608A8779`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.80.opm`.
- PSGI/web workers must be restarted after upgrade; the current logs show old packages being reloaded in-process and the Agent backend remains poisoned until process restart.
- Retest Agent queue/customer permission paths first, because Amend/Clone cannot be proven while `DynamicField::Driver::Agent` fails globally.
- Retest an existing empty Assessment child; lazy hydration should write `ZRM-RiskAssessment` during form load if the BlueBook record has `ZBlue-Template`.
- Retest a newly Amend-created child; template rows should be written during child creation.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.81.opm`; install/upgrade 0.0.81 to capture error-level Amend/Clone diagnostics.

## 2026-06-17 Error-Level Runtime Diagnostics 0.0.81

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.81`.
- Added explicit error-level diagnostics for Amend and Clone top-level failures before `CustomerErrorScreen`.
- Added error-level `Amend started` and `Clone started` markers so Apache error.log confirms whether the upgraded module is actually loaded.
- Added error-level Amend diagnostics for:
  - Missing ticket context.
  - Missing submitted SupportProfile.
  - Unresolvable SupportProfile.
  - Resolved SupportProfile without GovernanceObjectID.
  - Missing `ZTicket-Parent`, `ZTicket-BlueBook`, `ZTicket-BlueLevel`, or `ZTicket-Chapter`.
  - Parent ticket load failure.
  - Child ticket creation failure.
- Added error-level Clone diagnostics for:
  - Missing ticket context.
  - Root ticket resolution failure.
  - ServiceSupportMap field application failure.
- Ensured template lazy-hydration diagnostics also use error level.
- Generated `Kernel/Package/GovernanceDB-0.0.81.opm`.
- `Kernel/Package/GovernanceDB-0.0.81.opm` SHA256: `F36B48B6BB7068B6B1D3F17ED92CF9B5CDA4A3E8793A32509DDE87F0F169E22B`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.81.opm`.
- After upgrade and restart, Apache error.log should show `CustomerTicketZTSMAction: Amend started` or `CustomerTicketZTSMAction: Clone started` on each action submit.
- If the started marker appears, the next `CustomerTicketZTSMAction:` error should identify the failing branch.
- If the started marker does not appear, OTOBO is still not loading the upgraded module.

### Next Priorities

- Install/upgrade 0.0.81, restart PSGI/web workers, run Amend once, run Clone once, then inspect Apache error.log for `CustomerTicketZTSMAction:`.

## 2026-06-17 Runtime Failure Repair 0.0.82

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.82`.
- Repaired Amend parent ticket loading:
  - `TicketGet` is now read into a hash before checking parent ticket data.
  - Fixes the logged failure `Amend failed: parent ticket '133' could not be loaded` when the parent ticket exists.
- Repaired Clone root ticket resolution:
  - Parent/root ticket `TicketGet` is now read into a hash before returning the resolved root ticket.
  - Fixes the logged failure `Clone failed: root ticket could not be resolved from source ticket '134'` when the child ticket has `ZTicket-Parent`.
- Repaired Template risk assessment hydration shape for `ZRM-RiskAssessment`:
  - Entity fields inside the DynamicField Set are now written as per-row array values as expected by OTOBO Set/BaseEntity drivers.
  - Template metadata tokens such as `ZRM-RiskCategory` are discarded if they leak through as values.
  - Prevents the Set driver crash `Can't use string ("ZRM-RiskCategory") as an ARRAY ref`.
- Added error-level logging when template risk assessment write fails:
  - Logs `ZTSMBlueBookRuntime: Template risk assessment field set failed` with TicketID, TemplateID, and row count.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.82.opm`.
- `Kernel/Package/GovernanceDB-0.0.82.opm` SHA256: `F96C7CB6262DAA16A3C4A4D62FD379CD7476423F2543E95A105EEB8B3CEE551E`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.82.opm`.
- Restart PSGI/web workers after upgrade before retesting, especially after prior driver reload errors.
- Retest existing empty Assessment child `2026061725000023`; lazy hydration should populate template rows instead of crashing.
- Retest Amend from child ticket `134`; it should load parent ticket `133` and proceed to duplicate detection or child creation.
- Retest Clone from child ticket `134`; it should resolve root/parent ticket `133`, enforce same-service ServiceSupportMap, and proceed to create the cloned parent request.

### Next Priorities

- Install/upgrade 0.0.82, restart PSGI/web workers, and retest in this order:
  - Assessment workspace load/template hydration.
  - Amend support-profile add/duplicate behavior.
  - Clone same-service ServiceSupportMap creation.

## 2026-06-17 Clone Governance Snapshot Correction 0.0.83

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.83`.
- Corrected Clone ServiceSupportMap handling:
  - The selected ServiceSupportMap is only the selector/source of governance applicability.
  - Clone sets the new ticket service from the selected map.
  - Clone writes `ZTicket-StateBook` and `ZTicket-ApprovalModel`, matching the governance snapshot fields written by `ZTSMServiceLibrarian`.
  - Clone preserves `ZTicket-Parent` back to the trigger/source ticket.
  - Clone no longer writes application, environment, or location fields from ServiceSupportMap in this action.
- Fixed the Perl hash assignment bug where unresolved governance values could return an empty list and corrupt `%FieldMap`.
- Generated `Kernel/Package/GovernanceDB-0.0.83.opm`.
- `Kernel/Package/GovernanceDB-0.0.83.opm` SHA256: `70C772F461056293CFD0D4D1F6CF35A8FBE902B766B8288A07D4CFC729A45BFE`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.83.opm`.
- Retest Clone from child ticket `134`; the previous failure `Dynamic field set failed: '89' does not exist` should no longer occur.

### Next Priorities

- Install/upgrade 0.0.83, restart PSGI/web workers, and retest Clone.

## 2026-06-17 Clone Customer Permission Repair 0.0.84

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.84`.
- Repaired Clone customer visibility for child-owner initiated clones:
  - The cloned parent ticket now uses the acting customer user as `CustomerUser`.
  - The cloned parent ticket now writes `CustomerID` from the acting customer user's `UserCustomerID`, falling back to the original root ticket customer ID.
  - This prevents the immediate redirect to the new cloned parent from landing on `No Permission` when the child owner is not the original requester.
- Kept Clone governance behavior from 0.0.83:
  - ServiceSupportMap is still only the selector/source.
  - Clone writes `ZTicket-StateBook`, `ZTicket-ApprovalModel`, and the `ZTicket-Parent` backlink.
- Suppressed harmless `ZTSMBlueBookRuntime` subroutine redefinition warnings during package hot-reload.
- Generated `Kernel/Package/GovernanceDB-0.0.84.opm`.
- `Kernel/Package/GovernanceDB-0.0.84.opm` SHA256: `45AC1B55E94D884595CA49F0629F1C654D8D546A019C985B3EBADA7D35EB63D3`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.84.opm`.
- Retest Clone from child ticket `134`; new ticket should open for the acting customer user instead of showing `No Permission`.

### Next Priorities

- Install/upgrade 0.0.84, restart PSGI/web workers, and retest Clone end-to-end.

## 2026-06-17 Clone UX / Title Correction 0.0.85

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.85`.
- Changed Clone completion behavior:
  - Clone no longer redirects the customer to the newly created parent ticket.
  - Clone returns the customer to the source/current ticket after successful creation.
- Confirmed Amend already returns the customer to the source/current ticket after successful creation or duplicate detection.
- Changed cloned parent ticket title format:
  - Removed `External Party - <Parent Title>`.
  - New format is `<Parent TicketType>:<ParentTicket ID>: <Parent Title> - <ServiceSupportMap Name>`.
  - Parent identifier uses parent ticket number when available, falling back to parent internal TicketID.
- Generated `Kernel/Package/GovernanceDB-0.0.85.opm`.
- `Kernel/Package/GovernanceDB-0.0.85.opm` SHA256: `E56BD48478D55D6A6C78900BF8B179D43BB3140925709B35F77B0B7217DEFB75`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.85.opm`.
- Retest Clone from an Assessment child; it should stay on the current child ticket and the created parent title should use the parent context and selected ServiceSupportMap name.

### Next Priorities

- Install/upgrade 0.0.85, restart PSGI/web workers, and retest Clone title plus redirect behavior.

## 2026-06-17 Article Cleanup / Neutral BlueBook Stop 0.0.86

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.86`.
- Added RichText/plain-text cleanup before writing runtime evidence:
  - Strips full CKEditor HTML documents.
  - Removes `style` and `script` blocks.
  - Converts common block tags and line breaks to text.
  - Decodes common HTML entities.
- Applied cleanup to:
  - Template description article text.
  - Template-derived text fields before writing assessment rows.
  - Runtime remarks in text articles.
  - Risk assessment article values and remarks.
  - Stored assessment remarks.
- Improved Clone article ticket references:
  - Source ticket, duplicated parent ticket, and new request ticket now render with ticket number/internal ID, ticket type, and title instead of only internal IDs.
- Repaired BlueBook mandatory neutral completion behavior:
  - If a mandatory BlueLevel completes with at least one successful or partial-success mandatory task, BlueBook can continue.
  - If all mandatory tasks in the completed BlueLevel are neutral outcomes (`closed duplicate` / `closed no action`) and none are successful/partial/failed, the parent is closed neutral and orchestration stops.
  - Mixed neutral-only levels prefer `closed no action`; duplicate-only levels close `closed duplicate`.
  - Rejected/failed/rollback behavior remains immediate hard-stop behavior.
- Generated `Kernel/Package/GovernanceDB-0.0.86.opm`.
- `Kernel/Package/GovernanceDB-0.0.86.opm` SHA256: `13EB11A2A8A95B755A095AB5358FC1EC14F9F4B057BE3F475A15832EA6DD8019`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.86.opm`.
- Retest template article rendering to confirm CKEditor boilerplate no longer appears.
- Retest Clone article rendering to confirm ticket references are readable.
- Retest a BlueLevel where mandatory tasks close only as duplicate/no-action; parent should close neutral instead of advancing.

### Next Priorities

- Install/upgrade 0.0.86, restart PSGI/web workers, then retest article display and neutral BlueBook completion.

## 2026-06-17 Customer Cancel / Platform Failsafe 0.0.87

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.87`.
- Repaired requester/customer cancel visibility and backend enforcement:
  - Cancel is no longer restricted to `Ticket.CustomerUserID == current user`.
  - Cancel now requires normal customer read permission on the root governance ticket and still excludes orchestration child tickets.
  - Cancel still respects configured root ticket types and closed-ticket protections.
- Repaired Cancel action menu usability:
  - Menu item now opens the runtime dialog, scrolls it into view, and focuses the first actionable field.
  - This prevents the top menu click from appearing to do nothing when the dialog is lower in the zoom page.
- Added ServiceLibrarian platform failsafe resolution:
  - Reads Application `ZTSMAppSystem-Platform`.
  - Reads Platform `ZTSMPlatform-ServiceSupportMap`.
  - Platform-offered ServiceSupportMaps score above generic service-only maps and below direct application matches.
  - Resolution article now shows whether Platform Failsafe was applied and lists the resolved platform context.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.87.opm`.
- `Kernel/Package/GovernanceDB-0.0.87.opm` SHA256: `4368BF6452757C26F18CFD6B5C5390C01DAD42B107F2A63D6DE5D65AEE2152A9`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.87.opm`.
- Retest Cancel from a customer user who has customer ticket access but is not the original `CustomerUserID`.
- Retest Cancel from the top action menu and confirm the cancellation remarks dialog opens and submits.
- Retest ServiceLibrarian for an Application with Platform `IaaS Extension`; platform ServiceSupportMaps such as `ICA-IAASEXT-...` should beat generic score-0 maps.

### Next Priorities

- Install/upgrade 0.0.87, restart PSGI/web workers, then retest cancel and platform failsafe resolution before moving back to clone/amend/template regression testing.

## 2026-06-17 Runtime Menu / Evidence Cleanup 0.0.88

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.88`.
- Moved `Amend` and `Clone` back under the header `...` action menu:
  - These remain runtime utility actions rather than primary next-step buttons.
- Repaired menu action behavior:
  - Dialog-opening menu actions now explicitly unhide the action dialog, set display back to block, close the `...` menu, scroll to the dialog, and focus the first actionable field.
  - `On Hold` and `Resume` now execute directly from the menu because they require no input.
  - `Cancel Ticket` and `Follow-up` still open their remarks dialogs.
- Repaired runtime evidence readability:
  - Amend articles now show readable parent and created-child ticket summaries instead of internal numeric IDs.
  - Follow-up articles now show readable original-child and created follow-up ticket summaries.
  - ChapterPlay initiation articles now show readable parent ticket summaries.
- Repaired mandatory outcome article display:
  - `Parent Outcome` now uses the `ZTicket-Outcome` key label such as `No Action` instead of raw values such as `1`.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.88.opm`.
- `Kernel/Package/GovernanceDB-0.0.88.opm` SHA256: `BDA56006DB9FC59A08F14B5A8BF3D12AAA08B4E5D7A9214ACA7853DC53B6E1E5`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.88.opm`.
- Retest `Cancel Ticket` from the menu and confirm the remarks dialog visibly opens.
- Retest `On Hold` from the menu and confirm it submits directly.
- Retest `Follow-up` from the menu and confirm the remarks dialog visibly opens.
- Retest Amend/Clone visibility and confirm both render only under `...`.
- Retest generated evidence articles for Amend, Follow-up, and mandatory neutral completion.

### Next Priorities

- Install/upgrade 0.0.88, restart PSGI/web workers, clear browser cache if the old menu JavaScript persists, then retest menu actions before further backend changes.

## 2026-06-17 Cancel Propagation / Task Runtime Repair 0.0.89

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.89`.
- Added requester cancel propagation for orchestration descendants:
  - Parent `Cancel Ticket` now closes/unlocks active child tickets that are clearly orchestration ledgers (`ZTicket-Parent` plus BlueBook/BlueLevel/Chapter markers).
  - Cloned/main request tickets are not swept up by this propagation.
  - Child cancellation articles include a readable parent ticket summary and the requester remarks.
- Repaired BlueBookReader runtime evidence references:
  - `ChapterPlay initiated` now shows a readable parent ticket summary.
  - Parent `BlueBook orchestration started` now lists created child tickets as readable ticket summaries instead of raw internal IDs.
- Repaired task runtime access for task-like tickets whose OTOBO Type falls back to `Assessment`:
  - CustomerTicketZoom now treats titles beginning `Task -` as task runtime ledgers for `Complete Task` visibility.
- Repaired requester-role assignment:
  - `ZTSMCharacterEngage` now snapshots `ZTicket-Owner` from the ticket requester when `ZTicket-Role` resolves to Requester, rather than selecting a support-assignment user.
- Synced changed runtime files across live source, package source, runtime overlay, PortedFromITSMConfigItem copies, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.89.opm`.
- `Kernel/Package/GovernanceDB-0.0.89.opm` SHA256: `95E684A8F77324C7E4481420F02BAA87BB0EF6955B686C92638C9DE6731DF91E`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.89.opm`: XML parsed successfully, version `0.0.89`, 155 file nodes, `MissingBase64=0`.
- Embedded runtime overlay hashes matched package-source runtime overlay copies for:
  - `CustomerTicketZTSMAction.pm`
  - `CustomerTicketZoom.pm`
  - `ZTSMBlueBookReader.pm`
  - `ZTSMCharacterEngage.pm`
- Perl syntax checks passed with `perl -I. -c` for the four changed runtime modules.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.89.opm`.
- Retest parent `Cancel Ticket` on an in-progress orchestration and confirm all active orchestration children close cancelled while cloned/main request tickets remain open.
- Retest Requester clarification/task records and confirm requester-role tickets assign to Whye Wong Tang and show `Complete Task`.
- Retest BlueBook articles and confirm created ticket references are readable ticket summaries, not raw numeric IDs.

### Next Priorities

- Install/upgrade 0.0.89, restart PSGI/web workers, and retest cancel propagation, requester task completion, and BlueBookReader evidence before continuing with deeper ChapterDirector behavior.

## 2026-06-17 Customer Request Defaults Preferences 0.0.90

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.90`.
- Added a customer preference group `CustomerPreferencesGroups###ZTSMRequestDefaults` labelled `Request defaults`.
- Added runtime overlay preference module `Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults`:
  - Renders customer-editable defaults for `ZUser-SupportProfile`, `ZUser-Application`, `ZUser-Environment`, and `ZUser-Location`.
  - Saves values directly to CustomerUser dynamic fields.
  - Uses `ValueDelete` when the customer clears a default.
  - Filters `ZUser-SupportProfile` options from SupportAssignment records matching the current customer user.
  - Allows Application, Environment, and Location selection from all Governance Objects in their respective classes.
- Added bootstrap installation/repair for the four CustomerUser GovernanceObject dynamic fields:
  - `ZUser-Location`
  - `ZUser-Application`
  - `ZUser-Environment`
  - `ZUser-SupportProfile`
- Updated `ZTSMRoleDirector` requester profile resolution:
  - Prefers `ZUser-SupportProfile`.
  - Falls back to legacy `ZTSMUser-DefaultSupportProfile`.
  - Reads dynamic field values directly when the CustomerUser backend map does not expose them.
- Added the new preference module to the SOPM file list.
- Generated `Kernel/Package/GovernanceDB-0.0.90.opm`.
- `Kernel/Package/GovernanceDB-0.0.90.opm` SHA256: `1A29F9FA012B575DD9198DA9647555248F684913C469A45070153475250F0723`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.90.opm`: XML parsed successfully, version `0.0.90`, 156 file nodes, `MissingBase64=0`.
- Confirmed `var/governancedb/runtime_overlay/Kernel/Output/HTML/Preferences/ZTSMCustomerDefaults.pm` is embedded in the generated OPM.
- Perl syntax checks passed with `perl -I. -c` for:
  - `Kernel/System/GovernanceDB/Bootstrap.pm`
  - `Kernel/Output/HTML/Preferences/ZTSMCustomerDefaults.pm`
  - Runtime overlay ProcessManagement `ZTSMRoleDirector.pm`
  - Runtime overlay GenericAgent `ZTSMRoleDirector.pm`

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.90.opm`.
- Retest `CustomerPreferences` and confirm the `Request defaults` card appears.
- Retest support profile options using a customer user with multiple SupportAssignment records.
- Retest requester-role orchestration to confirm `ZUser-SupportProfile` is used as the requester default support profile.

### Next Priorities

- Install/upgrade 0.0.90, restart PSGI/web workers, and retest customer preference defaults end-to-end.

## 2026-06-17 Customer Request Hydration / Follow-up Ownership Design

### Architectural Decisions

* Customer request defaults are requester convenience values, not governance truth.
* Customer defaults are stored on the CustomerUser object through:

  * `ZUser-Application`
  * `ZUser-Environment`
  * `ZUser-Location`
  * `ZUser-SupportProfile`
* Request defaults should automatically hydrate new root governance requests during customer ticket creation.
* Hydration occurs only when the ticket field is empty; explicitly supplied ticket values always win.
* User defaults are snapshots at request creation time and must not remain linked to the CustomerUser record after ticket creation.
* Follow-up remains a runtime corrective execution action and not a StateBook transition.
* Follow-up child tickets inherit execution ownership context from the initiating child ticket.
* PurpleBook execution must preserve ownership continuity so the initiating owner can continue the corrective workflow without reassignment surprises.
* Successful PurpleBook completion returns the original child ticket to its previous execution owner and execution group.

### Completed Design

#### Customer Request Default Hydration

When a new customer request is created:

* `ZUser-Application` hydrates `ZTicket-Application`.
* `ZUser-Environment` hydrates `ZTicket-Env`.
* `ZUser-Location` hydrates `ZTicket-Location`.
* `ZUser-SupportProfile` remains requester preference context and is not automatically written to execution ownership fields.

#### Multi-Value Handling

Customer preference fields are currently single-select.

Ticket fields may be multi-select.

Hydration rules:

* Single → Single:

  * Copy value directly.
* Single → Multi:

  * Wrap value as a single-item array.
* Empty User Value:

  * Do not write ticket value.
* Existing Ticket Value:

  * Do not overwrite.

Example:

Customer:

* `ZUser-Location = Singapore DC`

Ticket:

* `ZTicket-Location` supports multiple values

Result:

* `["Singapore DC"]`

#### Follow-up Ownership Propagation

When Follow-up is executed:

Source Child Ticket:

* `ZTicket-Owner`
* `ZTicket-OwnerGroup`

must be copied to newly created PurpleBook child tickets.

This preserves:

* Visibility
* Ownership continuity
* Runtime action permissions
* Corrective execution accountability

#### Follow-up Return Ownership

When PurpleBook execution completes successfully:

* Original child ticket returns to `in-progress`.
* Original child ticket retains:

  * `ZTicket-Owner`
  * `ZTicket-OwnerGroup`

PurpleBook completion must not:

* Reassign ownership.
* Clear ownership.
* Replace ownership with PurpleBook executor values.

### Rejected Approaches

* Do not force customers to repeatedly select Application, Environment, and Location for every request when defaults already exist.
* Do not overwrite explicitly supplied ticket values using CustomerUser defaults.
* Do not link tickets dynamically back to CustomerUser defaults after ticket creation.
* Do not create new ownership fields for PurpleBook execution.
* Do not recalculate ownership during PurpleBook return.
* Do not transfer ownership to the last PurpleBook executor when returning to the original child ticket.

### Next Priorities

* Implement CustomerTicketMessage hydration from CustomerUser defaults.
* Verify single-value to multi-value field conversion behavior.
* Verify new customer requests receive default Application, Environment, and Location values.
* Verify Follow-up child tickets inherit Owner and OwnerGroup.
* Verify PurpleBook successful completion returns original child tickets to the same Owner and OwnerGroup.
* Verify all runtime action visibility rules continue to function after ownership propagation.

## 2026-06-18 Customer Request Hydration / Follow-up Ownership 0.0.91

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.91`.
- Implemented CustomerTicketMessage request-default hydration:
  - `ZUser-Application` hydrates empty `ZTicket-Application`.
  - `ZUser-Environment` hydrates empty `ZTicket-Env`.
  - `ZUser-Location` hydrates empty `ZTicket-Location`.
  - Explicit ticket values still win.
  - `ZUser-SupportProfile` remains requester preference context and is not written to execution ownership fields.
- Added single-value to multi-value wrapping when the target ticket Dynamic Field is configured as multi-value.
- Added Follow-up ownership propagation:
  - Follow-up PurpleBook children inherit `ZTicket-Owner` from the initiating child.
  - Follow-up PurpleBook children inherit `ZTicket-OwnerGroup` from the initiating child.
  - Normal BlueBook child spawning remains unchanged unless ownership overrides are passed.
- Generated `Kernel/Package/GovernanceDB-0.0.91.opm`.
- `Kernel/Package/GovernanceDB-0.0.91.opm` SHA256: `1F90FE05B945A89AA4C7737FEAFF3EC7E0C0F30A68D544832819123B400CB68E`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.91.opm`: XML parsed successfully, version `0.0.91`, 156 file nodes, `MissingBase64=0`.
- Embedded runtime overlay hashes matched package-source runtime overlay copies for:
  - `CustomerTicketMessage.pm`
  - `CustomerTicketZTSMAction.pm`
  - `ZTSMBlueBookRuntime.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for:
  - `Kernel/Modules/CustomerTicketMessage.pm`
  - `Kernel/Modules/CustomerTicketZTSMAction.pm`
  - `Kernel/System/ZTSMBlueBookRuntime.pm`

### Architectural Decisions

- Latest package field authority uses `ZTicket-Env`, not `ZTicket-Environment`.
- Customer defaults are creation-time snapshots only; they do not create a live dependency on the CustomerUser defaults after ticket creation.
- PurpleBook ownership inheritance is scoped to Follow-up child spawning and does not alter the successful return path, which only moves the original child ticket back to `in-progress`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.91` package.
- Verify CustomerTicketMessage creates new requests with defaults when Application, Environment, and Location are left empty.
- Verify explicit CustomerTicketMessage values are not overwritten by CustomerUser defaults.
- Verify Follow-up PurpleBook children inherit `ZTicket-Owner` and `ZTicket-OwnerGroup`.

### Next Priorities

- Install/upgrade 0.0.91, restart PSGI/web workers, and retest request-default hydration plus Follow-up ownership propagation.

## 2026-06-18 BlueLevel GeneralCatalog Repair 0.0.92

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.92`.
- Repaired BlueBook BlueLevel parsing for GeneralCatalog-backed values:
  - `ZBlue-BlueLevel`, `ZBlue-Level`, and `ZBlue-Seq` now resolve GeneralCatalog item IDs back to their item names before runtime use.
  - Example: raw GeneralCatalog item ID `207` resolves to BlueLevel value `1`.
- Applied the repair in both:
  - `ZTSMBlueBookReader`
  - `ZTSMBlueBookRuntime`
- This fixes both stored execution context (`ZTicket-BlueLevel`) and generated evidence article display for BlueBook orchestration and ChapterPlay initiation.
- Generated `Kernel/Package/GovernanceDB-0.0.92.opm`.
- `Kernel/Package/GovernanceDB-0.0.92.opm` SHA256: `2AA627296194A6BC6106DD12F9445B2BB506C3818DDE85E5F620F34CD751CDA9`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.92.opm`: XML parsed successfully, version `0.0.92`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across live source, package source, runtime overlay, and ZTSMOverlay copies for:
  - `ZTSMBlueBookReader.pm`
  - `ZTSMBlueBookRuntime.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for:
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `Kernel/System/ZTSMBlueBookRuntime.pm`

### Architectural Decisions

- BlueLevel remains runtime choreography data sourced from BlueBook records.
- GeneralCatalog IDs must not leak into ticket evidence articles when the catalog item name is the operational value.
- The fix resolves values at parse time so sorting, child-ticket matching, ticket field storage, and evidence rendering all use the same runtime value.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.92` package.
- Retest BlueBook orchestration article generation and confirm `BlueLevel` displays `1` rather than the raw GeneralCatalog item ID such as `207`.

### Next Priorities

- Install/upgrade 0.0.92, restart PSGI/web workers, and retest BlueBook orchestration from a BlueBook record whose BlueLevel is stored as a GeneralCatalog item ID.

## 2026-06-18 Requester Owner Workspace Repair 0.0.93

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.93`.
- Updated CustomerTicketMessage creation so new customer-created tickets snapshot the requester into `ZTicket-Owner` when `ZTicket-Owner` is empty.
- Hardened `CustomerDashboard::TileTicketList` workspace lookup:
  - Workspace tickets continue to resolve through SupportAssignment / `ZTicket-OwnerGroup`.
  - Workspace tickets also resolve through direct `ZTicket-Owner`.
  - Direct-owner lookup now checks both the dashboard `UserID` and `UserLogin` identity forms.
- Synced changed files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.93.opm`.
- `Kernel/Package/GovernanceDB-0.0.93.opm` SHA256: `A1C10FCAB0935A54D4FCDEF60E9C5C02DC846A49886C6775CE37D6994B795AEE`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.93.opm`: XML parsed successfully, version `0.0.93`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across live source, package source, runtime overlay, and ZTSMOverlay copies for:
  - `CustomerTicketMessage.pm`
  - `TileTicketList.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for:
  - `Kernel/Modules/CustomerTicketMessage.pm`
  - `Kernel/Output/HTML/CustomerDashboard/TileTicketList.pm`

### Architectural Decisions

- Requester ownership on ticket creation is execution visibility context, not governance truth.
- `ZTicket-Owner` is set only when empty so explicit/runtime assignment is preserved.
- Customer workspace visibility is inclusive: SupportAssignment participation OR direct ticket ownership.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.93` package.
- Retest new requester-created tickets and confirm they appear in the requester workspace.
- Retest Follow-up PurpleBook child tickets and confirm they appear for the direct `ZTicket-Owner`.

### Next Priorities

- Install/upgrade 0.0.93, restart PSGI/web workers, and retest the customer dashboard workspace tile for requester-created tickets and Follow-up children.

## 2026-06-18 Follow-up BlueLevel Compatibility Repair 0.0.94

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.94`.
- Restored Follow-up action visibility for tickets created before the BlueLevel GeneralCatalog repair:
  - BlueBook record parsing now preserves both resolved `BlueLevel` and original `RawBlueLevel`.
  - `CustomerTicketZoom` Follow-up visibility matches the ticket `ZTicket-BlueLevel` against either representation.
  - `CustomerTicketZTSMAction` Follow-up execution uses the same compatibility match.
  - `ZTSMBlueBookRuntime` template lookup also matches either representation for existing tickets.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.94.opm`.
- `Kernel/Package/GovernanceDB-0.0.94.opm` SHA256: `B5E79848451658ACE747A64DCD3E6E81F2C5EDB49E8A3F28FDAEEB03F0F80BCC`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.94.opm`: XML parsed successfully, version `0.0.94`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across live source, package source, runtime overlay, and ZTSMOverlay copies for:
  - `CustomerTicketZoom.pm`
  - `CustomerTicketZTSMAction.pm`
  - `ZTSMBlueBookRuntime.pm`
  - `ZTSMBlueBookReader.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for the four changed runtime modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- BlueLevel GeneralCatalog IDs remain repaired to readable operational values for new execution context and evidence.
- Existing tickets that already stored the raw GeneralCatalog item ID remain valid runtime execution ledgers and must still expose Follow-up when their BlueBook record contains `ZBlue-PurpleBook`.
- Compatibility is handled in matching logic; no new Dynamic Fields or governance recalculation are introduced.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.94` package.
- Retest an existing Assessment ticket whose `ZTicket-BlueLevel` is a raw GeneralCatalog item ID such as `207` and confirm `Follow-up` appears in the header action menu.

### Next Priorities

- Install/upgrade 0.0.94, restart PSGI/web workers, and retest Follow-up visibility plus submission on the affected Assessment ticket.

## 2026-06-18 Follow-up Pause / Requester Default Assignment Repair 0.0.95

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.95`.
- Tightened Follow-up pause behavior:
  - `CustomerTicketZoom` now hides customer runtime execution actions when the original child ticket state is `follow-up`.
  - `CustomerTicketZTSMAction` now blocks direct runtime execution submissions while the ticket state is `follow-up`.
  - The original Assessment child remains paused until PurpleBook completion returns it to `in-progress`.
- Corrected Follow-up PurpleBook ownership spawning:
  - Follow-up child tickets no longer receive a blanket `OwnerOverride` / `OwnerGroupOverride` from the initiating child.
  - PurpleBook child assignment now follows the child BlueBook record profile and role path.
- Repaired Requester Default assignment in both RoleDirector paths:
  - If requester `ZUser-SupportProfile` is populated, RoleDirector assigns it to `ZTicket-OwnerGroup`.
  - If requester `ZUser-SupportProfile` is empty, RoleDirector assigns the requester CustomerUserID to `ZTicket-Owner`.
  - GenericAgent RoleDirector no longer skips requester-default repair just because an OwnerGroup is already present.
- Synced changed runtime files across live source, package source, runtime overlay, PortedFromITSMConfigItem, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.95.opm`.
- `Kernel/Package/GovernanceDB-0.0.95.opm` SHA256: `F887611CE3AB821E2E598A0D1AE1E28DF28EFB8D7C126872A8F87C5709F8E4DC`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.95.opm`: XML parsed successfully, version `0.0.95`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across all mirror copies for:
  - `CustomerTicketZoom.pm`
  - `CustomerTicketZTSMAction.pm`
  - `Kernel/System/GenericAgent/ZTSMRoleDirector.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMRoleDirector.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for the four changed runtime modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- `follow-up` is a corrective execution pause for the original child ticket, not an active Assessment submission state.
- PurpleBook child assignment should be resolved by the child BlueBook record through RoleDirector, not copied wholesale from the initiating child.
- Requester Default means requester preference first, direct requester ownership second:
  - `ZUser-SupportProfile` present -> `ZTicket-OwnerGroup`.
  - `ZUser-SupportProfile` empty -> `ZTicket-Owner`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.95` package.
- Retest Follow-up on an Assessment child and confirm `Submit Assessment` / `Reject` disappear while the ticket is in `follow-up`.
- Retest the PurpleBook `Clarification Required` Task and confirm Requester Default assignment resolves to the requester support profile or requester CustomerUserID according to `ZUser-SupportProfile`.

### Next Priorities

- Install/upgrade 0.0.95, restart PSGI/web workers, and retest Follow-up pause plus requester clarification ownership end-to-end.

## 2026-06-18 GovernanceRole Requester Default Code Repair 0.0.96

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.96`.
- Corrected RoleDirector requester-default directive handling:
  - BlueBook `Profile` continues to resolve to either SupportProfile or GovernanceRole.
  - GovernanceRole `ZTSM-Code` / name such as `Requester Default` now normalizes to `REQUESTER-DEFAULT`.
  - RoleDirector now treats `REQUESTER-DEFAULT` as the requester-default branch.
  - Legacy `REQUESTER-SUPPORT-GROUP` remains accepted only as a backward-compatible alias.
- Applied the correction in both RoleDirector paths:
  - `Kernel/System/GenericAgent/ZTSMRoleDirector.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMRoleDirector.pm`
- Synced changed runtime files across live source, package source, runtime overlay, PortedFromITSMConfigItem, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.96.opm`.
- `Kernel/Package/GovernanceDB-0.0.96.opm` SHA256: `9F515FB791E9983A5ADFE03BB5EE054B655B198E06455CDF7E43AA100737DE86`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.96.opm`: XML parsed successfully, version `0.0.96`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across all RoleDirector mirror copies.
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for both RoleDirector modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- BlueBook `ZBlue-Profile` points to a GovernanceRole or SupportProfile.
- GovernanceRole `ZTSM-Code` is the behavior contract; names/codes such as `Requester Default` must drive requester-default assignment directly.
- `APP-PROFILE` and related directive keys are legacy normalized internal aliases, not values invented from BlueBook. The requester-default path must not depend on those aliases.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.96` package.
- Retest the GenericAgent log and confirm `Unsupported governance profile: Requester Default` no longer appears.
- Retest the PurpleBook `Clarification Required` Task requester-default assignment.

### Next Priorities

- Install/upgrade 0.0.96, restart PSGI/web workers, and rerun the Follow-up clarification flow.

## 2026-06-18 Task-Like Take Ownership Visibility Repair 0.0.97

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.97`.
- Repaired customer portal `Take Ownership` visibility for task-like execution tickets:
  - `CustomerTicketZoom` now treats task-like tickets as ownership-actionable even when they do not expose normal assessment/approval outcome actions.
  - Task-like detection continues to support real Ticket Type `Task` and fallback titles beginning `Task -`.
- Repaired backend submission validation:
  - `CustomerTicketZTSMAction` now accepts `TakeOwnership` for the same task-like ticket definition.
- Preserved support-assignment authorization:
  - Customer users still need `ztsm_action` access through direct ownership or SupportAssignment participation in `ZTicket-OwnerGroup`.
  - A requester who is not in the ICS Support Team SupportAssignment can still reply, but cannot take ICS ownership.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.97.opm`.
- `Kernel/Package/GovernanceDB-0.0.97.opm` SHA256: `C0EECD9E1E431305AB5E10D8FD1BBC00E1F491CB82141D927AF49C4821397AAB`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.97.opm`: XML parsed successfully, version `0.0.97`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across all `CustomerTicketZoom.pm` and `CustomerTicketZTSMAction.pm` mirror copies.
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for both changed customer modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- Ownership claim is a runtime execution action for task-like ledgers and should not depend on the normal assessment/approval outcome-action list.
- Support Assignment remains the authorization boundary for taking ownership of a SupportProfile-owned task.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.97` package.
- Retest with a customer user who has SupportAssignment membership in `ICS Support Team` and confirm `Take Ownership` appears.
- Retest with the requester account if it is not an ICS Support Team member and confirm it can reply but cannot take ownership.

### Next Priorities

- Install/upgrade 0.0.97, restart PSGI/web workers, and retest ownership claim on the clarification task.
