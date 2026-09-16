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

package Kernel::Language::cs_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Síť::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Úložiště::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Síť::Firewall Policy::Odstranit';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Síť::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Síť::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Odstranit';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Síť::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Address'} = 'Síť::Adresa';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Síť::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Síť::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Síť::Adresa::Nové';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nové';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Úložiště::Platform::Patch Management';
    $Self->{Translation}->{'Network::Segment::New'} = 'Síť::Segment::Nové';
    $Self->{Translation}->{'Network::Segment'} = 'Síť::Segment';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Síť::System Configuration::Baseline Update';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Služba';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Síť::System Configuration::Rollback';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Úložiště::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Úložiště::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Přidat';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Síť::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Odstranit';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Síť::System Hardening::Rollback';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Zdroj::Disk Expansion';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Odstranit';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Odstranit';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Síť::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Síť::Device Lifecycle::New Device';
    $Self->{Translation}->{'Storage::Platform'} = 'Úložiště::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Síť::Firewall Policy::Přehled';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Úložiště::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Síť::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Síť::Routing/Switching';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Služba::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Síť::Routing/Switching::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Úložiště::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Odstranit';
    $Self->{Translation}->{'Network::Address::Release'} = 'Síť::Adresa::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Síť::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Úložiště::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Úložiště::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Síť::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Síť::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Síť::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Síť::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Síť::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Síť::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Úložiště::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Síť::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Síť::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Úložiště::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Úložiště::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Úložiště::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Síť::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Zdroj';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Úložiště::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Úložiště::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Úložiště::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Síť::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Síť::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Síť::System Hardening';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Síť::Firmware Management';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Zdroj::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Síť::Nové';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Síť::DNS::Record Remove';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Síť::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Síť::Device Lifecycle';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Úložiště::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Síť::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Úložiště::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Úložiště::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Síť::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Síť::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Síť::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Síť::System Configuration::Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instalovat';
    $Self->{Translation}->{'Network::DNS'} = 'Síť::DNS';
    $Self->{Translation}->{'Network::Zone'} = 'Síť::Zone';
    $Self->{Translation}->{'Network::Patch Management'} = 'Síť::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Nahradit';
    $Self->{Translation}->{'Network::Connectivity'} = 'Síť::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Síť::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Síť::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Síť::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Zdroj::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nové';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Služba::Odstranit';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Úložiště::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Úložiště::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Odstranit';
    $Self->{Translation}->{'Network::System Configuration'} = 'Síť::System Configuration';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Síť::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nové';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Patch Management::Scheduled Patch',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Segment::New',
        'Network::Segment',
        'Network::System Configuration::Baseline Update',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Compute::Resource::Disk Expansion',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Storage::Object Storage::Bucket Remove',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::Firmware Management',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::DNS::Record Remove',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::System Configuration::Modify',
        'Security::Certificate::Install',
        'Network::DNS',
        'Network::Zone',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
    );

}

1;
