# Customer portal assessment — 2026-11-11

Status: started; live testing blocked by hostname resolution from assessment shell. Not a completed VAPT or certification.

Owner authorizes assessment of https://tessera.ncs.local/otobo/customer.pl?Action=CustomerDashboard including SQL injection, password brute-force protection, XSS and other portal vulnerabilities, with source fixes for confirmed issues. Scope remains this application; no unrelated hosts, destructive data changes, load testing or credential spraying. Dedicated disposable account, maximum failed-attempt budget and writable test records requested; not yet supplied. No login guesses or injection payloads sent.

## Evidence collected

- Initial unauthenticated HEAD request failed before connection: curl error6, could not resolve tessera.ncs.local. Requested reachable internal IP while retaining hostname/TLS validation.
- Existing local tests CustomerRuntimeRequestSecurity, CustomerConfigItemEntitlement and LinkedTicketReadPermission pass:3 suites,98 assertions. These do not establish deployed configuration or complete SQLi/XSS resistance.
- Existing package runtime CustomerTicketZoom template includes innerHTML insertion and ExecuteScripts helpers. This is a source-review candidate, not confirmed exploitable XSS. Trace attacker-controlled text and encoding before changing; preserve workspace initialization.
- CustomerAuth tracks UserLoginFailed; this alone does not prove effective throttling/lockout across native/LDAP/SSO backends or replicas. Verify active configuration and runtime behavior with dedicated identity.
- Previously confirmed legacy Elasticsearch override causes quick-search500; prepared compatibility replacement is required in Base189. Availability defect, not evidence of SQL injection.

## Remaining assessment

Inventory unauthenticated/login/recovery and authenticated dashboard/search/ticket/workspace/asset/upload/download/API paths. Test SQL input binding using bounded boolean/error probes without extraction or delay amplification; reflected/stored/DOM XSS using inert markers then isolated execution proof; account isolation/IDOR and entitlement boundaries; CSRF/method enforcement; session fixation/logout/cookie properties; redirects; upload/download authorization and path handling; security headers/TLS and sensitive error disclosure. Test throttling with at most5 failed logins only after explicit dedicated-account/budget confirmation. No real-user lockouts or password lists.

For each finding retain route, sanitized request/response, identity/target scope, reproduction, affected authoritative source/package, impact, fix and regression evidence. Keep suspected/static findings separate from live confirmed findings. Package confirmed corrections upgrade-safely; do not blanket-disable UI features, weaken permissions or build a generic security subsystem without evidence. Deployment/live retest remains required.


## Connectivity update

Windows hosts maps tessera.ncs.local to10.0.1.72. Sandbox cannot resolve/connect; approved unsandboxed curl with explicit --resolve reaches TLS. Standard validation fails SEC_E_UNTRUSTED_ROOT in this client. A credential-free diagnostic with --insecure returns200 and login HTML for CustomerDashboard (not authenticated dashboard access). Captured outputs/portal-initial-headers.txt and portal-initial-login.html. Headers include nosniff, SAMEORIGIN and Secure/HttpOnly/SameSite=Lax browser-test cookie; no HSTS or CSP observed on this response. This is an observation, not complete session/TLS assurance or a confirmed exploit. Internal CA trust must be configured before sending test credentials.

Owner clarifies AD owns authentication lockout; proposed5 attempts is assessment cap, not current configuration. Failed-login tests remain deferred pending disposable identity and AD policy. Normal customer accounts requested; two separate accounts permit cross-account isolation checks. Admin only needed for later configuration review.


## Initial live injection probes completed

Ran seven bounded credential-free requests against authorized portal IP10.0.1.72: baseline, two reflected-XSS markers, three synthetic nonexistent-login SQLi comparison probes and one malformed unauthenticated ticket ID. Synthetic password only; supplied customer credential not used or saved. No destructive statements, extraction, delay probes or brute-force loop. Evidence: outputs/portal-vapt/unauthenticated-probes.json; reproducible runner beside it.

All three login SQL baseline/quote/boolean POST responses remained login HTML200 with identical25316-byte lengths and no checked SQL-error signatures. This does not prove SQLi absence, especially with AD backend. XSS probes reflected the marker without the exact raw SVG payload; no browser execution test performed. Malformed ticket identifier returned400. No confirmed injection exploit from these probes. TLS verification was bypassed only for credential-free probes. Exporting public Windows ROOT/CA certificates did not resolve trust failure; authenticated probes require trusted internal root/intermediate or independent endpoint-certificate verification. No package/security fix inferred from negative limited probes.


