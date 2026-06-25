# TESSERA Project Status

Last Updated: 2026-06-25

## Current Focus

- Customer runtime execution actions on `CustomerTicketZoom`.
- Runtime stakeholder injection for active execution child tickets.
- Runtime duplication of a parent governance request for an additional external party.
- BlueBook neutral closure handling for `closed no action` and `closed duplicate`.
- Assessor Assessment task outcomes on `CustomerTicketZoom`.
- Implementer Task completion outcome handling on `CustomerTicketZoom`.
- Mandatory BlueBook outcome roll-up using `ZTicket-Outcome`.
- Follow-up/PurpleBook corrective execution from active child tickets.
- Template-driven child ticket hydration from BlueBook records.
- ZTSM first-class Template and RiskStatement governance concepts.
- Keep governance truth separate from execution evidence.

## Completed Work

## 2026-06-25 Customer Ticket Report Export And Payload Service Guard 0.0.150

### Completed work

- Added a real report export on the customer `Your Tickets` page:
  - The button is labelled `Download Report` and exports the current customer overview tab/search result, not the ticket-message service-payload template.
  - The export is generated as an `.xlsx` attachment from `CustomerTicketOverview`.
  - The report columns are: ticket number, ticket type, service, title, description, location, application, environment, state, created by, created date, customer user, `ZTicket-OwnerGroup`, `ZTicket-Owner`, and `ServicePayload`.
- The description column reads the first article body and converts rich text HTML to plain text with `HTMLUtils->ToAscii`, so the spreadsheet contains the content rather than the full rich text wrapper.
- The `ServicePayload` column is generated from the ticket's actual `ServiceID` and the service `ZService-Field` definition:
  - Only fields applicable to that service are included.
  - DynamicField Set values are exported as JSON row objects.
  - Display values are resolved through DynamicField backends where possible.
- Added a stale-service guard to the customer ticket-message payload JSON drawer:
  - Opening the JSON drawer regenerates the payload from the currently selected service and current form values.
  - The generated JSON is stamped with a service/payload signature.
  - Changing service invalidates the existing JSON.
  - Applying JSON after a service change now regenerates and blocks the apply once, forcing review before the payload can be applied to the new service.
- Synced runtime/package/overlay copies:
  - `CustomerTicketOverview.pm`
  - `CustomerTicketOverview.tt`
  - `ZTSMCustomerTicketMessageServiceFields.tt`
- Added the customer overview template to the GovernanceDB runtime overlay package file list.
- Bumped `GovernanceDB.sopm` package version to `0.0.150`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.150.opm`.
- Supersedes `0.0.149`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.150.opm`.
- `Kernel/Package/GovernanceDB-0.0.150.opm` SHA256: `BA539FAC1A10A8EA064275A9403A7E50D23C017C98389231A32B2F6BC003DFBD`.

### Validation

- `perl -I. -IKernel/cpan-lib -c Kernel\Modules\CustomerTicketOverview.pm` passed.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.150.opm` parsed successfully as XML: version `0.0.150`, `FileCount=173`, `MissingBase64=0`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- Mirrored `CustomerTicketOverview.pm` copies have matching SHA256 hash `0773DCF13570ADD80BA3313C92C2037FC2E8BC43D0ACDB445A915DE243AA658C`.
- Mirrored `CustomerTicketOverview.tt` copies have matching SHA256 hash `FB429AAB5AD1928F4B442FB606E951BDEBE6CE80A9D93578F616EAC8CA741948`.
- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `5AA280D004E4919991518DF6D16758BCF968E430C2C98404ED9C1F63F50087AF`.
- `git diff --check` passed. Git emitted CRLF-to-LF normalization warnings for `CustomerTicketOverview.pm` copies only.

### Runtime expectation

- After installing `0.0.150`, customer ticket overview should show `Download Report` beside `New Ticket`.
- Clicking `Download Report` should download an `.xlsx` report for the currently selected overview filter/search.
- On customer ticket creation, changing Service after generating payload JSON should not allow stale JSON from the previous service to be applied.

## 2026-06-25 Service Payload Hidden Validator Ignore 0.0.149

### Completed work

- Followed up the `0.0.148` runtime test where the UI theme was acceptable again but Submit still did nothing.
- Runtime console evidence showed jQuery Validate still blocking the form:
  - `[ZTSM submit click]`
  - `validatorErrors = 6`
  - `validatorPending = 0`
  - no native browser `:invalid` field.
- Root cause narrowed: OTOBO's jQuery Validate configuration ignores only `.ValidationIgnore`, not hidden fields in general. DynamicField Set template/blank hidden controls can therefore remain in the validator error list even when the visible service-payload row is correct.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Added `ZTSMServicePayloadValidationIgnoreSync()` to mark template rows and blank hidden service-payload controls as `.ValidationIgnore`.
  - The sync runs during DynamicField Set normalization and during payload submit reset.
  - Submit click now calls `ZTSMServicePayloadFormSubmitReset()` before OTOBO submit validation runs, so stale validator errors are cleared after the ignore sync.
  - Added plain JSON console output for validator details:
    - `[ZTSM submit click validator] details JSON`
    - `[ZTSM submit event validator] details JSON`
    - `[ZTSM submit after handlers validator] details JSON`
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.149`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.149.opm`.
- Supersedes `0.0.148`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.149.opm`.
- `Kernel/Package/GovernanceDB-0.0.149.opm` SHA256: `3AA0A1F4C298E06641B5989368CDF2A8F9956362FC4FF0D0FBDCC0E5DCDB7C4C`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `4945F672B595C05B7D1AB69AF71E9ACE9A24BAF9DAC886715A619883E31FC532`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.149.opm` parsed successfully as XML: version `0.0.149`, `FileCount=172`, `MissingBase64=0`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `git diff --check` passed.

### Runtime expectation

- After installing `0.0.149`, Submit should no longer be blocked by hidden/template service-payload validation errors.
- If jQuery Validate still blocks, copy the new `details JSON` console line; it now names the exact remaining fields without needing manual object expansion.

## 2026-06-25 Service Payload Validator Error Detail And Theme Rebalance 0.0.148

### Completed work

- Followed up the `0.0.147` runtime test where selected values rendered but the customer theme looked worse, and Submit still did not create a ticket.
- Runtime console evidence showed `[ZTSM submit click]` with:
  - `formClassName = Validate PreventMultipleSubmits oooSubmitted`
  - `disabledSubmits = 0`
  - `validatorErrors = 6`
  - `validatorPending = 0`
  - no native `:invalid` field.
- Interpretation: the blocker is jQuery Validate state, not browser-native required validation and not a disabled submit button.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Restored OTOBO's own selected-container behavior by marking the `InputField_Container`, its direct parent, and the parent `.Field` as `oooSelected` when payload creates/refreshes a Modernize selected chip.
  - Added the missing selected-chip left offset (`left: 24px`) so manually refreshed selected chips align like OTOBO `ShowSelectionBoxes()`.
  - Strengthened `ZTSMServicePayloadFormSubmitReset()` to call validator `resetForm()` and clear `submitted`, `invalid`, `errorList`, and `errorMap` after payload apply/import.
  - Added `validatorErrorDetails` to submit logs, including field name, id, class, value, hidden state, message, and nearby field text, so the six jQuery Validate blockers can be identified exactly if they return.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.148`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.148.opm`.
- Supersedes `0.0.147`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.148.opm`.
- `Kernel/Package/GovernanceDB-0.0.148.opm` SHA256: `3A5CF6DAF799B790A6F7A6DAF97DC5DFBCB03B2C546E80895642883D966EFD5D`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `8C7FF396A05599E0692E5CCE192B0E8120E88699EB2A3A63B50E424C1355A631`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.148.opm` parsed successfully as XML: version `0.0.148`, `FileCount=172`, `MissingBase64=0`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `git diff --check` passed.

### Runtime expectation

- After installing `0.0.148`, the selected chips should look closer to the original OTOBO customer theme again, especially top-level Location/Environment/Application and Set-row Source/Destination System controls.
- If Submit still does not create a ticket, expand `[ZTSM submit click]` or `[ZTSM submit after handlers]` and inspect `validatorErrorDetails`; that list is now the authoritative frontend blocker.

## 2026-06-25 Service Payload Submit Trace And Theme Restore 0.0.147

### Completed work

- Followed up the `0.0.146` runtime test where payload-applied firewall reference values rendered, but the customer theme looked slightly off and Submit still did not create a ticket.
- Runtime console evidence showed:
  - `[ZTSM submit click]` had no invalid field.
  - `[ZTSM submit event]` started with `defaultPrevented=false`.
  - `[ZTSM submit after handlers]` ended with `defaultPrevented=true`.
- Interpretation: browser native required validation is not the blocker; a later frontend submit handler prevents the browser event. In OTOBO this can be normal when jQuery Validate calls native `Form.submit()` itself, so the next useful trace is whether native submit is reached.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Removed the custom `ZTSMServicePayloadLabelFloated` styling so selected reference fields fall back to OTOBO customer theme rules (`oooSelected` / `oooFull`) instead of forcing label position.
  - Stopped marking parent containers as selected beyond the actual Modernize/InputField container, reducing layout drift in horizontal DynamicField Set rows.
  - Added `ZTSMServicePayloadFormSubmitReset()` after payload apply/import to clear stale `oooSubmitted` state, re-enable the form if it was left `AlreadyDisabled`, and reset jQuery Validate pending/submitted state.
  - Added native-submit tracing for `#NewCustomerTicket`: `[ZTSM native submit called]`.
  - Expanded submit diagnostics with form class, disabled submit count, validator error count, and validator pending request count.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.147`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.147.opm`.
- Supersedes `0.0.146`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.147.opm`.
- `Kernel/Package/GovernanceDB-0.0.147.opm` SHA256: `495657319CF84C93D4C5255E74892675FD26A370438D27D62DC07B2F676010AB`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `5113F72295928C5F28F1DF13FB5D24F31981639AF4A00B68F2A5798DE35011E4`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.147.opm` parsed successfully as XML: version `0.0.147`, `FileCount=172`, `MissingBase64=0`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `git diff --check` passed.

### Runtime expectation

- After installing `0.0.147`, payload-applied custom reference values should keep the selected value visible without the extra label/theme offset introduced by `0.0.146`.
- If Submit still does not navigate/create a ticket, check whether the console shows `[ZTSM native submit called]`:
  - If it appears, frontend validation handed off and the next blocker is server/runtime side.
  - If it does not appear, jQuery Validate did not invoke native submit and the expanded `[ZTSM submit click]` details should identify stale disabled/validator state.

## 2026-06-25 Service Payload Custom Reference Widget Trace 0.0.146

### Completed work

- Fixed the next customer service payload JSON apply issue for custom-created reference/search controls inside DynamicField Set rows, especially `ZFirewall-SrcSystem` and `ZFirewall-DstSystem`.
- Root cause: the previous visible refresh treated all reference widgets like the same Modernize selected-chip control. OTOBO select-backed `InputFields` render selected chips inside `.InputField_InputContainer`, not directly under `.InputField_Container`; autocomplete-backed DynamicFieldReference controls use `Core.Agent.DynamicFieldReferenceSearch.AddTicketReference()` to set the visible input and hidden key, and do not create a selected chip.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Select-backed references now rebuild the selected chip inside `.InputField_InputContainer`, matching OTOBO's own `ShowSelectionBoxes()` DOM shape.
  - Autocomplete-backed references now preserve the real visible input value, mark the widget selected/full, float the field label, and remove stale manually-created selected chips.
  - Submit tracing now logs `[ZTSM submit click]`, `[ZTSM submit event]`, `[ZTSM submit after handlers]`, and `[ZTSM submit invalid]` so runtime testing can distinguish native required-field blocking from later submit-handler cancellation.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.146`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.146.opm`.
- Supersedes `0.0.145`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.146.opm`.
- `Kernel/Package/GovernanceDB-0.0.146.opm` SHA256: `F121180977E924C6983C235EA1C6201B652C4E90D456A9BFCF3B18E90F734310`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `0F1DB07D1B76A90D8D52A56E66D0952ABFCECEF42076DE94D8DEF683DD3A69EA`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.146.opm` parsed successfully as XML: version `0.0.146`, `FileCount=172`, `MissingBase64=0`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `git diff --check` passed.

### Runtime expectation

- After installing `0.0.146`, payload-applied source/destination custom reference fields should show selected values in the normal visible layer rather than tucked behind the placeholder/label.
- If Submit still appears to click without ticket creation, browser console should now show whether the blocker is a specific invalid field or a later handler preventing submit.

## 2026-06-25 Service Payload Modernize Layout Preserve 0.0.145

### Completed work

- Fixed the regression where payload-applied Modernize/InputField selections appeared selected but visually tucked behind the field label/placeholder, and submit still failed after payload apply.
- Root cause: `0.0.143` introduced a manual selected-chip refresh that also set `.InputField_InputContainer.style.display = 'none'`. That overrode the Modernize widget's own layout state, causing the selected text to render in the wrong layer and potentially leaving the field in a validation-unfriendly state.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Removed the manual hiding of `.InputField_InputContainer`.
  - Kept the real autocomplete/search input populated for autocomplete-backed reference fields.
  - Kept the selected-chip text refresh, but positions newly created `.InputField_Selection` with the same `left: 24px` shape seen in the runtime Modernize DOM.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.145`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.145.opm`.
- Removed the superseded `Kernel/Package/GovernanceDB-0.0.144.opm` artifact.
- Supersedes `0.0.144`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.145.opm`.
- `Kernel/Package/GovernanceDB-0.0.145.opm` SHA256: `A4AC11566EF84EF0F4F255969CAC88295E4DA8A641517C9DD8DD3572FE5CA01F`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `AB8CB58A8E25610C3D306F40F7E058A9F3043CC9D1E0E55701650FB7AFE9853F`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.145.opm` parsed successfully as XML: version `0.0.145`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime expectation

- After installing `0.0.145`, payload-applied Location, Environment, Application, and firewall reference fields should render selected values in the normal Modernize selected-chip layer rather than behind labels/placeholders.
- Submit should no longer be blocked by the previous hidden-input-container mutation.

## 2026-06-25 Service Payload Autocomplete Required Value Preserve 0.0.144

### Completed work

- Fixed the follow-up submit symptom after applying service payload JSON:
  - The submit button visibly clicked, but no submit/navigation happened.
  - The likely affected fields were autocomplete-style reference controls such as `ZFirewall-SrcSystem`.
- Root cause: the shared Modernize/InputField display refresh in `0.0.143` correctly created/updated the selected chip for previously empty autocomplete reference fields, but it also cleared `.InputField_Search`. For autocomplete reference controls, that search input is the actual visible required input that `ZTSMServicePayloadReferenceSet()` had just populated with the selected label. Clearing it could leave `Validate_Required` empty, so browser/OTOBO validation could block submit without an obvious payload-layer click problem.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Modernize reference refresh still clears separate helper search inputs for select-backed fields.
  - It no longer clears the same autocomplete input element that was just populated with the selected label.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.144`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.144.opm`.
- Removed the superseded `Kernel/Package/GovernanceDB-0.0.143.opm` artifact.
- Supersedes `0.0.143`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.144.opm`.
- `Kernel/Package/GovernanceDB-0.0.144.opm` SHA256: `1D5674CA0760B84F24F49BC69F4FB73484CE20E7F7E4C8EC7F89063C8D695DB6`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `AF79EFF911BEFBFEF891EFF122C6484F5B81ED7F7BF48A2D6052DEB854D009D3`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.144.opm` parsed successfully as XML: version `0.0.144`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime expectation

- After installing `0.0.144`, applying JSON with `"ZFirewall-SrcSystem": "Application: ICA-ADFS"` should keep the actual autocomplete input value populated while also showing the selected chip/text.
- The submit button should no longer appear to click without submitting due to this required autocomplete value being cleared.

## 2026-06-25 Service Payload Drawer Close And Empty Reference Refresh 0.0.143

### Completed work

- Fixed two runtime issues found while applying customer service payload JSON:
  - After applying JSON, the submit button appeared visible but remained unclickable while the JSON editor drawer/tool layer was still open.
  - Reference fields that were previously empty, such as `ZFirewall-SrcSystem`, received the resolved value internally but did not update the visible Modernize/InputField UI.
- Root cause:
  - The JSON apply handler left the fixed payload drawer open after successful apply/import, so the tool surface could continue intercepting page interaction or focus.
  - The Modernize display refresh added in `0.0.141` handled hidden selects, but autocomplete-style reference inputs use `ZTSMServicePayloadReferenceSet()` and need the same visible selected-chip refresh when moving from empty to selected.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Successful JSON apply now closes the drawer, blurs the JSON textarea, and returns focus to the payload JSON button.
  - Successful spreadsheet/CSV import also closes the drawer and returns focus.
  - Added a shared Modernize/InputField selected-value refresh for both select-backed and autocomplete-backed reference controls.
  - The refresh creates the missing `.InputField_Selection`, `.Text`, and remove-button structure when a field was previously empty.
  - Programmatic payload changes now skip synthetic `input` events for all Modernize/InputField widgets, not just hidden selects, while still dispatching `change`.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.143`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.143.opm`.
- Removed the superseded `Kernel/Package/GovernanceDB-0.0.142.opm` artifact.
- Supersedes `0.0.142`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.143.opm`.
- `Kernel/Package/GovernanceDB-0.0.143.opm` SHA256: `70AEAC590220B33E3A728FEE11801BD9B229FD31FCB6558C15032A22C23129FB`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `A60A103553CEF464F5E4FD51686748C23C4230AFC0399B6C8E1C2167029C5BEF`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.143.opm` parsed successfully as XML: version `0.0.143`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime expectation

- After installing `0.0.143`, applying JSON should close the JSON drawer automatically and leave the real form submit button clickable.
- Applying `"ZFirewall-SrcSystem": "Application: ICA-ADFS"` to an empty source-system reference field should update both the hidden/reference value and the visible selected chip/text.
- Existing Location/Application changes should continue to show ICAB/ICA-ADFS after apply.

## 2026-06-25 Service Payload Autocomplete Submit Guard 0.0.142

### Completed work

- Fixed the submit-blocking browser error observed after service payload JSON apply:
  - `Uncaught TypeError: Cannot read properties of undefined (reading 'replace')`
  - Stack was inside `Core.UI.Autocomplete.$.ui.autocomplete._renderItem`.
- Runtime evidence showed JSON apply had finished and logged date-field apply entries before the shared autocomplete renderer failed.
- Root cause: the payload apply path was now correctly injecting/selecting resolved reference options and refreshing the Modernize display, but Modernize/autocomplete can later inspect rendered/injected select options during submit or focus handling. Injected options need the same readable label metadata that the renderer expects, and hidden Modernize selects do not need an extra synthetic `input` event after their value is changed.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Resolved reference options now carry `label`, `title`, `data-label`, and `data-value` metadata in addition to native option text/value.
  - The service payload event helper still dispatches `change`, but skips the synthetic `input` event for Modernize-backed select controls.
  - The Modernize display refresh still runs before and after the change event.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.142`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.142.opm`.
- Removed the superseded `Kernel/Package/GovernanceDB-0.0.141.opm` artifact.
- Supersedes `0.0.141`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.142.opm`.
- `Kernel/Package/GovernanceDB-0.0.142.opm` SHA256: `84197A3B86FC13AC9EA4C3A7102A265FF4ED026D2868368EA3DD1A04F0F74602`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `2F239FF28B39A3CC05D11AE56A18BD5FBC5C69B96653E9CFF62873635072C122`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.142.opm` parsed successfully as XML: version `0.0.142`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime expectation

- After installing `0.0.142`, applying the same JSON should still update Location/Application visible values and should no longer leave the page in a state where submit triggers the shared autocomplete `_renderItem` `replace` error.
- If a console error remains, capture the expanded first failing autocomplete item/source if possible; the next likely fix would be to align the injected option metadata with the exact field names expected by the deployed `CommonJS` autocomplete build.

## 2026-06-25 Service Payload Modernized Select Display Refresh 0.0.141

### Completed work

- Fixed the remaining customer service payload JSON apply display issue after runtime evidence showed the hidden native selects were correct but the visible Modernize/InputField display stayed stale:
  - `ZTicket-Application` console showed `nativeValue=2`, `matchedValue=2`, and `selectedOptions[0].text=Application: ICA-ADFS`.
  - `ZTicket-Location` console showed the resolved ICAB option selected on the native select/template control.
  - Browser DOM still rendered `.InputField_Container.oooSelected .InputField_Selection .Text` as the old value, such as `Application: Integrated Clearance System` or `Location: LDC`.
- Root cause: JSON apply updated the real hidden `<select>` value, but the Modernize/InputField rendered div beside it is not automatically refreshed by the browser after programmatic select changes.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Added a focused Modernize select display refresh helper for the existing hidden-select plus `.InputField_Container` DOM shape.
  - Refresh now updates `.InputField_Selection .Text`, clears the search input, keeps `oooSelected`, and updates the remove-button aria label.
  - Refresh runs when service payload apply sets a select value and again after the existing change/input event dispatch.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.141`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.141.opm`.
- Removed the superseded `Kernel/Package/GovernanceDB-0.0.140.opm` artifact.
- Supersedes `0.0.140`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.141.opm`.
- `Kernel/Package/GovernanceDB-0.0.141.opm` SHA256: `25C257146D1231F67BC2E59A97B57948B4065887A1AD9C0BD5E26C811FE8F7D6`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `EE83A8C22140F2EB2512A700138C70CD7D93B41C39222C399370DE08A0D83468`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.141.opm` parsed successfully as XML: version `0.0.141`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime expectation

- After installing `0.0.141`, applying JSON that changes `ZTicket-Location` to `Location: ICAB` and `ZTicket-Application` to `Application: ICA-ADFS` should update both:
  - the hidden native select value and selected option
  - the visible `.InputField_Selection .Text` chip/div shown to the requester
- Browser console should still show `[ZTSM payload apply] ...` entries with the resolved native value, while the form itself should visibly change from LDC/Integrated Clearance System to ICAB/ICA-ADFS.

## 2026-06-25 Service Payload Reference Select Apply Fix 0.0.140

### Completed work

- Fixed the next customer service payload JSON apply issue after browser-console evidence showed `ZTicket-Application` is rendered as a `DynamicFieldReference` `select-one` control with numeric option keys:
  - `tagName=SELECT`
  - `type=select-one`
  - `id=DynamicField_ZTicket-Application`
  - `name=DynamicField_ZTicket-Application`
  - `nativeValue=1`
  - `selectedOptions[0].text=Application: Integrated Clearance System`
- Root cause: JSON apply only matched select-one values against the currently loaded option list. When JSON requested a reference label such as `Application: ICA-ADFS`, the raw text was not a valid numeric option key, so the browser kept the old selected key and the visible chip stayed on the previous application.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Added a select-one reference resolver path for `DynamicFieldReference` controls.
  - Reused `CustomerTicketMessage;Subaction=ZTSMServicePayloadReferenceResolve` for non-autocomplete reference selects.
  - Ensured the resolved reference option exists in the native select before selecting it.
  - Applied the resolved object key to the real select control and fired the existing change/input events.
  - Kept `[ZTSM payload apply] ...` console diagnostics so runtime testing can confirm requested label, matched key, native value, and selected option.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.140`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.140.opm`.
