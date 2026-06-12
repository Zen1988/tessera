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
