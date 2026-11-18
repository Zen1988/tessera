# Worked recipes

The pack includes exact examples from its source OPM. Their business fields are examples, not built-in engine policy.

## Product discovery

var/governancedb/policy/control_discovery_products.yml searches Product ConfigItems and returns Collection<ITSMConfigItem.Product>. Use the same pattern for another verified class. Keep bounded complete search and correct return type. Store in PolicyFilter using its exact Set members.

## Per-target EOSL evaluation

product_eosl_evaluation.yml targets Product, checks ZTAM-EoServiceLife with a time zone/pinned clock, handles empty explicitly, and expands failing Product descendants/affected assets through verified paths. Test expired, threshold-equal, missing and malformed dates; cycles and search overflow remain UNKNOWN. Store in PolicyEvaluation, not in a role resolver.

## Risk assignment

product_eosl_risk_assignment.yml groups findings into stable identities, resolves references and assigns fields/severity. The entitlement variant partitions work by contract/support scope. Check required fields and affected Set paths against the included schema. Preserve idempotent identity/evidence; do not invent risk reopening or automatic closure.

## Role resolution

governance_role_dynamic_resolver.yml resolves the ticket Application's Platform RoleMap for CURRENT OBJECT. Ambiguous role rows fail closed. governance_role_requester.yml returns a typed support profile/customer fallback. These are distinct return shapes; use the actual caller contract. Do not attach a resolver script to reserved TESSERA capabilities.

## External discovery: capability boundary

An end-to-end business design is not automatically executable YAML. The authorized automation adapter must bind AWX template/inventory/scope, callback handler, Navis service/source permissions, envelope validation and receipt reconciliation. Application topology creation additionally needs approved mapping fields/service persistence. If those are absent, return a dependency plan rather than a fabricated CALL WEB SERVICE program.

All sample UUIDs/IDs and destinations are illustrative. The pack contains no live service credentials or blanket permission grants.

