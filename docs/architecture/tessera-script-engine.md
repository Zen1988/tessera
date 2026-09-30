# TESSERA ScriptEngine Knowledge Base

## Language boundary

TESSERA YAML is a versioned, English-like programming language for governance
policies and automation. A program declares typed targets, searches, conditions,
grouping, calculations, assignments and actions. ScriptEngine interprets those
declarations against live object data. Perl provides reusable adapters for
CMDB/GovernanceObject/Ticket access, DateTime calendar operations, persistence,
locking and external execution. A new policy supplies a new YAML program; it
does not require a Perl module for that policy.

`RETURN.GROUP FINDINGS` is one reusable language operator. `GROUP BY`,
`IDENTITY` and `FIELD ASSIGNMENTS` are required; `FOR EACH`, `RESOLVE`, `MERGE`
and `SEVERITY` are optional according to the program. ScriptEngine resolves
the program into a validated assignment plan. ControlRuntime applies the plan
and records evidence. The Product EOSL program demonstrates these operators;
its field names, date conditions and severity bands are authored in YAML.
`GROUP BY.MEMBER FROM` and `MEMBERS AS` select an optional collection from
the finding shape. A Contract program can choose ContractEntitlement members
without changing Perl or supplying an `Asset` property.

An external action such as AWX needs a reusable, typed execution adapter with
credential handling, timeouts, results and evidence before a YAML program can
call it. The current EOSL assignment does not implement AWX execution.

## Control discovery and authored evaluation (0.0.46 / 0.0.47)

VERSION remains 1. PolicyFilter discovers Control targets; PolicyEvaluation checks each
bound target and expands failing findings; FieldAssignment maps findings into RiskClass.
Product/EOSL is an authored example, never an engine-specific rule.

### PolicyFilter (0.0.46, confirmed live)

An Active objective save and the five-minute discovery daemon reconcile one Control per
objective and typed target. Inactive objectives are skipped. ControlClass is not a selector.
Supported SEARCH FOR / RETURN AS / Control fields:

| FOR | AS | Control field |
| --- | --- | --- |
| ITSMConfigItem | Collection<ITSMConfigItem.ClassName> | ZRM-CIInstance |
| GovernanceObject | Collection<GovernanceObject.ClassName> | ZRM-GOInstance |
| MELTObject | Collection<MELTObject.ClassName> | ZRM-MOInstance |
| Ticket | Collection<Ticket> | ZRM-TKInstance |

Class-based searches specify CLASS; Ticket omits CLASS. RETURN FROM: ALL Targets returns
the full typed collection, including empty collections. WHERE EQUALS/CONTAINS remain
available. Searches probe LIMIT+1 and reject incomplete populations, maximum 1000.
Repeated runs reuse Controls. Narrowing filters preserves historical Controls. CustomerUser
is deferred. Legacy scalar ticket applicability does not consume this collection program.

### PolicyEvaluation and findings (0.0.47, local validation)

The packaged examples under var/governancedb/policy are paste-ready:
control_discovery_products.yml -> ZRM-PolicyFilter;
product_eosl_evaluation.yml -> ZRM-PolicyEvaluation;
product_eosl_risk_assignment.yml -> ZRM-FieldAssignment.
Use Active objective, automatic type, supported ControlCycle (e.g. daily), CreateRisk enabled
and RiskClass MELTObject.Risk. The five-minute evaluation daemon dispatches due Controls.

TARGET must match the bound type/class. CHECK.EXPECT uses existing ScriptEngine expressions
(numeric/string/date conditions). Optional CHECK.ON EMPTY specifies FIELD, RETURN Pass or
N/A, and REASON. Unknown fields or malformed populated dates are errors, not missing data.
TIME ZONE and the pinned evaluation clock govern TODAY and TODAY + N DAYS/MONTHS/YEARS.
Calendar arithmetic clamps month-end/leap-day boundaries. Pass and empty-value returns
perform no descendant or affected-object searches.

ON FAIL.DESCENDANTS uses authored FOR, CLASS, PARENT FIELD, INCLUDE SELF, MAX DEPTH and
LIMIT. It follows inverse parent references to the last leaf without evaluating descendants'
own conditions. Cycles are visited once; depth/count overflow returns UNKNOWN. This
operation supports class-based ITSMConfigItem, GovernanceObject and MELTObject targets,
not Ticket hierarchies. ON FAIL.AFFECTED lists FOR, CLASS, LIMIT and REFERENCES. Direct
fields and Set[*].Child paths match selected identities. Traversal is bounded to 1000
objects/100 levels; affected class scans allow 100000. Overflow never silently truncates.

For a control on the bound object itself, `ON FAIL: { EMIT FINDING: THIS }` emits
one finding with `Target`, `TargetType` and `Source`. It performs no graph search
and works for ITSMConfigItem, GovernanceObject, MELTObject and Ticket targets.
`FINDING.Target` can be read by FieldAssignment. The Control remains a CI execution
record; the authored target can be any of these four supported object kinds.

The example checks only the current Product date. EOSL strictly before today plus one
calendar year fails, including expired dates. Exactly one year passes. Blank EOSL is N/A
(not announced). A failing source includes itself and all descendants regardless of their
dates. Workload/NetworkNode reference ZTAM-Model; StorageNode/PeripheralNode reference
ZTAM-Product; all four also use ZTAM-Runtime[*].ZTAM-Installed. HostedService indirection
is not implied. These field names, classes, threshold and relationships live in YAML.

