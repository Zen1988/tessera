# --
# Kernel/System/ZTSMBlueBookRuntime.pm
# --

package Kernel::System::ZTSMBlueBookRuntime;

use strict;
use warnings;
no warnings 'redefine';

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

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

sub _RuntimeLog {
    my (%Param) = @_;

    eval {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => $Param{Priority} || 'notice',
            Message  => $Param{Message}  || '',
        );
    };

    return 1;
}

sub _KnownParamKey {
    my ($Key) = @_;

    return if !defined $Key || ref $Key;

    my %Known = map { $_ => 1 } qw(
        AllowRepeatClosed
        ArticleParam
        BlueBookID
        BlueLevel
        CurrentBlueLevel
        Data
        Iteration
        OwnerGroupOverride
        OwnerOverride
        OwnerWeightageOverride
        ParentTicket
        ParentTicketID
        PreserveParentBlueLevel
        Record
        Records
        Ticket
        UserID
    );

    return $Known{$Key};
}

sub _ParamHash {
    my ( $Caller, @Raw ) = @_;

    return %{ $Raw[0] } if @Raw == 1 && ref $Raw[0] eq 'HASH';

    my %Param;
    my $RawCount = scalar @Raw;

    _RuntimeLog(
        Priority => 'error',
        Message  => "ZTSMBlueBookRuntime: odd argument list received Caller=$Caller RawCount=$RawCount",
    ) if $RawCount % 2;

    while (@Raw) {
        my $Key = shift @Raw;

        if ( !@Raw ) {
            _RuntimeLog(
                Priority => 'error',
                Message  => "ZTSMBlueBookRuntime: dropping argument without value Caller=$Caller Key="
                    . ( defined $Key ? $Key : '' ),
            );
            last;
        }

        my $Value = shift @Raw;

        if ( defined $Value && !ref $Value && _KnownParamKey($Value) ) {
            $Param{$Key} = undef;
            unshift @Raw, $Value;
            next;
        }

        $Param{$Key} = $Value;
    }

    return %Param;
}

