# TESSERA Project Next Focus

## Current accepted baseline — 0.0.129

- User confirms129 works and accepts the accumulated functional baseline. Approval recovery0052 is implemented and accepted; completed design, source and validation are recorded in PROJECT_STATUS.md. Continue from latest129 SOPM/OPM, not earlier repair assumptions.
- Remaining targeted checks: future fresh-cycle approval capture persists master outcome/date/marker, idempotent fresh/upgrade/reinstallation, and final OTOBO11.1 compatibility when stable. Prior detailed live checklists below are historical/unverified specifics and must not override this accepted baseline.


## Approval gate and session greeting — 0.0.128 live acceptance

- Install128 and hard refresh. Pending risk parent must be absent from Risk list, all dashboard counts/charts/matrices and export even after Assessment submits. Complete the required final Book-governed approval normally; its master decision marker/outcome/date should make submitted rows eligible. Do not backfill approvals or alter immutable history to force display. Approved missing/expired dates retain Review required behavior.
- Fresh login: choose emoji, see message for4 seconds, then card disappears. Immediately navigate elsewhere and return: no prompt. Refresh/another tab same login: no prompt; logout/new login: prompt again. Browser receives HttpOnly temporary dismissal cookie with no mood/message content. Verify desktop/mobile card edges align with dashboard boxes; native tiles and other controls remain usable. Newly discovered uses Assessment native Created.


## Profile preference layout — 0.0.126

- Install126/hard refresh. Check Current photo label above preview, Upload photo label above file picker, visible small removal checkbox with single label, laptop/mobile wrapping and working upload/removal. Other preferences retain native layout.


## Avatar action pointer path — 0.0.125

- Install125/hard refresh. Hover avatar, cross gap to gear then Logout; controls must remain clickable until pointer leaves whole row. Confirm hidden controls do not block page and keyboard focus/touch still works.

## Photo registration — 0.0.124 deployment

- Install124 to repair missing NavBarName in123 registration; deploy photo settings if pending and hard refresh. Verify profile preferences/upload/remove and stable sidebar controls. Includes123 owner mapping; existing Framework YAML still needs explicit assignment. No unrelated access settings overwritten.

## Ownership and profile deployment — 0.0.123

- Install123/hard refresh. Confirm Preferences/Profile photo upload/remove, stable avatar and gear right/logout next right on hover/focus/touch. GD required. Verify unrelated preferences preserved.
- Add `ZTicket-OwnerGroup: '"APPLICATION::DEFAULT"'` under RETURN/FIELD ASSIGNMENTS in applicable Framework ZRM-MasterTicket; full example docs/examples/framework/risk-master-ticket.yml. Fresh Risk SR stores Application default RoleMap SupportProfile before orchestration and retains it during assessment/remediation. Missing/ambiguous resolution prevents creation. Existing0050 unchanged; no snapshot backfill.


## Ticket dashboard date/type — 0.0.122 deployment

- Install122, hard refresh. Verify all five drilldowns show Ticket type before Ticket number, populated UTC creation dates, oldest-first rows and corrected seven-day count including held tickets. No ticket data changes required.

## Customer profile photo — 0.0.121 deployment

- Install121 (declares GD2.0 server resize dependency), hard refresh. In Preferences/Profile photo upload JPEG/PNG and verify128px square preview/navigation photo across refresh; remove returns initials. Check gear right of avatar on hover/keyboard focus, stable picture, touch layout and logout access. Verify another customer continues to see only own photo. No live account writes made by agent.121 includes120 clickable metrics and rolling closure window.


## Ticket metric drilldowns — 0.0.120 deployment

- Install120 and hard refresh Tickets. Click each of the five cards and check matching count/list, oldest creation date first, OwnerGroup names and source links. Closed window label should show prior calendar-month day through today UTC; verify a long-existing ticket closed recently is included and an earlier closure excluded. Failed remains all-time closed unsuccessful. Retains119 right-header toggles and118 searches. No workflow action required.


## Overview consistency and Ticket dashboard — 0.0.119 deployment

- Install119, hard refresh Tickets/Assets/Risk. Verify header New Ticket then Export Tickets, single export action, List/Dashboard toggle immediately to the right of blue Export and Dashboard default. Search should appear only in List: existing ticket fulltext, Asset name/number/tag/type and Risk configured display values. Verify list filter/pagination/export retain context.
- Check five Ticket cards against permitted All tickets: nonclosed including hold, unclosed at least7 days, all closed, only closed unsuccessful, directly IPC-delegated tickets. Click seven-day count and verify oldest-first creation date, readable OwnerGroup and links. Verify wide/narrow layouts and empty result lists. No workflow action needed for inspection.119 includes118/117 matrix compaction and earlier paired dashboard changes.


## Dashboard — 0.0.117 deployment

- Install117 and hard refresh. Check compact matrices show every impact column side by side at laptop width, labels wrap, and nonzero cells still expand links. Assets/CMDB and Risk Register default Dashboard; Export stays top-right. Verify paired Inherent/Residual Category and Risk Category charts and Framework-coloured matrices; selecting a category updates both, each cell opens its Assessment links. Summary counts are shared once. Check narrow-screen stacking, long labels, empty scope and configured Excel export. Includes115/116 dashboard changes; no separate earlier installation needed.
- Scope and limits recorded in Status: visible governed Assessment rows across Current/Review, New by Assessment created date, current Framework definitions, unavailable Framework/scales cannot generate matrix. Live visual acceptance pending.


