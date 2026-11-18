# Runtime and execution evidence

ServiceLibrarian resolves applicability. StateBookReader controls lifecycle; BlueBookReader/Director coordinate execution levels and chapters. Parent governance evidence and child execution evidence stay separate.

Requester Hold stores each ticket's previous state name in ZTicket-HoldState, moves the parent and active children to On Hold, and writes evidence. Resume restores those states and clears the field. Neither action invokes Book readers/directors, transition validation/actions, chapter evaluation or orchestration. ZState-CurrentStage, ZState-CurrentState and ZBlue-CurrentChapter remain unchanged.

Native Change uses protected ChangeType (Normal/Standard/Emergency) and ChangeClassification (Normal/Not-Assessed/Major). Managers classify after assessment. IPC may make explicit reasoned overrides but cannot publish an unapproved change. Historical Change::Major is retained invalid.

Remote effects need durable identity, saved intent, bounded requests, actor/target checks and idempotent continuations. A timeout is uncertain, not proof of rollback. Do not replay a trace/launch/ingestion POST automatically. Discovery ingestion completion, graph readiness, connectivity verdict and execution approval are separate claims.

See [Change decisions](../change-classification.md), [async execution](../async-execution-contract.md), and [ScriptEngine authoring](../scriptengine/README.md).

