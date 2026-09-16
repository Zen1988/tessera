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

package Kernel::Language::uk_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Зберігання::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Мережа::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Зберігання::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Мережа::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Мережа::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Мережа::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Сервіс::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Мережа::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Мережа::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Зберігання::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Вилучити';
    $Self->{Translation}->{'Network::Address::Release'} = 'Мережа::Адреса::Release';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Мережа::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Мережа::System Hardening::Remediation';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Зберігання::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Вилучити';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Вилучити';
    $Self->{Translation}->{'Storage::Platform'} = 'Зберігання::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Мережа::Firewall Policy::Огляд';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Мережа::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Мережа::Device Lifecycle::New Device';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Зберігання::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Додати';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Зберігання::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Ресурс::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Мережа::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Вилучити';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Мережа::System Hardening::Rollback';
    $Self->{Translation}->{'Network::Segment'} = 'Мережа::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Мережа::Segment::Новий';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Сервіс';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Мережа::System Configuration::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Мережа::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Мережа::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Мережа::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Новий';
    $Self->{Translation}->{'Network::Address::New'} = 'Мережа::Адреса::Новий';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Зберігання::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address'} = 'Мережа::Адреса';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Мережа::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Мережа::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Зберігання::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Мережа::Firewall Policy::Вилучити';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Мережа::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Вилучити';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Мережа::Load Balancer::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Зберігання::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Сервіс::Вилучити';
    $Self->{Translation}->{'Network::System Configuration'} = 'Мережа::System Configuration';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Мережа::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Новий';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Зберігання::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Вилучити';
    $Self->{Translation}->{'Network::Zone'} = 'Мережа::Zone';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Новий';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Ресурс::Assist';
    $Self->{Translation}->{'Network::Patch Management'} = 'Мережа::Patch Management';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Мережа::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Мережа::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = 'Мережа::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Мережа::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Мережа::System Configuration::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Мережа::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Мережа::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Установити';
    $Self->{Translation}->{'Network::DNS'} = 'Мережа::DNS';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Зберігання::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Мережа::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Мережа::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Мережа::Device Lifecycle';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Зберігання::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Мережа::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Зберігання::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::New'} = 'Мережа::Новий';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Ресурс::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Мережа::DNS::Record Remove';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Зберігання::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Зберігання::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Зберігання::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Мережа::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Ресурс';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Мережа::Firmware Management';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Мережа::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Мережа::System Hardening';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Мережа::DNS::Record New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Зберігання::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Зберігання::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Зберігання::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Мережа::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Мережа::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Мережа::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Мережа::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Зберігання::Object Storage';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Network::Device Lifecycle::Device Replacement',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Storage::Platform::Hardening Apply/Modify',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Compute::Resource::Disk Expansion',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network::Segment',
        'Network::Segment::New',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
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
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Load Balancer',
        'Network::Connectivity',
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
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::DNS::Record Remove',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Network::Firmware Management',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::DNS::Record New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
    );

}

1;
