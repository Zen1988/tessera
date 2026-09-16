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

package Kernel::Language::pt_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Armazenamento::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Apagar';
    $Self->{Translation}->{'Network::Address::Release'} = 'Rede::Endereço::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Rede::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Configuração do Sistema';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Serviço::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Rede::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Configuração do Sistema::Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Armazenamento::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Rede::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Rede::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Rede::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Rede::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Armazenamento::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Rede::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Rede::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Configuração do Sistema::Rollback';
    $Self->{Translation}->{'Storage::Platform'} = 'Armazenamento::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Rede::Firewall Policy::Revisão';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Apagar';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Apagar';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Armazenamento::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Rede::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Rede::Routing/Switching';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Rede::Configuração do Sistema::Baseline Update';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Serviço';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Rede::Configuração do Sistema::Rollback';
    $Self->{Translation}->{'Network::Segment::New'} = 'Rede::Segment::Novo';
    $Self->{Translation}->{'Network::Segment'} = 'Rede::Segment';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Rede::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Apagar';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Rede::System Hardening::Rollback';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Recurso::Disk Expansion';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Armazenamento::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Armazenamento::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Adicionar';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Rede::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Rede::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Apagar';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Rede::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Armazenamento::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Rede::Firewall Policy::Apagar';
    $Self->{Translation}->{'Network::Address'} = 'Rede::Endereço';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Rede::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Rede::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Rede::Endereço::Novo';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Armazenamento::Platform::Patch Management';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Novo';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Rede::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Configuração do Sistema::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management'} = 'Rede::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Substituir';
    $Self->{Translation}->{'Network::Connectivity'} = 'Rede::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Rede::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Rede::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Rede::Load Balancer';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Recurso::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Novo';
    $Self->{Translation}->{'Network::Zone'} = 'Rede::Zone';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Armazenamento::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Apagar';
    $Self->{Translation}->{'Network::System Configuration'} = 'Rede::Configuração do Sistema';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Rede::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Novo';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Serviço::Apagar';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Armazenamento::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Armazenamento::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Armazenamento::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Rede::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Rede::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Rede::Device Lifecycle';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Armazenamento::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Rede::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instalar';
    $Self->{Translation}->{'Network::DNS'} = 'Rede::DNS';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Rede::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Rede::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Rede::Configuração do Sistema::Modify';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Rede::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Rede::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Rede::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Rede::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Rede::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Recurso';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Armazenamento::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Armazenamento::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Armazenamento::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Rede::DNS::Record Remove';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Recurso::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Rede::Novo';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Rede::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Armazenamento::Object Storage';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Rede::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Rede::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Rede::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Armazenamento::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Armazenamento::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Armazenamento::Object Storage::Quota New/Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Compute::System Configuration',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Compute::System Configuration::Rollback',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Network::System Configuration::Baseline Update',
        'Backup::Service',
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
        'Network::Address::New',
        'Storage::Platform::Patch Management',
        'Compute::Virtual Machine::New',
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Connectivity',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Zone',
        'Storage::Object Storage::Assist',
        'Common Service::Trellix ePO::Remove',
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
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::Firmware Management',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::DNS::Record Remove',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
    );

}

1;