## Assessment encoding — 0.0.114 deployment

- Install114 (includes113), refresh Assessment0047 Ticket330. Confirm custom rows render and Framework scales load. Assessment template malformed UTF-8 repaired; restart cycle confirmed by user screenshot. No submission required for view verification.


## Evidence wrapping — 0.0.113 deployment

-112 submission now confirmed by user screenshot.113 fixes wrapping for future execution/diagnosis articles; existing immutable article HTML is not rewritten. Verify new snapshot long labels wrap without overlapping values at laptop/narrow width. Downstream Unsuccessful lifecycle behavior remains independent live verification.


## Actual runtime form — 0.0.112 deployment

- Install112; agent reproduced111 failure and confirmed actual runtime form lacked FormID. After refresh/reopen, inspect populated FormID in named ZTSMRuntimeActionTreat form, search/reselect reference and retry user-authorized treatment. Live112 success not yet verified. No reference validation relaxation.


## Runtime reference validation — 0.0.111 deployment

- Install111, Ctrl+Shift+R, reopen treatment and reselect reference through search so cached allowed IDs bind to populated FormID. Retry intended treatment. Existing110 field-specific errors retained. Live end-to-end validation still pending.


## Treatment submission — 0.0.110 deployment

- Install110, refresh and reopen form to obtain proper FormID, reselect Treatment Ticket via search, fill work/outcome, then retry intended submission. If rejected, field-specific error should identify validation cause. No permission/reference validation relaxed. Live retry pending.


## Remediation plan guidance — 0.0.109 deployment

- Install109 directly (108 is superseded), Ctrl+Shift+R, reopen treatment. Plan remains visible with no checkbox and no acknowledgement error on submission; existing required treatment fields still enforced.27 implementation checks recorded in Status.


## Risk-plan acknowledgement — 0.0.108 deployment

- Install108, Ctrl+Shift+R and reopen treatment form. Checkbox I have reviewed the mapped risk treatment plan above must appear beneath mapped plan and respond to label click/Space. Unchecked submission should remain in form with required validation; checked allows normal validation. Avoid submitting test workflow merely for visual inspection. Existing server requirement remains enforced.


## Runtime dropdown alignment — 0.0.107 deployment

- Install107 and Ctrl+Shift+R. Check Outcome selected text stays inside its inner control before/after hover, focus, change and clear; reopen dropdown and verify options still usable. Verify Remarks label and narrower layout. CSS-only patch; no submission required.


## Runtime hover and Result — 0.0.106 deployment

- Install106, Ctrl+Shift+R, reopen0045. Verify hover/focus on Risk Treatment Ticket keeps its label on border, Result shows plain Step/Result, and tall empty wrapper is gone. Plan already confirmed visible with105. Live visual checks pending; no submission required.


## Remediation follow-up — 0.0.105 deployment

- Install105 and Ctrl+Shift+R; reopen0045. Confirm Assessment0043 plan test is displayed, Result default has plain Step/Result, and labels/textarea align.104 follow-up supersedes the104 acceptance steps. No submission needed to inspect. Current lookup collects matching successful assessments under the same parent; future iteration selection should be coordinated with execution role evidence policy if remediation retries accumulate assessments.


## Remediation rendering — 0.0.104 deployment

- Install104, Ctrl+Shift+R and reopen0045 treatment action. Verify matching Assessment plan text appears, Result default shows Step/Result without HTML tags, and labels/textarea align on laptop and narrower screens. No submission needed for visual check. If plan remains missing, inspect persisted Assessment origin/statement/row values; only the confirmed scalar extraction defect was corrected.


## Universal role lookup — 0.0.103 deployment

- Install103. Existing managed TESSERA-ACTIVITY-ROLELOOKUP loses its old type allowlist; runtime excludes master types using ZTSM::RequestType. Rerun the role lookup job once for existing pending0045 and verify OwnerGroup resolves via TICKET::ASSESSOR YAML from closed Assessment0043 to ICA::ATFM::CLOUD. Fresh execution types should require no job filter edit; catalog master types remain excluded, closed/held evidence untouched. No live install/assignment change performed.

## Framework scales — 0.0.102 deployment

- Install102 and Ctrl+Shift+R. Set Framework ZRM-LikelihoodScale/ZRM-ImpactScale to positive integer maxima, and ensure catalog classes contain valid numeric names1 through intended maximum. Verify3×5 then10×10 choices on both inherent/residual fields, preserved valid selection, out-of-range reselection, calculated products and authored matrix badges. Missing/invalid Framework scales must block submission. No package install or live Framework/catalog updates performed by agent.
- Scale implementation complete; remaining Framework design is immutable version/config evidence and selected-Framework origin scoring. Historical101 scale design entry below is superseded by102.

## Assessment classification — 0.0.101 deployment and Framework scales

- Install101 and Ctrl+Shift+R. Verify dropdown score changes and Framework overrides update inherent/residual labels/colours; authored9 Low agrees with Register. Test missing rules neutral and new article labels. Implementation checks recorded in PROJECT_STATUS.
- Design Framework-specific allowed likelihood/impact scales (user proposes3×3/5×5), render choices from explicit scale metadata and validate submissions server-side. Do not infer scales from severity score bands or invent Dynamic Fields before export/schema agreement. Current101 does not restrict dropdown values.

