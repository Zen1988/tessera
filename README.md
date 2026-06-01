# TESSERA

![TESSERA logo](docs/logo/TESSERA_LOGO_v2.svg)

TESSERA is a governed workflow operating platform built on top of OTOBO. It extends the customer portal, ticket runtime, process management, and CMDB-style configuration model into a governance-driven orchestration layer called ZTSM.

TESSERA is not a replacement for OTOBO. It is an overlay architecture for turning OTOBO into a portal-first service governance platform.

## Core Philosophy

TESSERA separates governance truth from runtime execution:

| Layer | Responsibility |
|---|---|
| Book | governed operational truth |
| Process | runtime orchestration engine |
| Ticket | execution evidence and audit trail |
| StateBook | lifecycle choreography |
| BlueBook | execution choreography |

The parent ticket acts as the governance ledger. Child tickets act as execution ledgers. Governance is resolved from Book/CMDB objects and then snapshotted onto tickets so runtime execution remains auditable.

## ZTSM Runtime Model

ZTSM uses a book-and-story model:

- `StateBook` controls the lifecycle story: validate, assess, approve, implement, verify, close.
- `BlueBook` controls execution inside a lifecycle stage.
- `BlueLevel` groups parallel or sequential execution chapters.
- Child tickets represent chapter work, approval work, assessment work, or implementation work.
- Runtime actions are exposed through the customer portal wherever possible.

The intended runtime flow is:

```text
Service Support Map
  -> resolve StateBook
  -> StateBookReader
  -> resolve lifecycle stage
  -> BlueBookReader
  -> spawn and coordinate child execution tickets
  -> validate BlueLevel completion
  -> BlueBookDirector advances or exits
  -> StateBookReader resumes lifecycle progression
```

## Repository Layout

```text
Kernel/
  OTOBO source tree with TESSERA/ZTSM custom modules applied

ZTSMOverlay/
  Portable overlay for applying TESSERA customizations to an OTOBO release

docs/architecture/
  Architecture notes for governance, orchestration, portal interaction, and UI rendering

docs/logo/
  TESSERA brand assets
```

## Important Modules

- `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`
- `Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
- `Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookDirector.pm`
- `Kernel/System/ProcessManagement/TransitionValidation/ZTSMBlueLevelComplete.pm`
- `Kernel/System/ProcessManagement/TransitionValidation/ZTSMBlueBookHasNextLevel.pm`
- `Kernel/System/ProcessManagement/TransitionValidation/ZTSMBlueBookComplete.pm`
- `Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
- `Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
- `Kernel/System/ProcessManagement/TransitionAction/ZTSMRoleDirector.pm`
- `Kernel/Modules/CustomerTicketZTSMAction.pm`

## Applying The Overlay

Use the overlay after refreshing or replacing the upstream OTOBO tree:

```bash
perl ZTSMOverlay/bin/ztsm-overlay.pl --root . --check
perl ZTSMOverlay/bin/ztsm-overlay.pl --root . --apply
```

Overlay rules:

- `copy` entries are TESSERA/ZTSM-owned files and are copied directly.
- `patch` entries are targeted edits inside upstream OTOBO files and are applied with `git apply --3way`.
- If a patch conflicts after an OTOBO update, resolve the conflict manually instead of replacing the upstream file wholesale.

See [ZTSMOverlay/README.md](ZTSMOverlay/README.md) for overlay details.

## Portal-First Interaction

TESSERA treats the customer portal as the primary runtime interaction surface. Users may be requesters, approvers, assessors, implementers, verifiers, or governance participants, but they should normally interact through portal actions rather than the backend agent UI.

Current portal-oriented customizations include:

- customer ticket zoom runtime actions
- requester-only cancellation for master tickets
- support-profile work visibility on customer dashboard
- dynamic child ticket story links
- onboarding link instead of self-service account creation

## Dynamic Field Naming

TESSERA uses governed dynamic field prefixes:

- `ZTicket-*`
- `ZBlue-*`
- `ZState-*`
- `ZTSMServiceSupportMap-*`

Do not invent field names casually. New fields should be introduced through the Book/governance model and reflected consistently in runtime modules, UI, and overlay patches.

## Architecture Notes

Start with:

- [TESSERA Core Philosophy](docs/architecture/tessera-core-philosophy.md)
- [StateBook and BlueBook Model](docs/architecture/statebook-bluebook-model.md)
- [Runtime Orchestration Model](docs/architecture/runtime-orchestration.md)
- [Portal Interaction Model](docs/architecture/portal-interaction-model.md)
- [UI Rendering Model](docs/architecture/ui-rendering-model.md)

## Status

This repository is an active TESSERA/ZTSM customization workspace. Some files are upstream OTOBO files, some are TESSERA-owned modules, and some changes are represented as overlay patches. Treat `ZTSMOverlay` as the portable source of truth for applying TESSERA customizations across OTOBO releases.
