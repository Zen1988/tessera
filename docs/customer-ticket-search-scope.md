# Base196 customer ticket scope and counts

IPC's existing TESSERA ticket permission rule grants global ticket read access.
Workspace and overview already classified IPC through customer IPC rw membership
or the matching agent IPC rw membership; no company/requester requirement belongs
to that global read scope. This patch does not confer write or agent-session access.

The customer Elasticsearch controller previously injected company/requester
selection even for IPC, and its backend always built native customer/company-group
restrictions. Base196 reuses the existing ZTSMUserIDCheck::_IsIPCAgent classifier
through CustomerGlobalTicketRead in the Elasticsearch backend. The controller
omits its implicit company/requester selection only for this read capability;
the backend suppresses native implicit narrowing for the same actor/capability.
Explicit customer/requester scopes remain exact narrowing terms. Non-IPC and rw
paths retain native customer/multitenancy behavior. No IPC grant is inferred from
company identity, URL parameters, a numeric agent ID or an administrator session.

CustomerUserID is retained throughout; no UserID1 impersonation. Fulltext still
searches external articles/attachments and permitted customer Dynamic Fields,
with internal article/attachment source removed from IPC FULL responses. Other
Elasticsearch object types (ConfigItem/GovernanceObject/MELT/FAQ) are unaffected.
Non-IPC SupportAssignment-wide Elasticsearch expansion is not introduced by this
IPC-specific correction; it needs a separately reviewed per-ticket scope contract.

Quick preview uses existing Elasticsearch::QuickSearchShow###Ticket Count(default10),
not workspace MaxTickets. Native matched Total is displayed separately as Showing
X of Y matching tickets. Results still depend on query text and indexed data;
not every fulltext search equals all database tickets. No new indexed fields or
schema are introduced; stale index diagnosis remains separate if discrepancies persist.

Workspace previously truncated permitted rows to MaxTickets(default9), then
reported9 as total. MaxTickets now determines page size; count is calculated
before pagination. Missing/invalid/zero page size falls back to9; positive administrator limits remain in effect. Previous/Next links preserve Include closed mode and page
bounds; invalid/stale pages clamp safely. All IPC candidates are retrieved with
COUNT then ARRAY Limit=>Count, matching the overview strategy, and existing
ZTSMUserIDCheck ro checks apply before counting/paging. Default mode excludes
StateType closed; Include closed includes historical closed tickets. No workspace
date filter. Overview aged/closed/failed cards remain distinct overlapping sets;
closed-card date period is not an all-time closed count.

Delivery: TESSERA-Base0.0.196 standard native package install/upgrade/reinstall.
Existing overlay bootstrap deploys modules/templates; no DB migration/ACL/new
DynamicFields/SysConfig rewrite. Existing MaxTickets/preview Count customization
preserved. Install source package, rebuild image and matching upgrade bundle,
then existing controlled target upgrade, consistent worker restart/cache refresh.
Do not reinstall retired one-time recovery or weaken company permissions globally.

Package is built from authoritative195 OPM, excluding unrelated source edits.
469 payloads:463 byte-identical,4 changed(workspace module/template, Elasticsearch
backend, release descriptor),2 added(quick-search module/template). Descriptor
version196 explicitly accepts195. Tests:52 new assertions plus existing dashboard,
multitenancy, native overlay fresh/upgrade/reinstall and4 release metadata checks.
Offline desktop and390px-container rendering inspected; live native ES index,
portal/keyboard/mobile and195-to196 install acceptance remain pending.


Base197 replaces the ticket quick-preview limit with bounded pages using the same
configured Count (default10). COUNT and FULL requests retain the same actor,
fulltext and permission scope; FULL adds validated From and stable TicketID tie
breaking. The dialog shows a range and total, Previous/Next and page count.
Only the result area scrolls; header, summary and pager remain reachable.
Customer-only delegated AJAX preserves native session handling, rejects stale or
closed-dialog responses, and recovers controls on failure. FAQ is unchanged.
No index schema, governance role, Redis or ticket data changes are introduced.
Deep pagination remains subject to the Elasticsearch backend result-window limit;
this release does not change that cluster setting.363 matches use37 default pages.
Base197 package and payload comparison are recorded in outputs/base197-validation.json.
Local tests pass; actual deployment and native index acceptance remain pending.
