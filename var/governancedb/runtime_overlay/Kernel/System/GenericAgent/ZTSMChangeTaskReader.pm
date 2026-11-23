# --
# Kernel/System/GenericAgent/ZTSMChangeTaskReader.pm
# --

package Kernel::System::GenericAgent::ZTSMChangeTaskReader;

use strict;
use warnings;

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);
use Kernel::System::ZTSMBlueBookRuntime ();
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::CustomerUser',
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

my @NormalPhases = qw(precheck implementation postchange);
my %SetFieldFor = (
    precheck       => 'ZCH-Precheck',
    implementation => 'ZCH-Implementation',
    postchange     => 'ZCH-PostChange',
    rollback       => 'ZCH-Rollback',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless $Self, $Type;

    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketID = $Param{TicketID};
    return 0 if !$TicketID;

    my $UserID       = $Param{UserID} || 1;
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Ticket       = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
        Silent        => 1,
    );

    return 1 if !IsHashRefWithData( \%Ticket );

    my $ParentTicketID = _NormalizeValue( $Ticket{'DynamicField_ZTicket-Parent'} ) || $TicketID;
    my %ParentTicket = $ParentTicketID == $TicketID
        ? %Ticket
        : $TicketObject->TicketGet(
            TicketID      => $ParentTicketID,
            DynamicFields => 1,
            UserID        => $UserID,
            Silent        => 1,
        );

    return 1 if !IsHashRefWithData( \%ParentTicket );
    return 1 if lc( $ParentTicket{Type} || '' ) ne 'change';
    return 1 if ( $ParentTicket{StateType} || '' ) eq 'closed';
    return 1 if _StateKey( $ParentTicket{State} ) ne 'inprogress';

    return $Self->_Advance(
        ParentTicketID => $ParentTicketID,
        ParentTicket   => \%ParentTicket,
        UserID         => $UserID,
    );
}

sub PlanComplete {
    my ( $Self, %Param ) = @_;

    return if !$Param{ParentTicketID};
    return if !IsHashRefWithData( $Param{ParentTicket} );

    my $Status = $Self->_PlanStatus(%Param);
    return $Status->{Complete} ? 1 : 0;
}

sub NormalProgressAllowed {
    my ( $Self, %Param ) = @_;

    return if !$Param{ParentTicketID};
    return if !IsHashRefWithData( $Param{ParentTicket} );

    my $Status = $Self->_PlanStatus(%Param);
    return if !$Status;
    return if $Status->{Failure} || $Status->{RollbackActive};

    return 1;
}

sub _Advance {
    my ( $Self, %Param ) = @_;

    my $Status = $Self->_PlanStatus(%Param);
    return 1 if !$Status;

    if ( $Status->{RollbackActive} ) {
        return $Self->_RollbackAdvance( %Param, Status => $Status );
    }

    if ( $Status->{Failure} ) {
        if ( !$Self->_HistoryCommentExists( %Param, Comment => 'ZTSM: Change rollback initiated' ) ) {
            $Self->_ParentArticle(
                %Param,
                Subject => 'DO-NOT-REPLY: Change rollback initiated.',
                Body    =>
                      "** Note: This is a system-generated orchestration update message.\n\n"
                    . "A mandatory change execution task failed.\n\n"
                    . "Failed Phase:\n$Status->{Failure}->{Phase}\n\n"
                    . "Failed Child Ticket:\n$Status->{Failure}->{TicketSummary}\n\n"
                    . "The shared rollback plan is now active. Normal Change and StateBook progression is stopped.",
                HistoryComment => 'ZTSM: Change rollback initiated',
            );
        }

        return $Self->_RollbackAdvance( %Param, Status => $Status );
    }

    for my $Phase (@NormalPhases) {
        my $PhaseStatus = $Status->{Phase}->{$Phase};
        next if !$PhaseStatus;

        $Self->_EligibleRowsSpawn(
            %Param,
            Phase       => $Phase,
            PhaseStatus => $PhaseStatus,
        );

        # Re-read after spawning so completion is evaluated from persisted evidence.
        $Status      = $Self->_PlanStatus(%Param);
        $PhaseStatus = $Status->{Phase}->{$Phase};

        return 1 if !$PhaseStatus->{Complete};

        my $PhaseCompletionComment = 'ZTSM: Change execution phase completed: ' . $Phase;
        if (
            $PhaseStatus->{HasRows}
            && !$Self->_HistoryCommentExists( %Param, Comment => $PhaseCompletionComment )
            )
        {
            $Self->_ParentArticle(
                %Param,
                Subject => 'DO-NOT-REPLY: Change execution phase completed.',
                Body    =>
                      "** Note: This is a system-generated orchestration update message.\n\n"
                    . "Change execution phase:\n"
                    . _PhaseLabel($Phase)
                    . "\n\nStatus:\nCompleted successfully",
                HistoryComment => $PhaseCompletionComment,
            );
        }
    }

    $Status = $Self->_PlanStatus(%Param);
    if (
        $Status->{Complete}
        && !$Self->_HistoryCommentExists( %Param, Comment => 'ZTSM: Change execution plan completed' )
        )
    {
        $Self->_ParentArticle(
            %Param,
            Subject => 'DO-NOT-REPLY: Change execution plan completed.',
            Body    =>
                  "** Note: This is a system-generated orchestration update message.\n\n"
                . "Pre-check, Implementation, and Post-change execution have completed successfully.\n\n"
                . "Control has returned to the parent Change Request. StateBook progression may continue only after the normal in-progress BlueBook is also complete.",
            HistoryComment => 'ZTSM: Change execution plan completed',
        );
    }

    return 1;
}

