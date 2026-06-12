# --
# Copyright (C) 2026 TESSERA
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# --

package Kernel::System::GovernanceObject::Number::GOID;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::GovernanceObject::Number::GOID - Governance Object GOID backend module

=head1 DESCRIPTION

Creates human-readable Governance Object identifiers from the class name.

=head2 _GOIDCreate()

    my $Number = $BackendObject->_GOIDCreate(
        ClassID => 123,
    );

=cut

sub _GOIDCreate {
    my ( $Self, %Param ) = @_;

    if ( !$Param{ClassID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ClassID!',
        );
        return;
    }

    my $Class = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
        ItemID => $Param{ClassID},
    );

    my $ClassName = $Class->{Name} || 'GO';
    $ClassName =~ s{[^A-Za-z0-9]}{}g;
    $ClassName = uc substr( $ClassName || 'GO', 0, 8 );

    my $CounterKey = 'GOID::' . $ClassName;
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

    return sprintf 'GO-%s-%08d', $ClassName, $Counter;
}

1;
