# TESSERA ScriptEngine Knowledge Base

## Execution Context Contract

TESSERA scripts separate the object that owns the program from the runtime object being evaluated:

- `CURRENT OBJECT` is the programming object. For RoleDirector resolution, this is the GovernanceRole containing `ZTSM-ScriptEngine`.
- `THIS` is the typed runtime object. `LET THIS: TICKET` binds the complete ticket supplied by RoleDirector.
- `TICKET` remains a supported alias, but authored scripts should use `THIS` after declaring `LET THIS: TICKET`.

RoleDirector calls the GovernanceRole resolver with both objects:

```perl
Resolve(
    GovernanceRole => $GovernanceRole,
    Ticket         => \%Ticket,
);
```

The ScriptEngine gets the logic from the GovernanceRole and actual values from the ticket. Unsupported `LET THIS` types fail closed. Future engines may use the same contract with another programming object and runtime object, such as a ControlObjective as `CURRENT OBJECT` and an affected ConfigItem as `THIS`, after that typed adapter is implemented.

## GovernanceRole Namespaces

- `PLATFORM::*`, `APPLICATION::*`, and `TICKET::*` are first-class scripted resolution roles.
- `SUPPORT::*` are assignment classifications without resolver programs.
- `TESSERA::*` are reserved system capabilities rather than resolution roles. Script execution fails closed with `RESERVED_CAPABILITY` even if a script is added to one.
- `TESSERA::CMDB::READ` grants entitled customer frontend users read-only CMDB navigation and detail access. It does not grant customer portal modification or API access; changes proceed through ticket workflow.
- Bootstrap creates every missing role from the authoritative GovernanceRole workbook, including its exported description, code, status, and script. Existing objects are left unchanged.

## Ticket Field Collection Semantics

`RETURN.TICKET FIELD COLLECTION` returns a typed collection, not a multivalue ticket field. RoleDirector reconciles it into separate tickets with scalar assignments:

- `Collection<GovernanceObject.SupportProfile>` assigns one `ZTicket-OwnerGroup` per ticket.
- `Collection<CustomerUser>` assigns one `ZTicket-Owner` per ticket.
- Matching tickets are preserved, active unmatched tickets are reused, missing tickets are created, and surplus active tickets are closed as `closed no action`.
- An empty collection is successful resolution with no eligible targets; eligible active tickets are closed as `closed no action`.
- Completed evidence is preserved.

Evidence is scoped to the same parent. Resolution checks the current iteration first, then the explicit previous iteration using `FALLBACK OFFSET: -1`. When the runtime ticket has no iteration, `UNNUMBERED WHEN EMPTY: true` permits unnumbered evidence. No qualifying evidence produces an empty collection.

## DIAGNOSE

Only affected Diagnosis outcomes contribute owner groups:

```yaml
---
SCRIPT: Resolve DIAGNOSE From Affected Diagnosis Evidence
VERSION: 1
LET THIS: TICKET

RETURN:
  TICKET FIELD COLLECTION:
    TICKET TYPE: Diagnosis
    STATE TYPE: closed
    PARENT:
      FIELD: ZTicket-Parent
      VALUE: THIS.ZTicket-Parent
    ITERATION:
      FIELD: ZIN-Iteration
      VALUE: THIS.ZIN-Iteration
      CURRENT FIRST: true
      FALLBACK OFFSET: -1
      UNNUMBERED WHEN EMPTY: true
    FILTER:
      FIELD: ZIN-Outcome
      IN:
        - Severity Confirmed
        - Symptom Observed
        - Cause Observed
        - Root Cause Observed
    FIELD: ZTicket-OwnerGroup
    DISTINCT: true
    IGNORE EMPTY: true
    AS: Collection<GovernanceObject.SupportProfile>
```

## ASSESSOR

`Not Applicable` confirms assessment but does not contribute an affected assignment:

```yaml
---
SCRIPT: Resolve ASSESSOR From Affected Assessment Evidence
VERSION: 1
LET THIS: TICKET

RETURN:
  TICKET FIELD COLLECTION:
    TICKET TYPE: Assessment
    STATE TYPE: closed
    PARENT:
      FIELD: ZTicket-Parent
      VALUE: THIS.ZTicket-Parent
    ITERATION:
      FIELD: ZIN-Iteration
      VALUE: THIS.ZIN-Iteration
      CURRENT FIRST: true
      FALLBACK OFFSET: -1
      UNNUMBERED WHEN EMPTY: true
    FILTER:
      FIELD: RiskAssessmentOutcome
      IN:
        - At Risk - Mitigation Control in Place
        - At Risk - Mitigation Planned
        - At Risk - No Mitigation
        - Risk Accepted
    FIELD: ZTicket-OwnerGroup
    DISTINCT: true
    IGNORE EMPTY: true
    AS: Collection<GovernanceObject.SupportProfile>
```

## IMPLEMENTER

Implementation outcome is intentionally not filtered. Every implementer involved in the selected iteration may be needed by later execution or verification:

```yaml
---
SCRIPT: Resolve IMPLEMENTER From Implementation Evidence
VERSION: 1
LET THIS: TICKET

RETURN:
  TICKET FIELD COLLECTION:
    TICKET TYPE: Implementation
    STATE TYPE: closed
    PARENT:
      FIELD: ZTicket-Parent
      VALUE: THIS.ZTicket-Parent
    ITERATION:
      FIELD: ZIN-Iteration
      VALUE: THIS.ZIN-Iteration
      CURRENT FIRST: true
      FALLBACK OFFSET: -1
      UNNUMBERED WHEN EMPTY: true
    FIELD: ZTicket-OwnerGroup
    DISTINCT: true
    IGNORE EMPTY: true
    AS: Collection<GovernanceObject.SupportProfile>
```

## Spreadsheet Storage

Excel may protect a value beginning with `---` by using a leading apostrophe. At the workbook import boundary, TESSERA removes one leading apostrophe when the value does not end with another apostrophe. Deliberately paired single-quoted text is preserved. ScriptEngine therefore receives executable source beginning with exactly `---`.