sub _PlainTextValue {
    my ($Value) = @_;

    $Value = _NormalizeValue($Value);
    return if !defined $Value;

    return $Value if $Value !~ m{<[^>]+>}s;

    if ( $Value =~ m{<body[^>]*>(.*?)</body>}is ) {
        $Value = $1;
    }

    $Value =~ s{<script\b[^>]*>.*?</script>}{}gis;
    $Value =~ s{<style\b[^>]*>.*?</style>}{}gis;
    $Value =~ s{<br\s*/?>}{\n}gi;
    $Value =~ s{</(?:p|div|li|tr|h[1-6])>}{\n}gi;
    $Value =~ s{<[^>]+>}{}g;

    my %Entity = (
        amp  => '&',
        lt   => '<',
        gt   => '>',
        quot => '"',
        apos => q{'},
        nbsp => ' ',
    );
    $Value =~ s{&([A-Za-z]+);}{ exists $Entity{lc $1} ? $Entity{lc $1} : ' ' }eg;
    $Value =~ s{&#(\d+);}{ chr($1) }eg;
    $Value =~ s{&#x([0-9A-Fa-f]+);}{ chr(hex($1)) }eg;
    $Value =~ s{\r\n?}{\n}g;
    $Value =~ s{[ \t]+}{ }g;
    $Value =~ s{[ \t]*\n[ \t]*}{\n}g;
    $Value =~ s{\n{3,}}{\n\n}g;
    $Value =~ s{\A\s+|\s+\z}{}g;

    return $Value;
}

sub _NeutralClosureState {
    my ($State) = @_;

    return if !defined $State;
    return 1 if $State eq 'closed no action';
    return 1 if $State eq 'closed duplicate';

    return;
}

sub _FulfilledClosureState {
    my ($State) = @_;

    return if !defined $State;
    return 1 if $State eq 'closed successful';
    return 1 if $State eq 'diagnosed';
    return 1 if _NeutralClosureState($State);

    return;
}

sub _SetEntityValueNormalize {
    my ($Value) = @_;

    return [] if !defined $Value;

    my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
    my @Clean;

    VALUE:
    for my $Item (@Values) {
        $Item = _NormalizeValue($Item);
        next VALUE if !defined $Item || $Item eq '';
        next VALUE if $Item =~ m{\AZ(?:RM|Template)-[A-Za-z0-9-]+\z};

        push @Clean, $Item;
    }

    return \@Clean;
}

sub _ScalarValueNormalize {
    my ($Value) = @_;

    $Value = _PlainTextValue($Value);
    return if !defined $Value || $Value eq '';
    return if $Value =~ m{\AZ(?:RM|Template)-[A-Za-z0-9-]+\z};

    return $Value;
}

sub _TicketSummary {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return $Param{TicketID} || 'N/A' if !$Ticket || ref $Ticket ne 'HASH';

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

sub _TruthValue {
    my ($Value) = @_;

    $Value = _NormalizeValue($Value);

    return if !defined $Value;
    return if $Value eq '';
    return if $Value eq '0';
    return if lc $Value eq 'no';
    return if lc $Value eq 'false';

    return 1;
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

sub ChildProcessContextGet {
    my (%Param) = @_;

    my $ProcessName  = $Param{ProcessName}  || 'ztsm-activity-lifecycle-orchestration';
    my $ActivityName = $Param{ActivityName} || 'Start';
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Processes    = $ConfigObject->Get('Process') || {};
    my $Activities   = $ConfigObject->Get('Process::Activity') || {};

    my $ProcessEntityID;
    my $ActivityEntityID;

    PROCESS:
    for my $CandidateProcessEntityID ( sort keys %{$Processes} ) {
        my $Process = $Processes->{$CandidateProcessEntityID};

        next PROCESS if ref $Process ne 'HASH';
        next PROCESS if ( $Process->{Name} || '' ) ne $ProcessName;
        next PROCESS if ( $Process->{State} || '' ) ne 'Active';

        $ProcessEntityID = $CandidateProcessEntityID;
        $ActivityEntityID = $Process->{StartActivity};

        if (
            $ActivityEntityID
            && ref $Activities->{$ActivityEntityID} eq 'HASH'
            && ( $Activities->{$ActivityEntityID}->{Name} || '' ) eq $ActivityName
            )
        {
            last PROCESS;
        }

        ACTIVITY:
        for my $CandidateActivityEntityID ( sort keys %{ $Process->{Path} || {} } ) {
            next ACTIVITY if ref $Activities->{$CandidateActivityEntityID} ne 'HASH';
            next ACTIVITY if ( $Activities->{$CandidateActivityEntityID}->{Name} || '' ) ne $ActivityName;

            $ActivityEntityID = $CandidateActivityEntityID;
            last PROCESS;
        }
    }

    return if !$ProcessEntityID;
    return if !$ActivityEntityID;

    return (
        ProcessEntityID  => $ProcessEntityID,
        ActivityEntityID => $ActivityEntityID,
    );
}

sub ChildProcessSet {
    my (%Param) = @_;

    return if !$Param{TicketID};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ProcessField = $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID')
        || 'ProcessManagementProcessID';
    my $ActivityField = $ConfigObject->Get('Process::DynamicFieldProcessManagementActivityID')
        || 'ProcessManagementActivityID';

    my %Context = ChildProcessContextGet(%Param);

    if ( !%Context ) {
        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  'ZTSMBlueBookRuntime: Child process context not found '
                . 'Process=ztsm-activity-lifecycle-orchestration '
                . 'Activity=Start '
                . "TicketID=$Param{TicketID}",
        );

        return;
    }

    my $ProcessSet = _TicketFieldSet(
        TicketID  => $Param{TicketID},
        FieldName => $ProcessField,
        Value     => $Context{ProcessEntityID},
        UserID    => $Param{UserID} || 1,
    );

    my $ActivitySet = _TicketFieldSet(
        TicketID  => $Param{TicketID},
        FieldName => $ActivityField,
        Value     => $Context{ActivityEntityID},
        UserID    => $Param{UserID} || 1,
    );

    if ( !$ProcessSet ) {
        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  'ZTSMBlueBookRuntime: Failed setting child process '
                . "TicketID=$Param{TicketID} "
                . "Field=$ProcessField "
                . "ProcessEntityID=$Context{ProcessEntityID}",
        );

        return;
    }

    if ( !$ActivitySet ) {
        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  'ZTSMBlueBookRuntime: Failed setting child process activity '
                . "TicketID=$Param{TicketID} "
                . "Field=$ActivityField "
                . "ActivityEntityID=$Context{ActivityEntityID}",
        );

        return;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              'ZTSMBlueBookRuntime: Child process assigned '
            . "TicketID=$Param{TicketID} "
            . "ProcessEntityID=$Context{ProcessEntityID} "
            . "ActivityEntityID=$Context{ActivityEntityID}",
    );

    return %Context;
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

sub BlueBookIDGet {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket} || $Param{Data};

    return if !$Ticket || ref $Ticket ne 'HASH';

    return _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
}

sub BlueBookGet {
    my (%Param) = @_;

    return if !$Param{BlueBookID};

    return $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $Param{BlueBookID},
        DynamicFields => 1,
    );
}

sub RecordsParse {
    my (%Param) = @_;

    my $BlueBook = $Param{BlueBook};

    return if !$BlueBook || ref $BlueBook ne 'HASH';

    my $Records = $BlueBook->{'DynamicField_ZBlue-Record'}
        || ( ref $BlueBook->{XMLData} eq 'HASH' ? $BlueBook->{XMLData}->{'ZBlue-Record'} : undef );

    return if !$Records;

    if ( ref $Records eq 'HASH' ) {
        $Records = [$Records];
    }

    return if ref $Records ne 'ARRAY';

    my @ParsedRecords;

    RECORD:
    for my $Record ( @{$Records} ) {

        next RECORD if ref $Record ne 'HASH';

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
            Fields => ['ZBlue-Chapter'],
        );

        next RECORD if !$Chapter;

        my $RawPurpleBook = _RecordValueGet( Record => $Record, Fields => ['ZBlue-PurpleBook'] );

        push @ParsedRecords, {
            BlueLevel    => $BlueLevel,
            RawBlueLevel => $RawBlueLevel,
            Chapter      => $Chapter,
            Type      => _TicketTypeResolve(
                Value => _RecordValueGet(
                    Record => $Record,
                    Fields => [ 'ZBlue-Type', 'ZBlue-TicketType' ],
                ),
            ),
            Activity => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Activity'] ),
            Profile => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Profile'] ),
            Role    => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Role'] ),
            Template => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Template'] ),
            PurpleBook => _GovernanceObjectDynamicFieldValueResolve(
                Value      => $RawPurpleBook,
                FieldNames => ['ZBlue-PurpleBook'],
            ) || $RawPurpleBook,
            Mandatory => _RecordValueGet(
                Record => $Record,
                Fields => ['ZBlue-Mandatory'],
            ),
            Strict   => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Strict'] ),
            Duration => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Duration'] ),
            RequiredWeightage => _RecordValueGet(
                Record => $Record,
                Fields => [ 'ZBlue-RequiredWeightage', 'ZBlue-Weightage' ],
            ),
        };
    }

    return sort {
        $a->{BlueLevel} <=> $b->{BlueLevel}
            ||
            $a->{Chapter} cmp $b->{Chapter}
    } @ParsedRecords;
}

