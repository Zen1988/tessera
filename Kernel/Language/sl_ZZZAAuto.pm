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

package Kernel::Language::sl_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Omrežje::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Shranjevanje::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Omrežje::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Omrežje::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Omrežje::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Shranjevanje::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Omrežje::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Odstrani';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Shranjevanje::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Omrežje::Address::Release';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Storitev::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Omrežje::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Omrežje::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Omrežje::System Hardening::Remediation';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Shranjevanje::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Omrežje::Firewall Policy::Pregled';
    $Self->{Translation}->{'Storage::Platform'} = 'Shranjevanje::Platform';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Omrežje::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Omrežje::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Odstrani';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Odstrani';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Odstrani';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Omrežje::System Hardening::Rollback';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Omrežje::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Shranjevanje::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Dodaj';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Shranjevanje::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Storitev';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Omrežje::System Configuration::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Omrežje::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Omrežje::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Omrežje::Segment::Novo';
    $Self->{Translation}->{'Network::Address::New'} = 'Omrežje::Address::Novo';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Novo';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Shranjevanje::Platform::Patch Management';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Omrežje::DNS::Assist';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Omrežje::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = 'Omrežje::Address';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Omrežje::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Odstrani';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Omrežje::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Omrežje::Load Balancer::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Shranjevanje::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Omrežje::Firewall Policy::Odstrani';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Omrežje::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Omrežje::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Novo';
    $Self->{Translation}->{'Network::System Configuration'} = 'Omrežje::System Configuration';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Shranjevanje::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Odstrani';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Shranjevanje::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Storitev::Odstrani';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Novo';
    $Self->{Translation}->{'Network::Patch Management'} = 'Omrežje::Patch Management';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Omrežje::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Omrežje::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Omrežje::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Omrežje::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Zone'} = 'Omrežje::Zone';
    $Self->{Translation}->{'Network::DNS'} = 'Omrežje::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Namestite';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Omrežje::System Configuration::Modify';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Omrežje::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Omrežje::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Omrežje::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Shranjevanje::Platform::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Shranjevanje::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Omrežje::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Shranjevanje::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Omrežje::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Omrežje::Device Lifecycle';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Omrežje::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Omrežje::Novo';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Omrežje::Firmware Management';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Omrežje::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Omrežje::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Omrežje::System Hardening';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Shranjevanje::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Shranjevanje::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Shranjevanje::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Omrežje::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Shranjevanje::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Shranjevanje::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Shranjevanje::Object Storage::Rollback';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Omrežje::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Shranjevanje::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Omrežje::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Omrežje::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Omrežje::Device Lifecycle::Decommission';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Storage::Object Storage::Bucket Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Network::Device Lifecycle::New Device',
        'Network::Patch Management::Patch Rollback',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network::Firmware Management::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Platform::Firmware Upgrade',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::Segment',
        'Network::Segment::New',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::DNS::Assist',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Network::Patch Management::Scheduled Patch',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Network::Load Balancer::Assist',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::Emergency',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Network::System Configuration',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::Firewall Policy::New',
        'Network::Patch Management',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Zone',
        'Network::DNS',
        'Security::Certificate::Install',
        'Network::System Configuration::Modify',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::DNS::Record Remove',
        'Network::New',
        'Network::Firmware Management',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Network::System Hardening::Apply/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
    );

}

1;