sub _RollbackAdvance {
    my ( $Self, %Param ) = @_;

    my $Status      = $Self->_PlanStatus(%Param);
    my $PhaseStatus = $Status->{Phase}->{rollback};

    if ( !$PhaseStatus->{HasRows} ) {
        if ( !$Self->_HistoryCommentExists( %Param, Comment => 'ZTSM: Change rollback unavailable' ) ) {
            $Self->_ParentArticle(
                %Param,
                Subject => 'DO-NOT-REPLY: Change rollback unavailable.',
                Body    =>
                      "** Note: This is a system-generated orchestration update message.\n\n"
                    . "A mandatory change execution task failed, but the Change Request contains no rollback task rows.\n\n"
                    . "Automatic lifecycle progression remains stopped.",
                HistoryComment => 'ZTSM: Change rollback unavailable',
            );
        }
        return 1;
    }

    $Self->_EligibleRowsSpawn(
        %Param,
        Phase       => 'rollback',
        PhaseStatus => $PhaseStatus,
    );

    $Status      = $Self->_PlanStatus(%Param);
    $PhaseStatus = $Status->{Phase}->{rollback};

    return 1 if !$PhaseStatus->{Complete};

    if ( !$Self->_HistoryCommentExists( %Param, Comment => 'ZTSM: Change rollback completed' ) ) {
        $Self->_ParentArticle(
            %Param,
            Subject => 'DO-NOT-REPLY: Change rollback completed.',
            Body    =>
                  "** Note: This is a system-generated orchestration update message.\n\n"
                . "The Change Request rollback plan completed successfully.\n\n"
                . "The parent Change Request is being closed as closed rollback. Normal StateBook progression will not continue.",
            HistoryComment => 'ZTSM: Change rollback completed',
        );
    }

    $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateSet(
        TicketID           => $Param{ParentTicketID},
        State              => 'closed rollback',
        SendNoNotification => 0,
        UserID             => $Param{UserID} || 1,
    );

    return 1;
}

