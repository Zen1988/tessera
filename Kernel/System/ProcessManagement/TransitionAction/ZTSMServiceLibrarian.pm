# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMServiceLibrarian.pm
# --
# Copyright (C) 2026 Zen
#
# Purpose:
# - Resolve governance routing context
# - Resolve Service Support Map
# - Resolve StateBook
# - Resolve ApprovalModel
# - Apply weighted specificity matching
# - Initialize governance orchestration context
# - Write governance orchestration narrative
#
# Philosophy:
# Librarians help Readers find the correct Books.
#
# Powered by Zen ☕
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMServiceLibrarian;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Ticket',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

# ------------------------------------------------------------ #
# NORMALIZE SINGLE VALUE
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
# NORMALIZE ARRAY
# ------------------------------------------------------------ #

sub _NormalizeArray {
    my ($Value) = @_;

    return () if !defined $Value;

	if (ref $Value eq 'HASH') {
		$Value = [$Value];
	}
	
    if ( ref $Value eq 'ARRAY' ) {
        return grep { defined $_ && $_ ne '' } @{$Value};
    }

    return ($Value)
        if defined $Value
        && $Value ne '';

    return ();
}


sub Run {
    my ( $Self, %Param ) = @_;

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

    my $TicketObject = $Kernel::OM->Get(
        'Kernel::System::Ticket'
    );

    # ------------------------------------------------------------ #
    # VALIDATE
    # ------------------------------------------------------------ #

    return if !$Param{Ticket};

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};

    return if !$TicketID;

    my $ServiceID = $Ticket->{ServiceID};

    return if !$ServiceID;

    # ------------------------------------------------------------ #
    # GOVERNANCE CONTEXT
    # ------------------------------------------------------------ #

    my @TicketApplications = _NormalizeArray(
        $Ticket->{'DynamicField_ZTicket-Application'}
    );

    my @TicketEnvironments = _NormalizeArray(
        $Ticket->{'DynamicField_ZTicket-Env'}
    );

    my @TicketLocations = _NormalizeArray(
        $Ticket->{'DynamicField_ZTicket-Location'}
    );

    # ------------------------------------------------------------ #
    # FIND SERVICE SUPPORT MAPS
    # ------------------------------------------------------------ #

    my @CandidateIDs = $ConfigItemObject->ConfigItemSearch(

        Result => 'ARRAY',

        Classes => ['Service Support Map'],

        'DynamicField_ZTSMServiceSupportMap-Service' => {
            Equals => $ServiceID,
        },

        UserID => 1,
    );

    # ------------------------------------------------------------ #
    # NO SERVICE SUPPORT MAP
    # ------------------------------------------------------------ #

    if ( !@CandidateIDs ) {

        my $FailureBody
            = "** Note: This is a system-generated orchestration update message.\n\n"
            . "Governance Resolution:\n"
            . "Failed\n\n"
            . "Reason:\n"
            . "Unable to find matching Service Support Map.\n\n"
            . "Service:\n"
            . $ServiceID
            . "\n\n"
            . "Action Required:\n"
            . "IPC governance review required.";

        $TicketObject->ArticleCreate(

            TicketID => $TicketID,

            ArticleType => 'note-internal',

            SenderType => 'system',

            Subject => 'ZTSM Governance Resolution Failed',

            Body => $FailureBody,

            ContentType => 'text/plain; charset=utf-8',

            HistoryType => 'AddNote',

            HistoryComment =>
                'ZTSM: Governance resolution failed',

            UserID => 1,
        );

        return;
    }

    # ------------------------------------------------------------ #
    # WEIGHTED GOVERNANCE MATCHING
    # ------------------------------------------------------------ #

	my $Winner;
	my $HighestScore = -1;

	MAP:
	for my $MapID (@CandidateIDs) {

		my $Map = $ConfigItemObject->ConfigItemGet(

			ConfigItemID => $MapID,

			DynamicFields => 1,
		);

		next MAP if !$Map;

		# -------------------------------------------------------- #
		# MAP CONTEXT
		# -------------------------------------------------------- #

		my @MapApplications = _NormalizeArray(
			$Map->{'DynamicField_ZTSMServiceSupportMap-Application'}
		);

		my @MapLocations = _NormalizeArray(
			$Map->{'DynamicField_ZTSMServiceSupportMap-Location'}
		);

		my @MapEnvironments = _NormalizeArray(
			$Map->{'DynamicField_ZTSMServiceSupportMap-Environment'}
		);

		# -------------------------------------------------------- #
		# SPECIFICITY SCORE
		# -------------------------------------------------------- #

		my $Score = 0;

		# -------------------------------------------------------- #
		# APPLICATION FILTER
		# -------------------------------------------------------- #

		if (@MapApplications) {

			my $Matched = 0;

			APPLICATION:
			for my $MapValue (@MapApplications) {

				next APPLICATION
					if !defined $MapValue;

				next APPLICATION
					if $MapValue eq '';

				for my $TicketValue (@TicketApplications) {

					next
						if !defined $TicketValue;

					next
						if $TicketValue eq '';

					if ( $MapValue eq $TicketValue ) {

						$Matched = 1;

						last APPLICATION;
					}
				}
			}

			#
			# Defined but no intersect
			#

			next MAP if !$Matched;

			#
			# Specificity score
			#

			$Score += 100;
		}

		# -------------------------------------------------------- #
		# LOCATION FILTER
		# -------------------------------------------------------- #

		if (@MapLocations) {

			my $Matched = 0;

			LOCATION:
			for my $MapValue (@MapLocations) {

				next LOCATION
					if !defined $MapValue;

				next LOCATION
					if $MapValue eq '';

				for my $TicketValue (@TicketLocations) {

					next
						if !defined $TicketValue;

					next
						if $TicketValue eq '';

					if ( $MapValue eq $TicketValue ) {

						$Matched = 1;

						last LOCATION;
					}
				}
			}

			#
			# Defined but no intersect
			#

			next MAP if !$Matched;

			#
			# Specificity score
			#

			$Score += 10;
		}

		# -------------------------------------------------------- #
		# ENVIRONMENT FILTER
		# -------------------------------------------------------- #

		if (@MapEnvironments) {

			my $Matched = 0;

			ENVIRONMENT:
			for my $MapValue (@MapEnvironments) {

				next ENVIRONMENT
					if !defined $MapValue;

				next ENVIRONMENT
					if $MapValue eq '';

				for my $TicketValue (@TicketEnvironments) {

					next
						if !defined $TicketValue;

					next
						if $TicketValue eq '';

					if ( $MapValue eq $TicketValue ) {

						$Matched = 1;

						last ENVIRONMENT;
					}
				}
			}

			#
			# Defined but no intersect
			#

			next MAP if !$Matched;

			#
			# Specificity score
			#

			$Score += 1;
		}

		# -------------------------------------------------------- #
		# MOST SPECIFIC MATCH WINS
		# -------------------------------------------------------- #

		if ( $Score > $HighestScore ) {

			$HighestScore = $Score;

			$Winner = $Map;
		}
	}

    # ------------------------------------------------------------ #
    # NO GOVERNANCE MATCH
    # ------------------------------------------------------------ #

    if ( !$Winner ) {

        my $FailureBody
            = "** Note: This is a system-generated orchestration update message.\n\n"
            . "Governance Resolution:\n"
            . "Failed\n\n"
            . "Reason:\n"
            . "No governance rule matched ticket context.\n\n"
            . "Service:\n"
            . ( $ServiceID || 'N/A' )
            . "\n\n"
            . "Application:\n"
            . ( join( ',', @TicketApplications ) || 'N/A' )
            . "\n\n"
            . "Environment:\n"
            . ( join( ',', @TicketEnvironments ) || 'N/A' )
            . "\n\n"
            . "Location:\n"
            . ( join( ',', @TicketLocations ) || 'N/A' )
            . "\n\n"
            . "Action Required:\n"
            . "IPC governance review required.";

        $TicketObject->ArticleCreate(

            TicketID => $TicketID,

            ArticleType => 'note-internal',

            SenderType => 'system',

            Subject => 'ZTSM Governance Resolution Failed',

            Body => $FailureBody,

            ContentType => 'text/plain; charset=utf-8',

            HistoryType => 'AddNote',

            HistoryComment =>
                'ZTSM: Governance resolution failed',

            UserID => 1,
        );

        return;
    }

    # ------------------------------------------------------------ #
    # RESOLVE GOVERNANCE SNAPSHOT
    # ------------------------------------------------------------ #

    my $WinnerID = $Winner->{ConfigItemID};

    my $WinnerName = $Winner->{Name} || 'Unknown';

    my $StateBookID = _NormalizeValue(
        $Winner->{'DynamicField_ZTSMServiceSupportMap-StateBook'}
    );

    my $ApprovalModel = _NormalizeValue(
        $Winner->{'DynamicField_ZTSMServiceSupportMap-ApprovalModel'}
    );

    # ------------------------------------------------------------ #
    # UPDATE GOVERNANCE SNAPSHOT
    # ------------------------------------------------------------ #

    my %UpdateMap = (

        'ZTicket-StateBook'
            => $StateBookID,

        'ZTicket-ApprovalModel'
            => $ApprovalModel,
    );

    FIELD:
    for my $FieldName ( keys %UpdateMap ) {

        next FIELD
            if !$UpdateMap{$FieldName};

        my $DynamicFieldConfig
            = $DynamicFieldObject->DynamicFieldGet(
                Name => $FieldName,
            );

        next FIELD if !$DynamicFieldConfig;

        my $Success
            = $DynamicFieldBackendObject->ValueSet(

                DynamicFieldConfig => $DynamicFieldConfig,

                ObjectID => $TicketID,

                Value => $UpdateMap{$FieldName},

                UserID => 1,
            );

        if ( !$Success ) {

            $LogObject->Log(
                Priority => 'error',
                Message =>
                      "ZTSM: Failed updating "
                    . "$FieldName "
                    . "TicketID=$TicketID",
            );
        }
    }

    # ------------------------------------------------------------ #
    # SUCCESS ARTICLE
    # ------------------------------------------------------------ #

    my $SuccessBody
        = "** Note: This is a system-generated orchestration update message.\n\n"
        . "Governance Resolution:\n"
        . "Successful\n\n"
        . "Resolved Service Support Map:\n"
        . $WinnerName
        . "\n\n"
        . "Resolved StateBook:\n"
        . ( $StateBookID || 'N/A' )
        . "\n\n"
        . "Resolved ApprovalModel:\n"
        . ( $ApprovalModel || 'N/A' )
        . "\n\n"
        . "Specificity Score:\n"
        . $HighestScore
        . "\n\n"
        . "Service:\n"
        . ( $ServiceID || 'N/A' )
        . "\n\n"
        . "Application:\n"
        . ( join( ',', @TicketApplications ) || 'N/A' )
        . "\n\n"
        . "Environment:\n"
        . ( join( ',', @TicketEnvironments ) || 'N/A' )
        . "\n\n"
        . "Location:\n"
        . ( join( ',', @TicketLocations ) || 'N/A' );

    $TicketObject->ArticleCreate(

        TicketID => $TicketID,

        ArticleType => 'note-internal',

        SenderType => 'system',

        Subject => 'ZTSM Governance Resolution',

        Body => $SuccessBody,

        ContentType => 'text/plain; charset=utf-8',

        HistoryType => 'AddNote',

        HistoryComment =>
              'ZTSM: Governance resolved '
            . '[Score='
            . $HighestScore
            . '] '
            . $WinnerName,

        UserID => 1,
    );

    # ------------------------------------------------------------ #
    # LOG
    # ------------------------------------------------------------ #

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSM: Governance resolved "
            . "TicketID=$TicketID "
            . "ServiceSupportMap=$WinnerID "
            . "Score=$HighestScore",
    );

    return 1;
}

1;
