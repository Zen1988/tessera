# --
# Copyright (C) 2026 TESSERA
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# --

package Kernel::System::GovernanceDB::Number::GOID;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::GovernanceDB::Number::GOID - Governance Object ID generator.

=head1 DESCRIPTION

Creates GOIDs for GovernanceDB records. GOID replaces the ITSM ConfigItem number
concept for governance objects.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

=head2 GOIDCreate()

    my $GOID = $GOIDObject->GOIDCreate(
        Class  => 'BlueBook',
        UserID => 1,
    );

=cut

sub GOIDCreate {
    my ( $Self, %Param ) = @_;

    my $Class = $Param{Class} || 'GO';
    $Class =~ s{[^A-Za-z0-9]}{}g;
    $Class = uc substr( $Class || 'GO', 0, 8 );

    my $CounterKey = 'GOID::' . $Class;
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');

    my $Counter;
    return if !$DBObject->Prepare(
        SQL  => 'SELECT counter_value FROM governance_object_counter WHERE counter_key = ?',
        Bind => [ \$CounterKey ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Counter = $Row[0];
    }

    if ( defined $Counter ) {
        $Counter++;
        return if !$DBObject->Do(
            SQL  => 'UPDATE governance_object_counter SET counter_value = ? WHERE counter_key = ?',
            Bind => [ \$Counter, \$CounterKey ],
        );
    }
    else {
        $Counter = 1;
        return if !$DBObject->Do(
            SQL  => 'INSERT INTO governance_object_counter (counter_key, counter_value) VALUES (?, ?)',
            Bind => [ \$CounterKey, \$Counter ],
        );
    }

    return sprintf 'GO-%s-%08d', $Class, $Counter;
}

1;
