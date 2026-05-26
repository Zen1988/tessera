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

use Kernel::System::Type ();    ## no perlimports

package Kernel::System::Type;   ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;
use warnings;
use v5.24;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData);

our @ObjectDependencies = (
    'Kernel::System::Type',
    'Kernel::System::Valid',
);

sub ExportTypes {
    my ( $Self, %Param ) = @_;

    my %TypeFilter;
    if ( IsArrayRefWithData( $Param{Types} ) ) {
        %TypeFilter = map { $_ => 1 } $Param{Types}->@*;
    }

    # get necessary objects
    my $TypeObject  = $Kernel::OM->Get('Kernel::System::Type');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

    # fetch lookup lists
    my %TypeList = $TypeObject->TypeList(
        Valid => 0,
    );

    my %ExportData;
    TYPEID:
    for my $TypeID ( sort keys %TypeList ) {

        my %TypeData = $TypeObject->TypeGet(
            ID => $TypeID,
        );

        if (%TypeFilter) {
            next TYPEID unless $TypeFilter{ $TypeData{Name} };
        }

        # translate IDs into names or name-like identifiers
        ATTRIBUTE:
        for my $Attribute ( keys %TypeData ) {

            next ATTRIBUTE unless $Attribute =~ /ID/;

            if ( $Attribute eq 'ValidID' ) {
                my $Valid = $ValidObject->ValidLookup(
                    ValidID => $TypeData{ValidID},
                );
                $TypeData{Valid} = $Valid;
                delete $TypeData{ValidID};
            }
        }

        # delete unneeded attributes to avoid bloating the export
        delete $TypeData{ChangeBy};
        delete $TypeData{ChangeTime};
        delete $TypeData{CreateBy};
        delete $TypeData{CreateTime};
        delete $TypeData{ID};

        $ExportData{ $TypeData{Name} } = \%TypeData;
    }

    return \%ExportData;
}

sub ImportTypes {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    # get necessary objects
    my $TypeObject  = $Kernel::OM->Get('Kernel::System::Type');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

    # fetch lookup lists
    my %TypeList = $TypeObject->TypeList(
        Valid => 0,
    );
    my %TypeLookup = reverse %TypeList;

    TYPENAME:
    for my $TypeName ( keys $Param{Types}->%* ) {
        my $TypeData = $Param{Types}{$TypeName};

        my $TypeID = $TypeLookup{ $TypeData->{Name} };

        # skip if type with same name exists and overwrite is not set
        next TYPENAME if ( !$Param{OverwriteExistingEntities} && $TypeID );

        # translate named data back to IDs
        $TypeData->{ValidID} = $ValidObject->ValidLookup(
            Valid => $TypeData->{Valid},
        );

        # update
        if ($TypeID) {
            my $Success = $TypeObject->TypeUpdate(
                $TypeData->%*,
                ID     => $TypeID,
                UserID => $UserID,
            );
            return unless $Success;
        }

        # create
        else {
            my $TypeID = $TypeObject->TypeAdd(
                $TypeData->%*,
                UserID => $UserID,
            );
            return unless $TypeID;
        }
    }

    return 1;
}

1;
