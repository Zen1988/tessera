# Offline ScriptEngine authoring

This is an authoring contract for another AI or developer without internet access. It is not permission to publish or run a script.

Download the generated TESSERA-0.1.5-ScriptEngine-Offline-Pack.zip from outputs after the release build. It contains this guide, an AGENTS.md entry point, exact packaged interpreter/adapters, package examples/defaults, dated native exports, derived field indexes, validators and SHA256 provenance. No secret/config/customer-data dump is included.

Read in order:

1. [Authoring workflow](workflow.md)
2. [Language and entry points](language.md)
3. [Fields and storage](fields-and-storage.md)
4. [Caller context and effects](context-and-effects.md)
5. [Worked recipes](recipes.md)
6. [Validation and delivery](validation.md)
7. [Limits and pending capabilities](limitations.md)

The package's SOPM/OPM and included runtime source outrank this prose. Verify the manifest first. Missing fields, classes, allowed values, service bindings or authorization context are blockers to executable output: report them instead of inventing names or IDs.

Python3 is enough to verify pack integrity. The optional real parser/Set validator needs an already installed Perl runtime with YAML::XS. Full date/runtime fixtures additionally require the dependencies supplied by the matching Tessera/OTOBO installation. The pack does not download packages or include platform-specific Perl binaries.

