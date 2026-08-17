# --
# Copyright (C) 2026 TESSERA
# --

package Kernel::System::TESSERA::MELTCrossObjectRecovery;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicFieldValue',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub Run {
    my ($Self) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldValue  = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');
    my $GovernanceObject   = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $DBObject           = $Kernel::OM->Get('Kernel::System::DB');

    my @RecoveryFields = qw(
        ZBlue-Profile
        ZBlue-PurpleBook
        ZBlue-Role
        ZBlue-Template
        ZState-Book
    );

    my ( $RecoveredObjects, $SkippedObjects ) = ( 0, 0 );

    FIELD:
    for my $FieldName (@RecoveryFields) {
        my $Target = $DynamicFieldObject->DynamicFieldGet( Name => $FieldName );
        my $Source = $DynamicFieldObject->DynamicFieldGet( Name => $FieldName . 'Old' );

        if (
            !$Target
            || !$Source
            || ( $Target->{ObjectType} || '' ) ne 'GovernanceObject'
            || ( $Source->{ObjectType} || '' ) ne 'MELTObject'
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'notice',
                Message  => "TESSERA MELT recovery skipped $FieldName because its current/*Old field pair is missing or has an unexpected object type.",
            );
            next FIELD;
        }

        if (
            !$DBObject->Prepare(
                SQL  => 'SELECT DISTINCT object_id FROM dynamic_field_value WHERE field_id = ?',
                Bind => [ \$Source->{ID} ],
            )
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "TESSERA MELT recovery could not enumerate preserved values for $FieldName.",
            );
            $SkippedObjects++;
            next FIELD;
        }

        my @ObjectIDs;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            push @ObjectIDs, $Row[0] if $Row[0];
        }

        OBJECT:
        for my $ObjectID (@ObjectIDs) {
            my $GovernanceVersion = $GovernanceObject->GovernanceObjectGet(
                VersionID     => $ObjectID,
                DynamicFields => 0,
                Silent        => 1,
            );
            if ( !$GovernanceVersion || !$GovernanceVersion->{GovernanceObjectID} ) {
                $SkippedObjects++;
                next OBJECT;
            }

            my $Existing = $DynamicFieldValue->ValueGet(
                FieldID  => $Target->{ID},
                ObjectID => $ObjectID,
            ) || [];
            next OBJECT if @{$Existing};

            my $OldValues = $DynamicFieldValue->ValueGet(
                FieldID  => $Source->{ID},
                ObjectID => $ObjectID,
            ) || [];
            next OBJECT if !@{$OldValues};

            my $ClassIDs = $Target->{Config}{ClassIDs};
            $ClassIDs = [] if ref $ClassIDs ne 'ARRAY';
            my %AllowedClassID = map { $_ => 1 }
                grep { defined $_ && $_ =~ m{\A\d+\z} }
                @{$ClassIDs};

            my @Values;
            for my $OldValue ( @{$OldValues} ) {
                my $ValueInt = $OldValue->{ValueInt};
                if ( defined $ValueInt && $ValueInt ne '' ) {
                    my $Referenced = $GovernanceObject->GovernanceObjectGet(
                        GovernanceObjectID => $ValueInt,
                        DynamicFields      => 0,
                        Silent             => 1,
                    );
                    if (
                        !$Referenced
                        || !$Referenced->{GovernanceObjectID}
                        || ( %AllowedClassID && !$AllowedClassID{ $Referenced->{ClassID} || '' } )
                        )
                    {
                        $SkippedObjects++;
                        next OBJECT;
                    }
                }

                push @Values, {
                    ValueText     => $OldValue->{ValueText},
                    ValueInt      => $OldValue->{ValueInt},
                    ValueDateTime => $OldValue->{ValueDateTime},
                    IndexValue    => $OldValue->{IndexValue},
                    IndexSet      => $OldValue->{IndexSet},
                };
            }
            next OBJECT if !@Values;

            my $Success = $DynamicFieldValue->ValueSet(
                FieldID  => $Target->{ID},
                ObjectID => $ObjectID,
                Value    => \@Values,
                UserID   => 1,
            );
            $Success ? $RecoveredObjects++ : $SkippedObjects++;
        }
    }

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => $SkippedObjects ? 'notice' : 'info',
        Message  => "TESSERA MELT one-time recovery restored $RecoveredObjects object field value(s); "
            . "$SkippedObjects ambiguous or invalid value(s) were preserved in *Old fields and skipped.",
    );

    return 1;
}

1;

