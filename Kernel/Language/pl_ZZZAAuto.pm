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

package Kernel::Language::pl_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instaluj';
    $Self->{Translation}->{'Network::DNS'} = 'Sieć::DNS';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Sieć::Konfiguracja Systemu::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Sieć::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Sieć::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Przechowywanie::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Sieć::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Przechowywanie::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Przechowywanie::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Sieć::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Sieć::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Sieć::Device Lifecycle';
    $Self->{Translation}->{'Network::System Configuration'} = 'Sieć::Konfiguracja Systemu';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Sieć::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nowe';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Usuń';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Przechowywanie::Object Storage::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Przechowywanie::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Usługa::Usuń';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Zasoby::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nowe';
    $Self->{Translation}->{'Network::Patch Management'} = 'Sieć::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Zamień';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Sieć::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Sieć::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Sieć::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Sieć::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Zone'} = 'Sieć::Zone';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Przechowywanie::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Przechowywanie::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Przechowywanie::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Sieć::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::Przywróć';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Przechowywanie::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Sieć::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Sieć::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Sieć::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Sieć::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Sieć::Nowe';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Zasoby::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Sieć::Firmware Management';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Sieć::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Sieć::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Sieć::System Hardening';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Przechowywanie::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Przechowywanie::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Przechowywanie::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Sieć::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Zasoby';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Sieć::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Sieć::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Przechowywanie::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Sieć::Firewall Policy::Przegląd';
    $Self->{Translation}->{'Storage::Platform'} = 'Przechowywanie::Platform';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Sieć::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Sieć::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Konfiguracja Systemu::Rollback';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Usuń';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Usuń';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Sieć::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Przechowywanie::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Sieć::DNS::Rollback';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Sieć::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Sieć::Load Balancer::New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Przechowywanie::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Sieć::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Przechowywanie::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Usuń';
    $Self->{Translation}->{'Network::Address::Release'} = 'Sieć::Adres::Release';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Konfiguracja Systemu';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Usługa::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Sieć::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Konfiguracja Systemu::Modify';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Sieć::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nowe';
    $Self->{Translation}->{'Network::Address::New'} = 'Sieć::Adres::Nowe';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Przechowywanie::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address'} = 'Sieć::Adres';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Sieć::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Sieć::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Konfiguracja Systemu::Baseline Update';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Sieć::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Usuń';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Sieć::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Sieć::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Przechowywanie::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Sieć::Firewall Policy::Usuń';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Zasoby::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Sieć::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Usuń';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Sieć::System Hardening::Rollback';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Przechowywanie::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Przechowywanie::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Dodaj';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Usługa';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Sieć::Konfiguracja Systemu::Rollback';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::Przywróć::Request';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Sieć::Konfiguracja Systemu::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Sieć::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Sieć::Segment::Nowe';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
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
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Zone',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Backup::Restore',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::DNS::Record Remove',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::Firmware Management',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
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
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
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
        'Network::DNS::Assist',
        'Compute::Virtual Machine::New',
        'Network::Address::New',
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
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Backup::Restore::Request',
        'Network::System Configuration::Baseline Update',
        'Network::Segment',
        'Network::Segment::New',
    );

}

1;
