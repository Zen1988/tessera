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

package Kernel::Language::bg_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'Функционалност';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'Управление на основния каталог';
    $Self->{Translation}->{'Items in Class'} = 'Елементи в класа';
    $Self->{Translation}->{'Edit Item'} = 'Редактиране на елемент';
    $Self->{Translation}->{'Add Class'} = 'Добавяне на клас';
    $Self->{Translation}->{'Add Item'} = 'Добавете елемент';
    $Self->{Translation}->{'Include invalid items'} = '';
    $Self->{Translation}->{'Add Catalog Item'} = 'Добави елемент към каталога';
    $Self->{Translation}->{'Add Catalog Class'} = 'Добави клас в каталога';
    $Self->{Translation}->{'Catalog Class'} = 'Класове в каталога';
    $Self->{Translation}->{'Edit Catalog Item'} = 'Редактиране на елемент от каталога';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = 'Състоянието на инцидент с предупреждение не може да бъде зададено като невалидно.';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = 'Коментар 2';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'Създаване и поддръжка на Основния каталог.';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = 'Дефинирайте коментар 2 към общия каталог.';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = 'Определя пътя на URL JS Color Picker.';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'Регистрация на предния модул за конфигурацията на Администраторския Основен каталог в Административната част.';
    $Self->{Translation}->{'General Catalog'} = 'Основен каталог';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'Параметри на примерния коментар 2 на атрибутите на общия каталог.';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'Параметри за примерните разрешителни групи от атрибутите на общия каталог.';
    $Self->{Translation}->{'Permission Group'} = 'Група разрешения';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
