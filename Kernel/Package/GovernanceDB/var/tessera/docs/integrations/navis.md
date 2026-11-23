> Reviewed2026-11-23 against [Navis0.1.1 commit ed4ba3e](https://github.com/Zen1988/navis/tree/ed4ba3e312bd24b0afabc2a2b2949e0aaa9c75a8/docs). Routes/request schemas remain compatible with the frozen reference snapshot; API version metadata changed. TESSERA0.1.6 accepts topology creation HTTP201. See [release notes](../releases/0.1.6.md). End users never supply graph IDs or labels; Application selection resolves its trusted label server-side.

> Reviewed2026-11-23 against [Navis0.1.1 commit ed4ba3e](https://github.com/Zen1988/navis/tree/ed4ba3e312bd24b0afabc2a2b2949e0aaa9c75a8/docs). Routes/request schemas are unchanged from the frozen reference snapshot except API version metadata. TESSERA0.1.6 fixes topology creation success status to201. See [release notes](../releases/0.1.6.md). End users never supply graph IDs or labels; Application selection resolves its trusted label in the backend.

# Navis workflow

Contract pinned to published Navis commit2a43005e445c2a33f6b6139cc8e8e6d05140feff, verified2026-11-17. [Provenance](../reference/navis/PROVENANCE.json), [topology contract](../reference/navis/TOPOLOGY_WORKFLOW.md) and [OpenAPI](../reference/navis/openapi.json) are included offline. Deploy the matching named-topology/visibility/progress code and migrations through 021. Published code is not proof of a live Navis/database upgrade.

## Current patch

Integration onboarding configures one enabled customer-simulation Navis connection. Application GO now has an optional Text Dynamic Field named Navis, shown on a separate Agent Navis page. It stores a stable topology label, not a UUID. The installer preserves existing class pages/roles and adds this page once; conflicting administrator-owned Navis layouts fail preflight. Collection namespace selects evidence; CMDB identity namespace matches returned external identities. They may differ. InstanceID is metadata, not either namespace.

Access administration grants exact active customer logins only; Utilities configures Workplace shortcuts. Customers choose authorized endpoints and protocol/port, with no mandatory environment or graph UUID.

With no Named graph, Tessera sends no graph_build_id. Navis freezes latest-known namespace evidence and returns its UUID. Tessera supplies a durable caller ID, validates returned IDs, saves the UUID and reads that exact graph. Agent NavisControl also supports Default traces without a pinned graph and Application contexts with an explicitly supplied trusted mapping UUID.

Named graph is a stable topology_name sent directly to Navis, which refreshes/resolves the named application's latest content version. Tessera does not scan builds or store a current UUID on Application. Historical inspection uses name-based version/history/compare routes; an explicit version is for reproducibility, not the default selector. The Application GO Navis field holds this stable label. In the workspace choose Default network or a permitted Application explicitly; source/destination Application filters do not implicitly select a graph. An absent/empty optional Application label uses the default network while retaining the selected Application context. Malformed references, unauthorized/inactive Applications and a saved name that Navis cannot resolve still fail closed; never retry those against default. Full topology-creation automation remains separate.

## Agreed end-to-end direction

1. Authorized automation/ScriptEngine context launches AWX discovery with durable execution identity.
2. AWX returns normalized per-device/data-type Navis envelopes, not raw stdout or an unrestricted whole response.
3. Tessera submits each envelope once, retaining receipt and payload digest.
4. Reconcile by ingestion ID or collection run using GET. The readback service supplies backend-owned collection_run_id, expected_submissions and expected_items. Success requires the aggregate received/processed totals to match, no pending/failed/raw-only submissions, and explicit normalization success. A stopped upload cannot become complete merely because all received envelopes processed. raw_only is preserved distinctly and does not claim typed normalization. Ingestion success does not claim a graph or verified connectivity.
5. Ingestion does not create application-named graphs. Ordinary/firewall traces use the namespace's logical default topology by omitting graph_build_id; no literal name=default is sent merely because the UI calls it default.
6. Separately, application topology creation submits selected server IPs and an application label to POST /v1/topologies. Store the stable name on Application and retain returned version/build UUIDs, selected-IP digest, connection identity and namespace in operation evidence. Unchanged content can retain its UUID/built_at and advance updated_at; those dates do not establish fresh device collection.
7. Application tracing uses its saved topology_name, optionally a specific historical live version when explicitly requested. Firewall-rule tracing does not inherit an application graph just because an endpoint belongs to an application.
8. Recommendations are fetched by the original caller_session_id. They are drafts, not approval or network execution.

The patch adds topology creation/read, build discovery, ingestion status and session graph routes. NavisControl has GET-only ingestion-status reconciliation. The Application label and explicit trace context are implemented. The complete AWX discovery scheduler, CMDB membership/topology-creation automation and workflow publication remain pending. A label is a reference to an existing named topology, not a trigger to create one by itself.

## Evidence and failures

A durable intent precedes each trace POST. Repeated submission does not replay it. Results recheck owner, grants, endpoints, connection and current CI entitlement. Every referenced device, including nested coverage/reverse evidence, is permission checked. The graph may show anonymous grey restricted nodes with the Application system name only, under the owner-approved graph-only exception; no hidden CI name/address/class/ID or link is returned. Detailed path/recommendation data remains withheld across restricted scope. Unmanaged gaps are distinct and unknown. Raw graph/trace/private text stays backend-side.

Legacy environment bindings remain untouched only for saved records; new traces do not fall back to them. Overlapping IPs across accessible assets are ambiguous, even with application filtering; no IP-based tenant/VRF inference.

[Navis source contract](https://github.com/Zen1988/navis/blob/2a43005e445c2a33f6b6139cc8e8e6d05140feff/docs/TOPOLOGY_WORKFLOW.md).



## Trace presentation

The portal displays candidate managed hops, permission-masked grey devices and distinct unmanaged/missing segments. The grey placeholder may show its Application system name only; it has no CI name/IP/class/native or Navis ID, and no device link. Application affiliation is a narrow owner-approved graph projection through the existing ZTAM-Application reference, not a CMDB discovery/detail grant. Missing or ambiguous affiliation remains unavailable. Known managed endpoints beyond a gap are marked not_traced rather than promoted to evaluated/connected. Mobile uses a readable vertical graph with pan/zoom and a keyboard-accessible inspector.
