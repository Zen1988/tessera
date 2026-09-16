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

package Kernel::Language::fr_CA_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Réseau::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Réseau::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Réseau::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Stockage::Object Storage';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Stockage::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Stockage::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Stockage::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Réseau::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Stockage::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Stockage::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Stockage::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Réseau::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Réseau::Firmware Management';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Réseau::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Réseau::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Réseau::System Hardening';
    $Self->{Translation}->{'Network::New'} = 'Réseau::Nouvelle';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Réseau::DNS::Record Remove';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Réseau::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Stockage::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Réseau::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Réseau::Firewall Policy';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Réseau::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Stockage::Platform::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Stockage::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Réseau::System Configuration::Modify';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Réseau::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Réseau::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::DNS'} = 'Réseau::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Installer';
    $Self->{Translation}->{'Network::Zone'} = 'Réseau::Zone';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nouvelle';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Réseau::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Réseau::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Réseau::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Réseau::Connectivity';
    $Self->{Translation}->{'Network::Patch Management'} = 'Réseau::Patch Management';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Stockage::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Service ::Supprimer';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nouvelle';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Réseau::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::System Configuration'} = 'Réseau::System Configuration';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Stockage::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Supprimer';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Réseau::Firewall Policy::Supprimer';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Stockage::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Réseau::Firewall Policy::Emergency';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Supprimer';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Réseau::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Réseau::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Réseau::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Stockage::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address::New'} = 'Réseau::Address::Nouvelle';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nouvelle';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Réseau::DNS::Assist';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Réseau::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = 'Réseau::Address';
    $Self->{Translation}->{'Network::Segment'} = 'Réseau::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Réseau::Segment::Nouvelle';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Réseau::System Configuration::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Service ';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Réseau::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Ajouter ';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Stockage::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Stockage::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Réseau::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Supprimer';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Réseau::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Supprimer';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Supprimer';
    $Self->{Translation}->{'Storage::Platform'} = 'Stockage::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Réseau::Firewall Policy::Révision';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Réseau::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Réseau::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Réseau::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Réseau::System Hardening::Remediation';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Stockage::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Réseau::Routing/Switching::Rollback';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Service ::Onboarding/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Réseau::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Address::Release'} = 'Réseau::Address::Release';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Supprimer';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Stockage::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Stockage::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Réseau::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Réseau::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Réseau::Load Balancer::New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Stockage::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Réseau::DNS::Rollback';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Network::System Hardening::Apply/Modify',
        'Network::Firmware Management',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::New',
        'Network::DNS::Record Remove',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Network::System Configuration::Modify',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::DNS',
        'Security::Certificate::Install',
        'Network::Zone',
        'Network::Firewall Policy::New',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Connectivity',
        'Network::Patch Management',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Network::System Configuration',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Emergency',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Network::Load Balancer::Assist',
        'Network::Patch Management::Scheduled Patch',
        'Storage::Platform::Patch Management',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Network::DNS::Assist',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Network::Segment',
        'Network::Segment::New',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Network::System Configuration::Baseline Update',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Storage::Platform::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Device Lifecycle::New Device',
        'Network::Patch Management::Patch Rollback',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Routing/Switching::Rollback',
        'Backup::Service::Onboarding/Modify',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Address::Release',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
    );

}

1;
