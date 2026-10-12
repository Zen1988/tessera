# Agent security and portal email design — 2026-10-12

## Confirmed scope

Protect assignment of TESSERA::SYSTEM and TESSERA::SECURITY through backend agent portal only. User also requests special agent-portal 2FA and a new custom email authoring/notification engine with copy/paste images, saved content and links that open portal context, with future SSO integration. No new schema names assumed. These additions are design requirements; 0.0.147 only contains previously tested interpreter hardening.

## Reserved-role implementation boundary

Exact fields are ZTSMSupportAssignment-Role, ZTSMSupportAssignment-UserAccount and ZTSMSupportAssignment-SupportProfile. Validate both previous and proposed assignment: changing account/scope/status, deleting or restoring a historical assignment can grant or remove permission even without changing Role. Resolve role identities from authoritative GovernanceRole objects, fail closed on missing/ambiguous references and protect both reserved names. GovernanceRole creation/rename/deletion and catalog/definition modifications cannot manufacture a reserved capability through an ordinary role's existing assignments.

Trace findings: AgentGovernanceObjectEdit writes GovernanceObjectAdd/Update. Object and Version APIs accept caller parameters; VersionAdd/Update write Dynamic Fields. Document/workbook and bulk controllers provide alternate entry points. A controller-only check does not cover version or direct DynamicField backend writes. Native mutations must share an authorization context issued from verified agent session and existing backend class permissions, with audit. Caller-supplied Source=Agent or UserID alone is not evidence of an authenticated agent request. Bootstrap defaults must remain idempotent and must not grant user assignments. No broad new restrictions on ordinary assignments are intended, but compatibility must be tested before deployment.

Outstanding authorization choice: who manages these assignments in the portal (existing OTOBO admin group or a dedicated role-administration group). Possession of TESSERA::SYSTEM/TESSERA::SECURITY alone does not imply role-management authority. Their direct-change bypass cannot override reserved-role protection. Until decided, do not silently allow all agents or self-assignment.

## Special 2FA — scope awaiting confirmation

Local Auth.pm invokes configured AuthTwoFactorModule; Auth/TwoFactor/GoogleAuthenticator.pm verifies a time-based token and can allow an empty secret when configured. That existing login component does not establish recent, action-bound MFA evidence or token replay prevention for a privileged mutation.

Proposed sensitive-action authentication contract, pending user confirmation: challenge before reserved-role management and sensitive-request release; short-lived proof bound to agent, session and exact operation/proposal hash; consume once; no fallback bypass for unenrolled users; attempt throttling, audited failure/success and session invalidation. Enrollment/reset/recovery are also privileged operations and must not allow a caller to replace their own security proof unchecked. Authenticate through supported standard factors, not custom cryptography. Corporate-security frontend approval requires its own authenticated reviewer checks; agent-only enrollment or login does not authenticate that frontend action. No MFA configuration/enrollment changes performed.

## Custom email engine

Authoring: rich-text template/draft editor; paste/drop/upload images into managed storage; save and reopen drafts with stable image references; version templates; preview subject, HTML and plain text with sample data. Shared templates and per-message drafts are different records. Uploads are permission-checked, bounded and verified by actual media content; reject active content. Do not fetch arbitrary image URLs on the server. Sanitization applies at save and render; no scripts, executable expressions, event attributes or unsafe links. Template placeholders are allowlisted, escaped and supplied by permission-aware services; recipient and header validation prevent header injection.

Delivery: build recipient-authorized event DTOs and render approved templates; retain existing SMTP/mail queue as the delivery adapter while introducing a new TESSERA authoring/rendering layer. Local Email.pm already builds HTML/plain-text alternatives and multipart/related inline image attachments using ContentID and inline disposition. Persisted image identifiers are transformed into CID references for sending; do not include session-bound internal image URLs or embed broadly accessible customer assets. Record event/template version, recipient and delivery status with deduplication/retry; no email sent during design.

Portal links: a notification action identifies a registered internal destination, object and allowed action. Click opens the portal; login or future SSO completes first; return to the same destination; server resolves object authorization and current workflow state again. No open redirects, credentials or bearer mutation authority in links. No state change on GET, email click, mail preview or link-scanner fetch. Final approval/release/update is an explicit authenticated portal submission with CSRF and any required MFA. Forwarded email grants no recipient entitlement. Links to revoked/completed/inaccessible requests show a safe unavailable result.

Illustrative flow (not yet the selected first example): agent releases a hidden request -> one governed security-review ticket -> corporate security receives summary and Review request button -> portal login/SSO -> authorized exact-version review -> explicit approve/reject -> runtime independently authorizes approved changes and records evidence. The unreleased backend record is not disclosed by customer notifications. Review role does not grant blanket operational-ticket visibility.

## Delivery sequence and acceptance

1. Confirm role-management actor and MFA scope; enforce native assignment and role-definition mutation boundaries with negative tests for customer/API/import/automation/direct field and role-rename paths. Preserve ordinary assignment behavior and fresh/upgrade/reinstall.
2. Implement authenticated, operation-bound MFA, enrollment/recovery and tests for replay, stale proof, altered target, missing enrollment and session mismatch.
3. Build email editor/storage/renderer and one agreed notification example. Verify draft images survive reopening; HTML/plain-text/CID MIME output; hostile markup, unsafe URL, recipient leaks and duplicate delivery denial.
4. Integrate governed review-ticket event and registered portal destination. Verify logged-out return, forwarding, unauthorized target, link-scanner GET, expired request, approval version mismatch and future SSO behavior.

Known decisions still pending: first notification example; role administrator; extra-action versus all-login MFA; template/storage field contracts; retention and mail domain; supported SSO provider. Existing runtime notifications, login settings and role assignments remain unchanged. Do not report any of these features as deployed.
