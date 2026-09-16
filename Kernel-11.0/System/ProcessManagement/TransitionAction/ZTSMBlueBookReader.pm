# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);
use Kernel::System::ZTSMBlueBookRuntime ();

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Ticket',
    'Kernel::System::Type',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        $Value = $Value->[0];
    }

    if ( ref $Value eq 'HASH' ) {
        for my $Key (qw(Key Value Content GovernanceObjectID ObjectID ID ItemID SelectedID SelectedValue)) {
            return $Value->{$Key} if defined $Value->{$Key} && $Value->{$Key} ne '';
        }
        return undef;
    }

    return $Value;
}

sub _TicketOnHold {
    my ($Ticket) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';
    return 1 if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    return 1 if lc( $Ticket->{State} || '' ) eq 'onhold';

    return;
}

sub _TicketSummary {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};

    if ( !$Ticket && $Param{TicketID} ) {
        my %TicketData = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID => $Param{TicketID},
            UserID   => 1,
            Silent   => 1,
        );
        $Ticket = \%TicketData if %TicketData;
    }

    return 'N/A' if !$Ticket || ref $Ticket ne 'HASH';

    my $TicketNumber = $Ticket->{TicketNumber} || '';
    my $TicketID     = $Ticket->{TicketID}     || $Param{TicketID} || '';
    my $Type         = $Ticket->{Type}         || 'Ticket';
    my $Title        = $Ticket->{Title}        || '';

    my $Label = $TicketNumber ? "Ticket#$TicketNumber" : "TicketID#$TicketID";
    $Label .= " (ID $TicketID)" if $TicketNumber && $TicketID;
    $Label .= " - $Type" if $Type;
    $Label .= ": $Title" if $Title;

    return $Label;
}

sub _RecordValueGet {
    my (%Param) = @_;

    my $Record = $Param{Record};

    return undef if !$Record || ref $Record ne 'HASH';

    FIELD:
    for my $Field ( @{ $Param{Fields} || [] } ) {
        my $StructuredValue = _RecordStructuredFieldValue(
            Record => $Record,
            Field  => $Field,
        );
        return $StructuredValue if defined $StructuredValue && $StructuredValue ne '';

        next FIELD if !exists $Record->{$Field};

        my $Value = $Record->{$Field};

        $Value = _NormalizeValue($Value);

        return $Value if defined $Value && $Value ne '';
    }

    return undef;
}

sub _RecordStructuredFieldValue {
    my (%Param) = @_;

    my $Record = $Param{Record};
    my $Field  = $Param{Field};
    return undef if !$Record || ref $Record ne 'HASH';
    return undef if !$Field;

    if ( ( $Record->{DF} || '' ) eq $Field ) {
        my $Value;
        FIELDVALUE:
        for my $Key (qw(Value Content Key GovernanceObjectID ObjectID ID ItemID SelectedID SelectedValue)) {
            next FIELDVALUE if !exists $Record->{$Key};
            $Value = $Record->{$Key};
            last FIELDVALUE;
        }
        $Value = _NormalizeValue($Value);
        return $Value if defined $Value && $Value ne '';
    }

    for my $ContainerKey (qw(Fields Items Values Content Value)) {
        my $Container = $Record->{$ContainerKey};
        next if ref $Container ne 'ARRAY';

        ITEM:
        for my $Item ( @{$Container} ) {
            next ITEM if ref $Item ne 'HASH';

            my $Value = _RecordStructuredFieldValue(
                Record => $Item,
                Field  => $Field,
            );
            return $Value if defined $Value && $Value ne '';
        }
    }

    return undef;
}

