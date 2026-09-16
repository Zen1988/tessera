# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2023 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::Language::th_TH_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::การบริการ::Onboarding/Modify';
    $Self->{Translation}->{'Network::Address'} = 'Network::ที่อยู่';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::ลบ';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::ลบ';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::ลบ';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::ใหม่';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::ใหม่';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::ลบ';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::การบริการ::ลบ';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::ลบ';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::ที่อยู่::Release';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::เพิ่ม';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::ใหม่';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::ลบ';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::ติดตั้ง';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::การบริการ';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::ลบ';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::ที่อยู่::ใหม่';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Network::Firewall Policy::ตัวอย่าง';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::ใหม่';
    $Self->{Translation}->{'Network::New'} = 'Network::ใหม่';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Backup::Service::Onboarding/Modify',
        'Network::Address',
        'Common Service::Trellix ePO::Remove',
        'Common Service::Carbon Black::Remove',
        'Common Service::Monitoring::Remove',
        'Compute::Virtual Machine::New',
        'Network::Segment::New',
        'Compute::Virtual Machine::Remove',
        'Backup::Service::Remove',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Address::Release',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Load Balancer::New',
        'Network::Firewall Policy::Remove',
        'Security::Certificate::Install',
        'Backup::Service',
        'Common Service::WSUS::Remove',
        'Network::Address::New',
        'Network::Firewall Policy::Review',
        'Network::Firewall Policy::New',
        'Network::New',
    );

}

1;