sub _PlanStatus {
    my ( $Self, %Param ) = @_;

    my %Status = (
        Complete       => 1,
        RollbackActive => 0,
        Phase          => {},
    );

    my @Children = $Self->_ChildrenGet(%Param);

    PHASE:
    for my $Phase ( @NormalPhases, 'rollback' ) {
        my @Rows = $Self->_RowsGet(
            ParentTicket => $Param{ParentTicket},
            Phase        => $Phase,
        );

        my @PhaseChildren = grep {
            _NormalizeValue( $_->{'DynamicField_ZTicket-Stage'} ) eq "change-$Phase"
        } @Children;

        my %ChildrenByIdentity;
        for my $Child (@PhaseChildren) {
            my $Identity = join q{|},
                _NormalizeValue( $Child->{'DynamicField_ZTicket-BlueLevel'} ) || 0,
                _NormalizeValue( $Child->{'DynamicField_ZTicket-Chapter'} ) || 0;
            push @{ $ChildrenByIdentity{$Identity} }, $Child;
        }

        my $PhaseStatus = {
            AllGenerated             => 1,
            Children                 => \@PhaseChildren,
            ChildrenByIdentity       => \%ChildrenByIdentity,
            Complete                 => 1,
            CompletionArticleExists  => 0,
            HasRows                  => @Rows ? 1 : 0,
            Rows                     => \@Rows,
            Started                  => @PhaseChildren ? 1 : 0,
        };

        my %Level;
        for my $Row (@Rows) {
            push @{ $Level{ $Row->{BlueLevel} } }, $Row;
        }

        my $PriorMandatoryComplete = 1;
        LEVEL:
        for my $Level ( sort { $a <=> $b } keys %Level ) {
            my $LevelStatus = {
                Eligible => $PriorMandatoryComplete,
                Complete => 1,
                Rows     => $Level{$Level},
            };

            ROW:
            for my $Row ( @{ $Level{$Level} } ) {
                my $Identity = join q{|}, $Row->{BlueLevel}, $Row->{Seq};
                my @Matches  = @{ $ChildrenByIdentity{$Identity} || [] };
                my $Child    = $Matches[0];

                $Row->{Child}     = $Child;
                $Row->{Generated} = $Child ? 1 : 0;
                $PhaseStatus->{AllGenerated} = 0 if !$Child;

                next ROW if !$Row->{Mandatory};

                if ( !$Child ) {
                    $LevelStatus->{Complete} = 0;
                    next ROW;
                }

                if ( ( $Child->{StateType} || '' ) ne 'closed' ) {
                    $LevelStatus->{Complete} = 0;
                    next ROW;
                }

                if ( !_ChildSuccessful($Child) ) {
                    $LevelStatus->{Complete} = 0;
                    if ( $Phase ne 'rollback' && !$Status{Failure} ) {
                        $Status{Failure} = {
                            Phase         => _PhaseLabel($Phase),
                            TicketID      => $Child->{TicketID},
                            TicketSummary => _TicketSummary($Child),
                        };
                    }
                }
            }

            $LevelStatus->{Complete} = 0 if !$LevelStatus->{Eligible};
            $PriorMandatoryComplete &&= $LevelStatus->{Complete};
            $PhaseStatus->{Level}->{$Level} = $LevelStatus;
        }

        $PhaseStatus->{Complete} = $PriorMandatoryComplete;
        $Status{Phase}->{$Phase} = $PhaseStatus;

        if ( $Phase eq 'rollback' ) {
            $Status{RollbackActive} = @PhaseChildren ? 1 : 0;
            next PHASE;
        }

        $Status{Complete} &&= $PhaseStatus->{Complete} && $PhaseStatus->{AllGenerated};
    }

    # A recorded failure always takes precedence over normal completion.
    $Status{Complete} = 0 if $Status{Failure} || $Status{RollbackActive};

    return \%Status;
}

sub _EligibleRowsSpawn {
    my ( $Self, %Param ) = @_;

    my $Now = $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch();

    LEVEL:
    for my $Level ( sort { $a <=> $b } keys %{ $Param{PhaseStatus}->{Level} || {} } ) {
        my $LevelStatus = $Param{PhaseStatus}->{Level}->{$Level};
        next LEVEL if !$LevelStatus->{Eligible};

        ROW:
        for my $Row ( sort { $a->{Seq} <=> $b->{Seq} } @{ $LevelStatus->{Rows} || [] } ) {
            next ROW if $Row->{Generated};
            next ROW if $Row->{Strict} && !_ScheduleReached( Row => $Row, Now => $Now );

            $Self->_ChildSpawn(
                %Param,
                Row => $Row,
            );
        }
    }

    return 1;
}

