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
    'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader',
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
        $Value = $Value->[0];
    }

	if ( ref $Value eq 'HASH' ) {

		if ( defined $Value->{Key} ) {
			return $Value->{Key};
		}

		if ( defined $Value->{Value} ) {
			return $Value->{Value};
		}

		return ();
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
		$Value = [ $Value ];
	}

    if ( ref $Value eq 'ARRAY' ) {

        my @Result;

		ITEM:
		for my $Item ( @{$Value} ) {

			next ITEM if !defined $Item || $Item eq '';

			if ( ref $Item eq 'HASH' ) {

				push @Result,
					defined $Item->{Key}
					? $Item->{Key}
					: $Item->{Value};

				next ITEM;
			}

			push @Result, $Item;
		}

        return grep { defined $_ && $_ ne '' } @Result;
    }

    return ($Value)
        if !ref $Value
        && defined $Value
        && $Value ne '';

    return ();
}

sub _TransitionContextGet {
    my (%Param) = @_;

    my $Config = ref $Param{Config} eq 'HASH' ? $Param{Config} : {};

    return (
        ProcessEntityID => $Param{ProcessEntityID}
            || $Config->{ProcessEntityID}
            || $Config->{FallbackProcessEntityID},

        ActivityEntityID => $Param{ActivityEntityID}
            || $Config->{ActivityEntityID}
            || $Config->{FallbackActivityEntityID},

        TransitionEntityID => $Param{TransitionEntityID}
            || $Config->{TransitionEntityID}
            || $Config->{FallbackTransitionEntityID},

        TransitionActionEntityID => $Param{TransitionActionEntityID}
            || $Config->{TransitionActionEntityID}
            || $Config->{FallbackTransitionActionEntityID},
    );
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

	my $TicketArticleCreateObject = $Kernel::OM->Get(
		'Kernel::System::ProcessManagement::TransitionAction::TicketArticleCreate'
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

    my %TransitionContext = _TransitionContextGet(%Param);

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

        $TicketArticleCreateObject->Run(
			UserID => $Param{UserID},
			Ticket => $Ticket,
            %TransitionContext,
			Config => {
				CommunicationChannel => 'Internal',

				SenderType           => 'system',

				IsVisibleForCustomer => 1,

				Subject => 'DO-NOT-REPLY: Service Governance Resolution Failed',

				Body => $FailureBody,

				ContentType => 'text/plain; charset=utf-8',

				HistoryType => 'AddNote',

				HistoryComment => 'ZTSM: Governance resolution failed',
			},
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

        $TicketArticleCreateObject->Run(
			UserID => $Param{UserID},
			Ticket => $Ticket,
            %TransitionContext,
			Config => {
				CommunicationChannel => 'Internal',

				SenderType           => 'system',

				IsVisibleForCustomer => 1,

				Subject => 'DO-NOT-REPLY: Service Governance Resolution Failed',

				Body => $FailureBody,

				ContentType => 'text/plain; charset=utf-8',

				HistoryType => 'AddNote',

				HistoryComment =>
					'ZTSM: Governance resolution failed',
			},
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

        $TicketArticleCreateObject->Run(
			UserID => $Param{UserID},
			Ticket => $Ticket,
            %TransitionContext,
			Config => {
				CommunicationChannel => 'Internal',

				SenderType           => 'system',

				IsVisibleForCustomer => 1,

				Subject => 'DO-NOT-REPLY: Service Governance Resolved',

				Body => $SuccessBody,

				ContentType => 'text/plain; charset=utf-8',

				HistoryType => 'AddNote',

				HistoryComment =>
					  'ZTSM: Governance resolved '
					. '[Score='
					. $HighestScore
					. '] '
					. $WinnerName,
			},
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

    if ($StateBookID) {

        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  "ZTSM: Invoking StateBookReader "
                . "TicketID=$TicketID "
                . "StateBook=$StateBookID",
        );

        my %FreshTicket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $Param{UserID} || 1,
        );

        if ( %FreshTicket && $FreshTicket{TicketID} ) {

            my $StateBookResult = $Kernel::OM->Get(
                'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader'
            )->Run(
                %Param,
                Ticket      => \%FreshTicket,
                UserID      => $Param{UserID} || 1,
                StateBookID => $StateBookID,
            );

            $LogObject->Log(
                Priority => 'notice',
                Message  =>
                      "ZTSM: StateBookReader finished "
                    . "TicketID=$TicketID "
                    . "StateBook=$StateBookID "
                    . "Result="
                    . ( $StateBookResult || 0 ),
            );
        }
        else {

            $LogObject->Log(
                Priority => 'error',
                Message  =>
                      "ZTSM: Failed reloading ticket before StateBookReader "
                    . "TicketID=$TicketID "
                    . "StateBook=$StateBookID",
            );
        }
    }
    else {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  "ZTSM: Governance resolved without StateBook "
                . "TicketID=$TicketID "
                . "ServiceSupportMap=$WinnerID",
        );
    }

    return 1;
}

1;
