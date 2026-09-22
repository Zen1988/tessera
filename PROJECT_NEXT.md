# TESSERA Project Next Focus

## Standalone Risk Calculation Framework - Confirmed Design, Pending Implementation

- Framework is a standalone reusable governance object, not an implicitly selected ancestor
  of Policy. IM8 is the user's Policy example; calculation frameworks may address infrastructure,
  applications, suppliers or other assessment subjects.
- Policy defines requirements. ControlObjective references applicable Policies. The current
  ZRM-Policy reference is multi-value; Policy-to-Framework linkage has not been verified and
  must not be assumed to exist.
- Framework defines required inputs, likelihood/impact scales, formula or matrix, rating
  thresholds and applicable object types. No multiplication formula is assumed universally.
- Objects may attach applicable frameworks. Attachment declares applicability; PolicyEvaluation
  explicitly selects the framework to execute and maps its inputs. Do not choose a framework
  implicitly from Policy ancestry, reference ordering or the first matching attachment.
- Missing/ambiguous selected frameworks, incompatible object types and invalid inputs produce
  a calculation error rather than a guessed score. Business formulas remain authored rules.
- Preserve one asset-level Risk identity while keeping separate assessment results by framework
  and version, retaining input values, calculated results and contributing Control provenance.
  Different frameworks must not overwrite each other's scores. Any overall Risk aggregation
  requires an explicit authored rule; none is selected by this decision.
- Before implementation, validate latest SOPM/OPM and exports and map this design to existing
  classes/fields. No new class names, Dynamic Field names or executable YAML syntax are approved
  by this conceptual decision. Define framework versioning and assessment storage next.
- Once implemented and verified, move completed details to PROJECT_STATUS and remove this
  pending section in accordance with the continuity contract.


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
