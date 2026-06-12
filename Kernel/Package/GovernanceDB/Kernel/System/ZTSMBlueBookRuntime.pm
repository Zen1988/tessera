# --
# Kernel/System/ZTSMBlueBookRuntime.pm
# --

package Kernel::System::ZTSMBlueBookRuntime;

use strict;
use warnings;

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        $Value = $Value->[0];
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Content} if defined $Value->{Content};
        return;
    }

    return $Value;
}

sub _RecordValueGet {
    my (%Param) = @_;

    my $Record = $Param{Record};

    return if !$Record || ref $Record ne 'HASH';

    FIELD:
    for my $Field ( @{ $Param{Fields} || [] } ) {

        next FIELD if !exists $Record->{$Field};

        my $Value = ref $Record->{$Field} eq 'HASH'
            ? $Record->{$Field}->{Content}
            : $Record->{$Field};

        $Value = _NormalizeValue($Value);

        return $Value if defined $Value && $Value ne '';
    }

    return;
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

        my $BlueLevel = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-BlueLevel', 'ZBlue-Level', 'ZBlue-Seq' ],
        ) || 1;

        my $Chapter = _RecordValueGet(
            Record => $Record,
            Fields => ['ZBlue-Chapter'],
        );

        next RECORD if !$Chapter;

        push @ParsedRecords, {
            BlueLevel => $BlueLevel,
            Chapter   => $Chapter,
            Type      => _TicketTypeResolve(
                Value => _RecordValueGet(
                    Record => $Record,
                    Fields => [ 'ZBlue-Type', 'ZBlue-TicketType' ],
                ),
            ),
            Activity => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Activity'] ),
            Profile => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Profile'] ),
            Role    => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Role'] ),
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
    my (%Param) = @_;

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

    if ( defined $Param{BlueLevel} && $Param{BlueLevel} ne '' ) {
        $Search{'DynamicField_ZTicket-BlueLevel'} = {
            Equals => $Param{BlueLevel},
        };
    }

    return $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(%Search);
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

    my @TicketIDs = ChildTicketIDsGet(%Param);

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
    my (%Param) = @_;

    return if !$Param{ParentTicketID};
    return if !$Param{BlueBookID};
    return if !defined $Param{BlueLevel};

    my @TicketIDs = ChildTicketIDsGet(%Param);

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

        $Chapter{$Chapter}->{Weightage} += _NormalizeValue(
            $ChildTicket{'DynamicField_ZTicket-OwnerWeightage'}
        ) || 0;
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

    my @ExistingTicketIDs = ChildTicketIDsGet(
        ParentTicketID => $Param{ParentTicketID},
        BlueBookID     => $Param{BlueBookID},
        BlueLevel      => $Param{BlueLevel},
        UserID         => $Param{UserID} || 1,
    );

    return @ExistingTicketIDs if @ExistingTicketIDs;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my @CreatedTicketIDs;

    RECORD:
    for my $Record (@Records) {

        next RECORD if !$Record;
        next RECORD if ref $Record ne 'HASH';
        next RECORD if $Record->{BlueLevel} ne $Param{BlueLevel};

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
            OwnerID       => 1,
            UserID        => $Param{UserID} || 1,
            Type          => $ChildType,
            ServiceID     => $ParentTicket->{ServiceID},
            SLAID         => $ParentTicket->{SLAID},
            ResponsibleID => 1,
        );

        next RECORD if !$NewTicketID;

        push @CreatedTicketIDs, $NewTicketID;

        my %ChildProcessContext = ChildProcessSet(
            TicketID => $NewTicketID,
            UserID   => $Param{UserID} || 1,
        );

        my $OwnerGroup = _SupportProfileResolve(
            Value  => $Record->{Profile},
            UserID => $Param{UserID} || 1,
        );

        my %FieldMap = (
            'ZTicket-Parent'            => $Param{ParentTicketID},
            'ZTicket-BlueBook'          => $Param{BlueBookID},
            'ZTicket-BlueLevel'         => $Record->{BlueLevel},
            'ZTicket-Chapter'           => $Record->{Chapter},
            'ZTicket-Application'       => $ParentTicket->{'DynamicField_ZTicket-Application'},
            'ZTicket-Profile'           => $Record->{Profile},
            'ZTicket-OwnerGroup'        => $OwnerGroup,
            'ZTicket-Role'              => $Record->{Role},
            'ZTicket-Mandatory'         => $Record->{Mandatory},
            'ZTicket-Strict'            => $Record->{Strict},
            'ZTicket-Duration'          => $Record->{Duration},
            'ZTicket-RequiredWeightage' => $Record->{RequiredWeightage} || 1,
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
                . $Param{ParentTicketID}
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
    }

    _TicketFieldSet(
        TicketID  => $Param{ParentTicketID},
        FieldName => 'ZTicket-BlueLevel',
        Value     => $Param{BlueLevel},
        UserID    => $Param{UserID} || 1,
    );

    return @CreatedTicketIDs;
}

1;
