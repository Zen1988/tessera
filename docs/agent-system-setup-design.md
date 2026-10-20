# Agent system setup and Central identity provisioning

Requested and clarified 2026-10-19. Confirmed requirements below; not implemented or deployed.

## Requested agent functions

- Provide a New setup entry point in the backend agent interface.
- Start the wizard with organization name and description. Save these as the first Organization governance record using the existing class and description representation. Next page asks whether to create another Organization and supports repeating that step before continuing setup. Preserve the actual created record identifier as setup progress; do not assume its database ID is 1. Back/refresh/retry must not duplicate the record, and existing installations must not be mistaken for empty installations.
- Include ticket numbering reset and ask for the ticket prefix using the existing system configuration setting. Confirm whether prefix means SystemID, TicketHook, or another existing exported setting before binding the form. Do not invent a replacement configuration field.
- Provide create CSR, complete CSR, and renew CSR actions for future HTTPS/SSL deployment. Complete CSR means accepting the issued certificate and chain for the pending request; validate matching public key, hostname and chain before activation. Renewal must preserve the currently working certificate until replacement succeeds. Private keys must remain protected on the serving host and must not be exported through this page. Exact TLS termination/deployment target remains to be selected.
- Ticket reset deletes all tickets and restarts numbering, rather than changing future numbering alone. Include ticket-dependent records, articles, attachments, links and external execution references in the implementation dependency inventory. Resolve the actual counter/generator storage before implementing reset; avoid partial deletes and orphaned evidence.
- CMDB reset removes asset records. Governance reset is a separate button and removes instance-specific governance data for recreation, including Application, Organization and other applicable governance objects. Enumerate classes and dependencies from current exports for a reviewable preview; do not conflate asset reset with governance reset. Keep package definitions/default bootstrap behavior separate from administrator-authored instance records.
- Support a Central function that automatically creates a missing human identity without a password; those identities must not log in.

## Implementation boundaries

New setup is an explicit administrative operation, never a package-install or upgrade side effect. Opening the page must not mutate data. Destructive reset requires a concrete scope preview and explicit confirmation at execution. Existing ticket IDs, numbering counters, and displayed ticket numbers are different concepts; confirmed deletion scope does not by itself establish the safe database reseeding implementation. Serialize reset against runtime/import workers and account for database and filesystem failures before enabling execution.

Central provisioning must use a stable authoritative identity key, reuse an existing unambiguous match, avoid duplicates on retries/concurrency, and reject ambiguous matches. Missing identity data must not be fabricated. Determine which native account or governance object represents the human from the authoritative exports before implementation. Creating an identity must not assign support scope, reserved capabilities, or login privileges. Enforce non-login status at authentication boundaries, including alternative authentication and password recovery; an empty password alone is insufficient. Existing accounts must not be silently converted or have credentials removed.

## Central instance

Central is a separate analysis/data-store instance and does not serve customers. Authorized staff may need analysis access; imported customer identities must never become login accounts. Ticket import must resolve missing referenced assets and user IDs into local records without enabling customer access. Preserve source instance plus source object identity so identical ticket IDs, user IDs or asset IDs from different instances do not collide. Retries must reuse the same records. Missing references must not be silently dropped, and ambiguous imports must report an actionable error. Do not execute imported governance code or launch ticket workflow just because historical data is ingested.

The existing TicketTable CSV importer requires an existing local ticket_id and updates that ticket; it is not a cross-instance ingestion implementation. Central import requires a separate defined input contract and provenance mapping. Trusted import source, transport, reference attributes and schema mappings remain to be selected from actual exports; no replacement Dynamic Field names are authorized by this design.

## Confidential data reveal

- Trusted client IP ranges default to an empty list. A trusted client IP bypasses the additional password prompt. All other locations require password verification before confidential data is revealed.
- Mask confidential values by default where reveal is not authorized. Requested IPv4 presentation keeps two octets visible, for example 192.168.10.20 becomes ***.***.10.20; this example assumes the last two octets are retained. Exact masking for IPv6 and other confidential field types requires definition.
- Successful verification grants a server-held reveal permission for 10 minutes, bound to the authenticated actor/session and network context. Use a fixed expiry; ordinary activity must not extend it. Expiry hides confidential information again and requires a new prompt, without logging the user out or blocking ordinary work. Network/session changes invalidate the reveal proof.
- Verify the current actor's password through the supported authentication backend, with CSRF protection and attempt limiting. Do not retain the password or treat this repeated password check as an independent MFA factor. Future passwordless/SSO accounts need a supported fresh-authentication mechanism.
- Reuse one backend disclosure policy for pages, detail views, search responses, API responses, downloads and exports. No raw protected value in HTML attributes, hidden DOM, browser state, tooltips or cached responses while masked. Shared caches must not retain revealed responses. Recheck permission when generating and delivering exports; a pre-generated unrestricted file must not bypass the policy.
- Derive client address from the actual peer or explicitly configured trusted reverse proxies. Do not trust arbitrary forwarded headers. Fail closed on malformed addresses/ranges or unresolved policy. An empty trusted list means every location requires verification; it does not disable masking.
- Define confidential field classification against current exported fields before enforcing the feature. IP values inside free text, articles, attachments and imported documents need an explicit handling strategy; structured-field masking alone must not be described as complete protection.
- Browser copies and files already downloaded cannot be withdrawn after expiry. The expiry governs subsequent server disclosure; the UI should remove revealed values at expiry and recheck on focus/reload, without claiming it can erase prior copies.

## Source trace

Current package is TESSERA-Base 0.0.174 in Kernel/Package/GovernanceDB/TESSERA-Base.sopm and the matching generated OPM. No dedicated CSR/Central setup implementation found in that package. Native Ticket.xml defines Ticket::NumberGenerator, Ticket::NumberGenerator::CheckSystemID and counter formatting options. This does not establish which setting the requested prefix denotes.

## Pending decisions

1. TLS termination target (Apache, reverse proxy or another host), issuer and certificate deployment mechanism.
2. Exact reset class/dependency inventory and treatment of immutable system bootstrap defaults versus instance data.
3. Central import format, trusted origin authentication and stable cross-instance keys from real source exports.
4. Confidential field inventory, IPv6/free-text handling and confirmation of which IPv4 octets remain visible.
5. Exact existing SysConfig setting meant by ticket prefix; enumerate current values in the setup form.
