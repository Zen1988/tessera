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

package Kernel::Language::sr_Latn_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Resurs';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Novo';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Konfiguracija sistema';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Ukloni';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Usluga::Ukloni';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Network::Konfiguracija sistema::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Konfiguracija sistema::Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Ukloni';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Network::Konfiguracija sistema::Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Dodati';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Ukloni';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Ukloni';
    $Self->{Translation}->{'Network::Address'} = 'Network::Adresa';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Resurs::Assist';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Zameni';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Ukloni';
    $Self->{Translation}->{'Network::New'} = 'Network::Novo';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Konfiguracija sistema::Baseline Update';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Resurs::Disk Expansion';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Novo';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::Adresa::Release';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Usluga::Onboarding/Modify';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Ukloni';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Konfiguracija sistema::Rollback';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instaliraj';
    $Self->{Translation}->{'Network::System Configuration'} = 'Network::Konfiguracija sistema';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Network::Konfiguracija sistema::Baseline Update';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Resurs::Upgrade/Downgrade';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Ukloni';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Adresa::Novo';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Usluga';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Novo';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Novo';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Compute::Resource',
        'Network::Segment::New',
        'Compute::System Configuration',
        'Common Service::Red Hat Satellite::Remove',
        'Backup::Service::Remove',
        'Network::System Configuration::Rollback',
        'Compute::System Configuration::Modify',
        'Common Service::Trellix ePO::Remove',
        'Network::System Configuration::Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firewall Policy::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::Address',
        'Compute::Resource::Assist',
        'Security::Certificate::Replace',
        'Common Service::WSUS::Remove',
        'Network::New',
        'Compute::System Configuration::Baseline Update',
        'Compute::Resource::Disk Expansion',
        'Compute::Virtual Machine::New',
        'Network::Address::Release',
        'Backup::Service::Onboarding/Modify',
        'Common Service::Carbon Black::Remove',
        'Compute::System Configuration::Rollback',
        'Security::Certificate::Install',
        'Network::System Configuration',
        'Network::System Configuration::Baseline Update',
        'Compute::Resource::Upgrade/Downgrade',
        'Common Service::Monitoring::Remove',
        'Network::Address::New',
        'Backup::Service',
        'Network::Firewall Policy::New',
        'Network::Load Balancer::New',
    );

}

1;
