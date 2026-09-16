# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::System::GovernanceObject::Number::AutoIncrement;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::GovernanceObject::Number::AutoIncrement - Governance Object number backend module

=head1 DESCRIPTION

All auto increment Governance Object number functions

=head2 _GOIDCreate()

create a new Governance Object number

    my $Number = $BackendObject->_GOIDCreate(
        ClassID => 123,
    );

=cut

sub _GOIDCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ClassID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ClassID!',
        );
        return;
    }

    # get system id
    my $SystemID = $Kernel::OM->Get('Kernel::Config')->Get('SystemID');

    # get current counter
    my $CurrentCounter = $Self->CurrentCounterGet(
        ClassID => $Param{ClassID},
        Type    => 'AutoIncrement',
    ) || 0;

    CIPHER:
    for my $Cipher ( 1 .. 1_000_000_000 ) {

        # create new number
        my $Number = $SystemID . $Param{ClassID} . sprintf( "%06d", ( $CurrentCounter + $Cipher ) );

        # find existing number
        my $Duplicate = $Self->GOIDLookup(
            GOID => $Number,
        );

        next CIPHER if $Duplicate;

        # set counter
        $Self->CurrentCounterSet(
            ClassID => $Param{ClassID},
            Type    => 'AutoIncrement',
            Counter => ( $CurrentCounter + $Cipher ),
        );

        return $Number;
    }

    return;
}

1;