sub ChildTicketIDsGet {
    my %Param = _ParamHash( 'ChildTicketIDsGet', @_ );

    return if !$Param{ParentTicketID};
    return if !$Param{BlueBookID};

    my %Search = (
        Result => 'ARRAY',
        'DynamicField_ZTicket-Parent' => {
            Equals => $Param{ParentTicketID},
        },
        'DynamicField_ZTicket-BlueBook' => {
            Equals => $Param{BlueBookID},
        },
        UserID => $Param{UserID} || 1,
    );

    my $Iteration = _NormalizeValue( $Param{Iteration} );
    for my $TicketKey (qw(Ticket Data ParentTicket)) {
        next if defined $Iteration;
        next if !$Param{$TicketKey} || ref $Param{$TicketKey} ne 'HASH';
        $Iteration = _NormalizeValue( $Param{$TicketKey}->{'DynamicField_ZIN-Iteration'} );
    }
    if ( defined $Iteration && $Iteration ne '' ) {
        $Search{'DynamicField_ZIN-Iteration'} = {
            Equals => $Iteration,
        };
    }

    if ( defined $Param{BlueLevel} && $Param{BlueLevel} ne '' ) {
        $Search{'DynamicField_ZTicket-BlueLevel'} = {
            Equals => $Param{BlueLevel},
        };
    }

    return $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(%Search);
}

sub ChildTicketIDsForRecordGet {
    my %Param = _ParamHash( 'ChildTicketIDsForRecordGet', @_ );

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
    for my $TicketKey (qw(Ticket Data ParentTicket)) {
        next if defined $Iteration;
        next if !$Param{$TicketKey} || ref $Param{$TicketKey} ne 'HASH';
        $Iteration = _NormalizeValue( $Param{$TicketKey}->{'DynamicField_ZIN-Iteration'} );
    }
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

sub CurrentBlueLevelGet {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket} || $Param{Data};

    if ( $Ticket && ref $Ticket eq 'HASH' ) {
        my $CurrentBlueLevel = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} );
        return $CurrentBlueLevel if defined $CurrentBlueLevel && $CurrentBlueLevel ne '';
    }

    return if !$Param{ParentTicketID};
    return if !$Param{BlueBookID};

    my @TicketIDs = ChildTicketIDsGet( \%Param );

    my $CurrentBlueLevel;
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    TICKETID:
    for my $TicketID (@TicketIDs) {

        my %ChildTicket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $Param{UserID} || 1,
            Silent        => 1,
        );

        next TICKETID if !%ChildTicket;

        my $BlueLevel = _NormalizeValue( $ChildTicket{'DynamicField_ZTicket-BlueLevel'} );

        next TICKETID if !defined $BlueLevel;
        next TICKETID if $BlueLevel eq '';

        if ( !defined $CurrentBlueLevel || $BlueLevel > $CurrentBlueLevel ) {
            $CurrentBlueLevel = $BlueLevel;
        }
    }

    return $CurrentBlueLevel;
}

sub NextBlueLevelGet {
    my (%Param) = @_;

    return if !defined $Param{CurrentBlueLevel};

    my @Records = @{ $Param{Records} || [] };

    RECORD:
    for my $Record (@Records) {

        next RECORD if !$Record;
        next RECORD if ref $Record ne 'HASH';
        next RECORD if !defined $Record->{BlueLevel};
        next RECORD if $Record->{BlueLevel} <= $Param{CurrentBlueLevel};

        return $Record->{BlueLevel};
    }

    return;
}

