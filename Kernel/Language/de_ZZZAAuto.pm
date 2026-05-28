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

package Kernel::Language::de_ZZZAAuto;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Network::Load Balancer'} = 'Netzwerk::Load Balancer';
    $Self->{Translation}->{'Network::Firewall Policy::New/Modify'} = 'Netzwerk::Firewall Policy::New/Modify';
    $Self->{Translation}->{'ATFM::Network'} = 'ATFM::Netzwerk';
    $Self->{Translation}->{'Network::Firewall Policy::Modify'} = 'Netzwerk::Firewall Policy::Modify';
    $Self->{Translation}->{'Network::Firewall Policy'} = 'Netzwerk::Firewall Policy';
    $Self->{Translation}->{'Sustainment::Network'} = 'Sustainment::Netzwerk';
    $Self->{Translation}->{'Network::Load Balancer::New/Modify'} = 'Netzwerk::Load Balancer::New/Modify';
    $Self->{Translation}->{'Network Management::Network Security & Policy Management::Add'} =
        'Network Management::Network Security & Policy Management::Hinzufügen';
    $Self->{Translation}->{'Network::Firewall Policy::Remove'} = 'Netzwerk::Firewall Policy::Entfernen';
    $Self->{Translation}->{'Network::Firewall Policy::New'} = 'Netzwerk::Firewall Policy::Neu';
    $Self->{Translation}->{'Network::Load Balancer::New'} = 'Netzwerk::Load Balancer::Neu';


    push @{ $Self->{JavaScriptStrings} // [] }, (
        'Network::Load Balancer',
        'Network::Firewall Policy::New/Modify',
        'ATFM::Network',
        'Network::Firewall Policy::Modify',
        'Network::Firewall Policy',
        'Sustainment::Network',
        'Network::Load Balancer::New/Modify',
        'Network Management::Network Security & Policy Management::Add',
        'Network::Firewall Policy::Remove',
        'Network::Firewall Policy::New',
        'Network::Load Balancer::New',
    );

}

1;
