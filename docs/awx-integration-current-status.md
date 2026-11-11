## Base190 installation correction (2026-11-11)

Base189 is superseded: its direct Elasticsearch Filelist entry conflicts with ITSMConfigItemMultitenancy-11.0.2. Install Base190 normally; it deploys the identical compatibility replacement through the existing runtime overlay. Keep multitenancy installed. Restart all web/daemon workers after installation. A later multitenancy upgrade can restore its older module; reapply Base190 afterward. Live install acceptance pending.

# AWX integration checkpoint â€” 2026-11-11

Current authoritative package: prepared TESSERA-Base0.0.189; previously confirmed live release0.0.188. Historical review below predates the new extension. SOPM/OPM versions agree; all28 AWX/onboarding-related OPM payloads checked match package-source bytes. No189 package built. Owner previously confirmed Base188 deployed; verify live package/configuration before acceptance. Do not reinstall or downgrade to182 because older guides use that release number.

## Implemented

- Registered AWX job/workflow launch/status/stdout/events/nodes invokers; full JSON and paginated evidence.
- Durable execution intent, single-attempt callback dispatch, scoped callback authentication, deadline/replay/conflict protection and continuation/history.
- Inventory synchronization with separate restricted write identity; stable owned aliases, preserve manual records, no prune/delete, returned Limit constrains launch.
- Explicit authorized AutomationWebService provider/AllowedCalls and bounded ScriptEngine external result context. No default outbound privilege for stored/selection YAML.
- Harmless localhost polling and callback fixtures, managed-local-alias inventory fixture, console commands AWXTest/AWXCallbackTest/AutomationTest.

Local revalidation:6 AWX suites/204 assertions pass. These use simulated transports and do not prove live AWX acceptance.

## Previously confirmed live

AWX web rollout and two task replicas ready across k8s/k8s2 in October. Earlier rollout deadlock resolved. Observed AWX24.6.1; recheck current version. Gateway/login/API/job execution, operator strategy retention and controlled node-loss/job behavior are not established by replica readiness. Do not repeat resolved rollout fixes without fresh failure evidence.

## Live acceptance sequence

1. Read-only inventory of current native TESSERA web services (names/IDs/invoker types only), callback URL, daemon/handler configuration and history schema. Inspect AWX actual version, restricted API identity access, project synchronization, EE, localhost inventory and harmless template IDs. Do not dump transport credentials/debug payloads.
2. Run localhost integration-test.yml once through AWXTest; retain JobID, terminal JobGet status, artifact result, all stdout/events pages. On ambiguous dispatch resume reads/reconcile; never blindly launch again.
3. Run callback-test.yml once through AWXCallbackTest. Verify callback API reachability and EE trust of TESSERA CA, durable ExecutionUIDâ†’dispatch JobIDâ†’resultâ†’continuation, duplicate/conflicting/expired callback behavior and history after pod replacement. DONE alone is not final AWX success; verify JobGet too.
4. Use separate inventory write service to sync the single managed fixture alias, repeat without duplicates/manual changes, then launch callback-inventory-test.yml with returned Limit through AutomationTest. Confirm partial/uncertain sync blocks launch.
5. Bind a reviewed real read-only target/vendor and production CMDB extraction/mapping in existing automation. This feeds the separately pending AWX discoveryâ†’retained TESSERA evidenceâ†’Navis normalization/ingestion acceptance, not AWX-owned Navis orchestration. No credentials for Navis in AWX.
6. Negative compatibility/RBAC/TLS/prompt rejection/failure/output pagination tests, followed separately by controlled availability acceptance.

Execution credentials remain bound in AWX. TESSERA holds restricted AWX API authentication in administrator-owned transport only; inventory writes use separate identity. Callback capability is execution-scoped, not a target password. TLS verification mandatory for actual integration; earlier self-signed bypass authorization applied to portal VAPT, not AWX/callback configuration. No playbook/job/configuration changes or live launch performed during this review.

References: docs/awx-integration.md and docs/tessera-182-end-to-end.md sections3â€“5 (historical implementation release); examples/awx; docs/integration-onboarding.md; PROJECT_STATUS.md. Generic/Navis onboarding is not evidence that AWX web services are configured. Launch.json IDs42/7, guide WebserviceID12 and bindings IDs12/14 are placeholders, not accepted live IDs.


## First acceptance must originate in ScriptEngine automation

Owner corrects the acceptance sequence: create/bind an automation script/task and prove the script triggers Ansible, not merely direct AWX connector invocation. Existing automation-test.yml includes inventory writes; begin with the new launch-only examples/awx/automation-launch-test.example.yml and automation-launch-bindings.example.json. Their42/7/12 IDs are explicit placeholders. Configure the real callback-test.yml localhost template, existing inventory and restricted execution Web Service first. No target credentials enter script.

