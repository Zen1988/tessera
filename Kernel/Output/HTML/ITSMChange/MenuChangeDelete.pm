# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2021 Rother OSS GmbH, https://otobo.de/
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

package Kernel::Output::HTML::ITSMChange::MenuChangeDelete;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
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
    if ( !$Param{Change} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Change!',
        );
        return;
    }

    # get config object
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # get config for the relevant action
    my $FrontendConfig = $ConfigObject->Get("ITSMChange::Frontend::$Param{Config}->{Action}");

    # get the required privilege, 'ro' or 'rw'
    my $RequiredPriv;
    if ($FrontendConfig) {

        # get the required priv from the frontend configuration
        $RequiredPriv = $FrontendConfig->{Permission};
    }

    # Display the menu-link, when no privilege is required
    my $Access = 1;

    if ($RequiredPriv) {

        # get the required group for the frontend module
        my $Group = $ConfigObject->Get('Frontend::Module')->{ $Param{Config}->{Action} }
            ->{GroupRo}->[0];

        # deny access, when the group is not found
        return $Param{Counter} if !$Group;

        # get group object
        my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');

        # get the group id
        my $GroupID = $GroupObject->GroupLookup( Group => $Group );

        # deny access, when the group is not found
        return $Param{Counter} if !$GroupID;

        # get user groups, where the user has the appropriate privilege
        my %Groups = $GroupObject->GroupMemberList(
            UserID => $Self->{UserID},
            Type   => $RequiredPriv,
            Result => 'HASH',
        );

        # grant access if the agent has the appropriate type in the appropriate group
        if ( $Groups{$GroupID} ) {
            $Access = 1;
        }
    }

    return $Param{Counter} if !$Access;

    # build a lookup hash for the allowed change states
    my %AllowedChangeStates = map { $_ => 1 } @{ $FrontendConfig->{ChangeStates} };

    # only show the delete link for changes in the allowed change states
    return $Param{Counter} if !$AllowedChangeStates{ $Param{Change}->{ChangeState} };

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # output menu block
    $LayoutObject->Block( Name => 'Menu' );

    # output seperator, when this is not the first menu item
    if ( $Param{Counter} ) {
        $LayoutObject->Block( Name => 'MenuItemSplit' );
    }

    # output menu item
    $LayoutObject->Block(
        Name => 'MenuItem',
        Data => {
            %Param,
            %{ $Param{Change} },
            %{ $Param{Config} },
        },
    );

    # check if a dialog has to be shown
    if ( $Param{Config}->{DialogTitle} ) {
        my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
        my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

        my %JSData = (
            %Param,
            %{ $Param{Change} },
            %{ $Param{Config} },
        );

        delete $JSData{Config};
        delete $JSData{Change};

        $JSData{ElementSelector}            =~ s/\[%\s*Data\.MenuID\s*\|\s*html\s*%\]/$JSData{MenuID}/i;
        $JSData{DialogContentQueryString}   =~ s/\[%\s*Data\.ChangeID\s*\|\s*html\s*%\]/$JSData{ChangeID}/i;
        $JSData{ConfirmedActionQueryString} =~ s/\[%\s*Data\.ChangeID\s*\|\s*html\s*%\]/$JSData{ChangeID}/i;

        $JSData{DialogTitle} =~ s/\[%\s*Translate\("(.*)"\)\s*\|\s*html\s*%\]/$LanguageObject->Translate($1)/ei;
        $JSData{DialogTitle} =~ s/\[%\s*Config\("(.*)"\)\s*%\]/$ConfigObject->Get($1)/ei;
        $JSData{DialogTitle} =~ s/\[%\s*Data.ChangeNumber\s*\|\s*html\s*%\]/$JSData{ChangeNumber}/ei;

        $JSData{MenuID} = 'Menu' . $JSData{MenuID};

        $LayoutObject->AddJSData(
            Key   => 'ITSMShowConfirmDialog.' . $Param{MenuID},
            Value => \%JSData,
        );
    }

    $Param{Counter}++;

    return $Param{Counter};
}

1;
