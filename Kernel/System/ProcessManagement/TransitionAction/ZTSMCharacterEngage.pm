# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMCharacterEngage.pm
# --
# ZTSM Runtime Participation Engine
#
# Purpose:
# - Activate ChapterEngage participation
# - Resolve Support Assignment capability
# - Snapshot OwnerWeightage
# - Lock ChapterPlay ownership
# - Create orchestration narrative
#
# IMPORTANT:
# ACL controls who MAY engage.
# Process logic only records orchestration runtime.
#
# Philosophy:
# Users do not receive work.
# Users engage governed execution.
#
# Powered by Zen ☕
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMCharacterEngage;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

our @ObjectDependencies = (
    'Kernel::System::Ticket',
    'Kernel::System::Log',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::CustomerUser',
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

    my $ConfigItemObject = $Kernel::OM->Get(
        'Kernel::System::ITSMConfigItem'
    );

    my $CustomerUserObject = $Kernel::OM->Get(
        'Kernel::System::CustomerUser'
    );

    # -------------------------------------------------------- #
    # VALIDATE
    # -------------------------------------------------------- #

    return if !$Param{Ticket};

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};

    return if !$TicketID;

    my $UserID = $Param{UserID};

    return if !$UserID;

    # -------------------------------------------------------- #
    # RUNTIME CONTEXT
    # -------------------------------------------------------- #

    my $CurrentOwner = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Owner'}
    );

    my $SupportProfile = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-OwnerGroup'}
    );

    my $Chapter = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Chapter'}
    );

    my $BlueBook = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueBook'}
    );

    my $BlueLevel = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueLevel'}
    );

    my $RequiredWeightage = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-RequiredWeightage'}
    ) || 1;

    # -------------------------------------------------------- #
    # PREVENT DUPLICATE ENGAGEMENT
    # -------------------------------------------------------- #

    if ($CurrentOwner) {

        $LogObject->Log(

            Priority => 'notice',

            Message =>
                  'ZTSMCharacterEngage: '
                . 'ChapterPlay already engaged '
                . "TicketID=$TicketID",
        );

        return 1;
    }

    # -------------------------------------------------------- #
    # CUSTOMER USER RESOLUTION
    # -------------------------------------------------------- #

    my %UserData = $CustomerUserObject->CustomerUserDataGet(

        User => $UserID,
    );

    my $CustomerUserID = $UserData{UserLogin};

    return if !$CustomerUserID;

    # -------------------------------------------------------- #
    # SUPPORT ASSIGNMENT RESOLUTION
    # -------------------------------------------------------- #

    my $AssignmentList = $ConfigItemObject->ConfigItemSearch(

		Classes  => ['Support Assignment'],

		SearchByDynamicField => {

			'ZTSMSupportAssignment-SupportProfile'
				=> $SupportProfile,
			'ZTSMSupportAssignment-UserAccount'
				=> $CustomerUserID,
		},

		Result => 'ARRAY',
	);

	my $SelectedAssignment;

	PICK:
	for my $AssignmentID ( @{$AssignmentList} ) {

		my $Assignment = $ConfigItemObject->ConfigItemGet(

			ConfigItemID  => $AssignmentID,

			DynamicFields => 1,
		);

		next PICK if !$Assignment;
		next PICK if !$Assignment->{XMLData};

		#
		# First match fallback
		#

		if ( !$SelectedAssignment ) {

			$SelectedAssignment = $Assignment;
		}

		my $Type = _NormalizeValue(
			$Assignment->{XMLData}
			->{'ZTSMSupportAssignment-Type'}
			->{Content}
		);

		next PICK
			if !defined $Type;

		if ( $Type eq 'Primary' ) {

			$SelectedAssignment = $Assignment;

			last PICK;
		}
	}
	
    # -------------------------------------------------------- #
    # OWNER WEIGHTAGE
    # -------------------------------------------------------- #

    my $OwnerWeightage = 1;

    if ($SelectedAssignment) {

        my $Weightage = _NormalizeValue(
            $SelectedAssignment->{XMLData}
            ->{'ZTSMSupportAssignment-Weightage'}
            ->{Content}
        );

        if ( defined $Weightage ) {

            $OwnerWeightage = $Weightage;
        }
    }

    # -------------------------------------------------------- #
    # SNAPSHOT PARTICIPATION
    # -------------------------------------------------------- #

    my %UpdateMap = (

        'ZTicket-Owner'
            => $CustomerUserID,

        'ZTicket-OwnerWeightage'
            => $OwnerWeightage,
    );

    FIELD:
    for my $FieldName ( keys %UpdateMap ) {

        my $DynamicFieldConfig
            = $DynamicFieldObject->DynamicFieldGet(
                Name => $FieldName,
            );

        next FIELD if !$DynamicFieldConfig;

        $DynamicFieldBackendObject->ValueSet(

            DynamicFieldConfig => $DynamicFieldConfig,

            ObjectID => $TicketID,

            Value => $UpdateMap{$FieldName},

            UserID => $UserID,
        );
    }

    # -------------------------------------------------------- #
    # LOCK CHAPTERPLAY
    # -------------------------------------------------------- #

    $TicketObject->TicketLockSet(

        TicketID => $TicketID,

        Lock => 'lock',

        UserID => $UserID,
    );

    # -------------------------------------------------------- #
    # ORCHESTRATION NARRATIVE
    # -------------------------------------------------------- #

    my $Body
        = "** Note: This is a system-generated orchestration update message.\n\n"
        . "ChapterEngage activated.\n\n"
        . "Chapter:\n"
        . ( $Chapter || 'N/A' )
        . "\n\n"
        . "BlueBook:\n"
        . ( $BlueBook || 'N/A' )
        . "\n\n"
        . "BlueLevel:\n"
        . ( $BlueLevel || 'N/A' )
        . "\n\n"
        . "Support Profile:\n"
        . ( $SupportProfile || 'N/A' )
        . "\n\n"
        . "Participant:\n"
        . $CustomerUserID
        . "\n\n"
        . "Owner Weightage:\n"
        . $OwnerWeightage
        . "\n\n"
        . "Required Weightage:\n"
        . $RequiredWeightage;

    ZTSMArticleCreate(
        %Param,
        TicketID => $TicketID,
        Subject  => 'ZTSM ChapterEngage',
        Body     => $Body,
        HistoryComment =>
            'ZTSM: ChapterEngage '
            . 'Chapter='
            . ( $Chapter || 'N/A' ),
        UserID => $UserID,
    );

    # -------------------------------------------------------- #
    # LOG
    # -------------------------------------------------------- #

    $LogObject->Log(

        Priority => 'notice',

        Message =>
              'ZTSMCharacterEngage: '
            . 'Participant engaged ChapterPlay '
            . "TicketID=$TicketID "
            . "Participant=$CustomerUserID "
            . "Weightage=$OwnerWeightage "
            . "Required=$RequiredWeightage",
    );

    return 1;
}

1;
