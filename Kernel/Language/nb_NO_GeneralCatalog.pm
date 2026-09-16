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

package Kernel::Language::nb_NO_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'Funksjonalitet';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'Administrasjon av Generell Katalog';
    $Self->{Translation}->{'Items in Class'} = 'Oppføringer i klasse';
    $Self->{Translation}->{'Edit Item'} = 'Endre objekt';
    $Self->{Translation}->{'Add Class'} = 'Legg til klasse';
    $Self->{Translation}->{'Add Item'} = 'Legg til oppføring';
    $Self->{Translation}->{'Include invalid items'} = '';
    $Self->{Translation}->{'Add Catalog Item'} = 'Legg til katalogobjekt';
    $Self->{Translation}->{'Add Catalog Class'} = 'Legg til katalog-klasse';
    $Self->{Translation}->{'Catalog Class'} = 'Katalogklasse';
    $Self->{Translation}->{'Edit Catalog Item'} = 'Rediger katalogoppføring';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = 'Hendelsesstatus for advarsel kan ikke settes til ugyldig.';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = 'Kommentar 2';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'Opprett og administrér den generelle katalogen.';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = 'Definer generell kommentar 2 til katalogen.';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = 'Definerer URL for JS-fargevelger.';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'Forsidemodul-registrering for AdminGeneralCatalog-oppsett i admin-delen.';
    $Self->{Translation}->{'General Catalog'} = 'Generell Katalog';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'Parametre for eksempelkommentar 2 i attributtene for generell katalog.';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'Parametere for tilgangsgruppe-eksempel i attributtene for generell katalog.';
    $Self->{Translation}->{'Permission Group'} = 'Tillatelsesgruppe';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
