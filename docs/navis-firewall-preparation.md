# Navis firewall-request preparation

2026-11-02 architecture correction: the AWX-owned Navis flow described below is
superseded by [TESSERA integration onboarding](integration-onboarding.md).
TESSERA now calls Navis, prepares/authorizes the plan, instructs AWX, requests
separate readback and sends observed policy back to Navis. The current AWX example
consumes prepared plans for simulation only and makes no Navis calls. Historical
setup instructions below are retained for provenance, not deployment guidance.

Prepared 2026-11-02 against Navis API 0.1.0 and its integration guide (reviewed
2026-10-30). This is a standalone AWX project preparation kit for existing
TESSERA Base184, not an installed package upgrade or a deployed BlueBook.

## Execution flow

SR request → configured BlueBook activity → authorized TESSERA ScriptEngine
`JobLaunchCallback` → AWX `workflow.yml` → caller-scoped Navis graph → Navis trace → same-caller
recommendations → authorized graph identity resolution and CMDB context enrichment → Palo Alto,
Cisco ACI or VMware NSX simulation → authenticated TESSERA callback ledger.

The existing scripting engine already supports the necessary launch grammar.
`automation.yml` was evaluated with the real ScriptEngine and a mock authorized
provider. No new language opcode, Dynamic Field, database table or hardcoded
workflow route is required for this preparation. NetXMS source/config remains
available for installed environments; this workflow has no NetXMS dependency.

## Navis contract and identity

`POST /v1/traces` is synchronous. The caller ID is `tessera-<ExecutionUID>`;
the execution ledger is created before AWX launch. The graph build UUID must
identify an operator-prepared, completed build accessible to the same principal.
Only literal host IP lists and supported protocols/ports are sent. Requested
action stays in TESSERA/AWX because Navis forbids an extra `action` request key.

Recommendations use `GET /v1/trace-sessions/{caller_session_id}/recommendations`.
The internal trace UUID is retained but is not substituted into that path.
Both IDs, graph, expanded-flow tuples, original request, trace, drafts and
snapshot/request digests are retained in callback evidence. Unknown aggregate
verdicts remain unknown even when a candidate is blocked. Drafts never authorize
execution; every result is `Simulation: true`, `ApplyReady: false`.

Identity contract pinned to Navis commit
`a00bed98aafe2a214267a7af26d5d862ef53d5ab`. The workflow first calls
`GET /v1/graph-builds/{build_id}/graph` under the same registered consumer.
Each recommendation's Navis `device_id` joins to a graph device node's `id`.
Only `external_identity.status: mapped` with the configured exact
`identity_namespace` and `object_class: NetworkNode` can select CMDB enrichment.
Missing/ambiguous identities and absent authorized enrichment block that target;
wrong build, duplicate graph devices or duplicate external identities reject the
response. The recommendation endpoint itself still returns the stored draft.

The stable identity is `(namespace, object_class, id)`. All three values are
opaque case-sensitive strings; leading zeros and punctuation are preserved.
No integer conversion or colon-splitting is performed. A graph identity grants
no TESSERA access by itself: the backend must independently authorize the CMDB
enrichment snapshot for the actor/ticket/entitlement scope.

The `cmdb_snapshot` now contains only `namespace`, `Class: NetworkNode`, string
`ConfigItemID`, `platform` and `context`. It no longer contains
`navis_device_id`; legacy manual associations are rejected. The tuple
`(namespace, Class, ConfigItemID)` must match the graph identity exactly.
Configure `identity_namespace` for the actual registered CMDB instance rather
than assuming all tenants use `CMDB`. These are integration envelope keys, not
new Dynamic Fields or a separate identity registry. Vendor context is still
extracted by authorized automation from actual CMDB fields and reviewed
operational facts; governance NetworkZone IDs are not device zone names.

