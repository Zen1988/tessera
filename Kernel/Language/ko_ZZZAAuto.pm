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

package Kernel::Language::ko_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = '네트워크::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = '스토리지::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = '스토리지::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = '스토리지::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = '네트워크::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = '스토리지::Object Storage';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = '네트워크::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = '네트워크::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = '네트워크::DNS::Record Remove';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::자원::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = '네트워크::새로운';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = '네트워크::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = '네트워크::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = '네트워크::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::Firmware Management'} = '네트워크::Firmware Management';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::자원';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = '네트워크::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = '스토리지::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = '스토리지::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = '스토리지::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Network::DNS'} = '네트워크::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::설치';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = '네트워크::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = '네트워크::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = '네트워크::시스템 설정::Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = '스토리지::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = '네트워크::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = '스토리지::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = '네트워크::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = '네트워크::Firewall Policy';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = '네트워크::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = '스토리지::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = '스토리지::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::삭제';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::새로운';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = '네트워크::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::System Configuration'} = '네트워크::시스템 설정';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::서비스::삭제';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = '스토리지::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = '네트워크::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = '네트워크::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = '네트워크::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = '네트워크::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::바꾸다';
    $Self->{Translation}->{'Network::Patch Management'} = '네트워크::Patch Management';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::자원::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::새로운';
    $Self->{Translation}->{'Network::Zone'} = '네트워크::Zone';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = '네트워크::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = '네트워크::주소';
    $Self->{Translation}->{'Network::Address::New'} = '네트워크::주소::새로운';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::새로운';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = '스토리지::Platform::Patch Management';
    $Self->{Translation}->{'Network::DNS::Assist'} = '네트워크::DNS::Assist';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::시스템 설정::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = '네트워크::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = '네트워크::Load Balancer::Assist';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::삭제';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = '네트워크::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = '네트워크::Firewall Policy::삭제';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = '스토리지::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = '네트워크::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = '네트워크::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::삭제';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = '네트워크::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::자원::Disk Expansion';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = '스토리지::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::추가';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = '스토리지::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = '네트워크::시스템 설정::Baseline Update';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = '네트워크::시스템 설정::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::서비스';
    $Self->{Translation}->{'Network::Segment::New'} = '네트워크::Segment::새로운';
    $Self->{Translation}->{'Network::Segment'} = '네트워크::Segment';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = '스토리지::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = '네트워크::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = '네트워크::System Hardening::Remediation';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::시스템 설정::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = '네트워크::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = '네트워크::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Storage::Platform'} = '스토리지::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = '네트워크::Firewall Policy::검토';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::삭제';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::삭제';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = '네트워크::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = '네트워크::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = '스토리지::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = '네트워크::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = '네트워크::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = '스토리지::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Address::Release'} = '네트워크::주소::Release';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = '스토리지::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::삭제';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = '네트워크::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = '네트워크::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::시스템 설정::Modify';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::서비스::Onboarding/Modify';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::시스템 설정';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::DNS::Record Remove',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::Firmware Management',
        'Compute::Resource',
        'Network::System Hardening::Apply/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Network::DNS',
        'Security::Certificate::Install',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::System Configuration::Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Network::System Configuration',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Security::Certificate::Replace',
        'Network::Patch Management',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Zone',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::DNS::Assist',
        'Compute::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
        'Network::Load Balancer::Assist',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Emergency',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Firmware Management::Firmware Upgrade',
        'Compute::Resource::Disk Expansion',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Platform::Firmware Upgrade',
        'Network::System Configuration::Baseline Update',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Network::Segment::New',
        'Network::Segment',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Compute::System Configuration::Rollback',
        'Network::Device Lifecycle::New Device',
        'Network::Patch Management::Patch Rollback',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Address::Release',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
        'Backup::Service::Onboarding/Modify',
        'Compute::System Configuration',
    );

}

1;
