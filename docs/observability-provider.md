# TESSERA provider API: Grafana and Alertmanager (Base191)

TESSERA is the provider. It issues its own bearer tokens to separate machine identities; these are not AWX tokens or Grafana service-account tokens. No API identity has a portal password or agent session. Each identity binds immutably to an existing valid customer permission subject so current SupportAssignments and entitlements remain authoritative. It does not create or modify assignments, accounts, roles, Dynamic Fields, Books or workflow routing.

## Package and activation

Install TESSERA-Base-0.0.191.opm normally (fresh, upgrade or reinstall). The additive install hook creates the provider identity and key-binding tables, correlation ledger and a create-if-missing Web Service named TESSERAObservability. Existing service configuration, identities, keys and evidence are preserved. No tokens, live grants or alert targets are installed automatically. The existing API-key hash store is reused: plaintext tokens are never persisted by TESSERA.

Enable TESSERA::API::Enabled and TESSERA::Observability::Enabled in SysConfig only after configuration. Keep HTTPS and trust the internal CA from Grafana and Alertmanager. Allow Authorization through the ingress. Use the current Base191 image consistently in web, daemon and loader/init containers; restart workers after package deployment. MELT must be installed and its melt_object_activity_article table must use InnoDB; ingestion fails closed otherwise. This release does not rebuild the container toolkit or apply Kubernetes manifests.

## API identities and token lifecycle

Admin -> API identities and tokens (Action=AgentTESSERAAPIIdentity):

1. Create grafana-reader, select an existing valid customer permission subject, enable only report:tickets, report:alerts and report:risks. Specify allowed TicketQueueIDs and MELTObjectIDs. Queue scope limits candidate tickets; the existing requester/SupportAssignment visibility service must also authorize each returned ticket. Alert scope also requires MELT API capability and object entitlement. Risk data uses the subject's permission-filtered governed Risk Register. No company-only scope expansion.
2. Create alertmanager-writer with only ingest:alertmanager. Set a unique SourceName, one existing TargetMELTObjectID and a valid agent ActorID for audit evidence. The permission subject needs the existing MELT API capability/groups/SupportAssignment and access to the target. The payload cannot choose its own target or actor. No automatic MELT objects or entitlements are created.
3. Enable the identity and issue a named token with a 1-365 day lifetime. Copy the token once into the consumer's protected secret store. The administration page is no-store; later views show metadata and prefix only. No credentials in URLs, dashboard definitions or ticket scripts.
4. Rotate by issuing a replacement, updating/testing the consumer, then revoking the old token. Disable the identity to suspend all its tokens immediately. Revocation, expiry, subject validity and current capabilities are checked on every API request. Capability edits apply immediately to existing tokens. Identity permission subject cannot be changed. Revoke controls only operate on the selected identity's tokens. Existing CLI-created keys cannot call these endpoints without an explicit provider identity binding.

The standard APIKey CLI remains compatible for the older staged API. No old key receives observability grants implicitly. API identities grant access only to these four capabilities; they do not authenticate as agent users or authorize arbitrary ticket/CMDB/governance writes. The registry is extendable in code for later provider endpoints; it is not OAuth/OIDC token issuance.

## Endpoints and response shape

Base URL:

    https://tessera.ncs.local/otobo/nph-genericinterface.pl/Webservice/TESSERAObservability/v1

| Method/path | Capability | Result |
| --- | --- | --- |
| GET /tickets?Limit=100&Cursor=0 | report:tickets | Minimal authorized ticket metadata; no articles, attachments or raw dynamic fields |
| GET /alerts?Limit=100&Cursor=0 | report:alerts | Authorized current alert state and selected labels; no raw annotations |
| GET /risks?Limit=100&Cursor=0 | report:risks | Governed Risk Register rows, resolved Column1..ColumnN values and column-label metadata |
| POST /alertmanager | ingest:alertmanager | Accepted, Changed and Duplicates counts after committed MELT evidence |

Send Authorization: Bearer <TESSERA-issued-token>. Reports return {"Rows": [...], "NextCursor": null}. Risks additionally return Columns mapping ColumnN to current configured labels. Limit is 1-200. A non-null NextCursor means another page exists. Tickets scan only configured queues and can return an empty page with a non-null cursor when candidates were denied; continue until null. Ticket/alert cursors are IDs, risk cursors are offsets in the current authorized register. Cursors are not snapshot isolation: refreshes during data changes can change page membership. No global totals are disclosed. Rebuild a complete dashboard query from Cursor=0 on each refresh. Do not count just the first page as a global total.