- Removed the superseded `Kernel/Package/GovernanceDB-0.0.139.opm` artifact.
- Supersedes `0.0.139`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.140.opm`.
- `Kernel/Package/GovernanceDB-0.0.140.opm` SHA256: `E7D2DE38D2CD5A5252A54AD18DAAF0107E39E8A7FDCA08D346FE3FDE09512B06`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `EB1B998869E7293634DEAD5246822B75ED9DC8449250794DD9CE93D1B932AF33`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.140.opm` parsed successfully as XML: version `0.0.140`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime expectation

- After installing `0.0.140`, applying JSON such as `"ZTicket-Application": "Application: ICA-ADFS"` should resolve the label to the reference object's numeric key, update the native select, and show the ICA-ADFS chip/rendered selection.
- Browser console should show `[ZTSM payload apply] ZTicket-Application` with `requestedValue=Application: ICA-ADFS`, `matchedValue=<resolved object key>`, and `selectedOptions[0].text=Application: ICA-ADFS`.
- If a requested reference value is not allowed by the current form constraints, console should show `[ZTSM payload apply] reference select resolve failed ZTicket-Application` with the resolver response for troubleshooting.

## 2026-06-25 Service Payload Repeated Select-One Collection Fix 0.0.139

### Completed work

- Fixed the remaining customer service payload JSON issue for `ZTicket-Location` after browser-console evidence showed Location is rendered as repeated `select-one` controls, not as a native multiselect:
  - `tagName=SELECT`
  - `type=select-one`
  - `id=DynamicField_ZTicket-Location_0`
  - `name=DynamicField_ZTicket-Location`
  - `multiple=false`
  - `nativeValue=22`
  - `selectedOptions[0].text=Location: LDC`
  - `outputValue=Location: LDC`
- Root cause: JSON collection assigned `Payload[SetName] = Value` for every control in a field container. Repeated Dynamic Field controls and template/blank siblings could overwrite the valid selected value with blank.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Added payload value empty/merge helpers.
  - Non-Set field collection now merges repeated non-empty values instead of overwriting.
  - DynamicField Set row collection now uses the same merge behavior for repeated inner controls.
  - JSON apply now maps array payload values back to repeated non-multiple controls by index, while preserving the existing native multiselect apply path.
  - Kept browser-console diagnostics from `0.0.138` so runtime evidence remains available if another field shape appears.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.139`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.139.opm`.
- Removed the superseded diagnostic-only `Kernel/Package/GovernanceDB-0.0.138.opm` artifact.
- Supersedes `0.0.138`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.139.opm`.
- `Kernel/Package/GovernanceDB-0.0.139.opm` SHA256: `A45AD0571B7F4A6C42A5CBBB0BE0E278B9C43E52217BED394779F7231F44C9D5`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `EADBE8F27960D62B2637DE0013768FAB1D1EABB35678D9C098ADA6E0F128A213`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.139.opm` parsed successfully as XML: version `0.0.139`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime expectation

- After installing `0.0.139`, JSON/code view should export selected Location from `selectedOptions[0].text` rather than blank.
- For a single selected Location, JSON may emit `"ZTicket-Location": "Location: LDC"`.
- For multiple repeated Location rows, JSON should emit an array such as `"ZTicket-Location": ["Location: LDC", "Location: ICAB"]`.
- Applying the JSON array should write values back to repeated `DynamicField_ZTicket-Location_*` controls by row index.

## 2026-06-25 Service Payload Multiselect Console Diagnostics 0.0.138

### Completed work

- Added targeted browser-console diagnostics for the customer service payload JSON collector after runtime testing still showed visible Location chips but JSON emitted `"ZTicket-Location": ""`.
- Extended `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Payload collection now logs one `[ZTSM payload collect] ...` console entry per collected service field.
  - Each log includes the field output value, element tag/type/name/id/classes, native value, selected options, jQuery value, Select2 data, rendered chip values, and nearby field text.
  - Rendered chip fallback now searches the surrounding `.FieldCell`, `.Row_DynamicField`, and `.ZTSMServiceExtensionField`, not only the select sibling/parent.
  - Empty non-select controls now also try rendered chip values before returning blank, because the runtime symptom suggests the collector may be handed an empty backing control while the visible chip is elsewhere.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.138`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.138.opm`.
- Removed the intermediate unrecorded `Kernel/Package/GovernanceDB-0.0.137.opm` artifact so install testing has one clear package.
- Supersedes `0.0.136`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.138.opm`.
- `Kernel/Package/GovernanceDB-0.0.138.opm` SHA256: `1D688093EE40E907814EA3CF06F50FBBE6E743BD40666DD0A2DE7EC4FAB6A7F7`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `308C7EBA5B4551200F5B3281DF02D67C9215234BBC3396DBBE8BCAA9B853C1BB`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.138.opm` parsed successfully as XML: version `0.0.138`, `FileCount=172`, `MissingBase64=0`.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Runtime troubleshooting steps

- Install/upgrade `0.0.138`, restart PSGI/web workers, hard-refresh the browser.
- Open browser dev tools Console before clicking the service payload JSON/code button.
- Click JSON/code and inspect `[ZTSM payload collect] ZTicket-Location`.
- The important console fields are:
  - `outputValue`
  - `tagName`, `type`, `name`, `id`, `className`
  - `nativeValue`
  - `selectedOptions`
  - `jqueryValue`
  - `select2Data`
  - `renderedValues`
  - `fieldText`
- If `fieldText` contains `Location: LDC` but `renderedValues` is empty, the selected chip is rendered outside the searched field containers and the next fix should use the exact container shown in the console evidence.
- If `renderedValues` contains `Location: LDC` but `outputValue` is still blank, the fallback return path is not being reached for the actual collected control.

## 2026-06-25 Service Payload Multiselect JSON Apply Fix 0.0.136

### Completed work

- Fixed customer service payload JSON/template handling for multiselect fields such as `ZTicket-Location`.
- Root cause: `ZTSMServicePayloadInputSet()` treated every `<select>` as a single-value control. For multiselects, JSON apply could update the displayed Select2 text while leaving the real selected option state empty, so submit-time validation still treated Location as missing.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Multiselect JSON export now emits arrays of selected display names instead of a comma-joined string or `-`.
  - Multiselect apply now accepts JSON arrays and comma/newline/semicolon-separated text.
  - Display labels such as `Location: LDC` are normalized to `LDC` before matching visible options.
  - Apply sets the real native selected options, updates jQuery/Select2 value state when present, and fires change/input events.
  - JSON export falls back to Select2 displayed data if the native selected-option state is stale.
- Synced the template across live source, package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.136`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.136.opm`.
- Supersedes `0.0.135`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.136.opm`.
- `Kernel/Package/GovernanceDB-0.0.136.opm` SHA256: `FD55F877F6E6F02A3E8EF25033F9194DAA0A8781F58E31D6160289DF90ED8F56`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `F7D67B110253D0FD6D8FE40F28F757FD9664733C1A9304497643F45D04C5D9D8`.
- `GovernanceDB.sopm` and `Kernel/Package/GovernanceDB-0.0.136.opm` parsed successfully as XML: version `0.0.136`, `FileCount=172`, `MissingBase64=0`.
- Import normalization sanity check confirmed:
  - `Location: LDC` -> `LDC`
  - `LDC` -> `LDC`
  - `-` -> blank
- `perl -I. -IKernel\cpan-lib -c Kernel\Package\GovernanceDB\Kernel\Modules\CustomerTicketMessage.pm`: syntax OK.
- `git diff --check` passed.
- Node.js is not available in this desktop runtime, so inline JavaScript parse validation could not be rerun here.

### Architectural decisions

- Service payload JSON remains a frontend prefill utility over the already rendered `ZService-Field` form. It must update the actual submitted controls, not only the Select2 display layer.
- Multiselect values should be represented as JSON arrays for correctness and readability.
- Label-prefix normalization remains accepted for operator-readable JSON, but stored/submitted values continue to flow through existing rendered form controls.

### Known issues / follow-up

- Runtime install/upgrade verification is needed in OTOBO using `0.0.136`.
- Retest the firewall/service request form:
  - Select `Location: LDC`, open JSON, confirm Location exports as an array containing `LDC` rather than `-`.
  - Apply JSON with `"ZTicket-Location": ["Location: LDC"]` or `["LDC"]`.
  - Submit and confirm the Location required prompt no longer appears when LDC is visibly selected.

## 2026-06-24 Governance Object Class Seed Repair 0.0.135

### Completed work

- Repaired the governance-as-code class seed after confirming the StateBook edit UI was rendering wrong field types and wrong GovernanceObject class restrictions.
- Root cause: `Kernel/Package/GovernanceDB/var/governancedb/default_classes.json` contained corrupted embedded DynamicField definitions for Governance Object classes. StateBook was only the visible failure:
  - `ZState-State` had lost its `GeneralCatalog` `Class => ZTSM::State` definition.
  - `ZState-Book` was no longer restricted to `BlueBook`.
  - Other GO class references also carried wrong or incomplete class restrictions.
- Rebuilt class DynamicField definitions from `Export/ALL_DynamicFields_2026-06-19 06_28_14.yml` and used `Export/GOID_2026-06-19.yml` plus the current class map to restore symbolic GovernanceObject `ClassIDs`.
- Restored all GO class DynamicFields in the seed, including Set inner field definitions:
  - 94 top-level class field definitions refreshed.
  - 26 embedded Set inner definitions refreshed.
- Bumped `GovernanceDB.sopm` package version to `0.0.135`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.135.opm`.
- Supersedes `0.0.134`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.135.opm`.
- `Kernel/Package/GovernanceDB-0.0.135.opm` SHA256: `E6D1FF7B1B7084E5B7B0700F113540B8BBF37792CCD37ACB288914A01D996834`.

### Validation

- `default_classes.json` parses successfully as JSON.
- StateBook seed spot-check:
  - `ZState-Seq` is `Text` with numeric validation.
  - `ZState-State` is `GeneralCatalog` with `Class => ZTSM::State`.
  - `ZState-Book` is `GovernanceObject` restricted to `ClassIDs => [BlueBook]`.
- ServiceSupportMap seed spot-check:
  - Application, Environment, Location, ServiceProfile, ApprovalModel, and StateBook references are restricted to their matching GO classes.
- BlueBook seed spot-check:
  - Profile, Role, Template, and PurpleBook Set inner references are restricted to the exported classes.
- `Kernel/Package/GovernanceDB-0.0.135.opm` parsed successfully as XML: version `0.0.135`, `FileCount=172`, `MissingBase64=0`.

### Runtime expectation

- Upgrading to `0.0.135` should repair existing DynamicField definitions through the package bootstrap `_DynamicFieldsEnsure` / `_DynamicFieldUpdateForce` path.
- StateBook edit should show `State` as a `ZTSM::State` GeneralCatalog selector and `Book` restricted to BlueBook objects, not Application objects.
- If StateBook records were saved while the wrong field definitions were active, reopen StateBook `41`, reselect the State and BlueBook rows, save, and retry submit. The previous `ZTSMStateBookReader: No usable StateBook records` symptom can persist until corrupted stored row values are corrected.

## 2026-06-24 StateBook Record Shape Diagnostics 0.0.134

### Completed work

- Added targeted diagnostics for the remaining `ZTSMStateBookReader: No usable StateBook records ...` runtime blocker.
- Clarified runtime diagnosis:
  - `ZTicket-StateBook` resolving proves the ticket has a reference to StateBook governance object `41`.
  - It does not prove the referenced StateBook object has populated `ZState-StateRecord` rows.
  - `ZTSMStateBookReader` needs the rows inside `ZState-StateRecord` to resolve lifecycle state and hand off BlueBook execution.
- Updated `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`:
  - If `ZState-StateRecord` is missing/empty, log available `DynamicField_*` keys on the loaded StateBook object.
  - If `ZState-StateRecord` exists but parses to zero usable records, log compact shape details: ref type, array count, first row keys, and scalar sample values.
- Synced `ZTSMStateBookReader.pm` across package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.134`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.134.opm`.
- Supersedes `0.0.133`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.134.opm`.
- `Kernel/Package/GovernanceDB-0.0.134.opm` SHA256: `4E33A02BC865EC3761A405348AA39B6BF718881FE1B3FEA291BC5614A60116FD`.

### Validation

- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookReader.pm`: syntax OK.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.134.opm` parsed successfully as XML: version `0.0.134`, `MissingBase64=0`.
- `ZTSMStateBookReader.pm` canonical/package/runtime-overlay/`ZTSMOverlay` copies all share SHA256 `D116BB68F8CC3D64F66E3A98FDFBE508DB12BED53D9E174B50911DA01E25D532`.

### Runtime expectation

- After upgrading to `0.0.134`, retry submit and inspect the new `ZTSMStateBookReader` error text.
- If it says `Missing ZState-StateRecord` and lists no `DynamicField_ZState-StateRecord`, StateBook object `41` has no runtime StateRecord value loaded.
- If it says `No usable StateBook records` with `StateRecords=array(...)`, use the logged first-row keys/sample values to fix the parser or the stored data shape.

## 2026-06-24 StateBook Set Array Row Parsing 0.0.133

### Completed work

- Fixed the next submit-time blocker after `0.0.132`:
  - Runtime error: `ZTSMStateBookReader: No usable StateBook records TicketID=174 StateBook=41`
- Root cause: the StateBook reader could still skip DynamicField Set rows when a row is returned as an array of Set cells rather than a single hash. In that shape, each row looks like an array containing cell hashes such as `DF => ZState-Seq`, `DF => ZState-State`, and `DF => ZState-Book`.
- Updated `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`:
  - `_RecordValue()` now accepts hash or array records.
  - `_RecordStructuredFieldValue()` recursively searches arrays as well as hashes.
  - The parse loop no longer skips array-shaped StateBook rows.
- Updated `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookResume.pm` with the same array-shaped Set row support.
- Synced both modules across package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.133`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.133.opm`.
- Supersedes `0.0.132`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.133.opm`.
- `Kernel/Package/GovernanceDB-0.0.133.opm` SHA256: `E2647364D36D69286C3C257F6500E9EF40A1804B22688062F345E8019BE41F07`.

### Validation

- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookReader.pm`: syntax OK.
- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookResume.pm`: syntax OK.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.133.opm` parsed successfully as XML: version `0.0.133`, `MissingBase64=0`.
- `ZTSMStateBookReader.pm` canonical/package/runtime-overlay/`ZTSMOverlay` copies all share SHA256 `73FE97654CEEDCC3B1A98953AEA90336B311F0504F68C61597FD75BBCA77FB3B`.
- `ZTSMStateBookResume.pm` canonical/package/runtime-overlay/`ZTSMOverlay` copies all share SHA256 `AC3E45CF3C9E0CF1B1FBFC1E89D3658A2910F42992AD2D4CAA95B8F3647032D6`.
- `git diff --check` passed.

### Runtime expectation

- After upgrading to `0.0.133`, retry customer submit.
- The `No usable StateBook records` error should stop if StateBook `41` contains Set-row data.
- Expected next checkpoint remains BlueBook handoff and child creation:
  - Notice log `ZTSM: BlueBook resolved ...`
  - Notice log `ZTSMBlueBookReader: Enter Run ...`
  - Parent article `DO-NOT-REPLY: BlueBook orchestration started.`
  - Child article `DO-NOT-REPLY: ChapterPlay initiated`.
- If the same `No usable StateBook records` error still appears, then StateBook `41` likely has no `ZState-StateRecord` values in the runtime database, and the next fix should be data/import repair rather than parser logic.

## 2026-06-24 StateBook GeneralCatalog Class Guard 0.0.132

### Completed work

- Fixed the submit-time StateBook resolver failure after `0.0.131` advanced far enough to parse StateBook rows:
  - Runtime error: `Need Class!`
  - Traceback: `Kernel::System::GeneralCatalog::ItemList` called from `ZTSMStateBookReader::_StateNameResolve`.
- Root cause: `_StateNameResolve()` called `GeneralCatalog->ItemList()` whenever the DynamicField type was `GeneralCatalog`, even when the DynamicField config did not contain `Config->{Class}`. OTOBO requires `Class`, so the submit transaction failed before BlueBook orchestration could continue.
- Updated `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`:
  - Only calls `GeneralCatalog->ItemList()` when `Config->{Class}` exists.
  - Guards `$PossibleValues` before reading candidate display values.
  - Falls back to `DynamicField::Backend->ValueLookup()` when no GeneralCatalog class is configured.
- Updated `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookResume.pm` with the same `Config->{Class}` guard.
- Synced both modules across package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.132`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.132.opm`.
- Supersedes `0.0.131`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.132.opm`.
- `Kernel/Package/GovernanceDB-0.0.132.opm` SHA256: `6813EA3753018382B1F4A123B978DE6B866A2C5D7FB7390FA85A01D566A5267D`.

### Validation

- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookReader.pm`: syntax OK.
- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookResume.pm`: syntax OK.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.132.opm` parsed successfully as XML: version `0.0.132`, `MissingBase64=0`.
- `ZTSMStateBookReader.pm` canonical/package/runtime-overlay/`ZTSMOverlay` copies all share SHA256 `BE0EA9F8564E98233EACA5EE5ADC78E7A57EC040F8CF2BEB820A5331543AE0D8`.
- `ZTSMStateBookResume.pm` canonical/package/runtime-overlay/`ZTSMOverlay` copies all share SHA256 `43965B1A7BD10BE979901EF55043A33085D95F7D086C5EA31FB9A9CC66DD9AAF`.
- `git diff --check` passed.

### Runtime expectation

- After upgrading to `0.0.132`, retry customer submit.
- The `Need Class!` error from `GeneralCatalog::ItemList` should stop.
- Expected next runtime checkpoint remains BlueBook handoff and child creation:
  - Notice log `ZTSM: BlueBook resolved ...`
  - Notice log `ZTSMBlueBookReader: Enter Run ...`
  - Parent article `DO-NOT-REPLY: BlueBook orchestration started.`
  - Child article `DO-NOT-REPLY: ChapterPlay initiated`.

## 2026-06-24 StateBook Set Row Parsing 0.0.131

### Completed work

- Fixed the no-child-spawn path after the customer submit article `DO-NOT-REPLY: Service Governance Resolved`.
- Root cause: `ZTSMStateBookReader` loaded the resolved StateBook but still expected flat record keys for `ZState-Seq`, `ZState-State`, and `ZState-Book`. Current GovernanceDB StateBook rows are stored as nested Set rows with `DF`/`Value` entries, so no usable StateBook records were parsed and BlueBook orchestration never ran.
- Added nested Set-row extraction to:
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookResume.pm`
- Added a direct error log when `ZTSMStateBookReader` loads a StateBook but parses zero usable records:
  - `ZTSMStateBookReader: No usable StateBook records TicketID=... StateBook=...`
- Synced both modules across package source, runtime overlay, and `ZTSMOverlay`.
- Bumped `GovernanceDB.sopm` package version to `0.0.131`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.131.opm`.
- Supersedes `0.0.130`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.131.opm`.
- `Kernel/Package/GovernanceDB-0.0.131.opm` SHA256: `72582FB653E6C7B94BF3B41E2AC7602A9D95FAB41725A6531733D688876180E7`.

### Validation

- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookReader.pm`: syntax OK.
- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookResume.pm`: syntax OK.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.131.opm` parsed successfully as XML: version `0.0.131`, `MissingBase64=0`.
- `ZTSMStateBookReader.pm` canonical/package/runtime-overlay/`ZTSMOverlay` copies all share SHA256 `4912E9A6143B4DFD680897A309D46EDAAC424411D0A3F080169741EA0813AE6D`.
- `ZTSMStateBookResume.pm` canonical/package/runtime-overlay/`ZTSMOverlay` copies all share SHA256 `723DFDE5169530CD4D0D6BBFA248AEC5DDE16E8C4A8DB403E66D67189B64B07A`.
- `git diff --check` passed.

### Runtime expectation

- After upgrading to `0.0.131`, retry customer submit for the same firewall service.
- Expected continuation after `DO-NOT-REPLY: Service Governance Resolved`:
  - Notice log `ZTSM: BlueBook resolved ...`
  - Notice log `ZTSMBlueBookReader: Enter Run ...`
  - Parent article `DO-NOT-REPLY: BlueBook orchestration started.`
  - Child article `DO-NOT-REPLY: ChapterPlay initiated` on the spawned execution ticket.
- If child creation still does not happen, the next useful log is now whether `ZTSMStateBookReader: No usable StateBook records ...` appears, or whether BlueBook starts but resolves no playable ChapterPlay rows.

- Added customer ZTSM runtime action `AddRequiredSupportProfile`.
- Added action visibility on active child execution tickets only:
  - Ticket Type `Assessment`
  - Ticket Type `Endorsement`
  - Ticket Type `Approval`
  - `StateType` must not be `closed`
  - Ticket must carry `ZTicket-Parent`, `ZTicket-BlueBook`, `ZTicket-BlueLevel`, and `ZTicket-Chapter`
  - Current customer user must own `ZTicket-Owner`
- Added support profile prompt using existing SupportProfile governance objects.
- Added runtime creation of an additional mandatory child execution ticket:
  - Same parent governance ticket
  - Same BlueBook
  - Same BlueLevel
  - Same chapter
  - Same execution ticket type
  - Selected support profile stored in existing `ZTicket-Profile` and `ZTicket-OwnerGroup`
  - `ZTicket-Mandatory` set to `1`
  - `ZTicket-RequiredWeightage` set to `1`
- Added duplicate protection for the same parent, BlueBook, BlueLevel, chapter, ticket type, and support profile.
- Added article snapshots on both the source child ticket and the new child ticket.
- Added customer ZTSM runtime action `CreateExternalPartyRequest`.
- Added action visibility for a separate external-party request:
  - Root governance tickets can be duplicated by the requester while `StateType` is not `closed`.
  - Active child execution tickets can trigger duplication of their parent request when the current customer user owns `ZTicket-Owner`.
  - Closed tickets do not allow the action.
- Added target service prompt for the external-party request.
- Added runtime creation of a new root governance ticket:
  - Same ticket type as the duplicated parent request, such as `ServiceRequest`.
  - Same requester, queue, priority, SLA, and copied ticket Dynamic Fields from the parent request.
  - Target service is selected in the action prompt.
  - Ticket Dynamic Fields are copied through the Dynamic Field backend so DynamicField Set values are copied as structured values.
  - Process management runtime fields are not copied, so the new ticket does not inherit the old process activity.
- Updated `ZTSMServiceLibrarian` so a ticket that already has `ZTicket-StateBook` skips ServiceSupportMap/governance resolution.
- Invoked `ZTSMServiceLibrarian` for the new external-party request after Dynamic Fields are copied.
- Added article snapshots on both the source ticket and the new external-party request ticket.
- Added BlueBook neutral closure propagation in `ZTSMChapterDirector`:
  - `closed no action` and `closed duplicate` are treated as neutral closed task outcomes.
  - If the neutral-closed task is mandatory and is the only child ticket in the same parent, BlueBook, and BlueLevel, the parent ticket is closed with the same state.
  - If other child tickets exist in the same BlueLevel, the neutral-closed task only fulfills its own participation weightage and the BlueBook continues to wait for the other tasks.
- Added assessor-owned Assessment task outcomes:
  - `Submit Assessment` closes the Assessment child as `closed successful` and uses the risk assessment workspace.
  - `Close Duplicate` closes the Assessment child as `closed duplicate`.
  - `Close No Action` closes the Assessment child as `closed no action`.
  - All three outcomes require the current customer user to own `ZTicket-Owner`.
- Added implementer-owned Task completion action:
  - Visible only for Ticket Type `Task`.
  - Current customer user must own `ZTicket-Owner`.
  - Prompts for `ZTicket-Outcome`.
  - Prompts for details and stores them in `ZTicket-Result`.
  - Allows one uploaded attachment and writes it to the generated task completion article.
  - Writes an article snapshot for every Task completion.
  - Maps Task outcome to ticket state:
    - Successful `0` -> `closed successful`
    - No Action `1` -> `closed no action`
    - Partial Success `2` -> `closed successful`
    - Failed `-1` -> `closed unsuccessful`
    - Rollback `-2` -> `closed rollback`
- Updated runtime action dialog form to support `multipart/form-data` uploads.
- Added mandatory BlueLevel outcome roll-up in `ZTSMChapterDirector`:
  - Only mandatory child tickets are considered.
  - Parent `ZTicket-Outcome` is updated from mandatory child outcomes.
  - Failed/Rollback mandatory outcomes are hard stops and close the parent as failed/rollback.
  - Partial Success writes parent `ZTicket-Outcome = 2` and allows BlueBook flow to continue.
  - Success/No Action outcomes are non-negative completion outcomes.
- Bumped `GovernanceDB.sopm` package version to `0.0.72`.
- Generated `Kernel/Package/GovernanceDB-0.0.72.opm` for upgrade testing.
- Added BlueBook record support for `ZBlue-PurpleBook` and `ZBlue-Template`.
- Added customer runtime action `Follow-up`:
  - Visible on owned active child tickets of type `Assessment`, `Endorsement`, `Approval`, `Implementation`, and `Verification`.
  - Requires the current BlueBook record to contain `ZBlue-PurpleBook`.
  - Sets the current child ticket state to `follow-up`.
  - Spawns the configured PurpleBook as child execution tickets under the current child ticket.
  - Preserves the original child ticket `ZTicket-BlueLevel` so it can still return to its original parent BlueBook level.
  - Writes a follow-up article with the acting owner and created corrective tickets.
- Added Verification completion action:
  - Visible only for owned active `Verification` tickets.
  - Prompts for success/failed result, details stored in `ZTicket-Result`, and a mandatory artifact upload.
  - Successful verification sets `ZTicket-Outcome = 0` and closes `closed successful`.
  - Failed verification starts Follow-up when `ZBlue-PurpleBook` is configured; otherwise it sets `ZTicket-Outcome = -1` and closes `closed unsuccessful`.
  - Writes a verification article and attachment.
- Updated `ZTSMChapterDirector` for PurpleBook return flow:
  - When a PurpleBook under a `follow-up` parent completes successfully, the original child ticket returns to `in-progress`.
  - When a mandatory PurpleBook task fails, existing failed-first logic closes the original child and immediately evaluates its original parent level.
- Added Template hydration during child creation in both `ZTSMBlueBookRuntime` and `ZTSMBlueBookReader`:
  - `ZBlue-Template` can be empty.
  - Template description is written to the generated child ticket as an article.
  - `ZTemplate-RiskAssessment` rows are mapped into existing `ZRM-RiskAssessment`.
  - Risk statement defaults are applied from the Risk Statement governance object where present.
  - Inherent and residual calculated risk scores are computed from likelihood and impact.
- Bumped `GovernanceDB.sopm` package version to `0.0.73`.
- Generated `Kernel/Package/GovernanceDB-0.0.73.opm` for upgrade testing.
- Synced implementation across:
  - `Kernel/Modules/CustomerTicketZTSMAction.pm`
  - `Kernel/Modules/CustomerTicketZoom.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/*`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/*`
  - `ZTSMOverlay/files/Kernel/Modules/*`
  - `Kernel/Package/GovernanceDB/Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `ZTSMOverlay/files/Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `ZTSMOverlay/files/Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm`
  - `Kernel/System/ZTSMBlueBookRuntime.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/ZTSMBlueBookRuntime.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ZTSMBlueBookRuntime.pm`
  - `ZTSMOverlay/files/Kernel/System/ZTSMBlueBookRuntime.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `ZTSMOverlay/files/Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt`
  - `ZTSMOverlay/files/Kernel/Output/HTML/Templates/Standard/CustomerTicketZoom.tt`

## Architectural Decisions

- Additional stakeholder injection is a runtime execution action, not a StateBook transition.
- Additional stakeholder injection is not BlueBook choreography; BlueBook already defines the planned sequence.
- The action is controlled by Ticket Type, not lifecycle state.
- Allowed hardcoded Ticket Types for now: `Assessment`, `Endorsement`, `Approval`.
- Future control can move to SysConfig or a governance object, but current implementation intentionally keeps the rule local and explicit.
- The action must not modify governance snapshots, lifecycle position, StateBook position, or BlueBook position.
- The additional task duplicates execution evidence only; it does not duplicate governance truth.
- Closed execution child tickets must not allow additional mandatory stakeholders, to avoid hanging a gate after work has already completed.
- Existing BlueBook level completion logic blocks progression while any child in the same parent, BlueBook, and BlueLevel remains open, so the new mandatory child naturally prevents lifecycle advancement until completed.
- External-party request creation is a separate root/governance request clone, not a child execution duplicate.
- External-party request creation goes back through ServiceLibrarian after cloning, because the selected service can represent a different vendor or party.
- If the cloned request already carries `ZTicket-StateBook`, ServiceLibrarian must treat the snapshot as already chosen and must not resolve governance again.
- Parent/request Dynamic Fields are copied through Dynamic Field backend APIs, not string-rendered values, so DynamicField Set data stays structured.
- `closed no action` and `closed duplicate` are not failure states.
- A neutral closure only propagates upward when it represents the whole mandatory BlueLevel; otherwise it behaves as completion evidence for its own child ticket.
- Assessment neutral closure is an assessor task outcome, not a requester action.
- Assessment neutral closure uses the same owner enforcement as normal Assessment submission.
- Task completion is an implementer task outcome, not a requester action.
- `ZTicket-Result` is the Task details field.
- Parent request status evidence is represented by `ZTicket-Outcome`; hard-stop negative outcomes additionally close the parent ticket state.
- Follow-up is a runtime corrective execution action, not a StateBook transition.
- PurpleBook is read from the current BlueBook record using `ZBlue-PurpleBook`; no ticket Dynamic Field was introduced for PurpleBook.
- Template is read from the current BlueBook record using `ZBlue-Template`; no ticket Dynamic Field was introduced for Template.
- PurpleBook child tickets use their PurpleBook as `ZTicket-BlueBook` and the original child ticket as `ZTicket-Parent`.
- Successful PurpleBook completion returns the original child to `in-progress`; it does not resume StateBook directly.
- Failed mandatory PurpleBook completion propagates through the original child so the original parent BlueBook receives failed-first handling.
- Template risk assessment hydration uses existing `ZRM-*` ticket fields because the current risk assessment workspace stores ticket risk rows there.
- Mandatory outcome precedence:
  - Rollback outranks Failed.
  - Failed outranks Partial Success.
  - Partial Success outranks Successful/No Action but does not stop BlueBook flow.
  - Only mandatory child tickets affect parent outcome roll-up.

## Rejected Approaches

- Do not enable by `ZState-CurrentState`; Ticket Type is the cleaner action-control layer.
- Do not make this a StateBook transition.
- Do not make this a BlueBook transition.
- Do not recalculate governance or rebuild snapshots when adding the stakeholder.
- Do not introduce new Dynamic Field names for this behavior.
- Do not allow additions on closed child tickets.
- Do not make external-party request creation a BlueBook or StateBook transition.
- Do not duplicate child execution tickets for the external-party request; create a new root request and let runtime orchestration handle it.
- Do not force ServiceSupportMap re-resolution when `ZTicket-StateBook` is already present.
- Do not treat `closed no action` or `closed duplicate` as mandatory failure.
- Do not close the parent/root ticket when other tasks exist in the same BlueBook level.
- Do not expose `closed duplicate` or `closed no action` as generic outcomes for Endorsement or Approval yet; current requirement is Assessment/Assessor only.
- Do not use Task free-text remarks as the canonical result; store Task details in `ZTicket-Result`.
- Do not let non-mandatory child outcomes drive parent outcome roll-up.
- Do not show Follow-up when the BlueBook record has no `ZBlue-PurpleBook`.
- Do not store PurpleBook or Template on new `ZTicket-*` fields.
- Do not let PurpleBook spawning overwrite the original child ticket BlueLevel.

## Known Issues / Follow-Up

- `PROJECT_STATUS.md` was empty before this update; older project memory is not present here.
- The current action hardcodes allowed Ticket Types in module defaults. Move to SysConfig or governance object control later if needed.
- Latest generated OPM is `Kernel/Package/GovernanceDB-0.0.81.opm`.
- `Kernel/Package/GovernanceDB-0.0.81.opm` SHA256: `F36B48B6BB7068B6B1D3F17ED92CF9B5CDA4A3E8793A32509DDE87F0F169E22B`.
- Runtime verification is still needed for the target service list and external-party request clone flow inside OTOBO.
- Runtime verification is still needed for sole mandatory `closed no action` / `closed duplicate` propagation.
- Runtime verification is still needed that only the Assessment owner sees and can submit `Submit Assessment`, `Close Duplicate`, and `Close No Action`.
- Runtime verification is still needed that only the Task owner sees and can submit `Complete Task`.
- Runtime verification is still needed for Task attachment upload into the generated article.
- Runtime verification is still needed for parent `ZTicket-Outcome` roll-up across mandatory BlueLevel children.
- Runtime verification is still needed for Follow-up visibility on each configured child type.
- Runtime verification is still needed for PurpleBook spawn and successful return to `in-progress`.
- Runtime verification is still needed for failed PurpleBook propagation to the original parent level.
- Runtime verification is still needed for Template hydration into `ZRM-RiskAssessment`.
- Runtime verification is still needed for Verification artifact upload and failed-with-PurpleBook behavior.

## Next Priorities

- Verify the action in an OTOBO runtime using an active `Assessment`, `Endorsement`, or `Approval` child ticket.
- Confirm SupportProfile search/list permissions in the customer portal environment.
- Verify `CreateExternalPartyRequest` from both a root requester ticket and an active child owner ticket.
- Confirm cloned DynamicField Set values render correctly on the new request.
- Verify neutral closure behavior:
  - Sole mandatory BlueLevel child closes parent with the same neutral state.
  - Multi-task BlueLevel continues until remaining tasks complete.
- Verify assessor outcome buttons on an owned Assessment ticket:
  - `Submit Assessment`
  - `Close Duplicate`
  - `Close No Action`
- Verify Task completion on an owned Task ticket:
  - Outcome dropdown from `ZTicket-Outcome`
  - Details saved to `ZTicket-Result`
  - Attachment written to the task completion article
  - Parent mandatory outcome roll-up
- Install or upgrade using `Kernel/Package/GovernanceDB-0.0.81.opm` and perform runtime verification.
- Verify Follow-up on owned `Assessment`, `Endorsement`, `Approval`, `Implementation`, and `Verification` child tickets.
- Verify an empty `ZBlue-PurpleBook` does not expose Follow-up and failed Verification closes `closed unsuccessful`.
- Verify `ZTemplate-RiskAssessment` creates multiple `ZRM-RiskAssessment` rows when the Template carries multiple risk statements.
- Consider adding SysConfig for `AddRequiredSupportProfileTypes` after the hardcoded behavior is accepted.

## 2026-06-17 Runtime Test Feedback Update

### Completed Work

- Shortened customer runtime action labels:
  - `Add Required Support Profile` now displays as `Amend`.
  - `Create External Party Request` now displays as `Clone`.
  - Assessment neutral outcomes now display as `Duplicate` and `No Action`.
- Moved Assessment neutral outcomes out of the top activity button row:
  - `Duplicate` and `No Action` are now submitted from the Risk Assessment workspace footer.
  - `Submit Assessment` remains the primary assessment submission.
- Made `InActionMenu` effective on `CustomerTicketZoom`:
  - Utility/runtime actions such as `Amend`, `Clone`, requester hold/cancel, follow-up, task completion, and verification completion can render under the header action menu instead of cluttering the main activity row.
- Changed Clone selection from service selection to direct ServiceSupportMap selection:
  - Customer selects a `ServiceSupportMap` governance object.
  - Backend reads `ZTSMServiceSupportMap-Service`, `ZTSMServiceSupportMap-Application`, `ZTSMServiceSupportMap-Environment`, `ZTSMServiceSupportMap-Location`, `ZTSMServiceSupportMap-StateBook`, and `ZTSMServiceSupportMap-ApprovalModel`.
  - New cloned parent request receives the selected service and governance snapshot fields from the selected ServiceSupportMap.
  - New clone stores `ZTicket-Parent` pointing back to the ticket where Clone was triggered.
- Changed clone field copying to skip runtime/governance execution fields:
  - Process fields, `ZState-*`, `ZBlue-*`, current StateBook/ApprovalModel, BlueBook execution fields, owner fields, outcome/result fields, hold state, and execution participation fields are not copied into the new parent request.
- Made duplicate Amend support-profile detection non-fatal:
  - Existing matching support-profile child returns success instead of showing `Could not add required support profile`.
  - Matching now considers GovernanceObjectID, LastVersionID, and Name where available.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Bumped `GovernanceDB.sopm` package version to `0.0.74`.
- Generated `Kernel/Package/GovernanceDB-0.0.74.opm` for install/upgrade testing.
- Verified generated OPM parses as XML and contains 154 embedded package files plus `CodeInstall` and `CodeUpgrade`.
- Verified Perl syntax for `CustomerTicketZTSMAction.pm` and `CustomerTicketZoom.pm`.

### Architectural Decisions

- Clone is a governance-request clone, but the requester must select the exact ServiceSupportMap rather than a generic service.
- Clone does not reuse the original request's StateBook snapshot; it writes a fresh governance snapshot from the selected ServiceSupportMap.
- Clone must not copy BlueBook execution position, owner/assignment state, process runtime fields, hold state, or child-execution fields into the new parent request.
- Assessment `Duplicate` and `No Action` are assessor-owned outcome submissions for the current assessment child, not separate top-level requester actions.
- `Amend` remains a runtime execution action that adds execution evidence only; it does not alter governance truth.

### Known Issues / Follow-Up

- Runtime verification is needed for Clone using direct ServiceSupportMap selection.
- Runtime verification is needed that cloned parent/SR/CR tickets carry `ZTicket-Parent` back to the trigger ticket and receive StateBook/ApprovalModel from the selected ServiceSupportMap.
- Runtime verification is needed that `Amend` no longer errors when the requested support profile already exists.
- Runtime verification is needed that Assessment footer buttons submit `Duplicate`, `No Action`, and `Submit Assessment` correctly.
- Local `otobo.Console.pl Dev::Package::Build --help` is still blocked because the bundled console refuses to run outside the OTOBO user context; `Kernel/Package/GovernanceDB-0.0.74.opm` was generated mechanically from the authoritative SOPM and package file list instead.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.76.opm`; install/upgrade 0.0.76 and retest the exact customer screenshots/workflows:
  - Assessment workspace footer buttons.
  - Amend support-profile creation/duplicate behavior.
  - Clone ServiceSupportMap selection and new request governance hydration.

## 2026-06-17 Template / First-Class ZTSM Update

### Completed Work

- Added `Template` as a first-class GovernanceDB class in `default_classes.json`.
- Added `RiskStatement` as a first-class GovernanceDB class in `default_classes.json`.
- Added `Reference` category to GovernanceDB defaults.
- Added `ZBlue-Template` and `ZBlue-PurpleBook` back into default `ZBlue-Record` so upgrade can repair the BlueBook DynamicField Set.
- Added full default `ZTemplate-*` DynamicField definitions for `ZTemplate-RiskAssessment`.
- Added runtime GovernanceObject resolution for Template and RiskStatement values:
  - Accepts numeric GovernanceObjectID.
  - Accepts GO number.
  - Accepts rendered labels such as `Template: Std-Fw-Assessment`.
- Made `Amend` and `Clone` visible activity-row actions again while keeping longer utility actions in the menu.
- Bumped `GovernanceDB.sopm` package version to `0.0.75`.
- Generated `Kernel/Package/GovernanceDB-0.0.75.opm` for install/upgrade testing.

### Architectural Decisions

- Template is now a ZTSM first-class governance concept, not a manually maintained local object shape.
- RiskStatement is now a ZTSM first-class governance concept used by Template risk assessment hydration.
- BlueBook records reference Template through `ZBlue-Template`; no `ZTicket-*` Template field is introduced.
- Upgrade repair is idempotent and class-name based, avoiding environment-specific class IDs from exports.

### Known Issues / Follow-Up

- Runtime verification is still needed that upgraded `ZBlue-Record` keeps `ZBlue-Template` and `ZBlue-PurpleBook`.
- Runtime verification is still needed that `Std-Fw-Assessment` hydrates all expected risk rows into `ZRM-RiskAssessment`.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.76.opm`; install/upgrade 0.0.76 instead.
- Reopen the Assessment child and confirm the template creates the expected risk rows.
- Confirm `Amend` and `Clone` are visible again after upgrade.

## 2026-06-17 Bootstrap Upgrade Repair

### Completed Work

- Repaired `Kernel/System/GovernanceDB/Bootstrap.pm` catalog seeding so `_CatalogItemEnsure` resolves existing GeneralCatalog rows through `ItemList` before attempting `ItemAdd`.
- Avoided calling `GeneralCatalog::ItemGet` for missing catalog items during bootstrap, preventing the upgrade error `Item not found in database!` and the related empty SQL `IN ()` failure.
- Kept catalog creation idempotent by re-reading after `ItemAdd` returns false, so repeated install/upgrade runs do not fail when the item already exists.
- Bumped `GovernanceDB.sopm` package version to `0.0.76`.
- Generated `Kernel/Package/GovernanceDB-0.0.76.opm`.
- `Kernel/Package/GovernanceDB-0.0.76.opm` SHA256: `4FB38F2FD1328F58BB07C28FFD10B063E2A53822050D438AF85CC2B002162F01`.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.77.opm`; install/upgrade 0.0.77 and retest bootstrap first.

## 2026-06-17 Amend / Clone Runtime Repair

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.77`.
- Repaired Amend duplicate detection so it no longer passes SupportProfile names into `ZTicket-OwnerGroup` TicketSearch reference validation; it now searches stable ticket context first and compares owner group locally.
- Guarded SupportAssignment reference searches so only numeric SupportProfile IDs are submitted to reference-field search validators.
- Repaired Clone / external-party request input handling so submitted ServiceSupportMap names are resolved to GovernanceObject IDs and Service values are resolved to Service IDs before ticket creation.
- Adjusted custom runtime dialog CSS in the CustomerTicketZoom runtime overlay so Amend and Clone fieldsets align like the assessment view.
- Repaired GovernanceObject version zoom/list status handling so missing `ZTSMStatusID` no longer calls `GeneralCatalog::ItemGet` with an empty ID.
- Passed `ConfigItemHandled` during GovernanceObject version DynamicField writes to prevent ITSM ConfigItem hooks from treating GovernanceObject version IDs as ConfigItem IDs.
- Added idempotent bootstrap seeding for GovernanceObject history types, including `AttachmentAddPost` and `AttachmentDeletePost`.
- Generated `Kernel/Package/GovernanceDB-0.0.77.opm`.
- `Kernel/Package/GovernanceDB-0.0.77.opm` SHA256: `40927AF6A4E27AF0D61BAA0CB4D5C8A3B496E8E7FEBC9DE7860C2F31B442A6EF`.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.78.opm`; install/upgrade 0.0.78 because 0.0.77 embedded base64 file content without `Encode="Base64"` and can install corrupted module files.
- Retest Amend with a SupportProfile name such as `ICA IaaS Ext ATFM Cloud Team`.
- Retest Clone with a ServiceSupportMap name such as `ICA-SSC-NETWORK-FIREWALL-ADD`.
- Retest GovernanceObject version zoom/list after upgrade to confirm history type and ConfigItem hook errors are gone.

## 2026-06-17 OPM Encoding / Template / Clone Filter Repair

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.78`.
- Rebuilt the generated OPM with `Encode="Base64"` on all 154 embedded file nodes, repairing the 0.0.77 install corruption that produced raw base64 Perl files and `Identifier too long`.
- Repaired Template risk hydration so `ZTemplate-RiskAssessment` rows can be read from both keyed row hashes and DynamicField Set row shapes using `DF` plus `Value` or `Content`.
- Updated Clone ServiceSupportMap selection to filter against the root request service, so an Assessment child only offers maps for the same parent request service.
- Added Clone backend enforcement so a submitted ServiceSupportMap whose service differs from the root request service is rejected.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.78.opm`.
- `Kernel/Package/GovernanceDB-0.0.78.opm` SHA256: `1E04DE7C78D3A9E866FE24C88314027CD934B75A727F6B542E61749DC477575F`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.78.opm`.
- If 0.0.77 already installed raw base64 files and the package manager page cannot load, the environment may need a direct 0.0.78 console/package repair path to overwrite those files.
- Retest Template hydration from `Std-Fw-Assessment`; it should create the expected multiple `ZRM-RiskAssessment` rows.
- Retest Clone ServiceSupportMap selection from an Assessment child; it should show only maps for the same root request service.
- Retest Clone ticket creation and verify the new parent request keeps `ZTicket-Parent` back to the trigger ticket.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.79.opm`; install/upgrade 0.0.79 instead.
- Retest the customer portal workflows in this order: dashboard refresh, Assessment template hydration, Clone same-service map filter, Clone creation, Amend support-profile add/duplicate behavior.

## 2026-06-17 Runtime Regression Repair 0.0.79

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.79`.
- Repaired customer dashboard workable-ticket SupportProfile lookup so it no longer searches `ZTSMSupportAssignment-UserAccount` through the DynamicField `Agent` backend; it now lists SupportAssignment objects and compares users locally.
- Repaired `ZTSMBlueBookReader` record parsing so `ZBlue-Template` is read from DynamicField Set row shapes using `DF` plus `Value` or `Content`.
- Repaired `ZTicket-Profile` ticket reference configuration so it allows both `Governance Role` and `Support Profile`.
- Hardened Clone action:
  - Submitted ServiceSupportMap labels are normalized before lookup.
  - ServiceSupportMap governance reference fields are resolved to GovernanceObject IDs before writing ticket fields.
  - Optional copied DynamicField write failures are logged and skipped instead of aborting the clone.
  - Backend same-service rejection now logs the source and selected service IDs.
- Hardened Amend action:
  - Submitted SupportProfile labels are normalized before lookup.
  - DynamicField write failures now log the exact field, ticket ID, and value.
- Synced changed files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.79.opm`.
- `Kernel/Package/GovernanceDB-0.0.79.opm` SHA256: `37FF076BF63B5924B433A996CAD87F3A540057E14C5287D631BE1DAFFD8C727D`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.79.opm`.
- Restart PSGI/web workers after upgrade if subroutine redefinition or reload warnings continue after package install.
- Retest dashboard refresh from CustomerTicketZoom back to CustomerDashboard; the previous `DynamicField::Driver::Agent` load failure should no longer be triggered by the dashboard tile.
- Retest Amend. If it still fails, the OTOBO log should now show the exact failing DynamicField/value.
- Retest Clone. If it still fails, the OTOBO log should now show whether the blocker is map lookup, service mismatch, ticket create, or governance field write.
- Retest Template hydration on a newly spawned Assessment child, because existing child tickets will not be backfilled automatically.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.80.opm`; install/upgrade 0.0.80 and restart PSGI/web workers before retesting.

## 2026-06-17 Driver Repair / Lazy Template Hydration 0.0.80

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.80`.
- Added clean `Kernel/System/DynamicField/Driver/Agent.pm` to the package file list so upgrade can overwrite a corrupted installed Agent dynamic-field backend.
- Added `Kernel::System::ZTSMBlueBookRuntime::TemplateIDForTicket`.
- Added Assessment lazy hydration:
  - When the Assessment workspace loads and `ZRM-RiskAssessment` is empty, it resolves template through `ZTicket-BlueBook`, `ZTicket-BlueLevel`, and `ZTicket-Chapter`.
  - It writes template rows back to the existing `ZRM-RiskAssessment` DynamicField Set before rendering the assessor form.
- Added template application during Amend-created duplicate child ticket creation, so additional SupportProfile children inherit the BlueBook record template.
- Hardened Template DynamicField Set parsing so wrapper hashes containing `Values`, `Value`, `Content`, `Items`, or `Rows` arrays are normalized to row arrays before mapping into `ZRM-*`.
- Generated `Kernel/Package/GovernanceDB-0.0.80.opm`.
- `Kernel/Package/GovernanceDB-0.0.80.opm` SHA256: `158C516BCD6AB41AB6003AB4300F8E2DB6BF2A6D13F9E85A6F0F53C9608A8779`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.80.opm`.
- PSGI/web workers must be restarted after upgrade; the current logs show old packages being reloaded in-process and the Agent backend remains poisoned until process restart.
- Retest Agent queue/customer permission paths first, because Amend/Clone cannot be proven while `DynamicField::Driver::Agent` fails globally.
- Retest an existing empty Assessment child; lazy hydration should write `ZRM-RiskAssessment` during form load if the BlueBook record has `ZBlue-Template`.
- Retest a newly Amend-created child; template rows should be written during child creation.

### Next Priorities

- Superseded by `Kernel/Package/GovernanceDB-0.0.81.opm`; install/upgrade 0.0.81 to capture error-level Amend/Clone diagnostics.

## 2026-06-17 Error-Level Runtime Diagnostics 0.0.81

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.81`.
- Added explicit error-level diagnostics for Amend and Clone top-level failures before `CustomerErrorScreen`.
- Added error-level `Amend started` and `Clone started` markers so Apache error.log confirms whether the upgraded module is actually loaded.
- Added error-level Amend diagnostics for:
  - Missing ticket context.
  - Missing submitted SupportProfile.
  - Unresolvable SupportProfile.
  - Resolved SupportProfile without GovernanceObjectID.
  - Missing `ZTicket-Parent`, `ZTicket-BlueBook`, `ZTicket-BlueLevel`, or `ZTicket-Chapter`.
  - Parent ticket load failure.
  - Child ticket creation failure.
- Added error-level Clone diagnostics for:
  - Missing ticket context.
  - Root ticket resolution failure.
  - ServiceSupportMap field application failure.
- Ensured template lazy-hydration diagnostics also use error level.
- Generated `Kernel/Package/GovernanceDB-0.0.81.opm`.
- `Kernel/Package/GovernanceDB-0.0.81.opm` SHA256: `F36B48B6BB7068B6B1D3F17ED92CF9B5CDA4A3E8793A32509DDE87F0F169E22B`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.81.opm`.
- After upgrade and restart, Apache error.log should show `CustomerTicketZTSMAction: Amend started` or `CustomerTicketZTSMAction: Clone started` on each action submit.
- If the started marker appears, the next `CustomerTicketZTSMAction:` error should identify the failing branch.
- If the started marker does not appear, OTOBO is still not loading the upgraded module.

### Next Priorities

- Install/upgrade 0.0.81, restart PSGI/web workers, run Amend once, run Clone once, then inspect Apache error.log for `CustomerTicketZTSMAction:`.

## 2026-06-17 Runtime Failure Repair 0.0.82

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.82`.
- Repaired Amend parent ticket loading:
  - `TicketGet` is now read into a hash before checking parent ticket data.
  - Fixes the logged failure `Amend failed: parent ticket '133' could not be loaded` when the parent ticket exists.
- Repaired Clone root ticket resolution:
  - Parent/root ticket `TicketGet` is now read into a hash before returning the resolved root ticket.
  - Fixes the logged failure `Clone failed: root ticket could not be resolved from source ticket '134'` when the child ticket has `ZTicket-Parent`.
- Repaired Template risk assessment hydration shape for `ZRM-RiskAssessment`:
  - Entity fields inside the DynamicField Set are now written as per-row array values as expected by OTOBO Set/BaseEntity drivers.
  - Template metadata tokens such as `ZRM-RiskCategory` are discarded if they leak through as values.
  - Prevents the Set driver crash `Can't use string ("ZRM-RiskCategory") as an ARRAY ref`.
- Added error-level logging when template risk assessment write fails:
  - Logs `ZTSMBlueBookRuntime: Template risk assessment field set failed` with TicketID, TemplateID, and row count.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.82.opm`.
- `Kernel/Package/GovernanceDB-0.0.82.opm` SHA256: `F96C7CB6262DAA16A3C4A4D62FD379CD7476423F2543E95A105EEB8B3CEE551E`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.82.opm`.
- Restart PSGI/web workers after upgrade before retesting, especially after prior driver reload errors.
- Retest existing empty Assessment child `2026061725000023`; lazy hydration should populate template rows instead of crashing.
- Retest Amend from child ticket `134`; it should load parent ticket `133` and proceed to duplicate detection or child creation.
- Retest Clone from child ticket `134`; it should resolve root/parent ticket `133`, enforce same-service ServiceSupportMap, and proceed to create the cloned parent request.

### Next Priorities

- Install/upgrade 0.0.82, restart PSGI/web workers, and retest in this order:
  - Assessment workspace load/template hydration.
  - Amend support-profile add/duplicate behavior.
  - Clone same-service ServiceSupportMap creation.

## 2026-06-17 Clone Governance Snapshot Correction 0.0.83

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.83`.
- Corrected Clone ServiceSupportMap handling:
  - The selected ServiceSupportMap is only the selector/source of governance applicability.
  - Clone sets the new ticket service from the selected map.
  - Clone writes `ZTicket-StateBook` and `ZTicket-ApprovalModel`, matching the governance snapshot fields written by `ZTSMServiceLibrarian`.
  - Clone preserves `ZTicket-Parent` back to the trigger/source ticket.
  - Clone no longer writes application, environment, or location fields from ServiceSupportMap in this action.
- Fixed the Perl hash assignment bug where unresolved governance values could return an empty list and corrupt `%FieldMap`.
- Generated `Kernel/Package/GovernanceDB-0.0.83.opm`.
- `Kernel/Package/GovernanceDB-0.0.83.opm` SHA256: `70C772F461056293CFD0D4D1F6CF35A8FBE902B766B8288A07D4CFC729A45BFE`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.83.opm`.
- Retest Clone from child ticket `134`; the previous failure `Dynamic field set failed: '89' does not exist` should no longer occur.

### Next Priorities

- Install/upgrade 0.0.83, restart PSGI/web workers, and retest Clone.

## 2026-06-17 Clone Customer Permission Repair 0.0.84

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.84`.
- Repaired Clone customer visibility for child-owner initiated clones:
  - The cloned parent ticket now uses the acting customer user as `CustomerUser`.
  - The cloned parent ticket now writes `CustomerID` from the acting customer user's `UserCustomerID`, falling back to the original root ticket customer ID.
  - This prevents the immediate redirect to the new cloned parent from landing on `No Permission` when the child owner is not the original requester.
- Kept Clone governance behavior from 0.0.83:
  - ServiceSupportMap is still only the selector/source.
  - Clone writes `ZTicket-StateBook`, `ZTicket-ApprovalModel`, and the `ZTicket-Parent` backlink.
- Suppressed harmless `ZTSMBlueBookRuntime` subroutine redefinition warnings during package hot-reload.
- Generated `Kernel/Package/GovernanceDB-0.0.84.opm`.
- `Kernel/Package/GovernanceDB-0.0.84.opm` SHA256: `45AC1B55E94D884595CA49F0629F1C654D8D546A019C985B3EBADA7D35EB63D3`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.84.opm`.
- Retest Clone from child ticket `134`; new ticket should open for the acting customer user instead of showing `No Permission`.

### Next Priorities

- Install/upgrade 0.0.84, restart PSGI/web workers, and retest Clone end-to-end.

## 2026-06-17 Clone UX / Title Correction 0.0.85

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.85`.
- Changed Clone completion behavior:
  - Clone no longer redirects the customer to the newly created parent ticket.
  - Clone returns the customer to the source/current ticket after successful creation.
- Confirmed Amend already returns the customer to the source/current ticket after successful creation or duplicate detection.
- Changed cloned parent ticket title format:
  - Removed `External Party - <Parent Title>`.
  - New format is `<Parent TicketType>:<ParentTicket ID>: <Parent Title> - <ServiceSupportMap Name>`.
  - Parent identifier uses parent ticket number when available, falling back to parent internal TicketID.
- Generated `Kernel/Package/GovernanceDB-0.0.85.opm`.
- `Kernel/Package/GovernanceDB-0.0.85.opm` SHA256: `E56BD48478D55D6A6C78900BF8B179D43BB3140925709B35F77B0B7217DEFB75`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.85.opm`.
- Retest Clone from an Assessment child; it should stay on the current child ticket and the created parent title should use the parent context and selected ServiceSupportMap name.

### Next Priorities

- Install/upgrade 0.0.85, restart PSGI/web workers, and retest Clone title plus redirect behavior.

## 2026-06-17 Article Cleanup / Neutral BlueBook Stop 0.0.86

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.86`.
- Added RichText/plain-text cleanup before writing runtime evidence:
  - Strips full CKEditor HTML documents.
  - Removes `style` and `script` blocks.
  - Converts common block tags and line breaks to text.
  - Decodes common HTML entities.
- Applied cleanup to:
  - Template description article text.
  - Template-derived text fields before writing assessment rows.
  - Runtime remarks in text articles.
  - Risk assessment article values and remarks.
  - Stored assessment remarks.
- Improved Clone article ticket references:
  - Source ticket, duplicated parent ticket, and new request ticket now render with ticket number/internal ID, ticket type, and title instead of only internal IDs.
- Repaired BlueBook mandatory neutral completion behavior:
  - If a mandatory BlueLevel completes with at least one successful or partial-success mandatory task, BlueBook can continue.
  - If all mandatory tasks in the completed BlueLevel are neutral outcomes (`closed duplicate` / `closed no action`) and none are successful/partial/failed, the parent is closed neutral and orchestration stops.
  - Mixed neutral-only levels prefer `closed no action`; duplicate-only levels close `closed duplicate`.
  - Rejected/failed/rollback behavior remains immediate hard-stop behavior.
- Generated `Kernel/Package/GovernanceDB-0.0.86.opm`.
- `Kernel/Package/GovernanceDB-0.0.86.opm` SHA256: `13EB11A2A8A95B755A095AB5358FC1EC14F9F4B057BE3F475A15832EA6DD8019`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.86.opm`.
- Retest template article rendering to confirm CKEditor boilerplate no longer appears.
- Retest Clone article rendering to confirm ticket references are readable.
- Retest a BlueLevel where mandatory tasks close only as duplicate/no-action; parent should close neutral instead of advancing.

### Next Priorities

- Install/upgrade 0.0.86, restart PSGI/web workers, then retest article display and neutral BlueBook completion.

## 2026-06-17 Customer Cancel / Platform Failsafe 0.0.87

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.87`.
- Repaired requester/customer cancel visibility and backend enforcement:
  - Cancel is no longer restricted to `Ticket.CustomerUserID == current user`.
  - Cancel now requires normal customer read permission on the root governance ticket and still excludes orchestration child tickets.
  - Cancel still respects configured root ticket types and closed-ticket protections.
- Repaired Cancel action menu usability:
  - Menu item now opens the runtime dialog, scrolls it into view, and focuses the first actionable field.
  - This prevents the top menu click from appearing to do nothing when the dialog is lower in the zoom page.
- Added ServiceLibrarian platform failsafe resolution:
  - Reads Application `ZTSMAppSystem-Platform`.
  - Reads Platform `ZTSMPlatform-ServiceSupportMap`.
  - Platform-offered ServiceSupportMaps score above generic service-only maps and below direct application matches.
  - Resolution article now shows whether Platform Failsafe was applied and lists the resolved platform context.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.87.opm`.
- `Kernel/Package/GovernanceDB-0.0.87.opm` SHA256: `4368BF6452757C26F18CFD6B5C5390C01DAD42B107F2A63D6DE5D65AEE2152A9`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.87.opm`.
- Retest Cancel from a customer user who has customer ticket access but is not the original `CustomerUserID`.
- Retest Cancel from the top action menu and confirm the cancellation remarks dialog opens and submits.
- Retest ServiceLibrarian for an Application with Platform `IaaS Extension`; platform ServiceSupportMaps such as `ICA-IAASEXT-...` should beat generic score-0 maps.

### Next Priorities

- Install/upgrade 0.0.87, restart PSGI/web workers, then retest cancel and platform failsafe resolution before moving back to clone/amend/template regression testing.

## 2026-06-17 Runtime Menu / Evidence Cleanup 0.0.88

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.88`.
- Moved `Amend` and `Clone` back under the header `...` action menu:
  - These remain runtime utility actions rather than primary next-step buttons.
- Repaired menu action behavior:
  - Dialog-opening menu actions now explicitly unhide the action dialog, set display back to block, close the `...` menu, scroll to the dialog, and focus the first actionable field.
  - `On Hold` and `Resume` now execute directly from the menu because they require no input.
  - `Cancel Ticket` and `Follow-up` still open their remarks dialogs.
- Repaired runtime evidence readability:
  - Amend articles now show readable parent and created-child ticket summaries instead of internal numeric IDs.
  - Follow-up articles now show readable original-child and created follow-up ticket summaries.
  - ChapterPlay initiation articles now show readable parent ticket summaries.
- Repaired mandatory outcome article display:
  - `Parent Outcome` now uses the `ZTicket-Outcome` key label such as `No Action` instead of raw values such as `1`.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.88.opm`.
- `Kernel/Package/GovernanceDB-0.0.88.opm` SHA256: `BDA56006DB9FC59A08F14B5A8BF3D12AAA08B4E5D7A9214ACA7853DC53B6E1E5`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.88.opm`.
- Retest `Cancel Ticket` from the menu and confirm the remarks dialog visibly opens.
- Retest `On Hold` from the menu and confirm it submits directly.
- Retest `Follow-up` from the menu and confirm the remarks dialog visibly opens.
- Retest Amend/Clone visibility and confirm both render only under `...`.
- Retest generated evidence articles for Amend, Follow-up, and mandatory neutral completion.

### Next Priorities

- Install/upgrade 0.0.88, restart PSGI/web workers, clear browser cache if the old menu JavaScript persists, then retest menu actions before further backend changes.

## 2026-06-17 Cancel Propagation / Task Runtime Repair 0.0.89

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.89`.
- Added requester cancel propagation for orchestration descendants:
  - Parent `Cancel Ticket` now closes/unlocks active child tickets that are clearly orchestration ledgers (`ZTicket-Parent` plus BlueBook/BlueLevel/Chapter markers).
  - Cloned/main request tickets are not swept up by this propagation.
  - Child cancellation articles include a readable parent ticket summary and the requester remarks.
- Repaired BlueBookReader runtime evidence references:
  - `ChapterPlay initiated` now shows a readable parent ticket summary.
  - Parent `BlueBook orchestration started` now lists created child tickets as readable ticket summaries instead of raw internal IDs.
- Repaired task runtime access for task-like tickets whose OTOBO Type falls back to `Assessment`:
  - CustomerTicketZoom now treats titles beginning `Task -` as task runtime ledgers for `Complete Task` visibility.
- Repaired requester-role assignment:
  - `ZTSMCharacterEngage` now snapshots `ZTicket-Owner` from the ticket requester when `ZTicket-Role` resolves to Requester, rather than selecting a support-assignment user.
- Synced changed runtime files across live source, package source, runtime overlay, PortedFromITSMConfigItem copies, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.89.opm`.
- `Kernel/Package/GovernanceDB-0.0.89.opm` SHA256: `95E684A8F77324C7E4481420F02BAA87BB0EF6955B686C92638C9DE6731DF91E`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.89.opm`: XML parsed successfully, version `0.0.89`, 155 file nodes, `MissingBase64=0`.
- Embedded runtime overlay hashes matched package-source runtime overlay copies for:
  - `CustomerTicketZTSMAction.pm`
  - `CustomerTicketZoom.pm`
  - `ZTSMBlueBookReader.pm`
  - `ZTSMCharacterEngage.pm`
- Perl syntax checks passed with `perl -I. -c` for the four changed runtime modules.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.89.opm`.
- Retest parent `Cancel Ticket` on an in-progress orchestration and confirm all active orchestration children close cancelled while cloned/main request tickets remain open.
- Retest Requester clarification/task records and confirm requester-role tickets assign to Whye Wong Tang and show `Complete Task`.
- Retest BlueBook articles and confirm created ticket references are readable ticket summaries, not raw numeric IDs.

### Next Priorities

- Install/upgrade 0.0.89, restart PSGI/web workers, and retest cancel propagation, requester task completion, and BlueBookReader evidence before continuing with deeper ChapterDirector behavior.

## 2026-06-17 Customer Request Defaults Preferences 0.0.90

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.90`.
- Added a customer preference group `CustomerPreferencesGroups###ZTSMRequestDefaults` labelled `Request defaults`.
- Added runtime overlay preference module `Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults`:
  - Renders customer-editable defaults for `ZUser-SupportProfile`, `ZUser-Application`, `ZUser-Environment`, and `ZUser-Location`.
  - Saves values directly to CustomerUser dynamic fields.
  - Uses `ValueDelete` when the customer clears a default.
  - Filters `ZUser-SupportProfile` options from SupportAssignment records matching the current customer user.
  - Allows Application, Environment, and Location selection from all Governance Objects in their respective classes.
- Added bootstrap installation/repair for the four CustomerUser GovernanceObject dynamic fields:
  - `ZUser-Location`
  - `ZUser-Application`
  - `ZUser-Environment`
  - `ZUser-SupportProfile`
- Updated `ZTSMRoleDirector` requester profile resolution:
  - Prefers `ZUser-SupportProfile`.
  - Falls back to legacy `ZTSMUser-DefaultSupportProfile`.
  - Reads dynamic field values directly when the CustomerUser backend map does not expose them.
- Added the new preference module to the SOPM file list.
- Generated `Kernel/Package/GovernanceDB-0.0.90.opm`.
- `Kernel/Package/GovernanceDB-0.0.90.opm` SHA256: `1A29F9FA012B575DD9198DA9647555248F684913C469A45070153475250F0723`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.90.opm`: XML parsed successfully, version `0.0.90`, 156 file nodes, `MissingBase64=0`.
- Confirmed `var/governancedb/runtime_overlay/Kernel/Output/HTML/Preferences/ZTSMCustomerDefaults.pm` is embedded in the generated OPM.
- Perl syntax checks passed with `perl -I. -c` for:
  - `Kernel/System/GovernanceDB/Bootstrap.pm`
  - `Kernel/Output/HTML/Preferences/ZTSMCustomerDefaults.pm`
  - Runtime overlay ProcessManagement `ZTSMRoleDirector.pm`
  - Runtime overlay GenericAgent `ZTSMRoleDirector.pm`

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using `Kernel/Package/GovernanceDB-0.0.90.opm`.
- Retest `CustomerPreferences` and confirm the `Request defaults` card appears.
- Retest support profile options using a customer user with multiple SupportAssignment records.
- Retest requester-role orchestration to confirm `ZUser-SupportProfile` is used as the requester default support profile.

### Next Priorities

- Install/upgrade 0.0.90, restart PSGI/web workers, and retest customer preference defaults end-to-end.

## 2026-06-17 Customer Request Hydration / Follow-up Ownership Design

### Architectural Decisions

* Customer request defaults are requester convenience values, not governance truth.
* Customer defaults are stored on the CustomerUser object through:

  * `ZUser-Application`
  * `ZUser-Environment`
  * `ZUser-Location`
  * `ZUser-SupportProfile`
* Request defaults should automatically hydrate new root governance requests during customer ticket creation.
* Hydration occurs only when the ticket field is empty; explicitly supplied ticket values always win.
* User defaults are snapshots at request creation time and must not remain linked to the CustomerUser record after ticket creation.
* Follow-up remains a runtime corrective execution action and not a StateBook transition.
* Follow-up child tickets inherit execution ownership context from the initiating child ticket.
* PurpleBook execution must preserve ownership continuity so the initiating owner can continue the corrective workflow without reassignment surprises.
* Successful PurpleBook completion returns the original child ticket to its previous execution owner and execution group.

### Completed Design

#### Customer Request Default Hydration

When a new customer request is created:

* `ZUser-Application` hydrates `ZTicket-Application`.
* `ZUser-Environment` hydrates `ZTicket-Env`.
* `ZUser-Location` hydrates `ZTicket-Location`.
* `ZUser-SupportProfile` remains requester preference context and is not automatically written to execution ownership fields.

#### Multi-Value Handling

Customer preference fields are currently single-select.

Ticket fields may be multi-select.

Hydration rules:

* Single → Single:

  * Copy value directly.
* Single → Multi:

  * Wrap value as a single-item array.
* Empty User Value:

  * Do not write ticket value.
* Existing Ticket Value:

  * Do not overwrite.

Example:

Customer:

* `ZUser-Location = Singapore DC`

Ticket:

* `ZTicket-Location` supports multiple values

Result:

* `["Singapore DC"]`

#### Follow-up Ownership Propagation

When Follow-up is executed:

Source Child Ticket:

* `ZTicket-Owner`
* `ZTicket-OwnerGroup`

must be copied to newly created PurpleBook child tickets.

This preserves:

* Visibility
* Ownership continuity
* Runtime action permissions
* Corrective execution accountability

#### Follow-up Return Ownership

When PurpleBook execution completes successfully:

* Original child ticket returns to `in-progress`.
* Original child ticket retains:

  * `ZTicket-Owner`
  * `ZTicket-OwnerGroup`

PurpleBook completion must not:

* Reassign ownership.
* Clear ownership.
* Replace ownership with PurpleBook executor values.

### Rejected Approaches

* Do not force customers to repeatedly select Application, Environment, and Location for every request when defaults already exist.
* Do not overwrite explicitly supplied ticket values using CustomerUser defaults.
* Do not link tickets dynamically back to CustomerUser defaults after ticket creation.
* Do not create new ownership fields for PurpleBook execution.
* Do not recalculate ownership during PurpleBook return.
* Do not transfer ownership to the last PurpleBook executor when returning to the original child ticket.

### Next Priorities

* Implement CustomerTicketMessage hydration from CustomerUser defaults.
* Verify single-value to multi-value field conversion behavior.
* Verify new customer requests receive default Application, Environment, and Location values.
* Verify Follow-up child tickets inherit Owner and OwnerGroup.
* Verify PurpleBook successful completion returns original child tickets to the same Owner and OwnerGroup.
* Verify all runtime action visibility rules continue to function after ownership propagation.

## 2026-06-18 Customer Request Hydration / Follow-up Ownership 0.0.91

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.91`.
- Implemented CustomerTicketMessage request-default hydration:
  - `ZUser-Application` hydrates empty `ZTicket-Application`.
  - `ZUser-Environment` hydrates empty `ZTicket-Env`.
  - `ZUser-Location` hydrates empty `ZTicket-Location`.
  - Explicit ticket values still win.
  - `ZUser-SupportProfile` remains requester preference context and is not written to execution ownership fields.
- Added single-value to multi-value wrapping when the target ticket Dynamic Field is configured as multi-value.
- Added Follow-up ownership propagation:
  - Follow-up PurpleBook children inherit `ZTicket-Owner` from the initiating child.
  - Follow-up PurpleBook children inherit `ZTicket-OwnerGroup` from the initiating child.
  - Normal BlueBook child spawning remains unchanged unless ownership overrides are passed.
- Generated `Kernel/Package/GovernanceDB-0.0.91.opm`.
- `Kernel/Package/GovernanceDB-0.0.91.opm` SHA256: `1F90FE05B945A89AA4C7737FEAFF3EC7E0C0F30A68D544832819123B400CB68E`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.91.opm`: XML parsed successfully, version `0.0.91`, 156 file nodes, `MissingBase64=0`.
- Embedded runtime overlay hashes matched package-source runtime overlay copies for:
  - `CustomerTicketMessage.pm`
  - `CustomerTicketZTSMAction.pm`
  - `ZTSMBlueBookRuntime.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for:
  - `Kernel/Modules/CustomerTicketMessage.pm`
  - `Kernel/Modules/CustomerTicketZTSMAction.pm`
  - `Kernel/System/ZTSMBlueBookRuntime.pm`

### Architectural Decisions

- Latest package field authority uses `ZTicket-Env`, not `ZTicket-Environment`.
- Customer defaults are creation-time snapshots only; they do not create a live dependency on the CustomerUser defaults after ticket creation.
- PurpleBook ownership inheritance is scoped to Follow-up child spawning and does not alter the successful return path, which only moves the original child ticket back to `in-progress`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.91` package.
- Verify CustomerTicketMessage creates new requests with defaults when Application, Environment, and Location are left empty.
- Verify explicit CustomerTicketMessage values are not overwritten by CustomerUser defaults.
- Verify Follow-up PurpleBook children inherit `ZTicket-Owner` and `ZTicket-OwnerGroup`.

### Next Priorities

- Install/upgrade 0.0.91, restart PSGI/web workers, and retest request-default hydration plus Follow-up ownership propagation.

## 2026-06-18 BlueLevel GeneralCatalog Repair 0.0.92

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.92`.
- Repaired BlueBook BlueLevel parsing for GeneralCatalog-backed values:
  - `ZBlue-BlueLevel`, `ZBlue-Level`, and `ZBlue-Seq` now resolve GeneralCatalog item IDs back to their item names before runtime use.
  - Example: raw GeneralCatalog item ID `207` resolves to BlueLevel value `1`.
- Applied the repair in both:
  - `ZTSMBlueBookReader`
  - `ZTSMBlueBookRuntime`
- This fixes both stored execution context (`ZTicket-BlueLevel`) and generated evidence article display for BlueBook orchestration and ChapterPlay initiation.
- Generated `Kernel/Package/GovernanceDB-0.0.92.opm`.
- `Kernel/Package/GovernanceDB-0.0.92.opm` SHA256: `2AA627296194A6BC6106DD12F9445B2BB506C3818DDE85E5F620F34CD751CDA9`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.92.opm`: XML parsed successfully, version `0.0.92`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across live source, package source, runtime overlay, and ZTSMOverlay copies for:
  - `ZTSMBlueBookReader.pm`
  - `ZTSMBlueBookRuntime.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for:
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm`
  - `Kernel/System/ZTSMBlueBookRuntime.pm`

### Architectural Decisions

- BlueLevel remains runtime choreography data sourced from BlueBook records.
- GeneralCatalog IDs must not leak into ticket evidence articles when the catalog item name is the operational value.
- The fix resolves values at parse time so sorting, child-ticket matching, ticket field storage, and evidence rendering all use the same runtime value.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.92` package.
- Retest BlueBook orchestration article generation and confirm `BlueLevel` displays `1` rather than the raw GeneralCatalog item ID such as `207`.

### Next Priorities

- Install/upgrade 0.0.92, restart PSGI/web workers, and retest BlueBook orchestration from a BlueBook record whose BlueLevel is stored as a GeneralCatalog item ID.

## 2026-06-18 Requester Owner Workspace Repair 0.0.93

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.93`.
- Updated CustomerTicketMessage creation so new customer-created tickets snapshot the requester into `ZTicket-Owner` when `ZTicket-Owner` is empty.
- Hardened `CustomerDashboard::TileTicketList` workspace lookup:
  - Workspace tickets continue to resolve through SupportAssignment / `ZTicket-OwnerGroup`.
  - Workspace tickets also resolve through direct `ZTicket-Owner`.
  - Direct-owner lookup now checks both the dashboard `UserID` and `UserLogin` identity forms.
- Synced changed files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.93.opm`.
- `Kernel/Package/GovernanceDB-0.0.93.opm` SHA256: `A1C10FCAB0935A54D4FCDEF60E9C5C02DC846A49886C6775CE37D6994B795AEE`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.93.opm`: XML parsed successfully, version `0.0.93`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across live source, package source, runtime overlay, and ZTSMOverlay copies for:
  - `CustomerTicketMessage.pm`
  - `TileTicketList.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for:
  - `Kernel/Modules/CustomerTicketMessage.pm`
  - `Kernel/Output/HTML/CustomerDashboard/TileTicketList.pm`

### Architectural Decisions

- Requester ownership on ticket creation is execution visibility context, not governance truth.
- `ZTicket-Owner` is set only when empty so explicit/runtime assignment is preserved.
- Customer workspace visibility is inclusive: SupportAssignment participation OR direct ticket ownership.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.93` package.
- Retest new requester-created tickets and confirm they appear in the requester workspace.
- Retest Follow-up PurpleBook child tickets and confirm they appear for the direct `ZTicket-Owner`.

### Next Priorities

- Install/upgrade 0.0.93, restart PSGI/web workers, and retest the customer dashboard workspace tile for requester-created tickets and Follow-up children.

## 2026-06-18 Follow-up BlueLevel Compatibility Repair 0.0.94

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.94`.
- Restored Follow-up action visibility for tickets created before the BlueLevel GeneralCatalog repair:
  - BlueBook record parsing now preserves both resolved `BlueLevel` and original `RawBlueLevel`.
  - `CustomerTicketZoom` Follow-up visibility matches the ticket `ZTicket-BlueLevel` against either representation.
  - `CustomerTicketZTSMAction` Follow-up execution uses the same compatibility match.
  - `ZTSMBlueBookRuntime` template lookup also matches either representation for existing tickets.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.94.opm`.
- `Kernel/Package/GovernanceDB-0.0.94.opm` SHA256: `B5E79848451658ACE747A64DCD3E6E81F2C5EDB49E8A3F28FDAEEB03F0F80BCC`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.94.opm`: XML parsed successfully, version `0.0.94`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across live source, package source, runtime overlay, and ZTSMOverlay copies for:
  - `CustomerTicketZoom.pm`
  - `CustomerTicketZTSMAction.pm`
  - `ZTSMBlueBookRuntime.pm`
  - `ZTSMBlueBookReader.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for the four changed runtime modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- BlueLevel GeneralCatalog IDs remain repaired to readable operational values for new execution context and evidence.
- Existing tickets that already stored the raw GeneralCatalog item ID remain valid runtime execution ledgers and must still expose Follow-up when their BlueBook record contains `ZBlue-PurpleBook`.
- Compatibility is handled in matching logic; no new Dynamic Fields or governance recalculation are introduced.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.94` package.
- Retest an existing Assessment ticket whose `ZTicket-BlueLevel` is a raw GeneralCatalog item ID such as `207` and confirm `Follow-up` appears in the header action menu.

### Next Priorities

- Install/upgrade 0.0.94, restart PSGI/web workers, and retest Follow-up visibility plus submission on the affected Assessment ticket.

## 2026-06-18 Follow-up Pause / Requester Default Assignment Repair 0.0.95

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.95`.
- Tightened Follow-up pause behavior:
  - `CustomerTicketZoom` now hides customer runtime execution actions when the original child ticket state is `follow-up`.
  - `CustomerTicketZTSMAction` now blocks direct runtime execution submissions while the ticket state is `follow-up`.
  - The original Assessment child remains paused until PurpleBook completion returns it to `in-progress`.
- Corrected Follow-up PurpleBook ownership spawning:
  - Follow-up child tickets no longer receive a blanket `OwnerOverride` / `OwnerGroupOverride` from the initiating child.
  - PurpleBook child assignment now follows the child BlueBook record profile and role path.
- Repaired Requester Default assignment in both RoleDirector paths:
  - If requester `ZUser-SupportProfile` is populated, RoleDirector assigns it to `ZTicket-OwnerGroup`.
  - If requester `ZUser-SupportProfile` is empty, RoleDirector assigns the requester CustomerUserID to `ZTicket-Owner`.
  - GenericAgent RoleDirector no longer skips requester-default repair just because an OwnerGroup is already present.
- Synced changed runtime files across live source, package source, runtime overlay, PortedFromITSMConfigItem, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.95.opm`.
- `Kernel/Package/GovernanceDB-0.0.95.opm` SHA256: `F887611CE3AB821E2E598A0D1AE1E28DF28EFB8D7C126872A8F87C5709F8E4DC`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.95.opm`: XML parsed successfully, version `0.0.95`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across all mirror copies for:
  - `CustomerTicketZoom.pm`
  - `CustomerTicketZTSMAction.pm`
  - `Kernel/System/GenericAgent/ZTSMRoleDirector.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMRoleDirector.pm`
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for the four changed runtime modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- `follow-up` is a corrective execution pause for the original child ticket, not an active Assessment submission state.
- PurpleBook child assignment should be resolved by the child BlueBook record through RoleDirector, not copied wholesale from the initiating child.
- Requester Default means requester preference first, direct requester ownership second:
  - `ZUser-SupportProfile` present -> `ZTicket-OwnerGroup`.
  - `ZUser-SupportProfile` empty -> `ZTicket-Owner`.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.95` package.
- Retest Follow-up on an Assessment child and confirm `Submit Assessment` / `Reject` disappear while the ticket is in `follow-up`.
- Retest the PurpleBook `Clarification Required` Task and confirm Requester Default assignment resolves to the requester support profile or requester CustomerUserID according to `ZUser-SupportProfile`.

### Next Priorities

- Install/upgrade 0.0.95, restart PSGI/web workers, and retest Follow-up pause plus requester clarification ownership end-to-end.

## 2026-06-18 GovernanceRole Requester Default Code Repair 0.0.96

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.96`.
- Corrected RoleDirector requester-default directive handling:
  - BlueBook `Profile` continues to resolve to either SupportProfile or GovernanceRole.
  - GovernanceRole `ZTSM-Code` / name such as `Requester Default` now normalizes to `REQUESTER-DEFAULT`.
  - RoleDirector now treats `REQUESTER-DEFAULT` as the requester-default branch.
  - Legacy `REQUESTER-SUPPORT-GROUP` remains accepted only as a backward-compatible alias.
- Applied the correction in both RoleDirector paths:
  - `Kernel/System/GenericAgent/ZTSMRoleDirector.pm`
  - `Kernel/System/ProcessManagement/TransitionAction/ZTSMRoleDirector.pm`
- Synced changed runtime files across live source, package source, runtime overlay, PortedFromITSMConfigItem, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.96.opm`.
- `Kernel/Package/GovernanceDB-0.0.96.opm` SHA256: `9F515FB791E9983A5ADFE03BB5EE054B655B198E06455CDF7E43AA100737DE86`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.96.opm`: XML parsed successfully, version `0.0.96`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across all RoleDirector mirror copies.
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for both RoleDirector modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- BlueBook `ZBlue-Profile` points to a GovernanceRole or SupportProfile.
- GovernanceRole `ZTSM-Code` is the behavior contract; names/codes such as `Requester Default` must drive requester-default assignment directly.
- `APP-PROFILE` and related directive keys are legacy normalized internal aliases, not values invented from BlueBook. The requester-default path must not depend on those aliases.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.96` package.
- Retest the GenericAgent log and confirm `Unsupported governance profile: Requester Default` no longer appears.
- Retest the PurpleBook `Clarification Required` Task requester-default assignment.

### Next Priorities

- Install/upgrade 0.0.96, restart PSGI/web workers, and rerun the Follow-up clarification flow.

## 2026-06-18 Task-Like Take Ownership Visibility Repair 0.0.97

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.97`.
- Repaired customer portal `Take Ownership` visibility for task-like execution tickets:
  - `CustomerTicketZoom` now treats task-like tickets as ownership-actionable even when they do not expose normal assessment/approval outcome actions.
  - Task-like detection continues to support real Ticket Type `Task` and fallback titles beginning `Task -`.
- Repaired backend submission validation:
  - `CustomerTicketZTSMAction` now accepts `TakeOwnership` for the same task-like ticket definition.
- Preserved support-assignment authorization:
  - Customer users still need `ztsm_action` access through direct ownership or SupportAssignment participation in `ZTicket-OwnerGroup`.
  - A requester who is not in the ICS Support Team SupportAssignment can still reply, but cannot take ICS ownership.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.97.opm`.
- `Kernel/Package/GovernanceDB-0.0.97.opm` SHA256: `C0EECD9E1E431305AB5E10D8FD1BBC00E1F491CB82141D927AF49C4821397AAB`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.97.opm`: XML parsed successfully, version `0.0.97`, 156 file nodes, `MissingBase64=0`.
- Synced hashes matched across all `CustomerTicketZoom.pm` and `CustomerTicketZTSMAction.pm` mirror copies.
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for both changed customer modules.
- `git diff --check` reported only existing CRLF normalization warnings.

### Architectural Decisions

- Ownership claim is a runtime execution action for task-like ledgers and should not depend on the normal assessment/approval outcome-action list.
- Support Assignment remains the authorization boundary for taking ownership of a SupportProfile-owned task.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.97` package.
- Retest with a customer user who has SupportAssignment membership in `ICS Support Team` and confirm `Take Ownership` appears.
- Retest with the requester account if it is not an ICS Support Team member and confirm it can reply but cannot take ownership.

## 2026-06-19 Task Completion Outcome and Action Placement Repair 0.0.98

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.98`.
- Repaired customer portal Task completion outcome selection:
  - `Complete` now renders as a first-class runtime action instead of an action-menu item.
  - Task outcome choices are rendered from the canonical stored outcome keys `0`, `1`, `2`, `-1`, and `-2` with user-facing labels `Successful`, `No Action`, `Partial Success`, `Failed`, and `Rollback`.
  - The form no longer trusts the deployed `ZTicket-Outcome` DynamicField `PossibleValues` orientation, avoiding duplicate numeric labels such as `1` and invalid submitted labels.
  - Backend submission normalizes older/display-label posts such as `Successful` back to stored values such as `0` before validation and DynamicField write.
- Renamed the runtime customer action label from `Complete Task` to `Complete`.
- Moved `Unlock` into the customer action menu.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.98.opm`.
- `Kernel/Package/GovernanceDB-0.0.98.opm` SHA256: `D3B1195B3757C2448ED0E160F964EF0F667C6821E81A86C1C81C22B08D12DB20`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.98.opm`: XML parsed successfully, version `0.0.98`, 156 file nodes, `MissingBase64=0`, with `CodeInstall` and `CodeUpgrade`.
- Synced hashes matched across all `CustomerTicketZoom.pm` and `CustomerTicketZTSMAction.pm` mirror copies.
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for both changed customer modules.
- `git diff --check` reported only the existing CRLF normalization warning for `Kernel/Package/GovernanceDB/GovernanceDB.sopm`.

### Architectural Decisions

- Task completion remains a runtime execution action and writes execution evidence only; it does not invoke StateBook or BlueBook transitions directly outside the existing chapter director evaluation after closure.
- The Task outcome form uses the canonical runtime outcome map instead of the DynamicField display configuration because completion logic depends on stored outcome values.
- `Unlock` is treated as a utility/failback action and belongs in the action menu, while `Complete` is the primary task outcome action.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.99.opm`; install/upgrade `0.0.99` instead because `0.0.98` still dropped submitted outcome value `0`.
- Retest the Task completion dropdown and confirm it shows text labels once each, stores numeric `ZTicket-Outcome`, and closes the Task according to the selected outcome.
- Retest that `Complete` appears in the main action row and `Unlock` appears under the menu.

## 2026-06-19 Task Completion Outcome Zero Preservation Diagnostic 0.0.99

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.99`.
- Corrected Task completion request parameter handling:
  - `ZTicketOutcome` is now read with definedness preservation instead of `|| ''`.
  - This preserves valid submitted outcome value `0` instead of converting it to empty before validation.
- Added requested error-level diagnostic logging for every `CompleteTask` submission:
  - Log priority is `error`.
  - Message prefix is `ZTSM CompleteTask outcome debug`.
  - Log includes `TicketID`, `CustomerUser`, raw posted `ZTicketOutcome`, normalized outcome value, and mapped task state.
- Synced changed `CustomerTicketZTSMAction.pm` across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.99.opm`.
- `Kernel/Package/GovernanceDB-0.0.99.opm` SHA256: `E256CFC4E54A8E00D27967CC0B2C1A04F1861C465D3A0C03482175D4CCCA6FD5`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.99.opm`: XML parsed successfully, version `0.0.99`, 156 file nodes, `MissingBase64=0`, with `CodeInstall` and `CodeUpgrade`.
- Synced hashes matched across all `CustomerTicketZTSMAction.pm` mirror copies.
- Perl syntax check passed with `perl -I. -IKernel\cpan-lib -c Kernel\Modules\CustomerTicketZTSMAction.pm`.

### Architectural Decisions

- `0` is a valid Task outcome and must be preserved as a submitted value; empty-string fallback must only happen when the parameter is truly undefined.
- The temporary diagnostic is intentionally error-level because runtime OTOBO access is using error logs for immediate customer portal debugging.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.100.opm`; install/upgrade `0.0.100` instead because `0.0.99` did not advance multi-level follow-up PurpleBooks or mirror task completion evidence to the direct parent.
- Retest `Complete` with `Successful`; expected debug log should show `RawZTicketOutcome='0'`, `NormalizedZTicketOutcome='0'`, and `TaskState='closed successful'`.
- Once confirmed, consider removing or lowering the diagnostic log level.

## 2026-06-19 Follow-up PurpleBook Advancement and Parent Evidence Repair 0.0.100

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.100`.
- Repaired Task completion evidence propagation:
  - `CompleteTask` still writes the task completion article to the completed child ticket.
  - `CompleteTask` now also writes a child task completion article to the direct parent from `ZTicket-Parent`.
  - The parent article includes the completed child ticket summary, outcome, details, and uploaded attachments.
- Repaired follow-up PurpleBook multi-level advancement:
  - `ZTSMChapterDirector` no longer returns the original follow-up parent to `in-progress` immediately after the first completed PurpleBook level.
  - When the direct parent ticket is in `follow-up` and the PurpleBook has a next BlueLevel, the director now spawns that next PurpleBook level directly.
  - The original parent ticket `ZTicket-BlueLevel` remains preserved during PurpleBook advancement.
  - The original ticket returns to `in-progress` only when the follow-up PurpleBook has no next BlueLevel.
- Added parent evidence article `ZTSM Follow-up Advanced` when a follow-up PurpleBook advances to another level.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.100.opm`.
- `Kernel/Package/GovernanceDB-0.0.100.opm` SHA256: `BD160619494E650F715079A59A2CDFFD9738CEBB02B9F7E20F67604B4BCC69CA`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.100.opm`: XML parsed successfully, version `0.0.100`, 156 file nodes, `MissingBase64=0`, with `CodeInstall` and `CodeUpgrade`.
- Synced hashes matched across all `CustomerTicketZTSMAction.pm` and `ZTSMChapterDirector.pm` mirror copies.
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for `CustomerTicketZTSMAction.pm` and `ZTSMChapterDirector.pm`.

### Architectural Decisions

- Follow-up/PurpleBook advancement is execution choreography under the direct follow-up parent, not a StateBook transition.
- PurpleBook advancement must use the completed child ticket's current PurpleBook BlueLevel, not the original parent ticket's preserved `ZTicket-BlueLevel`.
- Child task completion is execution evidence and should be visible on the direct parent execution ledger.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.101.opm`; install/upgrade `0.0.101` instead because `0.0.100` still reused closed PurpleBook children on a repeated Follow-up run.
- Retest a multi-level PurpleBook and confirm completion of the first follow-up task spawns the second follow-up task.
- Retest that completion of a follow-up task writes the completion article on the direct parent ticket.
- Once Task outcome diagnostics are no longer needed, consider removing or lowering the `ZTSM CompleteTask outcome debug` error-level log.

## 2026-06-19 Repeat Follow-up Closed PurpleBook Child Reuse Repair 0.0.101

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.101`.
- Repaired repeated Follow-up execution after a previous PurpleBook run completed:
  - `ZTSMBlueBookRuntime::LevelSpawn` now supports `AllowRepeatClosed`.
  - Default behavior still reuses any existing child tickets for normal BlueBook duplicate protection.
  - When `AllowRepeatClosed` is enabled, existing open children are reused, but closed children from a previous run no longer block creation of new follow-up children.
- Enabled `AllowRepeatClosed` for PurpleBook follow-up spawning:
  - Initial customer `FollowUp` action.
  - ChapterDirector advancement to later PurpleBook BlueLevels.
- Synced changed runtime files across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.101.opm`.
- `Kernel/Package/GovernanceDB-0.0.101.opm` SHA256: `E6EEBDBD3844FC56B0E3097EC299A1C6AD67F602AA874D2D9404AD86F93E80B6`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.101.opm`: XML parsed successfully, version `0.0.101`, 156 file nodes, `MissingBase64=0`, with `CodeInstall` and `CodeUpgrade`.
- Synced hashes matched across all `ZTSMBlueBookRuntime.pm`, `CustomerTicketZTSMAction.pm`, and `ZTSMChapterDirector.pm` mirror copies.
- Perl syntax checks passed with `perl -I. -IKernel\cpan-lib -c` for all three changed modules.

### Architectural Decisions

- Repeat Follow-up is a new execution run under the same original child and PurpleBook.
- Closed PurpleBook children are historical execution evidence and must not block a new follow-up run.
- Active/open PurpleBook children are still reused to avoid duplicate active follow-up tasks.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.101` package.
- Retest: complete the first follow-up run, trigger Follow-up again on the original child, and confirm a new PurpleBook task is created instead of the article referencing the old closed task.
- Once Task outcome diagnostics are no longer needed, consider removing or lowering the `ZTSM CompleteTask outcome debug` error-level log.

### Next Priorities

- Install/upgrade 0.0.101, restart PSGI/web workers, and retest repeated Follow-up after previous PurpleBook completion.

## 2026-06-19 Customer Chapter Overview Workspace Logic Repair 0.0.102

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.102`.
- Repaired the customer chapter/ticket overview page so it uses the same workspace ownership logic as the front dashboard tile:
  - SupportAssignment discovery now scans SupportAssignment objects and matches the current customer user's reference IDs, instead of relying only on direct DynamicField search.
  - SupportProfile values can be read from the normal DynamicField value or the stored XMLData fallback.
  - Workable ticket lookup now includes tickets owned by all customer user reference IDs and by `CustomerUserLogin` when it differs from `UserID`.
  - Overview filter counts and the empty-state decision now use the merged requester ticket IDs plus ZTSM workspace ticket IDs.
- Synced `CustomerTicketOverview.pm` across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Generated `Kernel/Package/GovernanceDB-0.0.102.opm`.
- `Kernel/Package/GovernanceDB-0.0.102.opm` SHA256: `7F41963C74208F5E027188CFFCC763A094E7D2013BAFB3C4A5E200D9F203A7DB`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.102.opm`: XML parsed successfully, version `0.0.102`, 156 file nodes, `MissingBase64=0`, with `CodeInstall` and `CodeUpgrade`.
- Synced hashes matched across all `CustomerTicketOverview.pm` mirror copies.
- Perl syntax check passed with `perl -I. -IKernel\cpan-lib -c Kernel\Modules\CustomerTicketOverview.pm`.
- `git diff --check` reported only CRLF normalization warnings for touched files.

### Architectural Decisions

- The customer overview/chapter page should not fall back to requester-only ticket visibility when the dashboard workspace already knows the customer has assigned execution ledgers.
- Workspace visibility remains based on execution ownership fields and SupportAssignment participation, not lifecycle state or hardcoded routing.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.102` package.
- Retest the chapter/ticket overview page with a user who has assigned SupportAssignment work and confirm the page lists the same active workspace tickets that appear on the dashboard front page.
- Once Task outcome diagnostics are no longer needed, consider removing or lowering the `ZTSM CompleteTask outcome debug` error-level log.

### Next Priorities

- Install/upgrade 0.0.102, restart PSGI/web workers, and retest the customer chapter overview plus the repeated Follow-up flow from 0.0.101.

## 2026-06-19 Export-Driven Governance Object Defaults Refresh 0.0.103

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.103`.
- Regenerated `Kernel/Package/GovernanceDB/var/governancedb/default_classes.json` from the latest exports:
  - `Export/GOID_2026-06-19.yml`
  - `Export/ALL_DynamicFields_2026-06-19 06_28_14.yml`
- Added the new first-class Governance Object classes from the export defaults:
  - `CriticalityProfile`
  - `DataClassification`
  - `ExposureProfile`
  - `FunctionProfile`
  - `ServiceTier`
- Refreshed Application class defaults so Application now references first-class Governance Object profile classes instead of the older simple dropdown-style fields:
  - `ZTSMAppSystem-CriticalityProfile`
  - `ZTSMAppSystem-DataClassificationProfile`
  - `ZTSMAppSystem-ExposureProfile`
  - `ZTSMAppSystem-ServiceTier`
  - `ZTSMAppSystem-DefaultApprovalModel`
  - `ZTSMAppSystem-DefaultApprovalProfile`
- Added exported role defaults including `CMDB Backlinks` and `CMDB Description`.
- Enriched DynamicField Set members from the full DynamicFields export so fresh installs create nested Set fields such as `ZBlue-Chapter`, `ZBlue-PurpleBook`, and template risk fields with their real field types and config.
- Updated GovernanceDB bootstrap install/upgrade handling:
  - Class preferences now preserve exported multi-category definitions.
  - Class preferences now preserve exported `VersionTrigger` values.
  - DynamicField config sanitization strips source-environment `ZTSMStatusIDs`, matching existing protection for stale `DeplStateIDs`.
- Generated `Kernel/Package/GovernanceDB-0.0.103.opm`.
- `Kernel/Package/GovernanceDB-0.0.103.opm` SHA256: `4E1281BDF390D3BBF9B694112CA331A6E674FCCDB12106EAD52EFFA3B2FE0349`.

### Validation

- `Kernel/Package/GovernanceDB-0.0.103.opm`: XML parsed successfully, version `0.0.103`, 156 file nodes, `MissingBase64=0`, with `CodeInstall` and `CodeUpgrade`.
- `default_classes.json` parsed successfully with 21 classes and 21 roles.
- Confirmed new first-class classes are present: `CriticalityProfile`, `DataClassification`, `ExposureProfile`, `FunctionProfile`, and `ServiceTier`.
- Confirmed Application defaults contain the new GO-backed Application fields and no longer contain the old `ZTSMAppSystem-Criticality`, `ZTSMAppSystem-DataClassification`, or `ZTSMAppSystem-Tier` class fields.
- Confirmed nested Set definitions are enriched, for example `ZBlue-Chapter` is `Text` and `ZBlue-PurpleBook` is `GovernanceObject`.
- Perl syntax check passed with `perl -I. -IKernel\cpan-lib -c Kernel\Package\GovernanceDB\Kernel\System\GovernanceDB\Bootstrap.pm`.
- `git diff --check` reported only CRLF normalization warnings for touched files.

### Architectural Decisions

- The latest export is treated as the source for matching Governance Object class and role definitions.
- Existing package-only class and role entries are preserved by name for upgrade safety instead of destructively replacing the entire defaults file.
- Removed Application fields are not auto-deleted from existing upgraded systems; they are no longer present in fresh-install defaults, while upgrade cleanup can be handled separately if needed.
- Source-environment numeric status filters from exports must not be installed directly into another environment because those IDs are deployment-specific.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.103` package.
- Retest fresh install or upgrade and confirm the new classes, class fields, DynamicField Sets, and roles are created automatically.
- If existing environments should remove the old Application dropdown fields, add an explicit controlled cleanup/migration step rather than relying on defaults refresh.

### Next Priorities

- Install/upgrade 0.0.103, restart PSGI/web workers, and verify the refreshed GO classes and Application profile references in GovernanceDB admin/customer flows.

## 2026-06-22 Governance as Code YAML/JSON Foundation 0.0.104

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.104`.
- Added `Kernel::System::GovernanceObject::Document` as the first document-codec service for Governance as Code:
  - Exports Governance Objects as YAML or JSON document hashes.
  - Imports YAML or JSON documents through the existing `GovernanceObjectAdd` / `GovernanceObjectUpdate` APIs.
  - Preserves normal GOID generation for new objects unless a document identifies an existing object by number or unique class/name.
  - Resolves `ztsm_status` by GeneralCatalog name or ID.
  - Exports Dynamic Fields under a `fields` hash using existing field names only.
  - Resolves GovernanceObject and GovernanceObjectVersion reference fields by exact object name first, then GOID/number, then `ZTSM-Code` where available.
  - Allows explicit ID fallback with `Name::123` for reference fields.
  - Resolves GeneralCatalog Dynamic Field values by name before storing IDs.
  - Recurses into DynamicField Set rows so nested reference fields can be represented in editor-friendly YAML/JSON.
- Added agent popup module `AgentGovernanceObjectDocument` and template `AgentGovernanceObjectDocument.tt`.
- Added a `YAML/JSON` action to the Governance Object zoom menu.
- Registered the new agent frontend module and loader settings in `GovernanceDB.xml`.
- Added new module/template/service files to the authoritative SOPM file list.
- Generated `Kernel/Package/GovernanceDB-0.0.104.opm`.
- `Kernel/Package/GovernanceDB-0.0.104.opm` SHA256: `0734975E068546A6611E2CD4FEC096608CF4FD0F2799877E921B703217F779BB`.

### Validation

- `GovernanceDB.xml` parsed successfully as XML.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.104.opm`: XML parsed successfully, version `0.0.104`, 159 file nodes, `MissingBase64=0`.
- `git diff --check` passed.
- Perl syntax checks could not be run in the current desktop runtime because no `perl.exe` / `perl` executable is available.

### Architectural Decisions

- Governance as Code starts as a document-codec service rather than a one-off UI parser, so the same import/export rules can later be reused for ticket, CMDB, and integration surfaces.
- The codec delegates writes to existing GovernanceObject APIs to preserve versioning, history, link sync, DynamicField driver behavior, and generated GOIDs.
- Reference fields default to human/code resolution and only accept raw IDs through the explicit `::ID` escape form.
- The UI entry point is an editor-format popup from Governance Object zoom; the existing rendered UI remains unchanged.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is still needed in OTOBO using the generated `0.0.104` package.
- Runtime verification is needed that the `YAML/JSON` popup appears from Governance Object zoom for `governance-db` / `admin` users.
- Runtime verification is needed for import/update of Set fields that contain nested GovernanceObject references.
- Runtime verification is needed for reference resolution by unique name, GOID/number, `ZTSM-Code`, and explicit `Name::ID`.
- Perl syntax checks should be run inside the OTOBO Perl runtime before installation if available.

### Next Priorities

- Install/upgrade 0.0.104, restart PSGI/web workers, and test export/import against StateBook, BlueBook, ServiceSupportMap, and Application profile reference fields.
- Extend the same document-codec pattern to ticket and CMDB adapters after the Governance Object path is accepted.

## 2026-06-22 TESSERA Ticket CSV/XLSX Import Export 0.0.105

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.105`.
- Added `Kernel::System::TESSERA::TicketTable` as the first tabular ticket import/export service:
  - Exports selected tickets to CSV or XLSX using OTOBO's existing `Kernel::System::CSV` wrapper.
  - Uses the package/runtime-native `Excel::Writer::XLSX` writer for Excel export; no Python runtime prerequisite was introduced.
  - Exports the requested ticket table columns: `ticket_id`, `type`, `parent`, `title`, `description`, `application`, `environment`, `location`, `created_date`, `created_by`, `customer_data`, `ownergroup`, `owner`, `state`, `service`, and `service_payload`.
  - Maps TESSERA ownership and request context columns to existing custom ticket Dynamic Fields:
    - `parent` -> `ZTicket-Parent`
    - `application` -> `ZTicket-Application`
    - `environment` -> `ZTicket-Env`
    - `location` -> `ZTicket-Location`
    - `ownergroup` -> `ZTicket-OwnerGroup`
    - `owner` -> `ZTicket-Owner`
  - Exports `customer_data` as JSON with `customer_id` and `customer_user_id`.
  - Exports `service_payload` as JSON by reading the selected ticket service's `ZService-Field` configuration and collecting the matching ticket Dynamic Fields.
  - Imports CSV updates for existing tickets by `ticket_id`.
  - Imports title/type/state/service updates through OTOBO ticket APIs.
  - Imports TESSERA ticket context fields through Dynamic Field backend APIs.
  - Imports `customer_data` JSON through `TicketCustomerSet`.
  - Imports `service_payload` JSON only for fields declared by the ticket's selected service through `ZService-Field` when that declaration exists.
- Added agent module `AgentTicketTESSERATable` and template `AgentTicketTESSERATable.tt`.
- Registered `AgentTicketTESSERATable` in `ZTSMGovernanceRuntime.xml`.
- Added a `Table Export` link on agent ticket zoom for the current ticket.
- Added new module/template/service files to the authoritative SOPM file list.
- Generated `Kernel/Package/GovernanceDB-0.0.105.opm`.
- `Kernel/Package/GovernanceDB-0.0.105.opm` SHA256: `7D568B2130E81AFFE3F428E1B4A79BB51CBF346C2A40245426642788905C5AB1`.

### Validation

- `ZTSMGovernanceRuntime.xml` parsed successfully as XML.
- `GovernanceDB.sopm` parsed successfully as XML.
- SOPM file list check passed: 162 file nodes, no missing source files.
- `Kernel/Package/GovernanceDB-0.0.105.opm`: XML parsed successfully, version `0.0.105`, 162 file nodes, `MissingBase64=0`.
- `git diff --check` passed.
- Perl syntax checks could not be run in the current desktop runtime because no `perl.exe` / `perl` executable is available.

### Architectural Decisions

- CSV is the canonical import format for this package slice because OTOBO already ships reliable CSV parsing.
- XLSX is export-only for now because the package already includes a native Perl XLSX writer but no XLSX reader.
- Python was not introduced as a package prerequisite; adding Python or vendoring a Perl XLSX reader remains a later explicit decision if XLSX import becomes mandatory.
- `owner` and `ownergroup` intentionally use custom TESSERA fields `ZTicket-Owner` and `ZTicket-OwnerGroup`, not OTOBO owner or queue/group routing fields.
- Service payload stays generic by using `ZService-Field` as the service's field contract instead of hardcoding service-specific payload fields.
- Ticket import currently updates existing tickets by `ticket_id`; it does not create brand-new tickets because the requested column contract does not include all safe ticket creation defaults such as queue and priority.

### Known Issues / Follow-Up

- Superseded by `Kernel/Package/GovernanceDB-0.0.106.opm`; install/upgrade `0.0.106` instead because `0.0.105` kept ticket table export admin-oriented/current-ticket-oriented instead of providing access-scoped Ticket menu downloads.
- Perl syntax checks should be run inside the OTOBO Perl runtime before installation if available.
- Runtime verification is needed for CSV export/import on tickets with `ZTicket-Application`, `ZTicket-Env`, `ZTicket-Location`, `ZTicket-OwnerGroup`, and `ZTicket-Owner`.
- Runtime verification is needed for `service_payload` export/import using a service with populated `ZService-Field`.
- XLSX import is not implemented yet; add a reader dependency only if the operational workflow requires direct `.xlsx` imports.
- Ticket creation from CSV is not implemented yet; add it only after defining the required defaulting contract for queue, priority, article type/sender, and lifecycle-safe initialization.

### Next Priorities

- Install/upgrade 0.0.106, restart PSGI/web workers, and test ticket CSV export/import from the agent UI.
- Confirm the exported `service_payload` JSON matches the dynamic service fields shown in the customer request form.
- Decide whether CSV import is sufficient for governance integration workflows or whether XLSX import should be added with an explicit dependency plan.

## 2026-06-22 Access-Scoped Ticket Table Download Repair 0.0.106

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.106`.
- Reworked ticket table export/download so it is available from the agent Ticket menu, not only from a specific ticket zoom action.
- Added `Frontend::Navigation###AgentTicketTESSERATable###002-Ticket` so agents can open `Table Export` from the Ticket navigation area.
- Removed the admin/governance-db group restriction from `AgentTicketTESSERATable` module registration; export scope is now controlled by ticket permissions.
- Added access enforcement in `Kernel::System::TESSERA::TicketTable`:
  - Export checks `TicketPermission(Type => 'ro')` for every requested ticket.
  - Import checks `TicketPermission(Type => 'rw')` before updating a ticket.
  - Leaving the ticket ID list empty exports tickets returned by `TicketSearch(UserID => ..., Permission => 'ro')`, limited to 10,000 rows.
  - The search includes both archived and unarchived tickets through `ArchiveFlags => ['y', 'n']`.
- Updated the export form flow so opening from a specific ticket pre-fills that ticket ID, while clearing the field exports all readable tickets.
- Regenerated `Kernel/Package/GovernanceDB-0.0.106.opm`.
- `Kernel/Package/GovernanceDB-0.0.106.opm` SHA256: `C0CDEFEBD8EF98BAD24DA4884F00A51F5B840D710162EBD520ECBA1E2BAD3CEC`.

### Validation

- Found Strawberry Perl at `C:\Strawberry\perl\bin\perl.exe` and used it for syntax validation.
- Perl syntax checks passed:
  - `Kernel/Package/GovernanceDB/Kernel/System/TESSERA/TicketTable.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentTicketTESSERATable.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentGovernanceObjectDocument.pm`
- `ZTSMGovernanceRuntime.xml` parsed successfully as XML.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.106.opm`: XML parsed successfully, version `0.0.106`, 162 file nodes, `MissingBase64=0`.
- `git diff --check` passed.

### Architectural Decisions

- Ticket table download is an access-scoped utility: the user can only export tickets readable through OTOBO ticket permission logic.
- The Ticket menu export page is the broad download surface; the ticket zoom link remains a convenience entry point for one-ticket export.
- CSV import remains available through the same module but is protected by per-ticket `rw` checks.
- Direct database-wide export is intentionally avoided; "all" means "all tickets readable by this user".

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.106` package.
- Runtime verification is needed that the Ticket menu shows `Table Export` for normal agents.
- Runtime verification is needed that leaving Ticket IDs empty exports only tickets readable by the current agent.
- Runtime verification is needed that CSV import rejects tickets where the current agent lacks `rw`.

### Next Priorities

- Install/upgrade 0.0.106, restart PSGI/web workers, and test Table Export from both Ticket menu and ticket zoom.

## 2026-06-22 IPC-Only Ticket Table Import Gate 0.0.107

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.107`.
- Restricted ticket CSV import in `AgentTicketTESSERATable` to IPC authority only:
  - Users with `rw` permission on the `IPC` group can import.
  - Users assigned to the `IPC` role can import.
  - All other users are rejected before upload parsing or CSV update logic runs.
- Kept export/download access-scoped by ticket read permission; this remains available from the Ticket menu for users to download tickets they can read.
- Kept the existing per-ticket `rw` import checks in `Kernel::System::TESSERA::TicketTable`, so IPC import authority does not bypass ticket write permission.
- Hid the CSV import form from non-IPC users while preserving backend enforcement for direct POST attempts.
- Generated `Kernel/Package/GovernanceDB-0.0.107.opm`.
- `Kernel/Package/GovernanceDB-0.0.107.opm` SHA256: `61A2D357724F9241E1844B9F14C20B1555805E00F7722E1CB298D89305103EC3`.

### Validation

- Perl syntax checks passed:
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentTicketTESSERATable.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/TESSERA/TicketTable.pm`
- `ZTSMGovernanceRuntime.xml` parsed successfully as XML.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.107.opm`: XML parsed successfully, version `0.0.107`, 162 file nodes, `MissingBase64=0`.
- `git diff --check` could not be run in the current desktop runtime because `git.exe` is not available on PATH.

### Architectural Decisions

- Import is an IPC-controlled operation, while export remains an access-scoped download utility.
- IPC authority is resolved from existing OTOBO group/role configuration instead of introducing a package-owned permission object.
- IPC import authority is an additional gate; ticket-level `rw` permission still controls whether each row can update a ticket.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.107` package.
- Runtime verification is needed that IPC users see the import form and can import only tickets where they have `rw`.
- Runtime verification is needed that non-IPC users can still export readable tickets but cannot see or POST ticket import.

### Next Priorities

- Install/upgrade 0.0.107, restart PSGI/web workers, and test Table Export from both Ticket menu and ticket zoom.
- Test CSV import with an IPC user and a non-IPC user to confirm the permission split.

## 2026-06-22 Customer Service Payload Excel/CSV Import and Code View 0.0.108

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.108`.
- Added offline SheetJS `0.20.3` asset:
  - `var/httpd/htdocs/js/thirdparty/sheetjs-0.20.3/xlsx.full.min.js`
  - Asset SHA256: `CC015130AA8521E7F088F88898EBA949CCDCBFB38DF0BD129B44B7273C3A6F41`
- Extended the CustomerTicketMessage service payload workspace in `ZTSMCustomerTicketMessageServiceFields.tt`:
  - Added service payload `Import`, `Code`, and `Apply` controls.
  - Excel/CSV import populates currently rendered service dynamic fields without submitting the ticket.
  - DynamicField Set payloads can create additional rows before filling values.
  - Spreadsheet headers can use field names, labels, or `SetField.InnerField`.
  - Code view exports the current service payload as JSON and can apply edited JSON back into the rendered fields.
  - Select fields resolve imported names against visible option labels before falling back to raw values.
  - Reference/autocomplete fields resolve imported names through `AgentReferenceSearch` and write the hidden ID via the existing `Core.Agent.DynamicFieldReferenceSearch.AddTicketReference` path.
  - Explicit ID fallback remains available as `Name::123`.
- Synced the changed template across package source, runtime overlay, live template, and `ZTSMOverlay`.
- Generated `Kernel/Package/GovernanceDB-0.0.108.opm`.
- `Kernel/Package/GovernanceDB-0.0.108.opm` SHA256: `9C8C86D56AF92A4EA14B55A22DA3CB2EE04539E238CD8C1D6806A1FAC2E97FCC`.

### Validation

- `GovernanceDB.sopm` parsed successfully as XML.
- `ZTSMGovernanceRuntime.xml` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.108.opm`: XML parsed successfully, version `0.0.108`, 163 file nodes, `MissingBase64=0`.
- Perl syntax checks passed:
  - `Kernel/Package/GovernanceDB/Kernel/Modules/CustomerTicketMessage.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentTicketTESSERATable.pm`
- Embedded service payload JavaScript parsed successfully with Node after stripping Template Toolkit tags.
- `git diff --check` passed using the bundled Git runtime.
- Template sync hashes matched across package source, runtime overlay, live template, and `ZTSMOverlay`.

### Architectural Decisions

- Spreadsheet import is a client-side prefill tool, not a ticket submit path.
- Service payload import operates on the existing dynamic service fields generated from `ZService-Field`, so it remains generic across services.
- DynamicField Set import treats each spreadsheet row as one set row where a set field is present.
- Name/label resolution is preferred for user-facing import; raw IDs are only accepted through the explicit `::ID` fallback.
- SheetJS is vendored offline because runtime environments may not have internet access.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.108` package.
- Runtime verification is needed for `.xlsx` and `.csv` import on a service whose `ZService-Field` contains both simple fields and DynamicField Set fields.
- Runtime verification is needed for GovernanceObject/reference field resolution by name and explicit `::ID`.
- Date and DateTime fields should be tested with the expected spreadsheet date format; the current client mapper primarily fills rendered controls by field name/label.

### Next Priorities

- Install/upgrade 0.0.108, restart PSGI/web workers, and test CustomerTicketMessage service payload import before ticket submit.
- Prepare a sample service payload spreadsheet for one real service with DynamicField Set rows and reference names.

## 2026-06-23 Runtime Default Prerequisites 0.0.109

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.109`.
- Added package-owned runtime seed exports under `var/governancedb/runtime_seed/`:
  - `generic_agents.yml`
  - `ztsm-activity-lifecycle-orchestration.yml`
  - `ztsm-ticket-lifecycle-orchestration.yml`
- Extended `GovernanceDB::Bootstrap->InstallDefaults()` with idempotent runtime prerequisite seeding for install and upgrade:
  - Ticket states used by GovernanceDB runtime actions and process exports, including approval, assessment, support, verification, follow-up, on-hold, neutral closure, rollback, duplicate, no-action, cancelled/canceled, cascaded/cascading, and success/failure closure states.
  - Ticket types used by parent and child execution flows, including `ServiceRequest`, `Task`, `Assessment`, `Endorsement`, `Approval`, `Implementation`, and `Verification`.
  - Default GovernanceRole objects, including requester, assessor, endorser, approver, implementer, verifier, support, and escalation roles.
  - Default runtime process exports when active processes of the same name do not already exist.
  - Default GenericAgent jobs with state/type names resolved to IDs during bootstrap.
- Updated the GenericAgent role lookup seed to include `Implementation` activity tickets.
- Generated `Kernel/Package/GovernanceDB-0.0.109.opm`.
- `Kernel/Package/GovernanceDB-0.0.109.opm` SHA256: `684DA53D7F6F0704D904F0FD117447EC8D9AA9CBB0D2C38ADD7ECACB950F7562`.

### Validation

- `Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm` passed Perl syntax check.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.109.opm` parsed successfully as XML.
- Runtime seed YAML files parsed successfully:
  - `generic_agents.yml`
  - `ztsm-activity-lifecycle-orchestration.yml`
  - `ztsm-ticket-lifecycle-orchestration.yml`
- `Kernel/Package/GovernanceDB-0.0.109.opm`: version `0.0.109`, 166 file nodes, `MissingBase64=0`.
- `git diff --check` passed.

### Architectural Decisions

- Runtime prerequisite seeding is centralized in `GovernanceDB::Bootstrap` so fresh installs, upgrades, and reinstalls share the same idempotent path.
- Existing states, types, processes, jobs, and GovernanceRole objects are preserved where possible and repaired only for validity or expected metadata.
- GovernanceRole defaults are seeded as Governance Objects, not as hardcoded workflow routing.
- Runtime process imports are skipped when an active process with the same name already exists, avoiding accidental overwrite of configured process definitions.
- GenericAgent jobs are rebuilt by name from the package seed so referenced states and types resolve against the deployed environment.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.109` package.
- Confirm whether the historical `ServiceRequest` process should also become a package seed; it was not added because it is not part of the current GovernanceDB lifecycle export pair.
- Confirm real environment GovernanceRole class/status naming if a site has renamed the default GeneralCatalog entries.

### Next Priorities

- Install/upgrade 0.0.109, restart PSGI/web workers, and confirm the default state, type, GenericAgent, process, and GovernanceRole records are present.
- Exercise parent `ServiceRequest` orchestration and child `Assessment`/`Endorsement`/`Approval`/`Implementation`/`Verification` creation on a fresh environment.

## 2026-06-23 Governance as Code Converted Object Edit Fix 0.0.110

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.110`.
- Added a compatibility guard in the DynamicField Set driver for converted governance objects whose nested child field definitions reference `GeneralCatalog` without a `Config->{Class}`.
- Applied the Set driver guard to both the live source and GovernanceDB runtime overlay:
  - `Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm`
- Updated the Governance as Code YAML/JSON document template so `Cancel & close` and bottom `Cancel` navigate back to the object zoom page or overview when the screen is opened as a normal page rather than a popup.
- Generated `Kernel/Package/GovernanceDB-0.0.110.opm`.
- `Kernel/Package/GovernanceDB-0.0.110.opm` SHA256: `FDF0529F5C6B760D6FB8EC66A698C9D9B13ADF02D39E6C9A7532CE5BB706F3CE`.

### Validation

- Perl syntax checks passed:
  - `Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentGovernanceObjectDocument.pm`
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.110.opm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.110.opm`: version `0.0.110`, 166 file nodes, `MissingBase64=0`.
- `git diff --check` passed.

### Architectural Decisions

- The missing GeneralCatalog class condition is handled as a compatibility fallback for converted object definitions, not as a mutation of stored governance definitions.
- Converted nested GeneralCatalog child definitions without a class are treated as text-like display/edit configs so existing stored values remain visible and edit screens do not call GeneralCatalog with an undefined class.
- Governance as Code cancel navigation must work from a main browser tab as well as from popup launch contexts.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.110` package.
- Verify zoom and edit for converted BlueBook and StateBook objects after installing `0.0.110` and restarting PSGI/web workers.
- Consider a future controlled migration to repair converted child field definitions with the intended GeneralCatalog `Class` values once the authoritative mappings are confirmed.

### Next Priorities

- Install/upgrade `0.0.110`, restart PSGI/web workers, and retest `AgentGovernanceObjectZoom` and `AgentGovernanceObjectEdit` for the failing converted object.
- Retest Governance as Code YAML/JSON format switching and cancel links from both normal-page and popup launch contexts.

## 2026-06-23 Governance as Code Direct YAML/JSON Import 0.0.111

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.111`.
- Added a list-level `Import YAML/JSON` action to the Governance Object overview action row.
- Fixed `AgentGovernanceObjectDocument` so the document editor can open without an existing `GovernanceObjectID`, allowing users to paste YAML or JSON directly and create/update the target Governance Object from the document content.
- Hardened `Kernel::System::GovernanceObject::Document->Import()` permission handling:
  - Updates require `rw` permission on the resolved existing Governance Object.
  - Creates require `rw` permission on the resolved Governance Object class.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.111.opm`.
- `Kernel/Package/GovernanceDB-0.0.111.opm` SHA256: `8F1521184FE33D3A6337A70680B06CA817482402CD5AD1AB77AD8B009AC52631`.

### Validation

- Perl syntax checks passed:
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentGovernanceObjectDocument.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Output/HTML/GovernanceObject/OverviewSmall.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm`
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.111.opm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.111.opm`: version `0.0.111`, 166 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM includes the updated document controller, document import backend, overview action renderer, and overview template.
- `git diff --check` passed.

### Architectural Decisions

- Governance as Code must be a full edit loop: export from an object, edit YAML/JSON, and import directly from the Governance Object overview without first opening or manually creating a target object.
- The document import path continues to use the existing GovernanceObject add/update APIs so GOID, versioning, history, field drivers, and link sync remain authoritative.
- Import authorization is enforced in the document backend because direct document imports may resolve the target object from `number` or `name` instead of from a URL parameter.
- Direct import does not introduce new field names or a parallel storage model; it consumes the existing document schema and existing Governance Object definitions.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.111` package.
- Verify that the overview `Import YAML/JSON` action opens a blank Governance as Code editor from the Governance Object list.
- Verify YAML and JSON imports for:
  - Creating a new Governance Object where the current agent has class `rw`.
  - Updating an existing Governance Object resolved by `number`.
  - Rejecting updates/creates where the current agent lacks `rw` permission.

### Next Priorities

- Install/upgrade `0.0.111`, restart PSGI/web workers, and test the full Governance as Code loop from overview import through object zoom/edit.
- Retest converted BlueBook/StateBook YAML imports that contain DynamicField Set values and GeneralCatalog names.

## 2026-06-23 General Catalog as Code 0.0.112

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.112`.
- Added `Kernel::System::GeneralCatalog::Document` as a YAML/JSON document codec for General Catalog classes, items, validity, comments, and preferences.
- Added `AgentGeneralCatalogDocument` and `AgentGeneralCatalogDocument.tt` as an agent-facing import/export screen.
- Added a `General Catalog YAML/JSON` action to the Governance Object overview action row.
- Registered the new module and loader settings in `GovernanceDB.xml`, restricted to the same `governance-db` and `admin` access groups as the Governance Object document editor.
- Added the new module, backend, and template files to the GovernanceDB SOPM filelist.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.112.opm`.
- `Kernel/Package/GovernanceDB-0.0.112.opm` SHA256: `4DE98AF0B6527E0261420F86D1940E8C32CB16F304C050B2FFB47D51A59E0CAB`.

### Validation

- Perl syntax checks passed:
  - `Kernel/Package/GovernanceDB/Kernel/System/GeneralCatalog/Document.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentGeneralCatalogDocument.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Output/HTML/GovernanceObject/OverviewSmall.pm`
- `GovernanceDB.sopm` parsed successfully as XML.
- `GovernanceDB.xml` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.112.opm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.112.opm`: version `0.0.112`, 169 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM includes the General Catalog document module, backend codec, template, overview action renderer, and SysConfig registration.
- `git diff --check` passed.

### Architectural Decisions

- General Catalog is treated as part of Governance as Code because GovernanceDB dynamic fields and runtime books depend on named catalog classes and items.
- The document schema exports catalog names and validity names instead of deployment-specific IDs.
- Imports are idempotent by `class + name`: existing items are updated, missing items are added, and preferences are rewritten through the existing General Catalog preferences API.
- The first UI entry point lives in the Governance Object overview action row so governance object YAML/JSON and General Catalog YAML/JSON are operated from the same governance maintenance surface.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.112` package.
- Verify export/import for core GovernanceDB catalog classes such as:
  - `ZTSM::GovernanceObject::Class`
  - `ZTSM::GovernanceObject::Status`
  - `ZTSM::GovernanceObject::Class::Category`
  - Governance role/status/catalog classes used by BlueBook and StateBook fields.
- Confirm whether a later enhancement should support class rename/deprecation operations; `0.0.112` intentionally uses non-destructive add/update by class and item name.

### Next Priorities

- Install/upgrade `0.0.112`, restart PSGI/web workers, and test `General Catalog YAML/JSON` from the Governance Object overview.
- Export a focused set of GovernanceDB catalog classes, import into a clean target environment, then import Governance Object YAML/JSON that references those catalog names.

## 2026-06-23 Governance YAML Set Blank Reference Fix 0.0.113

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.113`.
- Updated `Kernel::System::GovernanceObject::Document->_SetValueFromDocument()` so imported DynamicField Set rows explicitly write blank values for:
  - child fields omitted from YAML/JSON
  - child fields present as YAML null (`~`)
- Rebuilt `Kernel/Package/GovernanceDB-0.0.113.opm`.
- `Kernel/Package/GovernanceDB-0.0.113.opm` SHA256: `93D1FF71FBB53A51DB8DA8483D00AD502786B5F37688B2A67C24D70834FF9E85`.

### Validation

- `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm` passed Perl syntax check.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.113.opm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.113.opm`: version `0.0.113`, 169 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM includes `Kernel/System/GovernanceObject/Document.pm`.
- `git diff --check` passed.

### Architectural Decisions

- Missing or null fields in a Governance as Code Set row mean empty, not "choose the first selectable reference".
- The importer now makes that intent explicit before the DynamicField Set edit widget renders the row.
- This keeps constrained reference fields such as BlueBook Role, Template, Follow-up, Ticket Type, and similar child fields from being silently populated by UI defaults when the YAML did not define them.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.113` package.
- Retest importing a BlueBook YAML row where only `ZBlue-Profile` is set and `ZBlue-Role`, `ZBlue-Template`, and `ZBlue-Follow-up` are omitted.

### Next Priorities

- Install/upgrade `0.0.113`, restart PSGI/web workers, and verify omitted/null Set child fields render blank in edit and zoom screens.

## 2026-06-23 Governance Reference Filter and General Catalog Admin Import 0.0.114

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.114`.
- Restored constrained reference behavior for converted BlueBook Set child fields:
  - `ZBlue-Profile` and `ZBlue-Role` are restricted to `GovernanceRole`.
  - `ZBlue-Template` is restricted to `Template`.
  - `ZBlue-PurpleBook` / Follow-up is restricted to `BlueBook`.
  - `ZBlue-TicketType` is restored as a GeneralCatalog field using `ZTSM::GovernanceObject::Class`.
- Updated `default_classes.json` so fresh install and package upgrade repair the affected child DynamicField configs.
- Added runtime compatibility fallback in the DynamicField Set driver so already-bad converted configs do not render all Governance Object classes while the upgraded config is being repaired.
- Updated Governance Object YAML/JSON import resolution so Set child references use the same restrictions during name lookup.
- Added `Import / Export YAML/JSON` to the Admin General Catalog action panel and packaged `AdminGeneralCatalog.tt`.
- Updated `AgentGeneralCatalogDocument` so launch from Admin General Catalog returns to `AdminGeneralCatalog` on cancel instead of Governance Object overview.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.114.opm`.
- `Kernel/Package/GovernanceDB-0.0.114.opm` SHA256: `497CD868C73FEF885AFA04F057AB34BD1E6AAC45425E70CFE4A64A4B8CB0B807`.

### Validation

- Perl syntax checks passed:
  - `Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentGeneralCatalogDocument.pm`
- `var/governancedb/default_classes.json` parsed successfully as JSON.
- `GovernanceDB.sopm` parsed successfully as XML.
- `GovernanceDB.xml` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.114.opm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.114.opm`: 170 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM includes the Admin General Catalog template, General Catalog document controller/template/backend, Governance Object document importer, Set runtime overlay, and default class definitions.
- `git diff --check` passed with only the existing line-ending warning for `default_classes.json`.

### Architectural Decisions

- `ZBlue-TicketType` represents the intended governance execution class, so it is backed by `ZTSM::GovernanceObject::Class` catalog values such as `Assessment`, `Approval`, `Implementation`, `Task`, and `Verification`.
- BlueBook child reference filters are treated as package defaults and runtime compatibility guards because converted Set children can exist in deployed environments with empty configs.
- General Catalog as Code belongs directly on the General Catalog admin surface, while still reusing the existing `AgentGeneralCatalogDocument` import/export module.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.114` package.
- After upgrade, restart PSGI/web workers and retest BlueBook edit:
  - Role/Profile dropdowns should show only GovernanceRole objects.
  - Template dropdown should show Template objects only.
  - Follow-up dropdown should show BlueBook objects only.
  - Ticket Type should select from Governance Object class catalog entries, not remain empty or resolve through a wrong Governance Object class.
- Retest Admin General Catalog > Import / Export YAML/JSON for export, import, and cancel return behavior.

## 2026-06-23 General Catalog Package Conflict Fix 0.0.115

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.115`.
- Removed `Kernel/Output/HTML/Templates/Standard/AdminGeneralCatalog.tt` from the GovernanceDB package filelist because it is owned by `GeneralCatalog-11.0.10` and causes package install/upgrade conflicts.
- Replaced the Admin General Catalog template override with package-owned loader JavaScript:
  - `var/httpd/htdocs/js/Core.Agent.Admin.GeneralCatalogDocument.js`
- Added `Loader::Module::AdminGeneralCatalog###002-GovernanceDBGeneralCatalogDocument` to load the JS on `AdminGeneralCatalog`.
- The JS injects the `Import / Export YAML/JSON` action into the existing Admin General Catalog action list and links to `AgentGeneralCatalogDocument;ReturnAction=AdminGeneralCatalog`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.115.opm`.
- `Kernel/Package/GovernanceDB-0.0.115.opm` SHA256: `D57CECEF819CD054AC07D74BC4FE57D49FE7BA04F7DC53BDD91706A9EAC3A0CC`.

### Validation

- `GovernanceDB.sopm` parsed successfully as XML.
- `GovernanceDB.xml` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.115.opm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.115.opm`: 170 file nodes, `MissingBase64=0`.
- Confirmed generated OPM does not include `Kernel/Output/HTML/Templates/Standard/AdminGeneralCatalog.tt`.
- Confirmed generated OPM includes `var/httpd/htdocs/js/Core.Agent.Admin.GeneralCatalogDocument.js`.
- `git diff --check` passed with only the existing line-ending warning for `default_classes.json`.

### Architectural Decisions

- GovernanceDB must not ship files owned by the GeneralCatalog package.
- Admin General Catalog integration should be extension-based through loader JS, not a template replacement.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.115` package.
- After upgrade and cache rebuild/restart, verify the Admin General Catalog action list shows `Import / Export YAML/JSON`.

## 2026-06-23 GovernanceDB General Catalog Seed 0.0.116

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.116`.
- Added `var/governancedb/default_general_catalog.yml` as a GovernanceDB-owned GeneralCatalog seed.
- The seed is trimmed to GovernanceDB-owned or GovernanceDB-referenced catalog classes, avoiding the full stock ITSM GeneralCatalog set:
  - `ZTSM::GovernanceObject::Class`
  - `ZTSM::GovernanceObject::Category`
  - `ZTSM::GovernanceObject::Class::Category`
  - `ZTSM::GovernanceObject::Definition`
  - `ZTSM::GovernanceObject::Role`
  - `ZTSM::GovernanceObject::Status`
  - `ZRM::Impact`
  - `ZRM::ImpactCategory`
  - `ZRM::Likelihood`
  - `ZRM::RiskCategory`
- Updated `Kernel::System::GovernanceDB::Bootstrap->InstallDefaults()` to import the seed via `Kernel::System::GeneralCatalog::Document` during install and upgrade.
- The seed import is idempotent by catalog class and item name, so existing rows are updated and missing rows are added without duplicate catalog records.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.116.opm`.
- `Kernel/Package/GovernanceDB-0.0.116.opm` SHA256: `09AD0B6D28EC6D4CDF007DBB39901E5388BFE691E6D7DFF803D587C6C50E8976`.

### Validation

- `Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm` passed Perl syntax check.
- `var/governancedb/default_general_catalog.yml` parsed successfully as YAML and contains 10 catalog classes.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.116.opm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.116.opm`: 171 file nodes, `MissingBase64=0`.
- Confirmed generated OPM includes:
  - `var/governancedb/default_general_catalog.yml`
  - `var/governancedb/default_classes.json`
  - `Kernel/System/GovernanceDB/Bootstrap.pm`
  - `Kernel/System/GeneralCatalog/Document.pm`
- `git diff --check` passed with only the existing line-ending warning for `default_classes.json`.

### Architectural Decisions

- GovernanceDB package installation must not depend on the stock ITSM GeneralCatalog default set being enabled.
- GovernanceDB should seed only the catalog classes it owns or directly references, so disabled ITSM catalog defaults are not silently reintroduced.
- GeneralCatalog seeding runs before class definition/dynamic-field repair so references such as Governance Object class filters and ZRM risk score catalogs can resolve during bootstrap.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.116` package.
- After upgrade, verify General Catalog contains the seeded GovernanceDB and ZRM classes/items before importing Governance Object YAML/JSON.

## 2026-06-23 BlueBook Ticket Type Catalog Correction 0.0.117

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.117`.
- Corrected converted BlueBook `ZBlue-TicketType` child field configuration from `ZTSM::GovernanceObject::Class` to the intended GeneralCatalog class `ZTSM::Type`.
- Applied the same `ZTSM::Type` fallback to:
  - `Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm`
- Added `ZTSM::Type` to `var/governancedb/default_general_catalog.yml` so BlueBook ticket type values such as `Assessment`, `Approval`, `Endorsement`, `Task`, `Verification`, and `ServiceRequest` are seeded during install/upgrade.
- Updated `AgentGovernanceObjectEdit.tt` so `Cancel & close` and bottom `Cancel` navigate back to the Governance Object zoom page when the edit screen is opened in a normal browser tab.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.117.opm`.
- `Kernel/Package/GovernanceDB-0.0.117.opm` SHA256: `28044E235486FB84E711E3682E1B86F618478B17B724BAF43C94C7EC8CB652A5`.

### Validation

- Perl syntax checks passed:
  - `Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm`
  - `Kernel/Package/GovernanceDB/Kernel/Modules/AgentGovernanceObjectEdit.pm`
- `GovernanceDB.sopm` parsed successfully as XML.
- `var/governancedb/default_classes.json` parsed successfully and `ZBlue-TicketType` resolves to `ZTSM::Type`.
- `var/governancedb/default_general_catalog.yml` parsed successfully and includes `ZTSM::Type`.
- `Kernel/Package/GovernanceDB-0.0.117.opm` parsed successfully: version `0.0.117`, 171 file nodes, `MissingBase64=0`.
- Confirmed generated OPM includes the corrected `default_classes.json`, `default_general_catalog.yml`, edit template, Document importer, and runtime Set overlay.
- `git diff --check` passed with only the existing line-ending warning for `default_classes.json`.

### Architectural Decisions

- BlueBook `Ticket Type` is a ticket execution type and must use GeneralCatalog `ZTSM::Type`.
- Governance Object class catalog values remain for object classification and should not be reused as BlueBook ticket type choices.
- Edit cancel links must work when Governance Object edit is opened as a full page, not only in popup contexts.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.117` package.
- After upgrade, clear cache/restart web workers and verify BlueBook edit shows ticket types from `ZTSM::Type`, not Governance Object classes.
- Verify existing BlueBook YAML imports with omitted ticket type still leave the field blank, while explicit values resolve against `ZTSM::Type`.

## 2026-06-23 BlueBook Reference Empty Option Preservation 0.0.118

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.118`.
- Rechecked `Export/ALL_DynamicFields_2026-06-19 06_28_14.yml` for the original BlueBook DynamicField design.
- Preserved the exported BlueBook nested Set reference behavior in `var/governancedb/default_classes.json`:
  - `ZBlue-Profile`: `MultiValue=0`, `PossibleNone=0`
  - `ZBlue-Role`: `MultiValue=0`, `PossibleNone=1`
  - `ZBlue-TicketType`: `Class=ZTSM::Type`, `MultiValue=0`, `PossibleNone=0`
  - `ZBlue-Template`: `MultiValue=0`, `PossibleNone=1`
  - `ZBlue-PurpleBook`: `MultiValue=0`, `PossibleNone=1`
- Updated the converted-field compatibility repair so class restrictions no longer force optional fields to become mandatory:
  - `Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm`
- Rebuilt `Kernel/Package/GovernanceDB-0.0.118.opm`.
- `Kernel/Package/GovernanceDB-0.0.118.opm` SHA256: `DCEE62A0EACBB19619133F6CC7508BFC862791946CE034EB6DEB6B77D1E1314A`.

### Validation

- Perl syntax checks passed:
  - `Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm`
  - `Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm`
- Validated `default_classes.json` against the exported BlueBook field settings for `MultiValue`, `PossibleNone`, and `ZBlue-TicketType` class.
- `Kernel/Package/GovernanceDB-0.0.118.opm` parsed successfully: version `0.0.118`, 171 file nodes, `MissingBase64=0`.
- Confirmed generated OPM includes the corrected BlueBook Set child field configs and runtime compatibility repair.
- `git diff --check` passed.

### Architectural Decisions

- Class restriction and empty-option behavior are independent field decisions.
- `ZBlue-Template`, `ZBlue-PurpleBook`, and `ZBlue-Role` must remain optional single-value references.
- `ZBlue-Profile` and `ZBlue-TicketType` remain required single-value fields.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.118` package.
- After upgrade, verify BlueBook edit allows blank Template, Follow-up/PurpleBook, and Role values while preserving their class-restricted dropdowns.

## 2026-06-24 Customer Service Payload Import UI Clarity 0.0.119

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.119`.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt` service payload controls:
  - Replaced the large ambiguous `Import`, `Code`, and `Apply` buttons with a compact right-aligned toolbar.
  - Added a universal upload icon button for CSV/XLSX service payload import.
  - Added a JSON/code icon button that toggles the full service payload JSON editor.
  - Shows `Apply JSON` only while the JSON editor is open.
  - Added button titles and ARIA labels so users can understand the controls without guessing from the icon alone.
- Synced the template across live source, package source, runtime overlay, and ZTSMOverlay copies.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.119.opm`.
- `Kernel/Package/GovernanceDB-0.0.119.opm` SHA256: `5D209A6D69E4991E7FD255EB5B1E794281F7F8879468EAF52EA7F2AD3C984B0E`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `7C6751E3E3AF24A214ED21FB86863798D4C918452ED079C49FFF58F95D792F44`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.119.opm` parsed successfully as XML: version `0.0.119`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay template hash.
- `git diff --check` passed.

### Architectural Decisions

- Service payload import remains generic over the existing rendered `ZService-Field` dynamic fields.
- This change is presentation-only; it does not introduce new Dynamic Fields or alter service payload import/application semantics.
- JSON view is treated as a secondary inspection/edit mode, not the default interaction surface.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.119` package.
- Verify in `CustomerTicketMessage` that the upload icon sits beside the DynamicField Set row controls cleanly and that the JSON editor does not overlap the service payload form.

## 2026-06-24 Customer Service Payload Download Template 0.0.120

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.120`.
- Added a service payload template download button beside the existing payload upload and JSON controls.
- The downloaded template is generated from the currently rendered service payload fields for the selected service:
  - XLSX output when the bundled SheetJS library is available.
  - CSV fallback if SheetJS is not loaded.
  - `Template` sheet contains the importable column headers and a blank data row.
  - `Instructions` sheet lists each column header, field label, Dynamic Field name, payload group, required flag, and accepted value style.
- Nested DynamicField Set fields use import-compatible headers such as `SetName.FieldName`.
- Supersedes `0.0.119`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.120.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.120.opm`.
- `Kernel/Package/GovernanceDB-0.0.120.opm` SHA256: `2DDD534E5A6FE4965D2FCD3B56309FAFC3ED5C2F28BB8A4FF03E4FA0B5B98591`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `A44E56C3D51712D7FC5056BF48722A6BD6FCBD440522F8E728306EB05282CE53`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.120.opm` parsed successfully as XML: version `0.0.120`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay template hash.
- `git diff --check` passed.

### Architectural Decisions

- The template is generated client-side from the service-specific rendered form, keeping the import contract aligned with `ZService-Field`.
- No new Dynamic Fields, backend routes, or storage behavior were introduced.
- Template download is treated as companion guidance for import, not a separate governance document format.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.120` package.
- Verify the downloaded XLSX template opens cleanly and that filling its `Template` sheet can be imported back into the same service payload form.

## 2026-06-24 Customer Service Payload Name Export 0.0.121

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.121`.
- Updated service payload JSON/template export collection so human-readable names are emitted instead of opaque internal IDs:
  - Dropdown fields export selected option text, such as the environment or application name, instead of values like `11` or `1`.
  - Reference/autocomplete fields export the visible name from the control instead of the hidden reference ID.
  - Checkbox export now reflects checked state as `1` or blank.
- Imports remain backward-compatible because existing import logic still accepts:
  - dropdown option text or value
  - reference name or explicit `Name::ID`
- Supersedes `0.0.120`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.121.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.121.opm`.
- `Kernel/Package/GovernanceDB-0.0.121.opm` SHA256: `6AE07A828EB2239797D099DB969648E8F7A26DA1C174C0305E6C0E7E0B3A06D5`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `803155FE8FD95C90A8ED0991101DECA4D15A9E233E5377698BA9755157A83E4A`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.121.opm` parsed successfully as XML: version `0.0.121`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay template hash.
- `git diff --check` passed.

### Architectural Decisions

- Service payload code/export views must be operator-readable and portable, so they should prefer names over deployment-local numeric IDs.
- Numeric IDs remain accepted on import for compatibility and advanced troubleshooting, but generated guidance should use full names for resolution.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.121` package.
- Verify the JSON code view shows full names for `ZTicket-Env`, `ZTicket-Application`, firewall environment fields, and similar dropdown/reference fields.

## 2026-06-24 Customer Service Payload Toolbar Visual Hierarchy 0.0.122

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.122`.
- Redesigned the customer service payload JSON/template toolbar so it behaves as a secondary power-user utility:
  - Removed `CallForAction` from the payload toolbar buttons so they no longer render as large blue primary actions.
  - Replaced them with compact 30px icon-only buttons for download template, upload template, view JSON, and apply JSON.
  - Kept tooltip and ARIA labels for discoverability.
  - Kept the toolbar right-aligned above the service-specific payload fields.
  - Added pressed-state feedback to the JSON toggle only while the editor is open.
- Reduced JSON editor visual weight:
  - Hidden by default.
  - Shows only after clicking the JSON icon.
  - Preserves existing JSON text when collapsed.
  - Constrained to a scrollable 120px minimum / 180px maximum height.
- Supersedes `0.0.121`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.122.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.122.opm`.
- `Kernel/Package/GovernanceDB-0.0.122.opm` SHA256: `0FF688D54B7EB40B7BA329C23C5D81DD1AAB0E7CC7D3949405292FAFC4EFA3F0`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `7A4FA4BCA545CDF5E3AB4DA602AD11725AF94306110E03AA316DFF7AFFFDD201`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.122.opm` parsed successfully as XML: version `0.0.122`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay template hash.
- `git diff --check` passed.

### Architectural Decisions

- The request form remains the primary portal interaction; JSON/template actions are advanced utilities and must not visually compete with service fields.
- JSON editor exposure uses progressive disclosure rather than occupying vertical space by default.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.122` package.
- Verify visually that the toolbar stays compact on desktop and mobile and that the JSON editor does not push the service request fields too far down when opened.

## 2026-06-24 Floating Service Payload Utility Toolbar 0.0.123

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.123`.
- Redesigned the customer service payload JSON/template tools as a floating utility component:
  - Removed the toolbar from the request form flow entirely.
  - The utility rail is appended to `document.body`, fixed to the right side of the viewport, and remains visible while scrolling.
  - The rail uses compact vertical icon buttons for download template, upload template, view JSON, and apply JSON.
  - The rail uses custom styling, semi-transparent background, soft shadow, hover movement, and tooltip/ARIA labels.
  - The rail no longer uses `CallForAction` or inherited large blue theme button styling.
- Redesigned JSON editing as an overlay side drawer:
  - Clicking the JSON icon opens a fixed right-side `JSON Template Editor` drawer.
  - The drawer overlays the page and does not push request fields downward or reserve form space.
  - The drawer includes close/cancel and apply controls.
  - The JSON draft is preserved when the drawer is closed and reopened.
  - First open still populates the editor from the currently rendered service payload form.
- Added a small transient status chip attached to the floating rail for download/import/apply feedback without re-entering the form layout.
- Preserved all existing service payload behavior:
  - template download
  - template upload/import
  - JSON collect/view
  - JSON apply
  - name-based export for dropdown/reference fields
  - backward-compatible import of names or internal values
- Supersedes `0.0.122`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.123.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.123.opm`.
- `Kernel/Package/GovernanceDB-0.0.123.opm` SHA256: `1CA4AADADED037DDAADEB1AB47CFB53BCF01DC5721F8EE807F4B0290AE21485F`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `3E57AC769935452C8DC27A3627FE30BEB7582A4C78F5DEAF76F8E05579D3E986`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.123.opm` parsed successfully as XML: version `0.0.123`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay template hash.
- `git diff --check` passed.

### Architectural Decisions

- Template import/export and raw JSON editing are power-user utilities, not part of the normal request workflow.
- JSON/template controls must not be rendered between business request fields or consume form height.
- Overlay utility presentation is preferred here because it preserves portal-first request completion while keeping advanced functions available.

### Rejected Approaches

- Do not keep the compact toolbar inside the request form just because it is small.
- Do not expand the JSON editor inline under the rich text or service fields.
- Do not rely on large theme button styling for advanced payload utilities.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.123` package.
- Verify visually that the rail does not collide with the customer portal side toggle, scrollbar, or mobile viewport.
- Verify that the JSON drawer overlays the form cleanly and that cancel/close preserves the JSON draft.

## 2026-06-24 Service Payload JSON Apply Resolution Fix 0.0.124

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.124`.
- Fixed JSON apply/import resolution for human-readable payload values generated by the JSON view:
  - `Environment: PROD` resolves as `PROD`.
  - `Application: ICA-ADFS` resolves as `ICA-ADFS`.
  - `Location: LDC` resolves as `LDC`.
  - Explicit `Name::ID` values remain supported.
  - `-` is treated as blank for import so it does not accidentally resolve to the first reference search result.
- Tightened autocomplete/reference resolution:
  - Exact normalized matches are accepted.
  - Existing hidden reference IDs are cleared when no match is found.
  - The importer no longer falls back to the first reference search result for unresolved values.
- Widened the floating JSON drawer from 460px to 760px maximum and increased its vertical usable area.
- Supersedes `0.0.123`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.124.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.124.opm`.
- `Kernel/Package/GovernanceDB-0.0.124.opm` SHA256: `44A3CB09E3EED1804E49320E4026BE5A0DA2EFFA7211ED3EE11456BEF6D9E4F0`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `A49E8435359F631FBA83F64B180EF729B0A26E9B4D3A7D5CA032F710E6DB3D66`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- Import value normalization test confirmed:
  - `Environment: PROD` -> `PROD`
  - `Application: ICA-ADFS` -> `ICA-ADFS`
  - `Location: LDC` -> `LDC`
  - `-` -> blank
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.124.opm` parsed successfully as XML: version `0.0.124`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay template hash.
- `git diff --check` passed.

### Architectural Decisions

- Generated JSON should stay readable for operators, but apply/import must normalize display labels back to resolvable values before touching Dynamic Fields.
- Import must not use a first-result fallback for reference fields because that can silently select the wrong governance object.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.124` package.
- Verify JSON apply changes top-level Environment/Application fields and nested Firewall Policy Rule Environment/Application-like reference fields when payload values include display prefixes.
- Verify blank/dash reference values clear the visible chip and hidden reference ID rather than selecting the first result.

## 2026-06-24 Service Payload Reference Apply Refresh 0.0.125

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.125`.
- Tightened JSON apply for reference/autocomplete Dynamic Fields after runtime testing still showed unchanged visible chips:
  - Added a local reference setter that updates both the hidden reference ID field and the visible autocomplete value.
  - The setter also calls OTOBO `Core.Agent.DynamicFieldReferenceSearch.AddTicketReference()` when available.
  - Explicit `Name::ID` imports now use the same reference setter path.
  - Reference resolution now attempts both the normalized value and the original display value, so both `ICA-ADFS` and `Application: ICA-ADFS` can resolve.
  - Matching compares normalized backend result labels against both normalized payload forms.
- Supersedes `0.0.124`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.125.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.125.opm`.
- `Kernel/Package/GovernanceDB-0.0.125.opm` SHA256: `EE66297E09E3EB5BB5B178790F3D133BFCC4EA3D13C4D7B94937C836648C1421`.

### Validation

- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `854071154417596342AF086ADE2FC62A39BD1D73E9F9ED329E1733F781E9D4B8`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- Matching sanity tests confirmed:
  - `Application: ICA-ADFS` matches `ICA-ADFS`.
  - `ICA-ADFS` matches `Application: ICA-ADFS`.
  - `Environment: NON-PROD` matches `NON-PROD`.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.125.opm` parsed successfully as XML: version `0.0.125`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay template hash.
- `git diff --check` passed.

### Architectural Decisions

- JSON apply must update the actual reference field state, not only text input values, because ticket submission relies on hidden reference IDs.
- Display labels and raw names are both acceptable operator-facing JSON forms and must resolve through the same import path.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.125` package.
- Retest changing `ZTicket-Application` from `Application: Integrated Clearance System` to `Application: ICA-ADFS` from the JSON drawer and confirm both the visible chip and hidden reference ID change.
- If a value still does not resolve, verify whether the target governance object is returned by `AgentReferenceSearch` for the current service/location/environment restrictions.

## 2026-06-24 Service Payload Customer Reference Resolver 0.0.126

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.126`.
- Added customer portal payload reference resolution in `CustomerTicketMessage`:
  - New subaction `ZTSMServicePayloadReferenceResolve`.
  - Resolves JSON/template import labels such as `Application: ICA-ADFS` and `Application: Integrated Clearance System` to the actual hidden reference object key.
  - Accepts display labels, raw object names, object numbers, and explicit `Name::ID` values.
  - Treats `-` as blank and returns an empty key/value for clearing a reference.
  - For GovernanceObject Dynamic Fields, enforces the field's configured class restriction before returning a match.
- Updated `ZTSMCustomerTicketMessageServiceFields.tt` import behavior:
  - JSON/template apply first calls the customer-side resolver.
  - The previous `AgentReferenceSearch` lookup remains as a fallback.
  - Successful resolution updates both the visible autocomplete label and the hidden `DynamicField_*` value.
- Synced changed files across live source, package source, runtime overlay, and ZTSMOverlay copies:
  - `Kernel/Modules/CustomerTicketMessage.pm`
  - `Kernel/Output/HTML/Templates/Standard/ZTSMCustomerTicketMessageServiceFields.tt`
- Supersedes `0.0.125`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.126.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.126.opm`.
- `Kernel/Package/GovernanceDB-0.0.126.opm` SHA256: `6388CA071389333D6700A3A7022BA2F395D3ACDE7AB0A4B2067562346D8CF8A2`.

### Validation

- Perl syntax check passed for `Kernel/Modules/CustomerTicketMessage.pm`.
- Template inline JavaScript parsed successfully with bundled Node after stripping Template Toolkit tags.
- Mirrored `CustomerTicketMessage.pm` copies have matching SHA256 hash `8194D1C06A7EB206F4A308E06C87D2C8448863A2E731049A880F15F2F4EE3213`.
- Mirrored `ZTSMCustomerTicketMessageServiceFields.tt` copies have matching SHA256 hash `27F616A58952E07E62C0110CC07FF6F559B3DFE9529F88268B5FA54D95134CBC`.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.126.opm` parsed successfully as XML: version `0.0.126`, 171 file nodes, `MissingBase64=0`.
- Confirmed the generated OPM embeds the updated runtime overlay module and template hashes.
- `git diff --check` passed.

### Architectural Decisions

- JSON/template import remains a portal utility, but reference-name resolution must happen through a customer action because the generic agent autocomplete search can be constrained by current form state.
- Import resolution must set the hidden reference key, not only the visible autocomplete label.
- The resolver is exact-match oriented and class-restricted to avoid silently selecting the wrong GovernanceObject.

### Rejected Approaches

- Do not rely only on frontend text assignment for reference fields.
- Do not fall back to the first autocomplete result for unresolved reference values.
- Do not bypass GovernanceObject class restrictions while resolving import payload values.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.126` package.
- Retest changing both top-level `ZTicket-Application` and nested `ZFirewall-SrcSystem` / `ZFirewall-DstSystem` values from the JSON drawer and confirm visible chips and hidden reference IDs change.

## 2026-06-24 GenericAgent Type Array Submit Fix 0.0.127

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.127`.
- Hardened `Kernel/System/GovernanceDB/Bootstrap.pm` GenericAgent seeding:
  - Added `_GenericAgentSearchArraysSanitize`.
  - Removes empty TicketSearch array filters before writing GenericAgent jobs.
  - Covers `Types`, `TypeIDs`, `States`, `StateIDs`, queues, priorities, services, SLAs, owners, locks, and related created/search array fields.
  - Runs before and after state/type name-to-ID translation.
- This repairs installed GenericAgent jobs on package upgrade because bootstrap deletes and re-adds the seed jobs from `runtime_seed/generic_agents.yml`.
- Confirmed checked-in `generic_agents.yml` still contains non-empty `Types` for:
  - `TESSERA-ACTIVITY-ROLELOOKUP`
  - `TESSERA-TICKET-LIFECYCLE-INITIATION`
- Supersedes `0.0.126`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.127.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.127.opm`.
- `Kernel/Package/GovernanceDB-0.0.127.opm` SHA256: `1B309FD578FE84FF1448BEB326B1F286175613D11C73F1DCB5699A0E83CB5241`.

### Validation

- Perl syntax check passed for `Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm`.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.127.opm` parsed successfully as XML: version `0.0.127`, 171 file nodes, `MissingBase64=0`.

### Architectural Decisions

- GenericAgent seed import must sanitize empty TicketSearch array filters because OTOBO rejects empty arrays such as `Types => []` during event-time `TicketSearch`.
- The package upgrade path is the correct repair point because GenericAgent jobs live in DB and can be left in a bad state by older package/runtime imports.

### Known Issues / Follow-Up

- Runtime install/upgrade verification is needed in OTOBO using the generated `0.0.127` package.
- After upgrade, verify the two TESSERA GenericAgent jobs in the admin UI or DB have non-empty type filters, then retry customer request submit.
- `ZTSMUserIDCheck.pm` showed runtime warnings for redefined `_CanViewStory` and `Run`; repo copies are not internally duplicated, so check runtime deployment/cache or duplicate module loading if the warning remains after upgrade/restart.

## 2026-06-24 GenericAgent Runtime Search Guard 0.0.129

### Completed work
- Tightened the runtime `GenericAgent->JobRun` TicketSearch guard after live testing still produced `The given param 'Types' is invalid or an empty array reference!` without the previous diagnostic.
- Updated `Kernel/System/GenericAgent.pm` so `_TESSERATicketSearchArraySanitize` now catches both:
  - empty array filters such as `Types => []`
  - invalid truthy non-array filters such as `Types => '...'`
- Changed the diagnostic priority from `error` to `notice`, because this guard is a sanitizing diagnostic rather than the original fatal failure path.
- Mirrored the updated module to:
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/GenericAgent.pm`
  - `ZTSMOverlay/files/Kernel/System/GenericAgent.pm`
- Bumped `GovernanceDB.sopm` package version to `0.0.129`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.129.opm`.
- Supersedes `0.0.128`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.129.opm`.
- `Kernel/Package/GovernanceDB-0.0.129.opm` SHA256: `B5C7BDB3E1B780A9C5E248334CEAD381984D4DDF3084E7BF5AEA070C7A22520C`.

### Validation
- `perl -I. -IKernel\cpan-lib -c Kernel\System\GenericAgent.pm`: syntax OK.
- `perl -I. -IKernel\cpan-lib -c Kernel\Package\GovernanceDB\var\governancedb\runtime_overlay\Kernel\System\GenericAgent.pm`: syntax OK.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.129.opm` parsed successfully as XML: version `0.0.129`, 172 file nodes, `MissingBase64=0`.
- `Kernel/System/GenericAgent.pm`, package runtime overlay copy, and `ZTSMOverlay` copy all share SHA256 `13ED791D76FE36F1A7EFC99E58D3C162D7C49BCB55CE8AD49759AB5F1CDD564C`.

### Runtime expectation
- After upgrading to `0.0.129`, retry submit and check the normal OTOBO notice log for:
  - `TESSERA GenericAgent search guard sanitized invalid TicketSearch filters for Job='...'`
- The message should identify the exact GenericAgent job and whether the bad value was `Job.Types=[]` or `Job.Types=invalid(...)`.
- If the original `Types` error still appears without this notice line, the running PSGI process is not executing the overlaid `Kernel/System/GenericAgent.pm` and should be restarted or checked for overlay installation.

## 2026-06-24 StateBook Missing State Value Guard 0.0.130

### Completed work
- Fixed the submit-time StateBook failure shown after the GenericAgent `Types` guard was no longer the active blocker:
  - Runtime warning: `Odd number of elements in hash assignment ... ZTSMStateBookReader.pm line 114`
  - Runtime error: `No State for FieldName found!`
- Root cause: `_RecordValue()` returned bare `return;` for missing state fields. When used inside another argument list (`Value => _RecordValue(...), FieldName => ...`), Perl flattened the empty return, shifted the argument list, and made `_StateNameResolve()` treat `FieldName` as the state value.
- Updated `Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`:
  - `_RecordValue()` now returns explicit scalar `undef` on missing/invalid records.
  - State record parsing stores `$StateValue` before calling `_StateNameResolve()`, preventing list-context argument collapse.
- Synced the fixed module across:
  - `Kernel/Package/GovernanceDB/Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`
  - `ZTSMOverlay/files/Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm`
- This also brought the `ZTSMOverlay` copy back in sync with canonical source; it had been stale and missing the requester-hold skip guard already present in the package/runtime copies.
- Bumped `GovernanceDB.sopm` package version to `0.0.130`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.130.opm`.
- Supersedes `0.0.129`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.130.opm`.
- `Kernel/Package/GovernanceDB-0.0.130.opm` SHA256: `C82BC4041988CC8D5E57D42F11EAC52CE011EBBDB717823E3004DEFB8363E1C3`.

### Validation
- `perl -I. -IKernel\cpan-lib -c Kernel\System\ProcessManagement\TransitionAction\ZTSMStateBookReader.pm`: syntax OK.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.130.opm` parsed successfully as XML: version `0.0.130`, 172 file nodes, `MissingBase64=0`.
- Canonical, package-source, runtime-overlay, and `ZTSMOverlay` `ZTSMStateBookReader.pm` copies all share SHA256 `F7C21C6BB80A16805A1596B85535E9A124C739E84DD44F120A574F5C357E2CE4`.
- `git diff --check` passed.

### Runtime expectation
- After upgrading to `0.0.130`, retry customer submit. The `No State for FieldName found!` error should stop.
- The `ZTSMUserIDCheck.pm` subroutine redefinition warnings were checked against repo source; active copies contain one definition each and match by hash, so remaining warnings likely indicate PSGI/cache/module-load duplication in the runtime environment rather than duplicate source in this repo.

## 2026-06-24 GenericAgent Runtime Search Guard 0.0.128

### Completed Work

- Bumped `GovernanceDB.sopm` package version to `0.0.128`.
- Added runtime instrumentation and guard to `Kernel/System/GenericAgent.pm`:
  - New helper `_TESSERATicketSearchArraySanitize`.
  - Runs after DB/config GenericAgent job loading and dynamic-field search parameter construction, before any GenericAgent `TicketSearch`.
  - Removes empty TicketSearch array filters such as `Types => []` at runtime.
  - Logs the exact GenericAgent job and sanitized array fields using the message prefix `TESSERA GenericAgent search guard`.
- Added `var/governancedb/runtime_overlay/Kernel/System/GenericAgent.pm` to the package file list so package upgrade deploys the runtime guard.
- Synced the instrumented file across:
  - `Kernel/System/GenericAgent.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/GenericAgent.pm`
  - `ZTSMOverlay/files/Kernel/System/GenericAgent.pm`
- Supersedes `0.0.127`; install/upgrade testing should use `Kernel/Package/GovernanceDB-0.0.128.opm`.
- Rebuilt `Kernel/Package/GovernanceDB-0.0.128.opm`.
- `Kernel/Package/GovernanceDB-0.0.128.opm` SHA256: `F703AF66DFA0B8C1A4E3D9E3D9602E5574E2013D5EF60DD6055AF9324C615C0E`.

### Validation

- Perl syntax checks passed:
  - `Kernel/System/GenericAgent.pm`
  - `Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/GenericAgent.pm`
- Mirrored `GenericAgent.pm` copies have matching SHA256 hash `C87587C8EF9D030B54CF918FD4E369FE0A692F96E5BE82599E35491CD3324D6F`.
- `GovernanceDB.sopm` parsed successfully as XML.
- `Kernel/Package/GovernanceDB-0.0.128.opm` parsed successfully as XML: version `0.0.128`, 172 file nodes, `MissingBase64=0`.

### Architectural Decisions

- The GenericAgent runtime guard is diagnostic and defensive: it keeps ticket submit from failing while identifying the exact bad GenericAgent job in the logs.
- This is broader than the GovernanceDB seed repair because the bad job may come from DB state, another package, or runtime mutation outside `runtime_seed/generic_agents.yml`.

### Known Issues / Follow-Up

- After upgrading to `0.0.128`, retry submit and check the OTOBO log for `TESSERA GenericAgent search guard sanitized empty TicketSearch arrays for Job='...'`.
- Once the offending GenericAgent job is identified and corrected at source, consider removing the runtime guard or reducing its log level.
