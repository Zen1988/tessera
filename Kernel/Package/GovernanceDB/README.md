# GovernanceDB readiness scaffold

GovernanceDB is a separate ZTSM governance object store inspired by OTOBO ITSM
ConfigItem, but it is not a drop-in reuse of the CMDB schema.

## Current intent

- Keep existing ITSM ConfigItem records untouched.
- Create a new package-owned schema under `governance_object*` tables.
- Seed GovernanceDB GeneralCatalog namespaces:
  `ZTSM::GovernanceObject::Class`,
  `ZTSM::GovernanceObject::Class::Category`, and
  `ZTSM::GovernanceObject::Status`.
- Replace `configitem_number` with `goid`, the Governance Object ID.
- Store `ZTSM-Code` as `governance_object.ztsm_code`.
- Store `ZTSM-Status` as `governance_object.ztsm_status`.
- Keep `name` and `description` on object versions.
- Use `ZTSM-Status` instead of ITSM ConfigItem deployment/incident states.
- Leave runtime migration/copying for a later step.
- Install a starter agent UI for listing, adding, and zooming GovernanceDB
  objects.
- Install an Admin overview tile for configuring GovernanceObject class
  definitions before objects are created.
- Seed the `governance-db` access group and register the starter agent UI for
  both `admin` and `governance-db` so installers are not locked out before they
  can delegate access.
- Install a manual transform UI that copies an ITSM ConfigItem into
  GovernanceDB without deleting or modifying the source ConfigItem.
- Preserve a raw copy of the ITSM ConfigItem UI under
  `PortedFromITSMConfigItem/` for the fuller UI/runtime migration.

## Initial object classes

- Book
- StateBook
- BlueBook
- ServiceSupportMap
- GovernanceConfigItem

## Definition administration

Admin users can open the Governance Objects tile under CMDB Settings to edit the
definition for each `ZTSM::GovernanceObject::Class`. Saving creates a new
definition version. New objects use the latest configured class definition when
no explicit definition is supplied.

GovernanceDB also registers reference dynamic field drivers for
`GovernanceObject` and `GovernanceObject Version`, and extends CustomerCompany
and CustomerUser reference drivers so they can be used on GovernanceObject
definitions.

## Copied as porting baseline

`PortedFromITSMConfigItem/` includes raw ConfigItem/ZTSM handling sources for
manual GovernanceDB porting:

- ITSM ConfigItem SysConfig XML.
- GeneralCatalog admin/config support files for later GovernanceDB-specific
  catalog preference porting.
- Agent and customer ConfigItem modules/templates.
- ConfigItem system object, version, history, link, permission, number,
  definition, search, ACL, mask, and event modules.
- ConfigItem dynamic field drivers, object type, and definition sync event.
- ConfigItem GenericInterface operations/invokers/event object type.
- ConfigItem import/export, stats, console commands, link object, dashboard,
  layout, and template helpers.
- ConfigItem process TransitionActions.
- Current ZTSM/TESSERA TransitionActions that may need GovernanceObject-aware
  readers later.

## ServiceSupportMap conditions

`GovernanceDB::ServiceSupportMap::Condition` defines matching rules as a hash:
the key is the ServiceSupportMap object field and the value is the ticket field.
Defaults:

- `ZTSMSupportAssignment-Application` maps to `ZTicket-Application`
- `ZTSMSupportAssignment-Environment` maps to `ZTicket-Env`
- `ZTSMSupportAssignment-Location` maps to `ZTicket-Location`

Add more key/value entries in SysConfig to extend ServiceSupportMap matching
without hardcoding workflow routing.

## Permissions

The package creates the `governance-db` group in `groups_table`. Agent modules
and navigation allow both `admin` and `governance-db` so existing admins can
open GovernanceDB immediately after install and then grant the dedicated group
to governance users.

## Deliberately not active yet

- ITSM deployment state and incident state fields.
- Import/export and GenericInterface endpoints.
- Existing ZTSM governance records.

Those copied files are not registered in the package file list yet. They can be
ported screen by screen onto `Kernel::System::GovernanceDB` after the existing
ZTSM customizations are screened.
