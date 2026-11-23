# Field and storage reference

exports/DynamicFields.yml and class-definition exports preserve native names/types. field-index.json and dynamicfields-reference.xml are derived navigation aids, not native import formats. package-field-index.json indexes packaged class defaults, while managed-fields.json indexes later managed additions with installer-source references. These are included separately, with provenance. Do not silently merge dated schema and runtime additions into a claim about current deployed fields.

## Exact script Sets

| Owning Set | Index | Text member |
| --- | --- | --- |
| AdvancedCondition | ZTAM-ConditionIndex | ZTAM-AdvancedCondition |
| FieldAsssignment | ZTemplate-ScriptIndex | ZRM-FieldAssignment |
| MasterTicket | ZTemplate-ScriptIndex | ZRM-MasterTicket |
| PolicyEvaluation | ZTemplate-ScriptIndex | ZRM-PolicyEvaluation |
| PolicyFilter | ZTemplate-ScriptIndex | ZRM-PolicyFilter |
| RiskAggregationEngine | ZTemplate-ScriptIndex | ZRM-RiskAggregationEngine |
| RiskScoringEngine | ZTemplate-ScriptIndex | ZRM-RiskScoringEngine |
| ScriptEngine | ZTemplate-ScriptIndex | ZTSM-ScriptEngine |
| ZTemplate-AutomationScript | ZTemplate-ScriptIndex | ZTemplate-ScriptBlock |

FieldAsssignment is the exact spelling. Storage support does not prove an executable consumer exists for every Set.

Use SplitSource/Assemble from the included ScriptBlocks module. Each row has a scalar index1–99 and at most 3800 characters. Indices must be unique and consecutive from1; no padded indices/gaps. Concatenation is exact with no inserted newline. Total source cap 376200. Entire source is one parsed document; fragments may split YAML structures.

The loader rejects code/blessed values, duplicate keys, multiple documents, recursive/oversized trees. Expanded tree cap 1048576 characters, depth 32 and 10000 nodes. Blank optional Set widgets can be empty; partial rows cannot.

Use existing Set-valued import columns with JSON/native nested rows as supported by the target importer. Do not also send standalone source-member columns, even empty legacy columns. Preserve source text/newlines and validate reassembly byte-for-byte. Excel's32767-character cell limit is separate from native Set capacity.

Exact known exceptions to general ZTicket naming include ChangeType, ChangeClassification and FAQApplication. Navis is an owner-selected managed0.1.5 Text field on Application GO for its stable topology label; see managed-fields.json and ApplicationNavisInstaller.pm. It is absent from the dated native export and must not be confused with a UUID field. Do not invent additional fields.

