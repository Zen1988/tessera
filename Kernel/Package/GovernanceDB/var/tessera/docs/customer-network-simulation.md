# Customer network simulation workspace — Base188

Prepared source/package implementation; not deployed or live-validated.

## Customer interaction

Open **Network simulation** in the customer portal
(`customer.pl?Action=CustomerNetworkSimulation`). The initial environment is the
unique active Environment GovernanceObject named exactly **PROD**. Other active
environments can be selected explicitly. If PROD is absent or ambiguous, the page
requires an explicit selection; it never silently falls back to all environments.

Select an application/application system, then optionally a system/asset. The
page automatically resolves its permitted Workload/NetworkNode CMDB records and
their IPs, displays the mapped assets on the canvas and narrows the address
selectors. The exported model has no separate System class; systems here are the
actual Workload/NetworkNode records linked to an Application GovernanceObject.

Exact installed/exported fields used:

- `ZTAM-Application`: Application GovernanceObject reference on each asset.
- `ZTAM-Environment`: Environment GovernanceObject reference on each asset.
- `ZTAM-NetworkAdapter`: native Dynamic Field Set, read as an array of rows.
- `ZTAM-IpAddress`: actual address field inside each adapter row.

Do not substitute the older GeneralCatalog SystemEnvironment dropdown for the
exported GovernanceObject reference. No fields, roles or environment objects are
created. Missing/ambiguous references are excluded, invalid addresses are omitted
and duplicate addresses in the selected environment cannot be submitted as an
unambiguous endpoint. The current bounded workspace examines up to2000 Workload/
NetworkNode candidates and128 environments; excess fails explicitly rather than
silently presenting a partial inventory.

Choose one source IP, destination IP, protocol and destination port for TCP/UDP.
TESSERA obtains the graph, requests a trace, then requests recommendations using
the same registered consumer. Source/destination fields submitted by the browser
are server-validated endpoint keys, not unrestricted IPs or remote device UUIDs.
The connection/build/namespace are chosen by administrator configuration.

The canvas supports zoom, pan, reset and keyboard-selectable nodes. Selecting a
node opens its CMDB information inspector and a link to that native record. The
path table is the keyboard/screen-reader alternative. A changed input removes
old path edges and labels old evidence as belonging to the saved analysis.
Saved evidence shows its capture timestamp and analysis reference.

Only trace-supported consecutive main-candidate hops become edges. Asset
membership alone does not create a physical link. The current Navis graph API
returns identities without connection edges; baseline CMDB selection therefore
shows nodes without fabricated topology. Unknowns remain unknown. This page
does not implement arbitrary hypothetical rule edits or claim live connectivity.
Recommendation drafts never initiate AWX. Actual changes continue through the
configured governed ticket workflow; no new direct apply action or hardcoded
service/Book routing is introduced.

## Authorization and remote setup

Page/asset detail requires a valid CustomerUser and the existing centralized
CMDB detail entitlement: ContractEntitlement, matching SupportAssignment and
`TESSERA::CMDB::READ`. Checks run before asset disclosure and again when loading
saved results. Neither company membership nor application ownership is a bypass.

Remote simulation is independently authorized through administrator SysConfig:

In Base188, use **Admin → Network simulation access**
(`index.pl?Action=AgentNetworkSimulationAccess`). Enter exact active customer
logins, choose the enabled Navis connection for each environment, enter the
completed graph UUID and registered caller namespace, then enable simulation and
save. The page displays whether listed accounts have an existing CMDB read
assignment. It does not create that assignment or grant execution authority.
There is also a link from Integration onboarding.

The screen updates the same three SysConfig settings below. Save disables
simulation first, deploys and verifies users/bindings, and enables it last.
Partial deployment remains disabled. Concurrent edits and configuration-file
overrides must be resolved before saving. Native SysConfig records deployment
history. Earlier Base187 installations can configure these settings directly in
Admin → System Configuration until Base188 is installed.

