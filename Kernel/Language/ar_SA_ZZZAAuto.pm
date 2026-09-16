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

package Kernel::Language::ar_SA_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::خِدْمة::إزالة';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy Modify'} = 'التخزين::Object Storage::Lifecycle Policy Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::إزالة';
    $Self->{Translation}->{'Storage::Object Storage::Assist'} = 'التخزين::Object Storage::Assist';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::جديد';
    $Self->{Translation}->{'Network::Patch Management::Emergency Patch'} = 'الشبكة::Patch Management::Emergency Patch';
    $Self->{Translation}->{'Network::System Configuration'} = 'الشبكة::تكوين النظام';
    $Self->{Translation}->{'Network::Zone'} = 'الشبكة::Zone';
    $Self->{Translation}->{'Network::Load Balancer'} = 'الشبكة::Load Balancer';
    $Self->{Translation}->{'Network::Routing/Switching::Configuration Modify'} = 'الشبكة::Routing/Switching::Configuration Modify';
    $Self->{Translation}->{'Network::Load Balancer::Pool/Member New/Modify'} = 'الشبكة::Load Balancer::Pool/Member New/Modify';
    $Self->{Translation}->{'Network::Connectivity'} = 'الشبكة::Connectivity';
    $Self->{Translation}->{'Network::Patch Management'} = 'الشبكة::Patch Management';
    $Self->{Translation}->{'Security::Certificate::Replace'} = 'Security::Certificate::اِسْتَبْدَلَ';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::جديد';
    $Self->{Translation}->{'Compute::Resource::Assist'} = 'Compute::مَوْرِد::Assist';
    $Self->{Translation}->{'Network::Patch Management::Out-of-Band Patch'} = 'الشبكة::Patch Management::Out-of-Band Patch';
    $Self->{Translation}->{'Network::Connectivity::Proxy/URL Allowlist'} = 'الشبكة::Connectivity::Proxy/URL Allowlist';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'الشبكة::تكوين النظام::Modify';
    $Self->{Translation}->{'Network::DNS'} = 'الشبكة::DNS';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::تثبيت';
    $Self->{Translation}->{'Network::Device Lifecycle'} = 'الشبكة::Device Lifecycle';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'الشبكة::Firewall Policy';
    $Self->{Translation}->{'Network::Load Balancer::Certificate New/Modify'} = 'الشبكة::Load Balancer::Certificate New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Configuration Modify'} = 'التخزين::Object Storage::Bucket Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage::Lifecycle Policy New/Modify'} = 'التخزين::Object Storage::Lifecycle Policy New/Modify';
    $Self->{Translation}->{'Network::DNS::Configuration Modify'} = 'الشبكة::DNS::Configuration Modify';
    $Self->{Translation}->{'Storage::Platform::Configuration Modify'} = 'التخزين::Platform::Configuration Modify';
    $Self->{Translation}->{'Compute::Resource::Upgrade/Downgrade'} = 'Compute::مَوْرِد::Upgrade/Downgrade';
    $Self->{Translation}->{'Network::New'} = 'الشبكة::جديد';
    $Self->{Translation}->{'Network::DNS::Record Remove'} = 'الشبكة::DNS::Record Remove';
    $Self->{Translation}->{'Compute::Resource'} = 'Compute::مَوْرِد';
    $Self->{Translation}->{'Network::System Hardening::Apply/Modify'} = 'الشبكة::System Hardening::Apply/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication Modify'} = 'التخزين::Object Storage::Replication Modify';
    $Self->{Translation}->{'Storage::Object Storage::Versioning Modify'} = 'التخزين::Object Storage::Versioning Modify';
    $Self->{Translation}->{'Storage::Object Storage::Replication New/Modify'} = 'التخزين::Object Storage::Replication New/Modify';
    $Self->{Translation}->{'Network::System Hardening'} = 'الشبكة::System Hardening';
    $Self->{Translation}->{'Network::Load Balancer::VIP Remove'} = 'الشبكة::Load Balancer::VIP Remove';
    $Self->{Translation}->{'Network::DNS::Record New/Modify'} = 'الشبكة::DNS::Record New/Modify';
    $Self->{Translation}->{'Network::Firmware Management'} = 'الشبكة::Firmware Management';
    $Self->{Translation}->{'Backup::Restore'} = 'Backup::اِسْتَعادَ';
    $Self->{Translation}->{'Network::Connectivity::Allowlist New/Modify'} = 'الشبكة::Connectivity::Allowlist New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Quota New/Modify'} = 'التخزين::Object Storage::Quota New/Modify';
    $Self->{Translation}->{'Storage::Object Storage::Rollback'} = 'التخزين::Object Storage::Rollback';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock New/Modify'} = 'التخزين::Object Storage::Object Lock New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Decommission'} = 'الشبكة::Device Lifecycle::Decommission';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'الشبكة::Firewall Policy::New/Modify';
    $Self->{Translation}->{'Network::Load Balancer::Configuration Modify'} = 'الشبكة::Load Balancer::Configuration Modify';
    $Self->{Translation}->{'Storage::Object Storage'} = 'التخزين::Object Storage';
    $Self->{Translation}->{'Storage::Object Storage::Bucket Remove'} = 'التخزين::Object Storage::Bucket Remove';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'الشبكة::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network::Connectivity::Connectivity Assist'} = 'الشبكة::Connectivity::Connectivity Assist';
    $Self->{Translation}->{'Storage::Object Storage::Bucket New/Modify'} = 'التخزين::Object Storage::Bucket New/Modify';
    $Self->{Translation}->{'Network::DNS::Rollback'} = 'الشبكة::DNS::Rollback';
    $Self->{Translation}->{'Network::Load Balancer::VIP New/Modify'} = 'الشبكة::Load Balancer::VIP New/Modify';
    $Self->{Translation}->{'Network::Routing/Switching::Rollback'} = 'الشبكة::Routing/Switching::Rollback';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::تكوين النظام::Modify';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::خِدْمة::Onboarding/Modify';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::تكوين النظام';
    $Self->{Translation}->{'Network::Address::Release'} = 'الشبكة::العنوان::Release';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::إزالة';
    $Self->{Translation}->{'Storage::Object Storage::Versioning New/Modify'} = 'التخزين::Object Storage::Versioning New/Modify';
    $Self->{Translation}->{'Network::Device Lifecycle::Device Replacement'} = 'الشبكة::Device Lifecycle::Device Replacement';
    $Self->{Translation}->{'Storage::Platform::Hardening Apply/Modify'} = 'التخزين::Platform::Hardening Apply/Modify';
    $Self->{Translation}->{'Network::System Hardening::Remediation'} = 'الشبكة::System Hardening::Remediation';
    $Self->{Translation}->{'Network::Routing/Switching'} = 'الشبكة::Routing/Switching';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::إزالة';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::إزالة';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::تكوين النظام::Rollback';
    $Self->{Translation}->{'Network::Device Lifecycle::New Device'} = 'الشبكة::Device Lifecycle::New Device';
    $Self->{Translation}->{'Network::Patch Management::Patch Rollback'} = 'الشبكة::Patch Management::Patch Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'الشبكة::Firewall Policy::المراجعة';
    $Self->{Translation}->{'Storage::Platform'} = 'التخزين::Platform';
    $Self->{Translation}->{'Storage::Object Storage::Access New/Modify'} = 'التخزين::Object Storage::Access New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::أضف';
    $Self->{Translation}->{'Storage::Platform::Firmware Upgrade'} = 'التخزين::Platform::Firmware Upgrade';
    $Self->{Translation}->{'Network::System Hardening::Rollback'} = 'الشبكة::System Hardening::Rollback';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::إزالة';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Upgrade'} = 'الشبكة::Firmware Management::Firmware Upgrade';
    $Self->{Translation}->{'Compute::Resource::Disk Expansion'} = 'Compute::مَوْرِد::Disk Expansion';
    $Self->{Translation}->{'Network::Segment::New'} = 'الشبكة::Segment::جديد';
    $Self->{Translation}->{'Network::Segment'} = 'الشبكة::Segment';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'الشبكة::تكوين النظام::Baseline Update';
    $Self->{Translation}->{'Backup::Restore::Request'} = 'Backup::اِسْتَعادَ::Request';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'الشبكة::تكوين النظام::Rollback';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::خِدْمة';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::تكوين النظام::Baseline Update';
    $Self->{Translation}->{'Network::Patch Management::Scheduled Patch'} = 'الشبكة::Patch Management::Scheduled Patch';
    $Self->{Translation}->{'Network::Firmware Management::Firmware Rollback'} = 'الشبكة::Firmware Management::Firmware Rollback';
    $Self->{Translation}->{'Network::Address'} = 'الشبكة::العنوان';
    $Self->{Translation}->{'Network::Address::New'} = 'الشبكة::العنوان::جديد';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::جديد';
    $Self->{Translation}->{'Storage::Platform::Patch Management'} = 'التخزين::Platform::Patch Management';
    $Self->{Translation}->{'Network::DNS::Assist'} = 'الشبكة::DNS::Assist';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'الشبكة::Firewall Policy::إزالة';
    $Self->{Translation}->{'Storage::Object Storage::Object Lock Modify'} = 'التخزين::Object Storage::Object Lock Modify';
    $Self->{Translation}->{'Network::Firewall Policy::Emergency'} = 'الشبكة::Firewall Policy::Emergency';
    $Self->{Translation}->{'Network::Load Balancer::Assist'} = 'الشبكة::Load Balancer::Assist';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::إزالة';
    $Self->{Translation}->{'Network::Load Balancer::Rollback'} = 'الشبكة::Load Balancer::Rollback';


    $Self->{JavaScriptStrings} //= [];
    push $Self->{JavaScriptStrings}->@*, (
        'Backup::Service::Remove',
        'Storage::Object Storage::Lifecycle Policy Modify',
        'Common Service::Trellix ePO::Remove',
        'Storage::Object Storage::Assist',
        'Network::Load Balancer::New',
        'Network::Patch Management::Emergency Patch',
        'Network::System Configuration',
        'Network::Zone',
        'Network::Load Balancer',
        'Network::Routing/Switching::Configuration Modify',
        'Network::Load Balancer::Pool/Member New/Modify',
        'Network::Connectivity',
        'Network::Patch Management',
        'Security::Certificate::Replace',
        'Network::Firewall Policy::New',
        'Compute::Resource::Assist',
        'Network::Patch Management::Out-of-Band Patch',
        'Network::Connectivity::Proxy/URL Allowlist',
        'Network::System Configuration::Modify',
        'Network::DNS',
        'Security::Certificate::Install',
        'Network::Device Lifecycle',
        'Network::Firewall Policy',
        'Network::Load Balancer::Certificate New/Modify',
        'Storage::Object Storage::Bucket Configuration Modify',
        'Storage::Object Storage::Lifecycle Policy New/Modify',
        'Network::DNS::Configuration Modify',
        'Storage::Platform::Configuration Modify',
        'Compute::Resource::Upgrade/Downgrade',
        'Network::New',
        'Network::DNS::Record Remove',
        'Compute::Resource',
        'Network::System Hardening::Apply/Modify',
        'Storage::Object Storage::Replication Modify',
        'Storage::Object Storage::Versioning Modify',
        'Storage::Object Storage::Replication New/Modify',
        'Network::System Hardening',
        'Network::Load Balancer::VIP Remove',
        'Network::DNS::Record New/Modify',
        'Network::Firmware Management',
        'Backup::Restore',
        'Network::Connectivity::Allowlist New/Modify',
        'Storage::Object Storage::Quota New/Modify',
        'Storage::Object Storage::Rollback',
        'Storage::Object Storage::Object Lock New/Modify',
        'Network::Device Lifecycle::Decommission',
        'Network::Firewall Policy::New/Modify',
        'Network::Load Balancer::Configuration Modify',
        'Storage::Object Storage',
        'Storage::Object Storage::Bucket Remove',
        'Network::Load Balancer::New/Modify',
        'Network::Connectivity::Connectivity Assist',
        'Storage::Object Storage::Bucket New/Modify',
        'Network::DNS::Rollback',
        'Network::Load Balancer::VIP New/Modify',
        'Network::Routing/Switching::Rollback',
        'Compute::System Configuration::Modify',
        'Backup::Service::Onboarding/Modify',
        'Compute::System Configuration',
        'Network::Address::Release',
        'Common Service::Monitoring::Remove',
        'Storage::Object Storage::Versioning New/Modify',
        'Network::Device Lifecycle::Device Replacement',
        'Storage::Platform::Hardening Apply/Modify',
        'Network::System Hardening::Remediation',
        'Network::Routing/Switching',
        'Compute::Virtual Machine::Remove',
        'Common Service::WSUS::Remove',
        'Compute::System Configuration::Rollback',
        'Network::Device Lifecycle::New Device',
        'Network::Patch Management::Patch Rollback',
        'Network::Firewall Policy::Review',
        'Storage::Platform',
        'Storage::Object Storage::Access New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Storage::Platform::Firmware Upgrade',
        'Network::System Hardening::Rollback',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Firmware Management::Firmware Upgrade',
        'Compute::Resource::Disk Expansion',
        'Network::Segment::New',
        'Network::Segment',
        'Network::System Configuration::Baseline Update',
        'Backup::Restore::Request',
        'Network::System Configuration::Rollback',
        'Backup::Service',
        'Compute::System Configuration::Baseline Update',
        'Network::Patch Management::Scheduled Patch',
        'Network::Firmware Management::Firmware Rollback',
        'Network::Address',
        'Network::Address::New',
        'Compute::Virtual Machine::New',
        'Storage::Platform::Patch Management',
        'Network::DNS::Assist',
        'Network::Firewall Policy::Remove',
        'Storage::Object Storage::Object Lock Modify',
        'Network::Firewall Policy::Emergency',
        'Network::Load Balancer::Assist',
        'Common Service::Carbon Black::Remove',
        'Network::Load Balancer::Rollback',
    );

}

1;