## Authenticated attempt and CORS update

Owner explicitly authorized bypassing self-signed TLS verification for this test endpoint. Used supplied test login via stdin, never stored password in runner/results; transient cookie file deleted in finally. Login reaches an Info privacy-policy acceptance page, not the dashboard. Initial runner insufficiently distinguished this gate from authenticated content; therefore all purported authenticated SQLi/XSS results are INCONCLUSIVE and must not be treated as negative findings. Redirect-aware rerun confirms gate; malformed IDs400. One quick-search boolean-shaped request and logout yielded500; no SQL-error signature or exploit demonstrated, and gate/replica routing may affect this. Requires correlated server logs. Results: authenticated-probes.json; login-diagnostic.json. No privacy policy accepted or account policy fields changed.

Six credential-free CORS requests: GET and OPTIONS with arbitrary HTTPS origin, null origin and hostname-suffix trap. CustomerDashboard responses200 without Access-Control-Allow-Origin or Access-Control-Allow-Credentials. No permissive CORS found on this unauthenticated route; authenticated/API route coverage pending. outputs/portal-vapt/cors-probes.json.

Official OTOBO advisory https://otobo.io/en/security-advisory-httpbasicauth-authentication-bypass/ describes client-supplied Remote-User fallback in HTTPBasicAuth configurations, fixed11.1 Beta3; distinct from CORS. Installed banner Beta2 alone does not prove affected backend or missing backport. Need active authentication backend and effective proxy/header behavior verification; no identity-header bypass probes performed yet.


## Authenticated injection batch after owner accepted privacy policy

Test account now reaches Dashboard200. Dedicated authenticated run exercised actual CustomerTicketSearch Subaction=Search with TicketNumber baseline, quote, SQL boolean-shaped input and SVG marker. These four responses200, identical25911-byte header+body captures, no checked SQL-error or raw SVG marker. Malformed TicketID quote/boolean returned400. Dashboard marker produced no raw reflection. Note earlier Fulltext-only requests loaded search form and do not constitute submitted search coverage; use authenticated-active-search-probes.json for submitted-handler evidence. Search stores normal last-search preferences as part of its native behavior; no ticket/article/asset writes performed.

Three authenticated dashboard origins (arbitrary, null, suffix trap) returned no Access-Control-Allow-Origin or Access-Control-Allow-Credentials. These plus earlier six anonymous probes do not cover all APIs or prove absence of CORS vulnerabilities elsewhere.

All three authenticated quick-search quote/boolean/SVG requests return Apache500. No injection exploit shown; known legacy override mismatch prevents assessing these paths until replacement deployed and logs correlated. Session logout succeeded and transient cookie file deleted. No stored-XSS/browser execution, SQL extraction, destructive commands, load testing or brute-force attempts on testuser1 performed. Negative marker/error-signature checks are limited screening, not complete proof.

Three isolated credential-free identity-header requests (baseline, Remote-User:testuser1, X-Forwarded-User:testuser1) all return Login200; no customer login bypass reproduced for this identity and route. Local HTTPBasicAuth source still includes client-header fallback described in vendor advisory; active backend/deployed bytes and backports need review before declaring it patched or applicable. No admin identities tested.

Evidence: outputs/portal-vapt/authenticated-probes.json, authenticated-active-search-probes.json and identity-header-probes.json. No passwords, cookie values or full ticket contents saved in these reports.


## Stored-XSS test — browser access restored; service selection blocked

Owner selected Firewall Policy / firewall rules creation and explicitly requested stored JavaScript injection testing. Draft HTTP code-marker screening completed previously (outputs/portal-vapt/code-injection-draft-probes.json):8 JavaScript/template/Perl/Bash-shaped inputs returned new-ticket200 with no checked raw script/event element or evaluated marker; no StoreNew or saved ticket. These are draft screening only, not stored-XSS/browser execution acceptance.

