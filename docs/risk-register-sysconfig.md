# Risk Register mapping

From0.0.100, configured Row columns for `ZRM-InherentCalculatedRisk` and `ZRM-ResidualCalculatedRisk` show score badges using the row's explicit `ZRM-Framework`. Framework `RiskMatrix` inclusive `ZRM-StartScore`/`ZRM-EndScore` bands resolve `ZRM-RiskSeverity` EventSeverity names and `ZTSM-ColorHex`. No fixed score bands or severity colours are used. Labels remain visible, foreground contrast adjusts, and only validated three/six-digit hex colours enter CSS. Missing Frameworks, uncovered/ambiguous bands or invalid colours render plain values. No fallback to another Framework.

Badges use the current selected Framework matrix, as stated in their tooltip; no immutable per-row matrix/version snapshot has yet been implemented. Stored scores and approval dates are not recalculated or rewritten. Excel continues to export configured cell values without badge labels or HTML. Existing column configuration and permission boundaries are preserved.

System Configuration: `TESSERA::RiskRegister::Columns`, navigation `TESSERA::RiskRegister`.

From0.0.97 this setting uses the native YAML editor. After upgrading from0.0.96, restore this setting to its default if an invalid empty-row override was saved, save and deploy. This explicit reset preserves administrator ownership; the package does not silently overwrite custom mappings.

One administrator-owned ordered mapping applies to portal columns and Excel export. Array order determines column order. Each entry has Label (heading), Source, Field (exact existing name), and optional ValueMap (display value to export value). No AI inference or scoring conversion is performed. Existing SysConfig overrides remain administrator-owned across upgrades.

Sources:
- Row: exact child Dynamic Field inside existing ZRM-RiskAssessment Set.
- Assessment: source Assessment ticket metadata or its existing Dynamic Field.
- Master: governed ServiceRequest metadata or its existing Dynamic Field.
- TargetGO: explicitly follow a Row GovernanceObject reference named Via, then read Field on that referenced Governance Object. No implicit target selection or discovery.

Supported ticket metadata: TicketNumber, Title, State, CreateTime. Master also supplies Outcome, GovernanceDate, ReviewDue, Reason. Dates are UTC. CreateTime is ticket creation, not an inferred risk-identification date. Map an actual identification-date field when your policy defines one.

Initial fields include Category, Risk Category, Statement, Detail, inherent calculated risk, Action, Plan, residual calculated risk and master lifecycle/decision dates. Configured fields must already exist. Invalid fields, unsupported sources or unresolved reference/catalog IDs block the report with an administrator-facing error rather than guessed output. A valid source with no recorded value produces an empty cell.

Example Discoverability mapping, when the row target is the Application containing the exported exposure profile:

```yaml
- Label: Discoverability
  Source: TargetGO
  Via: ZRM-RiskTargetGO
  Field: ZTSMAppSystem-ExposureProfile
  ValueMap: {}
```

Fill ValueMap with your organisation's exact display names and required export values. This example does not infer residual Discoverability from inherent Exposure. Separate residual data must have its own explicit mapping.

Rows come from the latest authorized successfully submitted Assessment in the master's exact current execution iteration, one exported row per assessment risk row. Master eligibility, expiry and permissions remain unchanged; child read permission is also required. Clicking Open Assessment opens that child. Closed assessment evidence can remain in the register while its governed master is current. Export includes the selected Current or Review view only and uses literal Excel strings, preserving leading zeros and preventing formula execution.

Initial delivery does not import arbitrary Excel templates, recalculate scores, create new assessment fields, or rewrite historical tickets. It exports a configurable ordered worksheet. Assets/CMDB permissions are not expanded.