## Risk Register Framework colours — 0.0.100 deployment

- Install100 and Ctrl+Shift+R. For submitted eligible Assessment rows, verify inherent/residual score badges use selected ZRM-Framework RiskMatrix and severity colours/names. Unmapped/missing rules remain neutral. Excel values stay unchanged. Implementation42 assertions in PROJECT_STATUS. User confirms99 replacement ticket exists.
- Remaining design: immutable submission-time Framework matrix/version snapshot and selected-Framework calculation. Current display uses current matrix explicitly; no historical score rewriting.

## Cancelled Risk Management restart — 0.0.99 deployment

- Install99. With TESSERARiskMasterTicket scheduler enabled and daemon running, next five-minute reconciliation should replace cancelled master0037 for still-active Risk21. Verify one new master and Assessment, previous-cycle link and retained0037/0041 cancellation history. Repeated scheduler delivery must reuse the fresh active master. No live restart or install was performed by the agent.

## Assessment Framework selection — 0.0.98 deployment

- Install98 and Ctrl+Shift+R. Set TESSERA::RiskAssessment::DefaultFramework to exact existing Asset Risk Management. Retain administrator Set Include mandatory rules. Apply optional ZRM-Framework mapping to Framework ZRM-MasterTicket using docs/risk-assessment-framework.md; no live YAML was modified. Start a fresh case and verify default, statement/clear fallback, manual override/reopen, mapped Framework inheritance, mandatory block and article name.
- Old test master0037 and active treatment0041 are cancelled; completed assessment/approval history retained. User will redo assessment. Do not delete or silently rewrite evidence.
- Pending enhancement: execute selected per-row Framework scoring/matrix/colour rules and capture immutable Framework version/config evidence. Current98 adds selection/persistence/mapping only; do not claim that selecting a different Framework changes calculations or colours. Trace latest Framework exports and authored rule schema before implementation.

## Risk Register configuration recovery — 0.0.97 deployment

- Install97. Open TESSERA::RiskRegister::Columns; restore default if96 invalid empty-row override persists, save and deploy. Expect native YAML editor with13 initial mappings. Verify deployment and report/export;21 checks recorded in PROJECT_STATUS.

## Configurable Risk Register — 0.0.96 deployment

- Install96 and Ctrl+Shift+R. Verify assessment risk rows and child links, mapped scores/action/plan, master governance context, Excel selected-view export and non-IPC visibility. Configure TESSERA::RiskRegister::Columns using docs/risk-register-sysconfig.md; no inferred org mapping or residual exposure conversion. Implementation and97 assertions recorded in PROJECT_STATUS.

## Remarks label — 0.0.95 deployment

- Install95 and Ctrl+Shift+R; verify shared Approval Remarks label aligns near the left border on laptop/narrow view. Includes94 replay guard; fresh assessment progression test remains pending.

## Chapter completion replay — 0.0.94 deployment

- Install0.0.94. Use a fresh assessment to verify completion creates Approval and waits, without spawning treatment early. Repeat delivery must not advance an already-changed Book/level/iteration. Implementation and50 checks recorded in PROJECT_STATUS. Existing master320/Treatment324 need controlled recovery before reusing that case; no automatic data repair is included. Verify authored Book behavior for RiskAccepted after final approval separately.

## Risk Register — 0.0.93 UI deployment

- Install0.0.93 and Ctrl+Shift+R. First verify header, tabs and card align in native portal content area, clear fixed sidebar and work on laptop/mobile. Functional tests can follow separately. Refresh customer portal. Verify new Risk Register button, Current / Review required tabs, master-only inclusion, closed accepted current records, exact365-day expiry and missing-date review. Confirm requester/governed participant visibility and denied queue/company-only accounts. Implementation, date assumptions and121-test evidence recorded in PROJECT_STATUS.
- Test final governed Approval completion writes master RiskAssessmentOutcome plus existing ITSMDecisionDate; replay must preserve date, renewed approval establishes a new date. Legacy missing master decisions remain Review required, without implicit child recommendation backfill. Annual reviews use existing governed ticket interaction; no automatic renewal or reassessment launch.

## EOSL name mapping activation

- Apply docs/examples/controlobjective/product-eosl-risk-name-update.yml to EOSL ControlObjective ZRM-FieldAssignment; next failing evaluation should include the source Product name. Shared Risk identity is preserved, so the name represents the latest evaluated Product. Implementation and108-test validation recorded in PROJECT_STATUS; live activation pending.

## Asset dashboard — 0.0.91 deployment

- Install0.0.91 and refresh Your Assets. Verify List/Dashboard beside Export, distribution counts/percentages by displayed Asset Type, and unique assets tagged in accessible active Risk Management tickets. Both views must follow current filters and entitlement; closed tickets must not contribute. Implementation/tests recorded in PROJECT_STATUS; live dashboard visual acceptance pending.
- User confirms0.0.90 Name/header alignment. Grouped Excel implementation remains unchanged; download acceptance is still pending.

## Multiple asset entitlements — 0.0.88 deployment

- Install0.0.88 and verify Zen sees iaas-ext-aci-node1 through its ATFM Management entitlement despite the additional Network Management entitlement. Check detail and list agree, and unrelated assets remain excluded. Implementation in PROJECT_STATUS; Workload ldcphiaasesx204 is user-confirmed visible after complete-candidate fix.

