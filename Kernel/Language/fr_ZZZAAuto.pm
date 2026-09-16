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

package Kernel::Language::fr_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Remplacer';
    $Self->{Translation}->{'Network::Patch Management'} = 'Réseau::Patch Management';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Réseau::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Réseau::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Réseau::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Réseau::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Ressource::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nouveau';
    $Self->{Translation}->{'Network::Zone'} = 'Réseau::Zone';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Supprimer';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Stockage::Object Storage::Assist';
    $Self->{Translation}->{'Network::System Configuration'} = 'Réseau::Configuration système';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Réseau::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nouveau';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Service::Supprimer';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Stockage::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Stockage::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Stockage::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Réseau::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Réseau::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Réseau::Device Lifecycle';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Stockage::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Réseau::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Installation';
    $Self->{Translation}->{'Network::DNS'} = 'Réseau::DNS';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Réseau::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Réseau::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Réseau::Configuration système::Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Réseau::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Réseau::System Hardening';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Réseau::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Réseau::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Réseau::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Ressource';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Stockage::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Stockage::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Stockage::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Réseau::DNS::Record Remove';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Ressource::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Réseau::Nouveau';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Stockage::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Réseau::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Réseau::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Réseau::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Réseau::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Stockage::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Stockage::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Stockage::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Stockage::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Supprimer';
    $Self->{Translation}->{'Network::Address::Release'} = 'Réseau::Adresse::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Réseau::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Configuration système';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Configuration système::Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Réseau::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Réseau::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Stockage::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Réseau::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Réseau::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Réseau::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Stockage::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Réseau::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Réseau::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Configuration système::Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Réseau::Firewall Policy::Revue';
    $Self->{Translation}->{'Storage::Platform'} = 'Stockage::Platform';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Supprimer';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Supprimer';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Stockage::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Réseau::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Réseau::Routing/Switching';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Réseau::Configuration système::Baseline Update';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Réseau::Configuration système::Rollback';
    $Self->{Translation}->{'Network::Segment::New'} = 'Réseau::Segment::Nouveau';
    $Self->{Translation}->{'Network::Segment'} = 'Réseau::Segment';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Réseau::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Supprimer';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Réseau::System Hardening::Rollback';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Ressource::Disk Expansion';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Stockage::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Stockage::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Ajouter';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Réseau::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Réseau::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Supprimer';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Réseau::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Stockage::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Réseau::Firewall Policy::Supprimer';
    $Self->{Translation}->{'Network::Address'} = 'Réseau::Adresse';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Réseau::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Réseau::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nouveau';
    $Self->{Translation}->{'Network::Address::New'} = 'Réseau::Adresse::Nouveau';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Stockage::Platform::Patch Management';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Réseau::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Configuration système::Baseline Update';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Security::Certificate::Replace',
        'Network::Patch Management',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Zone',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Security::Certificate::Install',
        'Network::DNS',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::System Configuration::Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Network::DNS::Record New/Modify',
        'Network::Firmware Management',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::DNS::Record Remove',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Compute::System Configuration',
        'Compute::System Configuration::Modify',
        'Network::Routing/Switching::Rollback',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Compute::System Configuration::Rollback',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Network::System Configuration::Baseline Update',
        'Network::System Configuration::Rollback',
        'Network::Segment::New',
        'Network::Segment',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Compute::Resource::Disk Expansion',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Compute::Virtual Machine::New',
        'Network::Address::New',
        'Storage::Platform::Patch Management',
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
    );

}

1;
