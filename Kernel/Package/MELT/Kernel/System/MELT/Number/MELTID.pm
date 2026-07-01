# --
# Copyright (C) 2026 TESSERA
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# --

package Kernel::System::MELT::Number::MELTID;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::MELT::Number::MELTID - MELT Object ID generator.

=head1 DESCRIPTION

Creates MELTIDs for MELT records. MELTID replaces the ITSM ConfigItem number
concept for MELT objects.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

=head2 MELTIDCreate()

    my $MELTID = $MELTIDObject->MELTIDCreate(
        Class  => 'BlueBook',
        UserID => 1,
    );

=cut

sub MELTIDCreate {
    my ( $Self, %Param ) = @_;

    my $Class = $Param{Class} || 'GO';
    $Class =~ s{[^A-Za-z0-9]}{}g;
    $Class = uc substr( $Class || 'GO', 0, 8 );

    my $CounterKey = 'MELTID::' . $Class;
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');

    my $Counter;
    return if !$DBObject->Prepare(
        SQL  => 'SELECT counter_value FROM melt_object_counter WHERE counter_key = ?',
        Bind => [ \$CounterKey ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Counter = $Row[0];
    }

    if ( defined $Counter ) {
        $Counter++;
        return if !$DBObject->Do(
            SQL  => 'UPDATE melt_object_counter SET counter_value = ? WHERE counter_key = ?',
            Bind => [ \$Counter, \$CounterKey ],
        );
    }
    else {
        $Counter = 1;
        return if !$DBObject->Do(
            SQL  => 'INSERT INTO melt_object_counter (counter_key, counter_value) VALUES (?, ?)',
            Bind => [ \$CounterKey, \$Counter ],
        );
    }

    return sprintf 'GO-%s-%08d', $Class, $Counter;
}

1;

