// --
// Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
// --
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later version.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};
Core.Agent.Admin = Core.Agent.Admin || {};

Core.Agent.Admin.MELTGeneralCatalogDocument = (function (TargetNS) {

    TargetNS.Init = function () {
        var $ActionList = $('.SidebarColumn .ActionList').first(),
            ClassMatch,
            URL;

        if (!$ActionList.length || $ActionList.find('.MELTGeneralCatalogDocument').length) {
            return;
        }

        URL = Core.Config.Get('Baselink') + 'Action=AgentMELTGeneralCatalogDocument;ReturnAction=AdminGeneralCatalog';
        ClassMatch = window.location.href.match(/[?;]Class=([^;&]+)/);
        if (ClassMatch && ClassMatch[1] && ClassMatch[1] !== 'NEW') {
            URL += ';Class=' + encodeURIComponent(decodeURIComponent(ClassMatch[1].replace(/\+/g, ' ')));
        }

        $('<li/>').append(
            $('<a/>', {
                'class': 'CallForAction Fullsize Center MELTGeneralCatalogDocument',
                href: URL
            }).append(
                $('<span/>').append(
                    $('<i/>', {
                        'class': 'fa fa-code'
                    }),
                    'Import / Export Catalog YAML/JSON'
                )
            )
        ).appendTo($ActionList);
    };

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Admin.MELTGeneralCatalogDocument || {}));