## Customer navigation — 0.0.87 deployment

- Install0.0.87 and refresh customer portal. Company Tickets should be absent while personal Tickets and entitled Assets remain available. Implementation recorded in PROJECT_STATUS; package includes complete asset lookup0.0.86.

## Complete customer asset list — 0.0.86 deployment

- Implementation and live entitlement trace recorded in PROJECT_STATUS. Install0.0.86 and verify Zen sees ldcphiaasesx204 through the matching PMT entitlement/read assignment. Check counts, pagination and export include all authorized matches beyond1000; denied assets remain excluded. Candidate completeness is implemented without raising permission scope; large-CMDB performance optimization remains future work.

## Assessment reference picker — 0.0.85 deployment

- Implementation is recorded in PROJECT_STATUS. Install 0.0.85 (includes input-relative button alignment), refresh browser assets and verify Risk Statement uses the existing search-button modal, display text is read-only, Apply updates defaults and required validation uses selected IDs. Repeat for added rows and target references.

## Assets navigation — 0.0.83 deployment

- Customer dashboard response is user-confirmed restored after the 0.0.83 correction was supplied; details are in PROJECT_STATUS. Remaining check: Assets is hidden without a matching CMDB read assignment and visible for authorized customers; direct URLs retain backend entitlement enforcement.

## Acknowledgment checkbox UI — 0.0.81 deployment

- Delegation GUI fix is user-confirmed; implementation and acceptance are recorded in PROJECT_STATUS. Shared override/recovery controls and detailed keyboard/unchecked-submit coverage remain unconfirmed. No live action submitted by the agent.

## Namespace editor compatibility review — 2026-10-06

- Set/Group namespace lookup and absent-input preservation are implemented in 0.0.77; details are in PROJECT_STATUS. Namespace ZRM / Name RiskAssessment is restored live. Install 0.0.80 to correct the empty-hash lookup fallback, then verify existing Assessment values load.
- Review legacy GeneralCatalog, Queue, SLA, Type and MasterSlave editors for the same issue; determine installed ownership before changes. Preserve field IDs, Include rules, values and explicit administrator choices. No automatic bulk renaming.

## RiskAssessment 0.0.80 deployment

- Runtime now prefers unprefixed `RiskAssessment` with legacy lookup compatibility; implementation details are recorded in PROJECT_STATUS. Install 0.0.80 (includes prior fixes) and verify existing Assessment 321 loads its stored values without recreation. Missing-name detection now matches OTOBO empty-hash behavior.

## Earlier Apache exception

- Required-field behavior is user-tested and reported working; implementation and acceptance are recorded in PROJECT_STATUS.
- The earlier Apache 500 still has no matching server exception available. Investigate if it recurs; do not claim its root cause was confirmed.

## EOSL Product Control and Grouped Risk — Corrected 2026-09-28

- Product is the Control target. The authored PolicyFilter selects Product
  ConfigItems; discovery creates/reuses one Control per Product. The current
  live and packaged filter does this. `ZRM-CIInstance` identifies that Product.
  `ZRM-GOInstance`, `ZRM-TKInstance`, and `ZRM-MOInstance` retain their target
  object meanings and are not grouping slots.
- Evaluate each due Product Control against its EOSL date. Empty EOSL returns
  N/A. On failure, the authored evaluation finds affected assets. Risk grouping
  then uses scenario, RiskStatement and Application as the stable identity.
  The Risk display name for this policy is like `IS-4: EOSL: IaaS Extension`.
  A second failed Product in the same group reuses the Risk and unions related
  ConfigItems. The Application is recorded in `MELT-RelatedGO`; the statement
  is recorded in `MELT-RiskStmt`.
- The old `MELT-Reference` included Product ID. The revised assignment removes
  it, tests shared Risk reuse, and is now saved on live ControlObjective 767.
  Package 0.0.56 is installed. Risk 21 was created for the ICA IaaS Extension
  group at 15:50 SGT on 28 September and reused on the next day's evaluations.
  Nine older asset-level Risks remain after the user deleted Risk 19. They have no grouped
  reference, Application or RiskStatement fields, so review their lifecycle
  and reconcile them with Risk 21 before treating the visible active Risk count
  as the count of current grouped risks.
- `MELT` 0.0.25 is installed. Normal Delete links now show a confirmation
  page; dialog calls use `AJAX=1`. Risk 19 was deleted, and grouped Risk 21
  remained present in the live SQL check.
- `MELT-Control` is currently single-valued. Keep its first Control and record
  every contributing Control in Risk activity evidence. Do not present it as a
  complete list of failed Controls.

## Risk Calculation Framework - deployment and live verification

- 0.0.70 is built locally; OTOBO still has 0.0.69 installed. Obtain action-time
  approval before uploading/installing the package.
- After installation, allow scheduled Risk master reconciliation to backfill
  Assessment 312. Verify the YAML-authored automatic calculation article on
  Assessment 312 and parent ServiceRequest 311 before the engineer submits.
  Confirm base dimensions, raw/effective factors, factor chains, adjusted
  decimals, ceiling results, and Framework score are readable and separate from
  the later assessment matrix/article.
- Framework 1597 (Application Risk Management) scores once from the Application
  context. Framework 1599 (Asset Risk Management) scores per applicable asset.
  Both article templates are authored in their Framework's
  `EVIDENCE.AUTOMATION ARTICLE` YAML. Keep the standalone scoring YAML and
  GovernanceObject exports in `docs/examples/framework/` synchronized with the
  live objects.
