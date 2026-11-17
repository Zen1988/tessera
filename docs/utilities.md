# Customer Utilities

TESSERA-Base 0.1.1 adds one customer **Utilities** navigation entry for Advanced ticket search, Network simulation and administrator-managed tools. Workplace retains unified Search. Its former external-tool tile now reads shortcuts from the same catalogue and links to the full page.

## Administration

Open **Admin → Utilities** (`index.pl?Action=AgentUtilities`) as an active agent with admin write permission. Create a tool, enter its name/description, choose an external HTTPS destination or a registered internal handler, upload an optional PNG/JPEG, select customer access, enable it and optionally show it as a Workplace shortcut. Save before using access/launch preview. Disable a tool to retire it without losing configuration.

New tools default to disabled and no customer access. Choose selected exact active customer logins or explicitly choose all active customers. Uploaded images are limited to 256 KB and 1024×1024 input, decoded and resampled to 96×96 PNG; filenames and original metadata are not retained. Icons are served through permission-checked customer requests, not public files. Native toolbox custom HTTPS links/titles/local icon references are imported on the first save; only the exact unmodified native three-example configuration is omitted. Insecure or credential-bearing legacy destinations require administrator correction and remain in their original SysConfig record.

The initial built-ins are Advanced ticket search and Network simulation. Search retains native ticket scope and requires its customer module to be enabled. Network workspace visibility retains existing customer CMDB read checks; per-object entitlement remains in the destination. Remote simulation separately requires existing Enabled, AllowedCustomerUsers and environment bindings. Use the **Network simulation access** link to configure those existing controls. A Utilities audience never creates SupportAssignments or grants execution authority. Direct original tool bookmarks retain their existing native authorization; catalogue audience controls the catalogue and its launch routes.

## Parameters

The mapping editor accepts a JSON object keyed by destination query-parameter name:

```json
{
  "username": {"Source": "CustomerUserLogin", "Required": 1},
  "region": {"Source": "Literal", "Value": "sg"},
  "ticket": {"Source": "TicketNumber", "Required": 0}
}
```

Sources are Literal, CustomerUserLogin, CustomerUserEmail, TicketNumber and ConfigItemNumber. Identity comes from the authenticated session. External values are URL-encoded; mapped names replace matching static query names, and unrelated repeated static parameters are retained. Credential/session/token parameters and credentials embedded in URLs are rejected. External authentication remains the destination's own login or configured SSO; launching CyberArk does not authenticate to CyberArk.

Ticket/asset numbers require a live permission check on the supplied TicketID/ConfigItemID. Asset context requires full customer detail entitlement, including the matching CMDB read capability. Unknown, revoked, invalid or missing required context denies launch. Optional absent context is omitted. No arbitrary request-key substitution exists. A context-aware integration may link to `customer.pl?Action=CustomerUtilities;Subaction=Launch;ID=<stable-tool-id>;TicketID=<id>` (or ConfigItemID). Ordinary Utilities/Workplace shortcuts supply no object context. Administrator launch preview checks saved configuration and context without contacting the destination or impersonating a customer browser session.

## Additional internal tools

External tools can be created entirely in the administration page. Additional internal functionality must be installed as an extension with its own backend permission checks; the catalogue is not a code-upload facility. Register its adapter under `TESSERA::Utilities::Handlers`:

```perl
{ ExampleTool => {
    Name => 'Example tool',
    Module => 'Kernel::System::ExampleTool::UtilitiesAdapter',
} }
```

The installed adapter implements `AccessCheck(CustomerUserID => $Login)` and `Launch(CustomerUserID => $Login, Parameters => \%AuthorizedParameters)`. Launch returns `{Action => 'CustomerExampleTool', Parameters => { ... }}`. The customer action must be registered, implement its own authorization and display a safe GET entry screen. State-changing functionality belongs behind its own CSRF-protected POST or ticket workflow. Catalogue launch does not execute arbitrary scripts, authorize automation or perform remote API calls. Reserved routing/session/identity parameters cannot be substituted. Built-in handler identifiers cannot be overridden.

## Storage and upgrades

The catalogue and normalized icon data use one versioned native `system_data` record, `TESSERA::Utilities::Catalogue`. Reads go directly to the database so revocation does not depend on external-cache invalidation. An advisory lock serializes saves and a revision fingerprint rejects concurrent/stale edits. The row is created only on first administrator save; repeated package installation does not reseed, duplicate or overwrite it. No new Dynamic Fields, GovernanceRole objects, database tables or company-based grants are created. A malformed stored catalogue fails closed rather than reverting to global defaults.

Native TileToolBox and CustomerNavigationBar changes are delivered through the existing runtime-overlay mechanism into Custom. Existing navigation definitions are retained; the template hides the two separate tool links only while CustomerUtilities is enabled. Original SysConfig toolbox records are retained for review/rollback. Native target-specific customizations should be reviewed before overlay installation.

Install/upgrade/reinstall the versioned OPM normally and use the matching runtime image/upgrade bundle. Reconcile the shared configuration volume through the normal configuration phase so TESSERAUtilities.xml is registered, then refresh all workers through the normal rollout. Do not replace Config.pm/its Secret or copy another environment's generated ZZZ files. Published 0.1.0 remains unchanged.

## Network Simulation correction

The module explicitly enables scalar-root encoding for seven JSON comparisons in read/save verification. This fixes the supplied `hash- or arrayref expected` failure while retaining overrides, concurrency, validation and fail-closed partial deployment. Redis NOAUTH from the hand-written diagnostic is separate; that invocation omitted Custom. Verify the normal runtime driver/authentication before changing Redis secrets or cache backend.

Local validation covers permissions/direct routes, image handling, strict JSON defaults, contexts, persistence/revision behavior, templates and desktop/mobile browser fixtures. Actual native Linux fresh install/upgrade/reinstall, live database contention/failure recovery, complete themed portal rendering, real Navis and external-system acceptance remain deployment checks.
