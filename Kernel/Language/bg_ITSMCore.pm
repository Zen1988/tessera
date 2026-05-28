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

package Kernel::Language::bg_ITSMCore;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AdminITSMCIPAllocate
    $Self->{Translation}->{'Criticality ↔ Impact ↔ Priority'} = 'Критичност ↔ Влияние ↔ Приоритет';
    $Self->{Translation}->{'Manage the priority result of combinating Criticality ↔ Impact.'} =
        'Управлявайте приоритетния резултат от комбинирането на Критичност ↔ Въздействие.';
    $Self->{Translation}->{'Priority allocation'} = 'Приоритетно разпределение';

    # Template: AdminSLA
    $Self->{Translation}->{'Minimum Time Between Incidents'} = 'Минимално време между инцидентите';

    # Template: AdminService
    $Self->{Translation}->{'Criticality'} = 'Критичност';

    # Template: AgentITSMSLAZoom
    $Self->{Translation}->{'SLA Information'} = 'Информация за SLA';
    $Self->{Translation}->{'Last changed'} = 'Последна промяна';
    $Self->{Translation}->{'Last changed by'} = 'Последно променен от';
    $Self->{Translation}->{'Associated Services'} = 'Свързани услуги';

    # Template: AgentITSMServiceZoom
    $Self->{Translation}->{'Service Information'} = 'Сервизна информация';
    $Self->{Translation}->{'Current incident state'} = 'Текущо състояние на инцидента';
    $Self->{Translation}->{'Associated SLAs'} = 'Свързани SLA договори';

    # Template: TicketInformation
    $Self->{Translation}->{'Service Incident State'} = '';
    $Self->{Translation}->{'Service Criticality'} = '';

    # Perl Module: Kernel/Modules/AdminITSMCIPAllocate.pm
    $Self->{Translation}->{'Impact'} = 'Влияние';

    # Perl Module: Kernel/Modules/AgentITSMSLAPrint.pm
    $Self->{Translation}->{'No SLAID is given!'} = 'Не определен SLAID!';
    $Self->{Translation}->{'SLAID %s not found in database!'} = 'SLAID %s не е намерен в базата данни!';
    $Self->{Translation}->{'Calendar Default'} = 'Календар по подразбиране';

    # Perl Module: Kernel/Modules/AgentITSMSLAZoom.pm
    $Self->{Translation}->{'operational'} = 'оперативен';
    $Self->{Translation}->{'warning'} = 'внимание';
    $Self->{Translation}->{'incident'} = 'инцидент';

    # Perl Module: Kernel/Modules/AgentITSMServicePrint.pm
    $Self->{Translation}->{'No ServiceID is given!'} = 'Не е даден ID на услугата!';
    $Self->{Translation}->{'ServiceID %s not found in database!'} = 'ID на услугата %s не е намерен в базата данни!';
    $Self->{Translation}->{'Current Incident State'} = 'Текущо състояние на инцидента';

    # Perl Module: Kernel/Output/HTML/LinkObject/Service.pm
    $Self->{Translation}->{'Incident State'} = 'Състояние на инцидента';

    # Database XML / SOPM Definition: ITSMCore.sopm
    $Self->{Translation}->{'Operational'} = 'Оперативен';
    $Self->{Translation}->{'Incident'} = 'Инцидент';
    $Self->{Translation}->{'End User Service'} = 'Услуги за крайни потребители';
    $Self->{Translation}->{'Front End'} = 'Клиентски интерфейс';
    $Self->{Translation}->{'Back End'} = 'Сървърна част';
    $Self->{Translation}->{'IT Management'} = 'Управление на ИТ';
    $Self->{Translation}->{'Reporting'} = 'Отчетност';
    $Self->{Translation}->{'IT Operational'} = 'ИТ Операции';
    $Self->{Translation}->{'Demonstration'} = 'Демонстрация';
    $Self->{Translation}->{'Project'} = 'Проект';
    $Self->{Translation}->{'Underpinning Contract'} = 'Основен договор';
    $Self->{Translation}->{'Other'} = 'Други';
    $Self->{Translation}->{'Availability'} = 'Достъпност';
    $Self->{Translation}->{'Response Time'} = 'Време за отговор';
    $Self->{Translation}->{'Recovery Time'} = 'Време за възстановяване';
    $Self->{Translation}->{'Resolution Rate'} = 'Време за разрешаване';
    $Self->{Translation}->{'Transactions'} = 'Сделки/транзакции';
    $Self->{Translation}->{'Errors'} = 'Грешки';

    # SysConfig
    $Self->{Translation}->{'Alternative to'} = 'Алтернативен на';
    $Self->{Translation}->{'Both'} = 'И двете';
    $Self->{Translation}->{'CIPAllocation: Overwrite priority based on Criticality and Impact. Default fallback: Frontend::CIPAllocationDefault.'} =
        '';
    $Self->{Translation}->{'Connected to'} = 'Свързан с';
    $Self->{Translation}->{'Default behavior of priority allocation in the frontends based on Criticality and Impact. Can be overruled by frontend specific PriorityByCIP settings.'} =
        '';
    $Self->{Translation}->{'Define Actions where a settings button is available in the linked objects widget (LinkObject::ViewMode = "complex"). Please note that these Actions must have registered the following JS and CSS files: Core.AllocationList.css, Core.UI.AllocationList.js, Core.UI.Table.Sort.js, Core.Agent.TableFilters.js and Core.Agent.LinkObject.js.'} =
        'Дефинирайте действия, при които е наличен бутон за настройки в приспособлението за свързани обекти (LinkObject::ViewMode = "complex"). Моля, обърнете внимание, че тези действия трябва да са регистрирали следните JS и CSS файлове: Core.AllocationList.css, Core.UI.AllocationList.js, Core.UI.Table.Sort.js, Core.Agent.TableFilters.js и Core.Agent .LinkObject.js.';
    $Self->{Translation}->{'Define which columns are shown in the linked Services widget (LinkObject::ViewMode = "complex"). Note: Only Service attributes are allowed for DefaultColumns. Possible settings: 0 = Disabled, 1 = Available, 2 = Enabled by default.'} =
        'Определете кои колони да се показват в приспособлението за свързани услуги (LinkObject::ViewMode = "complex"). Забележка: Само атрибути на услугата са разрешени за колони по подразбиране. Възможни настройки: 0 = Забранено, 1 = Налично, 2 = Активирано по подразбиране.';
    $Self->{Translation}->{'Defines the list of online repositories. Another installation can be used as repository, for example: Key="http://example.com/otobo/public.pl?Action=PublicRepository;File=" and Content="Some Name".'} =
        '';
    $Self->{Translation}->{'Depends on'} = 'Зависи от';
    $Self->{Translation}->{'Enforce'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminITSMCIPAllocate configuration in the admin area.'} =
        'Регистрация на фронтенд модул за конфигурацията AdminITSMCIPAllocate в областта за администриране.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMSLA object in the agent interface.'} =
        'Регистрация на преден модул за обекта AgentITSMSLA в интерфейса на агента.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMSLAPrint object in the agent interface.'} =
        'Регистрация на преден модул за обекта AgentITMSLAPrint в интерфейса на агента.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMSLAZoom object in the agent interface.'} =
        'Регистрация на преден модул за обекта AgentITSMSLAZoom в интерфейса на агента.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMService object in the agent interface.'} =
        'Регистрация на преден модул за обекта AgentITSMService в интерфейса на агента.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMServicePrint object in the agent interface.'} =
        'Регистрация на преден модул за обекта AgentITSMServicePrint в интерфейса на агента.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMServiceZoom object in the agent interface.'} =
        'Регистрация на преден модул за обекта AgentITSMServiceZoom в интерфейса на агента.';
    $Self->{Translation}->{'ITSM SLA Overview.'} = 'Преглед на ITSM SLA.';
    $Self->{Translation}->{'ITSM Service Overview.'} = 'Преглед на услугата ITSM.';
    $Self->{Translation}->{'Incident State Type'} = 'Тип състояние на инцидента';
    $Self->{Translation}->{'Includes'} = 'Включени';
    $Self->{Translation}->{'Located in'} = '';
    $Self->{Translation}->{'Location of'} = '';
    $Self->{Translation}->{'Manage priority matrix.'} = 'Управление на приоритетната матрица.';
    $Self->{Translation}->{'Manage the criticality - impact - priority matrix.'} = 'Управлявайте матрицата критичност – въздействие – приоритет.';
    $Self->{Translation}->{'Module to show the Back menu item in SLA menu.'} = 'Модул за показване на елемента от менюто Назад в менюто на SLA.';
    $Self->{Translation}->{'Module to show the Back menu item in service menu.'} = 'Модул за показване на елемента от менюто Назад в сервизното меню.';
    $Self->{Translation}->{'Module to show the Link menu item in service menu.'} = 'Модул за показване на елемента от менюто Link в сервизното меню.';
    $Self->{Translation}->{'Module to show the Print menu item in SLA menu.'} = 'Модул за показване на елемента от менюто Печат в менюто SLA.';
    $Self->{Translation}->{'Module to show the Print menu item in service menu.'} = 'Модул за показване на елемента от менюто Печат в сервизното меню.';
    $Self->{Translation}->{'Off'} = '';
    $Self->{Translation}->{'Parameters for the incident states in the preference view.'} = 'Параметри за състоянията на инцидента в изгледа на предпочитанията.';
    $Self->{Translation}->{'Part of'} = 'Част от';
    $Self->{Translation}->{'Relevant to'} = 'Съответен с';
    $Self->{Translation}->{'Required for'} = 'Необходим за';
    $Self->{Translation}->{'SLA Overview'} = 'Преглед на SLA';
    $Self->{Translation}->{'SLA Print.'} = 'Печат на SLA.';
    $Self->{Translation}->{'SLA Zoom.'} = 'Подробности за SLA.';
    $Self->{Translation}->{'Service Overview'} = 'Преглед на услугата';
    $Self->{Translation}->{'Service Print.'} = 'Сервизен печат.';
    $Self->{Translation}->{'Service Zoom.'} = 'Подробности за услугата.';
    $Self->{Translation}->{'Service-Area'} = 'Обслужваща зона';
    $Self->{Translation}->{'Set the type and direction of links to be used to calculate the incident state. The key is the name of the link type (as defined in LinkObject::Type), and the value is the direction of the IncidentLinkType that should be followed to calculate the incident state. For example if the IncidentLinkType is set to \'DependsOn\', and the Direction is \'Source\', only \'Depends on\' links will be followed (and not the opposite link \'Required for\') to calculate the incident state. You can add more link types ad directions as you like, e.g. \'Includes\' with the direction \'Target\'. All link types defined in the sysconfig options LinkObject::Type are possible and the direction can be \'Source\', \'Target\', or \'Both\'. IMPORTANT: AFTER YOU MAKE CHANGES TO THIS SYSCONFIG OPTION YOU NEED TO RUN THE CONSOLE COMMAND bin/otobo.Console.pl Admin::ITSM::IncidentState::Recalculate SO THAT ALL INCIDENT STATES WILL BE RECALCULATED BASED ON THE NEW SETTINGS!'} =
        'Задайте типа и посоката на връзките, които да се използват за изчисляване на състоянието на инцидента. Ключът е името на типа връзка (както е дефинирано в LinkObject::Type), а стойността е посоката на IncidentLinkType, която трябва да се следва, за да се изчисли състоянието на инцидента. Например, ако IncidentLinkType е зададен на „DependsOn“ и посоката е „Source“, ще се следват само връзки „Depends on“ (а не обратната връзка „Required for“), за да се изчисли състоянието на инцидента. Можете да добавите повече типове връзки рекламни указания, както желаете, напр. „Включва“ с посока „Цел“. Всички типове връзки, дефинирани в опциите на sysconfig, LinkObject::Type са възможни и посоката може да бъде „Източник“, „Цел“ или „И двете“. ВАЖНО: СЛЕД КАТО НАПРАВИТЕ ПРОМЕНИ В ТАЗИ ОПЦИЯ НА SYSCONFIG, ТРЯБВА ДА ИЗПЪЛНИТЕ КОНЗОЛНАТА КОМАНДА bin/otobo.Console.pl Admin::ITSM::IncidentState::Recalculate, ТАКА ЧЕ ВСИЧКИ СЪСТОЯНИЯ НА ИНЦИДЕНТИ ЩЕ БЪДАТ ПРЕИЗЧИСЛЕНИ ВЪЗ НОВИТЕ НАСТРОЙКИ!';
    $Self->{Translation}->{'Show the current service incident state signal in the ticket information.'} =
        '';
    $Self->{Translation}->{'Source'} = 'Източник';
    $Self->{Translation}->{'Suggest'} = '';
    $Self->{Translation}->{'This setting defines that a \'ITSMChange\' object can be linked with \'Ticket\' objects using the \'Normal\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMChange“ може да бъде свързан с обекти „Ticket“ с помощта на типа връзка „Normal“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'FAQ\' objects using the \'Normal\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMConfigItem“ може да бъде свързан с обекти „ЧЗВ“, като се използва типът връзка „Нормален“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'FAQ\' objects using the \'ParentChild\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMConfigItem“ може да бъде свързан с обекти „ЧЗВ“ с помощта на типа връзка „ParentChild“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'FAQ\' objects using the \'RelevantTo\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMConfigItem“ може да бъде свързан с обекти „ЧЗВ“ с помощта на типа връзка „RelevantTo“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Service\' objects using the \'AlternativeTo\' link type.'} =
        'Тази настройка определя, че обект „ITSMConfigItem“ може да бъде свързан с обекти „Service“ с помощта на типа връзка „AlternativeTo“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Service\' objects using the \'DependsOn\' link type.'} =
        'Тази настройка определя, че обект „ITSMConfigItem“ може да бъде свързан с обекти „Service“, използвайки типа връзка „DependsOn“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Service\' objects using the \'RelevantTo\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMConfigItem“ може да бъде свързан с обекти „Service“ с помощта на типа връзка „RelevantTo“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Ticket\' objects using the \'AlternativeTo\' link type.'} =
        'Тази настройка определя, че обект „ITSMConfigItem“ може да бъде свързан с обекти „Ticket“ с помощта на типа връзка „AlternativeTo“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Ticket\' objects using the \'DependsOn\' link type.'} =
        'Тази настройка определя, че обект „ITSMConfigItem“ може да бъде свързан с обекти „Ticket“ с помощта на типа връзка „DependsOn“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Ticket\' objects using the \'RelevantTo\' link type.'} =
        'Тази настройка определя, че обект „ITSMConfigItem“ може да бъде свързан с обекти „Ticket“ с помощта на типа връзка „RelevantTo“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'AlternativeTo\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMConfigItem“ може да бъде свързан с други обекти „ITSMConfigItem“ с помощта на типа връзка „Алтернатива към“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'ConnectedTo\' link type.'} =
        'Тази настройка дефинира, че обектът „ITSMConfigItem“ може да бъде свързан с други обекти „ITSMConfigItem“, използвайки типа връзка „ConnectedTo“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'DependsOn\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMConfigItem“ може да бъде свързан с други обекти „ITSMConfigItem“ с помощта на типа връзка „DependsOn“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'Includes\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMConfigItem“ може да бъде свързан с други обекти „ITSMConfigItem“ с помощта на типа връзка „Включва“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'LocationOf\' link type.'} =
        '';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'RelevantTo\' link type.'} =
        'Тази настройка дефинира, че обектът „ITSMConfigItem“ може да бъде свързан с други обекти „ITSMConfigItem“, използвайки типа връзка „RelevantTo“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'ITSMConfigItem\' objects using the \'DependsOn\' link type.'} =
        'Тази настройка дефинира, че „ITSMConfigItem“ може да бъде свързан с други обекти „ITSMConfigItem“ с помощта на връзката „Включва“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'ITSMConfigItem\' objects using the \'Normal\' link type.'} =
        'Тази настройка определя, че обект „ITSMWorkOrder“ може да бъде свързан с обекти „ITSMConfigItem“, като се използва тип връзка „Нормален“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'Service\' objects using the \'DependsOn\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMWorkOrder“ може да бъде свързан с обекти „Service“ с помощта на типа връзка „DependsOn“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'Service\' objects using the \'Normal\' link type.'} =
        'Тази настройка определя, че обект „ITSMWorkOrder“ може да бъде свързан с обекти „Service“, като се използва тип връзка „Normal“.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'Ticket\' objects using the \'Normal\' link type.'} =
        'Тази настройка дефинира, че обект „ITSMWorkOrder“ може да бъде свързан с обекти „Ticket“, като се използва тип връзка „Нормален“.';
    $Self->{Translation}->{'This setting defines that a \'Service\' object can be linked with \'FAQ\' objects using the \'Normal\' link type.'} =
        'Тази настройка определя, че обект „Услуга“ може да бъде свързан с обекти „Често задавани въпроси“, като се използва тип връзка „Нормален“.';
    $Self->{Translation}->{'This setting defines that a \'Service\' object can be linked with \'FAQ\' objects using the \'ParentChild\' link type.'} =
        'Тази настройка определя, че обект „Услуга“ може да бъде свързан с обекти „Често задавани въпроси“ с помощта на типа връзка „Родител-дете“.';
    $Self->{Translation}->{'This setting defines that a \'Service\' object can be linked with \'FAQ\' objects using the \'RelevantTo\' link type.'} =
        'Тази настройка дефинира, че обект „Услуга“ може да бъде свързан с обекти „Често задавани въпроси“ с помощта на типа връзка „Съответно на“.';
    $Self->{Translation}->{'This setting defines the link type \'AlternativeTo\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Тази настройка дефинира типа връзка „Алтернатива на“. Ако името на източника и името на целта съдържат една и съща стойност, получената връзка е не насочена. Ако стойностите са различни, получената връзка е насочена връзка.';
    $Self->{Translation}->{'This setting defines the link type \'ConnectedTo\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Тази настройка дефинира типа връзка „Свързан с“. Ако името на източника и името на целта съдържат една и съща стойност, получената връзка е не насочена. Ако стойностите са различни, получената връзка е насочена връзка.';
    $Self->{Translation}->{'This setting defines the link type \'DependsOn\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Тази настройка дефинира типа връзка „DependsOn“. Ако името на източника и името на целта съдържат една и съща стойност, получената връзка е не насочена. Ако стойностите са различни, получената връзка е насочена връзка.';
    $Self->{Translation}->{'This setting defines the link type \'Includes\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Тази настройка дефинира типа връзка „Включва“. Ако името на източника и името на целта съдържат една и съща стойност, получената връзка не е насочена. Ако стойностите са различни, получената връзка е насочена връзка.';
    $Self->{Translation}->{'This setting defines the link type \'LocationOf\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        '';
    $Self->{Translation}->{'This setting defines the link type \'RelevantTo\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Тази настройка дефинира типа връзка „Съответно на“. Ако името на източника и името на целта съдържат една и съща стойност, получената връзка не е насочена. Ако стойностите са различни, получената връзка е насочена връзка.';
    $Self->{Translation}->{'Width of ITSM textareas.'} = 'Ширина на ITSM текстовите области.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
