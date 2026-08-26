# TESSERA / ZTSM Architecture

## Core Philosophy

- Book defines governance truth
- Process orchestrates runtime
- Ticket represents execution evidence
- StateBook controls lifecycle choreography
- BlueBook controls execution choreography

## Dynamic Field Naming

- ZTicket-*
- ZBlue-*
- ZState-*
- ZTSMServiceSupportMap-*

Never invent field names.

## Important Runtime Principles

- Parent ticket is governance ledger
- Child ticket is execution ledger
- Governance snapshots are immutable after orchestration starts

## OTOBO Extension Rules

- Avoid hardcoding workflow routing
- Resolve governance from CMDB objects
- Use TransitionAction modules whenever possible

## Key Modules

- ZTSMServiceLibrarian
- ZTSMStateBookReader
- ZTSMBlueBookReader

## UI Principles

- Portal-first interaction
- CustomerTicketZoom is runtime interaction surface
- ActivityDialog preferred over hardcoded buttons

## Current Known Areas

- DynamicField Set rendering bypasses Row_DynamicField
- Customer process actions injected dynamically into TicketZoom

## Customer Portal ConfigItem Entitlement and Asset Access Contract

### Purpose

Customer portal ConfigItem access is a new TESSERA feature. Customer users must not be able to discover or access assets merely because the ConfigItem customer frontend exists.

### Authoritative Export Model

Use the latest GovernanceObject, ConfigItem, and DynamicField exports before implementation.

The current exported model includes:

- ConfigItem class `ContractEntitlement`
- ConfigItem field `ZTAM-ContractEntitlement`
- ConfigItem field `ZTAM-SupportProfile`
- ContractEntitlement field `Contract-ServiceProfile`
- ContractEntitlement field `Contract-Coverage`
- ContractEntitlement field `Contract-SupportProfie`
- SupportAssignment field `ZTSMSupportAssignment-UserAccount`
- SupportAssignment field `ZTSMSupportAssignment-SupportProfile`
- SupportAssignment field `ZTSMSupportAssignment-Role`

`Contract-SupportProfie` is the exact current exported field name. Do not silently rename or correct it in code.

### Discovery and Selection Boundary

`ContractEntitlement` points to the applicable SupportProfile.

A CustomerUser may discover, list for selection, filter, or search only ConfigItems whose SupportProfile is covered by a ContractEntitlement and for which that CustomerUser has the corresponding SupportAssignment.

This entitlement boundary must be applied server-side to every customer-facing ConfigItem lookup path, including request selection, autocomplete, filtering, searching, direct listing, and equivalent APIs.

A ConfigItem outside this boundary must not be returned or disclosed, regardless of URL manipulation, request parameters, alternate portal paths, or direct object identifiers.

### Detail Visibility Boundary

Discovery permission and full detail permission are separate concerns.

A CustomerUser who is entitled to discover a ConfigItem may view the ConfigItem's full information in the customer frontend portal only when the matching SupportAssignment uses GovernanceRole `TESSERA::CMDB::READ`.

`TESSERA::CMDB::READ` is the reserved customer-portal CMDB read capability. It does not grant API access or ConfigItem create, update, or delete access. Customer-originated CMDB changes must continue through ticket workflow.

Without the matching `TESSERA::CMDB::READ` SupportAssignment role, entitlement may permit the ConfigItem to appear as a selectable or searchable request target, but it must not grant access to the customer ConfigItem detail view or its full data.

GovernanceRole namespace contract:

- `PLATFORM::*`, `APPLICATION::*`, and `TICKET::*` may contain ScriptEngine resolution programs.
- `SUPPORT::*` are assignment classifications and do not contain resolver programs.
- `TESSERA::*` are reserved system capabilities. They are not customizable resolution roles and must never execute GovernanceRole resolver scripts.
- Authoritative exported GovernanceRole objects are create-if-missing bootstrap defaults. Existing GovernanceRole objects remain administrator-owned and are not overwritten.

