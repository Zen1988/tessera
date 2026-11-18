# TESSERA 0.0.184 network assessment acceptance

184 connects CMDB network scope, NetXMS forward/reverse path discovery, AWX
read-only collection, authenticated completion and saved interpreted results.
OGL (Open Governance Language) is the name used here for the existing TESSERA
script language; this release uses its existing `CALL WEB SERVICE` syntax.

This is an executable collection/assessment flow, not a complete multi-vendor
policy compiler. It does not yet determine effective permission across every
rule, NAT, application, inherited policy or NSX realized scope, or emit/apply
vendor configuration. `ApplyReady` is always false. Plans identify enforcement
contexts and observed findings; review and unresolved semantics remain explicit.
Offline tests do not replace acceptance against the actual NetXMS and devices.

## Package and installation

Install `TESSERA-Base-0.0.184.opm` through the existing package upgrade process.
Keep existing database records. No new CMDB classes, Dynamic Fields or database
schema are introduced. Evidence uses the existing async execution ledger; the
interpreted immutable result uses an execution-keyed SystemData record. Existing
governance snapshots and administrator-owned Web Services remain unchanged.

Packaged docs/examples now install beneath `var/tessera/docs` and
`var/tessera/examples`, not new roots under OTOBO Home. This avoids the identified
top-level-directory permission exposure. The normal package upgrade removes old
owned paths; native Package.pm preserves differing files as `.custom_backup`.
Missing old paths are harmless. No root permission broadening or repeated repair
script is needed by design. Native Linux install/upgrade/reinstall still needs
acceptance; the reported host ownership cause has not been independently verified.
The ZIP test kit retains ordinary `docs/` and `examples/` paths for convenience.

Run the existing container toolkit prepare/build steps after installing 184.
Preparation still verifies every package byte. Do not skip failed verification.
184's release descriptor permits controlled upgrades from 180 through 183.

## Configure NetXMS

Import the updated `var/webservices/examples/TESSERANetXMS.yml` as a separate
reviewed service, or add PathTrace/PathTraceL2 to the existing service. Do not
overwrite its authentication or URL blindly. Configure HTTPS and certificate
verification. Path operations use POST `/v1/objects/:SourceID/execute-script`;
all previous observation operations remain GET. Leave mappings empty.

The invoker supplies fixed read-only NXSL, numeric source/destination IDs only.
It does not accept script text. The NetXMS API identity needs execute-script
permission on the selected source objects, as well as the relevant object access.
This account permission is broader than the TESSERA invoker surface: protect the
credential independently and restrict source scope. NetXMS 7.0.1 source was used
to verify the endpoint; actual installation compatibility remains untested.

`traceRoute` is routing/topology evidence, not a fresh packet probe or proof that
the requested TCP/UDP flow is permitted. Complete paths are required in both
directions. Unknown hops or missing classifications stop discovery. Classify
known unmanaged transit explicitly rather than treating an unknown hop as safe.
Path collection timestamps describe query time, not guaranteed routing-table age.

## Configure AWX

Put the entire `examples/network` directory in an AWX project. Select
`collect.yml` for the job template. Use an inventory with localhost plus the
managed aliases referenced by the backend mapping. Enable the inventory, limit
and extra-variable prompts required by JobLaunchCallback. The launch limits the
play to localhost; ASA reads delegate to the selected inventory alias.

Attach credentials in AWX. Supply these inventory/credential-injected variables:

| Variable | Meaning |
| --- | --- |
| tessera_platform | panos, checkpoint, fortios, asa or nsx |
| tessera_context | vsys, management domain, VDOM, ASA context, or NSX policy domain |
| tessera_manager | HTTPS hostname and optional port, without scheme/path |
| tessera_username / tessera_password / tessera_token | AWX-injected credential values |
| tessera_ca_file | Optional CA file inside the execution environment |
| tessera_options | Reviewed platform options below |

PAN-OS options require `virtual_router`. Check Point options require
`gateway_uid`, `access_layer`, `policy_package`. ASA uses context `single` for
single-context mode; otherwise it explicitly changes to the mapped context.
ASA requires `cisco.asa`, `ansible.netcommon`, network_cli inventory configuration,
SSH host verification and AWX-managed connection credentials. Other collectors
use Python's verified HTTPS client; redirects are refused. Install the corporate
CA inside the EE. Never turn off certificate checks to make acceptance pass.