sub _ChildSpawn {
    my ( $Self, %Param ) = @_;

    my $Row          = $Param{Row};
    my $ParentTicket = $Param{ParentTicket};
    my $UserID       = $Param{UserID} || 1;

    if ( $Row->{Owner} && !$Self->_OwnerInProfile( Profile => $Row->{Profile}, Owner => $Row->{Owner} ) ) {
        $Self->_ParentArticle(
            %Param,
            Subject => 'DO-NOT-REPLY: Change task assignment rejected.',
            Body    =>
                  "** Note: This is a system-generated orchestration update message.\n\n"
                . "Change execution task was not generated because the configured owner is not a member of the configured SupportProfile.\n\n"
                . "Phase:\n"
                . _PhaseLabel( $Param{Phase} )
                . "\n\nLevel:\n$Row->{BlueLevel}\n\nSequence:\n$Row->{Seq}\n\nProfile:\n"
                . ( $Row->{Profile} || 'N/A' )
                . "\n\nOwner:\n"
                . ( $Row->{Owner} || 'N/A' ),
            HistoryComment => 'ZTSM: Change task assignment rejected',
        );
        return;
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ChildType    = $Self->_TicketTypeResolve( Value => $Row->{TicketType} )
        || $ParentTicket->{Type}
        || 'Task';
    my $ParentRef = $ParentTicket->{TicketNumber} || $Param{ParentTicketID};
    my $Title = join ' - ', grep { defined $_ && $_ ne '' } (
        $ChildType,
        "Change#$ParentRef",
        _PhaseLabel( $Param{Phase} ),
        $Row->{Activity},
    );

    my $NewTicketID = $TicketObject->TicketCreate(
        TN                 => undef,
        Title              => $Title,
        Queue              => $ParentTicket->{Queue},
        Lock               => 'unlock',
        Priority           => $ParentTicket->{Priority},
        State              => 'new',
        CustomerUser       => $ParentTicket->{CustomerUserID},
        OwnerID            => 1,
        UserID             => $UserID,
        Type               => $ChildType,
        ServiceID          => $ParentTicket->{ServiceID},
        SLAID              => $ParentTicket->{SLAID},
        ResponsibleID      => 1,
        ParentTicketID     => $Param{ParentTicketID},
        ParentTicketNumber => $ParentTicket->{TicketNumber},
    );

    return if !$NewTicketID;

    Kernel::System::ZTSMBlueBookRuntime::ChildProcessSet(
        TicketID => $NewTicketID,
        UserID   => $UserID,
    );

    my %FieldMap = (
        'ZTicket-Parent'            => $Param{ParentTicketID},
        'ZTicket-Stage'             => "change-$Param{Phase}",
        'ZTicket-BlueLevel'         => $Row->{BlueLevel},
        'ZTicket-Chapter'           => $Row->{Seq},
        'ZTicket-Application'       => $ParentTicket->{'DynamicField_ZTicket-Application'},
        'ZTicket-Profile'           => $Row->{Profile},
        'ZTicket-OwnerGroup'        => $Row->{Profile},
        'ZTicket-Owner'             => $Row->{Owner},
        'ZTicket-OwnerWeightage'    => $Row->{Weightage},
        'ZTicket-RequiredWeightage' => $Row->{Weightage},
        'ZTicket-Mandatory'         => $Row->{Mandatory},
        'ZTicket-Strict'            => $Row->{Strict},
        'ZTicket-ScheduleStart'     => $Row->{ScheduleStart},
        'ZTicket-ScheduleFinish'    => $Row->{ScheduleFinish},
    );

    my @FieldOrder = (
        grep { $_ ne 'ZTicket-Parent' } sort keys %FieldMap,
        'ZTicket-Parent',
    );
    for my $FieldName (@FieldOrder) {
        next if !defined $FieldMap{$FieldName} || $FieldMap{$FieldName} eq '';
        $Self->_TicketFieldSet(
            TicketID  => $NewTicketID,
            FieldName => $FieldName,
            Value     => $FieldMap{$FieldName},
            UserID    => $UserID,
        );
    }

    my $Body =
          "** Note: This is a system-generated orchestration update message.\n\n"
        . "Change Task:\nInitiated\n\n"
        . "Phase:\n"
        . _PhaseLabel( $Param{Phase} )
        . "\n\nParent Ticket:\n"
        . _TicketSummary($ParentTicket)
        . "\n\nLevel:\n$Row->{BlueLevel}\n\nSequence:\n$Row->{Seq}\n\n"
        . "Scheduled Start:\n"
        . ( $Row->{ScheduleStart} || 'N/A' )
        . "\n\nScheduled Finish:\n"
        . ( $Row->{ScheduleFinish} || 'N/A' )
        . "\n\nMandatory:\n"
        . ( $Row->{Mandatory} ? 'Yes' : 'No' )
        . "\n\nStrict:\n"
        . ( $Row->{Strict} ? 'Yes' : 'No' )
        . "\n\nSupportProfile:\n"
        . ( $Row->{Profile} || 'N/A' )
        . "\n\nOwner:\n"
        . ( $Row->{Owner} || 'Unassigned' )
        . "\n\nWeightage:\n"
        . ( $Row->{Weightage} || 1 );

    $Body .= "\n\nDescription:\n$Row->{Description}" if $Row->{Description};

    ZTSMArticleCreate(
        TicketID             => $NewTicketID,
        Subject              => 'DO-NOT-REPLY: Change task initiated.',
        Body                 => $Body,
        HistoryComment       => 'ZTSM: Change task initiated',
        IsVisibleForCustomer => 1,
        UserID               => $UserID,
    );

    if ( $Row->{Template} ) {
        Kernel::System::ZTSMBlueBookRuntime::ChildTemplateApply(
            TicketID   => $NewTicketID,
            TemplateID => $Row->{Template},
            UserID     => $UserID,
        );
    }

    return $NewTicketID;
}

sub _RowsGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = $SetFieldFor{ $Param{Phase} };
    return if !$FieldName;

    my $Rows = $Param{ParentTicket}->{"DynamicField_$FieldName"};
    if ( ref $Rows eq 'HASH' ) {
        my $Normalized;
        for my $Key (qw(Values Value Content Items Rows)) {
            next if ref $Rows->{$Key} ne 'ARRAY';
            $Normalized = $Rows->{$Key};
            last;
        }
        $Rows = $Normalized || [$Rows];
    }
    return if ref $Rows ne 'ARRAY';

    my @Result;
    my $FallbackSeq = 0;

    for my $RawRow ( @{$Rows} ) {
        next if ref $RawRow ne 'HASH';
        $FallbackSeq++;

        my $BlueLevel = _RowValue( Row => $RawRow, Field => 'ZCH-BlueLevel' );
        my $Seq       = _RowValue( Row => $RawRow, Field => 'ZCH-Seq' );
        $BlueLevel = 1 if !defined $BlueLevel || $BlueLevel !~ m{\A\d+\z};
        $Seq       = $FallbackSeq if !defined $Seq || $Seq !~ m{\A\d+\z};

        push @Result, {
            Activity       => _RowValue( Row => $RawRow, Field => 'ZCH-Activity' ),
            BlueLevel      => 0 + $BlueLevel,
            Description    => _RowValue( Row => $RawRow, Field => 'ZCH-Description' ),
            Mandatory      => _TruthValue( _RowValue( Row => $RawRow, Field => 'ZCH-Mandatory' ) ),
            Owner          => _RowValue( Row => $RawRow, Field => 'ZCH-Owner' ),
            Profile        => _RowValue( Row => $RawRow, Field => 'ZCH-Profile' ),
            ScheduleFinish => _RowValue( Row => $RawRow, Field => 'ZCH-ScheduleFinish' ),
            ScheduleStart  => _RowValue( Row => $RawRow, Field => 'ZCH-ScheduleStart' ),
            Seq            => 0 + $Seq,
            Strict         => _TruthValue( _RowValue( Row => $RawRow, Field => 'ZCH-Strict' ) ),
            Template       => _RowValue( Row => $RawRow, Field => 'ZCH-Template' ),
            TicketType     => _RowValue( Row => $RawRow, Field => 'ZCH-TicketType' ),
            Weightage      => _RowValue( Row => $RawRow, Field => 'ZCH-Weightage' ) || 1,
        };
    }

    return @Result;
}

