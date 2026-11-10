# Customer network simulation workspace

Requirements intake, 2026-11-02. The Base187 implementation and its supported
scope are documented in [customer-network-simulation.md](customer-network-simulation.md).
It includes PROD-default environment selection, application/system-to-IP expansion,
scoped analysis and an interactive canvas. Arbitrary hypothetical rule evaluation
and a governed request-creation binding remain future extensions.

Provide one customer-portal workspace with a Grafana-style arrangement: input
controls, an interactive topology/path canvas, selection details and evidence.
TESSERA remains the control point for Navis analysis and governed execution.

## Page interaction

Application/system selection is the default entry point, not manual device UUID
entry. TESSERA resolves the selected application's/system's linked CMDB assets
and their actual exported address fields, constrained by the current customer's
entitlement and detail permissions. Show the resolved authorized IPs automatically;
let the user select the relevant endpoints when several addresses exist. Selecting
an IP highlights the corresponding authorized asset and evidence-backed paths.
Missing, stale or ambiguous CMDB relationships/addresses remain explicit and must
not be guessed. Trace requests may use literal IPs, but IP equality is not an
identity merge or authorization rule (addresses can overlap across network scope).

Device labels and click-throughs use the caller's native identity. For TESSERA,
map Navis external_identity to the exact opaque
(namespace, object_class, id) CMDB tuple and resolve the authorized CMDB record.
Navis's internal device UUID remains remote correlation metadata. Other callers
use their own registered namespace/class/native ID. Do not parse a display label
or replace the external identity with an IP, hostname or Navis UUID. Address-based
views are derived from these mapped assets and scoped evidence, not a second
device registry. Resolve exact application/system/address field names from latest
exports at implementation time; none are invented by this design.

- Inputs: entitled source and destination selections or validated literal host
  addresses, protocol and ports. Resolve asset visibility and endpoint scope on
  the server even when a user enters an IP manually. Build/connection selection
  is constrained by backend policy; browser input never selects credentials.
- Run analysis: TESSERA authorizes the current customer and selected scope,
  obtains authorized CMDB context, calls Navis and records analysis evidence.
- Canvas: pan/zoom, select a node/hop, highlight an analyzed path and show the
  observed/candidate/proposed distinctions with text and a legend. Unknown,
  blocked and allowed states must remain distinct. Supply an equivalent
  keyboard-accessible path table; do not depend on color or pointer gestures.
- Inspector: only entitled device information, evidence freshness, findings,
  coverage limitations and relevant recommendation drafts.
- Evidence panel: analysis status, completed build reference, observation time,
  missing information and request/recommendation correlation. Safe polling is
  for the saved analysis and recommendation GET; it cannot replay a trace POST.
- Compare a proposed change against the selected baseline as a visibly separate
  what-if scenario. Mark synthetic/unsupported scenarios explicitly. No actual
  graph mutation or verified connectivity claim without a supporting backend.
- Request action: carry the analysis reference into the configured ticket
  request/ActivityDialog. Approval, execution, readback and Navis feedback remain
  the governed TESSERA workflow. Simulation never directly grants apply authority.

## Customer authorization boundary

Use the current centralized entitlement service for lookup/selection and the
separate CMDB detail boundary for node metadata. Preserve ContractEntitlement,
SupportProfile and SupportAssignment semantics. TESSERA::CMDB::READ permits the
defined detail view only; it is not automatically a simulation, API or execution
capability. Confirm how simulation is authorized through existing exported
governance/service definitions; do not invent a new GovernanceRole or field.

Do not pass CustomerUser identifiers as agent ActorID into the Base186 controller.
Add an explicit customer principal adapter and independently authorized backend
execution context. Store customer ownership and authorized scope for each saved
analysis, check them on every lookup/poll/result access, and prevent analysis-ID
enumeration across users. Recheck permissions as assignments are revoked.

The browser must not receive raw Navis graphs/traces merely because it can select
one endpoint. Intermediate hops, hidden assets, addresses, counts and findings
also need a disclosure policy. Deny unsafe disclosure or return an explicitly
redacted projection; do not infer permission from a remote source grant. Navis
backend source access is broader than an individual customer's entitlement.
Use protected POST/CSRF validation, bounded input/results and per-user concurrency
limits. Never expose connection secret references, tokens or raw provider errors.

## Data limits and implementation order

Current Navis graph HTTP output is a device identity projection with an empty
connections array. Its trace response can provide candidate-hop evidence. Render
only edges actually supported by trace/topology evidence; never invent physical
links from device membership or recommendations. Full topology and arbitrary
hypothetical rule evaluation require an explicit backend data/API contract.

1. Establish customer principal/analysis ownership, simulation authorization and
   intermediate-hop disclosure policy using current exports and entitlement code.
2. Add the customer analysis adapter and bounded, filtered presentation DTO.
3. Build the responsive one-page inputs/canvas/inspector/evidence layout using
   native customer components with page-owned assets and accessible table view.
4. Connect governed request creation through configured ActivityDialog/context.
5. Add baseline/scenario comparison only for supported Navis simulation contracts.

Acceptance includes direct URL/poll/result bypass, unauthorized entered IP,
cross-customer analysis IDs, revoked assignments, hidden-hop disclosure, unknown
coverage, stale builds, uncertain POST outcomes, mobile layout, keyboard navigation
and screen-reader semantics. No package version change at requirements intake.
