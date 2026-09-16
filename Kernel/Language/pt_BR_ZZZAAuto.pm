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

package Kernel::Language::pt_BR_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Backup::Restore'} = 'Backup::Restaurar';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Armazenamento::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Armazenamento::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Armazenamento::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Rede::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Rede::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Rede::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Rede::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Armazenamento::Object Storage';
    $Self->{Translation}->{'Network::New'} = 'Rede::Nova';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Recurso::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Rede::DNS::Record Remove';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Armazenamento::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Armazenamento::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Armazenamento::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Recurso';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Rede::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Rede::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening'} = 'Rede::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Rede::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Rede::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Rede::Configuração do Sistema::Modify';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Rede::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Rede::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::DNS'} = 'Rede::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instalar';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Rede::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Armazenamento::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Rede::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Rede::Firewall Policy';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Rede::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Armazenamento::Platform::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Armazenamento::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Armazenamento::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Serviço::Remover';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Nova';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Rede::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::System Configuration'} = 'Rede::Configuração do Sistema';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Remover';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Armazenamento::Object Storage::Assist';
    $Self->{Translation}->{'Network::Zone'} = 'Rede::Zone';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Recurso::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Nova';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Rede::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Rede::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = 'Rede::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Rede::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Substituir';
    $Self->{Translation}->{'Network::Patch Management'} = 'Rede::Patch Management';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Configuração do Sistema::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Rede::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Address::New'} = 'Rede::Endereço::Nova';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Nova';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Armazenamento::Platform::Patch Management';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Rede::DNS::Assist';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Rede::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = 'Rede::Endereço';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Rede::Firewall Policy::Remover';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Armazenamento::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Rede::Firewall Policy::Emergency';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Remover';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Rede::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Rede::Load Balancer::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Armazenamento::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Adicionar';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Armazenamento::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Recurso::Disk Expansion';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Rede::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Remover';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Rede::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::Segment'} = 'Rede::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Rede::Segment::Nova';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Rede::Configuração do Sistema::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Serviço';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Rede::Configuração do Sistema::Baseline Update';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::Restaurar::Request';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Rede::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Rede::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Armazenamento::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Remover';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Remover';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Rede::Firewall Policy::Revisão';
    $Self->{Translation}->{'Storage::Platform'} = 'Armazenamento::Platform';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Configuração do Sistema::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Rede::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Rede::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Armazenamento::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Rede::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Rede::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Rede::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Armazenamento::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Rede::DNS::Rollback';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Rede::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Configuração do Sistema::Modify';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Serviço::Onboarding/Modify';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Configuração do Sistema';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Rede::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Address::Release'} = 'Rede::Endereço::Release';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Armazenamento::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Remover';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Backup::Restore',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::DNS::Record Remove',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Compute::Resource',
        'Network::System Hardening::Apply/Modify',
        'Network::Firmware Management',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Configuration::Modify',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::DNS',
        'Security::Certificate::Install',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Network::System Configuration',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::Zone',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Security::Certificate::Replace',
        'Network::Patch Management',
        'Compute::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::DNS::Assist',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Emergency',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Network::Load Balancer::Assist',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Platform::Firmware Upgrade',
        'Compute::Resource::Disk Expansion',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::Segment',
        'Network::Segment::New',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Network::System Configuration::Baseline Update',
        'Backup::Restore::Request',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Compute::System Configuration::Rollback',
        'Network::Device Lifecycle::New Device',
        'Network::Patch Management::Patch Rollback',
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
        'Backup::Service::Onboarding/Modify',
        'Compute::System Configuration',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Address::Release',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
    );

}

1;
