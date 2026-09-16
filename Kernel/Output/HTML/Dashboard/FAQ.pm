# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Output::HTML::Dashboard::FAQ;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::FAQ',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    for my $Needed (qw(Config Name UserID))
    {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    return;
}

sub Config {
    my ( $Self, %Param ) = @_;

    return (
        %{ $Self->{Config} },
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

    # set default interface settings
    my $Interface = $FAQObject->StateTypeGet(
        Name   => 'internal',
        UserID => $Self->{UserID},
    );
    my $InterfaceStates = $FAQObject->StateTypeList(
        Types  => $Kernel::OM->Get('Kernel::Config')->Get('FAQ::Agent::StateTypes'),
        UserID => $Self->{UserID},
    );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->FAQShowLatestNewsBox(
        FAQObject       => $FAQObject,
        Type            => $Self->{Config}->{Type},
        Mode            => 'Agent',
        CategoryID      => 0,
        Interface       => $Interface,
        InterfaceStates => $InterfaceStates,
        UserID          => $Self->{UserID},
    );
    my $Content = $LayoutObject->Output(
        TemplateFile => 'AgentDashboardFAQOverview',
        Data         => {
            CategoryID   => 0,
            SidebarClass => 'Medium',
        },
    );
    return $Content;
}

1;
