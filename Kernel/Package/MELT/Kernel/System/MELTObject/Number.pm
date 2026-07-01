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

package Kernel::System::MELTObject::Number;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::MELTObject::Number - sub module of Kernel::System::MELTObject

=head1 DESCRIPTION

All MELT Object number functions.

=head1 PUBLIC INTERFACE

=head2 MELTIDLookup()

return MELT Object id or MELT Object number

    my $MELTID = $MELTObjectObject->MELTIDLookup(
        MELTObjectID => 123,
    );

    or

    my $MELTObjectID = $MELTObjectObject->MELTIDLookup(
        MELTID => '123454321',
    );

=cut

sub MELTIDLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{MELTObjectID} && !$Param{MELTID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need MELTObjectID or MELTID!',
        );
        return;
    }

    if ( $Param{MELTObjectID} ) {

        # check if result is already cached
        return $Self->{Cache}->{MELTIDLookup}->{ID}->{ $Param{MELTObjectID} }
            if $Self->{Cache}->{MELTIDLookup}->{ID}->{ $Param{MELTObjectID} };

        # ask database
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => 'SELECT meltid FROM melt_object_item WHERE id = ?',
            Bind  => [ \$Param{MELTObjectID} ],
            Limit => 1,
        );

        # fetch the result
        my $MELTID;
        while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
            $MELTID = $Row[0];
        }

        # cache the result
        $Self->{Cache}->{MELTIDLookup}->{ID}->{ $Param{MELTObjectID} } = $MELTID;

        return $MELTID;
    }

    # check if result is already cached
    return $Self->{Cache}->{MELTIDLookup}->{Number}->{ $Param{MELTID} }
        if $Self->{Cache}->{MELTIDLookup}->{Number}->{ $Param{MELTID} };

    # ask database
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => 'SELECT id FROM melt_object_item WHERE meltid = ?',
        Bind  => [ \$Param{MELTID} ],
        Limit => 1,
    );

    # fetch the result
    my $MELTObjectID;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $MELTObjectID = $Row[0];
    }

    # cache the result
    $Self->{Cache}->{MELTIDLookup}->{Number}->{ $Param{MELTID} } = $MELTObjectID;

    return $MELTObjectID;
}

=head2 MELTIDCreate()

create a new MELT Object number

    my $Number = $MELTObjectObject->MELTIDCreate(
        Type    => 'AutoIncrement',
        ClassID => 123,
    );

=cut

sub MELTIDCreate {
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
            Message  => "Can't load MELT Object number generator backend module $Param{Type}! $@",
        );
        return;
    }

    # load backend
    return if !$Kernel::OM->Get('Kernel::System::Main')->RequireBaseClass( $Param{Type} );

    # create number
    my $Number = $Self->_MELTIDCreate(%Param);

    return $Number;
}

=head2 CurrentCounterGet()

return the current counter of a class

    my $Counter = $MELTObjectObject->CurrentCounterGet(
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
        SQL => 'SELECT counter FROM melt_object_item_counter WHERE '
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

    my $True = $MELTObjectObject->CurrentCounterSet(
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
        SQL  => 'DELETE FROM melt_object_item_counter WHERE class_id = ?',
        Bind => [ \$Param{ClassID} ],
    );

    # set new counter
    $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO melt_object_item_counter '
            . '(class_id, counter_type, counter) VALUES (?, ?, ?)',
        Bind => [ \$Param{ClassID}, \$Param{Type}, \$Param{Counter} ],
    );

    return 1;
}

1;

