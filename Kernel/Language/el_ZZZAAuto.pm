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

package Kernel::Language::el_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Δίκτυο::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Δίκτυο::Routing/Switching';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Αποθήκευση::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Δίκτυο::Firewall Policy::Ανασκόπηση';
    $Self->{Translation}->{'Storage::Platform'} = 'Αποθήκευση::Platform';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Δίκτυο::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Δίκτυο::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Δίκτυο::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Αποθήκευση::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Δίκτυο::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Δίκτυο::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Δίκτυο::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Αποθήκευση::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Δίκτυο::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Αποθήκευση::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Δίκτυο::Address::Release';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Υπηρεσία::Onboarding/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Δίκτυο::Routing/Switching::Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Δίκτυο::DNS::Assist';
    $Self->{Translation}->{'Network::Address::New'} = 'Δίκτυο::Address::Νέο';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Αποθήκευση::Platform::Patch Management';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Νέο';
    $Self->{Translation}->{'Network::Address'} = 'Δίκτυο::Address';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Δίκτυο::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Δίκτυο::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Δίκτυο::Load Balancer::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Δίκτυο::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Δίκτυο::Firewall Policy::Emergency';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Αποθήκευση::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Δίκτυο::Firewall Policy::Remove';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Δίκτυο::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Δίκτυο::System Hardening::Rollback';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Αποθήκευση::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Αποθήκευση::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Προσθήκη';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Υπηρεσία';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Δίκτυο::System Configuration::Rollback';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Δίκτυο::System Configuration::Baseline Update';
    $Self->{Translation}->{'Network::Segment'} = 'Δίκτυο::Segment';
    $Self->{Translation}->{'Network::Segment::New'} = 'Δίκτυο::Segment::Νέο';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Εγκατάσταση';
    $Self->{Translation}->{'Network::DNS'} = 'Δίκτυο::DNS';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Δίκτυο::System Configuration::Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Δίκτυο::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Δίκτυο::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Αποθήκευση::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Δίκτυο::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Αποθήκευση::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Αποθήκευση::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Δίκτυο::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Δίκτυο::Firewall Policy';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Δίκτυο::Device Lifecycle';
    $Self->{Translation}->{'Network::System Configuration'} = 'Δίκτυο::System Configuration';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Δίκτυο::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Νέο';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Αποθήκευση::Object Storage::Assist';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Αποθήκευση::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Υπηρεσία::Remove';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Νέο';
    $Self->{Translation}->{'Network::Patch Management'} = 'Δίκτυο::Patch Management';
    $Self->{Translation}->{'Network::Connectivity'} = 'Δίκτυο::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Δίκτυο::Load Balancer';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Δίκτυο::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Δίκτυο::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Zone'} = 'Δίκτυο::Zone';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Αποθήκευση::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Αποθήκευση::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Αποθήκευση::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Δίκτυο::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Αποθήκευση::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Δίκτυο::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Δίκτυο::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Δίκτυο::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Δίκτυο::DNS::Record Remove';
    $Self->{Translation}->{'Network::New'} = 'Δίκτυο::Νέο';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Δίκτυο::Firmware Management';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Δίκτυο::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Δίκτυο::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::System Hardening'} = 'Δίκτυο::System Hardening';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Αποθήκευση::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Αποθήκευση::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Αποθήκευση::Object Storage::Replication Modify';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Δίκτυο::System Hardening::Apply/Modify';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Network::Patch Management::Patch Rollback',
        'Network::Device Lifecycle::New Device',
        'Network::Load Balancer::VIP New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Storage::Object Storage::Bucket Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Address::Release',
        'Backup::Service::Onboarding/Modify',
        'Network::Routing/Switching::Rollback',
        'Network::DNS::Assist',
        'Network::Address::New',
        'Storage::Platform::Patch Management',
        'Compute::Virtual Machine::New',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Patch Management::Scheduled Patch',
        'Network::Load Balancer::Rollback',
        'Network::Load Balancer::Assist',
        'Network::Firewall Policy::Emergency',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Remove',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Storage::Platform::Firmware Upgrade',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Backup::Service',
        'Network::System Configuration::Rollback',
        'Network::System Configuration::Baseline Update',
        'Network::Segment',
        'Network::Segment::New',
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
        'Network::Firewall Policy',
        'Network::Device Lifecycle',
        'Network::System Configuration',
        'Network::Patch Management::Emergency Patch',
        'Network::Load Balancer::New',
        'Storage::Object Storage::Assist',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Backup::Service::Remove',
        'Network::Firewall Policy::New',
        'Network::Patch Management',
        'Network::Connectivity',
        'Network::Load Balancer',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Zone',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Network::Firewall Policy::New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::DNS::Record Remove',
        'Network::New',
        'Network::Firmware Management',
        'Network::DNS::Record New/Modify',
        'Network::Load Balancer::VIP Remove',
        'Network::System Hardening',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication Modify',
        'Network::System Hardening::Apply/Modify',
    );

}

1;
