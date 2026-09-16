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

package Kernel::Output::HTML::ITSMWorkOrder::MenuWithPermissionFromChange;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::ITSMChange',
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
    if ( !$Param{WorkOrder} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need WorkOrder!',
        );
        return;
    }

    # get config for the relevant action
    my $FrontendConfig = $Kernel::OM->Get('Kernel::Config')->Get("ITSMWorkOrder::Frontend::$Param{Config}->{Action}");

    # get the required privilege, 'ro' or 'rw'
    my $RequiredPriv;
    if ($FrontendConfig) {

        # get the required priv from the frontend configuration
        $RequiredPriv = $FrontendConfig->{Permission};
    }

    # get change object
    my $ChangeObject = $Kernel::OM->Get('Kernel::System::ITSMChange');

    my $Access;
    if ( !$RequiredPriv ) {

        # Display the menu-link, when no privilege is required
        $Access = 1;
    }
    else {

        # check permissions, based on the required privilege
        $Access = $ChangeObject->Permission(
            Type        => $RequiredPriv,
            Action      => $Param{Config}->{Action},
            ChangeID    => $Param{WorkOrder}->{ChangeID},
            WorkOrderID => $Param{WorkOrder}->{WorkOrderID},
            UserID      => $Self->{UserID},
            LogNo       => 1,
        );
    }

    return $Param{Counter} if !$Access;

    # get the change data
    my $Change = $ChangeObject->ChangeGet(
        ChangeID => $Param{WorkOrder}->{ChangeID},
        UserID   => $Self->{UserID},
    );

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # output menu block
    $LayoutObject->Block( Name => 'Menu' );

    # output menu item
    $LayoutObject->Block(
        Name => 'MenuItem',
        Data => {
            %Param,
            %{$Change},
            %{ $Param{WorkOrder} },
            %{ $Param{Config} },
        },
    );

    # check if a dialog has to be shown
    if ( $Param{Config}->{DialogTitle} ) {
        my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');
        my $LanguageObject = $Kernel::OM->Get('Kernel::Language');

        # Replace the template toolkit expressions with the final value.
        my %JSData = (
            %Param,
            %{ $Param{WorkOrder} },
            %{ $Param{Config} },
        );

        delete $JSData{Config};
        delete $JSData{WorkOrder};

        $JSData{ElementSelector}            =~ s/\[%\s*Data\.MenuID\s*\|\s*html\s*%\]/$JSData{MenuID}/i;
        $JSData{DialogContentQueryString}   =~ s/\[%\s*Data\.WorkOrderID\s*\|\s*html\s*%\]/$JSData{WorkOrderID}/i;
        $JSData{ConfirmedActionQueryString} =~ s/\[%\s*Data\.WorkOrderID\s*\|\s*html\s*%\]/$JSData{WorkOrderID}/i;

        $JSData{DialogTitle} =~ s/\[%\s*Translate\("(.*)"\)\s*\|\s*html\s*%\]/$LanguageObject->Translate($1)/ei;
        $JSData{DialogTitle} =~ s/\[%\s*Config\("(.*)"\)\s*%\]/$ConfigObject->Get($1)/ei;
        $JSData{DialogTitle} =~ s/\[%\s*Data.ChangeNumber\s*\|\s*html\s*%\]/$JSData{ChangeNumber}/ei;
        $JSData{DialogTitle} =~ s/\[%\s*Data.WorkOrderNumber\s*\|\s*html\s*%\]/$JSData{WorkOrderNumber}/ei;

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
