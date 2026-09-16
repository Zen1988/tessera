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

package Kernel::Language::de_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Segment::New'} = 'Netzwerk::Segment::Neu';
    $Self->{Translation}->{'Network::Segment'} = 'Netzwerk::Segment';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Netzwerk::Systemkonfiguration::Baseline Update';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::Wiederherstellen::Request';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Netzwerk::Systemkonfiguration::Rollback';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Hinzufügen';
    $Self->{Translation}->{'Security::Certificate::Revoke'} = 'Security::Certificate::Revoke';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Entfernen';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Netzwerk::System Hardening::Rollback';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Netzwerk::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Ressource::Disk Expansion';
    $Self->{Translation}->{'Security::Certificate'} = 'Security::Certificate';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Netzwerk::Firewall Policy::Entfernen';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Netzwerk::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Netzwerk::Load Balancer::Assist';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Entfernen';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Netzwerk::Load Balancer::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Systemkonfiguration::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Netzwerk::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Netzwerk::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = 'Netzwerk::Adresse';
    $Self->{Translation}->{'Network::Address::New'} = 'Netzwerk::Adresse::Neu';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Neu';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Netzwerk::DNS::Assist';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Systemkonfiguration::Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Netzwerk::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Systemkonfiguration';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Entfernen';
    $Self->{Translation}->{'Network::Address::Release'} = 'Netzwerk::Adresse::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Netzwerk::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Sustainment::Network'} = 'Sustainment::Netzwerk';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Netzwerk::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Netzwerk::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Netzwerk::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Netzwerk::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Entfernen';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Entfernen';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Netzwerk::Device Lifecycle::New Device';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Systemkonfiguration::Rollback';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Netzwerk::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Netzwerk::Firewall Policy::Unter Review';
    $Self->{Translation}->{'Network::Firewall Policy::Modify'} = 'Netzwerk::Firewall Policy::Modify';
    $Self->{Translation}->{'Security::Certificate::New/Renew'} = 'Security::Certificate::New/Renew';
    $Self->{Translation}->{'Security::Certificate::Issue'} = 'Security::Certificate::Issue';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Netzwerk::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Netzwerk::Routing/Switching';
    $Self->{Translation}->{'Security::Certificate::Assist'} = 'Security::Certificate::Assist';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Ressource';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Netzwerk::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Netzwerk::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Netzwerk::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Netzwerk::System Hardening';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Netzwerk::Firmware Management';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Ressource::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Netzwerk::Neu';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Netzwerk::DNS::Record Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Netzwerk::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Netzwerk::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Security::Certificate::Install/Update'} = 'Security::Certificate::Install/Update';
    $Self->{Translation}->{'Security::Certificate::Renew'} = 'Security::Certificate::Erneuern';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Netzwerk::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::Wiederherstellen';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Netzwerk::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'ATFM::Network'} = 'ATFM::Netzwerk';
    $Self->{Translation}->{'Security::Certificate::CSR Signing'} = 'Security::Certificate::CSR Signing';
    $Self->{Translation}->{'Network::Zone'} = 'Netzwerk::Zone';
    $Self->{Translation}->{'Network::Patch Management'} = 'Netzwerk::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Ersetzen';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Netzwerk::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Netzwerk::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Netzwerk::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Netzwerk::Connectivity';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Ressource::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Netzwerk::Firewall Policy::Neu';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Service::Entfernen';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Entfernen';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Netzwerk::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Netzwerk::Load Balancer::Neu';
    $Self->{Translation}->{'Network::System Configuration'} = 'Netzwerk::Systemkonfiguration';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Netzwerk::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Netzwerk::Device Lifecycle';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Netzwerk::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Netzwerk::DNS::Configuration Modify';
    $Self->{Translation}->{'Security::Certificate::Rollback'} = 'Security::Certificate::Rollback';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Netzwerk::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Netzwerk::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Netzwerk::Systemkonfiguration::Modify';
    $Self->{Translation}->{'Network::DNS'} = 'Netzwerk::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Installieren';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Segment::New',
        'Network::Segment',
        'Network::System Configuration::Baseline Update',
        'Backup::Restore::Request',
        'Network::System Configuration::Rollback',
        'Network Management::Network Security & Policy Management::Add',
        'Security::Certificate::Revoke',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Network::Firmware Management::Firmware Upgrade',
        'Compute::Resource::Disk Expansion',
        'Security::Certificate',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::Emergency',
        'Network::Load Balancer::Assist',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
        'Compute::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Network::DNS::Assist',
        'Compute::System Configuration::Modify',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Sustainment::Network',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::Device Lifecycle::New Device',
        'Compute::System Configuration::Rollback',
        'Network::Patch Management::Patch Rollback',
        'Network::Firewall Policy::Review',
        'Network::Firewall Policy::Modify',
        'Security::Certificate::New/Renew',
        'Security::Certificate::Issue',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Security::Certificate::Assist',
        'Compute::Resource',
        'Network::System Hardening::Apply/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Network::Firmware Management',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::DNS::Record Remove',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Security::Certificate::Install/Update',
        'Security::Certificate::Renew',
        'Network::Load Balancer::Configuration Modify',
        'Backup::Restore',
        'Network::Connectivity::Allowlist New/Modify',
        'ATFM::Network',
        'Security::Certificate::CSR Signing',
        'Network::Zone',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Connectivity',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Backup::Service::Remove',
        'Common Service::Trellix ePO::Remove',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Network::System Configuration',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::Load Balancer::Certificate New/Modify',
        'Network::DNS::Configuration Modify',
        'Security::Certificate::Rollback',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::System Configuration::Modify',
        'Network::DNS',
        'Security::Certificate::Install',
    );

}

1;
