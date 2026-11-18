# Entitlement-scoped EOS risk ownership — TESSERA-Base 0.0.156

Technology capability coverage determines the responsible SupportProfile. Assets retain ContractEntitlement references; they are not assigned directly to teams. Application remains the business context. Operational responsibility is resolved from SupportProfile and its existing SupportAssignments by the existing ticket workflow.

## Authoritative fields

- Asset: `ZTAM-ContractEntitlement`, `ZTAM-Application`.
- Product: `ZTAM-TechnologyProfile`.
- ContractEntitlement: `Contract-Coverage`, `Contract-SupportProfie` (the exported spelling).
- TechnologyProfile: `ZTSMTechnologyProfile-Parent`.
- Risk: existing `MELT-RelatedGO`, `MELT-RelatedCI`, `MELT-Reference` and other established Risk fields.
- Master ticket: existing `ZTicket-OwnerGroup` and `ZTicket-Application`.

No new Dynamic Fields, queues, assignments or customer capabilities are introduced.

## Matching and partitioning

The updated [Application EOS example](examples/controlobjective/application-eosl-risk-assignment.yml) introduces `GROUP BY / PARTITION BY`. FROM reads only entitlements linked to the affected asset. COVERAGE compares their declared TechnologyProfiles against the failed Product and actual matched Product references, using bounded TechnologyProfile ancestry.

With INCLUDE CHILDREN=1, entitlement coverage at a parent TechnologyProfile covers that profile and its children/descendants. A child coverage does not automatically cover its parents or siblings. With INCLUDE CHILDREN=0, matching is exact. MAX DEPTH and LIMIT bound the ancestry walk. Missing profiles, wrong classes, cycles, unreadable objects and overflow are errors, not partial successful scans.

Each Application/RiskStatement/Product/SupportProfile combination has a stable ID-based identity. The SupportProfile name follows the Application name in the display name. Identical display names cannot merge different profiles because the example uses REUSE BY IDENTITY. Renaming a profile updates the display name without changing its identity.

Multiple matching entitlements pointing to the same SupportProfile produce one partition. Entitlements pointing to different SupportProfiles produce separate Risks. Each Risk's RelatedCI list includes only that partition's affected assets, source Product and matching ContractEntitlements; its RelatedGO remains the single Application. Risk articles record SupportProfile, entitlement IDs and fallback evidence. Existing severity/lifecycle/RiskStatement/Framework rules remain in the authored YAML.

## Missing entitlement fallback

Only an absent/empty ContractEntitlement link enables ON MISSING. Its APPLICATION path resolves the Application; its ROLE is `APPLICATION::DEFAULT`, confirmed live as GovernanceRole1037. The existing GovernanceRoleResolver returns exactly one Active SupportProfile. That profile supplies the fallback partition identity, display name and ticket owner. A missing Application, unresolved/ambiguous default role or invalid result fails closed with a Control Activity Article.

Live E560F verification on 13 October found three assets linked to ContractEntitlement5033 and seven with no entitlement. A prior completed article references Risk23, but current retries fail in Application default resolution. Package159 preserves the fail-closed rule and adds the Application, role and underlying resolver error to the article so the exact failing mapping can be corrected. The Application1493 page visibly shows APPLICATION::DEFAULT mapped to SupportProfile1063; that visible mapping alone does not prove the ScriptEngine resolution succeeds.

An existing dangling entitlement, empty or invalid coverage, a missing SupportProfile, or no coverage match is an error. These do not silently fall back to Application ownership. `TESSERA::*` roles are never executed; they are reserved system capabilities.

## Framework ticket ownership

Install the matching [Framework MasterTicket example](examples/framework/entitlement-risk-master-ticket.yml) in the Framework's existing MasterTicket Set. It introduces RETURN / RESOLVE REFERENCES. The SUPPORT alias filters persisted Risk RelatedCI references through the ContractEntitlement class and reads `Contract-SupportProfie`. It must resolve one SupportProfile; zero entitlements invokes the same authored Application default fallback. `ZTicket-OwnerGroup` is assigned `@SUPPORT.GovernanceObjectID` before StateBook orchestration starts.

The configured Service and CustomerUser in the example are the existing sample values; administrators should retain their own authored values. No SupportAssignments are created, and no resolver role receives additional authority.

All finding partitions are planned before risk writes. Framework ownership is preflighted against the planned SupportProfile, so using the new risk grouping with an incompatible old Framework owner mapping fails before risk creation. Only ownership expressions are evaluated during this preflight; no fictitious Risk ID or ticket is created. Successful partitioned Risk creation also checks that master ticket reconciliation succeeded.

Existing master ledgers retain their original OwnerGroup and governance snapshot; this feature does not reassign an already-orchestrated ticket. New execution cycles retain the existing cancellation/restart policy and resolve current Framework governance. Existing Application-only Risks are preserved; the new support-partition identities create separate Risks rather than rewriting old history.

## Deployment and acceptance

0.0.156 adds a read-only ReferenceScope helper and two shipped policy examples. Fresh installation, upgrades and reinstallations replace package-owned files; administrator-owned definitions and saved programs are not overwritten. The new examples are opt-in, preserving existing workflows and schemas.

Install156 and reload web/daemon workers before saving the new constructs. Apply the updated EOS FieldAsssignment Set and the relevant Framework MasterTicket Set together. Verify two overlapping entitlement SupportProfiles create two Risks, repeated runs reuse both, each fresh master has the expected OwnerGroup before orchestration, and a no-entitlement asset resolves APPLICATION::DEFAULT. Invalid references must create error articles without advancing the successful cycle timestamp.

This package is prepared locally; no live policy or entitlement edits, installation or end-to-end production acceptance are claimed. Historical owners/risks are not migrated. Partial effects from a later storage/workflow failure are not rolled back; existing identity and ledger reconciliation support retries. Customer entitlement permissions remain separate from this operational risk-owner selection.
