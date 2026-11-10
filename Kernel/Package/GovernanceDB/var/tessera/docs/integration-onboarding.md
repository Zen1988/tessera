# Integration onboarding and TESSERA-controlled Navis execution

Prepared in TESSERA-Base 0.0.186. Not installed or live-validated here.

## Control flow

TESSERA owns the conversation: request context from Navis, request recommendations,
join caller-scoped external identities to independently authorized CMDB context,
review/authorize the exact plan, instruct AWX, receive completion, instruct a
separate firewall readback, compare observed policy, and submit that observation
to Navis. AWX has no Navis credential and does not choose recommendations or call
Navis. Network policy should allow TESSERA→Navis and TESSERA→AWX, AWX→approved
devices and the TESSERA callback; deny AWX→Navis. Device credentials belong to
restricted AWX credential bindings. No new queue or Book routing is hardcoded.

## Onboard a service

Open Administration → Integration onboarding (`Action=AgentTESSERAIntegration`).
An active agent with admin rw permission is required by the module and backend.

1. Have the external operator issue credentials and source/operation permissions.
   Navis registration is local to its operator; no registration HTTP API exists.
2. Mount the exact client secret as a restricted, read-only file inside the
   existing `/run/tessera-secrets` mount. Enter its file name as SecretName, for
   example `navis-client`. No trailing newline is allowed. Never enter a secret
   value in a route, client ID, ScriptEngine program, ticket or AWX launch.
3. Enter a unique connection name, Navis preset, HTTPS Origin, InstanceID metadata,
   TokenURL (`Origin/nauth/token`), ClientID and optional Scope. Required scopes
   for the complete loop are graph:read, analysis:run, analysis:read and
   inventory:write. Navis source permissions are independently required.
4. Test authentication. This requests a token without saving or displaying it.
   Saving disabled makes no remote call. Enabling tests the submitted profile.
5. Save. The created native Web Service ID is used by trusted workflow bindings.
   Editing a selected managed connection updates that ID. Creating the same name
   again is refused; unrelated administrator-owned services cannot be adopted.

The Generic preset supports the same client-credentials Basic protocol at a
configured HTTPS token endpoint and administrator-defined named GET/POST routes:

```json
{"Fetch":{"Method":"GET","Path":"/things/:ThingID","Parameters":["ThingID"]},
 "Submit":{"Method":"POST","Path":"/items","Parameters":[],"SuccessStatus":202}}
```

GET accepts only declared path parameters. POST removes path parameters and sends
the remaining object as JSON. Routes cannot contain arbitrary runtime origins,
query strings or headers. SuccessStatus defaults to 200. Future authentication
protocols require reviewed backend provider implementation; there is no arbitrary
module/script loading from configuration. Generic onboarding is usable without
Navis; it does not depend on Navis scopes or paths.

Tokens are opaque, process-memory-only, refreshed before expiry and isolated by
connection/profile/scope/secret content. Mounted secret replacement takes effect
on the next request. TLS verification is mandatory, redirects disabled, timeout
30 seconds, token-response bound 64 KiB and API-response bound 4 MiB. A GET 401
refreshes/retries once. POST requests are never automatically replayed. Token
exchange errors are sanitized; transient failures return to the caller without
an internal retry loop. No token body or Authorization header enters GI debugging.

## Trusted workflow binding

`AutomationWebService` now accepts a backend-supplied `NavisContext`, alongside
the existing exact `AllowedCalls` binding. These are trusted Perl/runtime inputs,
not fields accepted from a customer or stored policy. Bind NavisAnalyze,
NavisGet, NavisRecommendations and NavisExecute to the onboarded service ID.
See `examples/navis/automation.yml` and `bindings.json` for the analysis grammar.

NavisContext contains ActorID, NavisWebserviceID, TargetType/TargetID, completed
BuildID, registered Namespace and the independently authorized Snapshot. Snapshot
rows retain the existing namespace/Class/ConfigItemID/platform/context contract.
No ID, company membership or remote identity itself grants CMDB permission.

NavisAnalyze accepts only the flow (source, destination, protocol, optional
ports/application and requested action). It returns AnalysisID and status. NavisGet
returns scoped evidence and PlanDigest. Pending/unavailable recommendations can
be fetched again with NavisRecommendations using the saved trace; it never
recreates the trace. Each trace intent is saved before POST. If its outcome is
uncertain, inspect/reconcile the retained analysis rather than reissuing it.

