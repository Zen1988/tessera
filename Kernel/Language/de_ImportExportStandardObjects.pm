# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::Language::de_ImportExportStandardObjects;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AdminGenericAgent
    $Self->{Translation}->{'Here you can upload a configuration file to import generic agents to your system. The file needs to be in .yml format as exported by generic agent management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Generic Agents in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Generic-Agent-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Generic Agents Import'} = 'Generic Agent Import';
    $Self->{Translation}->{'Generic Agents Export'} = 'Generic Agent Export';

    # Template: AdminGenericAgentImportExport
    $Self->{Translation}->{'Here you can export a configuration file of generic agents to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Generic Agents exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Template: AdminGroup
    $Self->{Translation}->{'Here you can upload a configuration file to import groups to your system. The file needs to be in .yml format as exported by group management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Gruppen in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Gruppen-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Groups Import'} = 'Gruppen-Import';
    $Self->{Translation}->{'Groups Export'} = 'Gruppen-Export';

    # Template: AdminGroupImportExport
    $Self->{Translation}->{'Here you can export a configuration file of groups to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Gruppen exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Template: AdminQueue
    $Self->{Translation}->{'Here you can upload a configuration file to import queues to your system. The file needs to be in .yml format as exported by queue management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Queues in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Queue-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Queues Import'} = 'Queue-Import';
    $Self->{Translation}->{'Queues Export'} = 'Queue-Export';

    # Template: AdminQueueImportExport
    $Self->{Translation}->{'Here you can export a configuration file of queues to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Queues exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Template: AdminQueueTemplates
    $Self->{Translation}->{'Here you can upload a configuration file to import queue-template relations to your system. The file needs to be in .yml format as exported by queue-template management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Queue-Vorlagen-Beziehungen in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Queue-Vorlagen-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Queue-Templates Import'} = 'Queue-Vorlagen-Import';
    $Self->{Translation}->{'Queue-Templates Export'} = 'Queue-Vorlagen-Export';

    # Template: AdminQueueTemplatesImportExport
    $Self->{Translation}->{'Here you can export a configuration file of queue-template relations to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Queue-Vorlagen-Beziehungen exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Template: AdminRole
    $Self->{Translation}->{'Here you can upload a configuration file to import roles to your system. The file needs to be in .yml format as exported by role management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Rollen in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Rollen-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Roles Import'} = 'Rollen-Import';
    $Self->{Translation}->{'Roles Export'} = 'Rollen-Export';

    # Template: AdminRoleImportExport
    $Self->{Translation}->{'Here you can export a configuration file of roles to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Rollen exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Template: AdminRoleGroup
    $Self->{Translation}->{'Here you can upload a configuration file to import role-group relations to your system. The file needs to be in .yml format as exported by role-group management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Rollen-Gruppen-Beziehungen in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Rollen-Gruppen-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Role-Group Import'} = 'Rollen-Gruppen-Import';
    $Self->{Translation}->{'Role-Group Export'} = 'Rollen-Gruppen-Export';

    # Template: AdminRoleGroupImportExport
    $Self->{Translation}->{'Here you can export a configuration file of role-group relations to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Rollen-Gruppen-Beziehungen exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Template: AdminTemplate
    $Self->{Translation}->{'Here you can upload a configuration file to import templates to your system. The file needs to be in .yml format as exported by template management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Vorlagen in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Vorlagen-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Templates Import'} = 'Vorlagen-Import';
    $Self->{Translation}->{'Templates Export'} = 'Vorlagen-Export';

    # Template: AdminTemplateImportExport
    $Self->{Translation}->{'Here you can export a configuration file of templates to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Vorlagen exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Template: AdminType
    $Self->{Translation}->{'Here you can upload a configuration file to import types to your system. The file needs to be in .yml format as exported by type management module.'} =
            'Hier können Sie eine Konfigurationsdatei hochladen, um Typen in Ihr System zu importieren. Die Datei muss im .yml-Format vorliegen, wie es von dem Typen-Verwaltungsmodul exportiert wird.';
    $Self->{Translation}->{'Types Import'} = 'Typen-Import';
    $Self->{Translation}->{'Types Export'} = 'Typen-Export';

    # Template: AdminTypeImportExport
    $Self->{Translation}->{'Here you can export a configuration file of types to import these on another system. The configuration file is exported in yml format.'} =
            'Hier können Sie eine Konfigurationsdatei von Typen exportieren, um diese auf einem anderen System zu importieren. Die Konfigurationsdatei wird im yml Format exportiert.';

    # Perl Module: Kernel/Modules/AdminGenericInterfaceTransportHTTPREST.pm

    # SysConfig

    return 1;
}

1;
