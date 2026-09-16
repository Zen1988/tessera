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

package Kernel::Language::mk_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Избриши';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Инсталирајте';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Додади';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Нов';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Network::Firewall Policy::Преглед';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Нов';
    $Self->{Translation}->{'Network::New'} = 'Network::Нов';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Услуга';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Избриши';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Адреса::Нов';
    $Self->{Translation}->{'Network::Address'} = 'Network::Адреса';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Избриши';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Избриши';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Избриши';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Услуга::Onboarding/Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Услуга::Избриши';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Избриши';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::Адреса::Release';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Нов';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Нов';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Избриши';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Network::Firewall Policy::Remove',
        'Security::Certificate::Install',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Load Balancer::New',
        'Network::Firewall Policy::Review',
        'Network::Firewall Policy::New',
        'Network::New',
        'Backup::Service',
        'Common Service::WSUS::Remove',
        'Network::Address::New',
        'Network::Address',
        'Common Service::Trellix ePO::Remove',
        'Common Service::Carbon Black::Remove',
        'Common Service::Monitoring::Remove',
        'Backup::Service::Onboarding/Modify',
        'Backup::Service::Remove',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Address::Release',
        'Compute::Virtual Machine::New',
        'Network::Segment::New',
        'Compute::Virtual Machine::Remove',
    );

}

1;
