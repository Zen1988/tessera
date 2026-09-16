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

package Kernel::Language::lv_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Address'} = 'Tīkls::Address';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Tīkls::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Tīkls::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Jauna';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Uzglabāšana::Platform::Patch Management';
    $Self->{Translation}->{'Network::Address::New'} = 'Tīkls::Address::Jauna';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Tīkls::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Tīkls::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Tīkls::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Tīkls::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Uzglabāšana::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Tīkls::Firewall Policy::Remove';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Tīkls::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Tīkls::System Hardening::Rollback';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Uzglabāšana::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Pievienot';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Uzglabāšana::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Tīkls::System Configuration::Baseline Update';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Servisi';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Tīkls::System Configuration::Rollback';
    $Self->{Translation}->{'Network::Segment::New'} = 'Tīkls::Segment::Jauna';
    $Self->{Translation}->{'Network::Segment'} = 'Tīkls::Segment';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Uzglabāšana::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Tīkls::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Tīkls::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Tīkls::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Tīkls::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Tīkls::Firewall Policy::Pārskats';
    $Self->{Translation}->{'Storage::Platform'} = 'Uzglabāšana::Platform';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Tīkls::DNS::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Uzglabāšana::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Tīkls::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Tīkls::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Tīkls::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Uzglabāšana::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Uzglabāšana::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Tīkls::Address::Release';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Tīkls::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Servisi::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Tīkls::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Tīkls::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Uzglabāšana::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Uzglabāšana::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Uzglabāšana::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Uzglabāšana::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Tīkls::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Tīkls::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Tīkls::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Tīkls::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Tīkls::Jauna';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Tīkls::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Tīkls::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Tīkls::System Hardening';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Tīkls::Firmware Management';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Tīkls::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Uzglabāšana::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Uzglabāšana::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Uzglabāšana::Object Storage::Replication Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Instalēt';
    $Self->{Translation}->{'Network::DNS'} = 'Tīkls::DNS';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Tīkls::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Tīkls::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Tīkls::System Configuration::Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Uzglabāšana::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Uzglabāšana::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Tīkls::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Tīkls::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Tīkls::Device Lifecycle';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Uzglabāšana::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Tīkls::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Uzglabāšana::Object Storage::Assist';
    $Self->{Translation}->{'Network::System Configuration'} = 'Tīkls::System Configuration';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Tīkls::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Jauna';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Servisi::Remove';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Uzglabāšana::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Network::Patch Management'} = 'Tīkls::Patch Management';
    $Self->{Translation}->{'Network::Connectivity'} = 'Tīkls::Connectivity';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Tīkls::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Tīkls::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Tīkls::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Jauna';
    $Self->{Translation}->{'Network::Zone'} = 'Tīkls::Zone';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::Address::New',
        'Network::Patch Management::Scheduled Patch',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
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
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Network::DNS::Rollback',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Network::Device Lifecycle::Device Replacement',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::DNS::Record Remove',
        'Network::New',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::System Hardening',
        'Network::Firmware Management',
        'Network::System Hardening::Apply/Modify',
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
        'Storage::Object Storage::Assist',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Network::Patch Management',
        'Network::Connectivity',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Firewall Policy::New',
        'Network::Zone',
    );

}

1;