Ticket columns: TicketID, TicketNumber, Title, State, StateType, Type, Queue, Service, Priority, CreateTime, ChangeTime. Alert columns: AlertID, Source, Fingerprint, Status, MELTObjectID, ChangeTime, AlertName, Severity, Instance, StartsAt, EndsAt. Risks add register status/outcome/governance/review metadata and ColumnN display values. They preserve the existing final-governance-decision/assessment-iteration rules; filling an assessment or changing a ticket state does not manufacture an approved risk.

HTTP 200 acknowledges success, 400 rejects malformed payloads, 403 denies identity/capability, 405 denies wrong methods, 413 rejects oversized bodies, and 503 means scope/dependency/storage could not complete. Report responses and token pages are no-store. No CORS wildcard or browser-token flow is enabled. Grafana should query from its backend. Invalid or truncated webhook groups must be corrected rather than silently acknowledged.

## Grafana

Install the Infinity data source plugin. A secret-free provisioning example is packaged at var/tessera/examples/observability/grafana-datasource.yml. Supply TESSERA_GRAFANA_TOKEN from the deployment's protected secret store, restrict allowedHosts to the TESSERA origin and trust its CA; do not disable verification. Use the backend JSONata/JQ parser and select Rows. Query /v1/tickets, /v1/alerts or /v1/risks with the paging contract above. Risk ColumnN labels come from Columns, preserving the configured Risk Register presentation.

Start with refresh intervals of 60 seconds or longer. Risk reporting currently reuses the full existing authorized Risk Register calculation before output pagination; it is not a time-series warehouse or a preaggregated statistics API. Consumer pagination limits and query caching must not silently turn partial pages into totals. No live Grafana dashboard or plugin installation is claimed by this package.

## Alertmanager

Merge the packaged alertmanager-receiver.yml receiver fragment into the existing routing configuration deliberately. Mount its dedicated TESSERA token as the credentials_file and internal CA as ca_file. Use send_resolved: true. Group notifications by alertname and instance (and cluster where appropriate) so each group remains below 100 alerts and 1 MiB. max_alerts: 100 is an emergency bound: if truncatedAlerts is nonzero TESSERA rejects the notification; fix grouping instead of accepting lost alerts.

The endpoint consumes the standard v4 webhook. It stores the latest cycle/status per SourceName + fingerprint and writes a MELT activity entry only for a new recurrence or firing/resolved change. Repeated firing updates (including changing endsAt) do not duplicate activity. A resolved cycle cannot be reopened by a delayed firing; an older resolution cannot close a newer recurrence. Omitted alerts are never inferred resolved. At most 10,000 fingerprints per source are accepted; plan retention/archival before growth reaches this bound. Immutable historical evidence remains in MELT activities while the correlation row retains the latest state. Annotation changes without a lifecycle change are ignored in this first version.

A source-level MariaDB advisory lock serializes deliveries across web replicas. State and activity are committed in one transaction; failures roll back and return non-2xx so delivery can retry. URLs, labels and annotations are treated as data: no fetching generatorURL, scripts, shell commands or automatic transition execution. Receiving resolved does not close a ticket, approve a change, alter a Book or re-evaluate governance. Ticket escalation remains a later governed integration; this release does not retire MELT or delegate all its responsibilities to Prometheus.

## Acceptance before Kubernetes rollout

Verify install from188/190, repeat installation, administrator permissions/CSRF/token visibility, actual MariaDB rollback and concurrent/retried webhook deliveries, Authorization forwarding/TLS/CA, token expiry/rotation/revocation, subject/SupportAssignment revocation, dashboard pagination and risk rows, and malformed/truncated webhook handling. Live Linux/native OTOBO, Grafana and Alertmanager acceptance is pending; local tests use isolated service/database doubles plus native provider routing/response and template code. REST::Client is absent on the local Windows Perl; the native-provider test stubs only that unused requester library. Existing unrelated local changes are excluded from this package.

## References

- [Grafana Infinity authentication and provisioning](https://grafana.com/docs/plugins/yesoreyeram-infinity-datasource/latest/configure/)
- [Grafana Infinity query and backend parsers](https://grafana.com/docs/plugins/yesoreyeram-infinity-datasource/latest/query/)
- [Alertmanager webhook and HTTP authentication configuration](https://prometheus.io/docs/alerting/latest/configuration/)