1. `TESSERA::CustomerNetworkSimulation::Enabled`: default0; enable deliberately.
2. `TESSERA::CustomerNetworkSimulation::AllowedCustomerUsers`: explicit exact
   customer account logins; default empty. No wildcard, company matching or new
   GovernanceRole. CMDB read alone grants no remote simulation call.
3. `TESSERA::CustomerNetworkSimulation::Bindings`: JSON map from actual active
   Environment GovernanceObject ID to the reviewed Navis connection/build:

```json
{
  "<Environment GovernanceObject ID>": {
    "WebserviceID": 12,
    "BuildID": "<operator-provided completed graph UUID>",
    "Namespace": "<registered TESSERA instance namespace>"
  }
}
```

Replace all example identifiers. WebserviceID refers to an enabled Navis preset
created through Base186 Integration onboarding. Configure graph:read,
analysis:run and analysis:read plus independent Navis source permissions. Different
environments can bind different builds/connections. There is no default remote
binding. Customer input cannot override the connection, build or credentials.

Customer analyses are separate from the agent-only NavisControl execution ledger.
The customer login is stored as the analysis owner and is never converted to an
agent ActorID. Existing CustomerPanelUserID is only native backend storage/search
identity. No customer gets agent execution capability.

Raw graph/trace/recommendation evidence remains backend-side. The browser receives
a filtered presentation: native CMDB identities/names, selected IPs, authorized
candidate hops, safe finding codes and matching recommendation summaries. Remote
names, UUIDs, raw reasons, topology/configuration payloads, credentials and hidden
device data are omitted. Any unmapped/out-of-scope device referenced by the trace,
including nested candidate/coverage/reverse/alternative evidence, withholds the
path and recommendations. Endpoints remain individually permission-checked.
An independently authorized all-asset backend consumer never substitutes for the
customer's visibility boundary.

## Evidence and failure handling

Protected POST/native CSRF validation gates analysis and recommendation refresh.
One durable per-customer submission token maps to one immutable request/environment/
asset/binding identity. Reusing it cannot resend the trace, including after a lost
response. Fresh requests have a30-second per-customer cooldown and serialized
execution; recommendation refresh has a10-second bound and sends GET only.

TESSERA saves intent before trace POST and saves the synchronous trace before
requesting recommendations. An uncertain POST remains Outcome uncertain and must
be reconciled using its saved analysis reference. No refresh/resubmission silently
replays it. Successful browser submissions redirect to a saved result URL to
prevent browser refresh from creating another trace. Result lookup checks exact
owner, current entitlement/addresses, current environment and connection binding.
Revoking simulation authorization prevents further saved-result access.

Storage uses existing SystemData, with bounded private evidence records; no schema
or Dynamic Field migration. No external calls, credentials, assignments or remote
Web Services are created by installation. Base186 payloads and fresh/upgrade/
reinstall hooks are preserved. Standard native package/SysConfig deployment
installs the module, navigation and page-owned JS/CSS. Existing installation
administrators remain responsible for the explicit remote bindings and grants.
Retention/cleanup of private simulation evidence needs an operational policy
before a large rollout; no destructive automatic cleanup is introduced here.

## Validation and acceptance

Local coverage includes actual exported field checks, PROD default and ambiguity,
environment isolation, CMDB permission/role revocation, cross-customer analysis
IDs, endpoint/application tampering, nested hidden-hop redaction, idempotency,
uncertain POSTs, GET-only refresh, native CSRF, template escaping/JSON safety and
offline execution of the actual page JS (selection/filtering, mapped-IP expansion,
node inspector/native links, keyboard activation, zoom/reset and submit state).

The synthetic preview is `.artifacts/customer-network-simulation-preview.html`.
Browser visual QA was blocked by the local-file URL policy; no alternate browser
surface was used to bypass that restriction. Live browser/mobile/screen-reader,
native fresh/186→187/reinstall, real NAuth/CMDB/PROD/UAT bindings and actual Navis
response/projection acceptance remain to run in an authorized deployment.
