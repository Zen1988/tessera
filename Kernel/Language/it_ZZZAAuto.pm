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

package Kernel::Language::it_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Rete::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Configurazione di sistema::Baseline Update';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Rete::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nuovi';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Immagazzinamento::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address::New'} = 'Rete::Indirizzo::Nuovi';
    $Self->{Translation}->{'Network::Address'} = 'Rete::Indirizzo';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Rete::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Rete::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Rete::Firewall Policy::Rimuovi';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Immagazzinamento::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Rete::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Rimuovi';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Rete::Load Balancer::Assist';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Immagazzinamento::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Immagazzinamento::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Aggiungi';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Seguenti appuntamenti sono iniziati::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Rete::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Rete::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Rimuovi';
    $Self->{Translation}->{'Network::Segment'} = 'Rete::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Rete::Segment::Nuovi';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Rete::Configurazione di sistema::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Servizio';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Rete::Configurazione di sistema::Baseline Update';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Rete::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Rete::System Hardening::Remediation';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Immagazzinamento::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Rimuovi';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Rimuovi';
    $Self->{Translation}->{'Storage::Platform'} = 'Immagazzinamento::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Rete::Firewall Policy::Revisionato';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Rete::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Configurazione di sistema::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Rete::Device Lifecycle::New Device';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Immagazzinamento::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Rete::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Rete::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Rete::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Rete::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Immagazzinamento::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Configurazione di sistema';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Configurazione di sistema::Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Rete::Routing/Switching::Rollback';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Servizio::Onboarding/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Rete::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Address::Release'} = 'Rete::Indirizzo::Release';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Rimuovi';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Immagazzinamento::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Immagazzinamento::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Immagazzinamento::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Immagazzinamento::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Rete::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Rete::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Rete::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Rete::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Immagazzinamento::Object Storage';
    $Self->{Translation}->{'Network::New'} = 'Rete::Nuovi';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Seguenti appuntamenti sono iniziati::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Rete::DNS::Record Remove';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Immagazzinamento::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Immagazzinamento::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Immagazzinamento::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Rete::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Seguenti appuntamenti sono iniziati';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Rete::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening'} = 'Rete::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Rete::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Rete::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Rete::Configurazione di sistema::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Rete::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Rete::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Installa';
    $Self->{Translation}->{'Network::DNS'} = 'Rete::DNS';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Immagazzinamento::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Rete::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Rete::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Rete::Firewall Policy';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Immagazzinamento::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Rete::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Immagazzinamento::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Immagazzinamento::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Servizio::Rimuovi';
    $Self->{Translation}->{'Network::System Configuration'} = 'Rete::Configurazione di sistema';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nuovi';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Rete::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Rimuovi';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Immagazzinamento::Object Storage::Assist';
    $Self->{Translation}->{'Network::Zone'} = 'Rete::Zone';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Seguenti appuntamenti sono iniziati::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nuovi';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Rete::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = 'Rete::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Rete::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Rete::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Rete::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Sostituisci';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Network::DNS::Assist',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Address::New',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Assist',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Compute::Resource::Disk Expansion',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Segment',
        'Network::Segment::New',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Network::System Configuration::Baseline Update',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Storage::Platform::Hardening Apply/Modify',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Patch Management::Patch Rollback',
        'Compute::System Configuration::Rollback',
        'Network::Device Lifecycle::New Device',
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Compute::System Configuration',
        'Compute::System Configuration::Modify',
        'Network::Routing/Switching::Rollback',
        'Backup::Service::Onboarding/Modify',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Address::Release',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::DNS::Record Remove',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Network::Firmware Management',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Configuration::Modify',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Security::Certificate::Install',
        'Network::DNS',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::System Configuration',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::Zone',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Patch Management',
        'Security::Certificate::Replace',
    );

}

1;
