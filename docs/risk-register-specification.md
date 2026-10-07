Implement the **Risk Register as a derived view/filter over Risk Assessment master tickets**.

Do **not** create a new Risk Register object, ConfigItem class, persistence table, or duplicate risk record.

The authoritative record remains the **Risk Assessment master ticket**.

## 1. Eligible Service

Only master tickets under:

```text
Service = Risk::Management
```

are eligible for the Risk Register.

## 2. Core Inclusion Logic (0.0.129)

A master must have completed the required final approval before its Assessment rows can appear in the list, dashboard, matrices or export. Assessment submission, a state named `approve`, or a copied outcome/date does not establish approval.

The existing `RiskGovernanceDecision` writer determines final approval from the StateBook and BlueBooks, waits for successful approval execution in the current iteration, and writes the master `RiskAssessmentOutcome`, `ITSMDecisionDate`, and `ZTSM Risk Governance Decision <SHA256>` Misc history evidence. The register uses that recorded master decision. If capture was skipped by an older build, the same reader verifies final StateBook/BlueBook approval levels using native completion/weightage logic, successful Assessment and Approval children in the current iteration, and the actual approval closure history. It derives outcome and effective date without writing fields or history. It does not infer approval from the parent state name or create a separate approval Dynamic Field.

After approval, operationally active masters and closed accepted risks remain eligible. `ITSMDecisionDate` starts the maximum 365 elapsed-day governance window for both; expired approved records enter Review required. Missing/invalid dates on an approved decision also require review. Masters lacking verified final approval evidence remain excluded. Successful execution uses native outcome0, or a successful closure when the optional outcome is absent; value1 is neutral/no action, not success. Explicit negative or contradictory outcomes cannot establish approval. Installation does not fabricate approvals or alter snapshots.

---

## 3. Risk Outcome

Use the existing **Risk Outcome** field.

Do not create a separate field named `RiskAccepted`, `RiskAcceptance`, or equivalent merely for the Risk Register.

For example:

```text
Risk Outcome:
- Risk Accepted
- Risk Mitigated
- Risk Resolved
- No Risk
- Not Applicable
- other currently implemented outcomes
```

Use the actual configured values.

The important condition for the register is:

```text
Risk Outcome = Risk Accepted
```

A Risk Assessment ticket may therefore be closed while continuing to appear in the Risk Register.

Example:

```text
Service:       Risk::Management
StateType:     closed
Risk Outcome:  Risk Accepted
Age:           5 months
```

Result:

```text
SHOW in Risk Register
```

---

## 4. Active Risk Assessment

An assessment that has progressed beyond its initial creation/assessment stage and remains active should also appear.

Use the OTOBO **StateType** as the primary active-state discriminator wherever possible.

Conceptually:

```text
StateType <> closed
AND
State NOT IN (new, assess)
```

The reason for excluding `new` and `assess` is that these represent early assessment activity and should not yet be interpreted as an established risk being carried in the Risk Register.

Do not hardcode a complete list of all possible active workflow states if StateType can represent this reliably.

---

## 5. Maximum One-Year Risk Register Window

The active Risk Register must only represent risk within a **maximum one-year governance window**.

A risk must not remain accepted indefinitely.

Principle:

> Risk acceptance is time-bound governance approval, not permanent forgiveness of risk.

Any risk that reaches one year must be reviewed again.

Conceptually:

```text
Risk Register Window <= 1 year
```

At or before expiry:

```text
Risk Accepted
    ↓
Maximum 1 year
    ↓
Annual Review Required
    ↓
Reassess Risk
    ↓
New governance decision
```

The system must not silently continue treating an acceptance older than one year as valid.

---

## 6. Date Basis

Before implementation, identify the correct authoritative date to calculate the one-year window.

Preferred semantic meaning:

```text
Risk Governance Date
```

For an accepted risk, this should ideally correspond to the date on which the risk acceptance decision became effective.

Do not automatically assume `Ticket.Created` is always the correct acceptance-age source.

If an existing Risk Outcome Date, Decision Date, Approval Date, Acceptance Date, or equivalent authoritative timestamp already exists, use it.

If no dedicated decision timestamp exists, inspect the existing workflow and determine which existing timestamp reliably represents the governance decision before adding any new field.

The objective is:

```text
Risk Accepted Date + 1 year = Review Due Date
```

not simply:

```text
Ticket Created Date + 1 year
```

