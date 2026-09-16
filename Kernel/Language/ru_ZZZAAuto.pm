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

package Kernel::Language::ru_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Хранение::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Хранение::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Хранение::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Сеть::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::Восстановление';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Сеть::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Хранение::Object Storage';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Сеть::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Сеть::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Сеть::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Сеть::Новое';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Ресурсы::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Сеть::Firmware Management';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Сеть::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Сеть::System Hardening';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Сеть::DNS::Record New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Хранение::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Хранение::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Хранение::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Сеть::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Ресурсы';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Установить';
    $Self->{Translation}->{'Network::DNS'} = 'Сеть::DNS';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Сеть::Настройка Системы::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Сеть::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Сеть::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Хранение::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Сеть::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Хранение::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Хранение::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Сеть::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Сеть::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Сеть::Device Lifecycle';
    $Self->{Translation}->{'Network::System Configuration'} = 'Сеть::Настройка Системы';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Сеть::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Новое';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Хранение::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Удалить';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Хранение::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Сервис::Удалить';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Ресурсы::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Новое';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Заменить';
    $Self->{Translation}->{'Network::Patch Management'} = 'Сеть::Patch Management';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Сеть::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Сеть::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Сеть::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Сеть::Connectivity';
    $Self->{Translation}->{'Network::Zone'} = 'Сеть::Zone';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Сеть::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Сеть::Адрес::Новое';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Новое';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Хранение::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address'} = 'Сеть::Адрес';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Сеть::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Сеть::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Настройка Системы::Baseline Update';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Сеть::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Удалить';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Сеть::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Сеть::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Хранение::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Сеть::Firewall Policy::Удалить';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Ресурсы::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Сеть::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Удалить';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Сеть::System Hardening::Rollback';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Хранение::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Добавить';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Хранение::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Сервис';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Сеть::Настройка Системы::Rollback';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::Восстановление::Request';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Сеть::Настройка Системы::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Сеть::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Сеть::Segment::Новое';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Сеть::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Сеть::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Хранение::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Сеть::Firewall Policy::Экспертиза';
    $Self->{Translation}->{'Storage::Platform'} = 'Хранение::Platform';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Сеть::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Сеть::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Настройка Системы::Rollback';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Удалить';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Удалить';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Сеть::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Сеть::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Хранение::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Сеть::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Сеть::Load Balancer::New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Хранение::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Сеть::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Хранение::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Удалить';
    $Self->{Translation}->{'Network::Address::Release'} = 'Сеть::Адрес::Release';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Настройка Системы';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Сервис::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Сеть::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Настройка Системы::Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Backup::Restore',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::DNS::Record Remove',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::Firmware Management',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::DNS::Record New/Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
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
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Security::Certificate::Replace',
        'Network::Patch Management',
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Zone',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Assist',
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Compute::Resource::Disk Expansion',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Backup::Restore::Request',
        'Network::System Configuration::Baseline Update',
        'Network::Segment',
        'Network::Segment::New',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Compute::System Configuration::Rollback',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Compute::System Configuration',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
    );

}

1;