sub LevelComplete {
    my %Param = _ParamHash( 'LevelComplete', @_ );

    return if !$Param{ParentTicketID};
    return if !$Param{BlueBookID};
    return if !defined $Param{BlueLevel};

    my @TicketIDs = ChildTicketIDsGet( \%Param );

    return if !@TicketIDs;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Chapter;

    TICKETID:
    for my $TicketID (@TicketIDs) {

        my %ChildTicket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $Param{UserID} || 1,
            Silent        => 1,
        );

        next TICKETID if !%ChildTicket;

        my $Chapter = _NormalizeValue( $ChildTicket{'DynamicField_ZTicket-Chapter'} ) || '';
        return if !$Chapter;

        $Chapter{$Chapter}->{Seen} = 1;

        my $RequiredWeightage = _NormalizeValue(
            $ChildTicket{'DynamicField_ZTicket-RequiredWeightage'}
        ) || 1;

        if ( $RequiredWeightage > ( $Chapter{$Chapter}->{RequiredWeightage} || 0 ) ) {
            $Chapter{$Chapter}->{RequiredWeightage} = $RequiredWeightage;
        }

        if ( _TruthValue( $ChildTicket{'DynamicField_ZTicket-Mandatory'} ) ) {
            $Chapter{$Chapter}->{Mandatory} = 1;
        }

        if ( $ChildTicket{StateType} ne 'closed' ) {
            $Chapter{$Chapter}->{Open} = 1;
            next TICKETID;
        }

        my $State = $ChildTicket{State} || '';

        if (
            $State eq 'closed rollback'
            || $State eq 'closed rejected'
            || $State eq 'closed unsuccessful'
            )
        {
            $Chapter{$Chapter}->{Failure} = 1;
        }

        my $OwnerWeightage = _NormalizeValue(
            $ChildTicket{'DynamicField_ZTicket-OwnerWeightage'}
        );
        if ( ( !defined $OwnerWeightage || $OwnerWeightage eq '' ) && _FulfilledClosureState($State) ) {
            $OwnerWeightage = $RequiredWeightage || 1;
        }

        $Chapter{$Chapter}->{Weightage} += $OwnerWeightage || 0;
    }

    return if !%Chapter;

    CHAPTER:
    for my $Chapter ( keys %Chapter ) {

        return if $Chapter{$Chapter}->{Open};
        return if $Chapter{$Chapter}->{Mandatory} && $Chapter{$Chapter}->{Failure};
        return if ( $Chapter{$Chapter}->{Weightage} || 0 ) < ( $Chapter{$Chapter}->{RequiredWeightage} || 1 );
    }

    return 1;
}

