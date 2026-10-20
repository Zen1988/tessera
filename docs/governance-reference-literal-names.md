# Literal GovernanceObject references — 0.0.155

0.0.155 corrects the SQL quotation defect in154: OTOBO DB Quote escapes the value without enclosing quotation marks. Exact search now adds those marks explicitly, matching the existing CI literal lookup contract. Regression coverage executes generated SQL against SQLite and runs the actual CI Document importer through the inherited GO resolver. CI import errors now identify the owning field even when reference conversion throws before its old validation block.

Document and workbook references such as `TechnologyProfile: Monitoring & Observability` split at the first colon. The complete suffix is the identity; trim its surrounding whitespace only. Internal spaces, ampersands, additional colons, quotes, Unicode and wildcard-like characters retain their literal meaning.

The Document resolver uses native GovernanceObjectSearch NameExact and NumberExact equality lookup, avoiding DB QueryCondition expression parsing. Class restrictions, actor permissions and a two-result ambiguity check remain in force. Multiple matching identities fail closed; zero name matches can try the existing number/code fallbacks. Version references still return the matching object's VersionID. Existing explicit-ID compatibility remains unchanged.

Ordinary Name/Number searches keep their expression and wildcard behavior. No global parser replacement, name normalization, object renaming, data migration or new Dynamic Fields. Installation/upgrade/reinstallation replace package-owned code; administrator definitions and saved references are preserved.

Live diagnosis: parent913 / GO-TECHNOLO-00000116 exists uniquely as Monitoring & Observability. The old expression parser removes whitespace around its unescaped ampersand. Package155 supersedes154. After installing155 and reloading web workers, retry the original name-based nine-row workbook and the Product TechnologyProfile enrichment workbook. Live import acceptance remains pending. The number-based v2 workaround is not the permanent solution.
