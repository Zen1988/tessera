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

package Kernel::Language::sk_SK_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Úložisko::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Sieť::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Sieť::System Hardening::Remediation';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Vymazať';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Vymazať';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Sieť::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Sieť::Device Lifecycle::New Device';
    $Self->{Translation}->{'Storage::Platform'} = 'Úložisko::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Sieť::Firewall Policy::Prehľad';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Úložisko::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Sieť::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Sieť::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Sieť::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Úložisko::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Sieť::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Sieť::Routing/Switching::Rollback';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Servis::Onboarding/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Sieť::Address::Release';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Úložisko::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Vymazať';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Sieť::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Sieť::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Address'} = 'Sieť::Address';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Sieť::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Sieť::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Sieť::Address::nov';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::nov';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Úložisko::Platform::Patch Management';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Sieť::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Sieť::Firewall Policy::Vymazať';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Úložisko::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Sieť::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Sieť::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Vymazať';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Úložisko::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Pridať ';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Úložisko::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Sieť::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Sieť::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Vymazať';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Zdroj::Disk Expansion';
    $Self->{Translation}->{'Network::Segment::New'} = 'Sieť::Segment::nov';
    $Self->{Translation}->{'Network::Segment'} = 'Sieť::Segment';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Sieť::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Sieť::System Configuration::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Servis';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Sieť::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Sieť::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Sieť::System Configuration::Modify';
    $Self->{Translation}->{'Network::DNS'} = 'Sieť::DNS';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Sieť::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Sieť::Firewall Policy';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Úložisko::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Sieť::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Úložisko::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Úložisko::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Sieť::DNS::Configuration Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Servis::Vymazať';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Úložisko::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Vymazať';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Úložisko::Object Storage::Assist';
    $Self->{Translation}->{'Network::System Configuration'} = 'Sieť::System Configuration';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::nov';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Sieť::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Zone'} = 'Sieť::Zone';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Sieť::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Sieť::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Sieť::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Sieť::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Sieť::Patch Management';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::nov';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Zdroj::Assist';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Sieť::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Úložisko::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Úložisko::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Úložisko::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Sieť::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Sieť::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Sieť::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Úložisko::Object Storage';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Zdroj::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Sieť::nov';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Sieť::DNS::Record Remove';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Sieť::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Zdroj';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Úložisko::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Úložisko::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Úložisko::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Sieť::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Sieť::System Hardening';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Sieť::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Sieť::Firmware Management';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Storage::Object Storage::Bucket Remove',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Routing/Switching::Rollback',
        'Backup::Service::Onboarding/Modify',
        'Network::Address::Release',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Patch Management::Scheduled Patch',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Compute::Resource::Disk Expansion',
        'Network::Segment::New',
        'Network::Segment',
        'Network::System Configuration::Baseline Update',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::System Configuration::Modify',
        'Network::DNS',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::System Configuration',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Network::Zone',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Patch Management',
        'Network::Firewall Policy::New',
        'Compute::Resource::Assist',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::DNS::Record Remove',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::DNS::Record New/Modify',
        'Network::Firmware Management',
    );

}

1;