unless ticket creation genuinely represents the risk governance start date.

---

## 7. One-Year Expiry Behaviour

Once an accepted risk exceeds the approved one-year window:

```text
Risk Outcome = Risk Accepted
AND
Acceptance Age > 1 year
```

it must **not continue appearing as a normally accepted current risk**.

This condition indicates that governance action is overdue.

The system should make the risk eligible for annual reassessment / review according to the applicable Framework and workflow.

Do not automatically extend acceptance for another year.

A human/governance decision must explicitly reassess the risk.

Conceptually:

```text
Accepted Risk
    ↓
365 days reached
    ↓
Acceptance expires
    ↓
Risk Assessment / Review
    ↓
Possible outcomes:
    ├── Accept again
    ├── Mitigate
    ├── Resolve
    ├── Escalate
    └── Other governed outcome
```

A renewed acceptance should establish a new governance decision date and therefore a new maximum one-year review window.

---

## 8. Why the One-Year Rule Exists

The Risk Register should answer:

> What risk is the organization currently carrying?

It should not become a historical archive containing risks accepted years ago without reassessment.

For example:

```text
Risk accepted: 15 October 2026
Valid review window: until 14 October 2027
```

Before expiry:

```text
SHOW as current accepted risk
```

At annual review:

```text
REASSESS
```

If accepted again on:

```text
10 October 2027
```

the next review window is based on that new governance decision.

This produces a continuing governance cycle rather than permanent risk acceptance.

---

## 9. Risk Register vs Historical Risk Records

Do not delete old Risk Assessments.

The ticket remains permanent audit evidence.

Therefore distinguish:

```text
Risk Register
= current governed risk posture

Historical Risk Assessments
= complete audit history
```

A ticket dropping out of the current Risk Register does not mean its historical record is removed.

---

## 10. Master Ticket Only

The Risk Register operates on the **Risk Assessment master ticket**.

Do not independently register child tickets.

Child tickets may represent:

- assessment
- endorsement
- approval
- mitigation
- remediation
- verification
- follow-up

but they remain execution records.

The Risk Assessment master ticket remains the authoritative governance record tying together:

- risk context
- risk score
- Risk Outcome
- decision
- acceptance
- treatment
- child execution
- evidence
- audit history

---

## 11. Visibility

Risk Register visibility should follow governed relationships rather than merely native OTOBO queue membership.

A person may see an applicable Risk Assessment where they are involved as:

- Risk Owner
- approver / acceptance authority
- requester
- accountable owner
- relevant Support Profile
- relevant Support Assignment
- support participant on related child tickets
- IPC / risk governance
- other explicitly governed participant

However:

```text
Visibility != Authority
```

Being able to see an accepted risk does not give the person authority to accept, renew, or change it.

Acceptance authority must continue to be determined by the applicable Framework, Governance Role, and responsibility resolution.

---

## 12. Reusable Backend Rule

Implement the Risk Register predicate centrally where practical.

Do not independently reproduce slightly different logic in:

- portal
- backend
- dashboard
- reporting
- API

The same authoritative rule should be reusable across all presentation layers.

Conceptually:

```text
IsCurrentRiskRegisterEntry(Ticket)
```

should evaluate the business rule consistently.

---

## 13. Current Intended Predicate

Conceptually:

```text
EligibleRiskRegisterTicket =
    Service == "Risk::Management"

    AND WithinOneYearGovernanceWindow

    AND
    (
        (
            StateType != "closed"
            AND State NOT IN ("new", "assess")
        )

        OR

        RiskOutcome == "Risk Accepted"
    )
```

For accepted risks, `WithinOneYearGovernanceWindow` should preferably be calculated from the effective Risk Outcome / acceptance decision date.

Do not implement this pseudo-expression literally without first confirming the current TESSERA/OTOBO schema and workflow.

---

## 14. Architectural Principle

Keep the model simple:

```text
Risk Statement
= what the organization worries about

Risk Event
= the risk condition has occurred / exists

Risk Assessment
= governance evaluates and decides what to do with the risk

Risk Outcome
= result of that governance decision

Risk Register
= current view of risks still being carried or actively handled

Treatment Tickets
= accountable execution required to address the risk
```

The Risk Register is therefore a **derived governance view**, not another source of truth.

Final rule:

> No risk may remain accepted indefinitely. Every accepted risk must return to governance for review at least annually.