- Confirm linked-ticket read access for Abdul Malik and other support-profile
  participants while verifying they cannot perform another assignee's task.
  Also check child ServiceRequest `CustomerID` propagation and AdminLog after
  reconciliation.
- Future methodology decisions: define Platform's separate factor
  contribution, residual scoring from mitigation Controls and rating
  thresholds, and how to migrate historical per-asset EOSL Risks or remove
  recovered ConfigItems. Existing grouped runtime preserves historical
  contribution and raises severity only.
- Framework applicability and scoring formulas remain authored governance
  rules. Do not infer a Framework from Policy ancestry or use the superseded
  Application MAX aggregation draft.


## ControlObjective Evaluation - Deployment and Next Decisions

User confirmed 0.0.46 live discovery creates Controls. Local 0.0.47 implements authored
VERSION 1 evaluation, calendar expressions, descendant/reference traversal and asset Risk
assignment. Completed design is recorded in PROJECT_STATUS and the architecture document.

- Install/test 0.0.47 with packaged evaluation/assignment YAML. Verify due dispatch, missing
  date N/A, Pass short circuit, descendant impact, four asset classes and shared Risk reuse.
- Confirm fresh install, upgrade/reinstall and actual daemon execution. Adapter tests do not
  constitute live validation. Exercise limits before scanning large populations.
- Define Risk resolution/reopening and contribution lifecycle. Passing checks perform no
  descendant scans and do not close existing Risks; preserve history.
- Define retirement/evaluation eligibility for historical Controls after PolicyFilter narrows.
- Paginated discovery and further traversal operators remain future work; current discovery
  maximum is 1000 and overflow fails rather than truncates.
- CustomerUser remains deferred. Ticket discovery works; descendant traversal currently
  requires a class-based CMDB/GovernanceObject/MELTObject target.
- Keep business conditions, target classes, paths, thresholds and assignments in authored
  policy. Never add Product/EOSL-specific engine branches or invent Dynamic Fields.

## Asset Import Through Service Request

### Confirmed boundary

- The customer Assets page provides export only; it must not directly import, create, overwrite, or merge ConfigItems.
- Asset import will be introduced later through a governed Service Request workflow with reviewable execution evidence.
- DynamicField Set and DynamicField Group payloads use JSON within their spreadsheet cells so repeated and nested values remain intact.

### Identity reconciliation

- Prefer a defined Asset Tag as the strongest business identity check.
- Then evaluate ConfigItem number and other class-appropriate identifiers.
- A likely match must produce a duplicate/merge suggestion for review; it must not silently create a second asset or overwrite/merge the existing asset.
- The eventual SR must record the match evidence, selected resolution, and merge/update result.

## Incident Diagnosis Loop and Iteration Runtime

### Objective

Implement Incident Diagnosis as a first-class, loop-capable workflow stage.

Incident handling is different from Service Request / Change because the required recovery action may not be known at the beginning. Incident workflow must support repeated investigation cycles until recovery is verified.

```text
Incident Raised
→ Diagnose
→ Assess
→ Endorse
→ Approve
→ Resolve
→ Verify
→ if verification fails, return to Diagnose with next iteration
```

Previous diagnosis, assessment, resolution, and verification records must remain as evidence. The system must not overwrite previous attempts.

---

## 1. Parent Incident Intake Fields

Requester-provided incident information belongs to the parent Incident ticket.

| Field | Purpose | Provided By |
|---|---|---|
| `ZIN-Observed` | What behavior / issue was observed | Requester |
| `ZIN-ErrorMessage` | Error message, alert, screenshot description, log snippet, or symptom evidence | Requester |
| `ZIN-AffectedCI` | Affected CI / system / component reported by requester | Requester |
| `ZIN-Iteration` | Current incident investigation iteration | System |

Important rule:

```text
ZIN-Observed, ZIN-ErrorMessage, and ZIN-AffectedCI belong to the parent Incident ticket.
They are requester-provided intake fields.
They must not be treated as diagnoser input fields.
```

Diagnosis child tickets may display these parent values as read-only context, but must not overwrite them.

---

## 2. New State: `diagnose`

A new lifecycle state/stage exists:

```text
diagnose
```

When parent Incident enters `diagnose`, it should run BlueBook normally.

Expected runtime behavior:

```text
Parent Incident Stage = diagnose
→ StateBookReader detects diagnose stage
→ BlueBookReader loads BlueBook chapters for diagnose
→ BlueBookReader creates child Diagnosis tickets
```

Diagnosis is normal BlueBook orchestration, but Diagnosis child ticket rendering and submission require special handling.

---

## 3. New Ticket Type: `Diagnosis`

Add / use new ticket type:

```text
Diagnosis
```

Diagnosis is similar to Assessment as a child workflow ticket, but it has a dedicated diagnosis form.

When:

```text
TicketType = Diagnosis
```

the portal should load the custom diagnosis form based on:

```text
release/next/ideal.jpg
```

The form is for diagnoser input only.

---

## 4. Diagnosis Child Ticket Fields

Diagnosis child tickets capture diagnoser investigation result.

