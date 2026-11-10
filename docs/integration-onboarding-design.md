# Reusable outbound integration onboarding

Design intake: 2026-11-02. Implemented source/package direction is documented in
[integration-onboarding.md](integration-onboarding.md). That guide supersedes
the initial storage and AWX execution alternatives below: TESSERA is the control
point and owns all Navis calls; native Web Service configuration stores secret
references, with secret contents in the existing protected mount.

## Goal and authority

Provide an agent administration function to onboard an external backend and
create/update its OTOBO GenericInterface requester Web Service. Navis is the
first preset; the framework must support other services and authentication
protocols through registered backend providers. This is machine authentication,
separate from customer login, AD membership and customer first-login onboarding.

Reviewed authoritative TESSERA-Base 0.0.185 SOPM/OPM and current transport,
AutomationWebService and native OpenIDConnect token implementation.
Protocol reference: https://github.com/Zen1988/navis/blob/main/docs/ONBOARDING_API.md
(retrieved 2026-11-02).

## Agent flow

1. Choose an integration preset or generic supported authentication method.
2. Supply a connection name, HTTPS service origin, token endpoint when applicable,
   client identifier, secret reference and requested scopes. Navis also records
   its operator-provided instance ID as metadata, never as a token parameter.
3. Validate configuration and explicitly test authentication. Report sanitized
   success, granted scopes and expiry; never display the returned token.
4. Create a disabled requester Web Service from the selected reviewed invoker
   template, or explicitly update the already linked service after a change
   preview. Attach the authentication profile by reference.
5. Enable only after configuration is complete. Authentication readiness and
   application/data readiness must be shown separately.

Navis consumer registration, source permissions and credential issuance remain
Navis operator tasks. Its API has no registration endpoint. This function accepts
issued credentials; it does not perform database registration or fabricate grants.

## Responsibilities

- Connection record: approved destinations, external instance metadata and linked
  Web Service identity. No governance routing or assignment decisions.
- Authentication profile: registered provider, token endpoint, client ID, secret
  reference, requested scope, credential revision and TLS policy.
- Authentication provider: validates its typed configuration and obtains runtime
  credentials. First provider is client credentials with HTTP Basic client auth.
- Transport integration: resolves the linked profile and attaches runtime Bearer
  authentication immediately before the approved request.
- Invoker template: typed application operations and request/response mappings.
  Navis paths belong here, not in the generic token manager.
- Existing authorized ScriptEngine bindings: continue selecting only registered
  service/invoker pairs. Scripts cannot choose URLs, credentials, provider modules
  or arbitrary headers. Onboarding does not grant script execution permission.

These are conceptual configuration properties, not new Dynamic Field names or
approved CMDB schema. Reuse existing native Webservice storage/API. Confirm the
protected profile storage and secret reference mechanism before adding schema.
Future protocols use a code-registered provider contract; arbitrary scripts and
module names submitted through configuration must not become authentication code.

## Navis first preset

- Token endpoint: configured HTTPS origin plus `/nauth/token`.
- POST `application/x-www-form-urlencoded`, Accept `application/json`.
- Form contains `grant_type=client_credentials` and optional nonempty,
  space-separated scope subset. Maximum encoded body is 4096 bytes.
- Form-encode client ID and secret separately, then join with colon and Base64
  encode for Basic Authorization. Credentials never enter form or query data.
- Require a successful HTTP response with a nonempty opaque `access_token`,
  Bearer token type and valid positive bounded expiry. Validate response size,
  headers and scope representation before use. Do not infer JWT semantics.
- Keep tokens in process memory, keyed by profile identity/revision, endpoint,
  client identity and normalized requested scope. No Redis, DB, file or browser
  token persistence. Refresh before expiry with bounded clock skew; no refresh
  token is expected. Never reuse tokens after a credential/profile change.
- Bound token requests and transient backoff. Sanitize errors rather than
  propagating endpoint response bodies. A 403 requires permission review.
