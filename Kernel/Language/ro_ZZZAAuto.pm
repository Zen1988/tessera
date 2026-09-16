# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Language::ro_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Firmware Management'} = 'Rețea::Firmware Management';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Rețea::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Rețea::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Rețea::System Hardening';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Rețea::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Resurse';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Rețea::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Rețea::Noi';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Resurse::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Rețea::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Rețea::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Rețea::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Rețea::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Resurse::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Noi';
    $Self->{Translation}->{'Network::Patch Management'} = 'Rețea::Patch Management';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Rețea::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Rețea::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = 'Rețea::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Rețea::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Zone'} = 'Rețea::Zone';
    $Self->{Translation}->{'Network::System Configuration'} = 'Rețea::System Configuration';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Rețea::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Noi';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Șterge';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Serviciu::Șterge';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Rețea::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Rețea::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Rețea::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Rețea::Device Lifecycle';
    $Self->{Translation}->{'Network::DNS'} = 'Rețea::DNS';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Rețea::System Configuration::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Rețea::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Rețea::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Serviciu';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Rețea::System Configuration::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Rețea::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Rețea::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Rețea::Segment::Noi';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Resurse::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Rețea::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Șterge';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Rețea::System Hardening::Rollback';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Adaugă';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Rețea::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Șterge';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Rețea::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Rețea::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Rețea::Firewall Policy::Șterge';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Rețea::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Rețea::Adresa::Noi';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Noi';
    $Self->{Translation}->{'Network::Address'} = 'Rețea::Adresa';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Rețea::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Rețea::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Rețea::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Șterge';
    $Self->{Translation}->{'Network::Address::Release'} = 'Rețea::Adresa::Release';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Serviciu::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Rețea::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Rețea::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Rețea::DNS::Rollback';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Rețea::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Rețea::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Rețea::Firewall Policy::Revizuire';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Rețea::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Rețea::Device Lifecycle::New Device';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Șterge';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Șterge';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Rețea::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Rețea::Routing/Switching';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Firmware Management',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Network::DNS::Record Remove',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::Load Balancer::Configuration Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Connectivity::Allowlist New/Modify',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Patch Management',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Zone',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Common Service::Trellix ePO::Remove',
        'Backup::Service::Remove',
        'Network::DNS::Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::DNS',
        'Network::System Configuration::Modify',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::Segment',
        'Network::Segment::New',
        'Compute::Resource::Disk Expansion',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Assist',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::Remove',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Network::Device Lifecycle::Device Replacement',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Network::Load Balancer::VIP New/Modify',
        'Network::DNS::Rollback',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Network::Firewall Policy::Review',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
    );

}

1;
