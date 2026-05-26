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

## no critic (Modules::RequireExplicitPackage)

use Kernel::System::Group ();    ## no perlimports

package Kernel::System::Group;   ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;
use warnings;
use v5.24;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our @ObjectDependencies = (
    'Kernel::System::Group',
    'Kernel::System::Valid',
);

sub ExportGroups {
    my ( $Self, %Param ) = @_;

    my %GroupFilter;
    if ( IsArrayRefWithData( $Param{Groups} ) ) {
        %GroupFilter = map { $_ => 1 } $Param{Groups}->@*;
    }

    # get necessary objects
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

    # fetch lookup lists
    my %GroupList = $GroupObject->GroupList(
        Valid => 0,
    );

    my %ExportData;
    GROUPID:
    for my $GroupID ( sort keys %GroupList ) {

        my %GroupData = $GroupObject->GroupGet(
            ID => $GroupID,
        );

        if (%GroupFilter) {
            next GROUPID unless $GroupFilter{ $GroupData{Name} };
        }

        # translate IDs into names or name-like identifiers
        ATTRIBUTE:
        for my $Attribute ( keys %GroupData ) {

            next ATTRIBUTE unless $Attribute =~ /ID/;

            # single-value attributes
            if ( $Attribute eq 'ValidID' ) {
                my $Valid = $ValidObject->ValidLookup(
                    ValidID => $GroupData{ValidID},
                );
                $GroupData{Valid} = $Valid;
                delete $GroupData{ValidID};
            }
        }

        # delete unneeded attributes to avoid bloating the export
        delete $GroupData{ChangeBy};
        delete $GroupData{ChangeTime};
        delete $GroupData{CreateBy};
        delete $GroupData{CreateTime};
        delete $GroupData{ID};

        $ExportData{ $GroupData{Name} } = \%GroupData;
    }

    return \%ExportData;
}

sub ImportGroups {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    # get necessary objects
    my $GroupObject = $Kernel::OM->Get('Kernel::System::Group');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

    # fetch lookup lists
    my %GroupList = $GroupObject->GroupList(
        Valid => 0,
    );
    my %GroupLookup = reverse %GroupList;

    GROUPNAME:
    for my $GroupName ( keys $Param{Groups}->%* ) {
        my $GroupData = $Param{Groups}{$GroupName};

        my $GroupID = $GroupLookup{ $GroupData->{Name} };

        # skip if group with same name exists and overwrite is not set
        next GROUPNAME if ( !$Param{OverwriteExistingEntities} && $GroupID );

        # translate named data back to IDs
        # single-value attributes
        $GroupData->{ValidID} = $ValidObject->ValidLookup(
            Valid => $GroupData->{Valid},
        );

        # update
        if ($GroupID) {
            my $Success = $GroupObject->GroupUpdate(
                $GroupData->%*,
                ID     => $GroupID,
                UserID => $UserID,
            );
            return unless $Success;
        }

        # create
        else {
            my $GroupID = $GroupObject->GroupAdd(
                $GroupData->%*,
                UserID => $UserID,
            );
            return unless $GroupID;
        }
    }

    return 1;
}

1;
