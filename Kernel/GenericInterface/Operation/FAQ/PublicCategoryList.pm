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

package Kernel::GenericInterface::Operation::FAQ::PublicCategoryList;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

use parent qw(
    Kernel::GenericInterface::Operation::Common
);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::GenericInterface::Operation::FAQ::PublicCategoryList - GenericInterface FAQ PublicCategoryList Operation backend

=head1 PUBLIC INTERFACE

=head2 new()

usually, you want to create an instance of this
by using Kernel::GenericInterface::Operation->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw( DebuggerObject WebserviceID )) {
        if ( !$Param{$Needed} ) {

            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!"
            };
        }

        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

=head2 Run()

perform PublicCategoryList Operation. This will return the current FAQ Categories.

    my $Result = $OperationObject->Run(
        Data => {},
    );

    $Result = {
        Success      => 1,                                # 0 or 1
        ErrorMessage => '',                               # In case of an error
        Data         => {                                 # result data payload after Operation
            Category => [
                {
                    ID => 1,
                    Name> 'Misc',
                },
                {
                    ID => 2,
                    Name> 'OneMoreCategory',
                },
                # ...
            ],
        },
    };

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # Set UserID to root because in public interface there is no user.
    my $CategoryTree = $Kernel::OM->Get('Kernel::System::FAQ')->GetPublicCategoriesLongNames(
        Valid  => 1,
        Type   => 'rw',
        UserID => 1,
    );

    if ( !IsHashRefWithData($CategoryTree) ) {

        my $ErrorMessage = 'Could not get category data'
            . ' in Kernel::GenericInterface::Operation::FAQ::PublicCategoryList::Run()';

        return $Self->ReturnError(
            ErrorCode    => 'PublicCategoryList.NotCategoryData',
            ErrorMessage => "PublicCategoryList: $ErrorMessage",
        );

    }

    my @PublicCategoryList;
    for my $Key ( sort( keys %{$CategoryTree} ) ) {
        my %Category = (
            ID   => $Key,
            Name => $CategoryTree->{$Key},
        );
        push @PublicCategoryList, {%Category};
    }

    # Prepare return data.
    my $ReturnData = {
        Success => 1,
        Data    => {},
    };
    if ( scalar @PublicCategoryList > 1 ) {
        $ReturnData->{Data}->{Category} = \@PublicCategoryList;
    }
    else {
        $ReturnData->{Data}->{Category} = $PublicCategoryList[0];
    }

    return $ReturnData;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTOBO project (L<https://otobo.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
