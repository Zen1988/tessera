# Ported ITSM ConfigItem UI baseline

This folder preserves ITSM ConfigItem and current ZTSM governance-handling files
copied from the current checkout as source material for GovernanceDB migration.

The deployable starter UI in this package is currently:

- `Kernel/Modules/AgentGovernanceObject.pm`
- `Kernel/Modules/AgentGovernanceObjectAdd.pm`
- `Kernel/Modules/AgentGovernanceObjectZoom.pm`
- `Kernel/Output/HTML/Templates/Standard/AgentGovernanceObject*.tt`

The copied ITSM files remain intentionally separate because the original screens
are deeply coupled to ITSM ConfigItem classes, deployment state, incident state,
definition sync, links, lenses, and import/export behavior. They should be
ported screen by screen onto `Kernel::System::GovernanceDB`.

The baseline includes:

- ConfigItem SysConfig XML.
- GeneralCatalog SysConfig, admin modules, templates, preferences, and backend.
- Agent/customer/admin modules and templates.
- ConfigItem system object tree and event modules.
- Dynamic field object type, drivers, and sync event.
- GenericInterface operations, invokers, and event object type.
- LinkObject, ImportExport, stats, console commands, dashboards, layouts, and
  template helpers.
- `ConfigItemAdd` / `ConfigItemUpdate` TransitionActions.
- Current `ZTSM*` and `TESSERAResolveGovernance` TransitionActions that may
  need GovernanceObject-aware readers.
