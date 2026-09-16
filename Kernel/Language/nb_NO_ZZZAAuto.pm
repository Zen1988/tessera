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

package Kernel::Language::nb_NO_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Nettverk::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Nettverk::Statistics';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Ressurs::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Nettverk::Firmware Management';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Nettverk::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Nettverk::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Nettverk::System Hardening';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Lagring::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Lagring::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Lagring::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Nettverk::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Ressurs';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Lagring::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Lagring::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Lagring::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Nettverk::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::Gjenopprett';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Nettverk::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Lagring::Object Storage';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Nettverk::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Nettverk::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::System Configuration'} = 'Nettverk::Systeminstillinger';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Statistics';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Nettverk::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Lagring::Object Storage::Assist';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Fjern';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Lagring::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Tjeneste::Fjern';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Ressurs::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Statistics';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Nettverk::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Nettverk::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Nettverk::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Nettverk::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Nettverk::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Erstatt';
    $Self->{Translation}->{'Network::Zone'} = 'Nettverk::Zone';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Installer';
    $Self->{Translation}->{'Network::DNS'} = 'Nettverk::DNS';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Nettverk::Systeminstillinger::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Nettverk::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Nettverk::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Lagring::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Nettverk::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Lagring::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Lagring::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Nettverk::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Nettverk::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Nettverk::Firewall Policy';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Ressurs::Disk Expansion';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Nettverk::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Nettverk::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Fjern';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Lagring::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Legg til';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Lagring::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Nettverk::Systeminstillinger::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Tjeneste';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::Gjenopprett::Request';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Nettverk::Systeminstillinger::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Nettverk::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Nettverk::Segment::Statistics';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Nettverk::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Statistics';
    $Self->{Translation}->{'Network::Address::New'} = 'Nettverk::Adresse::Statistics';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Lagring::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address'} = 'Nettverk::Adresse';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Nettverk::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Nettverk::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Systeminstillinger::Baseline Update';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Nettverk::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Fjern';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Nettverk::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Nettverk::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Nettverk::Firewall Policy::Fjern';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Lagring::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Nettverk::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Nettverk::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Nettverk::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Nettverk::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Lagring::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Lagring::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Nettverk::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Address::Release'} = 'Nettverk::Adresse::Release';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Lagring::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Fjern';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Systeminstillinger';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Nettverk::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Systeminstillinger::Modify';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Tjeneste::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Nettverk::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Nettverk::System Hardening::Remediation';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Lagring::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Storage::Platform'} = 'Lagring::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Nettverk::Firewall Policy::Evaluering';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Nettverk::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Systeminstillinger::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Nettverk::Device Lifecycle::New Device';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Fjern';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Fjern';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::DNS::Record Remove',
        'Network::New',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::Firmware Management',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Backup::Restore',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
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
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Zone',
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
        'Compute::Resource::Disk Expansion',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Backup::Restore::Request',
        'Network::System Configuration::Baseline Update',
        'Network::Segment',
        'Network::Segment::New',
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
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Address::Release',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Compute::System Configuration',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Storage::Platform::Hardening Apply/Modify',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Patch Management::Patch Rollback',
        'Compute::System Configuration::Rollback',
        'Network::Device Lifecycle::New Device',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
    );

}

1;
