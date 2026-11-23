# End-to-end authoring workflow

## 1. Define the runtime caller

Identify the programming object, exact storage Set, runtime target, desired return type and effect. A GovernanceRole resolver, ControlObjective filter, per-target policy evaluation and risk assignment are distinct callers. Choosing the wrong entry point can yield valid YAML with no useful effect.

## 2. Establish schema truth

Search exports/field-index.json, native DynamicFields YAML and the relevant class definitions. Check ObjectType, FieldType, multi-value behavior, reference class, Set Include members and catalogue values. Package-owned bootstrap/defaults and managed-field source overlay the dated schema baseline; they do not prove a live deployment matches. Do not invent replacements for absent fields.

Resolve deployment-specific IDs from names through authorized backend context. Never copy example numeric IDs, customer names, queue/group names or integration IDs into production.

## 3. Specify behavior before source

Write the target population, empty/missing/ambiguous behavior, clock/time zone, output/effect, permission boundary, maximum population and replay behavior. Unknown must remain unknown; empty must not silently Pass unless the policy explicitly says so.

## 4. Select a packaged recipe

Copy the closest exact example from var/governancedb/script or policy. Keep VERSION 1 and supported grammar. Adapt only verified fields/conditions. A policy should not require a new Perl module unless a genuinely new reusable adapter is needed.

## 5. Validate locally

Verify manifest hashes, use the real source loader/parser for its supported family, round-trip through native ScriptBlocks, inspect exact field/class dependencies and run positive/negative runtime fixtures. Parser acceptance does not authorize execution or establish semantic correctness.

## 6. Package the deliverable

Supply source.yml (or the supported line DSL), blocks.json for the exact owning Set, dependencies.json with field/class/catalogue/service references, a test matrix, expected return/effect, installation/version notes, and a review summary. If facts are missing, label the artifact draft and list exact dependencies; do not produce an apparently ready script using guessed names.

## 7. Native import and acceptance

An authorized operator reviews/loads through the native object editor/import path. Preserve existing object identity and administrator ownership. Do not import owning Set and standalone members together. Test a nonproduction target with actual runtime actor/scope, inspect evidence, verify retries/failure handling and only then activate through the applicable governance procedure. This guide grants no publication bypass.