sub _TicketTypeResolve {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

    if ( $Value !~ m{\A\d+\z} ) {
        my $TypeID = $TypeObject->TypeLookup(
            Type => $Value,
        );

        return $Value if $TypeID;
    }

    FIELDNAME:
    for my $FieldName (qw(ZBlue-Type ZBlue-TicketType)) {
        my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $FieldName,
        );

        next FIELDNAME if !$DynamicFieldConfig;

        my $DisplayValue;

        my $GeneralCatalogClass = $DynamicFieldConfig->{Config}->{Class}
            || ( $FieldName eq 'ZBlue-TicketType' ? 'ZTSM::Type' : undef );

        if (
            ( $DynamicFieldConfig->{FieldType} || '' ) eq 'GeneralCatalog'
            && $GeneralCatalogClass
            )
        {
            my $PossibleValues = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                Class => $GeneralCatalogClass,
            );

            $DisplayValue = $PossibleValues->{$Value}
                if $PossibleValues;
        }

        if ( !$DisplayValue && $DynamicFieldConfig->{ID} ) {
            $DisplayValue = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueLookup(
                DynamicFieldConfig => $DynamicFieldConfig,
                Key                => $Value,
            );
        }

        next FIELDNAME if !$DisplayValue;
        next FIELDNAME if $DisplayValue eq $Value;

        my $TypeID = $TypeObject->TypeLookup(
            Type => $DisplayValue,
        );

        return $DisplayValue if $TypeID;
    }

    return;
}

sub _GeneralCatalogDynamicFieldValueResolve {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );
    return if !defined $Value;
    return if $Value eq '';

    FIELDNAME:
    for my $FieldName ( @{ $Param{FieldNames} || [] } ) {
        my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $FieldName,
        );
        next FIELDNAME if !$DynamicFieldConfig;
        next FIELDNAME if ( $DynamicFieldConfig->{FieldType} || '' ) ne 'GeneralCatalog';

        if ( $Value =~ m{\A\d+\z} ) {
            my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
                ItemID => $Value,
            );
            return $Item->{Name} if $Item && $Item->{Name};
        }

        next FIELDNAME if !$DynamicFieldConfig->{ID};

        my $DisplayValue = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueLookup(
            DynamicFieldConfig => $DynamicFieldConfig,
            Key                => $Value,
        );
        return $DisplayValue if defined $DisplayValue && $DisplayValue ne '';
    }

    return $Value;
}

sub _GovernanceObjectDynamicFieldValueResolve {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );
    return if !defined $Value;
    return if $Value eq '';
    return $Value if $Value =~ m{\A\d+\z};

    FIELDNAME:
    for my $FieldName ( @{ $Param{FieldNames} || [] } ) {
        my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $FieldName,
        );
        next FIELDNAME if !$DynamicFieldConfig;
        next FIELDNAME if ( $DynamicFieldConfig->{FieldType} || '' ) ne 'GovernanceObject';

        my %Search = (
            Result => 'ARRAY',
            Name   => $Value,
            Limit  => 2,
            UserID => 1,
        );

        my @ClassIDs;
        my @Classes;
        for my $Class ( @{ $DynamicFieldConfig->{Config}->{ClassIDs} || [] } ) {
            next if !defined $Class || $Class eq '';
            if ( $Class =~ m{\A\d+\z} ) {
                push @ClassIDs, $Class;
            }
            else {
                push @Classes, $Class;
            }
        }

        $Search{ClassIDs} = \@ClassIDs if @ClassIDs;
        $Search{Classes}  = \@Classes  if @Classes;

        my @GovernanceObjectIDs = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectSearch(%Search);
        return $GovernanceObjectIDs[0] if @GovernanceObjectIDs == 1;

        delete $Search{Name};
        $Search{Number} = $Value;
        @GovernanceObjectIDs = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectSearch(%Search);
        return $GovernanceObjectIDs[0] if @GovernanceObjectIDs == 1;
    }

    return $Value;
}

sub _TicketFieldSet {
    my (%Param) = @_;

    return if !$Param{TicketID};
    return if !$Param{FieldName};

    my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => $Param{FieldName},
    );

    return if !$DynamicFieldConfig;
    return if !$DynamicFieldConfig->{ID};
    return if $DynamicFieldConfig->{ObjectType} && $DynamicFieldConfig->{ObjectType} ne 'Ticket';

    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID} || 1,
    );
}

sub _TicketIteration {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return undef if !$Ticket || ref $Ticket ne 'HASH';

    my $Iteration = _NormalizeValue( $Ticket->{'DynamicField_ZIN-Iteration'} );
    return $Iteration;
}

