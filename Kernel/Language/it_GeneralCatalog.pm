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

package Kernel::Language::it_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'Funzionalità';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'Gestione del Catalogo Generale';
    $Self->{Translation}->{'Items in Class'} = 'Elementi nella Classe';
    $Self->{Translation}->{'Edit Item'} = 'Modifica Elemento';
    $Self->{Translation}->{'Add Class'} = 'Aggiungi Classe';
    $Self->{Translation}->{'Add Item'} = 'Aggiungi Elemento';
    $Self->{Translation}->{'Include invalid items'} = '';
    $Self->{Translation}->{'Add Catalog Item'} = 'Aggiungi Elemento al Catalogo';
    $Self->{Translation}->{'Add Catalog Class'} = 'Aggiungi Classe al Catalogo';
    $Self->{Translation}->{'Catalog Class'} = 'Classe di Catalogo';
    $Self->{Translation}->{'Edit Catalog Item'} = 'Modifica elemento di catalogo';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = 'Lo stato dell\'incidente di avviso non può essere impostato su non valido.';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = 'Commento 2';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'Crea e gestisci il Catalogo Generale';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = 'Definisci il commento 2 del catalogo generale';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = 'Specifica il percorso dell\'URL del selettore di colori JS.';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'Modulo di registrazione per la configurazione di AdminGeneralCatalog nell\'area di admin.';
    $Self->{Translation}->{'General Catalog'} = 'Catalogo Generale';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'Parametri per il commento di esempio 2 degli attributi del catalogo generale.';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'Parametri per i gruppi di permessi di esempio degli attributi del catalogo generale.';
    $Self->{Translation}->{'Permission Group'} = 'Gruppo di autorizzazioni';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
