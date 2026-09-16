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

package Kernel::Language::hu_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Segment::New'} = 'Hálózat::Segment::Új';
    $Self->{Translation}->{'Network::Segment'} = 'Hálózat::Segment';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::Helyreállítás::Request';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Hálózat::Rendszerbeállítások::Baseline Update';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Hálózat::Rendszerbeállítások::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Szolgáltatás';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'Tárolás::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Hozzáadás';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'Tárolás::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'Hálózat::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'Hálózat::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Eltávolítás';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::Erőforrás::Disk Expansion';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'Hálózat::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Hálózat::Firewall Policy::Eltávolítás';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'Tárolás::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'Hálózat::Load Balancer::Assist';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'Hálózat::Load Balancer::Rollback';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Eltávolítás';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'Hálózat::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Rendszerbeállítások::Baseline Update';
    $Self->{Translation}->{'Network::Address'} = 'Hálózat::Cím';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'Hálózat::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'Hálózat::DNS::Assist';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Új';
    $Self->{Translation}->{'Network::Address::New'} = 'Hálózat::Cím::Új';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'Tárolás::Platform::Patch Management';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Rendszerbeállítások';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Rendszerbeállítások::Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'Hálózat::Routing/Switching::Rollback';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Szolgáltatás::Onboarding/Modify';
    $Self->{Translation}->{'Network::Address::Release'} = 'Hálózat::Cím::Release';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'Tárolás::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Eltávolítás';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'Hálózat::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'Tárolás::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'Hálózat::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Hálózat::Load Balancer::New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'Tárolás::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'Hálózat::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'Hálózat::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Eltávolítás';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Eltávolítás';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'Hálózat::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Rendszerbeállítások::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'Hálózat::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Hálózat::Firewall Policy::Vizsgálat';
    $Self->{Translation}->{'Storage::Platform'} = 'Tárolás::Platform';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'Tárolás::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'Hálózat::Routing/Switching';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'Hálózat::System Hardening::Remediation';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'Hálózat::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::Erőforrás';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'Tárolás::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'Tárolás::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'Tárolás::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'Hálózat::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'Hálózat::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'Hálózat::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'Hálózat::Firmware Management';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::Erőforrás::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'Hálózat::Új';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'Hálózat::DNS::Record Remove';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'Hálózat::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Hálózat::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'Tárolás::Object Storage';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'Hálózat::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Security::Certificate::Renew'} = 'Security::Certificate::Megújítás';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::Helyreállítás';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'Hálózat::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'Tárolás::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'Tárolás::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'Tárolás::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Network::Zone'} = 'Hálózat::Zone';
    $Self->{Translation}->{'Network::Load Balancer'} = 'Hálózat::Load Balancer';
    $Self->{Translation}->{'Network::Connectivity'} = 'Hálózat::Connectivity';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'Hálózat::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'Hálózat::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::Csere';
    $Self->{Translation}->{'Network::Patch Management'} = 'Hálózat::Patch Management';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::Erőforrás::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Új';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Szolgáltatás::Eltávolítás';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'Tárolás::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Eltávolítás';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'Tárolás::Object Storage::Assist';
    $Self->{Translation}->{'Network::System Configuration'} = 'Hálózat::Rendszerbeállítások';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Új';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'Hálózat::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'Hálózat::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Hálózat::Firewall Policy';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'Tárolás::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'Hálózat::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'Tárolás::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'Tárolás::Platform::Configuration Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'Hálózat::DNS::Configuration Modify';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'Hálózat::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'Hálózat::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Hálózat::Rendszerbeállítások::Modify';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Telepítés';
    $Self->{Translation}->{'Network::DNS'} = 'Hálózat::DNS';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Network::Segment::New',
        'Network::Segment',
        'Backup::Restore::Request',
        'Network::System Configuration::Baseline Update',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Storage::Platform::Firmware Upgrade',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Object Storage::Access New/Modify',
        'Network::Firmware Management::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Compute::Resource::Disk Expansion',
        'Network::Firewall Policy::Emergency',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Load Balancer::Assist',
        'Network::Load Balancer::Rollback',
        'Common Service::Carbon Black::Remove',
        'Network::Patch Management::Scheduled Patch',
        'Compute::System Configuration::Baseline Update',
        'Network::Address',
        'Network::Firmware Management::Firmware Rollback',
        'Network::DNS::Assist',
        'Compute::Virtual Machine::New',
        'Network::Address::New',
        'Storage::Platform::Patch Management',
        'Compute::System Configuration',
        'Compute::System Configuration::Modify',
        'Network::Routing/Switching::Rollback',
        'Backup::Service::Onboarding/Modify',
        'Network::Address::Release',
        'Storage::Object Storage::Versioning New/Modify',
        'Common Service::Monitoring::Remove',
        'Network::Device Lifecycle::Device Replacement',
        'Storage::Object Storage::Bucket Remove',
        'Network::Connectivity::Connectivity Assist',
        'Network::Load Balancer::New/Modify',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::VIP New/Modify',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Network::Patch Management::Patch Rollback',
        'Compute::System Configuration::Rollback',
        'Network::Device Lifecycle::New Device',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::Routing/Switching',
        'Network::System Hardening::Remediation',
        'Network::System Hardening::Apply/Modify',
        'Compute::Resource',
        'Storage::Object Storage::Replication New/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::Firmware Management',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::DNS::Record Remove',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Storage::Object Storage',
        'Network::Load Balancer::Configuration Modify',
        'Security::Certificate::Renew',
        'Backup::Restore',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Network::Zone',
        'Network::Load Balancer',
        'Network::Connectivity',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Routing/Switching::Configuration Modify',
        'Security::Certificate::Replace',
        'Network::Patch Management',
        'Compute::Resource::Assist',
        'Network::Firewall Policy::New',
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::System Configuration',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Storage::Platform::Configuration Modify',
        'Network::DNS::Configuration Modify',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::System Configuration::Modify',
        'Security::Certificate::Install',
        'Network::DNS',
    );

}

1;