No target credential is passed from TESSERA. Raw network configuration is
sensitive: collection/callback tasks use no_log, including under verbose mode.
The saved callback retains bounded raw evidence and normalized findings. The
collector refuses oversized/truncated results; it does not claim completeness
after dropping data. Each response is capped at 4 MiB, each device evidence at
512 KB, and the aggregate callback below 900 KB. Large installations require
scoped queries or a future paged evidence protocol, not silent truncation.

## Backend mapping and OGL launch

See `network-cmdb-enforcement-contract.md`. All IDs in
`examples/network/context.json` and `bindings.json` are fictitious fixtures.
Replace them from the authorized CMDB snapshot and configured Web Service IDs.
The backend selects actor, target ticket, NetXMS service, AWX service/template/
inventory, endpoint identities, node classifications, segment/domain relations,
domain enforcement aliases and governed protocol/ports. Request data contains
Source and Destination only. A stored script cannot supply that backend context.

The existing automation adapter accepts `NetworkDiscover`, `NetworkAssess` and
`NetworkResult` through explicit AllowedCalls bindings. These are trusted
orchestration operations, not native remote endpoint routes. NetworkAssess
queues the existing durable AWX dispatcher with handler NetworkAssessment.
Ensure the deployed `TESSERA::AsyncExecution::Handlers` registry includes that
handler; an administrator override is not silently replaced by this package.
The existing callback URL remains configured in the AWX Web Service.

For a trusted OS-console acceptance launch (run as the application OS user):

```bash
bin/otobo.Console.pl Maint::TESSERA::AutomationTest \
  --actor-id 1 \
  --script-file var/tessera/examples/network/automation.yml \
  --bindings-file /secure/network-bindings.json \
  --network-context-file /secure/network-context.json
```

Replace actor 1 with the reviewed actor; the context ActorID must match. This
launches a job and prints its ExecutionUID. Do not rerun it to poll. A separate
OGL call uses NetworkResult with that ExecutionUID, returning saved Status,
Plans, Issues, SourceNetwork and DestinationNetwork for subsequent script steps.
Only the execution actor can retrieve this result through the adapter. No generic
customer-facing evidence API or automatic CMDB-wide extraction was introduced.

## Collector scope and known limits

| Platform | Collected evidence | Explicit limits |
| --- | --- | --- |
| PAN-OS | Virtual-router routes; local vsys zones/security/NAT/PBF | Panorama inheritance, App-ID, NAT and PBF effective-flow evaluation remain unimplemented |
| FortiOS | VDOM routes, zones/interfaces, policy/VIP/policy routes | Address/service groups, SD-WAN, NAT and ordered effective-policy evaluation remain unimplemented |
| Check Point | Scoped management gateway object, access/NAT rulebases | Gaia route collection, inline-layer/target/group effective evaluation remain unimplemented |
| ASA | Context interface/nameif, route, ACL bindings, NAT and ACL output | Complex/multiline route parsing, NAT/object-group/effective ACL evaluation remain unimplemented |
| NSX | Local infra policy-domain groups, IP membership, security policies/rules | Federation/projects, gateway firewall, applied-to/exclusions/realized state and effective DFW evaluation remain unimplemented |

Route-to-source is a candidate interface inference, not confirmed packet ingress.
CMDB NetworkZone is never used as a device zone. NSX is selected independently
of L3 hops, but overlay selection alone never proves a new DFW rule is needed.
No configuration-writing playbook is included.

## Source references

* [NetXMS 7.0.1 synchronous script endpoint](https://github.com/netxms/netxms/blob/release-7.0.1/src/server/webapi/script_execution.cpp)
* [NetXMS node/path implementation](https://github.com/netxms/netxms/blob/release-7.0.1/src/server/core/nxsl_classes.cpp)
* [NSX policy API](https://developer.broadcom.com/xapis/nsx-t-data-center-rest-api/latest/)
* [Cisco ASA collection context implementation](https://github.com/ansible-collections/cisco.asa/blob/main/plugins/module_utils/network/asa/asa.py)
