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

package Kernel::Language::hu_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'Funkcionalitás';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'Általános katalógus kezelés';
    $Self->{Translation}->{'Items in Class'} = 'Elemek az osztályban';
    $Self->{Translation}->{'Edit Item'} = 'Elem szerkesztése';
    $Self->{Translation}->{'Add Class'} = 'Osztály hozzáadása';
    $Self->{Translation}->{'Add Item'} = 'Elem hozzáadása';
    $Self->{Translation}->{'Include invalid items'} = '';
    $Self->{Translation}->{'Add Catalog Item'} = 'Katalóguselem hozzáadása';
    $Self->{Translation}->{'Add Catalog Class'} = 'Katalógusosztály hozzáadása';
    $Self->{Translation}->{'Catalog Class'} = 'Katalógusosztály';
    $Self->{Translation}->{'Edit Catalog Item'} = 'Katalóguselem szerkesztése';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = 'A figyelmeztetés incidensállapotot nem lehet érvénytelenre állítani.';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = '2. megjegyzés';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'Az általános katalógus létrehozása és kezelése.';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = 'Meghatározza az általános katalógus 2. megjegyzését.';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = 'Meghatározza a JS színválasztó útvonalának URL-ét.';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'Előtétprogram modul regisztráció az adminisztrációs területen lévő általános katalógus beállításhoz.';
    $Self->{Translation}->{'General Catalog'} = 'Általános katalógus';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'Paraméterek az általános katalógus attribútumainak 2. példa megjegyzéseihez.';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'Paraméterek az általános katalógus attribútumainak példa jogosultság csoportjaihoz.';
    $Self->{Translation}->{'Permission Group'} = 'Jogosultsági csoport';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
