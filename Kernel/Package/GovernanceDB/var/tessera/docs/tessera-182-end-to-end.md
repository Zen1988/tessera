# 182 acceptance: upgrade, inventory, AWX, callback and history

182 prepares a complete test route using TESSERA's existing database. No separate document database is introduced. No live cluster/database/AWX mutation was performed from this workspace.

## 1. Install on the original Linux host and build the new image

Install TESSERA-Base-0.0.182.opm normally on the original source host. Use a **fresh copy** of the updated TESSERA-Ubuntu26.04-Container-Toolkit.zip; older prepared app/dependencies directories have no upgrade artifact.

```sh
bash scripts/prepare.sh /opt/otobo
bash scripts/build.sh
```

Preparation reads the source installed version and exports only its installed OPM artifact, verifies its identity and every declared package payload against the source files, and captures SHA256/allowed upgrade origins. It excludes source Config.pm, runtime data and database dumps. Normal package defaults inside the OPM are code-controlled installation content, not a dump of source business records. Source trees containing symlinks are rejected by preparation/build/staging. Readable immutable release.json/package.opm are embedded in the image. Use the actual image tag printed in artifacts/latest-build.json (automatic revisions still apply) and import it onto every eligible node or use the intended registry.

## 2. Upgrade the existing Kubernetes database in place

Run the controlled helper once even if the target was already natively installed at182: it verifies the installed artifact and declared history columns, rebuilds configuration and establishes the successful release receipt without reinstalling the package. A matching registry version without that receipt cannot start new runtime Pods. Startup also verifies the two declared history columns; registry metadata alone is not accepted as schema-completion evidence.

The administration-host helper also claims a namespace ConfigMap named tessera-release-maintenance using atomic create/resourceVersion replacement. It holds LOCKED through image activation and records READY only after both rollouts succeed, preventing two helpers from overlapping maintenance/activation. There is no expiry or automatic takeover; failure retains the claim. The existing administration identity needs ConfigMap get/create/update permissions; no Pod service-account/RBAC grant is added. After reviewed manual recovery, restore images/replicas and mark this ConfigMap READY with its current resourceVersion only after confirming no old helper/Job is active. Do not delete a live claim. Successful retained upgrade Job Pods are evidence, not active writers, and do not block the next release; live/failed/terminating Pods still block quiescence. This namespace coordinator supplements the database-global claim; deployments outside the helper's namespace remain separately controlled writers.

Use the new toolkit's helper from the administration host, with actual Deployment/container/image names:

```sh
python3 scripts/upgrade-deploy.py \
  --namespace tessera --web tessera-web --daemon tessera-daemon \
  --container tessera --image tessera:0.0.182-ubuntu26.04 \
  --state-directory /private/tessera-release-182
```

The private state directory must be new. The helper saves original Deployments and exact Job, server-dry-runs the Job, stops the named web/daemon Deployments, waits for every old matching Pod to disappear, runs one Job and only after success updates both images/restores their saved replica counts and waits for rollout. This has an intentional maintenance interval. Quiesce any other target writers/GitOps controllers separately; external clients are not discoverable by this helper. HPA ownership, sidecars, unusual selectors, an existing app-root mount or absent direct target Config.pm/shared generated-config mounts are refused rather than guessed. Preserve the target database, external secrets, shared generated configuration and durable data volumes. No new service account/RBAC grant, database administrator credential or database is introduced.

The Job init container copies image code to a writable emptyDir. Its main container mounts that workspace at /opt/otobo plus the existing target mounts, preserving native Home/path semantics and non-root security. Native package upgrade writes occur in that disposable app tree and against the existing target database; the runtime image remains immutable. The Job is not a web server; copied web labels may match Services only during the intentional maintenance interval.

Supported target test paths:180→182,181→182 and182→182. Same-version deployment does not reinstall the package or rerun schema hooks; the controlled Job may rebuild this image's generated configuration. Native fresh package installation remains supported separately, but missing target package metadata never triggers an assumed fresh install. Future releases must explicitly declare/test supported origins in var/governancedb/container_release.json.

ReleaseUpgrade uses the existing system_data primary key TESSERA::ContainerRelease as a durable database compare-and-swap claim across database endpoints. Phases are UPGRADING→CONFIGURING→READY. OTOBO advances its package registry before all hooks finish, so an interrupted claim blocks new runtime even if the registry already says182. Native package ordering/version filtering/file/config/hooks remain, with ReleasePackage raising SQL/file/config/code helper failures instead of accepting logged failure as success. The controlled configure helper then rebuilds target SysConfig/ACL/process data and publishes the definition fingerprint. Full target package artifact hash and version checks remain enabled at web/daemon startup and readiness. Benchmark their cost with the real database/package size; no unverified fast path is used.