| Field | Purpose | Provided By |
|---|---|---|
| `ZIN-Diagnosis` | What the diagnoser checked, found, ruled out, or reasoned | Diagnoser |
| `ZIN-Outcome` | Structured diagnosis outcome | Diagnoser |
| `ZIN-Plan` | Proposed recovery / workaround / next action plan | Diagnoser |
| `ZIN-Summary` | Short diagnosis summary | Diagnoser |
| `ZIN-Iteration` | Current incident iteration copied from parent | System |

Do not include these as diagnoser-editable fields:

```text
ZIN-Observed
ZIN-ErrorMessage
ZIN-AffectedCI
```

Diagnosis form may display parent incident context as read-only:

```text
Observed issue: parent.ZIN-Observed
Error message: parent.ZIN-ErrorMessage
Affected CI: parent.ZIN-AffectedCI
Current iteration: parent.ZIN-Iteration
```

---

## 5. Governance Role: `DIAGNOSE`

For all diagnosis BlueBook chapters / diagnosis child tickets, add governance role:

```text
GovernanceRole = DIAGNOSE
```

This separates diagnosis from assessment.

```text
Diagnosis = investigate incident symptom / cause / applicability
Assessment = assess proposed action / risk / feasibility
```

Do not reuse `ASSESS` for diagnosis.

---

## 6. Diagnosis Outcome Logic

If diagnosis outcome is:

```text
ZIN-Outcome = Not Applicable
```

or:

```text
ZIN-Outcome = Recovered
```

then it should not generate follow-up recovery/action task from that diagnosis.

If diagnosis outcome is actionable, such as:

```text
Symptom Observed
Cause Observed
Root Cause Observed
Severity Confirmed
```

then the system should generate the next task set for that diagnosis result.

Core rule:

```text
Only actionable diagnosis outcomes should proceed into task generation.
Not Applicable and Recovered do not spawn recovery/action tasks.
```

---

## 7. Multi-Diagnoser Handling

Diagnosis is different from Assessment because multiple teams may diagnose the same incident in the same iteration.

Example:

```text
Iteration 1:
- Network Diagnosis → Not Applicable
- Server Diagnosis → Symptom Observed
- Application Diagnosis → Cause Observed
```

When diagnosis children complete, parent logic should pull all Diagnosis child tickets where:

```text
ParentTicketID = current parent
ZIN-Iteration = current parent ZIN-Iteration
TicketType = Diagnosis
```

Then evaluate their outcomes.

```text
If ZIN-Outcome is Not Applicable or Recovered
→ no action task generated from that diagnosis

If ZIN-Outcome is actionable
→ generate next task based on StateBook / BlueBook runtime logic
```

There may be multiple actionable diagnosis tickets in the same iteration. Do not collapse diagnosis into a single winner too early.

---

## 8. Propagate `ZIN-Iteration` to Incident Children

Every incident child ticket created by BlueBook should inherit:

```text
ZIN-Iteration = parent.ZIN-Iteration
```

This applies to:

```text
Diagnosis
Assessment
Endorsement
Approval
Resolve Task
Verification
```

For Service Request / Change, this field can be absent or default to `1`, but it must not break existing flows.

---

## 9. BlueBook Runtime Must Compare Iteration

Current runtime matching may use:

```text
ParentTicketID
Stage
BlueLevel
BlueRecordID
```

For incident, this is not enough.

When `ZIN-Iteration` exists, runtime identity must include it:

```text
ParentTicketID
Stage
BlueLevel
BlueRecordID
ZIN-Iteration
```

Why:

```text
Iteration 1 diagnose task completed
Verification failed
Parent returns to diagnose
Iteration becomes 2
BlueBook must create new diagnose child tasks
```

Required rule:

```text
If ZIN-Iteration exists on parent ticket, BlueBook child lookup and synchronization must include ZIN-Iteration.
```

---

## 10. StateBook Must Compare Iteration

StateBookReader also needs to be iteration-aware.

For incident loopback:

```text
Parent Stage = diagnose
Parent ZIN-Iteration = 2
```

StateBook must not treat previous `diagnose` completion from iteration 1 as current completion.

Required rule:

```text
If ZIN-Iteration exists, StateBook stage completion / transition checks must consider current iteration.
```

---

## 11. Incident Verify Failed Logic

For Incident verification, add special handling.

If verification outcome is failed, not resolved, partially resolved, worsened, or cannot verify:

```text
Verification failed
→ increment parent ZIN-Iteration
→ set parent stage/state back to diagnose
→ trigger StateBookReader / BlueBookReader again
→ create new Diagnosis child tickets for next iteration
```

Example:

```text
Current parent:
ZIN-Iteration = 1
Stage = verify

User submits:
VerificationOutcome = Not Resolved

System updates parent:
ZIN-Iteration = 2
Stage = diagnose
```

This is not ticket reset. This is controlled incident loopback.

---

## 12. Incident-Specific Verify Action

Existing verify action may be too generic for Service Request / Change.

Add or customize verify action for Incident ticket type.

Behavior:

```text
If parent TicketType = Incident
AND VerificationOutcome != Resolved
→ increment ZIN-Iteration
→ set Stage = diagnose
→ trigger orchestration again
```

If resolved:

```text
VerificationOutcome = Resolved
→ proceed to closure
→ final resolution copied from last successful resolve task
```

Recommended verify outcomes:

```text
Resolved
Partially Resolved
Not Resolved
Worsened
Cannot Verify
```

Loopback outcomes:

