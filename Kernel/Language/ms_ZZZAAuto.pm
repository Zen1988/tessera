# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2023 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::Language::ms_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::New'} = 'Network::Baru';
    $Self->{Translation}->{'Compute::System Configuration::Baseline Update'} = 'Compute::Konfigurasi Sistem::Baseline Update';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Buang';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Buang';
    $Self->{Translation}->{'Network::Address'} = 'Network::Alamat';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Network::Firewall Policy::mengkaji';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Buang';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Tambah';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Servis::Buang';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Buang';
    $Self->{Translation}->{'Compute::System Configuration'} = 'Compute::Konfigurasi Sistem';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Baru';
    $Self->{Translation}->{'Network::System Configuration::Modify'} = 'Network::Konfigurasi Sistem::Modify';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Buang';
    $Self->{Translation}->{'Compute::System Configuration::Modify'} = 'Compute::Konfigurasi Sistem::Modify';
    $Self->{Translation}->{'Network::System Configuration::Rollback'} = 'Network::Konfigurasi Sistem::Rollback';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Baru';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Servis';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Alamat::Baru';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Baru';
    $Self->{Translation}->{'Network::System Configuration'} = 'Network::Konfigurasi Sistem';
    $Self->{Translation}->{'Network::System Configuration::Baseline Update'} = 'Network::Konfigurasi Sistem::Baseline Update';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Buang';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Pasang';
    $Self->{Translation}->{'Compute::System Configuration::Rollback'} = 'Compute::Konfigurasi Sistem::Rollback';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::Alamat::Release';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Baru';
    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Buang';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Servis::Onboarding/Modify';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Network::New',
        'Compute::System Configuration::Baseline Update',
        'Common Service::WSUS::Remove',
        'Compute::Virtual Machine::Remove',
        'Network::Address',
        'Network::Firewall Policy::Review',
        'Network::Firewall Policy::Remove',
        'Network Management::Network Security & Policy Management::Add',
        'Backup::Service::Remove',
        'Common Service::Red Hat Satellite::Remove',
        'Compute::System Configuration',
        'Network::Segment::New',
        'Network::System Configuration::Modify',
        'Common Service::Trellix ePO::Remove',
        'Compute::System Configuration::Modify',
        'Network::System Configuration::Rollback',
        'Network::Firewall Policy::New',
        'Backup::Service',
        'Network::Address::New',
        'Network::Load Balancer::New',
        'Network::System Configuration',
        'Network::System Configuration::Baseline Update',
        'Common Service::Monitoring::Remove',
        'Security::Certificate::Install',
        'Compute::System Configuration::Rollback',
        'Network::Address::Release',
        'Compute::Virtual Machine::New',
        'Common Service::Carbon Black::Remove',
        'Backup::Service::Onboarding/Modify',
    );

}

1;
