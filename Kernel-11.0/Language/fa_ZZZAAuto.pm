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

package Kernel::Language::fa_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Network::Firewall Policy::حذف کردن';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::افزودن';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Network::Firewall Policy::جدید';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Network::Load Balancer::جدید';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Network::Firewall Policy::Remove',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firewall Policy::New',
        'Network::Load Balancer::New',
    );

}

1;