sub _SupportProfileResolve {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my %Search = (
        Result  => 'ARRAY',
        Classes => ['SupportProfile'],
        Limit   => 1,
        UserID  => $Param{UserID} || 1,
    );

    if ( $Value =~ m{\A\d+\z} ) {
        $Search{GovernanceObjectID} = [$Value];
    }
    else {
        $Search{Name} = $Value;
    }

    my @SupportProfileIDs = $GovernanceObjectObject->GovernanceObjectSearch(%Search);

    return if !@SupportProfileIDs;

    return $SupportProfileIDs[0];
}

sub _GovernanceObjectReferenceValues {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my %Reference = ( $Value => 1 );
    my @GovernanceObjects;

    if ( $Value =~ m{\A\d+\z} ) {
        for my $Lookup (
            { GovernanceObjectID => $Value },
            { VersionID          => $Value },
            )
        {
            my $GovernanceObject = eval {
                $GovernanceObjectObject->GovernanceObjectGet(
                    %{$Lookup},
                    DynamicFields => 0,
                    Silent        => 1,
                );
            };
            push @GovernanceObjects, $GovernanceObject if $GovernanceObject && ref $GovernanceObject eq 'HASH';
        }
    }
    elsif ( $Param{Class} ) {
        my @GovernanceObjectIDs = $GovernanceObjectObject->GovernanceObjectSearch(
            Result  => 'ARRAY',
            Classes => [ $Param{Class} ],
            Name    => $Value,
            Limit   => 10,
            UserID  => $Param{UserID} || 1,
        );

        for my $GovernanceObjectID (@GovernanceObjectIDs) {
            my $GovernanceObject = eval {
                $GovernanceObjectObject->GovernanceObjectGet(
                    GovernanceObjectID => $GovernanceObjectID,
                    DynamicFields      => 0,
                    Silent             => 1,
                );
            };
            push @GovernanceObjects, $GovernanceObject if $GovernanceObject && ref $GovernanceObject eq 'HASH';
        }
    }

    for my $GovernanceObject (@GovernanceObjects) {
        if ( $Param{Class} && ( $GovernanceObject->{Class} || '' ) ne $Param{Class} ) {
            next;
        }

        $Reference{ $GovernanceObject->{GovernanceObjectID} } = 1 if $GovernanceObject->{GovernanceObjectID};
        $Reference{ $GovernanceObject->{LastVersionID} }      = 1 if $GovernanceObject->{LastVersionID};
        $Reference{ $GovernanceObject->{VersionID} }          = 1 if $GovernanceObject->{VersionID};
        $Reference{ $GovernanceObject->{Name} }               = 1 if $GovernanceObject->{Name};
    }

    return sort grep { defined $_ && $_ ne '' } keys %Reference;
}

sub _SupportProfileByRoleResolve {
    my (%Param) = @_;

    my @RoleReferences = grep { defined $_ && $_ =~ m{\A\d+\z} } _GovernanceObjectReferenceValues(
        Value  => $Param{Role},
        Class  => 'GovernanceRole',
        UserID => $Param{UserID},
    );

    return if !@RoleReferences;

    my @ApplicationReferences = grep { defined $_ && $_ =~ m{\A\d+\z} } _GovernanceObjectReferenceValues(
        Value  => $Param{ApplicationID},
        Class  => 'Application',
        UserID => $Param{UserID},
    );

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %AssignmentID;

    ROLE:
    for my $RoleReference (@RoleReferences) {
        next ROLE if !defined $RoleReference || $RoleReference eq '';

        my %BaseSearch = (
            Classes => ['SupportAssignment'],
            'DynamicField_ZTSMSupportAssignment-Role' => {
                Equals => $RoleReference,
            },
            Result => 'ARRAY',
            Limit  => 1000,
            UserID => $Param{UserID} || 1,
        );

        for my $ApplicationReference (@ApplicationReferences) {
            next if !defined $ApplicationReference || $ApplicationReference eq '';

            my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
                %BaseSearch,
                'DynamicField_ZTSMSupportAssignment-Application' => {
                    Equals => $ApplicationReference,
                },
            );
            $AssignmentID{$_} = 1 for @FoundAssignmentIDs;
        }

        if ( !%AssignmentID ) {
            my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(%BaseSearch);
            $AssignmentID{$_} = 1 for @FoundAssignmentIDs;
        }
    }

    ASSIGNMENT:
    for my $AssignmentID ( sort { $a <=> $b } keys %AssignmentID ) {
        my $Assignment = eval {
            $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $AssignmentID,
                DynamicFields      => 1,
                Silent             => 1,
            );
        };

        next ASSIGNMENT if !$Assignment || ref $Assignment ne 'HASH';

        my $SupportProfile = _NormalizeValue(
            $Assignment->{'DynamicField_ZTSMSupportAssignment-SupportProfile'}
                || $Assignment->{XMLData}
                && $Assignment->{XMLData}->{'ZTSMSupportAssignment-SupportProfile'}
                && $Assignment->{XMLData}->{'ZTSMSupportAssignment-SupportProfile'}->{Content}
        );

        next ASSIGNMENT if !defined $SupportProfile || $SupportProfile eq '';

        return _SupportProfileResolve(
            Value  => $SupportProfile,
            UserID => $Param{UserID},
        ) || $SupportProfile;
    }

    return;
}

