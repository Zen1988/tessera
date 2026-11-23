// --
// TESSERA guard for the OTOBO 11.1 ConfigItem overview action-row initializer.
// --
Core.ZTSM = Core.ZTSM || {};
Core.ZTSM.Agent = Core.ZTSM.Agent || {};

(function (TargetNS) {
    'use strict';

    TargetNS.EnsureConfig = function () {
        var ActionRows = Core.Config.Get('ITSMConfigItemActionRow') || {},
            ConfigItem = Core.Config.Get('ITSMConfigItem') || {};

        ConfigItem.ConfigItemActionRow = ConfigItem.ConfigItemActionRow || ActionRows;

        Core.Config.AddConfig({
            ITSMConfigItemActionRow: ActionRows,
            ITSMConfigItem: ConfigItem
        });
    };

    TargetNS.Init = function () {
        TargetNS.EnsureConfig();
    };
}(Core.ZTSM.Agent.ConfigItemOverviewGuard = Core.ZTSM.Agent.ConfigItemOverviewGuard || {}));

// Loader order is significant: establish the root immediately, before
// ITSM.Agent.ConfigItem.Overview registers or executes its DOM initializer.
Core.ZTSM.Agent.ConfigItemOverviewGuard.EnsureConfig();
Core.Init.RegisterNamespace(Core.ZTSM.Agent.ConfigItemOverviewGuard, 'APP_MODULE');
