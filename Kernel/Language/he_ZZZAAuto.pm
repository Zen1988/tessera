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

package Kernel::Language::he_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::חדש';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::שירות::Onboarding/Modify';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::הסר';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::התקנה';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::הסר';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Address::חדש';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::שירות';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::חדש';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::חדש';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::חדש';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::הסר';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::שירות::הסר';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::הסר';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::הוסף';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::הסר';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::הסר';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::הסר';
    $Self->{Translation}->{'Network::New'} = 'Network::חדש';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Compute::Virtual Machine::New',
        'Backup::Service::Onboarding/Modify',
        'Common Service::Carbon Black::Remove',
        'Security::Certificate::Install',
        'Common Service::Monitoring::Remove',
        'Network::Address::New',
        'Backup::Service',
        'Network::Firewall Policy::New',
        'Network::Load Balancer::New',
        'Network::Segment::New',
        'Common Service::Red Hat Satellite::Remove',
        'Backup::Service::Remove',
        'Common Service::Trellix ePO::Remove',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firewall Policy::Remove',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::New',
    );

}

1;
