# --
# Copyright (C) 2026 TESSERA
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# --

package Kernel::System::DynamicField::ObjectType::GovernanceObject;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::DynamicField::ObjectType::GovernanceObject - DynamicField object handler for GovernanceDB records.

=head1 DESCRIPTION

Registers GovernanceDB records as a DynamicField object type. GovernanceDB keeps
ZTSM governance fields separate from ITSM ConfigItem operational fields.

=cut

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

=head2 PostValueSet()

Updates the GovernanceDB object timestamp after a dynamic field value is stored.

=cut

sub PostValueSet {
    my ( $Self, %Param ) = @_;

    for my $Needed (qw(DynamicFieldConfig ObjectID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    return if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => '
            UPDATE governance_object
            SET change_time = current_timestamp, change_by = ?
            WHERE id = ?',
        Bind => [ \$Param{UserID}, \$Param{ObjectID} ],
    );

    return 1;
}

1;
