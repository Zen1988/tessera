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

package Kernel::Language::fa_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::نصب';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::خدمات::Onboarding/Modify';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::حذف کردن';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::جدید';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::نشانی::Release';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::جدید';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::خدمات';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::نشانی::جدید';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::جدید';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::حذف کردن';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::افزودن';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::حذف کردن';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Network::Firewall Policy::بازبینی';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::حذف کردن';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::جدید';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::خدمات::حذف کردن';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::حذف کردن';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::حذف کردن';
    $Self->{Translation}->{'Network::New'} = 'Network::جدید';
    $Self->{Translation}->{'Network::Address'} = 'Network::نشانی';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::حذف کردن';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Security::Certificate::Install',
        'Backup::Service::Onboarding/Modify',
        'Common Service::Carbon Black::Remove',
        'Compute::Virtual Machine::New',
        'Network::Address::Release',
        'Network::Load Balancer::New',
        'Backup::Service',
        'Network::Address::New',
        'Network::Firewall Policy::New',
        'Common Service::Monitoring::Remove',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::Review',
        'Common Service::Trellix ePO::Remove',
        'Network::Segment::New',
        'Backup::Service::Remove',
        'Common Service::Red Hat Satellite::Remove',
        'Common Service::WSUS::Remove',
        'Network::New',
        'Network::Address',
        'Compute::Virtual Machine::Remove',
    );

}

1;
