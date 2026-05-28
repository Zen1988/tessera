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

package Kernel::Language::es_MX_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'Funcionalidad';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'Administración del Catálogo General';
    $Self->{Translation}->{'Items in Class'} = 'Artículos en clase';
    $Self->{Translation}->{'Edit Item'} = 'Editar artículo';
    $Self->{Translation}->{'Add Class'} = 'Agregar clase';
    $Self->{Translation}->{'Add Item'} = 'Agregar artículo';
    $Self->{Translation}->{'Add Catalog Item'} = 'Añadir artículo del catálogo';
    $Self->{Translation}->{'Add Catalog Class'} = 'Añadir clase del catálogo';
    $Self->{Translation}->{'Catalog Class'} = 'Catálogo de clases';
    $Self->{Translation}->{'Edit Catalog Item'} = 'Editar artículo del catálogo';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = 'Advertencia El estado del incidente no se puede establecer como inválido.';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = 'Comentario 2';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'Crear y administrar el Catálogo General.';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = 'Definir el comentario 2 del catálogo general.';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = 'Define la URL para el Selector de Color JS.';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'Registro del módulo de Frontend para la administración del catálogo general en el área de administración.';
    $Self->{Translation}->{'General Catalog'} = 'Catálogo General';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'Parámetros para el comentario de ejemplo 2 del catálogo general de atributos.';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'Parámetros para el ejemplo de permisos de grupo del catálogo general de atributos.';
    $Self->{Translation}->{'Permission Group'} = 'Permisos de grupo';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