### Security and Architecture Rules

- Enforce both boundaries in backend permission/search logic; UI hiding alone is insufficient.
- Default to no access when ContractEntitlement, SupportProfile, SupportAssignment, CustomerUser, or GovernanceRole resolution is missing or ambiguous.
- Do not broaden ConfigItem visibility through customer company membership alone.
- Do not treat `ZTAM-Owner`, ticket participation, or possession of a ConfigItem ID as entitlement.
- Reuse the exported objects and Dynamic Fields; never invent replacement field names.
- Preserve the separation between governance truth, entitlement scope, operational assignment, and ticket execution evidence.
- Design installation and upgrades idempotently for existing and fresh environments.

### Next Implementation Direction

The next work session should begin with read-only tracing of every customer ConfigItem search, selection, filter, list, zoom, and direct-access path. Then establish one centralized permission service used consistently by all paths before adding portal UI.


## Risk Assessment Workspace Design

Purpose:
Replace generic CustomerTicketZoom assessment rendering.

Storage:
Uses existing ZRM-* Dynamic Fields.

Presentation:
Hardcoded Risk Assessment table.

Submission:
Updates Dynamic Fields and generates article snapshot.

GeneralCatalog:
Always resolve names before rendering or writing article.

Assessment Structure:
Category
Risk Category
Risk Statement
Risk Detail
Inherent Likelihood
Inherent Impact
Inherent Calculated Risk
Risk Action
Risk Plan
Residual Likelihood
Residual Impact
Residual Calculated Risk

Targets:
Render CI and Governance Objects separately.

Non-Goals:
Do not use DynamicFieldSet renderer.
Do not use generic ticket rendering.
Do not store catalog IDs in article.

## Requester Hold / Resume Design Contract

### Purpose

Requester Hold allows the requester to temporarily pause execution of a ticket as long StateType != 'closed'

Requester Hold is an execution action.

Requester Hold is NOT a StateBook transition.

Requester Hold is NOT a BlueBook transition.

Requester Hold must not alter governance state, lifecycle position, orchestration state, or governance snapshots.

---

### Dynamic Field

#### ZTicket-HoldState

Purpose:

Stores the ticket state before the ticket is moved to On Hold.

Type:

Text

Example:

```text
open
pending approval
in progress
assigned
```

State names shall be stored rather than StateIDs.

This field is used exclusively for Resume operations.

---

## Requester Hold Action

### Parent Ticket Behaviour

When Requester Hold is selected:

1. Read current ticket state.
2. Store current state into ZTicket-HoldState.
3. Change ticket state to On Hold.
4. Create ticket article.

Article Example:

```text
Requester has placed this ticket On Hold.

Execution has been paused pending requester instruction.

No lifecycle transition has occurred.
```

---

### Child Ticket Behaviour

All active child tickets shall be processed.

For each child ticket:

1. Read current child ticket state.
2. Store state into child ZTicket-HoldState.
3. Change child ticket state to On Hold.
4. Create child ticket article.

Article Example:

```text
Requester has placed the parent ticket On Hold.

Execution has been paused pending requester instruction.

Parent Ticket: <Parent Ticket Number>
```

---

## StateBook Behaviour

Requester Hold is NOT a lifecycle transition.

The following modules must NOT execute:

* ZTSMStateBookReader
* ZTSMBlueBookReader
* Transition Validation Modules
* Transition Action Modules
* Chapter Evaluation Logic
* Orchestration Logic

No governance re-evaluation shall occur.

No lifecycle movement shall occur.

No chapter execution shall occur.

---

## Lifecycle Preservation

The following values must remain unchanged:

* ZState-CurrentStage
* ZState-CurrentState
* ZBlue-CurrentChapter

These values represent the current governance snapshot and execution position.

Requester Hold must not modify them.

---

## Resume Action

### Parent Ticket Behaviour

When Resume is selected:

