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

    # -------------------------------------------------------- #
    # CHAPTERPLAY SEARCH
    # -------------------------------------------------------- #

    my @ChapterPlays = $TicketObject->TicketSearch(

        Result => 'ARRAY',

        DynamicField_ZTicket_Parent => {
            Equals => $ParentTicketID,
        },

        DynamicField_ZTicket_BlueBook => {
            Equals => $BlueBook,
        },

        DynamicField_ZTicket_Chapter => {
            Equals => $Chapter,
        },

        DynamicField_ZTicket_BlueLevel => {
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

        $TicketObject->ArticleCreate(

            TicketID => $ParentTicketID,

            ArticleType => 'note-internal',

            SenderType => 'system',

            Subject => 'ZTSM Mandatory Chapter Failed',

            Body => $Body,

            ContentType => 'text/plain; charset=utf-8',

            HistoryType => 'AddNote',

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
			
			$TicketObject->ArticleCreate(

				TicketID => $PlayTicketID,

				ArticleType => 'note-internal',

				SenderType => 'system',

				Subject => 'Closed Cascading',

				Body => $Body,

				ContentType => 'text/plain; charset=utf-8',

				HistoryType => 'AddNote',

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
                'ZTicket-Mandatory',
                'ZTicket-Strict',
                'ZTicket-Duration',
                'ZTicket-OwnerGroup',
                'ZTicket-RequiredWeightage',
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

            $TicketObject->ArticleCreate(

                TicketID => $ParentTicketID,

                ArticleType => 'note-internal',

                SenderType => 'system',

                Subject => 'ZTSM Additional ChapterPlay Generated',

                Body => $Body,

                ContentType => 'text/plain; charset=utf-8',

                HistoryType => 'AddNote',

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

    $TicketObject->ArticleCreate(

        TicketID => $ParentTicketID,

        ArticleType => 'note-internal',

        SenderType => 'system',

        Subject => 'ZTSM Chapter Completed',

        Body => $Body,

        ContentType => 'text/plain; charset=utf-8',

        HistoryType => 'AddNote',

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

    return 1;
}

1;