After owner opened portal, CUA could read Edge URL. Owner regular window shows Zen; created isolated InPrivate window196634 to preserve owner session. Confirmed authenticated dashboard Welcome Test and new-ticket requester Test test <testuser1@ncs.local>. Service field displays Not available with ServiceRequest; selecting Change also leaves it Not available. No Firewall Policy service is selectable. No ticket created, rich-text payload saved, permission granted or backend validation bypassed. Test window left at new-ticket form with Change selected.

Next unblock legitimate service selection for disposable testuser1 through normal administrator configuration (cause not yet diagnosed; do not assume company membership is authorization). Then submit one labelled harmless stored-XSS test ticket in owner-selected service with required test CI fields, inspect saved article rendering in customer and agent portals. JavaScript must only set visible/console proof markers, no credential read or external callbacks. Agent-view execution remains untested; current test customer cannot open agent dashboard.


## Stored-XSS customer result — ticket92 / article2049

Owner enabled service; selected Network::Firewall Policy::New/Modify in isolated testuser1 browser. Created one clearly labelled SECURITY TEST ticket ICAT-TI-20260000092 (ID375), through direct browser fetch/FormData with Body overridden to bypass editor filtering. Harmless script alert, data-image error-handler and SVG onload markers plus literal Perl/Bash text; no credentials read/exfiltration or external callbacks. One successful backend submission; earlier console quoting syntax error did not execute/send a request. Required governance fields selected from allowed UI lists: DEV, ALPS-L2 Meeting Room and Automated Border Clearance System. Native orchestration advanced parent to assess and created assessment child ICAT-TI-20260000093 (ID376). No approval/implementation action submitted.

Customer browser now shows exact saved ticket and original article2049. Live article endpoint returns200 with marker present; parsed response has0 script elements,0 SVG elements and no event-handler attributes. CSP script-src none. Article iframe lacks allow-scripts; description srcdoc sandbox empty (all restrictions). Console reports attempted script execution blocked in about:srcdoc; no payload alert observed. Perl/Bash remain literal text, not execution proof. No stored-XSS bypass demonstrated for these payloads/customer paths. Agent rendering pending; do not call this full stored-XSS acceptance.

Evidence: outputs/portal-vapt/stored-xss-customer-evidence.json. Browser warns invalid ms-allow-popups token, obsolete CSP referrer directive and blocked stylesheet loads. Record as compatibility/hygiene observations, not an XSS exploit or reason to weaken script/CSP/sandbox restrictions. No source/package security change in this step.


## State/approval forgery and search disclosure — live results

Owner explicitly requests customer-forged in-progress/approval actions and Elasticsearch disclosure testing. Owner excludes AD brute-force/lockout policy from TESSERA assessment; AD team owns it. Do not continue asking owner to implement AD lockout or run AD guessing tests. Portal authorization/session controls remain in scope.

Baseline parent375 shows assess, displayed owner Test test. Child376 direct/read-only URL returns403; no child mutation attempted because a readable independent state baseline was unavailable. Five parent probes: Approve via GET with session token, POST without token, POST forged token, POST valid token and Patch recovery to in-progress with acknowledgment and valid token. All403. State/owner read after each remain assess/Test test; final same. GET/missing/forged-token responses Security check failed; valid-token approval/recovery responses Access unavailable. No approval/state bypass demonstrated. Parent is ServiceRequest, not an Approval execution ticket: this does NOT validate approver separation on a genuine Approval ticket. Hidden StateBook/BlueBook/governance snapshot fields were not independently read, so do not claim byte-level snapshot invariance. Evidence state-approval-forgery-probes.json.

Search positive control own ticket92 direct200 and submitted TicketNumber search returns its actual result link/title. Owner-identified candidate ticket85 direct403; submitted exact TicketNumber search200 with no result link and no candidate number in response. This demonstrates one specific search/direct-access separation; not all record entitlements/APIs. Quick Elasticsearch requests for own92 and candidate85 both500 (one generic Apache error, one themed server error), no result links; inconclusive and not an access-control pass. Evidence search-disclosure-probes.json. Need deploy prepared compatible override and retest index freshness, caller-supplied identity/company filters and alternate ES/FAQ/asset APIs.

Owner says dialog can be acknowledged and second round loads. Current inspected test-browser AX shows no active OK/dialog or test-marker alert; old blocked-script console messages remain. No claim of observed alert execution.