sub LevelSpawn {
    my (%Param) = @_;

    return if !$Param{ParentTicket};
    return if !$Param{ParentTicketID};
    return if !$Param{BlueBookID};
    return if !defined $Param{BlueLevel};

    my @Records = @{ $Param{Records} || [] };
    my $Iteration = _NormalizeValue( $Param{Iteration} );
    if ( !defined $Iteration || $Iteration eq '' ) {
        $Iteration = _NormalizeValue( $Param{ParentTicket}->{'DynamicField_ZIN-Iteration'} );
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    my @CreatedTicketIDs;
    my @ExistingTicketIDs;

    RECORD:
    for my $Record (@Records) {

        next RECORD if !$Record;
        next RECORD if ref $Record ne 'HASH';
        next RECORD if $Record->{BlueLevel} ne $Param{BlueLevel};

        my @RecordExistingTicketIDs = ChildTicketIDsForRecordGet(
            ParentTicketID => $Param{ParentTicketID},
            BlueBookID     => $Param{BlueBookID},
            BlueLevel      => $Param{BlueLevel},
            Record         => $Record,
            ParentTicket   => $Param{ParentTicket},
            Iteration      => $Iteration,
            UserID         => $Param{UserID} || 1,
        );

        if (@RecordExistingTicketIDs) {
            if ( !$Param{AllowRepeatClosed} ) {
                push @ExistingTicketIDs, @RecordExistingTicketIDs;
                next RECORD;
            }

            my @OpenExistingTicketIDs;
            EXISTINGTICKETID:
            for my $ExistingTicketID (@RecordExistingTicketIDs) {
                my %ExistingTicket = $TicketObject->TicketGet(
                    TicketID      => $ExistingTicketID,
                    DynamicFields => 0,
                    UserID        => $Param{UserID} || 1,
                    Silent        => 1,
                );

                next EXISTINGTICKETID if !%ExistingTicket;
                next EXISTINGTICKETID if ( $ExistingTicket{StateType} || '' ) eq 'closed';

                push @OpenExistingTicketIDs, $ExistingTicketID;
            }

            if (@OpenExistingTicketIDs) {
                push @ExistingTicketIDs, @OpenExistingTicketIDs;
                next RECORD;
            }
        }

        my $ParentTicket = $Param{ParentTicket};
        my $ChildType  = $Record->{Type} || $ParentTicket->{Type} || '';
        my $ParentType = $ParentTicket->{Type} || 'ParentTicket';
        my $ParentRef  = $ParentTicket->{TicketNumber} || $Param{ParentTicketID};
        my $Activity   = $Record->{Activity} || $ParentTicket->{Title};
        my $ChildTitle = join ' - ', grep { defined $_ && $_ ne '' } (
            $ChildType,
            "$ParentType#$ParentRef",
            $Activity,
        );

        my $NewTicketID = $TicketObject->TicketCreate(
            TN            => undef,
            Title         => $ChildTitle,
            Queue         => $ParentTicket->{Queue},
            Lock          => 'unlock',
            Priority      => $ParentTicket->{Priority},
            State         => 'new',
            CustomerUser  => $ParentTicket->{CustomerUserID},
            CustomerID    => $ParentTicket->{CustomerID},
            OwnerID       => 1,
            UserID        => $Param{UserID} || 1,
            Type          => $ChildType,
            ServiceID     => $ParentTicket->{ServiceID},
            SLAID         => $ParentTicket->{SLAID},
            ResponsibleID => 1,
            ParentTicketID     => $Param{ParentTicketID},
            ParentTicketNumber => $ParentTicket->{TicketNumber},
        );

        next RECORD if !$NewTicketID;

        push @CreatedTicketIDs, $NewTicketID;

        my %ChildProcessContext = ChildProcessSet(
            TicketID => $NewTicketID,
            UserID   => $Param{UserID} || 1,
        );

        my $OwnerGroup = $Record->{Profile};
        if ( defined $Param{OwnerGroupOverride} && $Param{OwnerGroupOverride} ne '' ) {
            $OwnerGroup = $Param{OwnerGroupOverride};
        }

        my $Owner = $Param{OwnerOverride};
        my $OwnerWeightage = $Param{OwnerWeightageOverride};

        my %FieldMap = (
            'ZTicket-Parent'            => $Param{ParentTicketID},
            'ZTicket-BlueBook'          => $Param{BlueBookID},
            'ZTicket-BlueLevel'         => $Record->{BlueLevel},
            'ZTicket-Chapter'           => $Record->{Chapter},
            'ZTicket-Application'       => $ParentTicket->{'DynamicField_ZTicket-Application'},
            'ZRM-OriginatedEvent'       => $ParentTicket->{'DynamicField_ZRM-OriginatedEvent'},
            'ZTicket-Profile'           => $Record->{Profile},
            'ZTicket-OwnerGroup'        => $OwnerGroup,
            'ZTicket-Owner'             => $Owner,
            'ZTicket-OwnerWeightage'    => $OwnerWeightage,
            'ZTicket-Role'              => $Record->{Role},
            'ZTicket-Mandatory'         => $Record->{Mandatory},
            'ZTicket-Strict'            => $Record->{Strict},
            'ZTicket-Duration'          => $Record->{Duration},
            'ZTicket-RequiredWeightage' => $Record->{RequiredWeightage} || 1,
            'ZIN-Iteration'             => $Iteration,
        );

        FIELD:
        for my $FieldName ( sort keys %FieldMap ) {

            next FIELD if !defined $FieldMap{$FieldName};
            next FIELD if $FieldMap{$FieldName} eq '';

            my $FieldSet = _TicketFieldSet(
                TicketID  => $NewTicketID,
                FieldName => $FieldName,
                Value     => $FieldMap{$FieldName},
                UserID    => $Param{UserID} || 1,
            );

            if ( !$FieldSet ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  =>
                          'ZTSMBlueBookRuntime: Child field set failed '
                        . "TicketID=$NewTicketID "
                        . "Field=$FieldName "
                        . 'Value='
                        . ( defined $FieldMap{$FieldName} ? $FieldMap{$FieldName} : '' ),
                );
            }
        }

        ZTSMArticleCreate(
            %{ $Param{ArticleParam} || {} },
            TicketID => $NewTicketID,
            Subject  => 'DO-NOT-REPLY: ChapterPlay initiated.',
            Body     =>
                  "** Note: This is a system-generated orchestration update message.\n\n"
                . "ChapterPlay:\n"
                . "Initiated\n\n"
                . "Parent Ticket:\n"
                . _TicketSummary(
                    Ticket   => $Param{ParentTicket},
                    TicketID => $Param{ParentTicketID},
                )
                . "\n\n"
                . "BlueBook:\n"
                . $Param{BlueBookID}
                . "\n\n"
                . "BlueLevel:\n"
                . $Record->{BlueLevel}
                . "\n\n"
                . "Chapter:\n"
                . $Record->{Chapter},
            HistoryComment => 'ZTSM: ChapterPlay initiated',
            UserID         => $Param{UserID} || 1,
        );

        ChildTemplateApply(
            TicketID       => $NewTicketID,
            TemplateID     => $Record->{Template},
            ArticleParam   => $Param{ArticleParam},
            UserID         => $Param{UserID} || 1,
        );
    }

    if ( !$Param{PreserveParentBlueLevel} ) {
        _TicketFieldSet(
            TicketID  => $Param{ParentTicketID},
            FieldName => 'ZTicket-BlueLevel',
            Value     => $Param{BlueLevel},
            UserID    => $Param{UserID} || 1,
        );
    }

    return @CreatedTicketIDs ? @CreatedTicketIDs : @ExistingTicketIDs;
}

