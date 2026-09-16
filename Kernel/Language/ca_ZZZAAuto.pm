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

package Kernel::Language::ca_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nou';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Afegir';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instal·lar';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Eliminar';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Eliminar';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Address::Nou';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Servei';
    $Self->{Translation}->{'Network::New'} = 'Network::Nou';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nou';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Servei::Onboarding/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Eliminar';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Eliminar';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Eliminar';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Eliminar';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Nou';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nou';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Eliminar';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Servei::Eliminar';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Network::Load Balancer::New',
        'Network Management::Network Security & Policy Management::Add',
        'Security::Certificate::Install',
        'Network::Firewall Policy::Remove',
        'Common Service::WSUS::Remove',
        'Network::Address::New',
        'Backup::Service',
        'Network::New',
        'Network::Firewall Policy::New',
        'Backup::Service::Onboarding/Modify',
        'Common Service::Monitoring::Remove',
        'Common Service::Carbon Black::Remove',
        'Common Service::Trellix ePO::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::Segment::New',
        'Compute::Virtual Machine::New',
        'Common Service::Red Hat Satellite::Remove',
        'Backup::Service::Remove',
    );

}

1;