Before deployment, Navis operators must apply migration
`016_device_identity_class.sql` (requires `btree_gist`), review conflicting
mapping intervals, explicitly classify known NetworkNode mappings and configure
the consumer's `identity_source_system_id` and `identity_object_class`.
Legacy records default to class `device`; do not infer class from ID text.
These are Navis-side trusted operator tasks, not TESSERA migrations, and this
kit does not execute them.

## AWX setup and offline rehearsal

1. Put the entire `examples/navis` directory in an AWX SCM project. Select
   `workflow.yml`; use an execution environment with Python3 and ansible-core.
   Only builtin Ansible modules and Python standard library are used.
2. Use a restricted localhost inventory. Configure the template to accept the
   launch inventory/limit/extra variables required by existing JobLaunchCallback.
   No device credentials or vendor collections are needed for simulation.
3. For offline rehearsal, use `fixture-input.json` as `tessera_navis` and leave
   `mode: fixture`. The callback execution UID replaces the fixture UID.
   `fixture-extra-vars.json` already wraps that value for AWX extra variables;
   merge only its `tessera_navis` into the existing authorized launch example.
   The trusted TESSERA dispatcher injects `tessera_callback`; do not invent a
   callback token or paste it into project files. Do not send the fixture's raw
   standalone `execution_uid` as a TESSERA ticket field.
4. Configure existing TESSERA AWX Web Service HTTPS/callback configuration.
   Replace template42/inventory7/Webservice12 in `automation.yml`/`bindings.json`.
   For fixture launch use `automation-fixture.yml`, which already embeds the
   synthetic input (JSON syntax is valid YAML); replace its AWX IDs too.
   `automation.yml` defaults to live Navis analysis plus vendor simulation.
5. Run the trusted console acceptance command as the application OS user:

   ```sh
   bin/otobo.Console.pl Maint::TESSERA::AutomationTest \
     --actor-id 1 --script-file /secure/navis-automation.yml \
     --bindings-file /secure/navis-bindings.json
   ```

   Substitute the reviewed actor and secure paths. This existing command uses
   AWXTest/IntegrationTest continuation. It verifies launch and saved callback,
   not production ticket completion. Retain returned ExecutionUID, verify AWX
   final job status and inspect saved TESSERA history. Do not rerun to poll.

Offline Python rehearsal without AWX:

```sh
python3 examples/navis/navis_workflow.py < examples/navis/fixture-input.json
python3 -m unittest discover -s scripts/test/TESSERA -p test_navis_workflow.py -v
perl -I . scripts/test/TESSERA/NavisPreparation.t
```

`fixture-result.json` and `fixture-vendor-receipts.json` show the expected
preparation and three vendor outputs. These are synthetic client-contract
fixtures; they are not Navis live engine/device acceptance evidence.

## Live Navis analysis with simulated device actions

Set `mode: navis`, supply the actual completed `graph_build_id`, request flow
and actor-authorized CMDB enrichment snapshot plus exact `identity_namespace`. Inject `NAVIS_URL`, `NAVIS_TOKEN` and optional
`NAVIS_CA_FILE` through an AWX custom credential/environment, never extra_vars.
Token needs `graph:read`, `analysis:run`, `analysis:read`, active consumer registration and
selected-source permissions. HTTPS and hostname/CA verification are mandatory;
redirects are refused. Navis does not receive device/controller credentials.

There is one POST attempt. Timeout/transport/server failure is
`FAILED_OR_UNCERTAIN`; the saved caller ID supports operator reconciliation.
No automatic new trace or retry is performed. AWX job relaunch must be treated
as a new analysis or reconciled explicitly, not as exactly-once delivery.
Raw request/response budgets are4MiB; callback JSON is bounded below900KB.
Exceeding budget fails instead of claiming complete evidence.

Pending and unavailable recommendations return those statuses without device
plans. They do not imply a background generator exists. For a pending session
with a saved trace, a separate authorized launch can use
`mode: recommendations`, `trace_execution_uid` from the original execution,
`saved_trace` from the original result, the same graph/flow and refreshed
authorized CMDB snapshot. This refreshes the same build's caller-scoped graph and performs recommendation GET only, using the original caller ID;
its completion callback belongs to the new execution. Session ownership and
expiry still apply. If the original trace response was lost, there is no public
stored-trace GET endpoint; operator reconciliation is required.