sub _ChildrenGet {
    my ( $Self, %Param ) = @_;

    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result => 'ARRAY',
        'DynamicField_ZTicket-Parent' => {
            Equals => $Param{ParentTicketID},
        },
        UserID => $Param{UserID} || 1,
    );

    my @Children;
    for my $TicketID (@TicketIDs) {
        my %Child = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $Param{UserID} || 1,
            Silent        => 1,
        );
        next if !IsHashRefWithData( \%Child );
        next if _NormalizeValue( $Child{'DynamicField_ZTicket-Stage'} ) !~ m{\Achange-};
        push @Children, \%Child;
    }

    return @Children;
}

sub _OwnerInProfile {
    my ( $Self, %Param ) = @_;

    return if !$Param{Profile} || !$Param{Owner};

    my @AssignmentIDs = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectSearch(
        Classes => ['SupportAssignment'],
        'DynamicField_ZTSMSupportAssignment-SupportProfile' => {
            Equals => $Param{Profile},
        },
        'DynamicField_ZTSMSupportAssignment-UserAccount' => {
            Equals => $Param{Owner},
        },
        Result => 'ARRAY',
    );

    return @AssignmentIDs ? 1 : 0;
}

sub _TicketTypeResolve {
    my ( $Self, %Param ) = @_;

    my $Value = _NormalizeValue( $Param{Value} );
    return if !defined $Value || $Value eq '';
    return $Value if $Value !~ m{\A\d+\z};

    my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
        ItemID => $Value,
    );

    return IsHashRefWithData($Item) ? $Item->{Name} : undef;
}