```text
Partially Resolved
Not Resolved
Worsened
Cannot Verify
```

Closure outcome:

```text
Resolved
```

---

## 13. Final Resolution Rule

For incident closure, parent final resolution should come from:

```text
latest successful verified resolution iteration
```

Rule:

```text
Final Resolution = resolution from last iteration where verification outcome = Resolved
```

Earlier attempts remain evidence only.

---

## 14. SLA V1 Rule

Incident SLA calculation should remain simple for the first version.

Parent Incident SLA:

```text
Incident Created Time
→ Final Verified Resolved Time
```

Severity determines SLA target.

```text
Severity → SLA Target
Actual Duration → compare against SLA Target
```

If SLA fails:

```text
SLA Justification Owner = last verified resolving team
```

This team is not automatically blamed. They become the explanation owner because their action finally restored the service.

Earlier diagnosis / routing / failed attempts remain evidence for IPC review.

---

## 15. Minimal Implementation Order

### Step 1 — Data Model

Parent Incident fields:

```text
ZIN-Observed
ZIN-ErrorMessage
ZIN-AffectedCI
ZIN-Iteration
```

Diagnosis child fields:

```text
ZIN-Diagnosis
ZIN-Outcome
ZIN-Plan
ZIN-Summary
ZIN-Iteration
```

Downstream linkage fields:

```text
ZIN-SourceDiagnosisTicketID
ZIN-SourceDiagnosisIteration
ZIN-SourceDiagnosisOutcome
```

Add ticket type:

```text
Diagnosis
```

Add governance role:

```text
DIAGNOSE
```

### Step 2 — Diagnosis Form

When:

```text
TicketType = Diagnosis
```

render custom diagnosis form based on:

```text
release/next/ideal.jpg
```

The form should:

```text
display parent incident intake fields as read-only context
allow diagnoser to submit only diagnosis fields
write diagnosis fields to child Diagnosis ticket
```

### Step 3 — Parent Incident Initialization

When parent Incident is created:

```text
ZIN-Iteration = 1
```

### Step 4 — BlueBook Iteration Awareness

Update child lookup / duplicate prevention / synchronization to include `ZIN-Iteration` when present.

### Step 5 — StateBook Iteration Awareness

Update stage completion / transition logic to include `ZIN-Iteration` when present.

### Step 6 — Diagnosis Result Aggregation and Expansion

When diagnosis children complete, pull all diagnosis children for:

```text
ParentTicketID
Current ZIN-Iteration
TicketType = Diagnosis
```

Filter out:

```text
Not Applicable
Recovered
```

For remaining actionable diagnosis results:

```text
generate one downstream task per actionable Diagnosis child
copy source Diagnosis OwnerGroup into generated task OwnerGroup
copy source Diagnosis linkage fields
avoid duplicate task creation using iteration + source diagnosis key
```

### Step 7 — Incident Verify Failed Loopback

For incident verification failure:

```text
increment ZIN-Iteration
set Stage = diagnose
trigger orchestration again
```

---

## 16. Do Not Break Existing SR / Change

Iteration must be backward-compatible.

```text
If ZIN-Iteration is missing:
    existing behavior remains unchanged

If ZIN-Iteration exists:
    include it in BlueBook / StateBook runtime comparison
```

---

## Final Design Principle

```text
Incident is loop-capable.
Requester observation stays on the parent Incident ticket.
Diagnoser input stays on child Diagnosis tickets.
Each failed verification creates a new investigation iteration.
Each iteration creates new child tickets.
Previous child tickets remain evidence.
BlueBook and StateBook must be iteration-aware.
Diagnosis is a first-class ticket type with GovernanceRole = DIAGNOSE.
Actionable diagnosis count drives downstream task count.
Source Diagnosis OwnerGroup drives downstream task OwnerGroup.
```

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Parsed records TicketID=214 BlueBook=165 Count=2 FirstBlueLevel=1

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 590
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Evaluate record spawn TicketID=214 BlueBook=165 BlueLevel=1 Chapter=BR-001 Profile=59 Role=13 Type=Diagnosis Activity=Cloud Healthcheck & Diagnosis

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 628
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

Odd number of elements in hash assignment at /opt/otobo/bin/psgi-bin/../../Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm line 341.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Support profile owner group resolution TicketID=214 ChildTicketID=215 Profile=59 OwnerGroup=59

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 724
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

Odd number of elements in hash assignment at /opt/otobo/bin/psgi-bin/../../Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm line 741.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: Evaluate record spawn TicketID=214 BlueBook=165 BlueLevel=1 Chapter=BR-002 Profile=58 Role=13 Type=Diagnosis Activity=Network Healthcheck & Diagnosis

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 628
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

Odd number of elements in hash assignment at /opt/otobo/bin/psgi-bin/../../Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm line 341.
DBD::mysql::db do failed: Duplicate entry 'ZT6b18f4bf16a871a564821783498426' for key 'ticket_number_counter_uid' at /opt/otobo/bin/psgi-bin/../../Kernel/System/DB.pm line 621.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: Duplicate entry 'ZT6b18f4bf16a871a564821783498426' for key 'ticket_number_counter_uid', SQL: '
            INSERT INTO ticket_number_counter
                (counter, counter_uid, create_time)
            VALUES
                (0, ?, ?)'

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::Ticket::Number::TESSERAIdentity::_ScopedTicketNumberCounterAdd Line: 316
   Module: Kernel::System::Ticket::Number::TESSERAIdentity::TicketNumberBuild Line: 57
   Module: Kernel::System::Ticket::NumberBase::TicketCreateNumber Line: 399
   Module: Kernel::System::Ticket::TicketCreateNumber Line: 280
   Module: Kernel::System::Ticket::TicketCreate Line: 587
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 685
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

