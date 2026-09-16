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

package Kernel::Language::bg_MasterSlave;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AgentTicketMasterSlave
    $Self->{Translation}->{'Manage Master/Slave status for %s%s%s'} = 'Управление на състоянието Master/Slave за %s%s%s';

    # Perl Module: Kernel/Modules/AgentTicketMasterSlave.pm
    $Self->{Translation}->{'New Master Ticket'} = 'Нов главен билет';
    $Self->{Translation}->{'Unset Master Ticket'} = 'Премахване на главния билет';
    $Self->{Translation}->{'Unset Slave Ticket'} = 'Премахване на билета за подчинен';
    $Self->{Translation}->{'Slave of %s%s%s: %s'} = 'Подчинен на %s%s%s: %s';

    # Perl Module: Kernel/Output/HTML/TicketBulk/MasterSlave.pm
    $Self->{Translation}->{'Unset Master Tickets'} = 'Премахване на главните билети';
    $Self->{Translation}->{'Unset Slave Tickets'} = 'Деактивиране на подчинени билети';

    # Perl Module: Kernel/System/DynamicField/Driver/MasterSlave.pm
    $Self->{Translation}->{'Master'} = 'Главен';
    $Self->{Translation}->{'Slave of %s%s%s'} = 'Подчинен %s%s%s';
    $Self->{Translation}->{'Master Ticket'} = 'Главен билет';

    # SysConfig
    $Self->{Translation}->{'All master tickets'} = 'Всички главни билети';
    $Self->{Translation}->{'All slave tickets'} = 'Всички подчинени билети';
    $Self->{Translation}->{'Allows adding notes in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Позволява добавяне на бележки в екрана MasterSlave на билет за увеличен билет в интерфейса на агента.';
    $Self->{Translation}->{'Change the MasterSlave state of the ticket.'} = 'Променете състоянието на MasterSlave на билета.';
    $Self->{Translation}->{'Defines dynamic field name for master ticket feature.'} = 'Дефинира име на динамично поле за функцията на главния билет.';
    $Self->{Translation}->{'Defines if a ticket lock is required in the ticket MasterSlave screen of a zoomed ticket in the agent interface (if the ticket isn\'t locked yet, the ticket gets locked and the current agent will be set automatically as its owner).'} =
        'Определя дали е необходимо заключване на билет в екрана MasterSlave на билет, ескалиран билет в интерфейса на агента (ако билетът все още не е заключен, билетът се заключва и текущият агент ще бъде зададен автоматично като негов собственик).';
    $Self->{Translation}->{'Defines if the MasterSlave note is visible for the customer by default.'} =
        'Определя дали бележката MasterSlave е видима за клиента по подразбиране.';
    $Self->{Translation}->{'Defines the default next state of a ticket after adding a note, in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Дефинира следващото състояние по подразбиране на билет след добавяне на бележка в екрана MasterSlave на билета, ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Defines the default ticket priority in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Определя приоритета на билета по подразбиране в екрана MasterSlave на билета, за ескалирания билет в интерфейса на агента.';
    $Self->{Translation}->{'Defines the height for the rich text editor component for this screen. Enter number (pixels) or percent value (relative).'} =
        '';
    $Self->{Translation}->{'Defines the history comment for the ticket MasterSlave screen action, which gets used for ticket history in the agent interface.'} =
        'Дефинира коментара на историята за действието на екрана MasterSlave на билет, който се използва за хронология на билет в интерфейса на агента.';
    $Self->{Translation}->{'Defines the history type for the ticket MasterSlave screen action, which gets used for ticket history in the agent interface.'} =
        'Дефинира типа история за действието на екрана MasterSlave на билета, което се използва за хронология на билети в интерфейса на агента.';
    $Self->{Translation}->{'Defines the next state of a ticket after adding a note, in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Дефинира следващото състояние на билет след добавяне на бележка в екрана MasterSlave на билета за ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Enables the advanced MasterSlave part of the feature.'} = 'Активира разширената MasterSlave част от функцията.';
    $Self->{Translation}->{'Enables the feature that slave tickets follow the master ticket to a new master in the advanced MasterSlave mode.'} =
        'Активира функцията, че подчинените билети следват главния билет към нов главен в разширен режим MasterSlave.';
    $Self->{Translation}->{'Enables the feature to change the MasterSlave state of a ticket in the advanced MasterSlave mode.'} =
        'Активира функцията за промяна на състоянието на Master Slave на билет в разширен режим Master Slave.';
    $Self->{Translation}->{'Enables the feature to forward articles from type \'forward\' of a master ticket to the customers of the slave tickets. By default (disabled) it will not forward articles from type \'forward\' to the slave tickets.'} =
        'Активира функцията за препращане на статии от тип „напред“ на главния билет към клиентите на подчинените билети. По подразбиране (забранено) няма да препраща статии от тип „напред“ към подчинените билети.';
    $Self->{Translation}->{'Enables the feature to keep parent-child link after change of the MasterSlave state in the advanced MasterSlave mode.'} =
        'Активира функцията за запазване на връзката родител-дете след промяна на състоянието на MasterSlave в разширен режим MasterSlave.';
    $Self->{Translation}->{'Enables the feature to keep parent-child link after unset of the MasterSlave state in the advanced MasterSlave mode.'} =
        'Активира функцията за запазване на връзката родител-дете след отмяна на състоянието MasterSlave в разширения режим MasterSlave.';
    $Self->{Translation}->{'Enables the feature to unset the MasterSlave state of a ticket in the advanced MasterSlave mode.'} =
        'Активира функцията за премахване на състоянието MasterSlave на билет в разширения режим MasterSlave.';
    $Self->{Translation}->{'If a note is added by an agent, sets the state of the ticket in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Ако бележка е добавена от агент, задава състоянието на билета в екрана MasterSlave на билета за ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Master / Slave'} = 'Главен/ Подчинен';
    $Self->{Translation}->{'Master Tickets'} = 'Главни билети';
    $Self->{Translation}->{'MasterSlave'} = 'ГлавенПодчинен';
    $Self->{Translation}->{'MasterSlave module for Ticket Bulk feature.'} = 'Модул MasterSlave за функцията Групово действие.';
    $Self->{Translation}->{'Parameters for the dashboard backend of the master tickets overview of the agent interface. "Limit" is the number of entries shown by default. "Group" is used to restrict the access to the plugin (e. g. Group: admin;group1;group2;). "Default" determines if the plugin is enabled by default or if the user needs to enable it manually. "CacheTTLLocal" is the cache time in minutes for the plugin.'} =
        'Параметри на таблото за управление на главния преглед на билетите в интерфейса на агента. „Ограничение“ е броят на записите, показан по подразбиране. „Група“ се използва за ограничаване на достъпа до плъгина (напр. Група: admin;group1;group2;). „По подразбиране“ определя дали приставката е активирана по подразбиране или потребителят трябва да я активира ръчно. „CacheTTLLocal“ е времето за кеширане в минути за плъгина.';
    $Self->{Translation}->{'Parameters for the dashboard backend of the slave tickets overview of the agent interface. "Limit" is the number of entries shown by default. "Group" is used to restrict the access to the plugin (e. g. Group: admin;group1;group2;). "Default" determines if the plugin is enabled by default or if the user needs to enable it manually. "CacheTTLLocal" is the cache time in minutes for the plugin.'} =
        'Параметри на таблото за управление на прегледа на подчинените билети на интерфейса на агента. „Ограничение“ е броят на записите, показан по подразбиране. „Група“ се използва за ограничаване на достъпа до плъгина (напр. Група: admin;group1;group2;). „По подразбиране“ определя дали приставката е активирана по подразбиране или потребителят трябва да я активира ръчно. „CacheTTLLocal“ е времето за кеширане в минути за плъгина.';
    $Self->{Translation}->{'Registration of the ticket event module.'} = 'Регистрация на модул за събитие с билети.';
    $Self->{Translation}->{'Required permissions to use the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Необходими права за използване на екрана MasterSlave билет, на ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Sets if Master / Slave field must be selected by the agent.'} = 'Задава дали полето Master/Slave трябва да бъде избрано от агента.';
    $Self->{Translation}->{'Sets the default body text for notes added in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Задава основния текст по подразбиране за бележки, добавени в екрана MasterSlave на билета, за ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Sets the default subject for notes added in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Задава темата по подразбиране за бележки, добавени в екрана MasterSlave на билета за ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Sets the responsible agent of the ticket in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Задава отговорния агент за билета в екрана MasterSlave на билета за ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Sets the service in the ticket MasterSlave screen of a zoomed ticket in the agent interface (Ticket::Service needs to be activated).'} =
        'Задава услугата в екрана MasterSlave на билета за ескалиран билет в интерфейса на агента (Ticket::Service трябва да бъде активиран).';
    $Self->{Translation}->{'Sets the ticket owner in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Задава собственика на билета в екрана MasterSlave на билета за ескалиран билет в интерфейса на агента.';
    $Self->{Translation}->{'Sets the ticket type in the ticket MasterSlave screen of a zoomed ticket in the agent interface (Ticket::Type needs to be activated).'} =
        'Задава типа билет в екрана MasterSlave на билета за увеличен билет в интерфейса на агента (Ticket::Type трябва да бъде активиран).';
    $Self->{Translation}->{'Shows a link in the menu to change the MasterSlave status of a ticket in the ticket zoom view of the agent interface.'} =
        'Показва връзка в менюто за промяна състоянието на MasterSlave билет в изгледа за увеличение на билета в интерфейса на агента.';
    $Self->{Translation}->{'Shows a list of all the involved agents on this ticket, in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Показва списък на всички включени агенти в този билет от екрана MasterSlave на билета, за увеличен билет в интерфейса на агента.';
    $Self->{Translation}->{'Shows a list of all the possible agents (all agents with note permissions on the queue/ticket) to determine who should be informed about this note, in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Показва списък с всички възможни агенти (всички агенти с разрешения за бележка в опашката/билета), за да определи кой трябва да бъде информиран за тази бележка, в екрана MasterSlave за билет на увеличен билет в интерфейса на агента.';
    $Self->{Translation}->{'Shows the ticket priority options in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Показва опциите за приоритет на билета в екрана MasterSlave на билета за увеличен билет в интерфейса на агента.';
    $Self->{Translation}->{'Shows the title field in the ticket MasterSlave screen of a zoomed ticket in the agent interface.'} =
        'Показва полето за заглавие в екрана MasterSlave на билета за увеличен билет в интерфейса на агента.';
    $Self->{Translation}->{'Slave Tickets'} = 'Подчинени билети';
    $Self->{Translation}->{'Specifies the different article communication channels where the real name from Master ticket will be replaced with the one in the Slave ticket.'} =
        'Указва различните канали за комуникация на статията, където истинското име от главния билет ще бъде заменено с това в подчинения билет.';
    $Self->{Translation}->{'This module activates Master/Slave field in new email and phone ticket screens.'} =
        'Този модул активира полето Master/Slave в нови екрани за имейл и телефонни билети.';
    $Self->{Translation}->{'This setting is deprecated and will be removed in further versions of MasterSlave.'} =
        'Тази настройка е остаряла и ще бъде премахната в следващите версии на MasterSlave.';
    $Self->{Translation}->{'Ticket MasterSlave.'} = 'Билет MasterSlave.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
