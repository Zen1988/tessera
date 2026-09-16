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

package Kernel::Language::zh_CN_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = '存储::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = '存储::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::添加';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = '网络::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::移除';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = '网络::System Hardening::Rollback';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::资源::Disk Expansion';
    $Self->{Translation}->{'Network::Segment::New'} = '网络::Segment::New（新建）';
    $Self->{Translation}->{'Network::Segment'} = '网络::Segment';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::恢复::Request';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = '网络::系统配置::Baseline Update';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::服务';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = '网络::系统配置::Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = '网络::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::系统配置::Baseline Update';
    $Self->{Translation}->{'Network::Address'} = '网络::地址';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = '网络::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = '网络::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = '网络::地址::New（新建）';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::New（新建）';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = '存储::Platform::Patch Management';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = '网络::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = '存储::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = '网络::Firewall Policy::移除';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = '网络::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = '网络::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::移除';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = '存储::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = '存储::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = '网络::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = '网络::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = '网络::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = '网络::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::系统配置';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::服务::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = '网络::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::系统配置::Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::移除';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = '存储::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = '网络::地址::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = '网络::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = '存储::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = '网络::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = '网络::System Hardening::Remediation';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::移除';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::移除';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = '网络::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = '网络::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::系统配置::Rollback';
    $Self->{Translation}->{'Storage::Platform'} = '存储::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = '网络::Firewall Policy::复审';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::资源::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = '网络::New（新建）';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = '网络::DNS::Record Remove';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = '网络::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::资源';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = '存储::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = '存储::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = '存储::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = '网络::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = '网络::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = '网络::System Hardening';
    $Self->{Translation}->{'Network::Firmware Management'} = '网络::Firmware Management';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::恢复';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = '网络::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = '存储::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = '存储::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = '存储::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = '网络::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = '网络::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = '存储::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = '网络::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::服务::移除';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = '存储::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::移除';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = '存储::Object Storage::Assist';
    $Self->{Translation}->{'Network::System Configuration'} = '网络::系统配置';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = '网络::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::New（新建）';
    $Self->{Translation}->{'Network::Zone'} = '网络::Zone';
    $Self->{Translation}->{'Network::Patch Management'} = '网络::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::替换';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = '网络::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = '网络::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = '网络::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = '网络::Load Balancer';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::资源::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::New（新建）';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = '网络::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = '网络::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = '网络::系统配置::Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::安装';
    $Self->{Translation}->{'Network::DNS'} = '网络::DNS';
    $Self->{Translation}->{'Network::Firewall Policy'} = '网络::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = '网络::Device Lifecycle';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = '存储::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = '网络::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = '存储::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = '存储::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = '网络::DNS::Configuration Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Compute::Resource::Disk Expansion',
        'Network::Segment::New',
        'Network::Segment',
        'Backup::Restore::Request',
        'Network::System Configuration::Baseline Update',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Storage::Object Storage::Bucket Remove',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Compute::System Configuration',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Compute::System Configuration::Rollback',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::DNS::Record Remove',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::Firmware Management',
        'Backup::Restore',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Network::Zone',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::System Configuration::Modify',
        'Security::Certificate::Install',
        'Network::DNS',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
    );

}

1;
