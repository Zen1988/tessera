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

package Kernel::Language::fa_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'کارکردی';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'مدیریت فهرست عمومی';
    $Self->{Translation}->{'Items in Class'} = '';
    $Self->{Translation}->{'Edit Item'} = '';
    $Self->{Translation}->{'Add Class'} = '';
    $Self->{Translation}->{'Add Item'} = '';
    $Self->{Translation}->{'Include invalid items'} = '';
    $Self->{Translation}->{'Add Catalog Item'} = 'اضافه کردن یک قلم فهرست';
    $Self->{Translation}->{'Add Catalog Class'} = 'اضافه کردن کلاس فهرستی';
    $Self->{Translation}->{'Catalog Class'} = 'فهرست کلاسی';
    $Self->{Translation}->{'Edit Catalog Item'} = '';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = '';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = '';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'ساخت و مدیریت فهرست عمومی';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = '';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = '';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'ثبت ماژول برای پیکربندی فهرست عمومی در بخش مدیریت';
    $Self->{Translation}->{'General Catalog'} = 'فهرست عمومی';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'پارامترهایی برای توضیح نمونه ۲ مربوط به ویژگی‌های فهرست عمومی';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'پارامترهایی برای گروه‌های دسترسی نمونه مربوط به ویژگی‌های فهرست عمومی';
    $Self->{Translation}->{'Permission Group'} = '';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
