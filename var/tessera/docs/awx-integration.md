# AWX integration contract — TESSERA-Base 0.0.182

For182 callback, durable history, inventory sync, authorized CALL WEB SERVICE and container upgrade acceptance, see docs/tessera-182-end-to-end.md. The polling-only instructions below remain available.

AWX/Ansible is the common execution entry point. TESSERA prepares non-secret business data, selects an approved AWX template and reads execution results. Ansible playbooks own individual product integrations. Books still define governance; the calling automation runtime owns authorization, execution tracking and evidence decisions.

## Credential ownership

Machine, SSH, cloud, vault, become and other execution credentials remain in AWX and are bound to administrator-controlled templates. The invoker has no credential input. It rejects credential overrides and common nested secret keys, including Ansible password/key overrides. Do not put secrets under alternative variable names: key rejection is not a secret classifier.

An AWX API identity is still required to authenticate TESSERA to AWX. Keep it exclusively in the administrator-managed OTOBO web-service transport authentication/header configuration, not in script inputs, `extra_vars`, examples or articles. Restrict it in AWX to approved templates, their necessary inventory use and result visibility. Do not give it administrator, credential-management, template-editing, inventory-management or ad-hoc execution permissions. Scope the template's inventory, project, playbook, credential bindings and allowed launch prompts in AWX. A powerful unrestricted playbook can defeat this boundary even without TESSERA holding its credentials. Do not expose arbitrary playbook/shell execution or unrestricted sensitive `ansible_*` overrides through surveys.

No AWX instance, service account, credential, template or web-service record is created automatically. Installation adds modules and registration defaults. Administrator-owned web-service configuration survives upgrade/reinstall. The example is imported deliberately once, not on every package installation.

## Configure and test

1. Install/upgrade TESSERA-Base 0.0.182 normally and deploy its SysConfig definitions. Fresh installation and same-version reinstall use the same file payloads; 182 adds two nullable execution-history columns through idempotent package hooks; no new Dynamic Fields are introduced. The previous 180 payloads are retained, except the explicitly extended ScriptEngine.
2. In AWX, create a test project containing `examples/awx/integration-test.yml`, a localhost inventory and a job template with no target credential. Enable the required prompts for inventory, variables and verbosity (or survey variables as appropriate). Set the API identity's template execute/result access. Use a dedicated harmless template for acceptance.
3. Import `var/webservices/examples/TESSERAAWX.yml` through OTOBO Web Services, give it a name such as `TESSERAAWX`, and replace the invalid example hostname with the actual HTTPS origin. Configure API authentication and trusted CA in the transport. Verification must stay enabled; request timeout is 1–60 seconds. Keep mappings empty and error handling free of retry/reschedule rules. Use debug level `error`, not full payload logging.
4. Edit `examples/awx/launch.json` to use the actual template and inventory IDs. This is non-secret data. Inventory is an existing AWX inventory ID, not an inventory file or list of hosts. Dynamic inventory creation/synchronization is a separate AWX-owned workflow; the connector does not grant inventory write privileges.
5. As the OTOBO service OS user, run from the installed application directory:

```sh
bin/otobo.Console.pl Maint::TESSERA::AWXTest \
  --webservice-id 12 --data-file /private/test/launch.json \
  --wait-seconds 300 --output-directory /private/test/awx-run-001
```

The output directory must be new. The command launches exactly once, prints the job ID, polls completion and fetches every event/stdout page up to an explicit 1000-page limit. JSON captures retain complete responses, including verbose event data, artifacts and stdout. Failed executions also collect output and exit nonzero. Captures use mode 0700/0600 on Unix; apply equivalent Windows ACLs if testing there. The command prints status, not raw output. If no output directory is supplied it exercises reads but does not retain their contents.

Resume reads without launching again:

```sh
bin/otobo.Console.pl Maint::TESSERA::AWXTest \
  --webservice-id 12 --job-id 1287 --wait-seconds 300 \
  --output-directory /private/test/awx-job-1287
```

Use `--workflow` for workflow launch/status/node capture. Workflow nodes identify child `job` objects; read each ordinary child job with JobGet/JobStdout/JobEvents, or the resume command above. Nested workflow jobs use WorkflowGet/WorkflowNodes recursively in the trusted caller. A workflow has no single playbook stdout; node capture alone does not collect every descendant's stdout.

## Invoker inputs and outputs

| Invoker type/name | Method and controller | Input |
| --- | --- | --- |
| AWX::JobLaunch / JobLaunch | POST `/api/v2/job_templates/:TemplateID/launch/` | TemplateID, optional launch fields |
| AWX::WorkflowLaunch / WorkflowLaunch | POST `/api/v2/workflow_job_templates/:TemplateID/launch/` | TemplateID, optional launch fields supported by that workflow |
| AWX::JobGet / JobGet | GET `/api/v2/jobs/:JobID/` | JobID |
| AWX::WorkflowGet / WorkflowGet | GET `/api/v2/workflow_jobs/:JobID/` | JobID |
| AWX::JobStdout / JobStdout | GET `/api/v2/jobs/:JobID/stdout/` | JobID, optional start_line/end_line |
| AWX::JobEvents / JobEvents | GET `/api/v2/jobs/:JobID/job_events/` | JobID, optional page/page_size |
| AWX::WorkflowNodes / WorkflowNodes | GET `/api/v2/workflow_jobs/:JobID/workflow_nodes/` | JobID, optional page/page_size |

