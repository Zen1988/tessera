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

package Kernel::Language::hr_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Backup::Service'} = 'Backup::Usluga';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Ukloni';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Address::Novi';
    $Self->{Translation}->{'Network::New'} = 'Network::Novi';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Novi';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Dodati';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Novi';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instaliraj';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Ukloni';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Novi';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Ukloni';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Novi';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Usluga::Ukloni';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Ukloni';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Usluga::Onboarding/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Ukloni';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Ukloni';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Ukloni';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Backup::Service',
        'Common Service::WSUS::Remove',
        'Network::Address::New',
        'Network::New',
        'Network::Firewall Policy::New',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Load Balancer::New',
        'Security::Certificate::Install',
        'Network::Firewall Policy::Remove',
        'Network::Segment::New',
        'Compute::Virtual Machine::Remove',
        'Compute::Virtual Machine::New',
        'Backup::Service::Remove',
        'Common Service::Red Hat Satellite::Remove',
        'Backup::Service::Onboarding/Modify',
        'Common Service::Monitoring::Remove',
        'Common Service::Trellix ePO::Remove',
        'Common Service::Carbon Black::Remove',
    );

}

1;
