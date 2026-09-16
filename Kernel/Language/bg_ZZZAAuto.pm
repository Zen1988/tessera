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

package Kernel::Language::bg_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Съхранение::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Съхранение::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Съхранение::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Мрежа::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Съхранение::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Мрежа::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Мрежа::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Мрежа::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Мрежа::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Мрежа::Нови';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Ресурс::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Мрежа::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening'} = 'Мрежа::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Мрежа::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Мрежа::DNS::Record New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Съхранение::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Съхранение::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Съхранение::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Мрежа::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Ресурс';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Инсталиране';
    $Self->{Translation}->{'Network::DNS'} = 'Мрежа::DNS';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Мрежа::System Configuration::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Мрежа::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Мрежа::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Съхранение::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Мрежа::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Съхранение::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Съхранение::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Мрежа::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Мрежа::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Мрежа::Firewall Policy';
    $Self->{Translation}->{'Network::System Configuration'} = 'Мрежа::System Configuration';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Нови';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Мрежа::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Съхранение::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Премахване';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Съхранение::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Service::Премахване';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Ресурс::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Нови';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Мрежа::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Мрежа::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Мрежа::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Мрежа::Load Balancer';
    $Self->{Translation}->{'Network::Patch Management'} = 'Мрежа::Patch Management';
    $Self->{Translation}->{'Network::Zone'} = 'Мрежа::Zone';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Мрежа::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Мрежа::Address::Нови';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Нови';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Съхранение::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address'} = 'Мрежа::Address';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Мрежа::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Мрежа::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Мрежа::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Премахване';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Мрежа::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Мрежа::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Мрежа::Firewall Policy::Премахване';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Съхранение::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Ресурс::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Мрежа::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Мрежа::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Премахване';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Съхранение::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Съхранение::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Добавяне';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Мрежа::System Configuration::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Мрежа::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Мрежа::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Мрежа::Segment::Нови';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Мрежа::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Мрежа::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Съхранение::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Мрежа::Firewall Policy::Преглеждан';
    $Self->{Translation}->{'Storage::Platform'} = 'Съхранение::Platform';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Мрежа::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Мрежа::Device Lifecycle::New Device';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Премахване';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Премахване';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Мрежа::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Мрежа::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Мрежа::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Мрежа::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Съхранение::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Съхранение::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Мрежа::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Address::Release'} = 'Мрежа::Address::Release';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Премахване';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Съхранение::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Мрежа::Routing/Switching::Rollback';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::DNS::Record Remove',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::Firmware Management',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
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
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Network::System Configuration',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer',
        'Network::Patch Management',
        'Network::Zone',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Assist',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
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
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Address::Release',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Routing/Switching::Rollback',
    );

}

1;