sub ChildTemplateApply {
    my (%Param) = @_;

    return if !$Param{TicketID};
    return if !$Param{TemplateID};

    my $UserID = $Param{UserID} || 1;
    my $Template = _GovernanceObjectResolve(
        Value   => $Param{TemplateID},
        Classes => ['Template'],
    );

    return if !$Template || ref $Template ne 'HASH';

    my $Description = _PlainTextValue( $Template->{Description} );
    my $Rows        = _TemplateRiskAssessmentRows( Template => $Template );

    if ( $Rows && @{$Rows} ) {
        my $FieldSet = _TicketFieldSet(
            TicketID  => $Param{TicketID},
            FieldName => 'ZRM-RiskAssessment',
            Value     => $Rows,
            UserID    => $UserID,
        );

        if ( !$FieldSet ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  =>
                      "ZTSMBlueBookRuntime: Template risk assessment field set failed TicketID='$Param{TicketID}' "
                    . "TemplateID='$Param{TemplateID}' RowCount='"
                    . scalar( @{$Rows} )
                    . "'.",
            );
        }
    }

    return 1 if !$Description && !( $Rows && @{$Rows} );

    my $Body = "** Note: This is a system-generated template hydration message.\n\n"
        . "Template:\n"
        . ( $Template->{Name} || $Template->{Number} || $Param{TemplateID} )
        . "\n\n";

    if ($Description) {
        $Body .= "Description:\n$Description\n\n";
    }

    if ( $Rows && @{$Rows} ) {
        $Body .= "Risk Assessment Rows:\n" . scalar @{$Rows};
    }

    ZTSMArticleCreate(
        %{ $Param{ArticleParam} || {} },
        TicketID => $Param{TicketID},
        Subject  => 'DO-NOT-REPLY: Template applied.',
        Body     => $Body,
        HistoryComment => 'ZTSM: Template applied',
        UserID         => $UserID,
    );

    return 1;
}

sub ChangeTemplatePayloadGet {
    my (%Param) = @_;

    return {
        Success => 0,
        Message => 'TemplateID is required.',
    } if !$Param{TemplateID};

    my $Template = _GovernanceObjectResolve(
        Value   => $Param{TemplateID},
        Classes => ['Template'],
    );

    return {
        Success => 0,
        Message => 'The selected change template could not be resolved.',
    } if !$Template || ref $Template ne 'HASH';

    my %PhaseMap = (
        'ZTemplate-ChPrecheck'       => 'ZCH-Precheck',
        'ZTemplate-ChImplementation' => 'ZCH-Implementation',
        'ZTemplate-ChPostChange'     => 'ZCH-PostChange',
        'ZTemplate-ChRollback'       => 'ZCH-Rollback',
    );
    my %FieldMap = (
        'ZTemplate-ChSeq'         => 'ZCH-Seq',
        'ZTemplate-ChStrict'      => 'ZCH-Strict',
        'ZTemplate-ChMandatory'   => 'ZCH-Mandatory',
        'ZTemplate-ChActivity'    => 'ZCH-Activity',
        'ZTemplate-ChDescription' => 'ZCH-Description',
        'ZTemplate-ChTicketType'  => 'ZCH-TicketType',
        'ZTemplate-ChProfile'     => 'ZCH-Profile',
        'ZTemplate-ChWeightage'   => 'ZCH-Weightage',
        'ZTemplate-ChBlueLevel'   => 'ZCH-BlueLevel',
    );
    my %Payload;

    for my $SourcePhase ( sort keys %PhaseMap ) {
        my $Rows = _SetRowsNormalize(
            _ObjectValueGet(
                Object => $Template,
                Field  => $SourcePhase,
            )
        );
        next if !$Rows || ref $Rows ne 'ARRAY';

        my @MappedRows;
        ROW:
        for my $Row ( @{$Rows} ) {
            next ROW if !$Row || ref $Row ne 'HASH';

            my %MappedRow;
            for my $SourceField ( sort keys %FieldMap ) {
                my $Value = _RecordValueGet(
                    Record => $Row,
                    Fields => [$SourceField],
                );
                next if !defined $Value;
                $MappedRow{ $FieldMap{$SourceField} } = $Value;
            }
            push @MappedRows, \%MappedRow if %MappedRow;
        }

        $Payload{ $PhaseMap{$SourcePhase} } = \@MappedRows;
    }

    return {
        Success      => 1,
        TemplateID   => $Param{TemplateID},
        TemplateName => $Template->{Name} || $Template->{Number} || $Param{TemplateID},
        Payload      => \%Payload,
    };
}

sub TemplateIDForTicket {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return if !$Ticket || ref $Ticket ne 'HASH';

    my $BlueBookID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
    my $BlueLevel  = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} );
    my $Chapter    = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );
    return if !$BlueBookID || !defined $BlueLevel || $BlueLevel eq '' || !$Chapter;

    my $BlueBook = BlueBookGet( BlueBookID => $BlueBookID );
    my @Records  = RecordsParse( BlueBook => $BlueBook );

    RECORD:
    for my $Record (@Records) {
        next RECORD if !$Record || ref $Record ne 'HASH';
        next RECORD if !_BlueLevelMatch(
            BlueLevel => $BlueLevel,
            Record    => $Record,
        );
        next RECORD if !defined $Record->{Chapter} || $Record->{Chapter} ne $Chapter;
        next RECORD if $Record->{Type} && ( $Ticket->{Type} || '' ) && $Record->{Type} ne $Ticket->{Type};

        my $TemplateID = _NormalizeValue( $Record->{Template} );
        return $TemplateID if $TemplateID;
    }

    return;
}

