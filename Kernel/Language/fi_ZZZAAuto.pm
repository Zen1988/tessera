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

package Kernel::Language::fi_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Verkko::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Varastointi::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Varastointi::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Varastointi::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Verkko::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Varastointi::Object Storage';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Verkko::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Verkko::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Verkko::DNS::Record Remove';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Resurssi::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Verkko::Uusi';
    $Self->{Translation}->{'Network::System Hardening'} = 'Verkko::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Verkko::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Verkko::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Verkko::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Verkko::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Resurssi';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Varastointi::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Varastointi::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Varastointi::Object Storage::Replication Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Asenna';
    $Self->{Translation}->{'Network::DNS'} = 'Verkko::DNS';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Verkko::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Verkko::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Verkko::System Configuration::Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Varastointi::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Varastointi::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Verkko::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Verkko::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Verkko::Device Lifecycle';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Varastointi::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Verkko::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Poista';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Varastointi::Object Storage::Assist';
    $Self->{Translation}->{'Network::System Configuration'} = 'Verkko::System Configuration';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Verkko::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Uusi';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Palvelu::Poista';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Varastointi::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Verkko::Patch Management';
    $Self->{Translation}->{'Network::Connectivity'} = 'Verkko::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Verkko::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Verkko::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Verkko::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Resurssi::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Uusi';
    $Self->{Translation}->{'Network::Zone'} = 'Verkko::Zone';
    $Self->{Translation}->{'Network::Address'} = 'Verkko::Address';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Verkko::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Verkko::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Verkko::Address::Uusi';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Uusi';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Varastointi::Platform::Patch Management';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Verkko::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Verkko::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Verkko::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Poista';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Verkko::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Varastointi::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Verkko::Firewall Policy::Poista';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Verkko::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Poista';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Verkko::System Hardening::Rollback';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Resurssi::Disk Expansion';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Varastointi::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Varastointi::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Lisää';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Verkko::System Configuration::Baseline Update';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Palvelu';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Verkko::System Configuration::Rollback';
    $Self->{Translation}->{'Network::Segment::New'} = 'Verkko::Segment::Uusi';
    $Self->{Translation}->{'Network::Segment'} = 'Verkko::Segment';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Varastointi::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Verkko::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Verkko::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Verkko::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Verkko::Device Lifecycle::New Device';
    $Self->{Translation}->{'Storage::Platform'} = 'Varastointi::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Verkko::Firewall Policy::Arvostelu';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Poista';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Poista';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Verkko::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Varastointi::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Verkko::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Verkko::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Verkko::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Varastointi::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Varastointi::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Poista';
    $Self->{Translation}->{'Network::Address::Release'} = 'Verkko::Address::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Verkko::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Palvelu::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Verkko::Routing/Switching::Rollback';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::DNS::Record Remove',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::Firmware Management',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Security::Certificate::Install',
        'Network::DNS',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::System Configuration::Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Network::Patch Management',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Zone',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Patch Management::Scheduled Patch',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firmware Management::Firmware Upgrade',
        'Common Service::Red Hat Satellite::Remove',
        'Network::System Hardening::Rollback',
        'Compute::Resource::Disk Expansion',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::System Configuration::Baseline Update',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::Segment::New',
        'Network::Segment',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
    );

}

1;
