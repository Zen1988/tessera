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

package Kernel::Language::nl_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Netwerk::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Netwerk::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Netwerk::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Netwerk::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Opslag::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Opslag::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Netwerk::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Address::Release'} = 'Netwerk::Adres::Release';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Verwijderen';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Opslag::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Systeemconfiguratie';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Systeemconfiguratie::Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Netwerk::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Netwerk::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Netwerk::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Opslag::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Storage::Platform'} = 'Opslag::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Netwerk::Firewall Policy::Review';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Netwerk::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Systeemconfiguratie::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Netwerk::Device Lifecycle::New Device';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Verwijderen';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Verwijderen';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Middel::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Netwerk::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Netwerk::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Verwijderen';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Opslag::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Opslag::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Toevoegen';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Netwerk::Systeemconfiguratie::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Netwerk::Systeemconfiguratie::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Netwerk::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Netwerk::Segment::Nieuw';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Netwerk::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Netwerk::Adres::Nieuw';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Opslag::Platform::Patch Management';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nieuw';
    $Self->{Translation}->{'Network::Address'} = 'Netwerk::Adres';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Netwerk::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Netwerk::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Systeemconfiguratie::Baseline Update';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Netwerk::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Verwijderen';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Netwerk::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Netwerk::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Netwerk::Firewall Policy::Verwijderen';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Opslag::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::System Configuration'} = 'Netwerk::Systeemconfiguratie';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nieuw';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Netwerk::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Verwijderen';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Opslag::Object Storage::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Opslag::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Service::Verwijderen';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nieuw';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Middel::Assist';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Netwerk::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = 'Netwerk::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Netwerk::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Netwerk::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Netwerk::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Vervang';
    $Self->{Translation}->{'Network::Zone'} = 'Netwerk::Zone';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Installeer';
    $Self->{Translation}->{'Network::DNS'} = 'Netwerk::DNS';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Netwerk::Systeemconfiguratie::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Netwerk::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Netwerk::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Opslag::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Netwerk::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Opslag::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Opslag::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Netwerk::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Netwerk::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Netwerk::Firewall Policy';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Netwerk::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Netwerk::Nieuw';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Middel::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Netwerk::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening'} = 'Netwerk::System Hardening';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Netwerk::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Netwerk::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Opslag::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Opslag::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Opslag::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Netwerk::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Middel';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Opslag::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Opslag::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Opslag::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Netwerk::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Opslag::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Netwerk::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Netwerk::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Netwerk::Device Lifecycle::Decommission';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Load Balancer::VIP New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Address::Release',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Compute::System Configuration',
        'Compute::System Configuration::Modify',
        'Network::Routing/Switching::Rollback',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Patch Management::Patch Rollback',
        'Compute::System Configuration::Rollback',
        'Network::Device Lifecycle::New Device',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Compute::Resource::Disk Expansion',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::Segment',
        'Network::Segment::New',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Storage::Platform::Patch Management',
        'Compute::Virtual Machine::New',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Assist',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::System Configuration',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::Firewall Policy::New',
        'Compute::Resource::Assist',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Zone',
        'Security::Certificate::Install',
        'Network::DNS',
        'Network::System Configuration::Modify',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Network::DNS::Record Remove',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::Firmware Management',
        'Network::System Hardening',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
    );

}

1;