The workflow must independently authorize the exact returned PlanDigest. Its
trusted execution context then supplies ApprovedPlanDigest and separate Apply
and Readback bindings. Each binding contains AWXWebserviceID, TemplateID,
InventoryID and Limit. NavisExecute accepts only AnalysisID; policy cannot submit
its own approved digest, templates, targets or endpoint. Review must be repeated
after a plan change. Connection configuration drift invalidates saved analysis.
This does not implement the separate general-purpose AOE publication/review gate.
Use existing authorized trusted workflow entry points until that gate is ready.

AWX receives only `tessera_work` with AnalysisID, PlanDigest, Phase and prepared
Plans. The existing JobLaunchCallback mechanism injects its execution callback.
Apply and readback remain two distinct, registered jobs. Their continuations run
inside TESSERA using the authenticated AsyncExecution ledger, not claimed callback
fields. Duplicate completion cannot relaunch work or duplicate ingestion.

## Worker evidence contract

An actual apply template returns through the existing authenticated callback:

```json
{"AnalysisID":"<saved-analysis>","PlanDigest":"<authorized-digest>",
 "Simulation":false,"Status":"APPLIED"}
```

ExitCode must also be zero. Simulation output cannot satisfy this contract.
TESSERA then requests READBACK using the separately bound template. It must
collect actual current device policy and return:

```json
{"AnalysisID":"<saved-analysis>","PlanDigest":"<authorized-digest>",
 "Envelopes":["one actual Navis normalized policy envelope per observed target"]}
```

The array elements are objects, not the explanatory string above. Follow Navis
INTEGRATION_API.md ingestion envelope/policy schema. Set source namespace,
object_class and external_device_id to the exact authorized CMDB tuple. Use
adapter navis/normalized-json/1, data_type policy, actual collection timestamp
with timezone, and truthful complete/partial/unknown coverage. Collection time
must be after apply (60-second clock allowance). No invented UUID mapping or
planned draft substituted for observed rules. TESSERA rejects unrelated targets,
duplicate per-target snapshots, unexpected metadata and stale observations.

TESSERA retains per-plan ReadbackVerification. Missing/partial observations remain
UNKNOWN. OBSERVED_MATCH requires complete coverage, exact source/destination and
service selectors, and reviewed `normalized_enforcement_point` and
`normalized_rule_set` context matching the observed rule. It establishes a
configuration observation, never verified connectivity or effective rule ordering.
These context keys are integration metadata, not new CMDB Dynamic Fields.

Readback is retained separately from plans. TESSERA sends each observed envelope
itself to Navis, saves each 202 receipt and payload digest, and stops at
NAVIS_STAGED_OPERATOR_PROCESSING_REQUIRED. Navis currently exposes no HTTP worker,
ingestion-status or graph-build API. Normalization/dataset/build handoff remains
an operator task. Never claim Navis's graph updated merely because ingestion
returned pending_identity. A partial/uncertain submission retains prior receipts
and INGEST_INTENT and requires reconciliation; no automatic POST replay.

## Installation and acceptance

Base186 adds file/config definitions only. No schema, Dynamic Field, live Web
Service, remote registration or credential is created by installation. Native
existing storage/APIs and the existing async ledger are reused. Existing
Web Services and customer OIDC authentication are preserved. Fresh install,
upgrade, reinstall and later upgrades retain data through existing package hooks.
Use the current package installer and normal SysConfig deployment.

`examples/navis/workflow.yml` is now a prepared-work SIMULATION fixture only. Its
helper has no network client. It is deliberately rejected as proof of a real
apply. Bind production reviewed vendor apply/readback playbooks separately.
For offline simulation use automation-fixture.yml with bindings-fixture.json;
fixture-extra-vars.json contains prepared intents only. This simulation callback
must not be wired to the NavisControl production completion handler.
The old standalone `navis_workflow.py` is retained as an offline compatibility
oracle; it is no longer invoked by the AWX workflow. No production vendor
collection implementation or credentials are assumed by this package.

Local tests exercise mocked HTTP/native storage/AWX boundaries, real token
encoding/cache logic, real plan compilation, continuation phases and template
rendering. Before production acceptance, test a native fresh/185→186/reinstall,
actual TLS/NAuth rotation, authenticated callback, real device apply/readback,
source permissions and Navis operator normalization/build handoff. Those live
checks were not possible in this workspace.
