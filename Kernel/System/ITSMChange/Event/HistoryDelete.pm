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

package Kernel::System::ITSMChange::Event::HistoryDelete;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::ITSMChange::History',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Data Event Config UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # handle deletion of a change
    if ( $Param{Event} eq 'ChangeDeletePost' ) {

        # delete history of change
        my $Success = $Kernel::OM->Get('Kernel::System::ITSMChange::History')->ChangeHistoryDelete(
            ChangeID => $Param{Data}->{ChangeID},
            UserID   => $Param{UserID},
        );

        # handle error
        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "ChangeDelete() failed for ChangeID '$Param{Data}->{ChangeID}'!",
            );
            return;
        }

        return 1;
    }

    # error
    else {

        # an unknown event
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "$Param{Event} is an unknown event!",
        );

        return;
    }

    return 1;
}

1;