182 adds only nullable request_data and dispatch_data columns to the existing ztsm_async_execution ledger, using explicit idempotent install/upgrade/reinstall hooks. Existing rows are preserved. Native package-declared defaults/metadata still apply through ordinary hooks. There is no arbitrary schema-diff ALTER generation, source-record import, destructive downgrade or transactional-DDL rollback promise.

Failure leaves Deployments stopped, durable phase and private snapshots for inspection. The Job has restartPolicy Never/backoffLimit0 and a1800-second deadline. Old Pods stuck Terminating cause a stop before database upgrade, not forced deletion. Inspect kubectl describe/logs for the saved Job; native logs/state snapshots can contain operational/custom configuration details and should stay private. An UPGRADING phase requires review of partial native effects and supported recovery, not registry edits/claim deletion/blind replay. A CONFIGURING-only failure can be resumed after verifying the old Job is no longer executing: create a new Job from the saved manifest with a new name and main args ['upgrade','--resume-config']. It verifies target identity and skips native migration. Preserve original snapshots for image/replica activation after recovery. Never assume image rollback rolls back DDL.

## 3. Configure the AWX connections and callback

Import/update the execution Web Service from var/webservices/examples/TESSERAAWX.yml. Its HTTP::REST Host is https://awx.ncs.local; configure the trusted CA and restricted API authentication in the **target** environment. Keep mappings empty and error handlers free of automatic launch retries. Existing Web Service records are administrator-owned and never overwritten on installation.182 adds AWX::JobLaunchCallback to the original launch/status/stdout/event invokers.

For inventory sync, import TESSERAAWXInventory.yml as a separate Web Service with a separate identity restricted to read/create/update hosts in the designated existing inventory. InventoryHosts, InventoryHostCreate and InventoryHostUpdate are registered. This is the explicitly requested inventory-write capability; it does not broaden the execution identity. Neither identity needs target credential-secret access or template administration. No inventory creation/deletion endpoint is provided. Target SSH/cloud/vault credentials stay bound to approved AWX templates, never TESSERA inputs or host variables.

Set TESSERA::AWX::CallbackURL in target SysConfig to the actual externally reachable HTTPS endpoint. Example only; verify the site's existing route:

```text
https://tessera.ncs.local/otobo/nph-genericinterface.pl/Webservice/TESSERAAsyncExecutionCallback/ExecutionCallback
```

The empty default disables callback launch before persistence/dispatch. The existing create-if-missing provider exposes POST TESSERA::ExecutionCallback. AWX EEs must trust its certificate CA; no TLS-verification-disable fallback is provided. Confirm the default async-handler registry includes AWXTest→AWXExecution::RecordTestCompletion; if administrators override that registry, add the test handler deliberately without replacing their other entries. The ordinary TESSERA daemon must run for dispatch/continuation tasks. No customer/agent portal receives new network privileges automatically.

## 4. Test Ansible completion callback and durable reference

Create an AWX template using examples/awx/callback-test.yml, a localhost inventory and no target credential. It executes locally inside the EE. Enable inventory, variables and verbosity prompts. AWX must accept the reserved tessera_callback extra variable. Edit the placeholder template/inventory IDs in examples/awx/launch.json.

As the trusted TESSERA OS console user:

```sh
bin/otobo.Console.pl Maint::TESSERA::AWXCallbackTest \
  --webservice-id 12 --data-file /private/launch.json \
  --wait-seconds 300 --timeout-seconds 3600
```

The printed ExecutionUID is saved before dispatch. The dedicated one-attempt worker records DISPATCHING before the AWX POST, saves its response/JobID, then WAITING. Repeated/crashed workers do not relaunch accepted or uncertain requests. HTTP ambiguity is DISPATCH_UNKNOWN; inspect AWX before any new request. A valid scoped callback can resolve uncertainty. Exactly-once external delivery is not claimed.

The playbook sends Authorization Bearer with a random execution-scoped capability, ExecutionUID, ExitCode and structured Response. That capability is not a target credential and can only complete the saved execution. Server-side token verifier/deadline/continuation bind the result; the callback body cannot select another handler/actor/target. Wrong/expired tokens, conflicting repeats and late callbacks fail; identical repeats are idempotent. Conditional state transitions prevent duplicate scheduling/continuation claims. Deadline checks run during callback acceptance, not only during reconciliation.

An accepted result proceeds READY/QUEUED/RUNNING/DONE through the registered continuation. DONE means callback/continuation processing completed; inspect ExitCode for the reported business result. It is not independent verification of AWX's final job status—a job could fail after sending a callback. Read JobGet using the saved dispatch JobID when verifying final AWX state. A job that fails before callback follows the saved deadline/timeout path, not automatic relaunch.

