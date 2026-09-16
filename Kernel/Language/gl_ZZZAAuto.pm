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

package Kernel::Language::gl_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Address::New'} = 'Network::Enderezo::Novo';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Servizo';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Novo';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Novo';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Retirar';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instalar';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Novo';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::Enderezo::Release';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Servizo::Onboarding/Modify';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Retirar';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Retirar';
    $Self->{Translation}->{'Network::New'} = 'Network::Novo';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Retirar';
    $Self->{Translation}->{'Network::Address'} = 'Network::Enderezo';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Engadir';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Retirar';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Novo';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Retirar';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Servizo::Retirar';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Retirar';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Network::Address::New',
        'Backup::Service',
        'Network::Firewall Policy::New',
        'Network::Load Balancer::New',
        'Common Service::Monitoring::Remove',
        'Security::Certificate::Install',
        'Compute::Virtual Machine::New',
        'Network::Address::Release',
        'Backup::Service::Onboarding/Modify',
        'Common Service::Carbon Black::Remove',
        'Common Service::WSUS::Remove',
        'Network::New',
        'Compute::Virtual Machine::Remove',
        'Network::Address',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firewall Policy::Remove',
        'Network::Segment::New',
        'Common Service::Red Hat Satellite::Remove',
        'Backup::Service::Remove',
        'Common Service::Trellix ePO::Remove',
    );

}

1;