FINDING exposes Asset, Source, AssetType and Matches (Path/Object). Assignment RETURN.AS
selects the destination type. `RETURN.GROUP FINDINGS` selects an authored group path,
iteration path, reference lookups, identity template, Risk name, Dynamic Field assignments,
merge modes and ordered severity conditions. The Product EOSL script groups affected assets
by Application, then iterates the ControlObjective's RiskStatements. Its identity is one
active Risk per scenario, Application, RiskStatement and source Product. The backend locks that identity, resolves
the authored references, unions CI links, keeps the highest authored severity priority and
records each contribution. The source Product and affected assets are linked in
`MELT-RelatedCI`. A closed Risk stays closed; the next failure starts a new
episode for the same identity. `MELT-Control` keeps the first creating Control because it is
single-valued; activities preserve subsequent Controls. CreateRisk gates creation. No new
Dynamic Fields are introduced. The earlier scalar `RETURN.IDENTITY` assignment remains
supported for existing scripts.

Successful runs record evidence, result and LastRun. Errors do not advance the cycle or
claim Pass. Earlier successful writes can remain after a later write failure; retries reuse
Risk identities. Automatic Risk closure/reopening is not implemented. Passing Controls do
not scan descendants to resolve old Risks. Historical Controls retained after filter narrowing
still need an explicit retirement decision. Fresh install/upgrade/reinstall use the same
packaged modules and scheduler settings; live deployment validation remains outstanding.

### Exact evaluation example

```yaml
VERSION: 1
TARGET: ITSMConfigItem.Product
TIME ZONE: Asia/Singapore
CHECK:
  ON EMPTY:
    FIELD: ZTAM-EoServiceLife
    RETURN: N/A
    REASON: End of service life is not announced.
  EXPECT: 'DATE(@THIS.ZTAM-EoServiceLife) IS ON OR AFTER DATE(TODAY + 1 YEAR)'
ON FAIL:
  DESCENDANTS:
    FOR: ITSMConfigItem
    CLASS: Product
    PARENT FIELD: ZTAM-Parent
    INCLUDE SELF: 1
    MAX DEPTH: 64
    LIMIT: 1000
  AFFECTED:
    - FOR: ITSMConfigItem
      CLASS: Workload
      LIMIT: 10000
      REFERENCES: [ZTAM-Model, 'ZTAM-Runtime[*].ZTAM-Installed']
    - FOR: ITSMConfigItem
      CLASS: NetworkNode
      LIMIT: 10000
      REFERENCES: [ZTAM-Model, 'ZTAM-Runtime[*].ZTAM-Installed']
    - FOR: ITSMConfigItem
      CLASS: StorageNode
      LIMIT: 10000
      REFERENCES: [ZTAM-Product, 'ZTAM-Runtime[*].ZTAM-Installed']
    - FOR: ITSMConfigItem
      CLASS: PeripheralNode
      LIMIT: 10000
      REFERENCES: [ZTAM-Product, 'ZTAM-Runtime[*].ZTAM-Installed']
```

### Exact field assignment example

The executable Product EOSL assignment is
`Kernel/Package/GovernanceDB/var/governancedb/policy/product_eosl_risk_assignment.yml`.
Set that content in the applicable ControlObjective's `ZRM-FieldAssignment` after installing
the package. The package preserves administrator-owned ControlObjective records and does not
change their existing field assignment during installation.

### Exact discovery example

```yaml
VERSION: 1
SEARCH:
  FOR: ITSMConfigItem
  CLASS: Product
  AS: Targets
  LIMIT: 1000
RETURN:
  FROM: ALL Targets
  AS: Collection<ITSMConfigItem.Product>
```


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

## Framework Risk Master Ticket Assignments

`Framework.ZRM-MasterTicket` uses the same VERSION 1 `RETURN.AS` and
`RETURN.FIELD ASSIGNMENTS` grammar as other TESSERA field mappings. Its target
is `Ticket.ServiceRequest`. The adapter provides `@RISK` (the originating
`MELTObject.Risk`) and `@FRAMEWORK` (the selected Framework). It requires the
authored `ZRM-OriginatedEvent` assignment to resolve to that Risk's ID and
`ZTicket-StateBook` to resolve to the Framework's `ZRM-RiskMgtStateBook`.
`Type`, `Service`, `CustomerUser`, and `Title` are also authored assignments.
When the StateBook resolves roles through an Application, the Framework mapping
assigns `ZTicket-Application` from the Risk's single `MELT-RelatedGO`
Application. The adapter validates its class and writes it before the
StateBook starts orchestration. An existing orchestrated SR cannot gain this
governance snapshot retroactively.
`ZRM-GOInstance` belongs to Control ConfigItems, not MELT Risks. The current
export defines `MELT-RelatedGO` as single-valued. ScriptEngine supports
class-filtered GovernanceObject references followed by a zero-based index,
for example `@RISK.MELT-RelatedGO[Application][0]`. It checks each referenced
object's class before indexing and fails if the selected index is absent or a
reference cannot be resolved. The existing single-value expression remains valid.
The example is `docs/examples/framework/risk-master-ticket.yml`.

Assessment follows `ZTicket-Parent` to the parent ServiceRequest and reads
that ticket's `ZRM-OriginatedEvent` to find the MELT Risk. A copied child
origin must agree with the parent. Framework `ZRM-RiskScoringEngine` may select
the Risk Statement with `@RISK.MELT-RiskStmt[RiskStatement][0]`; class filtering
occurs before index selection. The legacy `CURRENT RISK.MELT-RiskStmt` source
continues to require exactly one reference.

The adapter creates one master SR per originating Risk and reuses it on later
reconciliation. Risk changes dispatch it, and a five-minute reconciliation is
configured to cover existing Risks when a Framework gains a workflow. Live
reconciliation dispatch remains to be verified independently. A missing
workflow or mapping leaves the Risk unrouted. Invalid or ambiguous mappings
fail without choosing alternate objects.

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
