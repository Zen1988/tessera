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

package Kernel::Language::et_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Ladustamine::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Lisa';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Ladustamine::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Võrk::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Võrk::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Eemalda';
    $Self->{Translation}->{'Network::Segment'} = 'Võrk::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Võrk::Segment::Uus';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Võrk::System Configuration::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Teenus';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Võrk::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Võrk::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Võrk::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Uus';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Ladustamine::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address::New'} = 'Võrk::Address::Uus';
    $Self->{Translation}->{'Network::Address'} = 'Võrk::Address';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Võrk::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Võrk::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Võrk::Firewall Policy::Eemalda';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Ladustamine::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Võrk::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Eemalda';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Võrk::Load Balancer::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Ladustamine::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Võrk::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Võrk::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Võrk::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Võrk::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Ladustamine::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Võrk::Routing/Switching::Rollback';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Teenus::Onboarding/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Võrk::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Network::Address::Release'} = 'Võrk::Address::Release';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Ladustamine::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Eemalda';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Võrk::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Võrk::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Ladustamine::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Eemalda';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Eemalda';
    $Self->{Translation}->{'Storage::Platform'} = 'Ladustamine::Platform';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Võrk::Firewall Policy::Ülevaade';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Võrk::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Võrk::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::New'} = 'Võrk::Uus';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Võrk::DNS::Record Remove';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Ladustamine::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Ladustamine::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Ladustamine::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Võrk::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Võrk::Firmware Management';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Võrk::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Võrk::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Võrk::System Hardening';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Ladustamine::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Ladustamine::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Ladustamine::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Võrk::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Võrk::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Võrk::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Ladustamine::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Võrk::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Ladustamine::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Teenus::Eemalda';
    $Self->{Translation}->{'Network::System Configuration'} = 'Võrk::System Configuration';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Uus';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Võrk::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Eemalda';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Ladustamine::Object Storage::Assist';
    $Self->{Translation}->{'Network::Zone'} = 'Võrk::Zone';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Uus';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Võrk::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Võrk::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'Võrk::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Võrk::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Võrk::Patch Management';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Võrk::System Configuration::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Võrk::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Võrk::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Paigalda';
    $Self->{Translation}->{'Network::DNS'} = 'Võrk::DNS';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Ladustamine::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Võrk::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Võrk::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Võrk::Firewall Policy';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Ladustamine::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Võrk::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Ladustamine::Object Storage::Lifecycle Policy New/Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Segment',
        'Network::Segment::New',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Network::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
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
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::Routing/Switching::Rollback',
        'Backup::Service::Onboarding/Modify',
        'Network::Device Lifecycle::Device Replacement',
        'Network::Address::Release',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Storage::Platform',
        'Network::Firewall Policy::Review',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Network::New',
        'Network::DNS::Record Remove',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Network::System Hardening::Apply/Modify',
        'Network::Firmware Management',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::System Configuration',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::Zone',
        'Network::Firewall Policy::New',
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Connectivity',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Patch Management',
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
    );

}

1;
