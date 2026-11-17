# Language families and dispatch

VERSION 1 is the supported version. ScriptEngine contains multiple entry points; do not mix their top-level grammars.

| Caller/family | Entry point | Shape |
| --- | --- | --- |
| GovernanceRole or typed discovery/selection | ScriptParse / ScriptEvaluate | SCRIPT, VERSION, LET THIS, SEARCH, REQUIRE, RETURN, CALL WEB SERVICE |
| Per-target Control evaluation | PolicyEvaluation::Evaluate | VERSION, TARGET, TIME ZONE, CHECK, ON FAIL; adapter also supports configured selection rules |
| Grouped finding assignment | GroupedFieldAssignmentsEvaluate | RETURN.GROUP FINDINGS with grouping/identity/field assignments |
| Scalar field assignment | FieldAssignmentsEvaluate | Existing YAML/line assignment form; inspect source/packaged example |
| Attestation/master-ticket declaration | ProgramParse / ProgramEvaluate | NEW @TICKET or CREATE TICKET, literal assignments, declarations, EXPECT/THEN/ELSE, SUBMIT |
| Boolean/value conditions | Evaluate / ConditionEvaluate / ValueEvaluate | Supported expressions from interpreter source, not arbitrary Perl |

## Selection/role YAML

SEARCH is a mapping/list. FOR supports Ticket, ITSMConfigItem, GovernanceObject and MELTObject; class-based searches need CLASS. AS declares a variable. LIMIT is positive and at most 1000. Complete scans probe overflow and must not silently truncate.

RETURN supports typed VALUE/AS, ALL collections, FIRST or EXACTLY ONE, and conditional IF with IS EMPTY/IS NOT EMPTY, THEN and ELSE. EXACTLY ONE rejects missing/ambiguous results. A typed collection's elements must match its declared kind/class. RETURN UNKNOWN explicitly fails closed.

LET THIS supports TICKET in this family and requires complete TICKET context. CURRENT OBJECT identifies the programming object; THIS identifies the runtime target. Do not assume a generic LOOP/IMPORT/HTTP/SHELL/SQL operator exists.

CALL WEB SERVICE accepts at most 20 configured calls: fixed SERVICE, INVOKER, WITH mapping, AS alias. Interpreter syntax support is not a provider grant; constrained selection callers reject effects. Arbitrary URLs, credentials and modules are not callable from YAML.

## Per-target evaluation

TARGET must match the bound type/class. CHECK.EXPECT uses supported condition expressions. CHECK.ON EMPTY specifies exact FIELD, RETURN Pass or N/A and a reason; malformed populated data is an error, not empty. TIME ZONE and a pinned evaluation clock govern TODAY/date arithmetic.

ON FAIL can emit THIS or use authored DESCENDANTS/AFFECTED searches. Traversal is bounded; depth/count overflow is UNKNOWN. Class-based descendant traversal is not ticket hierarchy traversal. Do not infer relationships from field labels.

## Assignment and line DSL

Grouped assignment requires authored GROUP BY, IDENTITY and FIELD ASSIGNMENTS. Iteration, reference resolution, merge and severity behavior must follow the actual packaged example/source. Stable identity controls retries; closed Risk episodes do not automatically reopen.

ProgramParse is a specific existing line grammar, not a general imperative language. It recognizes ticket creation plus SUBMIT, supported literal ticket assignments, ticket declarations and EXPECT result branches. Parse acceptance can be permissive and does not prove every authored line executed. Do not translate arbitrary pseudocode into this grammar.

The exact interpreter and caller adapters are bundled as source. Use them to resolve edge cases; the guide does not promise unsupported combinations.



## Exact condition/value operators

The condition interpreter recognizes IS NOT EMPTY, IS EMPTY, IS ON OR AFTER, IS ON OR BEFORE, IS GREATER THAN, IS LESS THAN, IS AT LEAST, IS AT MOST, DOES NOT EQUAL, EQUALS, CONTAINS, STARTS WITH and ENDS WITH. Comparisons use numeric semantics when both operands are numeric; otherwise ordinary string comparisons apply. CONTAINS/STARTS WITH/ENDS WITH are case-insensitive. Missing/invalid operands produce UNKNOWN.

Multi-condition source is line-oriented. Lines may begin AND or OR; unprefixed later lines join with AND. The runtime combines them in source order with three-valued logic. Do not invent inline Boolean precedence, general parentheses, NOT or an arbitrary expression language.

Supported value forms include double-quoted strings, numeric literals, TRUE, FALSE, EMPTY, verified @context field paths, NUMBER(...), STRING(...), DATE(...), DATETIME(...), PRODUCT OF [values], numeric multiplication/division and TODAY plus a nonnegative number of DAYS/MONTHS/YEARS. Division by zero is unknown. TODAY requires pinned EVALUATION.Now/TimeZone. Month arithmetic clamps end-of-month. Do not assume general addition/subtraction, SUM, regex evaluation or arbitrary functions exist.

A value path checks exact direct or DynamicField_ keys and can traverse native row indices; reference-class filtering resolves typed GovernanceObject IDs through its adapter. A multi-valued/structured result is not automatically a scalar. Different role/grouped-assignment path syntaxes are handled by their own resolvers; copying one into another family is not guaranteed valid.

## Search and cardinality details

WHERE maps each exact field to a single operator/value mapping. Class-based native searches support Name EQUALS/CONTAINS, Validity EQUALS valid, and configured Dynamic Field EQUALS/CONTAINS. Ticket native search has its own explicit whitelist; consult _ScriptFlatSearch rather than assuming arbitrary Ticket/DynamicField filtering. An injected SearchProvider can impose narrower behavior and caller-owned AllowedSearchType is checked before reading.

REQUIRE maps a previously declared variable to HAS EXACTLY; OTHERWISE supplies the failure message. RETURN FROM EXACTLY ONE rejects both zero and multiple results. FIRST does not establish uniqueness. ALL requires a typed Collection and validates every returned element. A scalar RETURN is a Scalar value, not automatically an object reference or command.

For authoritative edge cases read the included methods ScriptParse, _ScriptSearch, _ScriptNativeSearch, _ScriptFlatSearch, _ScriptRequire, _ScriptReturn, _ConditionEvaluate and _Value. The operator list does not bypass the caller's schema or permissions.
