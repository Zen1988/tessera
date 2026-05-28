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

package Kernel::Language::sr_Latn_ITSMCore;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AdminITSMCIPAllocate
    $Self->{Translation}->{'Criticality ↔ Impact ↔ Priority'} = '';
    $Self->{Translation}->{'Manage the priority result of combinating Criticality ↔ Impact.'} =
        '';
    $Self->{Translation}->{'Priority allocation'} = '';

    # Template: AdminSLA
    $Self->{Translation}->{'Minimum Time Between Incidents'} = '';

    # Template: AdminService
    $Self->{Translation}->{'Criticality'} = '';

    # Template: AgentITSMSLAZoom
    $Self->{Translation}->{'SLA Information'} = '';
    $Self->{Translation}->{'Last changed'} = '';
    $Self->{Translation}->{'Last changed by'} = '';
    $Self->{Translation}->{'Associated Services'} = '';

    # Template: AgentITSMServiceZoom
    $Self->{Translation}->{'Service Information'} = '';
    $Self->{Translation}->{'Current incident state'} = '';
    $Self->{Translation}->{'Associated SLAs'} = '';

    # Template: TicketInformation
    $Self->{Translation}->{'Service Incident State'} = '';
    $Self->{Translation}->{'Service Criticality'} = '';

    # Perl Module: Kernel/Modules/AdminITSMCIPAllocate.pm
    $Self->{Translation}->{'Impact'} = '';

    # Perl Module: Kernel/Modules/AgentITSMSLAPrint.pm
    $Self->{Translation}->{'No SLAID is given!'} = '';
    $Self->{Translation}->{'SLAID %s not found in database!'} = '';
    $Self->{Translation}->{'Calendar Default'} = '';

    # Perl Module: Kernel/Modules/AgentITSMSLAZoom.pm
    $Self->{Translation}->{'operational'} = '';
    $Self->{Translation}->{'warning'} = '';
    $Self->{Translation}->{'incident'} = '';

    # Perl Module: Kernel/Modules/AgentITSMServicePrint.pm
    $Self->{Translation}->{'No ServiceID is given!'} = '';
    $Self->{Translation}->{'ServiceID %s not found in database!'} = '';
    $Self->{Translation}->{'Current Incident State'} = '';

    # Perl Module: Kernel/Output/HTML/LinkObject/Service.pm
    $Self->{Translation}->{'Incident State'} = '';

    # Database XML / SOPM Definition: ITSMCore.sopm
    $Self->{Translation}->{'Operational'} = '';
    $Self->{Translation}->{'Incident'} = '';
    $Self->{Translation}->{'End User Service'} = '';
    $Self->{Translation}->{'Front End'} = '';
    $Self->{Translation}->{'Back End'} = '';
    $Self->{Translation}->{'IT Management'} = '';
    $Self->{Translation}->{'Reporting'} = '';
    $Self->{Translation}->{'IT Operational'} = '';
    $Self->{Translation}->{'Demonstration'} = '';
    $Self->{Translation}->{'Project'} = '';
    $Self->{Translation}->{'Underpinning Contract'} = '';
    $Self->{Translation}->{'Other'} = '';
    $Self->{Translation}->{'Availability'} = '';
    $Self->{Translation}->{'Response Time'} = '';
    $Self->{Translation}->{'Recovery Time'} = '';
    $Self->{Translation}->{'Resolution Rate'} = '';
    $Self->{Translation}->{'Transactions'} = '';
    $Self->{Translation}->{'Errors'} = '';

    # SysConfig
    $Self->{Translation}->{'Alternative to'} = 'Alternativa za';
    $Self->{Translation}->{'Both'} = 'Oba';
    $Self->{Translation}->{'CIPAllocation: Overwrite priority based on Criticality and Impact. Default fallback: Frontend::CIPAllocationDefault.'} =
        '';
    $Self->{Translation}->{'Connected to'} = 'Povezano na';
    $Self->{Translation}->{'Default behavior of priority allocation in the frontends based on Criticality and Impact. Can be overruled by frontend specific PriorityByCIP settings.'} =
        '';
    $Self->{Translation}->{'Define Actions where a settings button is available in the linked objects widget (LinkObject::ViewMode = "complex"). Please note that these Actions must have registered the following JS and CSS files: Core.AllocationList.css, Core.UI.AllocationList.js, Core.UI.Table.Sort.js, Core.Agent.TableFilters.js and Core.Agent.LinkObject.js.'} =
        'Definiše Akcije gde je dugme postavki dostupno u povezanom grafičkom elementu objekta (LinkObject::ViewMode = "complex"). Molimo da imate na umu da ove Akcije moraju da budu registrovane u sledećim JS i CSS datotekama: Core.AllocationList.css, Core.UI.AllocationList.js, Core.UI.Table.Sort.js, Core.Agent.TableFilters.js i Core.Agent.LinkObject.js.';
    $Self->{Translation}->{'Define which columns are shown in the linked Services widget (LinkObject::ViewMode = "complex"). Note: Only Service attributes are allowed for DefaultColumns. Possible settings: 0 = Disabled, 1 = Available, 2 = Enabled by default.'} =
        'Definiše koje kolone su prikazane u povezanom grafičkom elementu Servisa (LinkObject::ViewMode = "complex"). Napomena: Samo atributi servisa su dozvoljeni za podrazumevane kolone. Moguće postavke: 0 = onemogućeno, 1 = dostupno, 2 = podrazumevano aktivirano.';
    $Self->{Translation}->{'Defines the list of online repositories. Another installation can be used as repository, for example: Key="http://example.com/otobo/public.pl?Action=PublicRepository;File=" and Content="Some Name".'} =
        '';
    $Self->{Translation}->{'Depends on'} = 'Zavisi od';
    $Self->{Translation}->{'Enforce'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminITSMCIPAllocate configuration in the admin area.'} =
        'Registracija pristupnog modula za konfiguraciju AdminITSMCIPAllocate u prostoru administratora.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMSLA object in the agent interface.'} =
        'Registracija pristupnog modula za konfiguraciju AgentITSMSLA objekta u interfejsu operatera.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMSLAPrint object in the agent interface.'} =
        'Registracija pristupnog modula za konfiguraciju AgentITSMSLAPrint objekta u interfejsu operatera.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMSLAZoom object in the agent interface.'} =
        'Registracija pristupnog modula za konfiguraciju AgentITSMSLAZoom objekta u interfejsu operatera.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMService object in the agent interface.'} =
        'Registracija pristupnog modula za konfiguraciju AgentITSMService objekta u interfejsu operatera.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMServicePrint object in the agent interface.'} =
        'Registracija pristupnog modula za konfiguraciju AgentITSMServicePrint objekta u interfejsu operatera.';
    $Self->{Translation}->{'Frontend module registration for the AgentITSMServiceZoom object in the agent interface.'} =
        'Registracija pristupnog modula za konfiguraciju AgentITSMServiceZoom objekta u interfejsu operatera.';
    $Self->{Translation}->{'ITSM SLA Overview.'} = 'ITSM pregled SLA.';
    $Self->{Translation}->{'ITSM Service Overview.'} = 'ITSM pregled servisa.';
    $Self->{Translation}->{'Incident State Type'} = 'Tip stanja incidenta';
    $Self->{Translation}->{'Includes'} = 'Uključuje';
    $Self->{Translation}->{'Located in'} = '';
    $Self->{Translation}->{'Location of'} = '';
    $Self->{Translation}->{'Manage priority matrix.'} = 'Urediti matricu prioriteta';
    $Self->{Translation}->{'Manage the criticality - impact - priority matrix.'} = 'Uređivanje matrica značaj - uticaj - prioritet.';
    $Self->{Translation}->{'Module to show the Back menu item in SLA menu.'} = 'Modul za prikaz veze za vraćanje u SLA meniju.';
    $Self->{Translation}->{'Module to show the Back menu item in service menu.'} = 'Modul za prikaz veze za vraćanje u servisnom meniju.';
    $Self->{Translation}->{'Module to show the Link menu item in service menu.'} = 'Modul za prikaz veze u servisnom meniju.';
    $Self->{Translation}->{'Module to show the Print menu item in SLA menu.'} = 'Modul za prikaz veze za štampu u SLA meniju.';
    $Self->{Translation}->{'Module to show the Print menu item in service menu.'} = 'Modul za prikaz veze za štampu u servisnom meniju.';
    $Self->{Translation}->{'Off'} = '';
    $Self->{Translation}->{'Parameters for the incident states in the preference view.'} = 'Parametri za incidentne statuse u prikazu podešavanja.';
    $Self->{Translation}->{'Part of'} = 'Sastavni deo';
    $Self->{Translation}->{'Relevant to'} = 'U zavisnosti';
    $Self->{Translation}->{'Required for'} = 'Obavezno za';
    $Self->{Translation}->{'SLA Overview'} = 'Pregled SLA';
    $Self->{Translation}->{'SLA Print.'} = 'Štampa SLA.';
    $Self->{Translation}->{'SLA Zoom.'} = 'Detalji SLA.';
    $Self->{Translation}->{'Service Overview'} = 'Pregled servisa';
    $Self->{Translation}->{'Service Print.'} = 'Štampa servisa.';
    $Self->{Translation}->{'Service Zoom.'} = 'Detalji servisa.';
    $Self->{Translation}->{'Service-Area'} = 'Prostor servisa';
    $Self->{Translation}->{'Set the type and direction of links to be used to calculate the incident state. The key is the name of the link type (as defined in LinkObject::Type), and the value is the direction of the IncidentLinkType that should be followed to calculate the incident state. For example if the IncidentLinkType is set to \'DependsOn\', and the Direction is \'Source\', only \'Depends on\' links will be followed (and not the opposite link \'Required for\') to calculate the incident state. You can add more link types ad directions as you like, e.g. \'Includes\' with the direction \'Target\'. All link types defined in the sysconfig options LinkObject::Type are possible and the direction can be \'Source\', \'Target\', or \'Both\'. IMPORTANT: AFTER YOU MAKE CHANGES TO THIS SYSCONFIG OPTION YOU NEED TO RUN THE CONSOLE COMMAND bin/otobo.Console.pl Admin::ITSM::IncidentState::Recalculate SO THAT ALL INCIDENT STATES WILL BE RECALCULATED BASED ON THE NEW SETTINGS!'} =
        'Podešava tip i smer veza koji će se koristiti za utvrđivanje stanja incidenta. Ključ je naziv tipa veze (kao što je definisano u LinkObject::Type), a vrednost je smer IncidentLinkType koji treba ispratiti za određivanje stanja incidenta. Na primer, ako je IncidentLinkType podešen na DependsOn i smer je Source, samo veza "Zavisi od" će biti praćena (a neće i suprotna veza "Neophodno za") u određivanju stanja incidenta. Ukoliko želite može dodati još tipova i smerova veza, npr. "Uključuje" sa smerom "Cilj". Svi tipovi veza definisani u sistemskoj konfiguraciji LinkObject::Type su mogući i smer može biti "Izvor", "Cilj" ili "Oba". VAŽNO: NAKON IZMENE OPCIJA SISTEMSKE KONFIGURACIJE MORATE POKRENUTI SKRIPT bin/otobo.Console.pl Admin::ITSM::IncidentState::Recalculate DA BI SVA STANJA INCIDENTA BILA PONOVO UTVRĐENA NA OSNOVU NOVIH PODEŠAVANJA!';
    $Self->{Translation}->{'Show the current service incident state signal in the ticket information.'} =
        '';
    $Self->{Translation}->{'Source'} = 'Izvor';
    $Self->{Translation}->{'Suggest'} = '';
    $Self->{Translation}->{'This setting defines that a \'ITSMChange\' object can be linked with \'Ticket\' objects using the \'Normal\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "Normal" objekat ITSM promena može da se poveže sa objektom tiketa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'FAQ\' objects using the \'Normal\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "Normal" objekat ITSM konfiguraciona stavka može da se poveže sa objektom FAQ.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'FAQ\' objects using the \'ParentChild\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa ParentChild objekat ITSM konfiguraciona stavka može da se poveže sa objektom FAQ.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'FAQ\' objects using the \'RelevantTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "RelevantTo" objekat ITSM konfiguraciona stavka može da se poveže sa objektom FAQ.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Service\' objects using the \'AlternativeTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "AlternativeTo" objekat ITSM konfiguraciona stavka može da se poveže sa objektom servisa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Service\' objects using the \'DependsOn\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "DependsOn" objekat ITSM konfiguraciona stavka može da se poveže sa objektom servisa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Service\' objects using the \'RelevantTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "RelevantTo" objekat ITSM konfiguraciona stavka može da se poveže sa objektom servisa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Ticket\' objects using the \'AlternativeTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "AlternativeTo" objekat ITSM konfiguraciona stavka može da se poveže sa objektom tiketa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Ticket\' objects using the \'DependsOn\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "DependsOn" objekat ITSM konfiguraciona stavka može da se poveže sa objektom tiketa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with \'Ticket\' objects using the \'RelevantTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "RelevantTo" objekat ITSM konfiguraciona stavka može da se poveže sa objektom tiketa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'AlternativeTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "AlternativeTo" objekat ITSM konfiguraciona stavka može da se poveže sa drugim objektom ITSM konfiguraciona stavka.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'ConnectedTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "ConnectedTo" objekat ITSM konfiguraciona stavka može da se poveže sa drugim objektom ITSM konfiguraciona stavka.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'DependsOn\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "DependsOn" objekat ITSM konfiguraciona stavka može da se poveže sa drugim objektom ITSM konfiguraciona stavka.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'Includes\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "Includes" objekat ITSM konfiguraciona stavka može da se poveže sa drugim objektom ITSM konfiguraciona stavka.';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'LocationOf\' link type.'} =
        '';
    $Self->{Translation}->{'This setting defines that a \'ITSMConfigItem\' object can be linked with other \'ITSMConfigItem\' objects using the \'RelevantTo\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "RelevantTo" objekat ITSM konfiguraciona stavka može da se poveže sa drugim objektom ITSM konfiguraciona stavka.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'ITSMConfigItem\' objects using the \'DependsOn\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "DependsOn" objekat ITSM radni nalog može da se poveže sa objektom ITSM konfiguraciona stavka.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'ITSMConfigItem\' objects using the \'Normal\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "Normal" objekat ITSM radni nalog može da se poveže sa objektom ITSM konfiguraciona stavka.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'Service\' objects using the \'DependsOn\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "DependsOn" objekat ITSM radni nalog može da se poveže sa objektom servisa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'Service\' objects using the \'Normal\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "Normal" objekat ITSM radni nalog može da se poveže sa objektom servisa.';
    $Self->{Translation}->{'This setting defines that a \'ITSMWorkOrder\' object can be linked with \'Ticket\' objects using the \'Normal\' link type.'} =
        'Ovo podešavanje određuje da li vezom tipa "Normal" objekat ITSM radni nalog može da se poveže sa objektom tiketa.';
    $Self->{Translation}->{'This setting defines that a \'Service\' object can be linked with \'FAQ\' objects using the \'Normal\' link type.'} =
        'Ovo podešavanje određuje da objekat servis može da se poveže sa objektom FAQ vezom tipa "Normal".';
    $Self->{Translation}->{'This setting defines that a \'Service\' object can be linked with \'FAQ\' objects using the \'ParentChild\' link type.'} =
        'Ovo podešavanje određuje da objekat servis može da se poveže sa objektom FAQ vezom tipa "ParentChild".';
    $Self->{Translation}->{'This setting defines that a \'Service\' object can be linked with \'FAQ\' objects using the \'RelevantTo\' link type.'} =
        'Ovo podešavanje određuje da objekat servis može da se poveže sa objektom FAQ vezom tipa "RelevantTo".';
    $Self->{Translation}->{'This setting defines the link type \'AlternativeTo\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Ovo podešavanje definiše vezu tipa "AlternativeTo". Ako izvorni i ciljni naziv sadrže istu vrednost, rezultujuća veza je neusmerena. Ako su vrednosti različite, rezultujuća veza je usmerena.';
    $Self->{Translation}->{'This setting defines the link type \'ConnectedTo\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Ovo podešavanje definiše vezu tipa "ConnectedTo". Ako izvorni i ciljni naziv sadrže istu vrednost, rezultujuća veza je neusmerena. Ako su vrednosti različite, rezultujuća veza je usmerena.';
    $Self->{Translation}->{'This setting defines the link type \'DependsOn\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Ovo podešavanje definiše vezu tipa "DependsOn". Ako izvorni i ciljni naziv sadrže istu vrednost, rezultujuća veza je neusmerena. Ako su vrednosti različite, rezultujuća veza je usmerena.';
    $Self->{Translation}->{'This setting defines the link type \'Includes\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Ovo podešavanje definiše vezu tipa "Includes". Ako izvorni i ciljni naziv sadrže istu vrednost, rezultujuća veza je neusmerena. Ako su vrednosti različite, rezultujuća veza je usmerena.';
    $Self->{Translation}->{'This setting defines the link type \'LocationOf\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        '';
    $Self->{Translation}->{'This setting defines the link type \'RelevantTo\'. If the source name and the target name contain the same value, the resulting link is a non-directional one. If the values are different, the resulting link is a directional link.'} =
        'Ovo podešavanje definiše vezu tipa "RelevantTo". Ako izvorni i ciljni naziv sadrže istu vrednost, rezultujuća veza je neusmerena. Ako su vrednosti različite, rezultujuća veza je usmerena.';
    $Self->{Translation}->{'Width of ITSM textareas.'} = 'Širina ITSM prostora teksta.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