1. Read ZTicket-HoldState.
2. Restore ticket state using stored value.
3. Clear ZTicket-HoldState.
4. Create ticket article.

Article Example:

```text
Requester has resumed ticket execution.

Execution continues from the existing lifecycle position.

No lifecycle transition has occurred.
```

---

### Child Ticket Behaviour

For each child ticket:

1. Read child ZTicket-HoldState.
2. Restore original child state.
3. Clear child ZTicket-HoldState.
4. Create ticket article.

Article Example:

```text
Requester has resumed the parent ticket.

Execution continues from the existing lifecycle position.

Parent Ticket: <Parent Ticket Number>
```

---

## Resume Behaviour

Resume is NOT a lifecycle transition.

Resume is NOT a StateBook transition.

Resume is NOT a BlueBook transition.

Resume restores execution state only.

The following modules must NOT execute:

* ZTSMStateBookReader
* ZTSMBlueBookReader
* Transition Validation Modules
* Transition Action Modules

Resume shall not:

* Recalculate completed chapters
* Recreate child tickets
* Rebuild governance snapshots
* Restart orchestration

Execution continues from the exact lifecycle position that existed before the ticket was placed On Hold.

---

## Architectural Principle

Governance state and execution state are separate concerns.

Requester Hold pauses execution.

Requester Resume restores execution.

Neither action changes governance truth.

Neither action changes StateBook position.

Neither action changes BlueBook position.

Only ticket state is modified.

# TESSERA Development Rules (Critical)

## Package Versioning Rule

GovernanceDB `0.0.x` patch builds must stop at `0.0.365`.

After `0.0.365`, the next GovernanceDB package version must be `0.1.0`, not `0.0.366`.

Future patch builds after that must increment from the `0.1.x` line unless a newer project decision changes the version series.

---

## Source of Truth Priority

When generating, modifying, or rebuilding code:

Priority order MUST be:

1. Latest `.sopm`
2. Latest generated `.opm`
3. Current repository source code
4. Current architecture documents
5. Historical context files

Historical examples, legacy implementations, and deprecated architecture MUST NOT override the latest build artifacts.

---

## Upgrade-Safe Development

All generated code MUST support:

* Fresh installation
* Package upgrade installation
* Reinstallation of same version
* Future version upgrades

Implementation MUST NOT assume a clean environment.

Whenever configuration, DynamicFields, SysConfig, Processes, ACLs, or ConfigItems are introduced:

* Upgrade path must be considered.
* Existing data must be preserved where possible.
* Installation must be idempotent.
* Repeated package installation must not create duplicate records.

---

## OPM / SOPM Authority

The latest `.sopm` and generated `.opm` represent the authoritative package definition.

If generated code, Perl modules, XML definitions, YAML exports, AGENTS instructions, or documentation conflict with the latest package definition:

The latest `.sopm` and `.opm` take precedence.

Do NOT regenerate package structure from historical assumptions.

Do NOT infer removed objects, DynamicFields, ConfigItems, or workflows from previous versions.

---

## Architecture Evolution Rule

TESSERA architecture evolves continuously.

Deprecated patterns must not be reintroduced.

Examples of deprecated assumptions include:

* Static queue routing
* Hardcoded approval routing
* OwnerGroup resolution from Service Support Map
* ApprovalGroup resolution from Service Support Map
* ZTicket-Profile ownership assumptions
* Legacy governance field mappings

Always validate implementation against the latest architecture before generating code.

---

## Runtime Governance Rule

Books define truth.
Process orchestrates runtime.
Tickets contain execution evidence.

Code generation must follow current TESSERA architecture:

ServiceSupportMap
→ resolves governance applicability

StateBook
→ resolves lifecycle choreography

BlueBook
→ resolves execution choreography

Support Assignment
→ resolves actual operational scope

Never collapse these responsibilities into a single module.

---

## Backward Compatibility Rule

Where architecture changes occur:

* Preserve upgradeability whenever practical.
* Add migration logic when required.
* Do not silently remove previously deployed structures.
* Prefer controlled deprecation over destructive replacement.