sub _BlueLevelMatch {
    my (%Param) = @_;

    my $BlueLevel = _NormalizeValue( $Param{BlueLevel} );
    return if !defined $BlueLevel || $BlueLevel eq '';
    return if !$Param{Record} || ref $Param{Record} ne 'HASH';

    for my $RecordBlueLevel ( $Param{Record}->{BlueLevel}, $Param{Record}->{RawBlueLevel} ) {
        $RecordBlueLevel = _NormalizeValue($RecordBlueLevel);
        next if !defined $RecordBlueLevel || $RecordBlueLevel eq '';
        return 1 if $RecordBlueLevel eq $BlueLevel;
    }

    return;
}

sub _TemplateRiskAssessmentRows {
    my (%Param) = @_;

    my $Template = $Param{Template};
    return if !$Template || ref $Template ne 'HASH';

    my $Rows = _ObjectValueGet(
        Object => $Template,
        Field  => 'ZTemplate-RiskAssessment',
    );

    return if !$Rows;
    $Rows = _SetRowsNormalize($Rows);
    return if ref $Rows ne 'ARRAY';

    my @MappedRows;

    ROW:
    for my $Row ( @{$Rows} ) {
        next ROW if !$Row || ref $Row ne 'HASH';

        my %Mapped = (
            'ZRM-RiskStatement'      => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-RiskStatement'] ),
            'ZRM-ImpactCategory'     => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-ImpactCategory'] ),
            'ZRM-RiskCategory'       => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-RiskCategory'] ),
            'ZRM-RiskDetail'         => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-RiskDetail'] ),
            'ZRM-InherentLikelihood' => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-InherentLikelihood'] ),
            'ZRM-InherentImpact'     => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-InherentImpact'] ),
            'ZRM-RiskAction'         => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-RiskAction'] ),
            'ZRM-RiskOwner'          => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-RiskOwner'] ),
            'ZRM-RiskPlan'           => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-RiskPlan'] ),
            'ZRM-ResidualLikelihood' => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-ResidualLikelihood'] ),
            'ZRM-ResidualImpact'     => _RecordValueGet( Record => $Row, Fields => ['ZTemplate-ResidualImpact'] ),
        );

        my %Defaults = _RiskStatementDefaults(
            RiskStatementID => $Mapped{'ZRM-RiskStatement'},
        );

        for my $Field ( keys %Defaults ) {
            $Mapped{$Field} = $Defaults{$Field}
                if !defined $Mapped{$Field} || $Mapped{$Field} eq '';
        }

        $Mapped{'ZRM-InherentCalculatedRisk'} = _RiskScoreCalculate(
            $Mapped{'ZRM-InherentLikelihood'},
            $Mapped{'ZRM-InherentImpact'},
        );
        $Mapped{'ZRM-ResidualCalculatedRisk'} = _RiskScoreCalculate(
            $Mapped{'ZRM-ResidualLikelihood'},
            $Mapped{'ZRM-ResidualImpact'},
        );

        for my $Field (
            qw(
            ZRM-RiskStatement
            ZRM-ImpactCategory
            ZRM-RiskCategory
            ZRM-InherentLikelihood
            ZRM-InherentImpact
            ZRM-ResidualLikelihood
            ZRM-ResidualImpact
            )
            )
        {
            $Mapped{$Field} = _SetEntityValueNormalize( $Mapped{$Field} );
        }

        for my $Field (
            qw(
            ZRM-RiskDetail
            ZRM-RiskAction
            ZRM-RiskOwner
            ZRM-RiskPlan
            ZRM-InherentCalculatedRisk
            ZRM-ResidualCalculatedRisk
            )
            )
        {
            $Mapped{$Field} = _ScalarValueNormalize( $Mapped{$Field} );
        }

        push @MappedRows, \%Mapped;
    }

    return \@MappedRows if @MappedRows;
    return;
}

sub _SetRowsNormalize {
    my ($Rows) = @_;

    return if !$Rows;
    return $Rows if ref $Rows eq 'ARRAY';
    return if ref $Rows ne 'HASH';

    for my $Key (qw(Values Value Content Items Rows)) {
        my $Value = $Rows->{$Key};
        next if ref $Value ne 'ARRAY';
        return $Value if @{$Value};
    }

    return [$Rows];
}

