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

package Kernel::Language::lt_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Tinklas::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Tinklas::System Configuration::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Paslauga';
    $Self->{Translation}->{'Network::Segment::New'} = 'Tinklas::Segment::Naujas';
    $Self->{Translation}->{'Network::Segment'} = 'Tinklas::Segment';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Tinklas::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Tinklas::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Pašalinti';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Resursai::Disk Expansion';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Saugykla::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Saugykla::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Pridėti';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Tinklas::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Tinklas::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Pašalinti';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Tinklas::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Tinklas::Firewall Policy::Pašalinti';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Saugykla::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Address'} = 'Tinklas::Address';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Tinklas::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Tinklas::DNS::Assist';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Saugykla::Platform::Patch Management';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Naujas';
    $Self->{Translation}->{'Network::Address::New'} = 'Tinklas::Address::Naujas';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Tinklas::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Address::Release'} = 'Tinklas::Address::Release';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Pašalinti';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Saugykla::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Tinklas::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Tinklas::Routing/Switching::Rollback';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Paslauga::Onboarding/Modify';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Tinklas::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Tinklas::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Tinklas::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Saugykla::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Tinklas::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Saugykla::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Tinklas::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Tinklas::Device Lifecycle::New Device';
    $Self->{Translation}->{'Storage::Platform'} = 'Saugykla::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Tinklas::Firewall Policy::Peržiūrėkite';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Pašalinti';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Pašalinti';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Saugykla::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Tinklas::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Tinklas::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Tinklas::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Tinklas::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Tinklas::System Hardening';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Tinklas::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Tinklas::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Resursai';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Saugykla::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Saugykla::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Saugykla::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Tinklas::DNS::Record Remove';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Resursai::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Tinklas::Naujas';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Saugykla::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Tinklas::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Tinklas::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Tinklas::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Tinklas::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Saugykla::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Saugykla::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Saugykla::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Tinklas::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Tinklas::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Tinklas::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Tinklas::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Tinklas::Patch Management';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Resursai::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Naujas';
    $Self->{Translation}->{'Network::Zone'} = 'Tinklas::Zone';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Pašalinti';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Saugykla::Object Storage::Assist';
    $Self->{Translation}->{'Network::System Configuration'} = 'Tinklas::System Configuration';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Naujas';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Tinklas::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Paslauga::Pašalinti';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Saugykla::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Saugykla::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Saugykla::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Tinklas::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Tinklas::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Tinklas::Firewall Policy';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Saugykla::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Tinklas::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Įdiegti';
    $Self->{Translation}->{'Network::DNS'} = 'Tinklas::DNS';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Tinklas::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Tinklas::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Tinklas::System Configuration::Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::System Configuration::Baseline Update',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Network::Segment::New',
        'Network::Segment',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Compute::Resource::Disk Expansion',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Storage::Platform::Patch Management',
        'Compute::Virtual Machine::New',
        'Network::Address::New',
        'Network::Patch Management::Scheduled Patch',
        'Network::Address::Release',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Routing/Switching::Rollback',
        'Backup::Service::Onboarding/Modify',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Network::Firmware Management',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Network::DNS::Record Remove',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Patch Management',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Network::Zone',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::System Configuration',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Security::Certificate::Install',
        'Network::DNS',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::System Configuration::Modify',
    );

}

1;
