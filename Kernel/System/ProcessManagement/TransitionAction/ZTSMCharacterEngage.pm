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
    'Kernel::System::GovernanceObject',
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

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Content}
            if defined $Value->{Content}
            && $Value->{Content} ne '';

        return $Value->{Value}
            if defined $Value->{Value}
            && $Value->{Value} ne '';

        return $Value->{Key}
            if defined $Value->{Key}
            && $Value->{Key} ne '';
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

    my $GovernanceObjectObject = $Kernel::OM->Get(
        'Kernel::System::GovernanceObject'
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

    if ( _TicketOnHold($Ticket) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMCharacterEngage: Ticket is onhold, skip participant engagement TicketID=$TicketID",
        );
        return 1;
    }

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

    my $TicketRole = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Role'}
    );

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

    my @AssignmentList = $GovernanceObjectObject->GovernanceObjectSearch(

		Classes  => ['SupportAssignment'],

        'DynamicField_ZTSMSupportAssignment-SupportProfile' => {
            Equals => $SupportProfile,
        },
        'DynamicField_ZTSMSupportAssignment-UserAccount' => {
            Equals => $CustomerUserID,
		},

		Result => 'ARRAY',
	);

	my $SelectedAssignment;

	PICK:
	for my $AssignmentID (@AssignmentList) {

		my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(

			GovernanceObjectID => $AssignmentID,

			DynamicFields => 1,
		);

		next PICK if !$Assignment;

		#
		# First match fallback
		#

		if ( !$SelectedAssignment ) {

			$SelectedAssignment = $Assignment;
		}

        my $AssignmentRole = _NormalizeValue(
            $Assignment->{'DynamicField_ZTSMSupportAssignment-Role'}
        );

        if (
            defined $TicketRole
            && $TicketRole ne ''
            && defined $AssignmentRole
            && lc $AssignmentRole eq lc $TicketRole
            )
        {
            $SelectedAssignment = $Assignment;

            last PICK;
        }

        next PICK
            if defined $TicketRole
            && $TicketRole ne '';

        my $Type = _NormalizeValue(
			$Assignment->{'DynamicField_ZTSMSupportAssignment-Type'}
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
            $SelectedAssignment->{'DynamicField_ZTSMSupportAssignment-Weightage'}
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