sub _RecordIsDiagnosis {
    my (%Param) = @_;

    my $Record = $Param{Record};
    return if !$Record || ref $Record ne 'HASH';

    my $Type = _NormalizeValue( $Record->{Type} );
    return 1 if defined $Type && lc $Type eq 'diagnosis';

    for my $RoleReference (
        _GovernanceObjectReferenceValues(
            Value  => $Record->{Role},
            Class  => 'GovernanceRole',
            UserID => $Param{UserID},
        )
        )
    {
        return 1 if defined $RoleReference && lc $RoleReference eq 'diagnose';
    }

    return;
}

sub _DiagnosisNoActionTicket {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return if !$Ticket || ref $Ticket ne 'HASH';

    my $StateValue = _NormalizeValue( $Ticket->{State} );
    my $State      = defined $StateValue ? lc $StateValue : '';
    return 1 if $State eq 'closed no action';

    my $TicketOutcomeValue = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Outcome'} );
    my $TicketOutcome      = defined $TicketOutcomeValue ? lc $TicketOutcomeValue : '';
    return 1 if $TicketOutcome eq '1';

    my $DiagnosisOutcomeValue = _NormalizeValue( $Ticket->{'DynamicField_ZIN-Outcome'} );
    my $DiagnosisOutcome      = defined $DiagnosisOutcomeValue ? lc $DiagnosisOutcomeValue : '';
    return 1 if $DiagnosisOutcome =~ m{\A(?:recovered|not applicable)\z};

    return;
}

sub _ExistingDiagnosisChapterPlayForRecord {
    my (%Param) = @_;

    return if !_RecordIsDiagnosis( Record => $Param{Record}, UserID => $Param{UserID} );

    my $Iteration = _NormalizeValue( $Param{Iteration} );
    my @Iterations;

    if ( defined $Iteration && $Iteration ne '' ) {
        push @Iterations, $Iteration;
    }

    push @Iterations, undef if !@Iterations;

    my $Chapter = _NormalizeValue( $Param{Record}->{Chapter} );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    ITERATION:
    for my $CandidateIteration (@Iterations) {
        my %Search = (
            Result => 'ARRAY',
            'DynamicField_ZTicket-Parent' => {
                Equals => $Param{ParentTicketID},
            },
            'DynamicField_ZTicket-BlueBook' => {
                Equals => $Param{BlueBookID},
            },
            'DynamicField_ZTicket-BlueLevel' => {
                Equals => $Param{BlueLevel},
            },
            UserID => $Param{UserID} || 1,
        );

        if ( defined $Chapter && $Chapter ne '' ) {
            $Search{'DynamicField_ZTicket-Chapter'} = {
                Equals => $Chapter,
            };
        }

        if ( defined $CandidateIteration && $CandidateIteration ne '' ) {
            $Search{'DynamicField_ZIN-Iteration'} = {
                Equals => $CandidateIteration,
            };
        }

        my @TicketIDs = sort { $b <=> $a } $TicketObject->TicketSearch(%Search);
        next ITERATION if !@TicketIDs;

        return @TicketIDs if defined $CandidateIteration && defined $Iteration && $CandidateIteration eq $Iteration;

        my @ActionableTicketIDs;
        TICKETID:
        for my $TicketID (@TicketIDs) {
            my %Ticket = $TicketObject->TicketGet(
                TicketID      => $TicketID,
                DynamicFields => 1,
                UserID        => $Param{UserID} || 1,
                Silent        => 1,
            );

            next TICKETID if !%Ticket;
            next TICKETID if _DiagnosisNoActionTicket( Ticket => \%Ticket );

            push @ActionableTicketIDs, $TicketID;
        }

        return @ActionableTicketIDs if @ActionableTicketIDs;
    }

    return;
}

