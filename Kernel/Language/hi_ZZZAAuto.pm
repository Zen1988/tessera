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

package Kernel::Language::hi_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::हटायें';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::जोड़ें';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::हटायें';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::सेवा::हटायें';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::नया';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::हटायें';
    $Self->{Translation}->{'Network::New'} = 'Network::नया';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::हटायें';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::हटायें';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::स्थापित';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::नया';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::हटायें';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::सेवा::Onboarding/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::नया';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Address::नया';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::सेवा';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::नया';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::हटायें';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Network::Firewall Policy::Remove',
        'Network Management::Network Security & Policy Management::Add',
        'Common Service::Red Hat Satellite::Remove',
        'Backup::Service::Remove',
        'Network::Segment::New',
        'Common Service::Trellix ePO::Remove',
        'Network::New',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Security::Certificate::Install',
        'Compute::Virtual Machine::New',
        'Common Service::Carbon Black::Remove',
        'Backup::Service::Onboarding/Modify',
        'Network::Firewall Policy::New',
        'Network::Address::New',
        'Backup::Service',
        'Network::Load Balancer::New',
        'Common Service::Monitoring::Remove',
    );

}

1;
