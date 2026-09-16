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

package Kernel::Language::vi_VN_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Common Service::Carbon Black::Remove'} = 'Common Service::Carbon Black::Hủy bỏ';
    $Self->{Translation}->{'Network::Address'} = 'Network::Địa chỉ';
    $Self->{Translation}->{'Common Service::Trellix ePO::Remove'} = 'Common Service::Trellix ePO::Hủy bỏ';
    $Self->{Translation}->{'Common Service::Monitoring::Remove'} = 'Common Service::Monitoring::Hủy bỏ';
    $Self->{Translation}->{'Backup::Service::Onboarding/Modify'} = 'Backup::Dịch vụ::Onboarding/Modify';
    $Self->{Translation}->{'Common Service::Red Hat Satellite::Remove'} = 'Common Service::Red Hat Satellite::Hủy bỏ';
    $Self->{Translation}->{'Network::Address::Release'} = 'Network::Địa chỉ::Release';
    $Self->{Translation}->{'Backup::Service::Remove'} = 'Backup::Dịch vụ::Hủy bỏ';
    $Self->{Translation}->{'Compute::Virtual Machine::New'} = 'Compute::Virtual Machine::Mới';
    $Self->{Translation}->{'Network::Segment::New'} = 'Network::Segment::Mới';
    $Self->{Translation}->{'Compute::Virtual Machine::Remove'} = 'Compute::Virtual Machine::Hủy bỏ';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::Hủy bỏ';
    $Self->{Translation}->{'Security::Certificate::Install'} = 'Security::Certificate::Cài đặt';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::Mới';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Thêm';
    $Self->{Translation}->{'Network::Firewall Policy::Review'} = 'Network::Firewall Policy::Thẩm định';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::Mới';
    $Self->{Translation}->{'Network::New'} = 'Network::Mới';
    $Self->{Translation}->{'Common Service::WSUS::Remove'} = 'Common Service::WSUS::Hủy bỏ';
    $Self->{Translation}->{'Network::Address::New'} = 'Network::Địa chỉ::Mới';
    $Self->{Translation}->{'Backup::Service'} = 'Backup::Dịch vụ';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Common Service::Carbon Black::Remove',
        'Network::Address',
        'Common Service::Trellix ePO::Remove',
        'Common Service::Monitoring::Remove',
        'Backup::Service::Onboarding/Modify',
        'Common Service::Red Hat Satellite::Remove',
        'Network::Address::Release',
        'Backup::Service::Remove',
        'Compute::Virtual Machine::New',
        'Network::Segment::New',
        'Compute::Virtual Machine::Remove',
        'Network::Firewall Policy::Remove',
        'Security::Certificate::Install',
        'Network::Load Balancer::New',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firewall Policy::Review',
        'Network::Firewall Policy::New',
        'Network::New',
        'Common Service::WSUS::Remove',
        'Network::Address::New',
        'Backup::Service',
    );

}

1;
