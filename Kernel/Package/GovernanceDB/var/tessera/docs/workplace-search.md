# Workplace search (TESSERA-Base 0.1.0; introduced in Base198)

Workplace quick search now defaults to All, with Tickets, Assets, FAQ and People
filters. All shows a bounded preview per type; selecting a type exposes its full
permitted count and Previous/Next pages. The configured ticket preview count is
the common page size (default10, bounded100). Native dialog/close ownership and
the existing ticket permission and IPC behavior remain in place.


## 0.1.0: approved field name, registration, label and version series

Owner explicitly renames the field to **FAQApplication** and replaces planned
0.0.200 with **0.1.0**. The TESSERA-Base patch series now rolls every200 positions:
0.0.199 -> 0.1.0, then 0.1.1 through0.1.199 -> 0.2.0. The separate GovernanceDB
package version and PackageMerge target are unchanged.

There is no ZFAQ namespace dependency. Bootstrap first ensures native
DynamicFields::ObjectType###FAQ and DynamicFields::Driver###GovernanceObject
registration. If missing from SysConfig, it imports existing native XML defaults
without cleanup, then checks the actual handler. Disabled valid native handlers
are enabled; a restricted reference driver gains FAQ without losing its existing
object types. An unrestricted driver stays unrestricted. Missing native defaults
or a conflicting custom handler stop the hook before field creation.

A missing FAQApplication is created automatically with optional multi-Application
reference configuration. If legacy ZFAQ-Application exists alone, it is renamed
through the native DynamicFieldUpdate API using the SAME FIELD ID: existing FAQ
values and administrator configuration remain attached. Add/Edit screen keys are
migrated while preserving explicit disable overrides and unrelated fields. If
both names exist, installation stops for an explicit data merge; neither record
or its values are deleted. Reinstall never creates duplicate fields.

Both customer search boxes now display **Search** unconditionally. Their tooltip
and accessible label say **Search tickets, CMDB, FAQ and people**. The conditional
Ticket Search label fallback is removed; existing feature enablement, Enter
handling and backend authorization remain in place.

FAQ index readiness is independent of field/handler registration. The live faq,
configitem and customeruser Elasticsearch indexes and record counts are still
UNVERIFIED. This release does not create, rebuild or populate live indexes and
must not be treated as full live search acceptance. Native first indexing and
actual matching/permission checks remain deployment acceptance work.

## Historical Base199 correction after a failed198 Package Manager upgrade

The reported `ZFAQ-Application must be an FAQ GovernanceObject reference` error
was reproduced with the native DynamicFieldGet implementation: a missing field
returns `{}`, not undef. Base198 mistakenly treated that empty hash as an existing
incompatible field and stopped before overlay installation. Base199 checks for a
nonempty record, creates a missing field automatically and preserves/rejects a
real existing field according to its type. Manual field creation is unnecessary.
Install/upgrade/reinstall hooks now use the native ObjectsDiscard /
ForcePackageReload mechanism before obtaining Bootstrap, so a persistent Package
Manager worker loads the corrected code during the same request. They also fail
explicitly if InstallDefaults returns failure rather than silently continuing.

The actual customer search input is `#oooSearch`. Base198's paging module checked
only `#FulltextES`; Base199 supports both inputs, preserves the open dialog query
when native blur clears the field, and invalidates responses on actual edits.
Enter in an active Workplace search uses the existing search-input handler rather
than submitting the ticket-only fallback form. Both dashboard and ticket overview
show “Search Workplace” when Workplace search and Elasticsearch are enabled;
otherwise they retain “Ticket Search”. The accessible label follows the same rule.

Install Base199 through the normal package upgrade path; the failed198 attempt may
have written files before its post-hook stopped. Do not delete/create fields or
rerun Kubernetes migration/recovery as a workaround. In a container deployment,
source package installation still needs the existing matching image/bundle
workflow and consistent workers; this patch performs no live deployment.

Local regressions exercise the actual native missing-field method, creation and
reinstallation, genuine conflicts, both real search templates/modes and paging
input/AJAX handling. Browser/visual and native Linux installation acceptance are
still pending; the previous browser policy blocker has not been bypassed.

## Visibility contract confirmed on 2026-11-16