sub _ObjectValueGet {
    my (%Param) = @_;

    my $Object = $Param{Object};
    my $Field  = $Param{Field};

    return if !$Object || ref $Object ne 'HASH';
    return if !$Field;

    for my $Key ( 'DynamicField_' . $Field, $Field ) {
        return $Object->{$Key} if defined $Object->{$Key};
    }

    my $XMLData = $Object->{XMLData};
    return if ref $XMLData ne 'HASH';

    my $Value = $XMLData->{$Field};
    if ( ref $Value eq 'HASH' ) {
        my $Normalized = _NormalizeValue($Value);
        return defined $Normalized ? $Normalized : $Value;
    }
    return _NormalizeValue($Value) if ref $Value ne 'ARRAY';

    my @Values;
    for my $Item ( @{$Value} ) {
        if ( ref $Item eq 'HASH' ) {
            my $Normalized = _NormalizeValue($Item);
            push @Values, defined $Normalized ? $Normalized : $Item;
            next;
        }
        push @Values, $Item;
    }

    return \@Values if @Values > 1;
    return $Values[0] if @Values;
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

sub _GovernanceObjectResolve {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );
    return if !defined $Value || $Value eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    if ( $Value =~ m{\A\d+\z} ) {
        my $Object = eval {
            $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $Value,
                DynamicFields      => 1,
                Silent             => 1,
            );
        };
        return $Object if $Object && ref $Object eq 'HASH';
    }

    my $Search = $Value;
    $Search =~ s{\A [^:]+: \s*}{}xms;
    $Search =~ s{\s+\z}{};
    return if $Search eq '';

    my %ClassFilter = ref $Param{Classes} eq 'ARRAY' && @{ $Param{Classes} }
        ? ( Classes => $Param{Classes} )
        : ();

    my @SearchParam;
    for my $Name ( $Search, "%$Search%" ) {
        push @SearchParam, {
            Name   => $Name,
            Result => 'ARRAY',
            Limit  => 1,
            %ClassFilter,
        };
        push @SearchParam, {
            Number => $Name,
            Result => 'ARRAY',
            Limit  => 1,
            %ClassFilter,
        };
    }

    SEARCH:
    for my $SearchParam (@SearchParam) {
        my @IDs = eval {
            $GovernanceObjectObject->GovernanceObjectSearch( %{$SearchParam} );
        };
        next SEARCH if !@IDs;

        my $Object = eval {
            $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $IDs[0],
                DynamicFields      => 1,
                Silent             => 1,
            );
        };
        return $Object if $Object && ref $Object eq 'HASH';
    }

    return;
}

sub _RiskStatementDefaults {
    my (%Param) = @_;

    my $RiskStatementID = _NormalizeValue( $Param{RiskStatementID} );
    return if !$RiskStatementID;

    my $GovernanceObject = _GovernanceObjectResolve(
        Value   => $RiskStatementID,
        Classes => ['RiskStatement'],
    );

    return if !$GovernanceObject || ref $GovernanceObject ne 'HASH';

    my %Defaults;
    my @DefaultFields = (
        { Source => 'ZRM-ImpactCategoryGO', Target => 'ZRM-ImpactCategory',     Type => 'GeneralCatalog' },
        { Source => 'ZRM-RiskCategoryGO',   Target => 'ZRM-RiskCategory',       Type => 'GeneralCatalog' },
        { Source => 'ZRM-BaseLikelihood',   Target => 'ZRM-InherentLikelihood', Type => 'GeneralCatalog' },
        { Source => 'ZRM-BaseImpact',       Target => 'ZRM-InherentImpact',     Type => 'GeneralCatalog' },
        { Source => 'ZRM-RiskDetail',       Target => 'ZRM-RiskDetail' },
    );

    FIELD:
    for my $Field (@DefaultFields) {
        my $Value = _ObjectValueGet(
            Object => $GovernanceObject,
            Field  => $Field->{Source},
        );
        next FIELD if !defined $Value || $Value eq '';

        if ( ( $Field->{Type} || '' ) eq 'GeneralCatalog' ) {
            $Value = _GeneralCatalogValueWithName($Value);
        }

        $Defaults{ $Field->{Target} } = $Value;
    }

    return %Defaults;
}

sub _GeneralCatalogValueWithName {
    my ($Value) = @_;

    my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
    my @Expanded;
    my %Seen;

    VALUE:
    for my $ItemID (@Values) {
        next VALUE if !defined $ItemID || $ItemID eq '';

        if ( !$Seen{$ItemID}++ ) {
            push @Expanded, $ItemID;
        }

        next VALUE if $ItemID !~ m{\A\d+\z};

        my $Item = eval {
            $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
                ItemID => $ItemID,
            );
        };

        next VALUE if !$Item || ref $Item ne 'HASH';
        next VALUE if !defined $Item->{Name} || $Item->{Name} eq '';
        next VALUE if $Seen{ $Item->{Name} }++;

        push @Expanded, $Item->{Name};
    }

    return $Expanded[0] if @Expanded == 1;
    return \@Expanded if @Expanded;
    return;
}

sub _RiskScoreCalculate {
    my ( $Likelihood, $Impact ) = @_;

    $Likelihood = _NormalizeValue($Likelihood);
    $Impact     = _NormalizeValue($Impact);

    return '' if !defined $Likelihood || $Likelihood eq '';
    return '' if !defined $Impact     || $Impact eq '';
    return '' if $Likelihood !~ m{\A-?\d+(?:\.\d+)?\z};
    return '' if $Impact     !~ m{\A-?\d+(?:\.\d+)?\z};

    return $Likelihood * $Impact;
}

1;