DBD::mysql::db do failed: Column 'tn' cannot be null at /opt/otobo/bin/psgi-bin/../../Kernel/System/DB.pm line 621.
ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: Column 'tn' cannot be null, SQL: '
            INSERT INTO ticket (tn, title, type_id, queue_id, ticket_lock_id,
                user_id, responsible_user_id, ticket_priority_id, ticket_state_id,
                escalation_time, escalation_update_time, escalation_response_time,
                escalation_solution_time, timeout, service_id, sla_id, until_time,
                archive_flag, create_time, create_by, change_time, change_by)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, ?, ?, 0, ?,
                '2026-07-08 08:13:46', ?, '2026-07-08 08:13:46', ?)'

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::Ticket::TicketCreate Line: 619
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 685
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: TicketCreate failed ParentTicketID=214 BlueBook=165 BlueLevel=1 Chapter=BR-002 Type=Diagnosis RawType=493 Queue=IPC

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 701
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20

ERROR: OTOBO-CGI-25 Perl: 5.38.2 OS: linux Time: Wed Jul  8 08:13:46 2026

 Message: ZTSMBlueBookReader: BlueBook orchestration started TicketID=214 BlueBook=165 BlueLevel=1 Created=1

 RemoteAddress: 127.0.0.1
 RequestURI: /

 Traceback (6482):
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader::Run Line: 832
   Module: Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader::Run Line: 727
   Module: Kernel::System::ProcessManagement::Process::ProcessTransition Line: 585
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 125
   Module: Kernel::System::Ticket::Event::TicketProcessTransitions::Run Line: 158
   Module: (eval) Line: 289
   Module: Kernel::System::EventHandler::EventHandler Line: 283
   Module: Kernel::System::EventHandler::EventHandlerTransaction Line: 380
   Module: Kernel::System::ObjectManager::ObjectEventsHandle Line: 461
   Module: Kernel::System::ObjectManager::ObjectsDiscard Line: 509
   Module: Kernel::System::ObjectManager::DESTROY Line: 679
   Module: (eval) Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 722
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 159
   Module: Plack::Sandbox::_2fopt_2fotobo_2fbin_2fpsgi_2dbin_2fotobo_2epsgi::__ANON__ Line: 145
   Module: Plack::Middleware::HTTPExceptions::try {...}  Line: 20
# TESSERA English YAML Script Engine Next Increment

- Add `MELTObject` as a native `SEARCH FOR` object type when MELT is installed, while retaining fail-closed behavior when it is absent.
- Add class-definition-backed authoring validation so every `WHERE` and `RETURN FIELD` name is verified against the selected exported class before execution.
- Make reference comparisons object-aware. For example, authored `ZTicket-Parent EQUALS CURRENT TICKET` must compare Ticket references semantically; scripts must not expose or require `TICKET.TicketID` merely because the Ticket reference driver persists an internal identifier.
- Use `TicketType` as the canonical TESSERA ticket property in authored scripts. The ScriptEngine adapter maps `TicketType` to OTOBO's native `Type`/`Types` APIs internally; authors must not use the backend search parameter name as if it were a TESSERA field.
- Add walkable reference paths with fixed traversal and cycle-safe recursive traversal using explicit maximum depth.
- Add bounded `FOR EACH`, collection `SELECT`, and `ALL` / `ANY` / `NONE` quantifiers without permitting unrestricted writes inside iteration.
- Add declared inputs, local `STATIC`/runtime variables, typed collections, and return-type verification against the actual returned object class.
- Add a future-safe `CALL` capability for registered external connectors. Define connector manifests, typed request/response schemas, authentication references, permission scopes, timeouts, retry/idempotency rules, secret redaction, audit evidence, and fail-closed error results before enabling any external endpoint.
- Keep `CALL` declarative and allowlisted; scripts must never supply arbitrary URLs, credentials, Perl, SQL, shell commands, or dynamically selected runtime modules.
- Migrate the remaining permission consumers behind the synchronous ScriptEngine-backed GovernanceRole resolver. GenericAgent and TransitionAction RoleDirector now share its typed return contract.
- Generalize the implemented bounded evidence-assignment operation into composable `FOR EACH` and collection `SELECT` grammar. Preserve the 0.0.4 behavior for semantic parent references, current/previous/empty iteration selection, typed assignment DTOs, and deduplication.
- Extend the implemented simple Control cycle frequencies with calendar ranges, named business calendars, calendar-exact month/year arithmetic, and explicit timezone semantics.
- Add catalog-name-to-score mappings without exposing GeneralCatalog IDs in authored policy or evidence.
- Add YAML parser diagnostics with source line/column and authoring-time validation on GovernanceRole and ControlObjective save.
- Extend failure field-assignment authoring with line/column diagnostics and richer calculated-value functions while retaining explicit `ZRM-CreateRisk` gating.
- Add focused automated tests for native backend permissions, invalid class fields, temporal month-end behavior, duplicate object-name ambiguity, traversal cycles, collection coercion, and GenericAgent article deduplication.
