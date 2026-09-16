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

package Kernel::Language::sr_Cyrl_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Уклони';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Услуга::Onboarding/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::Адреса::Release';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Ново';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Инсталирај';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Конфигурација система::Rollback';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Уклони';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Ресурс::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::System Configuration'} = 'Network::Конфигурација система';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Network::Конфигурација система::Baseline Update';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Ново';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Ново';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Услуга';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Адреса::Ново';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Network::Конфигурација система::Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Уклони';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Конфигурација система::Modify';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Network::Конфигурација система::Rollback';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Услуга::Уклони';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Уклони';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Конфигурација система';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Ново';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Ресурс';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Уклони';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Додати';
    $Self->{Translation}->{'Network::Address'} = 'Network::Адреса';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Уклони';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Ресурс::Disk Expansion';
    $Self->{Translation}->{'Network::New'} = 'Network::Ново';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Конфигурација система::Baseline Update';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Замени';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Уклони';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Ресурс::Assist';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Common Service::Carbon Black::Remove',
        'Backup::Service::Onboarding/Modify',
        'Network::Address::Release',
        'Compute::Virtual Machine::New',
        'Security::Certificate::Install',
        'Compute::System Configuration::Rollback',
        'Common Service::Monitoring::Remove',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::System Configuration',
        'Network::System Configuration::Baseline Update',
        'Network::Load Balancer::New',
        'Network::Firewall Policy::New',
        'Backup::Service',
        'Network::Address::New',
        'Network::System Configuration::Modify',
        'Common Service::Trellix ePO::Remove',
        'Compute::System Configuration::Modify',
        'Network::System Configuration::Rollback',
        'Backup::Service::Remove',
        'Common Service::Red Hat Satellite::Remove',
        'Compute::System Configuration',
        'Network::Segment::New',
        'Compute::Resource',
        'Network::Firewall Policy::Remove',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Address',
        'Compute::Virtual Machine::Remove',
        'Compute::Resource::Disk Expansion',
        'Network::New',
        'Compute::System Configuration::Baseline Update',
        'Security::Certificate::Replace',
        'Common Service::WSUS::Remove',
        'Compute::Resource::Assist',
    );

}

1;
