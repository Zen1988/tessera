# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMChapterDirector.pm
# --
# ZTSM Runtime Orchestration Director
#
# Purpose:
# - Coordinate ChapterPlay execution
# - Validate orchestration completion
# - Validate participation weightage
# - Expand ChapterPlay when participation insufficient
# - Escalate mandatory failures
# - Advance BlueBook orchestration
#
# Philosophy:
# Director coordinates runtime execution.
# Participants execute ChapterPlays.
#
# Powered by Zen ☕
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);
use Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookDirector ();
use Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookResume ();
use Kernel::System::ZTSMBlueBookRuntime ();

our @ObjectDependencies = (
    'Kernel::System::Ticket',
    'Kernel::System::Log',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

# ------------------------------------------------------------ #
# NORMALIZE VALUE
# ------------------------------------------------------------ #

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return $Value->[0];
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

sub _NeutralClosureState {
    my ($State) = @_;

    return if !defined $State;
    return 1 if $State eq 'closed no action';
    return 1 if $State eq 'closed duplicate';

    return;
}

sub _OutcomeValue {
    my ($Ticket) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';

    my $Outcome = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Outcome'} );
    return $Outcome if defined $Outcome && $Outcome ne '';

    my $State = $Ticket->{State} || '';
    return '0'  if $State eq 'closed successful';
    return '1'  if $State eq 'closed no action';
    return '1'  if $State eq 'closed duplicate';
    return '-1' if $State eq 'closed rejected';
    return '-1' if $State eq 'closed unsuccessful';
    return '-2' if $State eq 'closed rollback';

    return;
}

# ------------------------------------------------------------ #
# RUN
# ------------------------------------------------------------ #

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get(
        'Kernel::System::Ticket'
    );

    my $LogObject = $Kernel::OM->Get(
        'Kernel::System::Log'
    );

    my $DynamicFieldObject = $Kernel::OM->Get(
        'Kernel::System::DynamicField'
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get(
        'Kernel::System::DynamicField::Backend'
    );

    # -------------------------------------------------------- #
    # VALIDATE
    # -------------------------------------------------------- #

    return if !$Param{Ticket};

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};

    return if !$TicketID;

    if ( _TicketOnHold($Ticket) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMChapterDirector: Ticket is onhold, skip chapter orchestration TicketID=$TicketID",
        );
        return 1;
    }

    # -------------------------------------------------------- #
    # CHAPTERPLAY CONTEXT
    # -------------------------------------------------------- #

    my $ParentTicketID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Parent'}
    );

    my $BlueBook = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueBook'}
    );

    my $Chapter = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Chapter'}
    );

    my $BlueLevel = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueLevel'}
    );

    my $Mandatory = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Mandatory'}
    );

    my $RequiredWeightage = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-RequiredWeightage'}
    ) || 1;

    my %ParentTicket;
    if ($ParentTicketID) {
        %ParentTicket = $TicketObject->TicketGet(
            TicketID      => $ParentTicketID,
            DynamicFields => 1,
            UserID        => 1,
            Silent        => 1,
        );
    }

    # -------------------------------------------------------- #
    # CHAPTERPLAY SEARCH
    # -------------------------------------------------------- #

    my @ChapterPlays = $TicketObject->TicketSearch(

        Result => 'ARRAY',

        'DynamicField_ZTicket-Parent' => {
            Equals => $ParentTicketID,
        },

        'DynamicField_ZTicket-BlueBook' => {
            Equals => $BlueBook,
        },

        'DynamicField_ZTicket-Chapter' => {
            Equals => $Chapter,
        },

        'DynamicField_ZTicket-BlueLevel' => {
            Equals => $BlueLevel,
        },

        UserID => 1,
    );

    # -------------------------------------------------------- #
    # RUNTIME ORCHESTRATION STATE
    # -------------------------------------------------------- #

    my $CurrentWeightage = 0;

    my $AllCompleted = 1;

    my $FailureState;

    PLAY:
    for my $PlayTicketID (@ChapterPlays) {

        my %PlayTicket = $TicketObject->TicketGet(

            TicketID      => $PlayTicketID,

            DynamicFields => 1,

            UserID        => 1,
        );

        next PLAY if !%PlayTicket;

        my $OwnerWeightage = _NormalizeValue(
            $PlayTicket{
                'DynamicField_ZTicket-OwnerWeightage'
            }
        ) || 0;

        
        #
        # Completion state
        #

        my $StateType = $PlayTicket{StateType};

        if (
            $StateType ne 'closed'
        ) {
            $AllCompleted = 0;
        }else{
			$CurrentWeightage += $OwnerWeightage;
		}

		my $State = $PlayTicket{State};
		
        #
        # Failure detection
        #
		
        if (
            $State eq 'closed rollback' || $State eq 'closed rejected' || $State eq 'closed unsuccessful'
        ) {

            $FailureState = $State;
        }
    }

    # -------------------------------------------------------- #
    # MANDATORY FAILURE ESCALATION
    # -------------------------------------------------------- #

    if (
        $Mandatory
        && defined $FailureState
        && $ParentTicketID
    ) {
        my $ParentOutcome = $FailureState eq 'closed rollback' ? '-2' : '-1';
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => 'ZTicket-Outcome',
        );

        if ($DynamicFieldConfig) {
            $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ParentTicketID,
                Value              => $ParentOutcome,
                UserID             => 1,
            );
        }

        $TicketObject->TicketStateSet(

            TicketID => $ParentTicketID,

            State => $FailureState,

            UserID => 1,
        );

        my $Body
            = "** Note: This is a system-generated orchestration update message.\n\n"
            . "Mandatory Chapter failed.\n\n"
            . "BlueBook:\n"
            . ( $BlueBook || 'N/A' )
            . "\n\n"
            . "Chapter:\n"
            . ( $Chapter || 'N/A' )
            . "\n\n"
            . "BlueLevel:\n"
            . ( $BlueLevel || 'N/A' )
            . "\n\n"
            . "Result:\n"
            . "Parent orchestration failed.";

        ZTSMArticleCreate(
            %Param,
            TicketID => $ParentTicketID,
            Subject  => 'ZTSM Mandatory Chapter Failed',
            Body     => $Body,
            HistoryComment =>
                'ZTSM: Mandatory Chapter failed',
            UserID => 1,
        );
		
		# -------------------------------------------------------- #
		# CASCADING EFFECT
		# -------------------------------------------------------- #

		OPENTKT:
		for my $PlayTicketID (@ChapterPlays) {

			my %PlayTicket = $TicketObject->TicketGet(

				TicketID      => $PlayTicketID,

				DynamicFields => 1,

				UserID        => 1,
			);

			next OPENTKT if !%PlayTicket;
			
			next OPENTKT
				if $PlayTicketID == $TicketID;

			next OPENTKT
				if $PlayTicket{StateType} eq 'closed';
			
			$TicketObject->TicketStateSet(

				TicketID => $PlayTicketID,

				State => 'closed cascading',

				UserID => 1,
			);
			
			ZTSMArticleCreate(
				%Param,
				TicketID => $PlayTicketID,
				Subject  => 'Closed Cascading',
				Body     => $Body,
				HistoryComment =>
					'ZTSM: Closed cascading',
				UserID => 1,
			);
		}	


        $LogObject->Log(

            Priority => 'error',

            Message =>
                  'ZTSMChapterDirector: '
                . 'Mandatory Chapter failed '
                . "ParentTicketID=$ParentTicketID "
                . "Chapter=$Chapter",
        );
		
        if ( %ParentTicket && ( $ParentTicket{State} || '' ) eq 'follow-up' ) {
            $Self->Run(
                %Param,
                Ticket => \%ParentTicket,
                UserID => 1,
            );
        }
		

        return 1;
    }

    # -------------------------------------------------------- #
    # WAIT FOR COMPLETION
    # -------------------------------------------------------- #

    if ( !$AllCompleted ) {

        $LogObject->Log(

            Priority => 'notice',

            Message =>
                  'ZTSMChapterDirector: '
                . 'Waiting for ChapterPlay completion '
                . "Chapter=$Chapter "
                . "BlueLevel=$BlueLevel",
        );

        return 1;
    }

    # -------------------------------------------------------- #
    # MANDATORY OUTCOME ROLL-UP
    # -------------------------------------------------------- #

    my @BlueLevelPlays = Kernel::System::ZTSMBlueBookRuntime::ChildTicketIDsGet(
        ParentTicketID => $ParentTicketID,
        BlueBookID     => $BlueBook,
        BlueLevel      => $BlueLevel,
        UserID         => 1,
    );

    my @MandatoryOutcomes;
    my $RollbackOutcome;
    my $FailedOutcome;

    BLUELEVELPLAY:
    for my $BlueLevelPlayID (@BlueLevelPlays) {
        my %BlueLevelPlay = $TicketObject->TicketGet(
            TicketID      => $BlueLevelPlayID,
            DynamicFields => 1,
            UserID        => 1,
            Silent        => 1,
        );

        next BLUELEVELPLAY if !%BlueLevelPlay;
        next BLUELEVELPLAY if !_NormalizeValue( $BlueLevelPlay{'DynamicField_ZTicket-Mandatory'} );

        my $Outcome = _OutcomeValue( \%BlueLevelPlay );
        next BLUELEVELPLAY if !defined $Outcome || $Outcome eq '';

        push @MandatoryOutcomes, $Outcome;
        $RollbackOutcome = 1 if $Outcome eq '-2';
        $FailedOutcome   = 1 if $Outcome eq '-1';
    }

    if (@MandatoryOutcomes) {
        my $ParentOutcome;
        my $ParentHardStopState;

        if ($RollbackOutcome) {
            $ParentOutcome       = '-2';
            $ParentHardStopState = 'closed rollback';
        }
        elsif ($FailedOutcome) {
            $ParentOutcome       = '-1';
            $ParentHardStopState = 'closed unsuccessful';
        }
        else {
            my $PartialOutcome;
            my $SuccessfulOutcome;
            my $NoActionOutcome;

            OUTCOME:
            for my $Outcome (@MandatoryOutcomes) {
                $PartialOutcome    = 1 if $Outcome eq '2';
                $SuccessfulOutcome = 1 if $Outcome eq '0';
                $NoActionOutcome   = 1 if $Outcome eq '1';
            }

            if ($PartialOutcome) {
                $ParentOutcome = '2';
            }
            elsif ( @MandatoryOutcomes == 1 ) {
                $ParentOutcome = $MandatoryOutcomes[0];
            }
            elsif ($SuccessfulOutcome) {
                $ParentOutcome = '0';
            }
            elsif ($NoActionOutcome) {
                $ParentOutcome = '1';
            }
        }

        if ( defined $ParentOutcome && $ParentOutcome ne '' ) {
            my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
                Name => 'ZTicket-Outcome',
            );

            if ($DynamicFieldConfig) {
                $DynamicFieldBackendObject->ValueSet(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    ObjectID           => $ParentTicketID,
                    Value              => $ParentOutcome,
                    UserID             => 1,
                );
            }
        }

        if ($ParentHardStopState) {
            $TicketObject->TicketStateSet(
                TicketID => $ParentTicketID,
                State    => $ParentHardStopState,
                UserID   => 1,
            );

            my $Body
                = "** Note: This is a system-generated orchestration update message.\n\n"
                . "Mandatory BlueBook outcome caused a hard stop.\n\n"
                . "BlueBook:\n"
                . ( $BlueBook || 'N/A' )
                . "\n\n"
                . "BlueLevel:\n"
                . ( $BlueLevel || 'N/A' )
                . "\n\n"
                . "Parent Outcome:\n"
                . $ParentOutcome
                . "\n\n"
                . "Parent State:\n"
                . $ParentHardStopState;

            ZTSMArticleCreate(
                %Param,
                TicketID => $ParentTicketID,
                Subject  => 'ZTSM Mandatory Outcome Hard Stop',
                Body     => $Body,
                HistoryComment =>
                    'ZTSM: Mandatory outcome hard stop',
                UserID => 1,
            );

            if ( %ParentTicket && ( $ParentTicket{State} || '' ) eq 'follow-up' ) {
                $Self->Run(
                    %Param,
                    Ticket => \%ParentTicket,
                    UserID => 1,
                );
            }

            return 1;
        }
    }

    # -------------------------------------------------------- #
    # SOLE MANDATORY NO-ACTION / DUPLICATE CLOSURE
    # -------------------------------------------------------- #

    if (
        $Mandatory
        && _NeutralClosureState( $Ticket->{State} )
        && $ParentTicketID
    ) {
        if ( @BlueLevelPlays == 1 && $BlueLevelPlays[0] == $TicketID ) {
            $TicketObject->TicketStateSet(
                TicketID => $ParentTicketID,
                State    => $Ticket->{State},
                UserID   => 1,
            );

            my $Body
                = "** Note: This is a system-generated orchestration update message.\n\n"
                . "Sole mandatory BlueBook task closed without execution.\n\n"
                . "BlueBook:\n"
                . ( $BlueBook || 'N/A' )
                . "\n\n"
                . "Chapter:\n"
                . ( $Chapter || 'N/A' )
                . "\n\n"
                . "BlueLevel:\n"
                . ( $BlueLevel || 'N/A' )
                . "\n\n"
                . "Result:\n"
                . "Parent ticket closed as "
                . $Ticket->{State}
                . ".";

            ZTSMArticleCreate(
                %Param,
                TicketID => $ParentTicketID,
                Subject  => 'ZTSM Parent Closed Without Action',
                Body     => $Body,
                HistoryComment =>
                    'ZTSM: Parent closed from sole mandatory no-action task',
                UserID => 1,
            );

            $LogObject->Log(
                Priority => 'notice',
                Message  =>
                      'ZTSMChapterDirector: '
                    . 'Sole mandatory neutral closure propagated '
                    . "ParentTicketID=$ParentTicketID "
                    . "ChildTicketID=$TicketID "
                    . "State=$Ticket->{State}",
            );

            return 1;
        }
    }

    # -------------------------------------------------------- #
    # WEIGHTAGE VALIDATION
    # -------------------------------------------------------- #

    if ( $CurrentWeightage < $RequiredWeightage && $AllCompleted) {

        #
        # Duplicate ChapterPlay
        #

        my $NewTicketID = $TicketObject->TicketCreate(

            TN => undef,

            Title => $Ticket->{Title},

            Queue => $Ticket->{Queue},

            Lock => 'unlock',

            Priority => $Ticket->{Priority},

            State => 'new',

            CustomerUser => $Ticket->{CustomerUserID},

            OwnerID => 1,

            UserID => 1,

            Type => $Ticket->{Type},

            ServiceID => $Ticket->{ServiceID},

            SLAID => $Ticket->{SLAID},

            ResponsibleID => 1,
        );

        if ($NewTicketID) {

            my @CopyFields = (

                'ZTicket-Parent',
                'ZTicket-BlueBook',
                'ZTicket-BlueLevel',
                'ZTicket-Chapter',
                'ZTicket-Profile',
                'ZTicket-Mandatory',
                'ZTicket-Strict',
                'ZTicket-Duration',
                'ZTicket-OwnerGroup',
                'ZTicket-RequiredWeightage',
                'ZTicket-Role',
            );

            FIELD:
            for my $FieldName (@CopyFields) {

                my $Value = _NormalizeValue(
                    $Ticket->{
                        'DynamicField_' . $FieldName
                    }
                );

                next FIELD if !defined $Value;

                my $DynamicFieldConfig
                    = $DynamicFieldObject->DynamicFieldGet(
                        Name => $FieldName,
                    );

                next FIELD if !$DynamicFieldConfig;

                $DynamicFieldBackendObject->ValueSet(

                    DynamicFieldConfig => $DynamicFieldConfig,

                    ObjectID => $NewTicketID,

                    Value => $Value,

                    UserID => 1,
                );
            }

            Kernel::System::ZTSMBlueBookRuntime::ChildProcessSet(
                TicketID => $NewTicketID,
                UserID   => 1,
            );

            my $Body
                = "** Note: This is a system-generated orchestration update message.\n\n"
                . "Additional ChapterPlay generated.\n\n"
                . "Reason:\n"
                . "Required execution weightage not fulfilled.\n\n"
                . "Current Weightage:\n"
                . $CurrentWeightage
                . "\n\n"
                . "Required Weightage:\n"
                . $RequiredWeightage;

            ZTSMArticleCreate(
                %Param,
                TicketID => $ParentTicketID,
                Subject  => 'ZTSM Additional ChapterPlay Generated',
                Body     => $Body,
                HistoryComment =>
                    'ZTSM: Additional ChapterPlay generated',
                UserID => 1,
            );
        }

        return 1;
    }

    # -------------------------------------------------------- #
    # CHAPTER COMPLETED
    # -------------------------------------------------------- #

    my $Body
        = "** Note: This is a system-generated orchestration update message.\n\n"
        . "Chapter completed successfully.\n\n"
        . "BlueBook:\n"
        . ( $BlueBook || 'N/A' )
        . "\n\n"
        . "Chapter:\n"
        . ( $Chapter || 'N/A' )
        . "\n\n"
        . "BlueLevel:\n"
        . ( $BlueLevel || 'N/A' )
        . "\n\n"
        . "Participation Weightage:\n"
        . $CurrentWeightage
        . " / "
        . $RequiredWeightage;

    ZTSMArticleCreate(
        %Param,
        TicketID => $ParentTicketID,
        Subject  => 'ZTSM Chapter Completed',
        Body     => $Body,
        HistoryComment =>
            'ZTSM: Chapter completed '
            . 'Chapter='
            . ( $Chapter || 'N/A' ),
        UserID => 1,
    );

    # -------------------------------------------------------- #
    # NEXT CHAPTER
    # -------------------------------------------------------- #

    #
    # BlueBookReader will:
    # - resolve next Chapter
    # - spawn next ChapterPlay
    # - continue orchestration
    #

    $LogObject->Log(

        Priority => 'notice',

        Message =>
              'ZTSMChapterDirector: '
            . 'Chapter completed '
            . "ParentTicketID=$ParentTicketID "
            . "Chapter=$Chapter "
            . "Weightage=$CurrentWeightage/$RequiredWeightage",
    );

    if ( !%ParentTicket ) {
        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  'ZTSMChapterDirector: '
                . "Parent ticket not found ParentTicketID=$ParentTicketID "
                . "ChildTicketID=$TicketID",
        );

        return 1;
    }

    if ( ( $ParentTicket{State} || '' ) eq 'follow-up' ) {
        $TicketObject->TicketStateSet(
            TicketID => $ParentTicketID,
            State    => 'in-progress',
            UserID   => 1,
        );

        ZTSMArticleCreate(
            %Param,
            TicketID => $ParentTicketID,
            Subject  => 'ZTSM Follow-up Completed',
            Body     =>
                  "** Note: This is a system-generated follow-up orchestration update message.\n\n"
                . "Follow-up BlueBook completed successfully.\n\n"
                . "PurpleBook:\n"
                . ( $BlueBook || 'N/A' )
                . "\n\n"
                . "Original ticket returned to in-progress.",
            HistoryComment => 'ZTSM: Follow-up completed',
            UserID         => 1,
        );

        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  'ZTSMChapterDirector: '
                . 'Follow-up BlueBook complete, original ticket returned to in-progress '
                . "ParentTicketID=$ParentTicketID "
                . "PurpleBook=$BlueBook",
        );

        return 1;
    }

    my $BlueLevelComplete = Kernel::System::ZTSMBlueBookRuntime::LevelComplete(
        ParentTicketID => $ParentTicketID,
        BlueBookID     => $BlueBook,
        BlueLevel      => $BlueLevel,
        UserID         => 1,
    );

    if ( !$BlueLevelComplete ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  'ZTSMChapterDirector: '
                . 'Waiting for BlueLevel completion '
                . "ParentTicketID=$ParentTicketID "
                . "BlueBook=$BlueBook "
                . "BlueLevel=$BlueLevel",
        );

        return 1;
    }

    my $BlueBookObject = Kernel::System::ZTSMBlueBookRuntime::BlueBookGet(
        BlueBookID => $BlueBook,
    );

    my @BlueBookRecords = Kernel::System::ZTSMBlueBookRuntime::RecordsParse(
        BlueBook => $BlueBookObject,
    );

    my $NextBlueLevel = Kernel::System::ZTSMBlueBookRuntime::NextBlueLevelGet(
        CurrentBlueLevel => $BlueLevel,
        Records          => \@BlueBookRecords,
    );

    if ( defined $NextBlueLevel && $NextBlueLevel ne '' ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  'ZTSMChapterDirector: '
                . 'BlueLevel complete, advancing BlueBook '
                . "ParentTicketID=$ParentTicketID "
                . "BlueBook=$BlueBook "
                . "FromBlueLevel=$BlueLevel "
                . "ToBlueLevel=$NextBlueLevel",
        );

        my $BlueBookDirector = Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookDirector->new();

        return $BlueBookDirector->Run(
            %Param,
            Ticket => \%ParentTicket,
            UserID => 1,
        );
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              'ZTSMChapterDirector: '
            . 'BlueBook complete, resuming StateBook '
            . "ParentTicketID=$ParentTicketID "
            . "BlueBook=$BlueBook "
            . "BlueLevel=$BlueLevel",
    );

    my $StateBookResume = Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookResume->new();

    return $StateBookResume->Run(
        %Param,
        Ticket => \%ParentTicket,
        UserID => 1,
    );

    return 1;
}

1;
