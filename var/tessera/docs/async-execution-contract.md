# Asynchronous automation execution contract

An accepted automation request is **pending in durable state**, not successful and not running inside a waiting TESSERA worker. The execution engine saves an immutable request ID, target, current workflow position, and continuation before dispatch. A call to any external or long-running executor returns promptly with a stable execution ID. The HTTP request, daemon slot, database connection, and process lock are released immediately after dispatch. Pending consumes only a small persisted record; there is no polling loop or sleeping worker for each job.

The callback must authenticate the executor and carry the execution ID, response, and an exit code. The callback handler validates and stores the terminal result in a short transaction, then enqueues the saved continuation; it does not run the remaining workflow inside the callback HTTP request. Only a populated exit code resumes the workflow. Exit code `0` takes the success branch; every other populated exit code takes the failure branch. An absent exit code remains pending even if a transport request returned HTTP 200 or the response says “accepted.” A failed launch takes the dispatch-error branch. The resumed worker records the response and exit code as execution evidence before performing the next step. Completion of an external call alone cannot imply that an entire multi-step workflow succeeded.

Callbacks must be idempotent and correlated to the exact immutable execution request and target. Repeated identical terminal callbacks do not enqueue duplicate continuations, create duplicate articles, or repeat downstream effects. A callback with a conflicting result, unknown ID, altered target, or invalid authentication is rejected and audited. Continuation processing must claim the saved position atomically, check authorization and governance snapshot, and either advance to the next step or dispatch another async job and release its worker. A bounded worker pool, per-target concurrency lock during active transitions, queue limit, timeout policy, and reconciliation for lost callbacks are required. Timeout takes an explicit failure or unknown branch; it is never inferred success. Pending jobs must not retain a connection, worker slot, or PID lock.

The ControlObjective Run now action executes its existing local policy through OTOBO's daemon. External steps use the durable service below; they cannot be selected from arbitrary YAML until the policy capability and publication gates are implemented.

## Package 0.0.158 implementation

`Kernel::System::TESSERA::AsyncExecution` now provides the durable handoff. A trusted backend caller invokes `Start` with a registered continuation key, target, actor, a configured OTOBO GenericInterface requester web service/invoker, payload, and timeout. It saves the continuation in `ztsm_async_execution` and queues a native `GenericInterface` task. The requester transport timeout must be 1–60 seconds. The remote service must acknowledge promptly and then call back; OTOBO does not keep its HTTP connection open for remote job completion. The outbound request includes `ExecutionUID` and a random per-execution `CallbackToken`; the transport and GenericInterface debug-log access must be restricted accordingly.

The package registers `TESSERA::ExecutionCallback` as an OTOBO GenericInterface provider operation and idempotently creates the `TESSERAAsyncExecutionCallback` provider web service with a POST `/ExecutionCallback` route. The remote executor sends `Authorization: Bearer <CallbackToken>` and JSON `ExecutionUID`, `ExitCode`, `Response`. The operation rejects missing exit codes and invalid tokens. It stores a terminal result once and queues a short continuation task; duplicate identical callbacks return as duplicates, while conflicting callbacks fail. The five-minute reconciliation cron handles callback timeouts as unknown and retries queuing saved ready continuations. A timed-out job has no exit code and never counts as success.

Handlers are chosen from the backend-owned `TESSERA::AsyncExecution::Handlers` SysConfig registry, not YAML or remote callback data. `ControlObjective` is registered to record the external result and, on exit code zero, queue normal evaluation for all instances after rechecking the original agent's permission. A nonzero code or timeout writes failure evidence and does not evaluate those controls. Other workflows add their own explicitly registered continuation handler; handlers must make downstream effects idempotent because a crash after an effect but before completion can require operator reconciliation.

The existing ControlObjective Run now UI still queues local policy evaluation directly; it does not invent an external target. To use an external executor, configure an OTOBO requester web service and invoke `AsyncExecution->Start` from the authorized workflow step with the registered handler. Package158 supplies the service, storage, provider callback route and default ControlObjective continuation. No outbound web service destination is enabled by package installation alone.

For a trusted ControlObjective workflow step, the backend call is:

```perl
my $Started = $Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution')->Start(
    HandlerKey  => 'ControlObjective',
    TargetType  => 'ControlObjective',
    TargetID    => $ObjectiveID,
    ActorID     => $AgentID,
    Continuation => { Purpose => 'EvaluateInstances' },
    WebserviceID => $ConfiguredRequesterWebserviceID,
    Invoker      => $ConfiguredInvoker,
    Payload      => { ObjectiveID => $ObjectiveID },
    TimeoutSeconds => 3600,
);
```

The remote service receives `ExecutionUID` and `CallbackToken` in the outbound payload. It posts a completion to the OTOBO GenericInterface provider route with the token as the Bearer credential and a body such as `{"ExecutionUID":"...","ExitCode":0,"Response":{"job":"finished"}}`. `Start` requires a real, valid OTOBO requester web service whose HTTP transport timeout is at most 60 seconds. The backend caller must authorize the target before dispatch; the registered continuation rechecks permission before changing governance or Control state.
