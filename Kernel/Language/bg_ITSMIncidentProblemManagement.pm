# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Language::bg_ITSMIncidentProblemManagement;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AgentTicketOverviewMedium
    $Self->{Translation}->{'Criticality'} = 'Критичност';
    $Self->{Translation}->{'Impact'} = 'Влияние';

    # JS Template: ServiceIncidentState
    $Self->{Translation}->{'Service Incident State'} = 'Състояние на инцидент в услугата';

    # Perl Module: Kernel/Output/HTML/FilterElementPost/ITSMIncidentProblemManagement.pm
    $Self->{Translation}->{'Link ticket'} = 'Свържи билета';
    $Self->{Translation}->{'Change Decision of %s%s%s'} = 'Промяна на решението на %s%s%s';
    $Self->{Translation}->{'Change ITSM fields of %s%s%s'} = 'Променете ITSM полетата на %s%s%s';

    # Perl Module: var/packagesetup/ITSMIncidentProblemManagement.pm
    $Self->{Translation}->{'Review Required'} = 'Изисква преглеждане';
    $Self->{Translation}->{'Decision Result'} = 'Резултат от решението';
    $Self->{Translation}->{'Approved'} = 'Одобрено';
    $Self->{Translation}->{'Postponed'} = 'Отложено';
    $Self->{Translation}->{'Pre-approved'} = 'Предварително одобрен';
    $Self->{Translation}->{'Rejected'} = 'Отхвърлено';
    $Self->{Translation}->{'Repair Start Time'} = 'Време на стартиране на ремонта';
    $Self->{Translation}->{'Recovery Start Time'} = 'Време на стартиране на възстановяването';
    $Self->{Translation}->{'Decision Date'} = 'Дата за решаване';
    $Self->{Translation}->{'Due Date'} = 'Крайна дата';

    # Database XML / SOPM Definition: ITSMIncidentProblemManagement.sopm
    $Self->{Translation}->{'closed with workaround'} = 'приключен с обходно решение';

    # SysConfig
    $Self->{Translation}->{'Add a decision!'} = 'Добавете решение!';
    $Self->{Translation}->{'Additional ITSM Fields'} = 'Допълнителни ITSM полета';
    $Self->{Translation}->{'Additional ITSM ticket fields.'} = 'Допълнителни ITSM полета за билети.';
    $Self->{Translation}->{'Allows adding notes in the additional ITSM field screen of the agent interface.'} =
        'Позволява добавяне на бележки в допълнителния екран на ITSM поле на интерфейса на агента.';
    $Self->{Translation}->{'Allows adding notes in the decision screen of the agent interface.'} =
        'Позволява добавяне на бележки в екрана за решение интерфейса на агента.';
    $Self->{Translation}->{'Allows defining new types for ticket (if ticket type feature is enabled).'} =
        'Позволява дефиниране на нови типове за билет (ако функцията за тип билет е активирана).';
    $Self->{Translation}->{'Change the ITSM fields!'} = 'Променете ITSM полетата!';
    $Self->{Translation}->{'Decision'} = 'Решение';
    $Self->{Translation}->{'Defines if a ticket lock is required in the additional ITSM field screen of the agent interface (if the ticket isn\'t locked yet, the ticket gets locked and the current agent will be set automatically as its owner).'} =
        'Определя дали е необходимо заключване на билет в допълнителния екран на ITSM поле на интерфейса на агента (ако билетът все още не е заключен, билетът се заключва и текущият агент ще бъде зададен автоматично като негов собственик).';
    $Self->{Translation}->{'Defines if a ticket lock is required in the decision screen of the agent interface (if the ticket isn\'t locked yet, the ticket gets locked and the current agent will be set automatically as its owner).'} =
        'Определя дали е необходимо заключване на билет в екрана за решение на интерфейса на агента (ако билетът все още не е заключен, той се заключва и текущият агент ще бъде зададен автоматично като негов собственик).';
    $Self->{Translation}->{'Defines if the service incident state should be shown during service selection in the agent interface.'} =
        'Определя дали състоянието на инцидента на услугата трябва да се показва по време на избор на услуга в интерфейса на агента.';
    $Self->{Translation}->{'Defines the default body of a note in the additional ITSM field screen of the agent interface.'} =
        'Дефинира основния текст на бележката по подразбиране в екрана на допълнителното ITSM поле на интерфейса на агента.';
    $Self->{Translation}->{'Defines the default body of a note in the decision screen of the agent interface.'} =
        'Дефинира тялото по подразбиране на бележка в екрана за вземане на решения на интерфейса на агента.';
    $Self->{Translation}->{'Defines the default next state of a ticket after adding a note, in the additional ITSM field screen of the agent interface.'} =
        'Дефинира следващото състояние по подразбиране на билет след добавяне на бележка в допълнителния екран на ITSM полето на интерфейса на агента.';
    $Self->{Translation}->{'Defines the default next state of a ticket after adding a note, in the decision screen of the agent interface.'} =
        'Дефинира следващото състояние по подразбиране на билет след добавяне на бележка в екрана за решение на интерфейса на агента.';
    $Self->{Translation}->{'Defines the default subject of a note in the additional ITSM field screen of the agent interface.'} =
        'Дефинира темата по подразбиране на бележка в допълнителния екран на ITSM полето на интерфейса на агента.';
    $Self->{Translation}->{'Defines the default subject of a note in the decision screen of the agent interface.'} =
        'Определя темата по подразбиране на бележка в екрана за решение на интерфейса на агента.';
    $Self->{Translation}->{'Defines the default ticket priority in the additional ITSM field screen of the agent interface.'} =
        'Определя приоритета на билета по подразбиране в екрана на допълнителното ITSM поле на интерфейса на агента.';
    $Self->{Translation}->{'Defines the default ticket priority in the decision screen of the agent interface.'} =
        'Определя приоритета на билета по подразбиране в екрана за решение на интерфейса на агента.';
    $Self->{Translation}->{'Defines the history comment for the additional ITSM field screen action, which gets used for ticket history.'} =
        'Дефинира коментара за историята за допълнителното действие на екрана на полето ITSM, което се използва за хронология на билети.';
    $Self->{Translation}->{'Defines the history comment for the decision screen action, which gets used for ticket history.'} =
        'Дефинира коментара за историята за действието на екрана за решение, който се използва за хронологията на тикетите.';
    $Self->{Translation}->{'Defines the history type for the additional ITSM field screen action, which gets used for ticket history.'} =
        'Дефинира типа на хронологията за допълнителното действие на екрана на полето ITSM, което се използва за хронология на билети.';
    $Self->{Translation}->{'Defines the history type for the decision screen action, which gets used for ticket history.'} =
        'Определя типа на историята за действието на екрана за решение, което се използва за хронология на билети.';
    $Self->{Translation}->{'Defines the next state of a ticket after adding a note, in the additional ITSM field screen of the agent interface.'} =
        'Определя следващото състояние на билета след добавяне на бележка в екрана на допълнителното ITSM поле на интерфейса на агента.';
    $Self->{Translation}->{'Defines the next state of a ticket after adding a note, in the decision screen of the agent interface.'} =
        'Определя следващото състояние на билет след добавяне на бележка в екрана за Решение на интерфейса на агента.';
    $Self->{Translation}->{'Dynamic fields shown in the additional ITSM field screen of the agent interface.'} =
        'Динамични полета, показани в допълнителния екран на ITSM поле на интерфейса на агента.';
    $Self->{Translation}->{'Dynamic fields shown in the decision screen of the agent interface.'} =
        'Динамични полета, показани в екрана за решение в интерфейса на агента.';
    $Self->{Translation}->{'Dynamic fields shown in the ticket zoom screen of the agent interface.'} =
        'Динамични полета, показани в екрана за увеличение на билета в интерфейса на агента.';
    $Self->{Translation}->{'Enables the stats module to generate statistics about the average of ITSM ticket first level solution rate.'} =
        'Позволява на модула за статистика да генерира статистически данни за средната скорост на решение от първо ниво на ITSM билет.';
    $Self->{Translation}->{'Enables the stats module to generate statistics about the average of ITSM ticket solution.'} =
        'Позволява на модула за статистика да генерира статистика за средната стойност на решението за ITSM тикет.';
    $Self->{Translation}->{'If a note is added by an agent, sets the state of a ticket in the additional ITSM field screen of the agent interface.'} =
        'Ако бележка е добавена от агент, задава състоянието на билета в екрана на допълнително поле ITSM от интерфейса на агента.';
    $Self->{Translation}->{'If a note is added by an agent, sets the state of a ticket in the decision screen of the agent interface.'} =
        'Ако бележка е добавена от агент, задава състоянието на билета в екрана за решение от интерфейса на агента.';
    $Self->{Translation}->{'Modifies the display order of the dynamic field ITSMImpact and other things.'} =
        'Променя реда на показване на динамичното поле ITSMImpact и други неща.';
    $Self->{Translation}->{'Module to dynamically show the service incident state and to calculate the priority.'} =
        'Модул за динамично показване състоянието на инцидента в услугата и за изчисляване на приоритета.';
    $Self->{Translation}->{'Required permissions to use the additional ITSM field screen in the agent interface.'} =
        'Необходими права за използване на допълнителния екран от ITSM поле в интерфейса на агента.';
    $Self->{Translation}->{'Required permissions to use the decision screen in the agent interface.'} =
        'Необходими права за използване екрана за решение в интерфейса на агента.';
    $Self->{Translation}->{'Service Incident State and Priority Calculation'} = 'Състояние на инцидент от услугата и изчисляване на приоритета';
    $Self->{Translation}->{'Sets the service in the additional ITSM field screen of the agent interface (Ticket::Service needs to be activated).'} =
        'Задава услугата в допълнителния екран на полето ITSM от интерфейса на агента (Ticket::Service трябва да бъде активиран).';
    $Self->{Translation}->{'Sets the service in the decision screen of the agent interface (Ticket::Service needs to be activated).'} =
        'Задава услугата в екрана за решение от интерфейса на агента (Ticket::Service трябва да бъде активиран).';
    $Self->{Translation}->{'Sets the service in the ticket priority screen of a zoomed ticket in the agent interface (Ticket::Service needs to be activated).'} =
        'Задава услугата в екрана с приоритет на билета за увеличен билет в интерфейса на агента (Ticket::Service трябва да бъде активиран).';
    $Self->{Translation}->{'Sets the ticket owner in the additional ITSM field screen of the agent interface.'} =
        'Задава собственика на билета в допълнителния екран на ITSM полето от интерфейса на агента.';
    $Self->{Translation}->{'Sets the ticket owner in the decision screen of the agent interface.'} =
        'Задава собственика на билета в екрана за решение от интерфейса на агента.';
    $Self->{Translation}->{'Sets the ticket responsible in the additional ITSM field screen of the agent interface.'} =
        'Задава отговорния за билет в допълнителния екран на ITSM полето от интерфейса на агента.';
    $Self->{Translation}->{'Sets the ticket responsible in the decision screen of the agent interface.'} =
        'Задава отговорния за билет в екрана за решение от интерфейса на агента.';
    $Self->{Translation}->{'Sets the ticket type in the additional ITSM field screen of the agent interface (Ticket::Type needs to be activated).'} =
        'Задава типа билет в допълнителния екран на ITSM полето от интерфейса на агента (Ticket::Type трябва да бъде активиран).';
    $Self->{Translation}->{'Sets the ticket type in the decision screen of the agent interface (Ticket::Type needs to be activated).'} =
        'Задава типа билет в екрана за решение от интерфейса на агента (Ticket::Type трябва да бъде активиран).';
    $Self->{Translation}->{'Sets the ticket type in the ticket priority screen of a zoomed ticket in the agent interface (Ticket::Type needs to be activated).'} =
        'Задава типа билет в екрана с приоритет на билета за увеличен билет в интерфейса на агента (Ticket::Type трябва да бъде активиран).';
    $Self->{Translation}->{'Shows a link in the menu to change the decision of a ticket in its zoom view of the agent interface.'} =
        'Показва връзка в менюто за промяна на решението за билет в неговия увеличен изглед от интерфейса на агента.';
    $Self->{Translation}->{'Shows a link in the menu to modify additional ITSM fields in the ticket zoom view of the agent interface.'} =
        'Показва връзка в менюто за модифициране на допълнителни ITSM полета в изгледа за увеличение на билета от интерфейса на агента.';
    $Self->{Translation}->{'Shows a list of all the involved agents on this ticket, in the additional ITSM field screen of the agent interface.'} =
        'Показва списък на всички включени агенти в този билет в допълнителния екран на ITSM полето от интерфейса на агента.';
    $Self->{Translation}->{'Shows a list of all the involved agents on this ticket, in the decision screen of the agent interface.'} =
        'Показва списък на всички включени агенти в този билет в екрана за решение от интерфейса на агента.';
    $Self->{Translation}->{'Shows a list of all the possible agents (all agents with note permissions on the queue/ticket) to determine who should be informed about this note, in the additional ITSM field screen of the agent interface.'} =
        'Показва списък с всички възможни агенти (всички агенти с разрешения за бележки в опашката/билета), за да определи кой трябва да бъде информиран за тази бележка, в допълнителния екран на ITSM поле от интерфейса на агента.';
    $Self->{Translation}->{'Shows a list of all the possible agents (all agents with note permissions on the queue/ticket) to determine who should be informed about this note, in the decision screen of the agent interface.'} =
        'Показва списък с всички възможни агенти (всички агенти с разрешения за бележка в опашката/билета), за да определи кой трябва да бъде информиран за тази бележка в екрана за решение на интерфейса на агента.';
    $Self->{Translation}->{'Shows the ticket priority options in the additional ITSM field screen of the agent interface.'} =
        'Показва опциите за приоритет на билета в допълнителния екран на ITSM полето от интерфейса на агента.';
    $Self->{Translation}->{'Shows the ticket priority options in the decision screen of the agent interface.'} =
        'Показва опциите за приоритет на билета в екрана за решение от интерфейса на агента.';
    $Self->{Translation}->{'Shows the title fields in the additional ITSM field screen of the agent interface.'} =
        'Показва полетата за заглавие в допълнителния екран на ITSM поле от интерфейса на агента.';
    $Self->{Translation}->{'Shows the title fields in the decision screen of the agent interface.'} =
        'Показва полетата за заглавие в екрана за решение от интерфейса на агента.';
    $Self->{Translation}->{'Ticket decision.'} = 'Решение за билет.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Service Incident State',
    );

}

1;