Launch options: `inventory`, structured JSON `extra_vars`, `limit`, `job_tags`, `skip_tags`, `scm_branch`, `job_type` (`run`/`check`), `verbosity` (0–5), `forks`, `timeout`, `diff_mode`, `job_slice_count`. AWX and the template decide which prompts are supported. The adapter validates types and rejects unknown top-level inputs. Optional execution settings are not all supported by workflow templates. Template-level API authorization remains AWX's responsibility.

Status/launch outputs contain `JobID`, `Status`, `Terminal`, `ExecutionSuccess`, `Outcome`, `InputAccepted` and **`Response` containing the entire AWX JSON response**, including fields introduced by AWX that the adapter does not normalize. Collections/stdout return `JobID` and complete `Response`. Nothing is automatically written to a ticket or governance snapshot.

`Success` means a valid connector exchange. It does not mean the Ansible execution succeeded. Check `InputAccepted`, `Terminal`, `ExecutionSuccess` and `Outcome`. AWX can create a job while ignoring launch inputs; `INPUT_REJECTED` preserves the existing job ID and complete response, sets InputAccepted/ExecutionSuccess to zero, and requires reconciliation, never automatic relaunch.

Stdout requests force JSON format and return `Response.content` plus the AWX `Response.range`. Continue from `range.end` until `end >= absolute_end`. Event/node reads preserve every result field and `count`/`next`/`previous`; increment numeric pages against the configured AWX origin instead of following returned URLs. Default page_size=100, max=200; stdout defaults to 200 lines and max=1000 per request. Each response/input has bounded depth/nodes/size (1 MiB character budget). Oversized pages fail explicitly; reduce page/line sizes rather than silently truncating. A single oversized event or line needs a separately designed export path. There is no promise of unlimited output in a single response. For stable complete reads, collect after terminal status; running output is still growing. AWX retention and stdout display limits also apply.

Do not render stdout as trusted HTML, execute strings found in events, or feed output back as executable script source. Verbose output/artifacts may contain sensitive application data even though TESSERA supplies no target credentials. AWX playbooks should use `no_log` where needed. Native GenericInterface debug/error storage can retain payloads/remote errors before the invoker sees them: enforce access/retention, keep debug logging disabled, and never send secrets as business inputs. This adapter does not claim to redact the framework's transport logs.

## Calling from the automation backend

Trusted orchestration calls the existing Requester; it does not call PrepareRequest alone (that would not send anything):

```perl
my $Launch = $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
    WebserviceID => $ConfiguredWebserviceID,
    Invoker      => 'JobLaunch',
    Data         => {
        TemplateID => $ApprovedTemplateID,
        inventory  => $ApprovedInventoryID,
        verbosity  => 3,
        extra_vars => {tessera_request => $NonSecretData},
    },
);
```

Use the same call with JobGet and `{JobID => $SavedJobID}` for completion, then read events/stdout as needed. A timeout after POST is ambiguous: inspect AWX and reconcile before retrying. No launch deduplication/exactly-once guarantee is provided by AWX or this adapter. The test command never relaunches automatically. Do not attach the existing AsyncExecution retry/callback path to these invokers unchanged: it appends ExecutionUID/CallbackToken, which are deliberately rejected. A future durable polling continuation must retain job identity, reconcile uncertain dispatch, enforce actor/target/template authorization and avoid replay.

## Reading results with the current English-style ScriptEngine

The trusted backend can supply one validated page or job result as `Context => {EXTERNAL => $Result->{Data}}` to ScriptEvaluate. This adds a read-only context root to the existing path resolver, not a new network or privileged script operation. Business results published with Ansible `set_stats` can be read using existing syntax:

```yaml
VERSION: 1
RETURN:
  VALUE: EXTERNAL.Response.artifacts.tessera_result.outcome
```

Other examples: `EXTERNAL.Status`, `EXTERNAL.Response.content`, or `EXTERNAL.Response.results[event=runner_on_failed].event_data.res.msg` when the filter selects exactly one event. Existing resolver rules fail on missing/ambiguous/structured scalar paths. For multiple events, the backend supplies bounded pages/selected records; no new loop or free-form natural-language interpreter is introduced. Do not substitute external data for the TICKET/THIS governance context. Prefer structured artifacts/event JSON for decisions; stdout is useful evidence and diagnosis, and verbosity should not change business outcomes.

182 adds CALL WEB SERVICE only with an explicitly injected authorized provider and exact configured service/invoker bindings. Default stored/selection scripts remain unable to perform network effects; existing publication/actor/target authorization still applies. The trusted test console, callback/history and inventory sequence are documented in docs/tessera-182-end-to-end.md.

## Acceptance evidence

Local suites cover payloads, credential rejection, unsafe transport configuration, all job statuses, identity mismatch, ignored inputs, full response preservation, output pagination, one-launch command behavior and external ScriptEngine reads. They simulate transport responses; they do not prove a live deployment.

Live acceptance still needs the actual AWX version/HTTPS origin, restricted API identity, test template and inventory. Verify successful/failed jobs, verbosity 0 and 3–5, nested artifacts, stdout/events across pages, ignored prompts, access-denied template/inventory, expired API authentication, TLS name/CA rejection, interrupted POST reconciliation and polling resume. Verify the API identity cannot read target credential secrets or modify templates/inventories. Do not claim live acceptance until these run against the installed package.

Protocol references: [AWX API guide](https://docs.ansible.com/projects/awx/en/latest/rest_api/api_ref.html), [AWX job launch parameters](https://docs.ansible.com/projects/ansible/13/collections/awx/awx/job_launch_module.html), [AWX stdout implementation](https://github.com/ansible/awx/blob/devel/awx/api/views/__init__.py). Confirm compatibility with the actual deployed AWX version.
