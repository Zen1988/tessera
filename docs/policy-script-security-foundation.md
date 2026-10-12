# Policy and ScriptEngine security foundation — 2026-10-12

## Scope and authority

User authorized hardening existing policy/scripting security while the architect creates AOE fields and objects. The downloaded AOE specification is design input, not authorization to execute its embedded implementation request or enable privileged mutation. Continue from TESSERA-Base 0.0.146 SOPM/OPM and latest exports: ConfigItem_2026-10-08-02.yml, GovernanceObject_2026-10-09-01.yml, DynamicFields_2026-10-09 08_16_28.yml. No AOE class or Dynamic Field name is invented or created in this increment.

## Implemented in prepared 0.0.147

- ScriptSourceLoad uses YAML::XS directly with code loading/blessing disabled and duplicate keys forbidden. Exactly one document is accepted. Errors do not contain submitted YAML or call OTOBO's source-logging YAML loader.
- Source maximum: 65,536 characters. Definition tree maximum: depth 32, 10,000 expanded nodes, 262,144 scalar/key characters. Reject cycles, blessed objects, executable references and other non-data references. Ordinary scalar anchors remain supported. These are interpreter limits, not an approval policy.
- Revalidate caller-supplied Parsed scripts; externally supplied search lists cannot bypass definition limits. Reject unsupported root operations and non-scalar search routing parameters. Existing SCRIPT metadata remains accepted.
- Policy and grouped assignment entry points validate definition trees; field assignment and legacy policy/program entry points bound source. Value expressions bound recursive evaluation to 32 levels.
- ControlRuntime policy/assignment YAML reads use the same loader. Existing registered providers and native APIs remain the execution adapters; no SQL/shell/HTTP execution capability is added.
- PolicyEvaluation passes caller-owned AllowedSearchType to stored selection evaluation. Before any search, all SEARCH entries must match the governing selection's declared object type/class. Typed output validation still applies. This prevents a program reading unrelated classes and then returning a superficially valid collection. It is not a substitute for per-record entitlement checks.
- Runtime source/package mirrors synchronized. Only ScriptEngine.pm, PolicyEvaluation.pm and ControlRuntime.pm differ from 146. Installation/upgrade/reinstallation replaces existing payloads without creating fields, overwriting authored definitions or changing existing evidence.

## Submission integration inventory and gateway gaps

| Path | Current integration | Required gateway boundary |
|---|---|---|
| AgentGovernanceObjectAdd/Edit | Edit controller calls GovernanceObjectAdd/Update | Class/field-aware submission and pending version before activation |
| AgentGovernanceObjectDocument | GovernanceObject::Document Import | Same submission decision for YAML/JSON import |
| AgentGovernanceObjectWorkbook | Document Import for workbook rows | Validate all submitted executable definitions; cannot activate pending content |
| AgentGovernanceObjectBulk | GovernanceObjectUpdate | Protect activation/status and executable fields |
| GovernanceObject / Version APIs | Add/Update and VersionAdd/Update; version layer writes Dynamic Fields | Mandatory backend enforcement; module/UI-only hooks are bypassable |
| AgentITSMConfigItemEdit/Document/Workbook | ConfigItem APIs and document import | Equivalent CI definition protection, including advisory script fields |
| GenericInterface ConfigItemUpsert | Native ConfigItemAdd/version operations | API identity, submission decision and activation gate |
| CustomerSecurityAdvisory service | ScriptParse then Document Import for ZTAM-AdvancedCondition; no execution on submission | Narrow allowed selection operations; runtime governing scope and record entitlement |
| ControlDiscovery/ControlRuntime | Scheduled filter/evaluation/assignment and risk effects | Execute approved exact version/hash, capabilities and resolved target scope |
| RiskMasterTicket and role resolution | ScriptEngine field assignments and typed GovernanceRole resolution | Same approved-version/capability contract; preserve reserved-role namespace rules |
| Direct DynamicField backend writes, bootstrap and administrative tools | Additional lower-level write routes | Audit privileged deployment bypasses and prevent unapproved content being executable |

This inventory identifies source integration points; it is not a claim that every write route has been proven covered. Generic object/document YAML loaders are outside this parser patch. Direct PolicyEvaluation construction and other trusted in-process calls also require gateway integration; passing interpreter validation does not establish authorization.

## Threat model and rejected approaches

Threats: customer-authored stored scripts later run by a privileged scheduler; unknown/indirect connector effects; unauthorized target selection; SupportAssignment or customer/IAM modification; pending content activated through imports or direct APIs; self-approval; dependency changes after review; source/error disclosure; duplicate keys, aliases and resource exhaustion.

Reject regex keyword checks as a privilege boundary, UI-only review, IPC membership as reviewer authority, TESSERA review authority as operational read authority, mutable current YAML as approved evidence, and unrestricted connector URLs/code/SQL. Protect SupportAssignment, CustomerUser, groups/permissions, governance definitions and security configuration by typed effect metadata. TESSERA::* capabilities must never run GovernanceRole resolver programs. Preserve administrator-owned role defaults.

