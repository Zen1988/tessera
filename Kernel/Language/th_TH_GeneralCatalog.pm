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

package Kernel::Language::th_TH_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = 'ฟังก์ชั่นการทำงาน';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'การจัดการแค็ตตาล็อกทั่วไป';
    $Self->{Translation}->{'Items in Class'} = '';
    $Self->{Translation}->{'Edit Item'} = '';
    $Self->{Translation}->{'Add Class'} = '';
    $Self->{Translation}->{'Add Item'} = '';
    $Self->{Translation}->{'Include invalid items'} = '';
    $Self->{Translation}->{'Add Catalog Item'} = 'เพิ่มรายการแค็ตตาล็อก';
    $Self->{Translation}->{'Add Catalog Class'} = 'เพิ่มห้องแค็ตตาล็อก';
    $Self->{Translation}->{'Catalog Class'} = 'ห้องแค็ตตาล็อก';
    $Self->{Translation}->{'Edit Catalog Item'} = '';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = '';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = '';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'สร้างและจัดการแค็ตตาล็อกทั่วไป';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = '';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = '';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        'การลงทะเบียนโมดูล Frontend สำหรับการกำหนดค่าของ AdminGeneralCatalog ในพื้นที่ของแอดมิน';
    $Self->{Translation}->{'General Catalog'} = 'แค็ตตาล็อกทั่วไป';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'พารามิเตอร์สำหรับตัวอย่างความคิดเห็นที่2 ของแค็ตตาล็อกแอตทริบิวต์ทั่วไป';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'พารามิเตอร์สำหรับตัวอย่างกลุ่มที่ได้รับอนุญาตของแอตทริบิวต์แค็ตตาล็อกทั่วไป';
    $Self->{Translation}->{'Permission Group'} = '';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
