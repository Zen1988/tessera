# Assessment Framework selection — 0.0.98

The custom assessment workspace includes the exported Ticket GovernanceObject field `ZRM-Framework`. Its required marker and pre-submit validation follow the administrator's `ZRM-RiskAssessment` Set Include configuration.

`TESSERA::RiskAssessment::DefaultFramework` is the exact Framework object name. Its initial value is `Asset Risk Management`. The object must already exist and resolve uniquely; the package does not create or overwrite administrator Framework objects. Installation creates the exported field only if missing and resolves class/status names to local IDs. Existing field and Set definitions are preserved.

Initial rows preserve saved Framework choices. An explicit mapped ticket Framework takes priority; otherwise the selected RiskStatement's `ZRM-RMF` supplies the Framework, followed by the organization default. Changing or clearing the Risk Statement refreshes Framework from the statement/default. The assessor can select another Framework afterward. Existing saved overrides survive reopening.

For Framework `ZRM-MasterTicket`, add this under the existing `RETURN: FIELD ASSIGNMENTS:` mapping:

```yaml
    ZRM-Framework: '@FRAMEWORK.GovernanceObjectID'
```

This is optional for compatibility with existing programs. A policy owner may use another supported ScriptEngine expression returning exactly one Framework ID. The field is saved before `ZTicket-StateBook` starts orchestration and inherited by assessment children. Existing orchestrated masters are not backfilled; use a fresh test cycle.

For a specific assessment result override in `ZRM-RiskScoringEngine`, add this under the existing `ASSESSMENT RESULT:`:

```yaml
  FIELD ASSIGNMENTS:
    ZRM-Framework: '@FRAMEWORK.GovernanceObjectID'
```

This new optional result mapping supports `ZRM-Framework` only. The expression context contains `FRAMEWORK`, `RISK`, and `STATEMENT`. Unresolved, ambiguous and wrong-class values fail closed. No live YAML is automatically rewritten.

Selection, persistence and mapping were added in98. Package101 uses the selected row Framework's current RiskMatrix and severity colours for form badges and new article summaries, sharing the100 Register resolver. Existing origin-scoring programs still use the originating Risk Framework; assessor score products remain likelihood × impact. Changing the selection does not switch that scoring program. Immutable Framework version/matrix evidence remains pending.

Package102 reads exported Text fields `ZRM-LikelihoodScale` and `ZRM-ImpactScale` from the selected Framework as positive integer maxima. Both scales start at1. Valid catalog entries must have integer numeric names; their IDs remain storage keys. Both inherent and residual dropdowns limit choices independently, and backend submission validates the same limits. Framework changes clear invalid selections and require reselection. Missing or invalid scale values block submission. Field defaults do not imply missing existing Framework values are automatically populated. Installation creates missing fields while preserving existing administrator definitions and Framework values.

Test a fresh assessment: default on an empty row, statement with/without Framework, clear/change statement, manual override then reopen, YAML override, and mandatory empty selection. Refresh with Ctrl+Shift+R after installation.
