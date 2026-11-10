# NetXMS observation connector

NetXMS is a first-class enterprise observation integration, independent of AWX. TESSERA remains usable with other observation sources. CMDB and Books retain intended identity, scope and governance truth; NetXMS supplies observed objects, relationships, service state and measurements. Business-service observations do not replace StateBook or BlueBook choreography. AWX remains the device action gateway. Provider-owned MPLS may be represented as external transit without importing the provider's internal devices; uncertainty blocks planning only when material to a managed enforcement decision.

## Implemented foundation

TESSERA-Base 0.0.183 registers nine native GenericInterface invokers under NetXMS. Import the supplied `var/webservices/examples/TESSERANetXMS.yml` through Web Services, then configure its HTTPS Host and dedicated read-only API identity. The template is inert until configured; it is not automatically installed over an administrator's Web Service. Installation/upgrade/reinstallation register file-based modules and introduce no database schema or CMDB fields.

| Invoker | Input | Purpose |
|---|---|---|
| ServerInfo | empty object | Version/build discovery |
| Status | empty object | Server status response |
| Objects | empty object | Accessible objects |
| ObjectGet | ObjectID | Full object details, including relationships when exposed by the server |
| Alarms | optional rootObject | Accessible alarms, optionally under a root |
| AlarmGet | AlarmID | Alarm detail |
| CurrentValues | ObjectID | Current DCI measurements |
| DataCollection | ObjectID | DCI configuration |
| History | ObjectID, DCIID, timeFrom, timeTo; optional maxRows | Time-bounded DCI history, at most 1000 rows |

The connector is the configured native HTTP::REST Web Service plus these invokers. It uses the existing authorized AutomationWebService provider, not a second HTTP client or script mapping language. Example scripts and explicit binding placeholders are in `examples/netxms/`. An authorized backend must inject exact AllowedCalls after existing actor/publication/target checks. The trusted OS AutomationTest command is available for acceptance testing; installing this package does not grant stored scripts or portal users general outbound access.

Scripts cannot supply a URL, token, arbitrary query/NXSL or remote command. Endpoint routing is fixed to documented GET operations; TLS verification and a 1–60 second timeout are required. Configure a dedicated NetXMS account with access only to the intended objects and no credential-view or execution privileges. Its API credential belongs in protected Web Service configuration; SNMP/agent/device secrets remain in NetXMS or AWX. Do not put tokens in examples, script parameters or tickets. Native transport debug logging can expose request headers or raw response content; restrict administrative debug access and avoid production debug logging.

Every successful call returns Source, WebserviceID, Operation, RetrievedAt (Unix seconds), Request, Completeness=UNVERIFIED and the complete bounded Response. RetrievedAt is collection time, not proof of the underlying measurement's freshness. Unknown response fields are retained. Errors do not echo remote bodies. Lists may be empty; failed calls must not be interpreted as healthy/empty inventory. The response bound is 4 Mi characters, 50000 tree nodes and depth32 after transport decoding; it is not a streaming HTTP download limit. Oversized responses fail rather than silently truncate. For large estates use a suitably restricted account until a verified server-side filtering/paging profile is added. Never follow arbitrary remote pagination URLs. Raw observations may be sensitive and must not automatically become customer-visible articles.

## Compatibility and live acceptance

Owner intends to install the latest NetXMS and has no running server yet. The official site advertised 7.0.1 on 2026-10-26. This connector targets the built-in `/v1` API documented at the reference below; development documentation is not proof every operation exists in a particular release. No compatibility with the removed legacy standalone WebAPI is claimed. Pin the installed release for reproducible acceptance, record ServerInfo and verify each required operation against that deployment before enabling automation. Missing/unsupported endpoints fail; there is no silent legacy fallback.

1. Install NetXMS, enable its resource API, configure HTTPS and a restricted observation account.
2. Install TESSERA-Base183 using the existing native/package-container upgrade process; do not replace files in running Pods or overwrite the prepared182 artifact.
3. Import/configure the example Web Service. Bind its actual ID to the example automation; use actual authorized object/DCI IDs.
4. Verify ServerInfo, Status, one ObjectGet, current values, a bounded history window and empty/nonempty alarm results. Verify expired token, access denial, unavailable server and untrusted CA all fail without publishing a healthy result.
5. Compare returned device/service relationships and measurement timestamps with the NetXMS console. Exercise restart/retry reads. Persist selected snapshots through the calling execution workflow where needed; the read connector does not automatically create a history row per call.

## Core observation roadmap

Build on the same connector for business-service dependency graphs, service health/availability, network topology/path evidence, alarm correlation and enterprise observation. Dedicated topology/path/SLA operations require verified release-specific endpoints and representative responses; this release does not invent routes or use unrestricted remote scripts to emulate them. ObjectGet/Objects retain supplied relationship data but do not yet normalize a business-service graph or calculate impact.

The next layer should normalize source instance/object identity, observed/source timestamps, context, severity, dependencies, completeness and raw evidence references. Automation owns the CMDB correlation mapping; no new Dynamic Fields are guessed. Reconcile duplicate and out-of-order alarm observations before ticket creation. Correlate by source instance plus stable alarm identity; explicit clear/reopen handling and authorization must precede automatic incident actions. Polling schedules, push ingestion, durable correlation, automatic ticket creation and a service-topology UI are not implemented by these invokers.

Prometheus metrics collection is a separate data path. NetXMS scraping Prometheus/OpenMetrics endpoints is documented; that does not establish a NetXMS exporter for Prometheus to scrape. Verify an available export path or implement a separate bounded exporter with stable metric names, explicit units/types, allowlisted labels/DCIs, source timestamps and scrape health. Do not push high-volume samples through TESSERA tickets or turn arbitrary object attributes into metric labels. No exporter or Prometheus deployment is included here.

## References

- https://netxms.org/ (release listing, checked 2026-10-26)
- https://docs.netxms.org/admin/dev/integration/rest-api/ (built-in API and account/token model)
- https://docs.netxms.org/admin/dev/objects/object-model/ (objects and business services)
- https://netxms.org/documentation/userguide/management-console.html (business-service availability)
- https://github.com/netxms/netxms/releases (Prometheus/OpenMetrics scraping direction)
