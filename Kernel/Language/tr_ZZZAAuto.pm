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

package Kernel::Language::tr_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Şebeke::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Şebeke::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Şebeke::Firewall Policy::İnceleme';
    $Self->{Translation}->{'Storage::Platform'} = 'Depolama::Platform';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Kaldır';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Kaldır';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Depolama::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Şebeke::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Şebeke::Routing/Switching';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Kaldır';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Depolama::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Şebeke::Address::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Şebeke::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Servis::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Şebeke::Routing/Switching::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Depolama::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Şebeke::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Şebeke::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Şebeke::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Şebeke::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Depolama::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Şebeke::Load Balancer::Assist';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Kaldır';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Şebeke::Load Balancer::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Depolama::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Şebeke::Firewall Policy::Kaldır';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Şebeke::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Şebeke::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = 'Şebeke::Address';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Depolama::Platform::Patch Management';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Yeni';
    $Self->{Translation}->{'Network::Address::New'} = 'Şebeke::Address::Yeni';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Şebeke::DNS::Assist';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Şebeke::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Şebeke::System Configuration::Baseline Update';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Servis';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Şebeke::System Configuration::Rollback';
    $Self->{Translation}->{'Network::Segment::New'} = 'Şebeke::Segment::Yeni';
    $Self->{Translation}->{'Network::Segment'} = 'Şebeke::Segment';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Kaldır';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Şebeke::System Hardening::Rollback';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Şebeke::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Kaynak::Disk Expansion';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Depolama::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Ekle';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Depolama::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Depolama::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Şebeke::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Depolama::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Şebeke::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Şebeke::Device Lifecycle';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Şebeke::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Depolama::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::DNS'} = 'Şebeke::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Yükle';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Şebeke::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Şebeke::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Şebeke::System Configuration::Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Şebeke::Patch Management';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Şebeke::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Şebeke::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Şebeke::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Şebeke::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Kaynak::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Yeni';
    $Self->{Translation}->{'Network::Zone'} = 'Şebeke::Zone';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Kaldır';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Depolama::Object Storage::Assist';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Şebeke::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Yeni';
    $Self->{Translation}->{'Network::System Configuration'} = 'Şebeke::System Configuration';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Servis::Kaldır';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Depolama::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Depolama::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Şebeke::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Şebeke::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Şebeke::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Şebeke::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Depolama::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Depolama::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Depolama::Object Storage::Rollback';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Şebeke::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Şebeke::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Şebeke::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Şebeke::Firmware Management';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Kaynak';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Şebeke::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Depolama::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Depolama::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Depolama::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Şebeke::DNS::Record Remove';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Kaynak::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Şebeke::Yeni';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Device Lifecycle::New Device',
        'Network::Patch Management::Patch Rollback',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::Assist',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::Emergency',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Storage::Platform::Patch Management',
        'Compute::Virtual Machine::New',
        'Network::Address::New',
        'Network::DNS::Assist',
        'Network::Patch Management::Scheduled Patch',
        'Network::System Configuration::Baseline Update',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::Segment::New',
        'Network::Segment',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network::Firmware Management::Firmware Upgrade',
        'Compute::Resource::Disk Expansion',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::DNS',
        'Security::Certificate::Install',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::System Configuration::Modify',
        'Network::Patch Management',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Zone',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Network::System Configuration',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::Firmware Management',
        'Compute::Resource',
        'Network::System Hardening::Apply/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Network::DNS::Record Remove',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
    );

}

1;