Run the existing trusted backend test task through Maint::TESSERA::AutomationTest --script-file <configured launch YAML> --bindings-file <configured bindings JSON>. This invokes actual ScriptEngine with explicit allowed-call provider and execution context. It returns ExecutionUID, not proof of job completion. Read UID with AWXCallbackTest --execution-uid <UID> --wait-seconds1; inspect dispatch JobID, independently verify final AWX state/stdout/events using AWXTest --job-id <saved ID>, never re-evaluate effectful YAML just to poll. Inventory sync is the next stage after script-driven launch works.

Local AWXAutomationLaunchFixture.t passes11 assertions covering actual YAML parsing/evaluation, one scoped call, actor propagation, durable-reference return and denial without provider/in selection programs. Uses mocked outbound provider; not live AWX proof. No live stored Automated Task object created or generic task publication bridge verified. No current package-backed Automated Task schema/agent binding found in this trace, so do not invent class/field names or grant stored scripts ambient outbound access. If owner intends an agent-created persistent task, inspect its actual exported class and execution entry point and implement authorized binding before claiming that route complete. No OPM rebuilt.


## Template35 confirmed as heartbeat â€” first launch uses polling

Owner screenshot confirms System-AWX Heartbeat / Demo Inventory / ICA Automation / AWX EE(latest) / playbooks/system/awx/awx-heartbeat.yml / verbosity0. Local matching-path playbook is localhost/connection:local, reads EE statistics and publishes tessera_heartbeat; no callback. Live project revision not yet verified. Corrected configured outputs/awx-scriptengine-test/automation.yml to JobLaunch TemplateID35 only, returning JobID with template defaults. Do not use JobLaunchCallback or wait for ExecutionUID from this heartbeat. Callback acceptance uses a separate callback-capable template later. Need actual TESSERA execution WebserviceID; Admin::WebService::List prints names/IDs without credentials. Placeholder binding remains invalid0. No live launch.


## Authentication configuration clarified from official docs and native source

Observed live ansible.awx WebserviceID4 in requester transport GUI. Endpoint field already https://awx.ncs.local and timeout30, TLS hostname/mode Yes, no authentication/header values populated. No save or credential change performed by agent; UI field values are not proof of persisted configuration. Use actualID4 for draft binding only after invoker registration verified. Owner proposes dedicated tessera.integrator identity; token not yet created.

Official AWX24.6.1 authentication guide recommends OAuth2/PAT for programmatic calls, sent as Authorization: Bearer <token>. OTOBO11.1 OAuth dropdown is its managed OIDC-profile/functional-account TokenProvider path, not a field to paste an AWX PAT. For a manually issued AWX PAT, use HTTP::REST Additional request headers/Add header: Authorization=Bearer <token>, Accept=application/json; Authentication dropdown remains empty. Confirmed native REST.pm adds AdditionalHeaders and separately overwrites Authorization when OAuth functional account selected, so do not combine both modes. Native OAuth path also debug-logs fetched token in current source; keep debugging at error and restrict logs/config exports. Manual header token storage is administrator-managed native config, not assumed encrypted/auto-rotated.

References: https://doc.otobo.org/manual/admin/11.1/en/content/administration-area/processes-automation/web-services.html#otobo-as-invoker and https://docs.ansible.com/projects/awx/en/24.6.1/rest_api/authentication.html#oauth-2-token-authentication . Token inherits userRBAC; dedicated account must have approved template execute/result scope. Token creation/revocation/expiry/rotation and verified TESSERA-to-AWX CA trust remain configuration steps; no secrets in YAML.


## End-of-day completion — prepared Base189

Managed AWX bearer preset is implemented in existing Integration onboarding. It reuses mounted-secret authentication/HTTPS transport and8 typed AWX invokers; config contains SecretName only, fixed paths and read-only authentication test. LegacyREST ID4/Navis/Generic preserved; no automatic adoption or privileged access grants. Static token rotation rereads file; no launch retry. No core OTOBO auth-dropdown patch or new database/DynamicFields. Detailed setup and limits: docs/awx-managed-onboarding.md.

Base189 includes445 byte-verified payloads:6 semantic integration source changes,103 Git-canonical line-ending normalizations and4 additions (Elasticsearch override, guide, heartbeat fixtures), no188 removals and unchanged install/upgrade/reinstall/schema hooks.10 AWX/onboarding suites pass360 assertions; Elasticsearch syntax and12 actual-filter checks pass. Package unsigned/prepared, not installed. Token creation/mount/CA/new managed service/real ScriptEngine launch and native install acceptance remain next-session work. No live credentials or jobs created today.
