# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.de/
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

package Kernel::Output::HTML::SurveyMenu::Generic;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get UserID param
    $Self->{UserID} = $Param{UserID} || die "Got no UserID!";

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Survey} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Survey!',
        );
        return;
    }

    # grant access by default
    my $Access = 1;

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get groups
    my $Action   = $Param{Config}->{Action};
    my $GroupsRo = $ConfigObject->Get('Frontend::Module')->{$Action}->{GroupRo} || [];
    my $GroupsRw = $ConfigObject->Get('Frontend::Module')->{$Action}->{Group}   || [];

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check permission
    if ( $Action && ( @{$GroupsRo} || @{$GroupsRw} ) ) {

        # deny access by default, when there are groups to check
        $Access = 0;

        # check read only groups
        ROGROUP:
        for my $GroupRo ( @{$GroupsRo} ) {
            my $HasPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
                UserID    => $Self->{UserID},
                GroupName => $GroupRo,
                Type      => 'ro',
            );

            next ROGROUP if !$HasPermission;

            # set access
            $Access = 1;
            last ROGROUP;
        }

        # check read write groups
        RWGROUP:
        for my $RwGroup ( @{$GroupsRw} ) {

            my $HasPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
                UserID    => $Self->{UserID},
                GroupName => $RwGroup,
                Type      => 'rw',
            );

            next RWGROUP if !$HasPermission;

            # set access
            $Access = 1;
            last RWGROUP;
        }
    }

    return $Param{Counter} if !$Access;

    # output menu item
    $LayoutObject->Block(
        Name => 'MenuItem',
        Data => {
            %Param,
            %{ $Param{Survey} },
            %{ $Param{Config} },
        },
    );

    $Param{Counter}++;

    return $Param{Counter};
}

1;