- Assets require ContractEntitlement coverage and an active matching
  SupportAssignment carrying `TESSERA::CMDB::READ`. Use the existing centralized
  `CustomerEntitlement::ConfigItemDetailAccessCheck` before returning any asset
  row or count. Entitlement-only selection in request workflows is unchanged.
- The owner approved the new exact field name `FAQApplication`: an optional,
  multivalue GovernanceObject reference restricted to the Application class.
  **Empty means applicable to all portal users.** A populated field requires an
  active SupportAssignment whose `ZTSMSupportAssignment-Application` resolves
  to any selected Application for the current customer. Missing, inactive,
  ambiguous or malformed nonempty application references deny access.
- FAQ still requires approved, valid, customer/public publication. Application
  scope does not publish drafts or internal articles. Restricted articles cannot
  be read anonymously even when their native publication state is public.
- People search is available to every authenticated portal customer across
  company boundaries, as explicitly requested. Only valid directory accounts
  are returned. The result contains name, email and phone; there is no full-user
  payload, account-management link, new account grant or profile-detail endpoint.

## Implementation

`Kernel::System::TESSERA::WorkplaceSearch` intersects current source IDs with
Elasticsearch in bounded250-document-ID requests. This avoids deep result-window
pagination and text-mapping assumptions about identity fields. Match queries
use explicitly selected fields and prefix matching. The index returns only an
identifier; display data comes from the current source object after permission
checks. All totals are calculated after authorization. Query scope and index
names are fixed server-side; the permission subject comes from the session.

Assets match Name/Number. People match login, name and email. FAQ matches title,
number, keywords and configured customer/public body fields. This release does
not claim arbitrary CMDB Dynamic Field or attachment fulltext coverage.

`FAQAccess` centralizes publication and Application checks. Customer/public FAQ
zoom, attachment/HTML subactions, print, native search/CSV, explorer counts,
news/top10, public RSS, related articles and announcements apply it server-side.
The customer Elasticsearch FAQ branch also intersects its existing native scope
with current permitted IDs. Existing native category navigation/search settings
remain; Workplace applies the new global published-FAQ contract, and direct
customer detail uses the same Application check.

Bootstrap creates the approved field only if missing and fails on a conflicting
ObjectType/FieldType. The Application class ID is resolved from GeneralCatalog.
Add/Edit screen settings are merged without replacing other fields or an
existing administrator override. Fresh/upgrade/reinstall use the same routine.
Existing FAQ content is preserved; its previously absent/empty scope remains
applicable to everyone. No governance objects or SupportAssignments are created.

The new FAQ route overlays derive from the repository's installed FAQ source;
their native basis hashes are recorded in `outputs/base198-validation.json`.
Unrelated working edits were excluded by reconstructing the stage from Base197.

## Validation and acceptance

`scripts/test/TESSERA/WorkplaceSearch.t` exercises real services, controller,
template and bootstrap methods with mocked source/index storage. It includes
empty/multiple/revoked/malformed FAQ scope, direct customer/public download/print
denial before content reads, asset read boundaries, directory projection,
over10000 candidates, pagination, session identity, metadata escaping and
idempotent installation.

`scripts/test/TESSERA/render_workplace198.pl` creates the real-template browser
fixture; `WorkplaceSearch.browser.js` tests scope changes, paging, focus, pending
clicks, stale responses and scrolling. **These browser assertions have not run
successfully here.** Edge exits without output; Chrome fails side-by-side startup;
the available in-app browser rejects local-file navigation by policy. No policy
workaround was used and no visual acceptance is claimed. Public RSS syntax also
requires the existing native `XML::RSS::SimpleGen` dependency unavailable locally.

Before deployment acceptance: native Linux fresh/197 upgrade/same-version
reinstall, real multi-index mappings and content freshness, agent FAQ multi-value
editing, empty/global vs application-scoped customers, revoked SupportAssignment,
direct/public/attachment/CSV/RSS isolation, and desktop/narrow/keyboard browser
checks. Benchmark typing latency on the real directory/CMDB: candidate enumeration
and live authorization prioritize correctness, but introduce work proportional
to object/match counts. No cross-user permission cache is introduced.

Use the standard package/source install and matching rebuilt web/daemon image
and bundle workflow. This change does not perform a live installation, reindex,
role grant or Kubernetes operation. Confirm the outstanding196 migration outcome
before any subsequent deployment.
