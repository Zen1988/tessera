// --
// TESSERA CMDB data actions.
// --
Core.ZTSM = Core.ZTSM || {};
Core.ZTSM.Agent = Core.ZTSM.Agent || {};
Core.ZTSM.Agent.ConfigItem = Core.ZTSM.Agent.ConfigItem || {};

(function (TargetNS) {
    'use strict';

    TargetNS.Init = function () {
        var BaseLink = Core.Config.Get('Baselink') || 'index.pl?';
        var Actions = {
            '.ZTSMConfigItemDocumentAction a': 'Action=AgentITSMConfigItemDocument',
            '.ZTSMGeneralCatalogDocumentAction a': 'Action=AgentGeneralCatalogDocument;ReturnAction=AgentITSMConfigItem',
            '.ZTSMConfigItemWorkbookAction a': 'Action=AgentITSMConfigItemWorkbook'
        };
        var Query = new URLSearchParams(window.location.search);
        var CurrentClassID = Query.get('ClassID');
        if (!CurrentClassID && /^\d+$/.test(Query.get('Filter') || '')) {
            CurrentClassID = Query.get('Filter');
        }
        if (CurrentClassID) {
            Actions['.ZTSMConfigItemWorkbookAction a'] += ';ClassID=' + encodeURIComponent(CurrentClassID);
        }

        Object.keys(Actions).forEach(function (Selector) {
            var Link = document.querySelector(Selector);
            if (Link) {
                Link.setAttribute('href', BaseLink + Actions[Selector]);
            }
        });
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');
}(Core.ZTSM.Agent.ConfigItem.DataActions = Core.ZTSM.Agent.ConfigItem.DataActions || {}));