## Vendor simulation contract

All tasks are nonmutating; a deterministic simulation reference is not a real
rule ID. No PAN-OS commit, APIC deployment or NSX realization is claimed.

| Task file | Required reviewed context | Simulated intent |
| --- | --- | --- |
| palo-alto.yml | vsys, source_zone, destination_zone; zones must agree with resolved Navis draft | security_rule |
| cisco-aci.yml | tenant, source_epg, destination_epg, contract | directional contract_filter |
| vmware-nsx.yml | domain, source_group, destination_group, applied_to, policy | scoped dfw_rule |

Missing context yields `ENRICHMENT_REQUIRED`. Incomplete Navis proposals are
retained as issues, not promoted to rules. Current Navis generates allow drafts;
deny requests remain review-required and are not silently inverted. Existing
rules, policy order/inheritance, NAT, App-ID, ACI contract direction and NSX
realized scope require separate approved vendor implementation and validation.

## BlueBook integration and remaining runtime work

Prepare one activity named “Network request analysis” in the relevant *future*
BlueBook definition. Collect source, destination, protocol, source/destination
port when applicable, and requested action through the existing configured
ActivityDialog/ScriptSet input path. Bind to the service's actual exported
fields/definition; do not create guessed `ZTicket-*` fields or rewrite started
ticket snapshots. No active BlueBook object was supplied or edited here.

Production binding must inject the authorized provider/AllowedCalls and an
execution context for the real child ticket, actor and reviewed continuation.
Persist/request-snapshot the input before launch. Device/CMDB scope must pass
existing customer entitlement and SupportAssignment boundaries independently
of Navis mappings. Never trust mappings, target IDs, platform or callback URL
from requester input. Do not enable the OS acceptance handler for portal use.

The production continuation still needs explicit implementation/publication:
consume the callback's semantic status, write a human-readable child article
and parent evidence reference using existing Ticket APIs, and offer the next
configured review activity. ExitCode0 means the simulation program completed,
not that connectivity is allowed or rules were applied. Pending/unavailable,
review/enrichment and failure outcomes must not automatically complete the
implementation activity. Callback receipt alone is not independent AWX final
job success. StateBook/BlueBook movement remains governed by the configured
process, not by this Python worker. Requester Hold/Resume contracts remain intact.

Real vendor apply is intentionally absent from this simulation preparation.
Before adding it: immutable approved plan/hash, actor/target reauthorization,
execution idempotency/reconciliation, device-native IDs, credential-backed
vendor modules, commit/deploy/realization checks, rollback evidence and a fresh
post-change Navis analysis must be implemented. No temporary fields are needed
to substitute for these controls.

## Installation and continuity

No TESSERA SOPM/OPM/schema/export or installed NetXMS configuration changed. The kit
can be copied into a fresh or upgraded184 AWX integration without migrations.
It does not automatically overwrite administrator Web Services/Books/scripts.
A future runtime release must add reviewed files through the authoritative
SOPM and generate a new immutable OPM; never rewrite184 in place.

Remaining owner inputs: Navis HTTPS origin/principal/scopes and completed build,
Navis registered-client/migration setup and authorized CMDB
context extraction and the SR service/BlueBook/ScriptSet export to
bind. AWX template/inventory/credential IDs and EE CA trust also need actual
environment acceptance. No live Navis/AWX/vendor or Linux Ansible execution
was available in this workspace.

Sources: [Navis identity contract](https://github.com/Zen1988/navis/blob/a00bed98aafe2a214267a7af26d5d862ef53d5ab/docs/INTEGRATION_API.md#external-device-identity-and-registered-clients),
[recommendation fields](https://github.com/Zen1988/navis/blob/main/src/navis_common/zones.py),
[caller-owned session persistence](https://github.com/Zen1988/navis/blob/main/src/navis_api/trace_session.py).