All package changes should be installable on both:

* Existing upgraded environments
* Brand new environments

without manual intervention.

## Mandatory Project Continuity Rule

Before performing any analysis, design, code generation, refactoring, or implementation:

1. Read AGENTS.md
2. Read PROJECT_STATUS.md
3. Read latest SOPM
4. Read latest generated OPM
5. Read PROJECT_NEXT.md

PROJECT_STATUS.md is the authoritative project memory.

Whenever a significant change is made:

* Update completed work
* Update current focus
* Record architectural decisions
* Record rejected approaches
* Record known issues
* Record next priorities

Future sessions must continue from PROJECT_STATUS.md rather than reconstructing history from chat context.

Do not assume previous conversation history is available.

PROJECT_NEXT.md is out of codex design features. 

It contain all the design decision, and different constraint. Once it comfirmed implemented, it should clean up the PROJECT_NEXT.md and recorded under PROJECT_STATUS.md istead. 

# TESSERA Development Rules (Critical)

## Package Versioning Rule

GovernanceDB `0.0.x` patch builds must stop at `0.0.365`.

After `0.0.365`, the next GovernanceDB package version must be `0.1.0`, not `0.0.366`.

Future patch builds after that must increment from the `0.1.x` line unless a newer project decision changes the version series.

---

## Source of Truth Priority

When generating, modifying, or rebuilding code:

Priority order MUST be:

1. Latest `.sopm`
2. Latest generated `.opm`
3. Current repository source code
4. Current architecture documents
5. Historical context files

Historical examples, legacy implementations, and deprecated architecture MUST NOT override the latest build artifacts.

---

## Upgrade-Safe Development

All generated code MUST support:

* Fresh installation
* Package upgrade installation
* Reinstallation of same version
* Future version upgrades

Implementation MUST NOT assume a clean environment.

Whenever configuration, DynamicFields, SysConfig, Processes, ACLs, or ConfigItems are introduced:

* Upgrade path must be considered.
* Existing data must be preserved where possible.
* Installation must be idempotent.
* Repeated package installation must not create duplicate records.

---

## OPM / SOPM Authority

The latest `.sopm` and generated `.opm` represent the authoritative package definition.

If generated code, Perl modules, XML definitions, YAML exports, AGENTS instructions, or documentation conflict with the latest package definition:

The latest `.sopm` and `.opm` take precedence.

Do NOT regenerate package structure from historical assumptions.

Do NOT infer removed objects, DynamicFields, ConfigItems, or workflows from previous versions.

---

## Architecture Evolution Rule

TESSERA architecture evolves continuously.

Deprecated patterns must not be reintroduced.

Examples of deprecated assumptions include:

* Static queue routing
* Hardcoded approval routing
* OwnerGroup resolution from Service Support Map
* ApprovalGroup resolution from Service Support Map
* ZTicket-Profile ownership assumptions
* Legacy governance field mappings

Always validate implementation against the latest architecture before generating code.

---

## Runtime Governance Rule

Books define truth.
Process orchestrates runtime.
Tickets contain execution evidence.

Code generation must follow current TESSERA architecture:

ServiceSupportMap
→ resolves governance applicability

StateBook
→ resolves lifecycle choreography

BlueBook
→ resolves execution choreography

Support Assignment
→ resolves actual operational scope

Never collapse these responsibilities into a single module.

---

## Backward Compatibility Rule

Where architecture changes occur:

* Preserve upgradeability whenever practical.
* Add migration logic when required.
* Do not silently remove previously deployed structures.
* Prefer controlled deprecation over destructive replacement.

All package changes should be installable on both:

* Existing upgraded environments
* Brand new environments

without manual intervention.

## TESSERA UI Engineering Standard
A UI patch is not accepted just because it looks correct. It must also preserve DOM simplicity, component clarity, CSS ownership, responsiveness, accessibility, and maintainability.