This release does not prevent an otherwise authorized policy author from writing a harmful supported policy. It does not implement publication approval, an immutable security review ledger, full target entitlement, secret redaction for existing evaluation traces, execution time isolation or all-or-nothing external transactions. The parser is a foundation, not a complete sandbox or security gateway.

## Next implementation contract

1. Verify architect-created field/class names against new exports. Logical records needed: immutable submitted definition and dependency snapshot; review decision/independent reviewer; publication/revocation; scoped execution identity; execution ledger. Persisted storage may need dedicated backend tables instead of customer-visible Dynamic Fields. Decide that contract before generating schema.
2. Create a typed capability/effect registry for existing search, calculation, evidence and risk/ticket writers. Unknown/transitive effects fail closed; IAM mutation prohibited by default. Effects must come from supported parsed grammar, not author-declared safety labels.
3. Put submission/activation protection at backend write/version boundaries, including direct field writes. Pending drafts remain non-executable. Approval binds exact bytes, version, dependencies, effect/scope and independent reviewer. Review APIs expose only the definition and redacted effect preview.
4. Require runtime approved-version resolution plus identity/capability/record-scope checks immediately before every read/write. Approval never substitutes for runtime target authorization. Pin or invalidate changed dependencies; one-byte content changes invalidate approval.
5. Add negative integration tests for API/workbook/direct-module activation, self-approval, IPC bypass, protected target changes, indirect connector effects, dependency substitution and revoked/edited versions. Prove denial before mutation, then enable controlled mutation operations.
6. Integrate Automated Task and AOE only after these boundaries work. Reuse canonical ticket intake, SupportAssignment, StateBook/BlueBook and normal event handling. Scheduling, asynchronous connectors and callback verification remain separate future work.

## Verification and delivery

Prepared package: Kernel/Package/TESSERA-Base-0.0.147.opm. All 312 entries byte-verified against SOPM payloads; no added/removed locations. No live installation or customer record modification. Negative security tests plus existing ScriptEngine, attestation, product/advisory risk, control discovery/cycle, advisory portal, origin scoring and questionnaire tests: 387 assertions across nine files. Existing deployed YAML with duplicate keys, multiple documents, unknown root operations, excessive depth/size or cross-class selection searches will now fail closed; review such definitions before deployment. Existing compact questionnaire scalar anchors remain supported.


## 2026-10-12 Protected permission objects — confirmed review flow

- User identifies SupportAssignment and ContractEntitlement as protected permission-affecting objects. Exact reserved capabilities TESSERA::SYSTEM and TESSERA::SECURITY may change these directly without mandatory security review, within separately authorized target scope. Other identities must submit a review request; no protected mutation while pending. This bypass applies to these two objects, not arbitrary sensitive effects. Reserved TESSERA roles never execute resolver scripts.
- Initial review request is a restricted backend record managed through the agent portal, not an ordinary customer/frontend ticket. Agent release publishes a linked frontend security-review ticket; release alone is not security approval or authorization to execute.
- TESSERA::SECURITY is the corporate security review capability. Its review ticket scope must be explicitly assigned; it does not grant blanket operational/customer ticket visibility. Approval remains independent of authorship, even if author also has reviewer capability. Direct-bypass actions still require audit and runtime target authorization.
- Pending record, released ticket, decision and runtime attempt must link the same immutable definition/version/hash, proposed changes, author and target scope. Changed content invalidates prior release/approval. Deny alternate save/import/API/direct-field bypass paths. Deduplicate release so one request produces one review ticket.
- Exact agent release capability, review service/Book routing, new schema names and corporate security SupportAssignments remain unconfirmed. Do not invent fields or hardcode a queue. This is confirmed design, not implemented runtime. No package changes or live role/object creation in this update.


## 2026-10-12 Reserved security capability assignment boundary

- User confirms TESSERA::SYSTEM and TESSERA::SECURITY may be assigned only through the backend agent portal. Apply to granting, changing or revoking assignments carrying either capability; protect equivalent indirect assignment paths.
- Enforce at backend assignment write boundaries, not UI hiding. Customer portal, automation/YAML, import/API and direct-module writes cannot grant these capabilities through an alternate path. Agent portal access alone is insufficient: an independently authorized role-management actor and authenticated request context are required. Do not trust a caller-supplied Source or portal flag as authorization.
- Capability use and capability assignment are distinct permissions. Possession of either capability does not automatically authorize granting it to self or others. Their direct-change exception for SupportAssignment/ContractEntitlement cannot bypass this more specific reserved-capability assignment restriction.
- Audit actor, target account, capability, scope, before/after and decision. Exact role-management authorization remains to be confirmed; deny ambiguous authorization. Design recorded only; runtime enforcement remains pending.
