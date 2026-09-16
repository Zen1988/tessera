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

package Kernel::Language::zh_TW_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::服務::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = '网络::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = '网络::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::刪除';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = '存储::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = '网络::地址::Release';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = '存储::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = '网络::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = '存储::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = '网络::DNS::Rollback';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = '网络::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = '网络::Load Balancer::New/Modify';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::刪除';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::刪除';
    $Self->{Translation}->{'Storage::Platform'} = '存储::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = '网络::Firewall Policy::複審';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = '网络::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = '网络::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = '网络::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = '网络::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = '存储::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Segment'} = '网络::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = '网络::Segment::新建';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::服務';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = '网络::System Configuration::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = '网络::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::添加';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = '存储::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = '存储::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::資源::Disk Expansion';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::刪除';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = '网络::System Hardening::Rollback';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = '网络::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = '存储::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = '网络::Firewall Policy::刪除';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = '网络::Firewall Policy::Emergency';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::刪除';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = '网络::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = '网络::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = '网络::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Address::New'} = '网络::地址::新建';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = '存储::Platform::Patch Management';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::新建';
    $Self->{Translation}->{'Network::DNS::Assist'} = '网络::DNS::Assist';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = '网络::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = '网络::地址';
    $Self->{Translation}->{'Network::Zone'} = '网络::Zone';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::新建';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::資源::Assist';
    $Self->{Translation}->{'Network::Patch Management'} = '网络::Patch Management';
    $Self->{Translation}->{'Network::Load Balancer'} = '网络::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = '网络::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = '网络::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = '网络::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = '存储::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::服務::刪除';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = '网络::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::新建';
    $Self->{Translation}->{'Network::System Configuration'} = '网络::System Configuration';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::刪除';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = '存储::Object Storage::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = '网络::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = '存储::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = '网络::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = '网络::Device Lifecycle';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = '网络::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = '存储::Platform::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = '存储::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = '网络::System Configuration::Modify';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = '网络::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = '网络::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::DNS'} = '网络::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::安裝';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = '存储::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = '存储::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = '存储::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::資源';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = '网络::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = '网络::Firmware Management';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = '网络::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = '网络::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = '网络::System Hardening';
    $Self->{Translation}->{'Network::New'} = '网络::新建';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::資源::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = '网络::DNS::Record Remove';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = '网络::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = '网络::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = '网络::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = '存储::Object Storage';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = '存储::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = '存储::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = '存储::Object Storage::Rollback';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = '网络::Connectivity::Allowlist New/Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Network::Device Lifecycle::Device Replacement',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Device Lifecycle::New Device',
        'Network::Patch Management::Patch Rollback',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Segment',
        'Network::Segment::New',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Storage::Platform::Firmware Upgrade',
        'Compute::Resource::Disk Expansion',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network::Firmware Management::Firmware Upgrade',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::Emergency',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Network::Load Balancer::Assist',
        'Network::Patch Management::Scheduled Patch',
        'Network::Address::New',
        'Storage::Platform::Patch Management',
        'Compute::Virtual Machine::New',
        'Network::DNS::Assist',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Network::Zone',
        'Network::Firewall Policy::New',
        'Compute::Resource::Assist',
        'Network::Patch Management',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Network::System Configuration',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Network::System Configuration::Modify',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::DNS',
        'Security::Certificate::Install',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Compute::Resource',
        'Network::System Hardening::Apply/Modify',
        'Network::Firmware Management',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::DNS::Record Remove',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Network::Connectivity::Allowlist New/Modify',
    );

}

1;
