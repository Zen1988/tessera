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

package Kernel::Language::ja_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Backup::Service'} = 'Backup::サービス';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'ネットワーク::システム設定::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'ネットワーク::システム設定::Baseline Update';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::リストア::Request';
    $Self->{Translation}->{'Network::Segment'} = 'ネットワーク::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'ネットワーク::Segment::新規';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::リソース::Disk Expansion';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::削除';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'ネットワーク::System Hardening::Rollback';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'ネットワーク::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'ストレージ::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::追加';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'ストレージ::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::削除';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'ネットワーク::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'ネットワーク::Load Balancer::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'ストレージ::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'ネットワーク::Firewall Policy::削除';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'ネットワーク::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Address::New'} = 'ネットワーク::アドレス::新規';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::新規';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'ストレージ::Platform::Patch Management';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'ネットワーク::DNS::Assist';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'ネットワーク::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = 'ネットワーク::アドレス';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::システム設定::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'ネットワーク::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'ネットワーク::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::削除';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'ストレージ::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'ネットワーク::アドレス::Release';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::サービス::Onboarding/Modify';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::システム設定::Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'ネットワーク::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::システム設定';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'ネットワーク::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'ストレージ::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'ネットワーク::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'ネットワーク::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'ネットワーク::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'ストレージ::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Storage::Platform'} = 'ストレージ::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'ネットワーク::Firewall Policy::レビュー';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'ネットワーク::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::システム設定::Rollback';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'ネットワーク::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::削除';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::削除';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'ネットワーク::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'ネットワーク::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'ストレージ::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'ネットワーク::Firmware Management';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'ネットワーク::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'ネットワーク::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'ネットワーク::System Hardening';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'ストレージ::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'ストレージ::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'ストレージ::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::リソース';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'ネットワーク::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'ネットワーク::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'ネットワーク::新規';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::リソース::Upgrade/Downgrade';
    $Self->{Translation}->{'Storage::Object Storage'} = 'ストレージ::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'ネットワーク::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'ネットワーク::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'ネットワーク::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'ストレージ::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'ストレージ::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'ストレージ::Object Storage::Rollback';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'ネットワーク::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::リストア';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::新規';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::リソース::Assist';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::置換';
    $Self->{Translation}->{'Network::Patch Management'} = 'ネットワーク::Patch Management';
    $Self->{Translation}->{'Network::Load Balancer'} = 'ネットワーク::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = 'ネットワーク::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'ネットワーク::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'ネットワーク::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Zone'} = 'ネットワーク::Zone';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'ネットワーク::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::新規';
    $Self->{Translation}->{'Network::System Configuration'} = 'ネットワーク::システム設定';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::削除';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'ストレージ::Object Storage::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'ストレージ::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::サービス::削除';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'ネットワーク::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'ストレージ::Platform::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'ストレージ::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'ネットワーク::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'ストレージ::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'ネットワーク::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'ネットワーク::Device Lifecycle';
    $Self->{Translation}->{'Network::DNS'} = 'ネットワーク::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::インストール';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'ネットワーク::システム設定::Modify';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'ネットワーク::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'ネットワーク::Connectivity::Proxy/URL Allowlist';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Backup::Restore::Request',
        'Network::Segment',
        'Network::Segment::New',
        'Compute::Resource::Disk Expansion',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network::Firmware Management::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Platform::Firmware Upgrade',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Network::Load Balancer::Assist',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::Emergency',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::DNS::Assist',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Compute::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
        'Network::Device Lifecycle::Device Replacement',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Backup::Service::Onboarding/Modify',
        'Compute::System Configuration::Modify',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Storage::Object Storage::Bucket Remove',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Device Lifecycle::New Device',
        'Compute::System Configuration::Rollback',
        'Network::Patch Management::Patch Rollback',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Firmware Management',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Compute::Resource',
        'Network::System Hardening::Apply/Modify',
        'Network::DNS::Record Remove',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Network::Connectivity::Allowlist New/Modify',
        'Backup::Restore',
        'Network::Firewall Policy::New',
        'Compute::Resource::Assist',
        'Security::Certificate::Replace',
        'Network::Patch Management',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Zone',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Network::System Configuration',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::DNS',
        'Security::Certificate::Install',
        'Network::System Configuration::Modify',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
    );

}

1;
