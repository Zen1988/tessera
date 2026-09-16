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

package Kernel::Language::es_MX_ITSMChangeManagement;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AdminITSMChangeCIPAllocate
    $Self->{Translation}->{'Category ↔ Impact ↔ Priority'} = 'Categoría ↔ Impacto ↔ Prioridad';
    $Self->{Translation}->{'Manage the priority result of combinating Category ↔ Impact.'} =
        'Gestionar el resultado prioritario de combinar Categoría ↔ Impacto.';
    $Self->{Translation}->{'Priority allocation'} = 'Asignación de prioridad';

    # Template: AdminITSMChangeNotification
    $Self->{Translation}->{'ITSM ChangeManagement Notification Management'} = 'Gestión de notificaciones de gestión de cambios de ITSM';
    $Self->{Translation}->{'Add Notification Rule'} = 'Agregar regla de notificación';
    $Self->{Translation}->{'Edit Notification Rule'} = 'Editar regla de notificación';
    $Self->{Translation}->{'A notification should have a name!'} = '¡Una notificación debe tener un nombre!';
    $Self->{Translation}->{'Name is required.'} = 'el nombre es requerido.';

    # Template: AdminITSMStateMachine
    $Self->{Translation}->{'Admin State Machine'} = 'Administrar estado de la maquina';
    $Self->{Translation}->{'Select a catalog class!'} = '¡Seleccione una clase del catálogo!';
    $Self->{Translation}->{'A catalog class is required!'} = '¡Un catalogo de clases es requerido!';
    $Self->{Translation}->{'Add a state transition'} = 'Adicionar un estado de transición';
    $Self->{Translation}->{'Catalog Class'} = 'Catálogo de clases';
    $Self->{Translation}->{'Object Name'} = 'Nombre del objeto';
    $Self->{Translation}->{'Overview over state transitions for'} = 'Resumen sobre las transiciones de estado para';
    $Self->{Translation}->{'Delete this state transition'} = 'Borrar este estado de transición';
    $Self->{Translation}->{'Add a new state transition for'} = 'Agregar un nuevo estado de transición para';
    $Self->{Translation}->{'Please select a state!'} = '¡Por favor seleccione un estado!';
    $Self->{Translation}->{'Please select a next state!'} = '¡Por favor seleccione un próximo estado!';
    $Self->{Translation}->{'Edit a state transition for'} = 'Editar un estado de transición para';
    $Self->{Translation}->{'Do you really want to delete the state transition'} = 'Realmente desea eliminar el estado de transición';

    # Template: AgentITSMChangeAdd
    $Self->{Translation}->{'Add Change'} = 'Adicionar cambio';
    $Self->{Translation}->{'ITSM Change'} = 'Cambiar ITMS';
    $Self->{Translation}->{'Justification'} = 'Justificación';
    $Self->{Translation}->{'Input invalid.'} = 'Dato invalido.';
    $Self->{Translation}->{'Impact'} = 'Impacto';
    $Self->{Translation}->{'Requested Date'} = 'Fecha requerida';

    # Template: AgentITSMChangeAddFromTemplate
    $Self->{Translation}->{'Select Change Template'} = 'Seleccione cambiar plantilla';
    $Self->{Translation}->{'Time type'} = 'Tipo hora';
    $Self->{Translation}->{'Invalid time type.'} = 'Tipo de hora invalido.';
    $Self->{Translation}->{'New time'} = 'Nueva hora';

    # Template: AgentITSMChangeCABTemplate
    $Self->{Translation}->{'Save Change CAB as template'} = 'Guardar el cambio CAB como plantilla';
    $Self->{Translation}->{'go to involved persons screen'} = 'ir a la pantalla de personas involucradas';
    $Self->{Translation}->{'Invalid Name'} = 'Nombre invalido';

    # Template: AgentITSMChangeCondition
    $Self->{Translation}->{'Conditions and Actions'} = 'Condiciones y acciones';
    $Self->{Translation}->{'Delete Condition'} = 'Eliminar condición';
    $Self->{Translation}->{'Add new condition'} = 'Agregar nueva condición';

    # Template: AgentITSMChangeConditionEdit
    $Self->{Translation}->{'Edit Condition'} = 'Editar condición';
    $Self->{Translation}->{'Need a valid name.'} = 'Necesita un nombre valido.';
    $Self->{Translation}->{'A valid name is needed.'} = 'Se requiere un nombre valido.';
    $Self->{Translation}->{'Duplicate name:'} = 'Nombre duplicado:';
    $Self->{Translation}->{'This name is already used by another condition.'} = 'Este nombre ya esta siendo usado por otra condición.';
    $Self->{Translation}->{'Matching'} = 'coincidiendo';
    $Self->{Translation}->{'Any expression (OR)'} = 'Cualquier expresión (O)';
    $Self->{Translation}->{'All expressions (AND)'} = 'Todas la expresiones (Y)';
    $Self->{Translation}->{'All expressions depending (AND)'} = '';
    $Self->{Translation}->{'BypassStateMachine'} = '';
    $Self->{Translation}->{'BypassStateMachineWO'} = '';
    $Self->{Translation}->{'Expressions'} = 'Expresiones';
    $Self->{Translation}->{'Selector'} = 'Selector';
    $Self->{Translation}->{'Operator'} = 'Operador';
    $Self->{Translation}->{'Delete Expression'} = 'Eliminar expresión';
    $Self->{Translation}->{'No Expressions found.'} = 'No se encontraron expresiones.';
    $Self->{Translation}->{'Add new expression'} = 'Agregar nueva expresión';
    $Self->{Translation}->{'Delete Action'} = 'Eliminar acción';
    $Self->{Translation}->{'No Actions found.'} = 'No se encontraron acciones.';
    $Self->{Translation}->{'Add new action'} = 'Agregar nueva acción';

    # Template: AgentITSMChangeDelete
    $Self->{Translation}->{'Do you really want to delete this change?'} = '¿Realmente desea eliminar este cambio?';

    # Template: AgentITSMChangeEdit
    $Self->{Translation}->{'Edit %s%s'} = 'Editar %s %s';

    # Template: AgentITSMChangeHistory
    $Self->{Translation}->{'History of %s%s'} = 'Histórico de %s%s';
    $Self->{Translation}->{'History Content'} = 'Contenido de la historia';
    $Self->{Translation}->{'Workorder'} = 'Orden de trabajo';
    $Self->{Translation}->{'Createtime'} = 'Crear tiempo';
    $Self->{Translation}->{'Show details'} = 'Mostrar detalles';
    $Self->{Translation}->{'Show workorder'} = 'Mostrar orden de trabajo';

    # Template: AgentITSMChangeHistoryZoom
    $Self->{Translation}->{'Detailed history information of %s'} = 'Historial detallado de %s';
    $Self->{Translation}->{'Modified'} = 'Modificado';
    $Self->{Translation}->{'Old Value'} = 'Antiguo valor';
    $Self->{Translation}->{'New Value'} = 'Nuevo valor';

    # Template: AgentITSMChangeInvolvedPersons
    $Self->{Translation}->{'Edit Involved Persons of %s%s'} = 'Editar personal involucrado de %s%s';
    $Self->{Translation}->{'Involved Persons'} = 'Personas involucradas';
    $Self->{Translation}->{'ChangeManager'} = 'Cambiar supervisor';
    $Self->{Translation}->{'User invalid.'} = 'Usuario invalido.';
    $Self->{Translation}->{'ChangeBuilder'} = 'Cambio de constructor';
    $Self->{Translation}->{'Change Advisory Board'} = '';
    $Self->{Translation}->{'CAB Template'} = 'Plantilla CAB';
    $Self->{Translation}->{'Apply Template'} = 'Aplicar plantilla';
    $Self->{Translation}->{'NewTemplate'} = 'Nueva plantilla';
    $Self->{Translation}->{'Save this CAB as template'} = 'Guardar esta CAB como plantilla';
    $Self->{Translation}->{'Add to CAB'} = 'Agregar a CAB';
    $Self->{Translation}->{'Invalid User'} = 'Usuario Invalido';
    $Self->{Translation}->{'Current CAB'} = 'CAB Actual';

    # Template: AgentITSMChangeOverviewNavBar
    $Self->{Translation}->{'Context Settings'} = 'Ajustes de contexto';
    $Self->{Translation}->{'Changes per page'} = 'Cambios por página';

    # Template: AgentITSMChangeOverviewSmall
    $Self->{Translation}->{'Workorder Title'} = 'Titulo de la orden de trabajo';
    $Self->{Translation}->{'Change Title'} = 'Cambiar titulo';
    $Self->{Translation}->{'Workorder Agent'} = 'Agente de órdenes de trabajo';
    $Self->{Translation}->{'Change Builder'} = 'Cambiar constructor';
    $Self->{Translation}->{'Change Manager'} = 'Administrador de cambios';
    $Self->{Translation}->{'Workorders'} = 'Ordenes de trabajo';
    $Self->{Translation}->{'Change State'} = 'Cambiar estado';
    $Self->{Translation}->{'Workorder State'} = 'Estado de la orden de trabajo';
    $Self->{Translation}->{'Workorder Type'} = 'Tipo de orden de trabajo';
    $Self->{Translation}->{'Requested Time'} = 'Tiempo estimado';
    $Self->{Translation}->{'Planned Start Time'} = 'Hora de inicio prevista';
    $Self->{Translation}->{'Planned End Time'} = 'Hora de finalización prevista';
    $Self->{Translation}->{'Actual Start Time'} = 'Hora de inicio real';
    $Self->{Translation}->{'Actual End Time'} = 'Hora de finalización real';

    # Template: AgentITSMChangeReset
    $Self->{Translation}->{'Do you really want to reset this change?'} = '¿Realmente quieres restablecer este cambio?';

    # Template: AgentITSMChangeSearch
    $Self->{Translation}->{'(e.g. 10*5155 or 105658*)'} = '(por ejemplo. 10*5155 o 105658*)';
    $Self->{Translation}->{'CAB Agent'} = 'Agente CAB';
    $Self->{Translation}->{'e.g.'} = 'por ejemplo.';
    $Self->{Translation}->{'CAB Customer'} = 'Cliente CAB';
    $Self->{Translation}->{'ITSM Workorder Instruction'} = 'Instrucción de órdenes de trabajo ITSM';
    $Self->{Translation}->{'ITSM Workorder Report'} = 'Reporte de órdenes de trabajo ITSM';
    $Self->{Translation}->{'ITSM Change Priority'} = 'Cambiar prioridad ITSM';
    $Self->{Translation}->{'ITSM Change Impact'} = 'Cambiar impacto de ITSM';
    $Self->{Translation}->{'Change Category'} = 'Cambiar categoría';
    $Self->{Translation}->{'(before/after)'} = '(antes/después)';
    $Self->{Translation}->{'(between)'} = '(entre)';

    # Template: AgentITSMChangeTemplate
    $Self->{Translation}->{'Save Change as Template'} = 'Guardar cambios como plantilla';
    $Self->{Translation}->{'A template should have a name!'} = '¡Una plantilla debe tener un nombre!';
    $Self->{Translation}->{'The template name is required.'} = 'El nombre de la plantilla es obligatorio.';
    $Self->{Translation}->{'Reset States'} = 'Reiniciar estados';
    $Self->{Translation}->{'Overwrite original template'} = 'Sobrescribir la plantilla original';
    $Self->{Translation}->{'Delete original change'} = 'Borrar el cambio original';

    # Template: AgentITSMChangeTimeSlot
    $Self->{Translation}->{'Move Time Slot'} = 'Mover intervalo de tiempo';

    # Template: AgentITSMChangeZoom
    $Self->{Translation}->{'Change Information'} = 'Cambiar información';
    $Self->{Translation}->{'Planned Effort'} = 'Esfuerzo planificado';
    $Self->{Translation}->{'Accounted Time'} = 'Tiempo contabilizado';
    $Self->{Translation}->{'Change Initiator(s)'} = 'Iniciador(es) del cambio';
    $Self->{Translation}->{'CAB'} = 'CAB';
    $Self->{Translation}->{'Last changed'} = 'Último cambio';
    $Self->{Translation}->{'Last changed by'} = 'Modificado por última vez por';
    $Self->{Translation}->{'To open links in the following description blocks, you might need to press Ctrl or Cmd or Shift key while clicking the link (depending on your browser and OS).'} =
        'Para abrir los enlaces en los siguientes bloques de descripción, es posible que tenga que pulsar la tecla Ctrl o Cmd o Shift mientras hace clic en el enlace (dependiendo de su navegador y sistema operativo).';
    $Self->{Translation}->{'Download Attachment'} = 'Descarga de archivos adjuntos';

    # Template: AgentITSMTemplateEditCAB
    $Self->{Translation}->{'Edit CAB Template'} = 'Editar plantilla CAB';

    # Template: AgentITSMTemplateEditContent
    $Self->{Translation}->{'This will create a new change from this template, so you can edit and save it.'} =
        'Esto creará un nuevo cambio en esta plantilla, para que pueda editarla y guardarla.';
    $Self->{Translation}->{'The new change will be deleted automatically after it has been saved as template.'} =
        'El nuevo cambio se borrará automáticamente después de que se haya guardado como plantilla.';
    $Self->{Translation}->{'This will create a new workorder from this template, so you can edit and save it.'} =
        'Esto creará una nueva orden de trabajo a partir de esta plantilla, para que pueda editarla y guardarla.';
    $Self->{Translation}->{'A temporary change will be created which contains the workorder.'} =
        'Se creará un cambio temporal que contiene la orden de trabajo.';
    $Self->{Translation}->{'The temporary change and new workorder will be deleted automatically after the workorder has been saved as template.'} =
        'El cambio temporal y la nueva orden de trabajo se eliminarán automáticamente después de que la orden de trabajo se haya guardado como plantilla.';
    $Self->{Translation}->{'Do you want to proceed?'} = '¿Quieres continuar?';

    # Template: AgentITSMTemplateOverviewSmall
    $Self->{Translation}->{'Template ID'} = 'ID Plantilla';
    $Self->{Translation}->{'Edit Content'} = 'Editar contenido';
    $Self->{Translation}->{'Create by'} = 'Creado por';
    $Self->{Translation}->{'Change by'} = 'Cambiado por';
    $Self->{Translation}->{'Change Time'} = 'Hora de cambio';

    # Template: AgentITSMWorkOrderAdd
    $Self->{Translation}->{'Add Workorder to %s%s'} = 'Agregar orden de trabajo a %s%s';
    $Self->{Translation}->{'Instruction'} = 'Instrucción';
    $Self->{Translation}->{'Invalid workorder type.'} = 'Tipo de orden de trabajo invalida.';
    $Self->{Translation}->{'The planned start time must be before the planned end time!'} = '¡La hora de inicio prevista debe ser anterior a la hora de finalización prevista!';
    $Self->{Translation}->{'Invalid format.'} = 'Formato invalido.';

    # Template: AgentITSMWorkOrderAddFromTemplate
    $Self->{Translation}->{'Select Workorder Template'} = 'Seleccione una plantilla de orden de trabajo';

    # Template: AgentITSMWorkOrderAgent
    $Self->{Translation}->{'Edit Workorder Agent of %s%s'} = 'Editar agente de orden de trabajo de %s%s';

    # Template: AgentITSMWorkOrderDelete
    $Self->{Translation}->{'Do you really want to delete this workorder?'} = '¿Realmente quiere eliminar esta orden de trabajo?';
    $Self->{Translation}->{'You can not delete this Workorder. It is used in at least one Condition!'} =
        '¡No se puede eliminar esta Orden de Trabajo. Se utiliza en al menos una condición!';
    $Self->{Translation}->{'This Workorder is used in the following Condition(s)'} = 'Esta orden de trabajo se utiliza en las siguientes condiciones';

    # Template: AgentITSMWorkOrderEdit
    $Self->{Translation}->{'Edit %s%s-%s'} = 'Editar %s%s-%s';
    $Self->{Translation}->{'Move following workorders accordingly'} = 'Desplazar las siguientes órdenes de trabajo como corresponde';
    $Self->{Translation}->{'If the planned end time of this workorder is changed, the planned start times of all following workorders will be changed accordingly'} =
        'Si se modifica la hora de finalización prevista de esta orden de trabajo, las horas de inicio previstas de todas las órdenes de trabajo siguientes se modificarán en consecuencia';

    # Template: AgentITSMWorkOrderHistory
    $Self->{Translation}->{'History of %s%s-%s'} = 'Historia de %s%s-%s';

    # Template: AgentITSMWorkOrderReport
    $Self->{Translation}->{'Edit Report of %s%s-%s'} = 'Editar reporte de %s%s-%s';
    $Self->{Translation}->{'Report'} = 'Reporte';
    $Self->{Translation}->{'The actual start time must be before the actual end time!'} = '¡La hora de inicio real debe ser anterior a la hora de finalización real!';
    $Self->{Translation}->{'The actual start time must be set, when the actual end time is set!'} =
        '¡La hora de inicio real debe fijarse cuando se fije la hora de finalización real!';

    # Template: AgentITSMWorkOrderTake
    $Self->{Translation}->{'Current Agent'} = 'Agente actual';
    $Self->{Translation}->{'Do you really want to take this workorder?'} = '¿Realmente quieres aceptar esta orden de trabajo?';

    # Template: AgentITSMWorkOrderTemplate
    $Self->{Translation}->{'Save Workorder as Template'} = 'Guardar orden de trabajo como plantilla';
    $Self->{Translation}->{'Delete original workorder (and surrounding change)'} = 'Eliminar la orden de trabajo original (y el cambio circundante)';

    # Template: AgentITSMWorkOrderZoom
    $Self->{Translation}->{'Workorder Information'} = 'Información de la orden de trabajo';

    # Perl Module: Kernel/Modules/AdminITSMChangeNotification.pm
    $Self->{Translation}->{'Notification Added!'} = '¡Notificación añadida!';
    $Self->{Translation}->{'Unknown notification %s!'} = '¡Notificación desconocida %s!';
    $Self->{Translation}->{'There was an error creating the notification.'} = 'Se ha producido un error al crear la notificación.';

    # Perl Module: Kernel/Modules/AdminITSMStateMachine.pm
    $Self->{Translation}->{'State Transition Updated!'} = '¡Estado de transición actualizado!';
    $Self->{Translation}->{'State Transition Added!'} = '¡Estado de transición añadido!';

    # Perl Module: Kernel/Modules/AgentITSMChange.pm
    $Self->{Translation}->{'Overview: ITSM Changes'} = 'Descripción general: cambios de ITSM';

    # Perl Module: Kernel/Modules/AgentITSMChangeAdd.pm
    $Self->{Translation}->{'Ticket with TicketID %s does not exist!'} = '¡El ticket TicketID %s no existe!';
    $Self->{Translation}->{'Missing sysconfig option "ITSMChange::AddChangeLinkTicketTypes"!'} =
        '¡Falta la opción de sysconfig "ITSMChange :: AddChangeLinkTicketTypes"!';
    $Self->{Translation}->{'Was not able to add change!'} = '¡No he podido añadir el cambio!';

    # Perl Module: Kernel/Modules/AgentITSMChangeAddFromTemplate.pm
    $Self->{Translation}->{'Was not able to create change from template!'} = '¡No se a podido crear un cambio de plantilla!';

    # Perl Module: Kernel/Modules/AgentITSMChangeCABTemplate.pm
    $Self->{Translation}->{'No ChangeID is given!'} = '¡No se proporciona ChangeID!';
    $Self->{Translation}->{'No change found for changeID %s.'} = 'No se ha encontrado ningún cambio para el changeID %s.';
    $Self->{Translation}->{'The CAB of change "%s" could not be serialized.'} = 'El cambio de CAB "%s" no pudo ser serializado.';
    $Self->{Translation}->{'Could not add the template.'} = 'No se ha podido agregar la plantilla.';

    # Perl Module: Kernel/Modules/AgentITSMChangeCondition.pm
    $Self->{Translation}->{'Change "%s" not found in database!'} = '¡Cambio "%s" no encontrado en la base de datos!';
    $Self->{Translation}->{'Could not delete ConditionID %s!'} = '¡No se ha podido eliminar ConditionID %s!';

    # Perl Module: Kernel/Modules/AgentITSMChangeConditionEdit.pm
    $Self->{Translation}->{'No %s is given!'} = '¡No se da ningún %s!';
    $Self->{Translation}->{'Could not create new condition!'} = '¡No se ha podido crear una nueva condición!';
    $Self->{Translation}->{'Could not update ConditionID %s!'} = '¡No se ha podido actualizar ConditionID %s!';
    $Self->{Translation}->{'Could not update ExpressionID %s!'} = '¡No se ha podido actualizar la ExpressionID %s!';
    $Self->{Translation}->{'Could not add new Expression!'} = '¡No se puede agregar una nueva Expresión!';
    $Self->{Translation}->{'Could not update ActionID %s!'} = '¡No se ha podido actualizar la ActionID %s!';
    $Self->{Translation}->{'Could not add new Action!'} = '¡No se puede agregar una nueva Acción!';
    $Self->{Translation}->{'Could not delete ExpressionID %s!'} = '¡No se ha podido eliminar ExpressionID %s!';
    $Self->{Translation}->{'Could not delete ActionID %s!'} = '¡No se ha podido eliminar ActionID %s!';
    $Self->{Translation}->{'Error: Unknown field type "%s"!'} = 'Error: ¡Tipo de campo desconocido "%s"!';
    $Self->{Translation}->{'ConditionID %s does not belong to the given ChangeID %s!'} = '¡ConditionID %s no pertenece al ChangeID %s dado!';

    # Perl Module: Kernel/Modules/AgentITSMChangeDelete.pm
    $Self->{Translation}->{'Change "%s" does not have an allowed change state to be deleted!'} =
        '¡El cambio "%s" no tiene un estado de cambio permitido para ser eliminado!';
    $Self->{Translation}->{'Was not able to delete the changeID %s!'} = '¡No se ha podido borrar el changeID %s!';

    # Perl Module: Kernel/Modules/AgentITSMChangeEdit.pm
    $Self->{Translation}->{'Was not able to update Change!'} = '¡No se ha podido actualizar el cambio!';

    # Perl Module: Kernel/Modules/AgentITSMChangeHistory.pm
    $Self->{Translation}->{'Can\'t show history, as no ChangeID is given!'} = '¡No se puede mostrar el historial, ya que no se proporciona ningún ChangeID!';
    $Self->{Translation}->{'Change "%s" not found in the database!'} = '¡Cambio "%s" no encontrado en la base de datos!';
    $Self->{Translation}->{'Unknown type "%s" encountered!'} = '¡Se ha encontrado un tipo desconocido "%s"!';

    # Perl Module: Kernel/Modules/AgentITSMChangeHistoryZoom.pm
    $Self->{Translation}->{'Can\'t show history zoom, no HistoryEntryID is given!'} = '¡No se puede mostrar el zoom del historial, no se ha proporcionado un HistoryEntryID!';
    $Self->{Translation}->{'HistoryEntry "%s" not found in database!'} = '¡HistoryEntry "%s" no se encuentra en la base de datos!';

    # Perl Module: Kernel/Modules/AgentITSMChangeInvolvedPersons.pm
    $Self->{Translation}->{'Was not able to update Change CAB for Change %s!'} = '¡No se ha podido actualizar el CAB para cambiar %s!';
    $Self->{Translation}->{'Was not able to update Change %s!'} = '¡No se ha podido actualizar el cambio %s!';

    # Perl Module: Kernel/Modules/AgentITSMChangeManager.pm
    $Self->{Translation}->{'Overview: ChangeManager'} = 'Descripción general: ChangeManager';

    # Perl Module: Kernel/Modules/AgentITSMChangeMyCAB.pm
    $Self->{Translation}->{'Overview: My CAB'} = 'Descripción general: Mi CAB';

    # Perl Module: Kernel/Modules/AgentITSMChangeMyChanges.pm
    $Self->{Translation}->{'Overview: My Changes'} = 'Resumen: Mis cambios';

    # Perl Module: Kernel/Modules/AgentITSMChangeMyWorkOrders.pm
    $Self->{Translation}->{'Overview: My Workorders'} = 'Descripción general: Mis ordenes de trabajo';

    # Perl Module: Kernel/Modules/AgentITSMChangePIR.pm
    $Self->{Translation}->{'Overview: PIR'} = 'Resumen: PIR';

    # Perl Module: Kernel/Modules/AgentITSMChangePSA.pm
    $Self->{Translation}->{'Overview: PSA'} = 'Resumen: PSA';

    # Perl Module: Kernel/Modules/AgentITSMChangePrint.pm
    $Self->{Translation}->{'WorkOrder "%s" not found in database!'} = '¡La orden de trabajo "%s" no se encuentra en la base de datos!';
    $Self->{Translation}->{'Can\'t create output, as the workorder is not attached to a change!'} =
        '¡No se puede crear una salida, ya que la orden de trabajo no está asociada a un cambio!';
    $Self->{Translation}->{'Can\'t create output, as no ChangeID is given!'} = '¡No se puede crear una salida, ya que no se proporciona ChangeID!';
    $Self->{Translation}->{'unknown change title'} = 'título de cambio desconocido';
    $Self->{Translation}->{'ITSM Workorder'} = 'Orden de trabajo ITSM';
    $Self->{Translation}->{'WorkOrderNumber'} = 'Número de Orden de Trabajo';
    $Self->{Translation}->{'WorkOrderTitle'} = 'Título de la orden de trabajo';
    $Self->{Translation}->{'unknown workorder title'} = 'título de la orden de trabajo desconocido';
    $Self->{Translation}->{'ChangeState'} = 'Cambiar de estado';
    $Self->{Translation}->{'PlannedEffort'} = 'Esfuerzo planificado';
    $Self->{Translation}->{'CAB Agents'} = 'Agentes CAB';
    $Self->{Translation}->{'CAB Customers'} = 'Clientes CAB';
    $Self->{Translation}->{'RequestedTime'} = 'Hora solicitada';
    $Self->{Translation}->{'PlannedStartTime'} = 'Hora de inicio prevista';
    $Self->{Translation}->{'PlannedEndTime'} = 'Hora de finalización prevista';
    $Self->{Translation}->{'ActualStartTime'} = 'Hora de inicio real';
    $Self->{Translation}->{'ActualEndTime'} = 'Hora de finalización real';
    $Self->{Translation}->{'ChangeTime'} = 'Cambiar el tiempo';
    $Self->{Translation}->{'ChangeNumber'} = 'Número de modificación';
    $Self->{Translation}->{'WorkOrderState'} = 'Estado de la orden de trabajo';
    $Self->{Translation}->{'WorkOrderType'} = 'Tipo de orden de trabajo';
    $Self->{Translation}->{'WorkOrderAgent'} = 'Agente de órdenes de trabajo';
    $Self->{Translation}->{'ITSM Workorder Overview (%s)'} = 'Descripción general de la orden de trabajo de ITSM (%s)';

    # Perl Module: Kernel/Modules/AgentITSMChangeReset.pm
    $Self->{Translation}->{'Was not able to reset WorkOrder %s of Change %s!'} = '¡No se pudo restablecer la orden de trabajo %s de cambio %s!';
    $Self->{Translation}->{'Was not able to reset Change %s!'} = '¡No se pudo restablecer el cambio %s!';

    # Perl Module: Kernel/Modules/AgentITSMChangeSchedule.pm
    $Self->{Translation}->{'Overview: Change Schedule'} = 'Descripción general: cambio de horario';

    # Perl Module: Kernel/Modules/AgentITSMChangeSearch.pm
    $Self->{Translation}->{'Change Search'} = 'Cambiar búsqueda';
    $Self->{Translation}->{'ChangeTitle'} = 'Cambiar Título';
    $Self->{Translation}->{'WorkOrders'} = 'Órdenes de trabajo';
    $Self->{Translation}->{'Change Search Result'} = 'Cambiar el resultado de la búsqueda';
    $Self->{Translation}->{'Change Number'} = 'Cambie el número';
    $Self->{Translation}->{'Work Order Title'} = 'Título de la orden de trabajo';
    $Self->{Translation}->{'Change Description'} = 'Cambiar Descripción';
    $Self->{Translation}->{'Change Justification'} = 'Justificación del cambio';
    $Self->{Translation}->{'WorkOrder Instruction'} = 'Instrucción de orden de trabajo';
    $Self->{Translation}->{'WorkOrder Report'} = 'Informe de orden de trabajo';
    $Self->{Translation}->{'Change Priority'} = 'Cambiar prioridad';
    $Self->{Translation}->{'Change Impact'} = 'Cambiar impacto';
    $Self->{Translation}->{'Created By'} = 'Creado por';
    $Self->{Translation}->{'WorkOrder State'} = 'Estado de la orden de trabajo';
    $Self->{Translation}->{'WorkOrder Type'} = 'Tipo de orden de trabajo';
    $Self->{Translation}->{'WorkOrder Agent'} = 'Agente de órdenes de trabajo';
    $Self->{Translation}->{'before'} = 'antes';

    # Perl Module: Kernel/Modules/AgentITSMChangeTemplate.pm
    $Self->{Translation}->{'The change "%s" could not be serialized.'} = 'No se pudo serializar el cambio "%s".';
    $Self->{Translation}->{'Could not update the template "%s".'} = 'No se pudo actualizar la plantilla "%s".';
    $Self->{Translation}->{'Could not delete change "%s".'} = 'No se pudo borrar el cambio "%s".';

    # Perl Module: Kernel/Modules/AgentITSMChangeTimeSlot.pm
    $Self->{Translation}->{'The change can\'t be moved, as it has no workorders.'} = 'El cambio no se puede mover, ya que no tiene órdenes de trabajo.';
    $Self->{Translation}->{'Add a workorder first.'} = 'Primero agregue una orden de trabajo.';
    $Self->{Translation}->{'Can\'t move a change which already has started!'} = '¡No se puede mover un cambio que ya ha comenzado!';
    $Self->{Translation}->{'Please move the individual workorders instead.'} = 'En su lugar, mueva las órdenes de trabajo individuales.';
    $Self->{Translation}->{'The current %s could not be determined.'} = 'No se pudo determinar el %s actual.';
    $Self->{Translation}->{'The %s of all workorders has to be defined.'} = 'Se deben definir los %s de todas las órdenes de trabajo.';
    $Self->{Translation}->{'Was not able to move time slot for workorder #%s!'} = '¡No se pudo mover el intervalo de tiempo para la orden de trabajo #%s!';

    # Perl Module: Kernel/Modules/AgentITSMTemplateDelete.pm
    $Self->{Translation}->{'You need %s permission!'} = '¡Necesitas el permiso de %s!';
    $Self->{Translation}->{'No TemplateID is given!'} = '¡No se proporciona ningún TemplateID!';
    $Self->{Translation}->{'Template "%s" not found in database!'} = '¡La plantilla "%s" no se encuentra en la base de datos!';
    $Self->{Translation}->{'Was not able to delete the template %s!'} = '¡No se pudo borrar la plantilla %s!';

    # Perl Module: Kernel/Modules/AgentITSMTemplateEdit.pm
    $Self->{Translation}->{'Was not able to update Template %s!'} = '¡No se pudo actualizar la plantilla %s!';

    # Perl Module: Kernel/Modules/AgentITSMTemplateEditCAB.pm
    $Self->{Translation}->{'Was not able to update Template "%s"!'} = '¡No se pudo actualizar la plantilla "%s"!';

    # Perl Module: Kernel/Modules/AgentITSMTemplateEditContent.pm
    $Self->{Translation}->{'Was not able to create change!'} = '¡No fue posible crear un cambio!';
    $Self->{Translation}->{'Was not able to create workorder from template!'} = '¡No se pudo crear una orden de trabajo a partir de la plantilla!';

    # Perl Module: Kernel/Modules/AgentITSMTemplateOverview.pm
    $Self->{Translation}->{'Overview: Template'} = 'Descripción general: plantilla';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderAdd.pm
    $Self->{Translation}->{'You need %s permissions on the change!'} = '¡Necesita %s permisos para el cambio!';
    $Self->{Translation}->{'Was not able to add workorder!'} = '¡No se pudo agregar la orden de trabajo!';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderAgent.pm
    $Self->{Translation}->{'No WorkOrderID is given!'} = '¡No se proporciona WorkOrderID!';
    $Self->{Translation}->{'Was not able to set the workorder agent of the workorder "%s" to empty!'} =
        '¡No se pudo configurar el agente de la orden de trabajo de la orden de trabajo "%s" esta vacia!';
    $Self->{Translation}->{'Was not able to update the workorder "%s"!'} = '¡No se pudo actualizar la orden de trabajo "%s"!';
    $Self->{Translation}->{'Could not find Change for WorkOrder %s!'} = '¡No se pudo encontrar el cambio para la orden de trabajo %s!';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderDelete.pm
    $Self->{Translation}->{'Was not able to delete the workorder %s!'} = '¡No se pudo borrar la orden de trabajo %s!';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderEdit.pm
    $Self->{Translation}->{'Was not able to update WorkOrder %s!'} = '¡No se pudo actualizar la orden de trabajo %s!';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderHistory.pm
    $Self->{Translation}->{'Can\'t show history, as no WorkOrderID is given!'} = '¡No se puede mostrar el historial, ya que no se proporciona WorkOrderID!';
    $Self->{Translation}->{'WorkOrder "%s" not found in the database!'} = '¡La orden de trabajo "%s" no se encuentra en la base de datos!';
    $Self->{Translation}->{'WorkOrder History'} = 'Historial de órdenes de trabajo';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderHistoryZoom.pm
    $Self->{Translation}->{'History entry "%s" not found in the database!'} = '¡La entrada del historial "%s" no se encuentra en la base de datos!';
    $Self->{Translation}->{'WorkOrder History Zoom'} = 'Detalle del historial de órdenes de trabajo';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderTake.pm
    $Self->{Translation}->{'Was not able to take the workorder %s!'} = '¡No pudo tomar la orden de trabajo %s!';

    # Perl Module: Kernel/Modules/AgentITSMWorkOrderTemplate.pm
    $Self->{Translation}->{'The workorder "%s" could not be serialized.'} = 'No se pudo serializar la orden de trabajo "%s".';

    # Perl Module: Kernel/Output/HTML/Layout/ITSMChange.pm
    $Self->{Translation}->{'Need config option %s!'} = '¡Necesita la opción de configuración %s!';
    $Self->{Translation}->{'Config option %s needs to be a HASH ref!'} = '¡La opción de configuración %s debe ser una referencia HASH!';
    $Self->{Translation}->{'No config option found for the view "%s"!'} = '¡No se ha encontrado ninguna opción de configuración para la vista "%s"!';
    $Self->{Translation}->{'Title: %s | Type: %s'} = 'Título: %s | Tipo: %s';

    # Perl Module: Kernel/Output/HTML/ToolBar/MyCAB.pm
    $Self->{Translation}->{'My CABs'} = 'Mis CAB';

    # Perl Module: Kernel/Output/HTML/ToolBar/MyChanges.pm
    $Self->{Translation}->{'My Changes'} = 'Mis Cambios';

    # Perl Module: Kernel/Output/HTML/ToolBar/MyWorkOrders.pm
    $Self->{Translation}->{'My Work Orders'} = 'Mis órdenes de Trabajo';

    # Perl Module: Kernel/System/ITSMChange/History.pm
    $Self->{Translation}->{'%s: %s'} = '%s: %s';
    $Self->{Translation}->{'New Action (ID=%s)'} = 'Nueva acción (ID =%s)';
    $Self->{Translation}->{'Action (ID=%s) deleted'} = 'Acción (ID =%s) eliminada';
    $Self->{Translation}->{'All Actions of Condition (ID=%s) deleted'} = 'Todas las acciones de la condición (ID =%s) eliminadas';
    $Self->{Translation}->{'Action (ID=%s) executed: %s'} = 'Acción (ID =%s) ejecutada: %s';
    $Self->{Translation}->{'%s (Action ID=%s): (new=%s, old=%s)'} = '%s (ID de acción =%s): (nuevo =%s, antiguo =%s)';
    $Self->{Translation}->{'Change (ID=%s) reached actual end time.'} = 'El cambio (ID =%s) alcanzó la hora de finalización real.';
    $Self->{Translation}->{'Change (ID=%s) reached actual start time.'} = 'El cambio (ID =%s) alcanzó la hora de inicio real.';
    $Self->{Translation}->{'New Change (ID=%s)'} = 'Nuevo cambio (ID =%s)';
    $Self->{Translation}->{'New Attachment: %s'} = 'Nuevo adjunto: %s';
    $Self->{Translation}->{'Deleted Attachment %s'} = 'Adjunto eliminado %s';
    $Self->{Translation}->{'CAB Deleted %s'} = 'CAB eliminado %s';
    $Self->{Translation}->{'%s: (new=%s, old=%s)'} = '%s: (nuevo = %s, antiguo = %s)';
    $Self->{Translation}->{'Link to %s (ID=%s) added'} = 'Vínculo a %s (ID = %s) agregado';
    $Self->{Translation}->{'Link to %s (ID=%s) deleted'} = 'Enlace a %s (ID = %s) eliminado';
    $Self->{Translation}->{'Notification sent to %s (Event: %s)'} = 'Notificación enviada a %s (evento: %s)';
    $Self->{Translation}->{'Change (ID=%s) reached planned end time.'} = 'El cambio (ID=%s) alcanzó la hora de finalización planificada.';
    $Self->{Translation}->{'Change (ID=%s) reached planned start time.'} = 'El cambio (ID=%s) alcanzó la hora de inicio planificada.';
    $Self->{Translation}->{'Change (ID=%s) reached requested time.'} = 'El cambio (ID=%s) alcanzó la hora solicitada.';
    $Self->{Translation}->{'New Condition (ID=%s)'} = 'Condición nueva (ID=%s)';
    $Self->{Translation}->{'Condition (ID=%s) deleted'} = 'Condición (ID=%s) eliminada';
    $Self->{Translation}->{'All Conditions of Change (ID=%s) deleted'} = 'Todas las condiciones de cambio (ID=%s) eliminadas';
    $Self->{Translation}->{'%s (Condition ID=%s): (new=%s, old=%s)'} = '%s (ID de condición =%s): (nuevo =%s, antiguo =%s)';
    $Self->{Translation}->{'New Expression (ID=%s)'} = 'Nueva expresión (ID=%s)';
    $Self->{Translation}->{'Expression (ID=%s) deleted'} = 'Expresión (ID=%s) eliminada';
    $Self->{Translation}->{'All Expressions of Condition (ID=%s) deleted'} = 'Todas las expresiones de condición (ID=%s) eliminadas';
    $Self->{Translation}->{'%s (Expression ID=%s): (new=%s, old=%s)'} = '%s (ID de expresión=%s): (nuevo =%s, antiguo=%s)';
    $Self->{Translation}->{'Workorder (ID=%s) reached actual end time.'} = 'La orden de trabajo (ID=%s) alcanzó la hora de finalización real.';
    $Self->{Translation}->{'Workorder (ID=%s) reached actual start time.'} = 'La orden de trabajo (ID =%s) alcanzó la hora de inicio real.';
    $Self->{Translation}->{'New Workorder (ID=%s)'} = 'Nueva orden de trabajo (ID =%s)';
    $Self->{Translation}->{'New Attachment for WorkOrder: %s'} = 'Nuevo archivo adjunto para la orden de trabajo: %s';
    $Self->{Translation}->{'(ID=%s) New Attachment for WorkOrder: %s'} = '(ID =%s) Nuevo archivo adjunto para la orden de trabajo: %s';
    $Self->{Translation}->{'Deleted Attachment from WorkOrder: %s'} = 'Adjunto eliminado de la orden de trabajo: %s';
    $Self->{Translation}->{'(ID=%s) Deleted Attachment from WorkOrder: %s'} = '(ID=%s) Adjunto borrado de la orden de trabajo: %s';
    $Self->{Translation}->{'New Report Attachment for WorkOrder: %s'} = 'Nuevo reporte adjunto para la orden de trabajo: %s';
    $Self->{Translation}->{'(ID=%s) New Report Attachment for WorkOrder: %s'} = '(ID=%s) Nuevo reporte adjunto para la orden de trabajo: %s';
    $Self->{Translation}->{'Deleted Report Attachment from WorkOrder: %s'} = 'Se ha eliminado el informe adjunto de la orden de trabajo: %s';
    $Self->{Translation}->{'(ID=%s) Deleted Report Attachment from WorkOrder: %s'} = '(ID=%s) Reporte adjunto borrado de la orden de trabajo: %s';
    $Self->{Translation}->{'Workorder (ID=%s) deleted'} = 'Orden de trabajo (ID=%s) borrada';
    $Self->{Translation}->{'(ID=%s) Link to %s (ID=%s) added'} = '(ID=%s) Enlace a %s (ID=%s) añadido';
    $Self->{Translation}->{'(ID=%s) Link to %s (ID=%s) deleted'} = 'ID=%s) Enlace a %s (ID=%s) borrado';
    $Self->{Translation}->{'(ID=%s) Notification sent to %s (Event: %s)'} = '(ID=%s) Notificación enviada a %s (Evento: %s)';
    $Self->{Translation}->{'Workorder (ID=%s) reached planned end time.'} = 'La orden de trabajo (ID=%s) ha alcanzado la hora de finalización prevista.';
    $Self->{Translation}->{'Workorder (ID=%s) reached planned start time.'} = 'La orden de trabajo (ID=%s) ha alcanzado la hora de inicio prevista.';
    $Self->{Translation}->{'(ID=%s) %s: (new=%s, old=%s)'} = '(ID=%s) %s: (nuevo=%s, antiguo=%s)';

    # Perl Module: Kernel/System/ITSMChange/ITSMCondition/Object/ITSMWorkOrder.pm
    $Self->{Translation}->{'all'} = 'todo';
    $Self->{Translation}->{'any'} = 'cualquier';

    # Perl Module: Kernel/System/ITSMChange/Notification.pm
    $Self->{Translation}->{'Previous Change Builder'} = '';
    $Self->{Translation}->{'Previous Change Manager'} = '';
    $Self->{Translation}->{'Workorder Agents'} = 'Agentes de órdenes de trabajo';
    $Self->{Translation}->{'Previous Workorder Agent'} = 'Agente de órdenes de trabajo anteriores';
    $Self->{Translation}->{'Change Initiators'} = 'Iniciadores de cambio';
    $Self->{Translation}->{'Group ITSMChange'} = 'Grupo ITSMChange';
    $Self->{Translation}->{'Group ITSMChangeBuilder'} = 'Grupo ITSMChangeBuilder';
    $Self->{Translation}->{'Group ITSMChangeManager'} = 'Grupo ITSMChangeManager';

    # Database XML / SOPM Definition: ITSMChangeManagement.sopm
    $Self->{Translation}->{'requested'} = 'Requerido';
    $Self->{Translation}->{'pending approval'} = 'Aprobación pendiente';
    $Self->{Translation}->{'rejected'} = 'Rechazado';
    $Self->{Translation}->{'approved'} = 'Aprobado';
    $Self->{Translation}->{'in progress'} = 'en progreso';
    $Self->{Translation}->{'pending pir'} = 'pir pendiente';
    $Self->{Translation}->{'successful'} = 'exitoso';
    $Self->{Translation}->{'failed'} = 'fallo';
    $Self->{Translation}->{'canceled'} = 'cancelado';
    $Self->{Translation}->{'retracted'} = 'retraído';
    $Self->{Translation}->{'created'} = 'creado';
    $Self->{Translation}->{'accepted'} = 'aceptado';
    $Self->{Translation}->{'ready'} = 'listo';
    $Self->{Translation}->{'approval'} = 'aprobación';
    $Self->{Translation}->{'workorder'} = 'orden de trabajo';
    $Self->{Translation}->{'backout'} = 'retroceder';
    $Self->{Translation}->{'decision'} = 'decisión';
    $Self->{Translation}->{'pir'} = 'pir';
    $Self->{Translation}->{'ChangeStateID'} = 'ChangeStateID';
    $Self->{Translation}->{'CategoryID'} = 'CategoryID';
    $Self->{Translation}->{'ImpactID'} = 'ImpactID';
    $Self->{Translation}->{'PriorityID'} = 'PriorityID';
    $Self->{Translation}->{'ChangeManagerID'} = 'ChangeManagerID';
    $Self->{Translation}->{'ChangeBuilderID'} = 'ChangeBuilderID';
    $Self->{Translation}->{'WorkOrderStateID'} = 'WorkOrderStateID';
    $Self->{Translation}->{'WorkOrderTypeID'} = 'WorkOrderTypeID';
    $Self->{Translation}->{'WorkOrderAgentID'} = 'WorkOrderAgentID';
    $Self->{Translation}->{'is'} = 'es';
    $Self->{Translation}->{'is not'} = 'no es';
    $Self->{Translation}->{'is empty'} = 'está vacío';
    $Self->{Translation}->{'is not empty'} = 'no está vacío';
    $Self->{Translation}->{'is greater than'} = 'es mayor que';
    $Self->{Translation}->{'is less than'} = 'es menos que';
    $Self->{Translation}->{'is before'} = 'antes de';
    $Self->{Translation}->{'is after'} = 'después de';
    $Self->{Translation}->{'contains'} = 'contiene';
    $Self->{Translation}->{'not contains'} = 'no contiene';
    $Self->{Translation}->{'begins with'} = 'empieza con';
    $Self->{Translation}->{'ends with'} = 'termina con';
    $Self->{Translation}->{'set'} = 'establece';

    # JS File: ITSM.Agent.ChangeManagement.Condition
    $Self->{Translation}->{'Do you really want to delete this expression?'} = '¿Realmente desea eliminar esta expresión?';
    $Self->{Translation}->{'Do you really want to delete this action?'} = '¿Realmente quieres eliminar esta acción?';
    $Self->{Translation}->{'Do you really want to delete this condition?'} = '¿Realmente desea eliminar esta condición?';

    # SysConfig
    $Self->{Translation}->{'A list of the agents who have permission to take workorders. Key is a login name. Content is 0 or 1.'} =
        'Una lista de los agentes que tienen permiso para aceptar órdenes de trabajo. La clave es el nombre de inicio de sesión. El contenido es 0 o 1.';
    $Self->{Translation}->{'A list of workorder states, at which the ActualStartTime of a workorder will be set if it was empty at this point.'} =
        'Una lista de estados de la orden de trabajo, en la que se establecerá la hora de inicio real de una orden de trabajo si estaba vacía en este punto.';
    $Self->{Translation}->{'Actual end time'} = 'Hora de finalización real';
    $Self->{Translation}->{'Actual start time'} = 'Hora de inicio real';
    $Self->{Translation}->{'Add Workorder'} = 'Agregar una Orden de Trabajo';
    $Self->{Translation}->{'Add Workorder (from Template)'} = 'Agregar orden de trabajo (desde la plantilla)';
    $Self->{Translation}->{'Add a change from template.'} = 'Agregar un cambio desde la plantilla.';
    $Self->{Translation}->{'Add a change.'} = 'Agrega un cambio.';
    $Self->{Translation}->{'Add a workorder (from template) to the change.'} = 'Agregue una orden de trabajo (desde la plantilla) al cambio.';
    $Self->{Translation}->{'Add a workorder to the change.'} = 'Agregue una orden de trabajo al cambio.';
    $Self->{Translation}->{'Add from template'} = 'Agregar desde plantilla';
    $Self->{Translation}->{'Admin of the CIP matrix.'} = 'Administrador de la matriz CIP.';
    $Self->{Translation}->{'Admin of the state machine.'} = 'Administrador del estado de la máquina.';
    $Self->{Translation}->{'Agent interface notification module to see the number of change advisory boards.'} =
        'Módulo de notificación de la interfaz del agente para ver el número de paneles de cambios de asesoramiento.';
    $Self->{Translation}->{'Agent interface notification module to see the number of changes managed by the user.'} =
        'Módulo de notificación de la interfaz del agente para ver el número de cambios gestionados por el usuario.';
    $Self->{Translation}->{'Agent interface notification module to see the number of changes.'} =
        'Módulo de notificación de la interfaz del agente para ver el número de cambios.';
    $Self->{Translation}->{'Agent interface notification module to see the number of workorders.'} =
        'Módulo de notificación de la interfaz del agente para ver el número de órdenes de trabajo.';
    $Self->{Translation}->{'CAB Member Search'} = 'Búsqueda de miembros del CAB';
    $Self->{Translation}->{'Cache time in minutes for the change management toolbars. Default: 3 hours (180 minutes).'} =
        'Tiempo de caché en minutos para las barras de herramientas de gestión de cambios. Por defecto: 3 horas (180 minutos).';
    $Self->{Translation}->{'Cache time in minutes for the change management. Default: 5 days (7200 minutes).'} =
        'Tiempo de caché en minutos para la gestión de cambios. Por defecto: 5 días (7200 minutos).';
    $Self->{Translation}->{'Change CAB Templates'} = 'Cambiar las plantillas de CAB';
    $Self->{Translation}->{'Change History.'} = 'Historial de cambios.';
    $Self->{Translation}->{'Change Involved Persons.'} = 'Cambiar las personas participantes.';
    $Self->{Translation}->{'Change Overview "Small" Limit'} = 'Cambiar la visión general del límite "pequeño"';
    $Self->{Translation}->{'Change Overview.'} = 'Resumen de los cambios.';
    $Self->{Translation}->{'Change Print.'} = 'Cambiar la impresión.';
    $Self->{Translation}->{'Change Schedule'} = 'Cambio de horario';
    $Self->{Translation}->{'Change Schedule.'} = 'Cambiar el horario.';
    $Self->{Translation}->{'Change Settings'} = 'Cambiar la configuración';
    $Self->{Translation}->{'Change Zoom'} = 'Cambiar el detalle';
    $Self->{Translation}->{'Change Zoom.'} = 'Cambiar detalle.';
    $Self->{Translation}->{'Change and Workorder Templates'} = 'Plantillas de cambios y órdenes de trabajo';
    $Self->{Translation}->{'Change and workorder templates edited by this user.'} = 'Plantillas de cambios y órdenes de trabajo editadas por este usuario.';
    $Self->{Translation}->{'Change area.'} = 'Cambiar de área.';
    $Self->{Translation}->{'Change involved persons of the change.'} = '';
    $Self->{Translation}->{'Change limit per page for Change Overview "Small".'} = 'Límite de cambios por página para el resumen de cambios "Pequeño".';
    $Self->{Translation}->{'Change number'} = 'Cambiar el número';
    $Self->{Translation}->{'Change search backend router of the agent interface.'} = 'Cambiar el enrutamiento de búsqueda de la interfaz del agente.';
    $Self->{Translation}->{'Change state'} = 'Cambiar de estado';
    $Self->{Translation}->{'Change time'} = 'Cambiar el tiempo';
    $Self->{Translation}->{'Change title'} = 'Cambiar el título';
    $Self->{Translation}->{'Condition Edit'} = 'Condición Editar';
    $Self->{Translation}->{'Condition Overview'} = 'Resumen de la condición';
    $Self->{Translation}->{'Configure which screen should be shown after a new workorder has been created.'} =
        'Configure qué pantalla debe mostrarse tras la creación de una nueva orden de trabajo.';
    $Self->{Translation}->{'Configures how often the notifications are sent when planned the start time or other time values have been reached/passed.'} =
        'Configura la frecuencia con la que se envían las notificaciones cuando se ha alcanzado/pasado la hora de inicio planificada u otros valores de tiempo.';
    $Self->{Translation}->{'Create Change'} = 'Crear cambio';
    $Self->{Translation}->{'Create Change (from Template)'} = 'Crear el cambio (desde la plantilla)';
    $Self->{Translation}->{'Create a change (from template) from this ticket.'} = 'Crear un cambio (desde la plantilla) desde este ticket.';
    $Self->{Translation}->{'Create a change from this ticket.'} = 'Cree un cambio a partir de este ticket.';
    $Self->{Translation}->{'Create and manage ITSM Change Management notifications.'} = 'Crear y gestionar las notificaciones de gestión de cambios de ITSM.';
    $Self->{Translation}->{'Create and manage change notifications.'} = 'Crear y gestionar las notificaciones de cambios.';
    $Self->{Translation}->{'Default type for a workorder. This entry must exist in general catalog class \'ITSM::ChangeManagement::WorkOrder::Type\'.'} =
        'Tipo por defecto para una orden de trabajo. Esta entrada debe existir en la clase de catálogo general \'ITSM::ChangeManagement::WorkOrder::Type\'.';
    $Self->{Translation}->{'Define Actions where a settings button is available in the linked objects widget (LinkObject::ViewMode = "complex"). Please note that these Actions must have registered the following JS and CSS files: Core.AllocationList.css, Core.UI.AllocationList.js, Core.UI.Table.Sort.js, Core.Agent.TableFilters.js and Core.Agent.LinkObject.js.'} =
        'Definir acciones en las que un botón de configuración está disponible en el widget de objetos vinculados (LinkObject::ViewMode = "complex"). Tenga en cuenta que estas acciones deben haber registrado los siguientes archivos JS y CSS: Core.AllocationList.css, Core.UI.AllocationList.js, Core.UI.Table.Sort.js, Core.Agent.TableFilters.js y Core.Agent.LinkObject.js.';
    $Self->{Translation}->{'Define the signals for each workorder state.'} = 'Definir las señales para cada estado de la orden de trabajo.';
    $Self->{Translation}->{'Define which columns are shown in the linked Changes widget (LinkObject::ViewMode = "complex"). Note: Only Change attributes are allowed for DefaultColumns. Possible settings: 0 = Disabled, 1 = Available, 2 = Enabled by default.'} =
        'Define qué columnas se muestran en el widget Cambios vinculados (LinkObject::ViewMode = "complex"). Nota: Sólo se permiten atributos de cambio para DefaultColumns. Posibles ajustes: 0 = Desactivado, 1 = Disponible, 2 = Activado por defecto.';
    $Self->{Translation}->{'Define which columns are shown in the linked Workorder widget (LinkObject::ViewMode = "complex"). Note: Only Workorder attributes are allowed for DefaultColumns. Possible settings: 0 = Disabled, 1 = Available, 2 = Enabled by default.'} =
        'Define qué columnas se muestran en el widget de la Orden de Trabajo vinculada (LinkObject::ViewMode = "complex"). Nota: Sólo se permiten atributos de órdenes de trabajo para DefaultColumns. Posibles ajustes: 0 = Desactivado, 1 = Disponible, 2 = Activado por defecto.';
    $Self->{Translation}->{'Defines an overview module to show the small view of a change list.'} =
        'Define un módulo de resumen para mostrar la vista pequeña de una lista de cambios.';
    $Self->{Translation}->{'Defines an overview module to show the small view of a template list.'} =
        'Define un módulo de resumen para mostrar la vista pequeña de una lista de plantillas.';
    $Self->{Translation}->{'Defines if it will be possible to print the accounted time.'} = 'Define si será posible imprimir el tiempo contabilizado.';
    $Self->{Translation}->{'Defines if it will be possible to print the planned effort.'} = 'Define si será posible imprimir el esfuerzo planificado.';
    $Self->{Translation}->{'Defines if reachable (as defined by the state machine) change end states should be allowed if a change is in a locked state.'} =
        'Define si los estados finales de cambio alcanzables (según lo definido por la máquina de estado) deben ser permitidos si un cambio está en un estado bloqueado.';
    $Self->{Translation}->{'Defines if reachable (as defined by the state machine) workorder end states should be allowed if a workorder is in a locked state.'} =
        'Define si se deben permitir estados finales de órdenes de trabajo alcanzables (según lo definido por el estado de la máquina) si una orden de trabajo está en un estado bloqueado.';
    $Self->{Translation}->{'Defines if the accounted time should be shown.'} = 'Define si se debe mostrar el tiempo contabilizado.';
    $Self->{Translation}->{'Defines if the actual start and end times should be set.'} = 'Define si se deben establecer las horas de inicio y finalización reales.';
    $Self->{Translation}->{'Defines if the change search and the workorder search functions could use the mirror DB.'} =
        'Define si las funciones de búsqueda de modificaciones y de búsqueda de órdenes de trabajo pueden utilizar la base de datos espejo.';
    $Self->{Translation}->{'Defines if the change state can be set in the change edit screen of the agent interface.'} =
        'Define si el estado de cambio se puede establecer en la pantalla de edición de cambios de la interfaz del agente.';
    $Self->{Translation}->{'Defines if the planned effort should be shown.'} = 'Define si se debe mostrar el esfuerzo planificado.';
    $Self->{Translation}->{'Defines if the requested date should be print by customer.'} = 'Define si la fecha solicitada debe ser impresa por el cliente.';
    $Self->{Translation}->{'Defines if the requested date should be searched by customer.'} =
        'Define si la fecha solicitada debe buscarse por cliente.';
    $Self->{Translation}->{'Defines if the requested date should be set by customer.'} = 'Define si la fecha solicitada debe ser fijada por el cliente.';
    $Self->{Translation}->{'Defines if the requested date should be shown by customer.'} = 'Define si la fecha solicitada debe ser mostrada por el cliente.';
    $Self->{Translation}->{'Defines if the workorder state should be shown.'} = 'Define si se debe mostrar el estado de la orden de trabajo.';
    $Self->{Translation}->{'Defines if the workorder title should be shown.'} = 'Define si se debe mostrar el estado de la orden de trabajo.';
    $Self->{Translation}->{'Defines shown graph attributes.'} = 'Define los atributos del gráfico mostrado.';
    $Self->{Translation}->{'Defines that only changes containing Workorders linked with services, which the customer user has permission to use will be shown. Any other changes will not be displayed.'} =
        'Define que sólo se muestren los cambios que contengan Órdenes de Trabajo vinculadas a servicios, que el usuario cliente tenga permiso para utilizar. Cualquier otro cambio no se mostrará.';
    $Self->{Translation}->{'Defines the change states that will be allowed to delete.'} = 'Define los estados de cambio que se permitirán eliminar.';
    $Self->{Translation}->{'Defines the change states that will be used as filters in the Change PSA overview.'} =
        'Define los estados de cambio que se utilizarán como filtros en el resumen de PSA de cambio.';
    $Self->{Translation}->{'Defines the change states that will be used as filters in the Change Schedule overview.'} =
        'Define los estados de modificación que se utilizarán como filtros en el resumen del calendario de modificaciones.';
    $Self->{Translation}->{'Defines the change states that will be used as filters in the MyCAB overview.'} =
        'Define los estados de cambio que se utilizarán como filtros en el resumen de MyCAB.';
    $Self->{Translation}->{'Defines the change states that will be used as filters in the MyChanges overview.'} =
        'Define los estados de cambio que se utilizarán como filtros en el resumen de Mis Cambios.';
    $Self->{Translation}->{'Defines the change states that will be used as filters in the change manager overview.'} =
        'Define los estados de cambio que se utilizarán como filtros en el resumen del gestor de cambios.';
    $Self->{Translation}->{'Defines the change states that will be used as filters in the change overview.'} =
        'Define los estados de cambio que se utilizarán como filtros en el resumen de cambios.';
    $Self->{Translation}->{'Defines the change states that will be used as filters in the customer change schedule overview.'} =
        'Define los estados de modificación que se utilizarán como filtros en el resumen del programa de modificación del cliente.';
    $Self->{Translation}->{'Defines the default change title for a dummy change which is needed to edit a workorder template.'} =
        'Define el título de cambio por defecto para un cambio ficticio que se necesita para editar una plantilla de orden de trabajo.';
    $Self->{Translation}->{'Defines the default sort criteria in the change PSA overview.'} =
        'Define los criterios de clasificación por defecto en el resumen del APS de modificación.';
    $Self->{Translation}->{'Defines the default sort criteria in the change manager overview.'} =
        'Define los criterios de ordenación por defecto en el resumen del gestor de modificaciones.';
    $Self->{Translation}->{'Defines the default sort criteria in the change overview.'} = 'Define los criterios de clasificación por defecto en el resumen de modificaciones.';
    $Self->{Translation}->{'Defines the default sort criteria in the change schedule overview.'} =
        'Define los criterios de clasificación por defecto en el resumen del calendario de modificaciones.';
    $Self->{Translation}->{'Defines the default sort criteria of the changes in the MyCAB overview.'} =
        'Define los criterios de ordenación por defecto de los cambios en el resumen de Mi CAB.';
    $Self->{Translation}->{'Defines the default sort criteria of the changes in the MyChanges overview.'} =
        'Define el criterio de ordenación por defecto de las modificaciones en el resumen de Mis Cambios.';
    $Self->{Translation}->{'Defines the default sort criteria of the changes in the MyWorkorders overview.'} =
        'Define el criterio de ordenación por defecto de las modificaciones en el resumen de Mis órdenes de trabajo.';
    $Self->{Translation}->{'Defines the default sort criteria of the changes in the PIR overview.'} =
        'Define el criterio de ordenación por defecto de las modificaciones en el resumen del PIR.';
    $Self->{Translation}->{'Defines the default sort criteria of the changes in the customer change schedule overview.'} =
        'Define los criterios de clasificación por defecto de las modificaciones en el resumen del calendario de modificaciones de clientes.';
    $Self->{Translation}->{'Defines the default sort criteria of the changes in the template overview.'} =
        'Define el criterio de ordenación por defecto de las modificaciones en el resumen del modelo.';
    $Self->{Translation}->{'Defines the default sort order in the MyCAB overview.'} = 'Define el orden de clasificación por defecto en el resumen de Mi CAB.';
    $Self->{Translation}->{'Defines the default sort order in the MyChanges overview.'} = 'Define el orden de clasificación por defecto en el resumen de Mis Cambios.';
    $Self->{Translation}->{'Defines the default sort order in the MyWorkorders overview.'} =
        'Define el orden de clasificación por defecto en el resumen de Mis Órdenes de Trabajo.';
    $Self->{Translation}->{'Defines the default sort order in the PIR overview.'} = 'Define el orden de clasificación por defecto en el resumen del PIR.';
    $Self->{Translation}->{'Defines the default sort order in the change PSA overview.'} = 'Define el orden de clasificación por defecto en el resumen del APS de modificación.';
    $Self->{Translation}->{'Defines the default sort order in the change manager overview.'} =
        'Define el orden de clasificación por defecto en el resumen del gestor de modificaciones.';
    $Self->{Translation}->{'Defines the default sort order in the change overview.'} = 'Define el orden de clasificación por defecto en el resumen de modificaciones.';
    $Self->{Translation}->{'Defines the default sort order in the change schedule overview.'} =
        'Define el orden de clasificación por defecto en el resumen del programa de modificaciones.';
    $Self->{Translation}->{'Defines the default sort order in the customer change schedule overview.'} =
        'Define el orden de clasificación por defecto en el resumen del programa de modificación de clientes.';
    $Self->{Translation}->{'Defines the default sort order in the template overview.'} = 'Define el orden de clasificación por defecto en el resumen de la plantilla.';
    $Self->{Translation}->{'Defines the default value for the category of a change.'} = 'Define el valor por defecto de la categoría de un cambio.';
    $Self->{Translation}->{'Defines the default value for the impact of a change.'} = 'Define el valor predeterminado para el impacto de un cambio.';
    $Self->{Translation}->{'Defines the field type of CompareValue fields for change attributes used in the change condition edit screen of the agent interface. Valid values are Selection, Text and Date. If a type is not defined, the field will not be shown.'} =
        'Define el tipo de campo de CompareValue los campos para los atributos de cambio utilizados en la pantalla de edición de condiciones de cambio de la interfaz del agente. Los valores válidos son Selección, Texto y Fecha. Si no se define un tipo, el campo no se mostrará.';
    $Self->{Translation}->{'Defines the field type of CompareValue fields for workorder attributes used in the change condition edit screen of the agent interface. Valid values are Selection, Text and Date. If a type is not defined, the field will not be shown.'} =
        'Define el tipo de campo CompareValue de los campos para los atributos de la orden de trabajo utilizados en la pantalla de edición de la condición de cambio de la interfaz del agente. Los valores válidos son Selección, Texto y Fecha. Si no se define un tipo, el campo no se mostrará.';
    $Self->{Translation}->{'Defines the height for the rich text editor component for this screen. Enter number (pixels) or percent value (relative).'} =
        '';
    $Self->{Translation}->{'Defines the object attributes that are selectable for change objects in the change condition edit screen of the agent interface.'} =
        'Define los atributos del objeto que se pueden seleccionar para modificar los objetos en la pantalla de edición de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the object attributes that are selectable for workorder objects in the change condition edit screen of the agent interface.'} =
        'Define los atributos del objeto que se pueden seleccionar para los objetos de la orden de trabajo en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute AccountedTime in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo Tiempo contabilizado en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute ActualEndTime in the change condition edit screen of the agent interface.'} =
        'Define los operadores que se pueden seleccionar para el atributo Hora de finalización real en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute ActualStartTime in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo Hora de inicio real en la pantalla de edición de condiciones de cambio de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute CategoryID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo CategoryID en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute ChangeBuilderID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo ChangeBuilderID en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute ChangeManagerID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo ChangeManagerID en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute ChangeStateID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo ChangeStateID en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute ChangeTitle in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo ChangeTitle en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute DynamicField in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo DynamicField en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute ImpactID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo ImpactID en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute PlannedEffort in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo Esfuerzo planificado en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute PlannedEndTime in the change condition edit screen of the agent interface.'} =
        'Define los operadores que se pueden seleccionar para el atributo Hora de finalización prevista en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute PlannedStartTime in the change condition edit screen of the agent interface.'} =
        'Define los operadores que se pueden seleccionar para el atributo Hora de inicio prevista en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute PriorityID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo PriorityID en la pantalla de edición de cambio condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute RequestedTime in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo Hora solicitada en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute WorkOrderAgentID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo WorkOrderAgentID en la pantalla de cambio edición de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute WorkOrderNumber in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo WorkOrderNumber en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute WorkOrderStateID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo WorkOrderStateID en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute WorkOrderTitle in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo Título de la Orden de Trabajo en la pantalla de edición de condición de la interfaz del agente.';
    $Self->{Translation}->{'Defines the operators that are selectable for the attribute WorkOrderTypeID in the change condition edit screen of the agent interface.'} =
        'Define los operadores seleccionables para el atributo WorkOrderTypeID en la pantalla de edición cambio de condiciones de la interfaz del agente.';
    $Self->{Translation}->{'Defines the period (in years), in which start and end times can be selected.'} =
        'Define el periodo (en años), en el que se pueden seleccionar las horas de inicio y fin.';
    $Self->{Translation}->{'Defines the shown attributes of a workorder in the tooltip of the workorder graph in the change zoom. To show workorder dynamic fields in the tooltip, they must be specified like DynamicField_WorkOrderFieldName1, DynamicField_WorkOrderFieldName2, etc.'} =
        'Define los atributos mostrados de una orden de trabajo en el tooltip del gráfico de la orden de trabajo en el detalle de modificación. Para mostrar los campos dinámicos de la orden de trabajo en la tooltip, deben especificarse como DynamicField_WorkOrderFieldName1, DynamicField_WorkOrderFieldName2, etc.';
    $Self->{Translation}->{'Defines the shown columns in the Change PSA overview. This option has no effect on the position of the column.'} =
        'Define las columnas que se muestran en el resumen de cambios de la Disponibilidad proyectada del servicio (PSA) Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the Change Schedule overview. This option has no effect on the position of the column.'} =
        'Define las columnas que se muestran en el resumen del programa de modificaciones. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the MyCAB overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en la vista general de MyCAB. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the MyChanges overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en el resumen de Mis Cambios. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the MyWorkorders overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en la vista general de Mis Órdenes de Trabajo. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the PIR overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en el resumen del PIR. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the change manager overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en el resumen del gestor de modificaciones. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the change overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en el resumen de cambios. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the change search. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en la búsqueda de cambios. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the customer change schedule overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en el resumen del programa de modificación de clientes. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the shown columns in the template overview. This option has no effect on the position of the column.'} =
        'Define las columnas mostradas en el resumen de la plantilla. Esta opción no tiene efecto sobre la posición de la columna.';
    $Self->{Translation}->{'Defines the signals for each ITSM change state.'} = 'Define las señales para cada estado de cambio de ITSM.';
    $Self->{Translation}->{'Defines the template types that will be used as filters in the template overview.'} =
        'Define los tipos de plantillas que se utilizarán como filtros en el resumen de plantillas.';
    $Self->{Translation}->{'Defines the workorder states that will be used as filters in the MyWorkorders overview.'} =
        'Define los estados de las órdenes de trabajo que se utilizarán como filtros en la vista general de Mis órdenes de trabajo.';
    $Self->{Translation}->{'Defines the workorder states that will be used as filters in the PIR overview.'} =
        'Define los estados de las órdenes de trabajo que se utilizarán como filtros en el resumen del PIR.';
    $Self->{Translation}->{'Defines the workorder types that will be used to show the PIR overview.'} =
        'Define los tipos de órdenes de trabajo que se utilizarán para mostrar el resumen del PIR.';
    $Self->{Translation}->{'Defines whether notifications should be sent.'} = 'Define si se deben enviar notificaciones.';
    $Self->{Translation}->{'Delete a change.'} = 'Eliminar un cambio.';
    $Self->{Translation}->{'Delete the change.'} = 'Eliminar el cambio.';
    $Self->{Translation}->{'Delete the workorder.'} = 'Eliminar la orden de trabajo.';
    $Self->{Translation}->{'Details of a change history entry.'} = 'Detalles de una entrada del historial de cambios.';
    $Self->{Translation}->{'Determines if an agent can exchange the X-axis of a stat if he generates one.'} =
        'Determina si un agente puede intercambiar el eje X de una estadística si genera una.';
    $Self->{Translation}->{'Determines if the common stats module may generate stats about changes done for config item classes.'} =
        'Determina si el módulo de estadísticas comunes puede generar estadísticas sobre los cambios realizados en las clases de elementos de configuración.';
    $Self->{Translation}->{'Determines if the common stats module may generate stats about changes regarding change state updates within a timeperiod.'} =
        'Determina si el módulo de estadísticas comunes puede generar estadísticas sobre los cambios relativos a las actualizaciones del estado de los cambios dentro de un período de tiempo.';
    $Self->{Translation}->{'Determines if the common stats module may generate stats about changes regarding the relation between changes and incident tickets.'} =
        'Determina si el módulo de estadísticas comunes puede generar estadísticas sobre los cambios con respecto a la relación entre los cambios y los tickets de incidencias.';
    $Self->{Translation}->{'Determines if the common stats module may generate stats about changes.'} =
        'Determina si el módulo de estadísticas comunes puede generar estadísticas sobre los cambios.';
    $Self->{Translation}->{'Determines if the common stats module may generate stats about the number of Rfc tickets a requester created.'} =
        'puede generar estadísticas sobre el número de tickets RFC creados por un solicitante.';
    $Self->{Translation}->{'Dynamic fields (for changes and workorders) shown in the change print screen of the agent interface.'} =
        'Campos dinámicos (para cambios y órdenes de trabajo) mostrados en la pantalla de impresión de cambios de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the change add screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de modificación de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the change edit screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de edición de cambios de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the change search screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de búsqueda de cambios de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the change zoom screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla detalle de cambio de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the workorder add screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de agregar de órdenes de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the workorder edit screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de edición de órdenes de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the workorder report screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de reportes de órdenes de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Dynamic fields shown in the workorder zoom screen of the agent interface.'} =
        'Campos dinámicos mostrados en la pantalla de avance de la orden de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'DynamicField event module to handle the update of conditions if dynamic fields are added, updated or deleted.'} =
        'Módulo de eventos de campos dinámicos para gestionar la actualización de las condiciones si se añaden, actualizan o eliminan campos dinámicos.';
    $Self->{Translation}->{'Edit a change.'} = 'Editar un cambio.';
    $Self->{Translation}->{'Edit the change.'} = 'Editar el cambio.';
    $Self->{Translation}->{'Edit the conditions of the change.'} = 'Editar las condiciones del cambio.';
    $Self->{Translation}->{'Edit the workorder.'} = 'Editar la orden de trabajo.';
    $Self->{Translation}->{'Enables the minimal change counter size (if "Date" was selected as ITSMChange::NumberGenerator).'} =
        'Activa el tamaño mínimo del contador de cambios (si se ha seleccionado "Fecha" como ITSMChange::NumberGenerator).';
    $Self->{Translation}->{'Forward schedule of changes. Overview over approved changes.'} =
        'Calendario de cambios. Resumen sobre los cambios aprobados.';
    $Self->{Translation}->{'History Zoom'} = 'Detalle histórico';
    $Self->{Translation}->{'ITSM Change CAB Templates.'} = '';
    $Self->{Translation}->{'ITSM Change Condition Edit.'} = 'Editar la condición de cambio de ITSM.';
    $Self->{Translation}->{'ITSM Change Condition Overview.'} = 'Visión general del cambio de la condición de ITSM.';
    $Self->{Translation}->{'ITSM Change Manager Overview.'} = 'Visión general del Gestor de Cambios ITSM.';
    $Self->{Translation}->{'ITSM Change Notifications'} = 'Cambios de Notificaciones de ITSM';
    $Self->{Translation}->{'ITSM Change PIR Overview.'} = '';
    $Self->{Translation}->{'ITSM Change notification rules'} = 'Cambio de reglas de notificaciones de ITSM';
    $Self->{Translation}->{'ITSM Changes'} = 'ITSM Cambios';
    $Self->{Translation}->{'ITSM MyCAB Overview.'} = 'Visión general de ITSM MyCAB.';
    $Self->{Translation}->{'ITSM MyChanges Overview.'} = '';
    $Self->{Translation}->{'ITSM MyWorkorders Overview.'} = 'Resumen de ITSM mis órdenes de trabajo.';
    $Self->{Translation}->{'ITSM Template Delete.'} = 'Eliminar plantilla ITSM.';
    $Self->{Translation}->{'ITSM Template Edit CAB.'} = 'Plantilla ITSM Editar CAB.';
    $Self->{Translation}->{'ITSM Template Edit Content.'} = 'Editar Contenido de la plantilla ITSM.';
    $Self->{Translation}->{'ITSM Template Edit.'} = 'Edición de plantilla ITSM.';
    $Self->{Translation}->{'ITSM Template Overview.'} = 'Resumen de la plantilla ITSM.';
    $Self->{Translation}->{'ITSM event module that cleans up conditions.'} = 'Módulo de eventos ITSM que limpia las condiciones.';
    $Self->{Translation}->{'ITSM event module that deletes the cache for a toolbar.'} = 'Módulo de eventos ITSM que borra el caché de una barra de herramientas.';
    $Self->{Translation}->{'ITSM event module that deletes the history of changes.'} = 'Módulo de eventos ITSM que borra el historial de cambios.';
    $Self->{Translation}->{'ITSM event module that matches conditions and executes actions.'} =
        'Módulo de eventos de ITSM que compara las condiciones y ejecuta las acciones.';
    $Self->{Translation}->{'ITSM event module that sends notifications.'} = 'Módulo de eventos ITSM que envía notificaciones.';
    $Self->{Translation}->{'ITSM event module that updates the history of changes.'} = 'Módulo de eventos ITSM que actualiza el historial de cambios.';
    $Self->{Translation}->{'ITSM event module that updates the history of conditions.'} = 'Módulo de eventos ITSM que actualiza el historial de condiciones.';
    $Self->{Translation}->{'ITSM event module that updates the history of workorders.'} = 'Módulo de eventos ITSM que actualiza el historial de órdenes de trabajo.';
    $Self->{Translation}->{'ITSM event module to recalculate the workorder numbers.'} = 'Módulo de eventos ITSM para recalcular los números de las órdenes de trabajo.';
    $Self->{Translation}->{'ITSM event module to set the actual start and end times of workorders.'} =
        'Módulo de eventos ITSM para establecer las horas reales de inicio y finalización de las órdenes de trabajo.';
    $Self->{Translation}->{'ITSMChange'} = 'Cambio';
    $Self->{Translation}->{'ITSMWorkOrder'} = 'Orden de trabajo ITSM';
    $Self->{Translation}->{'If frequency is \'regularly\', you can configure how often the notifications are sent (every X hours).'} =
        'Si la frecuencia es "regularmente", puede configurar la frecuencia de envío de las notificaciones (cada X horas).';
    $Self->{Translation}->{'Link another object to the change.'} = 'Vincular otro objeto al cambio.';
    $Self->{Translation}->{'Link another object to the workorder.'} = 'Vincular otro objeto a la orden de trabajo.';
    $Self->{Translation}->{'List of all change events to be displayed in the GUI.'} = 'Lista de todos los eventos de cambio que se mostrarán en la GUI.';
    $Self->{Translation}->{'List of all workorder events to be displayed in the GUI.'} = 'Lista de todos los eventos de órdenes de trabajo que se mostrarán en la GUI.';
    $Self->{Translation}->{'Lookup of CAB members for autocompletion.'} = 'Búsqueda de miembros del CAB para autocompletar.';
    $Self->{Translation}->{'Lookup of agents, used for autocompletion.'} = 'Búsqueda de agentes, utilizada para el autocompletado.';
    $Self->{Translation}->{'Manage ITSM Change Management state machine.'} = '';
    $Self->{Translation}->{'Manage the category ↔ impact ↔ priority matrix.'} = 'Gestionar la categoría ↔ impacto ↔ matriz de prioridades.';
    $Self->{Translation}->{'Module to check if WorkOrderAdd or WorkOrderAddFromTemplate should be permitted.'} =
        'Módulo para comprobar si se debe permitir la adición de órdenes de trabajo o la adición de órdenes de trabajo desde la plantilla.';
    $Self->{Translation}->{'Module to check the CAB members.'} = 'Módulo para comprobar los miembros del CAB.';
    $Self->{Translation}->{'Module to check the agent.'} = 'Módulo para comprobar el agente.';
    $Self->{Translation}->{'Module to check the change builder.'} = 'Módulo para comprobar el constructor de cambios.';
    $Self->{Translation}->{'Module to check the change manager.'} = 'Módulo para comprobar el gestor de cambios.';
    $Self->{Translation}->{'Module to check the workorder agent.'} = 'Módulo para comprobar el agente de órdenes de trabajo.';
    $Self->{Translation}->{'Module to check whether no workorder agent is set.'} = 'Módulo para comprobar si no se ha establecido ningún agente de órdenes de trabajo.';
    $Self->{Translation}->{'Module to check whether the agent is contained in the configured list.'} =
        'Módulo para comprobar si el agente está contenido en la lista configurada.';
    $Self->{Translation}->{'Module to show a link to create a change from this ticket. The ticket will be automatically linked with the new change.'} =
        'Módulo para mostrar un enlace para crear un cambio desde este ticket. El ticket se vinculará automáticamente con el nuevo cambio.';
    $Self->{Translation}->{'Move Time Slot.'} = 'Mover la franja horaria.';
    $Self->{Translation}->{'Move all workorders in time.'} = 'Mover todas las órdenes de trabajo a tiempo.';
    $Self->{Translation}->{'New (from template)'} = 'Nuevo (desde la plantilla)';
    $Self->{Translation}->{'Only users of these groups have the permission to use the ticket types as defined in "ITSMChange::AddChangeLinkTicketTypes" if the feature "Ticket::Acl::Module###200-Ticket::Acl::Module" is enabled.'} =
        'Sólo los usuarios de estos grupos tienen permiso para utilizar los tipos de tickets definidos en "ITSMChange::AddChangeLinkTicketTypes" si la función "Ticket::Acl::Module##200-Ticket::Module" está activada.';
    $Self->{Translation}->{'Other Settings'} = 'Otras Configuraciones';
    $Self->{Translation}->{'Overview over all Changes.'} = 'Resumen de todos los cambios.';
    $Self->{Translation}->{'PIR'} = 'Revisión Post Implementación (PIR)';
    $Self->{Translation}->{'PIR (Post Implementation Review)'} = 'Revisión Post Implementación (PIR)';
    $Self->{Translation}->{'PSA'} = 'Disponibilidad del servicio proyectada (PSA)';
    $Self->{Translation}->{'Parameters for the UserCreateWorkOrderNextMask object in the preference view of the agent interface.'} =
        'Parámetros para el objeto UserCreateWorkOrderNextMask en la vista de preferencias de la interfaz del agente.';
    $Self->{Translation}->{'Parameters for the pages (in which the changes are shown) of the small change overview.'} =
        'Parámetros para las páginas (en las que se muestran los cambios) del resumen de pequeñas modificaciones.';
    $Self->{Translation}->{'Performs the configured action for each event (as an Invoker) for each configured Webservice.'} =
        'Realiza la acción configurada para cada evento (como Invoker) para cada Webservice configurado.';
    $Self->{Translation}->{'Planned end time'} = 'Hora de finalización prevista';
    $Self->{Translation}->{'Planned start time'} = 'Hora de inicio prevista';
    $Self->{Translation}->{'Print the change.'} = 'Imprime el cambio.';
    $Self->{Translation}->{'Print the workorder.'} = 'Imprimir la orden de trabajo.';
    $Self->{Translation}->{'Projected Service Availability'} = 'Disponibilidad del servicio proyectada';
    $Self->{Translation}->{'Projected Service Availability (PSA)'} = 'Disponibilidad del servicio proyectada (PSA)';
    $Self->{Translation}->{'Projected Service Availability (PSA) of changes. Overview of approved changes and their services.'} =
        'Cambios de la Disponibilidad de servicio proyectada (PSA). Resumen de los cambios aprobados y sus servicios.';
    $Self->{Translation}->{'Requested time'} = 'Hora solicitada';
    $Self->{Translation}->{'Required privileges in order for an agent to take a workorder.'} =
        'Privilegios necesarios para que un agente pueda tomar una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to access the overview of all changes.'} = 'Privilegios necesarios para acceder al resumen de todos los cambios.';
    $Self->{Translation}->{'Required privileges to add a workorder.'} = 'Privilegios necesarios para añadir una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to change the workorder agent.'} = 'Privilegios necesarios para cambiar el agente de la orden de trabajo.';
    $Self->{Translation}->{'Required privileges to create a template from a change.'} = 'Privilegios necesarios para crear una plantilla a partir de una modificación.';
    $Self->{Translation}->{'Required privileges to create a template from a changes\' CAB.'} =
        'Privilegios necesarios para crear una plantilla a partir de un CAB.';
    $Self->{Translation}->{'Required privileges to create a template from a workorder.'} = 'Privilegios necesarios para crear una plantilla a partir de una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to create changes from templates.'} = 'Privilegios necesarios para crear cambios desde las plantillas.';
    $Self->{Translation}->{'Required privileges to create changes.'} = 'Privilegios necesarios para crear cambios.';
    $Self->{Translation}->{'Required privileges to delete a template.'} = 'Privilegios necesarios para eliminar una plantilla.';
    $Self->{Translation}->{'Required privileges to delete a workorder.'} = 'Privilegios necesarios para eliminar una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to delete changes.'} = 'Privilegios necesarios para eliminar los cambios.';
    $Self->{Translation}->{'Required privileges to edit a template.'} = 'Privilegios necesarios para editar una plantilla.';
    $Self->{Translation}->{'Required privileges to edit a workorder.'} = 'Privilegios necesarios para editar una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to edit changes.'} = 'Privilegios necesarios para editar los cambios.';
    $Self->{Translation}->{'Required privileges to edit the conditions of changes.'} = 'Privilegios necesarios para editar las condiciones de los cambios.';
    $Self->{Translation}->{'Required privileges to edit the content of a template.'} = 'Privilegios necesarios para editar el contenido de una plantilla.';
    $Self->{Translation}->{'Required privileges to edit the involved persons of a change.'} =
        'Privilegios necesarios para editar las personas implicadas en un cambio.';
    $Self->{Translation}->{'Required privileges to move changes in time.'} = 'Los privilegios requeridos para mover los cambios en el tiempo.';
    $Self->{Translation}->{'Required privileges to print a change.'} = 'Privilegios necesarios para imprimir un cambio.';
    $Self->{Translation}->{'Required privileges to reset changes.'} = 'Privilegios necesarios para restablecer los cambios.';
    $Self->{Translation}->{'Required privileges to view a workorder.'} = 'Privilegios necesarios para ver una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to view changes.'} = 'Privilegios necesarios para ver los cambios.';
    $Self->{Translation}->{'Required privileges to view list of changes where the user is a CAB member.'} =
        'Privilegios necesarios para ver la lista de cambios cuando el usuario es miembro del CAB.';
    $Self->{Translation}->{'Required privileges to view list of changes where the user is the change manager.'} =
        'Privilegios necesarios para ver la lista de cambios donde el usuario es el gestor de cambios.';
    $Self->{Translation}->{'Required privileges to view overview over all templates.'} = 'Privilegios necesarios para ver el resumen de todas las plantillas.';
    $Self->{Translation}->{'Required privileges to view the conditions of changes.'} = 'Privilegios necesarios para ver las condiciones de los cambios.';
    $Self->{Translation}->{'Required privileges to view the history of a change.'} = 'Privilegios necesarios para ver el historial de un cambio.';
    $Self->{Translation}->{'Required privileges to view the history of a workorder.'} = 'Privilegios necesarios para ver el historial de una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to view the history zoom of a change.'} = 'Privilegios necesarios para ver el detalle del historial de una modificación.';
    $Self->{Translation}->{'Required privileges to view the history zoom of a workorder.'} =
        'Privilegios necesarios para ver el detalle del historial de una orden de trabajo.';
    $Self->{Translation}->{'Required privileges to view the list of Change Schedule.'} = 'Privilegios necesarios para ver la lista de la programación de cambios.';
    $Self->{Translation}->{'Required privileges to view the list of change PSA.'} = 'Privilegios requeridos para ver la lista de cambios PSA.';
    $Self->{Translation}->{'Required privileges to view the list of changes with an upcoming PIR (Post Implementation Review).'} =
        'Privilegios necesarios para ver la lista de cambios con una próxima PIR (Revisión Post-Implementación).';
    $Self->{Translation}->{'Required privileges to view the list of own changes.'} = 'Privilegios necesarios para ver la lista de cambios propios.';
    $Self->{Translation}->{'Required privileges to view the list of own workorders.'} = 'Privilegios necesarios para ver la lista de órdenes de trabajo propias.';
    $Self->{Translation}->{'Required privileges to write a report for the workorder.'} = 'Privilegios necesarios para escribir un informe para la orden de trabajo.';
    $Self->{Translation}->{'Reset a change and its workorders.'} = 'Restablecer un cambio y sus órdenes de trabajo.';
    $Self->{Translation}->{'Reset change and its workorders.'} = 'Restablecer el cambio y sus órdenes de trabajo.';
    $Self->{Translation}->{'Run task to check if specific times have been reached in changes and workorders.'} =
        'Ejecutar la tarea para comprobar si se han alcanzado los tiempos específicos en los cambios y órdenes de trabajo.';
    $Self->{Translation}->{'Save change as a template.'} = 'Guardar el cambio como una plantilla.';
    $Self->{Translation}->{'Save workorder as a template.'} = 'Guardar la orden de trabajo como una plantilla.';
    $Self->{Translation}->{'Schedule'} = 'Horario';
    $Self->{Translation}->{'Screen after creating a workorder'} = 'Pantalla después de crear una orden de trabajo';
    $Self->{Translation}->{'Search Changes'} = 'Buscar cambios';
    $Self->{Translation}->{'Search Changes.'} = 'Buscar cambios.';
    $Self->{Translation}->{'Selects the change number generator module. "AutoIncrement" increments the change number, the SystemID and the counter are used with SystemID.counter format (e.g. 100118, 100119). With "Date", the change numbers will be generated by the current date and a counter; this format looks like Year.Month.Day.counter, e.g. 2010062400001, 2010062400002. With "DateChecksum", the counter will be appended as checksum to the string of date plus the SystemID. The checksum will be rotated on a daily basis. This format looks like Year.Month.Day.SystemID.Counter.CheckSum, e.g. 2010062410000017, 2010062410000026.'} =
        'Selecciona el módulo generador de números de cambio. "AutoIncremento" incrementa el número de cambio, el SystemID y el contador se utilizan con el formato SystemID.counter (por ejemplo 100118, 100119). Con "Fecha", los números de cambio serán generados por la fecha actual y un contador; este formato se parece a Año.Mes.Día.contador, por ejemplo 2010062400001, 2010062400002. Con "DateChecksum", el contador se añadirá como suma de comprobación a la cadena de fecha más el SystemID. La suma de comprobación se rotará diariamente. Este formato se parece a Año.Mes.Día.SystemID.Contador.Suma de comprobación, por ejemplo, 2010062410000017, 2010062410000026.';
    $Self->{Translation}->{'Set the agent for the workorder.'} = 'Establezca el agente para la orden de trabajo.';
    $Self->{Translation}->{'Set the default height (in pixels) of inline HTML fields in the change zoom screen and workorder zoom screen of the agent interface.'} =
        'Establezca la altura por defecto (en píxeles) de los campos HTML en línea en la pantalla de detalles de cambios y en la pantalla de detalles de órdenes de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Set the maximum height (in pixels) of inline HTML fields in the change zoom screen and workorder zoom screen of the agent interface.'} =
        'Establezca la altura máxima (en píxeles) de los campos HTML en línea en la pantalla de zoom de cambios y en la pantalla de zoom de órdenes de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Sets the minimal change counter size (if "AutoIncrement" was selected as ITSMChange::NumberGenerator). Default is 5, this means the counter starts from 10000.'} =
        'Establece el tamaño mínimo del contador de cambios (si se ha seleccionado "AutoIncremento" como ITSMChange::NumberGenerator). Por defecto es 5, esto significa que el contador comienza desde 10000.';
    $Self->{Translation}->{'Sets up the state machine for changes.'} = 'Configura el estado de la máquina para los cambios.';
    $Self->{Translation}->{'Sets up the state machine for workorders.'} = 'Establece el estado de la máquina para las órdenes de trabajo.';
    $Self->{Translation}->{'Shows a checkbox in the workorder edit screen of the agent interface that defines if the the following workorders should also be moved if a workorder is modified and the planned end time has changed.'} =
        'Muestra una casilla de verificación en la pantalla de edición de órdenes de trabajo de la interfaz del agente que define si las siguientes órdenes de trabajo también deben moverse si se modifica una orden de trabajo y la hora de finalización prevista ha cambiado.';
    $Self->{Translation}->{'Shows a link in the menu that allows changing the workorder agent, in the zoom view of the workorder of the agent interface.'} =
        'Muestra un enlace en el menú que permite cambiar el agente de la orden de trabajo, en la vista de zoom de la orden de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu that allows defining a change as a template in the zoom view of the change, in the agent interface.'} =
        'Muestra un enlace en el menú que permite definir un cambio como una plantilla en la vista de zoom del cambio, en la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu that allows defining a workorder as a template in the zoom view of the workorder, in the agent interface.'} =
        'Muestra un enlace en el menú que permite definir una orden de trabajo como plantilla en la vista de zoom de la orden de trabajo, en la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu that allows editing the report of a workorder, in the zoom view of the workorder of the agent interface.'} =
        'Muestra un enlace en el menú que permite editar el informe de una orden de trabajo, en la vista de zoom de la orden de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu that allows linking a change with another object in the change zoom view of the agent interface.'} =
        'Muestra un enlace en el menú que permite vincular un cambio con otro objeto en la vista de zoom de cambios de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu that allows linking a workorder with another object in the zoom view of the workorder of the agent interface.'} =
        'Muestra un enlace en el menú que permite vincular una orden de trabajo con otro objeto en la vista de zoom de la orden de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu that allows moving the time slot of a change in its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú que permite mover la franja horaria de un cambio en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu that allows taking a workorder in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú que permite tomar una orden de trabajo en la vista de detalle desde la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to access the conditions of a change in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para acceder a las condiciones de un cambio en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to access the history of a change in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para acceder al historial de un cambio en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to access the history of a workorder in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para acceder al historial de una orden de trabajo en la vista de detalle desde la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to add a workorder in the change zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para añadir una orden de trabajo en la vista de zoom de cambio de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to delete a change in its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para eliminar un cambio en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to delete a workorder in its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para eliminar una orden de trabajo en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to edit a change in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para editar un cambio en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to edit a workorder in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para editar una orden de trabajo en la vista de detalle desde la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to go back in the change zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para volver a la vista de cambio de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to go back in the workorder zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para volver a la vista de zoom de la orden de trabajo de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to print a change in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para imprimir un cambio en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to print a workorder in the its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para imprimir una orden de trabajo en la vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to reset a change and its workorders in its zoom view of the agent interface.'} =
        'Muestra un enlace en el menú para restablecer un cambio y sus órdenes de trabajo en su vista de zoom de la interfaz del agente.';
    $Self->{Translation}->{'Shows a link in the menu to show the involved persons in a change, in the zoom view of the change in the agent interface.'} =
        'Muestra un enlace en el menú para mostrar las personas involucradas en un cambio, en la vista de zoom del cambio en la interfaz del agente.';
    $Self->{Translation}->{'Shows the change history (reverse ordered) in the agent interface.'} =
        'Muestra el historial de cambios (ordenado de forma inversa) en la interfaz del agente.';
    $Self->{Translation}->{'State Machine'} = 'Estado de la máquina';
    $Self->{Translation}->{'Stores change and workorder ids and their corresponding template id, while a user is editing a template.'} =
        'Almacena los identificadores de cambios y de órdenes de trabajo y su correspondiente identificador de plantilla, mientras un usuario está editando una plantilla.';
    $Self->{Translation}->{'Take Workorder'} = 'Tomar orden de trabajo';
    $Self->{Translation}->{'Take Workorder.'} = 'Tomar orden de trabajo.';
    $Self->{Translation}->{'Take the workorder.'} = 'Toma la orden de trabajo.';
    $Self->{Translation}->{'Template Overview'} = 'Resumen de la plantilla';
    $Self->{Translation}->{'Template type'} = 'Tipo de plantilla';
    $Self->{Translation}->{'Template.'} = 'Plantilla.';
    $Self->{Translation}->{'The identifier for a change, e.g. Change#, MyChange#. The default is Change#.'} =
        'El identificador de un cambio, por ejemplo, Change#, MyChange#. El valor por defecto es Change#.';
    $Self->{Translation}->{'The identifier for a workorder, e.g. Workorder#, MyWorkorder#. The default is Workorder#.'} =
        'El identificador de una orden de trabajo, por ejemplo, Orden de Trabajo#, Mi orden de trabajo#. El valor por defecto es Orden de trabajo#.';
    $Self->{Translation}->{'This ACL module restricts the usuage of the ticket types that are defined in the sysconfig option \'ITSMChange::AddChangeLinkTicketTypes\', to users of the groups as defined in "ITSMChange::RestrictTicketTypes::Groups". As this ACL could collide with other ACLs which are also related to the ticket type, this sysconfig option is disabled by default and should only be activated if needed.'} =
        'Este módulo ACL restringe el uso de los tipos de tickets que se definen en la opción sysconfig \'ITSMChange::AddChangeLinkTicketTypes\', a los usuarios de los grupos definidos en "ITSMChange::RestrictTicketTypes::Groups". Como esta ACL podría colisionar con otras ACLs que también están relacionadas con el tipo de ticket, esta opción de sysconfig está desactivada por defecto y sólo debería activarse si es necesario.';
    $Self->{Translation}->{'Time Slot'} = 'Franja horaria';
    $Self->{Translation}->{'Types of tickets, where in the ticket zoom view a link to add a change will be displayed.'} =
        'Tipos de tickets, donde en la vista de zoom del ticket se mostrará un enlace para añadir un cambio.';
    $Self->{Translation}->{'User Search'} = 'Búsqueda de usuarios';
    $Self->{Translation}->{'Workorder Add (from template).'} = 'Añadir orden de trabajo (desde la plantilla).';
    $Self->{Translation}->{'Workorder Add.'} = 'Añadir orden de trabajo.';
    $Self->{Translation}->{'Workorder Agent.'} = 'Agente de órdenes de trabajo.';
    $Self->{Translation}->{'Workorder Delete.'} = 'Borrar orden de trabajo.';
    $Self->{Translation}->{'Workorder Edit.'} = 'Edición de la orden de trabajo.';
    $Self->{Translation}->{'Workorder History Zoom.'} = 'Zoom del historial de órdenes de trabajo.';
    $Self->{Translation}->{'Workorder History.'} = 'Historial de órdenes de trabajo.';
    $Self->{Translation}->{'Workorder Report.'} = 'Informe de órdenes de trabajo.';
    $Self->{Translation}->{'Workorder Zoom'} = 'Zoom de la orden de trabajo';
    $Self->{Translation}->{'Workorder Zoom.'} = 'Zoom de la orden de trabajo.';
    $Self->{Translation}->{'once'} = 'una vez';
    $Self->{Translation}->{'regularly'} = 'regularmente';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Do you really want to delete this action?',
    'Do you really want to delete this condition?',
    'Do you really want to delete this expression?',
    'Do you really want to delete this notification language?',
    'Do you really want to delete this notification?',
    'No',
    'Ok',
    'Please enter at least one search value or * to find anything.',
    'Settings',
    'Submit',
    'Yes',
    );

}

1;
