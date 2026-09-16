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

package Kernel::Language::da_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Opbevaring::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Tilføj';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Opbevaring::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Resurse::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Netværk::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Fjern';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Netværk::System Hardening::Rollback';
    $Self->{Translation}->{'Network::Segment'} = 'Netværk::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Netværk::Segment::Ny';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Netværk::Systemkonfiguration::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Netværk::Systemkonfiguration::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Netværk::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Systemkonfiguration::Baseline Update';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Netværk::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Ny';
    $Self->{Translation}->{'Network::Address::New'} = 'Netværk::Adresse::Ny';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Opbevaring::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address'} = 'Netværk::Adresse';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Netværk::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Netværk::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Opbevaring::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Netværk::Firewall Policy::Fjern';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Netværk::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Fjern';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Netværk::Load Balancer::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Opbevaring::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Netværk::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Opbevaring::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Netværk::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Netværk::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Netværk::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Systemkonfiguration';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Netværk::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Systemkonfiguration::Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Netværk::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Fjern';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Opbevaring::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Netværk::Adresse::Release';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Netværk::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Netværk::System Hardening::Remediation';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Opbevaring::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Fjern';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Fjern';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Netværk::Firewall Policy::Anmeldelse';
    $Self->{Translation}->{'Storage::Platform'} = 'Opbevaring::Platform';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Netværk::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Netværk::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Systemkonfiguration::Rollback';
    $Self->{Translation}->{'Network::New'} = 'Netværk::Ny';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Resurse::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Netværk::DNS::Record Remove';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Opbevaring::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Opbevaring::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Opbevaring::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Netværk::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Resurse';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Netværk::Firmware Management';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Netværk::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Netværk::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Netværk::System Hardening';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Opbevaring::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Opbevaring::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Opbevaring::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Netværk::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Netværk::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Netværk::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Netværk::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Opbevaring::Object Storage';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Opbevaring::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Service::Fjern';
    $Self->{Translation}->{'Network::System Configuration'} = 'Netværk::Systemkonfiguration';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Netværk::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Ny';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Opbevaring::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Fjern';
    $Self->{Translation}->{'Network::Zone'} = 'Netværk::Zone';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Ny';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Resurse::Assist';
    $Self->{Translation}->{'Network::Patch Management'} = 'Netværk::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Erstat';
    $Self->{Translation}->{'Network::Connectivity'} = 'Netværk::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Netværk::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Netværk::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Netværk::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Netværk::Systemkonfiguration::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Netværk::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Netværk::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Installation';
    $Self->{Translation}->{'Network::DNS'} = 'Netværk::DNS';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Opbevaring::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Netværk::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Netværk::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Netværk::Device Lifecycle';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Opbevaring::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Netværk::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Opbevaring::Object Storage::Lifecycle Policy New/Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Compute::Resource::Disk Expansion',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network::Segment',
        'Network::Segment::New',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Network::DNS::Assist',
        'Compute::Virtual Machine::New',
        'Network::Address::New',
        'Storage::Platform::Patch Management',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Assist',
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Compute::System Configuration',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
        'Network::Device Lifecycle::Device Replacement',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Storage::Platform::Hardening Apply/Modify',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Compute::System Configuration::Rollback',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::DNS::Record Remove',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Network::Firmware Management',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
        'Network::Zone',
        'Network::Firewall Policy::New',
        'Compute::Resource::Assist',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Network::System Configuration::Modify',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Security::Certificate::Install',
        'Network::DNS',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
    );

}

1;
