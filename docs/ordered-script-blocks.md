# Ordered script storage — TESSERA-Base 0.0.148

The 2026-10-12 exports define script Dynamic Field Sets. The two-digit index contract is 1–99, unique and contiguous from 1. Physical row order does not control execution. Each source member holds at most 3800 characters. The runtime sorts numerically, concatenates exactly, and then parses one complete YAML document. No separator is inserted: preserve newlines/indentation in authored fragments. Multiline scalars and anchors may cross blocks. Legacy standalone source values are ignored.

| Set | Index member | Source member |
|---|---|---|
| AdvancedCondition | ZTAM-ConditionIndex | ZTAM-AdvancedCondition |
| FieldAsssignment | ZTemplate-ScriptIndex | ZRM-FieldAssignment |
| MasterTicket | ZTemplate-ScriptIndex | ZRM-MasterTicket |
| PolicyEvaluation | ZTemplate-ScriptIndex | ZRM-PolicyEvaluation |
| PolicyFilter | ZTemplate-ScriptIndex | ZRM-PolicyFilter |
| RiskAggregationEngine | ZTemplate-ScriptIndex | ZRM-RiskAggregationEngine |
| RiskScoringEngine | ZTemplate-ScriptIndex | ZRM-RiskScoringEngine |
| ScriptEngine | ZTemplate-ScriptIndex | ZTSM-ScriptEngine |
| ZTemplate-AutomationScript | ZTemplate-ScriptIndex | ZTemplate-ScriptBlock |

FieldAsssignment is the exact exported spelling. The shared Set driver checks aggregate values before native saves/validation and reports form errors. Ordinary Sets retain their behavior. Empty optional widgets are allowed; partial rows, duplicate indices, gaps, zero, fractions, padded indices and >99 are rejected. Shared ScriptEngine source cap is 376200 characters, expanded tree cap 1048576 characters; depth32 and 10000 nodes remain. Oversized trees still fail closed.

Existing ControlRuntime, ControlDiscovery, PolicyEvaluation, GovernanceRoleResolver, RiskMasterTicket, risk scoring and GenericAgent policy evaluation read the authoritative Sets. OSCAL re-import carries Set values forward. The advisory customer editor accepts one combined source and splits it for storage; advisory list export emits native Set JSON. RiskAggregationEngine and AutomationScript storage support does not introduce a new execution feature.

Template hydration resolves the target ticket Type and exact terminal section name in the merged Template definition (for example General Fields::Assessment). Only a selected section containing ZTemplate-RiskAssessment hydrates the existing ZRM-RiskAssessment ticket Set. Duplicate matching sections are rejected; unmatched types do not hydrate Assessment. Description articles remain supported.

## Installation and migration

Missing exported members/wrappers are created child-first, idempotently. Existing field configurations remain administrator-owned except the exact shipped index regex ^[0-9]$, which upgrades to ^[1-9][0-9]?$. Custom regexes remain intact. Existing object values and class/role definitions are preserved. Fresh class/role defaults use the latest exported ControlObjective, Framework, Template and SecurityAdvisory definitions. Existing GovernanceRoles remain create-if-missing; missing bootstrap roles write ScriptEngine Set values.

Three output workbooks under outputs/ordered-script-migration-2026-10-12 preserve every unrelated source cell and workbook structure. They move 7 ControlObjective, 9 Framework and 1 SecurityAdvisory sources into JSON Set rows, clear old source columns, and normalize Excel CR escapes/CRLF to LF only in scripts. Original Download files are untouched. Reopened outputs were checked for exact normalized source reassembly. Current scripts each fit one block; larger cross-block programs are verified in runtime tests. Excel's 32767-character single-cell limit still applies to native JSON workbook transport, independently of database block capacity. Large future scripts should use the native Set editor/document import rather than one Excel cell.

Package and workbooks are prepared locally, not installed/imported. Exported GovernanceRole layout still references the old source member, and Template Pages still references General Fields::Template while its role now defines Assessment. Administrator-owned deployed definitions require verification/correction through the native definition editor; package installation does not overwrite them. Reserved-role assignment gates, protected-object review, operation-bound MFA and email editor remain separate pending work.

SecurityAdvisory import correction: use TESSERA-SecurityAdvisory-Ordered-Scripts-v2.xlsx. Native ConfigItem document import rejects the retired standalone ZTAM-AdvancedCondition header even with empty values. Omit that column entirely; retain the member name only inside AdvancedCondition JSON. The original migrated advisory workbook is superseded.

## GovernanceObject recovery — 0.0.149

All old standalone source headers must be omitted from migration workbooks, not retained as empty cells. Native Set member values share storage with standalone fields; forwarding both creates competing writes. Use ControlObjective/Framework Ordered-Scripts-v2 and SecurityAdvisory Ordered-Scripts-v2. First verify TESSERA-EOS-Assets-Recovery.xlsx on the existing numbered object, then reopen it and inspect both Sets.149 normalizes legacy empty members away before writes, rejects nonempty conflicts and rejects unavailable script Sets instead of silently ignoring them. Package149 is prepared, not installed; persistence requires live verification. The earlier claim that empty legacy columns were sufficient is superseded.
