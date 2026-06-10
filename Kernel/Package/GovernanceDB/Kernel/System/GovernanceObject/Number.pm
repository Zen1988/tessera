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

package Kernel::System::GovernanceObject::Number;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::GovernanceObject::Number - sub module of Kernel::System::GovernanceObject

=head1 DESCRIPTION

All Governance Object number functions.

=head1 PUBLIC INTERFACE

=head2 GOIDLookup()

return Governance Object id or Governance Object number

    my $GOID = $GovernanceObjectObject->GOIDLookup(
        GovernanceObjectID => 123,
    );

    or

    my $GovernanceObjectID = $GovernanceObjectObject->GOIDLookup(
        GOID => '123454321',
    );

=cut

sub GOIDLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{GovernanceObjectID} && !$Param{GOID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need GovernanceObjectID or GOID!',
        );
        return;
    }

    if ( $Param{GovernanceObjectID} ) {

        # check if result is already cached
        return $Self->{Cache}->{GOIDLookup}->{ID}->{ $Param{GovernanceObjectID} }
            if $Self->{Cache}->{GOIDLookup}->{ID}->{ $Param{GovernanceObjectID} };

        # ask database
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => 'SELECT goid FROM governance_object_item WHERE id = ?',
            Bind  => [ \$Param{GovernanceObjectID} ],
            Limit => 1,
        );

        # fetch the result
        my $GOID;
        while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
            $GOID = $Row[0];
        }

        # cache the result
        $Self->{Cache}->{GOIDLookup}->{ID}->{ $Param{GovernanceObjectID} } = $GOID;

        return $GOID;
    }

    # check if result is already cached
    return $Self->{Cache}->{GOIDLookup}->{Number}->{ $Param{GOID} }
        if $Self->{Cache}->{GOIDLookup}->{Number}->{ $Param{GOID} };

    # ask database
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => 'SELECT id FROM governance_object_item WHERE goid = ?',
        Bind  => [ \$Param{GOID} ],
        Limit => 1,
    );

    # fetch the result
    my $GovernanceObjectID;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $GovernanceObjectID = $Row[0];
    }

    # cache the result
    $Self->{Cache}->{GOIDLookup}->{Number}->{ $Param{GOID} } = $GovernanceObjectID;

    return $GovernanceObjectID;
}

=head2 GOIDCreate()

create a new Governance Object number

    my $Number = $GovernanceObjectObject->GOIDCreate(
        Type    => 'AutoIncrement',
        ClassID => 123,
    );

=cut

sub GOIDCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Type ClassID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # load backend
    if ( !$Kernel::OM->Get('Kernel::System::Main')->Require( $Param{Type} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Can't load Governance Object number generator backend module $Param{Type}! $@",
        );
        return;
    }

    # load backend
    return if !$Kernel::OM->Get('Kernel::System::Main')->RequireBaseClass( $Param{Type} );

    # create number
    my $Number = $Self->_GOIDCreate(%Param);

    return $Number;
}

=head2 CurrentCounterGet()

return the current counter of a class

    my $Counter = $GovernanceObjectObject->CurrentCounterGet(
        ClassID => 123,
        Type    => 'AutoIncrement',
    );

=cut

sub CurrentCounterGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ClassID Type)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # ask the database
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => 'SELECT counter FROM governance_object_item_counter WHERE '
            . 'class_id = ? AND counter_type = ?',
        Bind  => [ \$Param{ClassID}, \$Param{Type} ],
        Limit => 1,
    );

    # fetch the result
    my $Number;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Number = $Row[0];
    }

    return $Number;
}

=head2 CurrentCounterSet()

set the current counter of a class

    my $True = $GovernanceObjectObject->CurrentCounterSet(
        ClassID => 123,
        Type    => 'AutoIncrement',
        Counter => '12',
    );

=cut

sub CurrentCounterSet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(ClassID Type Counter)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # delete old counter
    $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM governance_object_item_counter WHERE class_id = ?',
        Bind => [ \$Param{ClassID} ],
    );

    # set new counter
    $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO governance_object_item_counter '
            . '(class_id, counter_type, counter) VALUES (?, ?, ?)',
        Bind => [ \$Param{ClassID}, \$Param{Type}, \$Param{Counter} ],
    );

    return 1;
}

1;