sub _ExistingChapterPlayCount {
    my (%Param) = @_;

    my %Search = (
        Result => 'ARRAY',
        'DynamicField_ZTicket-Parent' => {
            Equals => $Param{ParentTicketID},
        },
        'DynamicField_ZTicket-BlueBook' => {
            Equals => $Param{BlueBookID},
        },
        'DynamicField_ZTicket-BlueLevel' => {
            Equals => $Param{BlueLevel},
        },
        UserID => $Param{UserID} || 1,
    );

    my $Iteration = _NormalizeValue( $Param{Iteration} );
    if ( defined $Iteration && $Iteration ne '' ) {
        $Search{'DynamicField_ZIN-Iteration'} = {
            Equals => $Iteration,
        };
    }

    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(%Search);

    return scalar @TicketIDs;
}

sub _ExistingChapterPlayForRecord {
    my (%Param) = @_;

    return if !$Param{ParentTicketID};
    return if !$Param{BlueBookID};
    return if !defined $Param{BlueLevel};
    return if !$Param{Record} || ref $Param{Record} ne 'HASH';

    my %Search = (
        Result => 'ARRAY',
        'DynamicField_ZTicket-Parent' => {
            Equals => $Param{ParentTicketID},
        },
        'DynamicField_ZTicket-BlueBook' => {
            Equals => $Param{BlueBookID},
        },
        'DynamicField_ZTicket-BlueLevel' => {
            Equals => $Param{BlueLevel},
        },
        UserID => $Param{UserID} || 1,
    );

    my $Iteration = _NormalizeValue( $Param{Iteration} );
    if ( defined $Iteration && $Iteration ne '' ) {
        $Search{'DynamicField_ZIN-Iteration'} = {
            Equals => $Iteration,
        };
    }

    my %RecordFieldMap = (
        'DynamicField_ZTicket-Chapter' => $Param{Record}->{Chapter},
    );
    my $RecordHasStableIdentity = _NormalizeValue( $Param{Record}->{Chapter} ) ? 1 : 0;

    FIELD:
    for my $SearchField ( sort keys %RecordFieldMap ) {
        my $Value = _NormalizeValue( $RecordFieldMap{$SearchField} );
        next FIELD if !defined $Value || $Value eq '';

        $Search{$SearchField} = {
            Equals => $Value,
        };
    }

    if ($RecordHasStableIdentity) {
        my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(%Search);
        return @TicketIDs if @TicketIDs;
    }

    return _ExistingDiagnosisChapterPlayForRecord(%Param);
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    if ( !$Param{Ticket} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'ZTSMBlueBookReader: Stop, missing Ticket param',
        );
        return;
    }

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};
    my $UserID   = $Param{UserID} || 1;

    if ( !$TicketID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'ZTSMBlueBookReader: Stop, missing TicketID',
        );
        return;
    }

    if ( _TicketOnHold($Ticket) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMBlueBookReader: Ticket is onhold, skip BlueBook orchestration TicketID=$TicketID",
        );
        return 1;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "ZTSMBlueBookReader: Enter Run TicketID=$TicketID",
    );

    my $BlueBookID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueBook'}
    );

    if ( !$BlueBookID ) {
        my %FreshTicket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $UserID,
            Silent        => 1,
        );

        $BlueBookID = _NormalizeValue(
            $FreshTicket{'DynamicField_ZTicket-BlueBook'}
        );

        if ($BlueBookID) {
            $Ticket = \%FreshTicket;
            $LogObject->Log(
                Priority => 'notice',
                Message  => "ZTSMBlueBookReader: BlueBook resolved after ticket reload TicketID=$TicketID BlueBook=$BlueBookID",
            );
        }
    }

    if ( !$BlueBookID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, missing ZTicket-BlueBook TicketID=$TicketID",
        );
        return;
    }

    my $BlueBook = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $BlueBookID,
        DynamicFields => 1,
    );

    if ( !$BlueBook || ref $BlueBook ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Failed loading BlueBook=$BlueBookID TicketID=$TicketID",
        );

        return;
    }

    my $XMLData = ref $BlueBook->{XMLData} eq 'HASH' ? $BlueBook->{XMLData} : {};

    my $Records
        = $XMLData->{'ZBlue-Record'}
        || $BlueBook->{'DynamicField_ZBlue-Record'};

    if ( !$Records ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, missing ZBlue-Record TicketID=$TicketID BlueBook=$BlueBookID",
        );
        return;
    }

    if ( ref $Records eq 'HASH' ) {
        $Records = [$Records];
    }

    if ( ref $Records ne 'ARRAY' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, invalid ZBlue-Record structure TicketID=$TicketID BlueBook=$BlueBookID Ref=" . ref $Records,
        );
        return;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "ZTSMBlueBookReader: Raw records TicketID=$TicketID BlueBook=$BlueBookID Count=" . scalar @{$Records},
    );

    my @ParsedRecords;

    RECORD:
    for my $Record ( @{$Records} ) {

        if ( ref $Record ne 'HASH' ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "ZTSMBlueBookReader: Skip record, invalid structure TicketID=$TicketID BlueBook=$BlueBookID Ref=" . ref $Record,
            );
            next RECORD;
        }

        my $RawBlueLevel = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-BlueLevel', 'ZBlue-Level', 'ZBlue-Seq' ],
        ) || 1;
        my $BlueLevel = _GeneralCatalogDynamicFieldValueResolve(
            Value      => $RawBlueLevel,
            FieldNames => [ 'ZBlue-BlueLevel', 'ZBlue-Level', 'ZBlue-Seq' ],
        ) || $RawBlueLevel;

        my $Chapter = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-Chapter' ],
        );

        if ( !$Chapter ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "ZTSMBlueBookReader: Skip record, missing ZBlue-Chapter TicketID=$TicketID BlueBook=$BlueBookID BlueLevel=$BlueLevel",
            );
            next RECORD;
        }

        my $RawType = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-Type', 'ZBlue-TicketType' ],
        );

        my $Type = _TicketTypeResolve(
            Value => $RawType,
        );

        my $RawPurpleBook = _RecordValueGet( Record => $Record, Fields => ['ZBlue-PurpleBook'] );

        push @ParsedRecords, {
            BlueLevel        => $BlueLevel,
            RawBlueLevel     => $RawBlueLevel,
            Chapter          => $Chapter,
            Type             => $Type,
            RawType          => $RawType,
            Activity         => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Activity'] ),
            Profile          => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Profile'] ),
            Role             => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Role'] ),
            Template         => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Template'] ),
            PurpleBook       => _GovernanceObjectDynamicFieldValueResolve(
                Value      => $RawPurpleBook,
                FieldNames => ['ZBlue-PurpleBook'],
            ) || $RawPurpleBook,
            Mandatory        => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Mandatory'] ),
            Strict           => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Strict'] ),
            Duration         => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Duration'] ),
            RequiredWeightage => _RecordValueGet(
                Record => $Record,
                Fields => [ 'ZBlue-RequiredWeightage', 'ZBlue-Weightage' ],
            ),
        };
    }

    if ( !@ParsedRecords ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, no parsed BlueBook records TicketID=$TicketID BlueBook=$BlueBookID",
        );
        return;
    }

    @ParsedRecords = sort {
        $a->{BlueLevel} <=> $b->{BlueLevel}
            ||
        $a->{Chapter} cmp $b->{Chapter}
    } @ParsedRecords;

    my $CurrentBlueLevel = $ParsedRecords[0]->{BlueLevel};

    $LogObject->Log(
        Priority => 'error',
        Message  => "ZTSMBlueBookReader: Parsed records TicketID=$TicketID BlueBook=$BlueBookID Count="
            . scalar @ParsedRecords
            . " FirstBlueLevel=$CurrentBlueLevel",
    );

    _TicketFieldSet(
        TicketID  => $TicketID,
        FieldName => 'ZTicket-BlueLevel',
        Value     => $CurrentBlueLevel,
        UserID    => $UserID,
    );

    my @CreatedTicketIDs;
    my @ExistingTicketIDs;

    RECORD:
    for my $Record (@ParsedRecords) {

        next RECORD if $Record->{BlueLevel} ne $CurrentBlueLevel;

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  "ZTSMBlueBookReader: Evaluate record spawn "
                . "TicketID=$TicketID "
                . "BlueBook=$BlueBookID "
                . "BlueLevel=$CurrentBlueLevel "
                . "Chapter="
                . ( $Record->{Chapter} || '' )
                . " Profile="
                . ( $Record->{Profile} || '' )
                . " Role="
                . ( $Record->{Role} || '' )
                . " Type="
                . ( $Record->{Type} || '' )
                . " Activity="
                . ( $Record->{Activity} || '' ),
        );

        my @RecordExistingTicketIDs = _ExistingChapterPlayForRecord(
            ParentTicketID => $TicketID,
            BlueBookID     => $BlueBookID,
            BlueLevel      => $CurrentBlueLevel,
            Record         => $Record,
            Iteration      => _TicketIteration( Ticket => $Ticket ),
            UserID         => $UserID,
        );

        if (@RecordExistingTicketIDs) {
            push @ExistingTicketIDs, @RecordExistingTicketIDs;
            $LogObject->Log(
                Priority => 'error',
                Message  =>
                      "ZTSMBlueBookReader: Existing ChapterPlay for record, skip record spawn "
                    . "TicketID=$TicketID "
                    . "BlueBook=$BlueBookID "
                    . "BlueLevel=$CurrentBlueLevel "
                    . "Chapter="
                    . ( $Record->{Chapter} || '' )
                    . " Profile="
                    . ( $Record->{Profile} || '' )
                    . " Existing="
                    . join( ',', @RecordExistingTicketIDs ),
            );
            next RECORD;
        }

        my $ChildType  = $Record->{Type} || $Ticket->{Type} || '';
        my $ParentType = $Ticket->{Type} || 'ParentTicket';
        my $ParentRef  = $Ticket->{TicketNumber} || $TicketID;
        my $Activity   = $Record->{Activity} || $Ticket->{Title};
        my $ChildTitle = join ' - ', grep { defined $_ && $_ ne '' } (
            $ChildType,
            "$ParentType#$ParentRef",
            $Activity,
        );

        my $NewTicketID = $TicketObject->TicketCreate(
            TN           => undef,
            Title        => $ChildTitle,
            Queue        => $Ticket->{Queue},
            Lock         => 'unlock',
            Priority     => $Ticket->{Priority},
            State        => 'new',
            CustomerUser => $Ticket->{CustomerUserID},
            OwnerID      => 1,
            UserID       => $UserID,
            Type         => $ChildType,
            ServiceID    => $Ticket->{ServiceID},
            SLAID        => $Ticket->{SLAID},
            ResponsibleID => 1,
            ParentTicketID     => $TicketID,
            ParentTicketNumber => $Ticket->{TicketNumber},
        );

        if ( !$NewTicketID ) {
            $LogObject->Log(
                Priority => 'error',
                Message  =>
                      "ZTSMBlueBookReader: TicketCreate failed "
                    . "ParentTicketID=$TicketID "
                    . "BlueBook=$BlueBookID "
                    . "BlueLevel=$Record->{BlueLevel} "
                    . "Chapter=$Record->{Chapter} "
                    . "Type="
                    . ( $Record->{Type} || $Ticket->{Type} || '' )
                    . " RawType="
                    . ( $Record->{RawType} || '' )
                    . " Queue="
                    . ( $Ticket->{Queue} || '' ),
            );
            next RECORD;
        }

        push @CreatedTicketIDs, $NewTicketID;

        my %ChildProcessContext = Kernel::System::ZTSMBlueBookRuntime::ChildProcessSet(
            TicketID => $NewTicketID,
            UserID   => $UserID,
        );

        my $OwnerGroup = $Record->{Profile};

        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Owner group selector assignment "
                . "TicketID=$TicketID "
                . "ChildTicketID=$NewTicketID "
                . "Profile="
                . ( $Record->{Profile} || '' )
                . " Role="
                . ( $Record->{Role} || '' )
                . " OwnerGroup="
                . ( $OwnerGroup || '' ),
        );

        my %FieldMap = (
            'ZTicket-Parent'           => $TicketID,
            'ZTicket-BlueBook'         => $BlueBookID,
            'ZTicket-BlueLevel'        => $Record->{BlueLevel},
            'ZTicket-Chapter'          => $Record->{Chapter},
            'ZTicket-Application'      => $Ticket->{'DynamicField_ZTicket-Application'},
            'ZTicket-Profile'          => $Record->{Profile},
            'ZTicket-OwnerGroup'       => $OwnerGroup,
            'ZTicket-Role'             => $Record->{Role},
            'ZTicket-Mandatory'        => $Record->{Mandatory},
            'ZTicket-Strict'           => $Record->{Strict},
            'ZTicket-Duration'         => $Record->{Duration},
            'ZTicket-RequiredWeightage' => $Record->{RequiredWeightage} || 1,
            'ZIN-Iteration'            => _TicketIteration( Ticket => $Ticket ),
        );

        FIELD:
        for my $FieldName ( sort keys %FieldMap ) {

            next FIELD if !defined $FieldMap{$FieldName};
            next FIELD if $FieldMap{$FieldName} eq '';

            my $FieldSet = _TicketFieldSet(
                TicketID  => $NewTicketID,
                FieldName => $FieldName,
                Value     => $FieldMap{$FieldName},
                UserID    => $UserID,
            );

            if ( !$FieldSet ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  =>
                          'ZTSMBlueBookReader: Child field set failed '
                        . "TicketID=$NewTicketID "
                        . "Field=$FieldName "
                        . 'Value='
                        . ( defined $FieldMap{$FieldName} ? $FieldMap{$FieldName} : '' ),
                );
            }
        }

        ZTSMArticleCreate(
            %Param,
            TicketID => $NewTicketID,
            Subject  => 'DO-NOT-REPLY: ChapterPlay initiated.',
            Body     =>
                  "** Note: This is a system-generated orchestration update message.\n\n"
                . "ChapterPlay:\n"
                . "Initiated\n\n"
                . "Parent Ticket:\n"
                . _TicketSummary(
                    Ticket   => $Ticket,
                    TicketID => $TicketID,
                )
                . "\n\n"
                . "BlueBook:\n"
                . $BlueBookID
                . "\n\n"
                . "BlueLevel:\n"
                . $Record->{BlueLevel}
                . "\n\n"
                . "Chapter:\n"
                . $Record->{Chapter},
            HistoryComment => 'ZTSM: ChapterPlay initiated',
            UserID         => $UserID,
        );

        Kernel::System::ZTSMBlueBookRuntime::ChildTemplateApply(
            TicketID     => $NewTicketID,
            TemplateID   => $Record->{Template},
            ArticleParam => \%Param,
            UserID       => $UserID,
        );
    }

    ZTSMArticleCreate(
        %Param,
        TicketID => $TicketID,
        Subject  => 'DO-NOT-REPLY: BlueBook orchestration started.',
        Body     =>
              "** Note: This is a system-generated orchestration update message.\n\n"
            . "BlueBook Reader:\n"
            . "Started\n\n"
            . "BlueBook:\n"
            . $BlueBookID
            . "\n\n"
            . "BlueLevel:\n"
            . $CurrentBlueLevel
            . "\n\n"
            . "ChapterPlay Tickets Created:\n"
            . (
                @CreatedTicketIDs
                ? join(
                    "\n",
                    map { _TicketSummary( TicketID => $_ ) } @CreatedTicketIDs
                )
                : 'None'
            ),
        HistoryComment => 'ZTSM: BlueBook orchestration started',
        UserID         => $UserID,
    );

    $LogObject->Log(
        Priority => 'error',
        Message  =>
              "ZTSMBlueBookReader: BlueBook orchestration started "
            . "TicketID=$TicketID "
            . "BlueBook=$BlueBookID "
            . "BlueLevel=$CurrentBlueLevel "
            . "Created="
            . scalar @CreatedTicketIDs,
    );

    return 1;
}

1;
