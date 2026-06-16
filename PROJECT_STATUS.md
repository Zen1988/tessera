# TESSERA Project Status

Last Updated: 2026-06-16

## Current Focus

- Customer runtime execution actions on `CustomerTicketZoom`.
- Runtime stakeholder injection for active execution child tickets.
- Runtime duplication of a parent governance request for an additional external party.
- BlueBook neutral closure handling for `closed no action` and `closed duplicate`.
- Assessor Assessment task outcomes on `CustomerTicketZoom`.
- Implementer Task completion outcome handling on `CustomerTicketZoom`.
- Mandatory BlueBook outcome roll-up using `ZTicket-Outcome`.
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

## Known Issues / Follow-Up

- `PROJECT_STATUS.md` was empty before this update; older project memory is not present here.
- The current action hardcodes allowed Ticket Types in module defaults. Move to SysConfig or governance object control later if needed.
- Latest generated OPM is `Kernel/Package/GovernanceDB-0.0.72.opm`.
- Runtime verification is still needed for the target service list and external-party request clone flow inside OTOBO.
- Runtime verification is still needed for sole mandatory `closed no action` / `closed duplicate` propagation.
- Runtime verification is still needed that only the Assessment owner sees and can submit `Submit Assessment`, `Close Duplicate`, and `Close No Action`.
- Runtime verification is still needed that only the Task owner sees and can submit `Complete Task`.
- Runtime verification is still needed for Task attachment upload into the generated article.
- Runtime verification is still needed for parent `ZTicket-Outcome` roll-up across mandatory BlueLevel children.

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
- Install or upgrade using `Kernel/Package/GovernanceDB-0.0.72.opm` and perform runtime verification.
- Consider adding SysConfig for `AddRequiredSupportProfileTypes` after the hardcoded behavior is accepted.
