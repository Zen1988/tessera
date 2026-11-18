# Offline validation and delivery

Run python3 tools/verify.py from the extracted pack. It verifies the manifest's SHA256 files without network access. Run perl tools/validate.pl selection path/to/source.yml with installed Perl/YAML::XS to invoke the actual packaged ScriptParse and ScriptBlocks round-trip. Use kind yaml for evaluation/assignment YAML loading only; the report explicitly says it did not evaluate runtime semantics.

Parser validation does not read live objects, authorize execution, validate all schema references or prove date/effect behavior. Source adapters and exact fixtures are included as reference. Full runtime tests require the matching installed Tessera dependencies and injected/native services.

Required test matrix:

- Happy path with exact typed return/effect.
- Empty optional value and absent required field.
- Malformed date/number/reference type.
- Zero/multiple matches; duplicate identities/addresses.
- Search/traversal budget overflow; cycles.
- Unauthorized actor, object or returned reference.
- Revoked scope between dispatch and continuation.
- Duplicate submission/callback and partial write failure.
- Uncertain remote outcome with no mutating replay.
- Unicode/newline/escaping and multi-fragment Set reassembly.

Deliver source, blocks, dependency list, tests/expected outputs, caller/storage/version contract and review notes. Native installation must preserve existing IDs/objects and test fresh/upgrade/reinstall. An AI should refuse to mark a script ready when required schema, caller adapter or permission context is missing.