sub _TicketFieldSet {
    my ( $Self, %Param ) = @_;

    my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => $Param{FieldName},
    );
    return if !$Config || !$Config->{ID};

    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $Config,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID} || 1,
    );
}

sub _ParentArticle {
    my ( $Self, %Param ) = @_;

    return ZTSMArticleCreate(
        TicketID             => $Param{ParentTicketID},
        Subject              => $Param{Subject},
        Body                 => $Param{Body},
        HistoryComment       => $Param{HistoryComment},
        IsVisibleForCustomer => 1,
        UserID               => $Param{UserID} || 1,
    );
}

sub _HistoryCommentExists {
    my ( $Self, %Param ) = @_;

    return if !$Param{ParentTicketID} || !$Param{Comment};

    my @History = $Kernel::OM->Get('Kernel::System::Ticket')->HistoryGet(
        TicketID => $Param{ParentTicketID},
        UserID   => $Param{UserID} || 1,
    );

    for my $Entry (@History) {
        next if ref $Entry ne 'HASH';
        return 1 if ( $Entry->{HistoryComment} || '' ) eq $Param{Comment};
    }

    return;
}

sub _ScheduleReached {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Row}->{ScheduleStart} );
    return 1 if !defined $Value || $Value eq '' || $Value eq '0';

    my $DateTimeObject = eval {
        $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Value,
            },
        );
    };
    return if !$DateTimeObject;

    return $DateTimeObject->ToEpoch() <= $Param{Now} ? 1 : 0;
}

sub _ChildSuccessful {
    my ($Child) = @_;

    return lc( $Child->{State} || '' ) eq 'closed successful' ? 1 : 0;
}

sub _RowValue {
    my (%Param) = @_;

    my $Row   = $Param{Row};
    my $Field = $Param{Field};

    for my $Key ( $Field, "DynamicField_$Field" ) {
        next if !exists $Row->{$Key};
        return _NormalizeValue( $Row->{$Key} );
    }

    return;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;
    return _NormalizeValue( $Value->[0] ) if ref $Value eq 'ARRAY';
    if ( ref $Value eq 'HASH' ) {
        for my $Key (qw(Content Value ID Key)) {
            return _NormalizeValue( $Value->{$Key} ) if exists $Value->{$Key};
        }
        return;
    }

    $Value =~ s{\A\s+|\s+\z}{}g if !ref $Value;
    return $Value;
}

sub _TruthValue {
    my ($Value) = @_;

    $Value = _NormalizeValue($Value);
    return if !defined $Value;
    return $Value =~ m{\A(?:1|yes|true|on)\z}i ? 1 : 0;
}

sub _StateKey {
    my ($Value) = @_;

    $Value = lc( $Value || '' );
    $Value =~ s{[^a-z0-9]+}{}g;
    return $Value;
}

sub _PhaseLabel {
    my ($Phase) = @_;

    return 'Pre-check'      if $Phase eq 'precheck';
    return 'Implementation' if $Phase eq 'implementation';
    return 'Post-change'    if $Phase eq 'postchange';
    return 'Rollback'       if $Phase eq 'rollback';
    return $Phase;
}

sub _TicketSummary {
    my ($Ticket) = @_;

    return join ' - ', grep { defined $_ && $_ ne '' } (
        $Ticket->{TicketNumber} || $Ticket->{TicketID},
        $Ticket->{Title},
    );
}

1;