- On protected API 401, invalidate the token; refresh and retry at most once only
  for an operation explicitly safe to repeat. No automatic ingestion/trace POST
  replay after ambiguous failures; Navis declares no idempotency-key contract.
- Rotation installs a new credential revision, invalidates cached credentials,
  verifies access and leaves old-client revocation to the Navis operator.
- Scopes do not grant source permissions. A successful token test does not prove
  build readiness, graph access, identity mappings or analysis availability.

## Existing extension points and compatibility findings

Native `Kernel::GenericInterface::Transport::HTTP::REST` supports BasicAuth,
OAuth and Kerberos. OAuth calls OpenIDConnect::TokenProvider using an account
name. The native OAuth2 helper supports client_credentials, but its current
`_SendRequest` passes raw credentials to authorization_basic and logs the entire
token response. REST OAuth debugging also records the token itself. TokenProvider
reads persistent tokens as well as cache. These paths are not sufficient evidence
of compliance with the Navis contract; do not simply configure an OAuth account
and claim secure support.

Implement the smallest maintained transport extension after checking packaged
overrides, and redact secrets across request, response, error and history debug
paths. Preserve existing authentication behavior and administrator-owned Web
Services. Do not globally change customer OIDC login semantics to onboard a
backend integration.

The existing Navis preparation workflow makes its Navis calls inside AWX. An
OTOBO authentication profile does not automatically authenticate AWX. Keep that
execution boundary explicit: either provide the same registered protocol in the
AWX execution environment with independently injected AWX credentials, or move
the application calls into reviewed TESSERA invokers. Never put a Bearer token or
client secret into ScriptEngine output, launch extra_vars or callback evidence.

## Backend and upgrade requirements

Restrict profile/service writes and credential tests to independently authorized
agent administration requests with CSRF protection. Recheck authorization on
every backend entry point. Possessing remote credentials grants no TESSERA role,
CMDB access or ticket lifecycle authority.

Use TLS verification and bounded requests. Approved HTTPS destinations may be
internal deployments; authorization must bind exact configured destinations.
Reject URL userinfo/fragments and redirects that could forward credentials to a
different destination. Do not let runtime payloads override token/API origins.

Use a protected secret backend; package files, exports, history, errors, logs,
articles and UI read-back must not contain plaintext credentials or tokens.
Record actor, profile revision, linked service and sanitized outcome only.

Fresh install adds definitions without remote calls or enabled credentials.
Upgrade/reinstall preserve existing records. Deduplicate by stable stored linkage,
not display name; repeated save/install cannot create another Web Service.
Existing services require explicit adoption/update and remain administrator-owned.
Partial save failures must leave no enabled, unlinked service or orphan credential.
No StateBook/BlueBook snapshots, routing or SupportAssignments are modified.

## Implementation sequence and acceptance

1. Confirm protected profile/secret storage and exact admin authority from current
   implementation; add backend profile validation and provider registry.
2. Implement client_credentials provider and secret-safe transport attachment.
3. Add idempotent native Web Service creation/update and a Navis invoker preset.
4. Add agent onboarding UI and explicit sanitized authentication test.
5. Resolve AWX versus direct-TESSERA execution boundary for the firewall workflow.
6. Verify fresh install, 185 upgrade, reinstall and subsequent upgrade.

Required tests: exact Basic form encoding including punctuation/Unicode; scope
encoding/body bound; invalid/expired/malformed responses; TLS/redirect failure;
token expiry and profile/credential/scope isolation; no secret persistence or
debug leakage; 401 safe retry once; 403 no refresh loop; POST no ambiguous replay;
unauthorized/CSRF/direct API denial; duplicate saves and failed saves; rotation;
preservation of existing services and customer login behavior.

Live acceptance requires a real operator-issued credential, approved scopes and
source grants, a completed build and authorized identity/enrichment scope. No live
registration, token exchange, service creation or package upgrade occurred during
this design intake.
