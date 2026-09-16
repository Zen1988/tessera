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

package Kernel::Language::es_MX_ITSMIncidentProblemManagement;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AgentTicketOverviewMedium
    $Self->{Translation}->{'Criticality'} = 'Criticidad';
    $Self->{Translation}->{'Impact'} = 'Impacto';

    # JS Template: ServiceIncidentState
    $Self->{Translation}->{'Service Incident State'} = 'Estado del Servicio de Incidentes';

    # Perl Module: Kernel/Output/HTML/FilterElementPost/ITSMIncidentProblemManagement.pm
    $Self->{Translation}->{'Link ticket'} = 'Enlazar Ticket';
    $Self->{Translation}->{'Change Decision of %s%s%s'} = 'Cambiar la decisión de %s%s%s';
    $Self->{Translation}->{'Change ITSM fields of %s%s%s'} = 'Cambiar los campos ITSM de %s%s%s';

    # Perl Module: var/packagesetup/ITSMIncidentProblemManagement.pm
    $Self->{Translation}->{'Review Required'} = 'Revisión Requerida';
    $Self->{Translation}->{'Decision Result'} = 'Resultado de la Decisión';
    $Self->{Translation}->{'Approved'} = 'Aprobado';
    $Self->{Translation}->{'Postponed'} = 'Aplazado';
    $Self->{Translation}->{'Pre-approved'} = 'Pre-aprobado';
    $Self->{Translation}->{'Rejected'} = 'Rechazado';
    $Self->{Translation}->{'Repair Start Time'} = 'Hora de inicio de la reparación';
    $Self->{Translation}->{'Recovery Start Time'} = 'Hora de inicio de la recuperación';
    $Self->{Translation}->{'Decision Date'} = 'Fecha de Decisión';
    $Self->{Translation}->{'Due Date'} = 'Fecha de vencimiento';

    # Database XML / SOPM Definition: ITSMIncidentProblemManagement.sopm
    $Self->{Translation}->{'closed with workaround'} = 'Cerrado con una solución';

    # SysConfig
    $Self->{Translation}->{'Add a decision!'} = '¡Agregar una decisión!';
    $Self->{Translation}->{'Additional ITSM Fields'} = 'Campos ITSM Adicionales';
    $Self->{Translation}->{'Additional ITSM ticket fields.'} = 'Campos adicionales del ticket ITSM.';
    $Self->{Translation}->{'Allows adding notes in the additional ITSM field screen of the agent interface.'} =
        'Permite añadir notas en la pantalla de campos adicionales ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Allows adding notes in the decision screen of the agent interface.'} =
        'Permite añadir notas en la pantalla de decisiones de la interfaz del agente.';
    $Self->{Translation}->{'Allows defining new types for ticket (if ticket type feature is enabled).'} =
        'Permite definir nuevos tipos para los tickets (si la funcionalidad de tipo de ticket está habilitada).';
    $Self->{Translation}->{'Change the ITSM fields!'} = '¡Cambiar los campos ITMS!';
    $Self->{Translation}->{'Decision'} = 'Decisión';
    $Self->{Translation}->{'Defines if a ticket lock is required in the additional ITSM field screen of the agent interface (if the ticket isn\'t locked yet, the ticket gets locked and the current agent will be set automatically as its owner).'} =
        'Define si se requiere un bloqueo del ticket en la pantalla del campo adicional ITSM de la interfaz del agente (si el ticket no está bloqueado todavía, el ticket se bloquea y el agente actual se establecerá automáticamente como su propietario).';
    $Self->{Translation}->{'Defines if a ticket lock is required in the decision screen of the agent interface (if the ticket isn\'t locked yet, the ticket gets locked and the current agent will be set automatically as its owner).'} =
        'Define si se requiere un bloqueo del ticket en la pantalla de decisión de la interfaz del agente (si el ticket no está bloqueado todavía, el ticket se bloquea y el agente actual se establece automáticamente como su propietario).';
    $Self->{Translation}->{'Defines if the service incident state should be shown during service selection in the agent interface.'} =
        'Define si el estado de la incidencia del servicio debe mostrarse durante la selección del servicio en la interfaz del agente.';
    $Self->{Translation}->{'Defines the default body of a note in the additional ITSM field screen of the agent interface.'} =
        'Define el cuerpo por defecto de una nota en la pantalla de campos adicionales de ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Defines the default body of a note in the decision screen of the agent interface.'} =
        'Define el cuerpo por defecto de una nota en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Defines the default next state of a ticket after adding a note, in the additional ITSM field screen of the agent interface.'} =
        'Define el siguiente estado por defecto de un ticket después de añadir una nota, en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Defines the default next state of a ticket after adding a note, in the decision screen of the agent interface.'} =
        'Define el siguiente estado por defecto de un ticket después de añadir una nota, en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Defines the default subject of a note in the additional ITSM field screen of the agent interface.'} =
        'Define el asunto por defecto de una nota en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Defines the default subject of a note in the decision screen of the agent interface.'} =
        'Define el asunto por defecto de una nota en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Defines the default ticket priority in the additional ITSM field screen of the agent interface.'} =
        'Define la prioridad del ticket por defecto en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Defines the default ticket priority in the decision screen of the agent interface.'} =
        'Define la prioridad del ticket por defecto en la pantalla de decisiones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the history comment for the additional ITSM field screen action, which gets used for ticket history.'} =
        'Define el comentario del historial para la acción de pantalla del campo ITSM adicional, que se utiliza para el historial del ticket.';
    $Self->{Translation}->{'Defines the history comment for the decision screen action, which gets used for ticket history.'} =
        'Define el comentario del historial para la acción de la pantalla de decisión, que se utiliza para el historial del ticket.';
    $Self->{Translation}->{'Defines the history type for the additional ITSM field screen action, which gets used for ticket history.'} =
        'Define el tipo de historial para la acción de pantalla del campo ITSM adicional, que se utiliza para el historial de tickets.';
    $Self->{Translation}->{'Defines the history type for the decision screen action, which gets used for ticket history.'} =
        'Define el tipo de historial para la acción de la pantalla de decisión, que se utiliza para el historial de tickets.';
    $Self->{Translation}->{'Defines the next state of a ticket after adding a note, in the additional ITSM field screen of the agent interface.'} =
        'Define el siguiente estado de un ticket después de añadir una nota, en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Defines the next state of a ticket after adding a note, in the decision screen of the agent interface.'} =
        'Define el siguiente estado de un ticket después de añadir una nota, en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the additional ITSM field screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de campos adicionales ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the decision screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the ticket zoom screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de zoom del ticket de la interfaz del agente.';
    $Self->{Translation}->{'Enables the stats module to generate statistics about the average of ITSM ticket first level solution rate.'} =
        'Permite que el módulo de estadísticas genere estadísticas sobre el promedio de la tasa de solución de primer nivel de los tickets ITSM.';
    $Self->{Translation}->{'Enables the stats module to generate statistics about the average of ITSM ticket solution.'} =
        'Permite que el módulo de estadísticas genere estadísticas sobre el promedio de la solución de tickets ITSM.';
    $Self->{Translation}->{'If a note is added by an agent, sets the state of a ticket in the additional ITSM field screen of the agent interface.'} =
        'Si un agente añade una nota, establece el estado de un ticket en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'If a note is added by an agent, sets the state of a ticket in the decision screen of the agent interface.'} =
        'Si un agente añade una nota, establece el estado de un ticket en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Modifies the display order of the dynamic field ITSMImpact and other things.'} =
        'Modifica el orden de visualización del campo dinámico ITSMImpact y otras cosas.';
    $Self->{Translation}->{'Module to dynamically show the service incident state and to calculate the priority.'} =
        'Módulo para mostrar dinámicamente el estado de las incidencias del servicio y calcular la prioridad.';
    $Self->{Translation}->{'Required permissions to use the additional ITSM field screen in the agent interface.'} =
        'Permisos necesarios para utilizar la pantalla de campos adicionales de ITSM en la interfaz del agente.';
    $Self->{Translation}->{'Required permissions to use the decision screen in the agent interface.'} =
        'Permisos necesarios para utilizar la pantalla de decisiones en la interfaz del agente.';
    $Self->{Translation}->{'Service Incident State and Priority Calculation'} = 'Estado de los incidentes de servicio y cálculo de la prioridad';
    $Self->{Translation}->{'Sets the service in the additional ITSM field screen of the agent interface (Ticket::Service needs to be activated).'} =
        'Establece el servicio en la pantalla del campo adicional ITSM de la interfaz del agente (es necesario activar Ticket::Service).';
    $Self->{Translation}->{'Sets the service in the decision screen of the agent interface (Ticket::Service needs to be activated).'} =
        'Establece el servicio en la pantalla de decisión de la interfaz del agente (es necesario activar Ticket::Service).';
    $Self->{Translation}->{'Sets the service in the ticket priority screen of a zoomed ticket in the agent interface (Ticket::Service needs to be activated).'} =
        'Define el servicio, en la ventana para cambiar la prioridad de un ticket, en su vista detallada de la interfaz del agente.';
    $Self->{Translation}->{'Sets the ticket owner in the additional ITSM field screen of the agent interface.'} =
        'Establece el propietario del ticket en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Sets the ticket owner in the decision screen of the agent interface.'} =
        'Establece el propietario del ticket en la pantalla de decisiones de la interfaz del agente.';
    $Self->{Translation}->{'Sets the ticket responsible in the additional ITSM field screen of the agent interface.'} =
        'Establece el responsable del ticket en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Sets the ticket responsible in the decision screen of the agent interface.'} =
        'Establece el responsable del ticket en la pantalla de decisiones de la interfaz del agente.';
    $Self->{Translation}->{'Sets the ticket type in the additional ITSM field screen of the agent interface (Ticket::Type needs to be activated).'} =
        'Establece el tipo de ticket en la pantalla del campo adicional ITSM de la interfaz del agente (es necesario activar Ticket::Type).';
    $Self->{Translation}->{'Sets the ticket type in the decision screen of the agent interface (Ticket::Type needs to be activated).'} =
        'Establece el tipo de ticket en la pantalla de decisión de la interfaz del agente (es necesario activar Ticket::Type).';
    $Self->{Translation}->{'Sets the ticket type in the ticket priority screen of a zoomed ticket in the agent interface (Ticket::Type needs to be activated).'} =
        'Define el tipo de ticket, en la ventana para cambiar la prioridad de un ticket, en su vista detallada de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to change the decision of a ticket in its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para cambiar la decisión de un ticket en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to modify additional ITSM fields in the ticket zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para modificar campos ITSM adicionales en la vista de zoom del ticket de la interfaz del agente.';
    $Self->{Translation}->{'Shows a list of all the involved agents on this ticket, in the additional ITSM field screen of the agent interface.'} =
        'Muestra una lista de todos los agentes implicados en este ticket, en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Shows a list of all the involved agents on this ticket, in the decision screen of the agent interface.'} =
        'Muestra una lista de todos los agentes implicados en este ticket, en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Shows a list of all the possible agents (all agents with note permissions on the queue/ticket) to determine who should be informed about this note, in the additional ITSM field screen of the agent interface.'} =
        'Muestra una lista de todos los posibles agentes (todos los agentes con permisos de nota en la cola/ticket) para determinar quién debe ser informado sobre esta nota, en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Shows a list of all the possible agents (all agents with note permissions on the queue/ticket) to determine who should be informed about this note, in the decision screen of the agent interface.'} =
        'Muestra una lista de todos los posibles agentes (todos los agentes con permisos de nota en la cola/ticket) para determinar quién debe ser informado sobre esta nota, en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Shows the ticket priority options in the additional ITSM field screen of the agent interface.'} =
        'Muestra las opciones de prioridad del ticket en la pantalla del campo adicional ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Shows the ticket priority options in the decision screen of the agent interface.'} =
        'Muestra las opciones de prioridad del ticket en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Shows the title fields in the additional ITSM field screen of the agent interface.'} =
        'Muestra los campos de título en la pantalla de campos adicionales de ITSM de la interfaz del agente.';
    $Self->{Translation}->{'Shows the title fields in the decision screen of the agent interface.'} =
        'Muestra los campos de título en la pantalla de decisión de la interfaz del agente.';
    $Self->{Translation}->{'Ticket decision.'} = 'Ticket de Decisión.';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Service Incident State',
    );

}

1;