Read the record later, including after Pod replacement:

```sh
bin/otobo.Console.pl Maint::TESSERA::AWXCallbackTest \
  --execution-uid PRINTED_UID --wait-seconds 1 \
  --output-file /private/execution-result.json
```

Use a new output file and the same actor ID if the test used --actor-id. The trusted console defaults to system actor1. Read-back enforces the saved actor and omits TokenHash/Continuation. It retains request snapshot (service/invoker/payload), dispatch response and callback result. No automatic purge/separate document DB is added. Results are bounded to1MiB; full stdout/events remain paginated reads and can be explicitly archived later. Raw output is not automatically published as a ticket article.

History stores only the token verifier; native scheduler tasks temporarily carry the plaintext capability and AWX receives it in extra_vars. Restrict scheduler/AWX access. Known token text is redacted before dispatch/callback output is persisted, including JSON-string extra_vars. Native GenericInterface transport/error/debug logs are outside that redaction guarantee: restrict access/retention, avoid debug logging and never put target secrets in business data. Callback tasks use no_log, verified HTTPS and no redirects.

## 5. Test CMDB snapshot → inventory → launch through automation

The user chose mapping later. No new mapping system or guessed CI fields is introduced. The existing automation/backend supplies its authorized snapshot as ConfigItemID, Address and optional non-secret Variables. These are connector payload keys, not new Dynamic Fields. Production extraction must use the latest exported model and enforce actor/CI scope before invoking the connector.

AWXInventory::Sync reads bounded inventory pages before mutation, creates stable tessera-ci-&lt;ConfigItemID&gt; names and JSON variables with ansible_host/ownership markers, updates only matching owned hosts, reconciles previously owned variable keys and preserves unrelated manual variables/hosts. It rejects ambiguous ownership and credential/connection overrides. It never deletes/prunes inventory entries. Repeat snapshots cause no duplicate or needless update. Stale hosts are retained; **use the returned Limit** to restrict execution to synchronized snapshot targets. Partial/uncertain sync returns LaunchAllowed0 and stops the automation before launch. This is not an AWX→CMDB import or a full inventory-pruning policy.

CALL WEB SERVICE uses fixed service/invoker names plus WITH payload and AS result alias. The trusted AutomationWebService provider binds those names to configured Webservice IDs. InventorySync composes the three configured inventory invokers; it is not an arbitrary-URL endpoint. Ordinary calls use the existing Requester; callback launch uses saved AsyncExecution with backend-supplied handler/actor/target.

No ambient outbound privilege is enabled in stored YAML. ScriptEvaluate requires an explicitly injected backend provider and exact AllowedCalls; otherwise CALL WEB SERVICE fails before effects. Stored selection programs cannot make these calls even with a provider. No arbitrary URL/authentication, Perl evaluation, execution of response text or production publication bypass is added. Existing publication/actor/target authorization remains mandatory before a production backend may inject that provider. The trusted OS console command below is the test surface.

examples/awx/automation-test.yml demonstrates sync→launch→return ExecutionUID, using EXTERNAL.INVENTORY.InventoryID/Limit. Its CI/template/inventory IDs are placeholders. For this combined fixture, configure the AWX template to use callback-inventory-test.yml: it selects only the explicit tessera-ci-1 fixture alias and uses connection:local, so no remote machine is contacted. The separate localhost-only callback fixture is unchanged. Replace these fixtures with reviewed production playbooks only after the mapping and target scope are configured.

Edit automation-bindings.json to the actual two Webservice IDs (no URLs/tokens/credentials), then run:

```sh
bin/otobo.Console.pl Maint::TESSERA::AutomationTest \
  --script-file /private/automation-test.yml \
  --bindings-file /private/automation-bindings.json
```

It prints the scalar ExecutionUID chosen by RETURN. Read it using AWXCallbackTest; **do not rerun the effectful script to poll**, because that requests a new execution. Complete job JSON, verbose stdout and events are still available through the original AWX invokers/test command in docs/awx-integration.md. Inventory sync writes are composed external operations, not an atomic distributed transaction; no automatic rollback is claimed.

## Acceptance limits

Local fixtures cover upgrade/claim/hash/failure decisions, workspace/Job construction, credential/TLS/payload restrictions, inventory ownership/repeat sync, authorized script chaining, callback/provider authentication/deadline/replay, dispatch intent/no replay and redacted durable history. Actual Linux source export/image build, isolated native target MariaDB upgrade/reinstall, AWX host writes, EE trust, callback delivery, gateway/job execution and rollout are still to run in the user's test environment.
