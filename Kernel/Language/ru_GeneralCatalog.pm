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

package Kernel::Language::ru_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'Функциональность';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'Управление Общим каталогом';
    $Self->{Translation}->{'Items in Class'} = 'Элемент в классе';
    $Self->{Translation}->{'Edit Item'} = 'Редактировать элемент';
    $Self->{Translation}->{'Add Class'} = 'Добавить класс';
    $Self->{Translation}->{'Add Item'} = 'Добавить элемент';
    $Self->{Translation}->{'Add Catalog Item'} = 'Добавление элемента каталога';
    $Self->{Translation}->{'Add Catalog Class'} = 'Добавление класса каталога';
    $Self->{Translation}->{'Catalog Class'} = 'Класс каталога';
    $Self->{Translation}->{'Edit Catalog Item'} = 'Правка элемента каталога';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = 'Предупреждение Состояние инцидента не может быть установлено на недействительное.';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = 'Комментарий 2';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'Создание и управление Общим каталогом';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = 'Определите комментарий 2 к общему каталогу.';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = 'Задает путь URL JS Color Picker.';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'Module registration для конфигурации AdminGeneralCatalog в панели администратора.';
    $Self->{Translation}->{'General Catalog'} = 'Общий каталог';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'Добавление дополнительного комментария к атрибутам Общего каталога';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'Параметры для примерных групповых прав для атрибутов Общего каталога';
    $Self->{Translation}->{'Permission Group'} = 'Группа разрешений';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
