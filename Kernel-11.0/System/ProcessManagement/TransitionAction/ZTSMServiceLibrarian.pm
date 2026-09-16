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
    'Kernel::System::GovernanceObject',
    'Kernel::System::Service',
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

sub _TicketOnHold {
    my ($Ticket) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';
    return 1 if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    return 1 if lc( $Ticket->{State} || '' ) eq 'onhold';

    return;
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

sub _ServiceDisplayValue {
    my (%Param) = @_;

    my $ServiceID = $Param{ServiceID};

    return 'N/A' if !defined $ServiceID || $ServiceID eq '';

    my %Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
        ServiceID => $ServiceID,
        UserID    => 1,
    );

    return $ServiceID . ' - ' . $Service{Name}
        if %Service && $Service{Name};

    return $ServiceID;
}

sub _ConfigItemDisplayValue {
    my (%Param) = @_;

    my $Value = $Param{Value};

    return 'N/A' if !defined $Value || $Value eq '';
    return $Value if $Value !~ m{\A\d+\z};

    my $GovernanceObjectObject = $Param{GovernanceObjectObject}
        || $Kernel::OM->Get('Kernel::System::GovernanceObject');

    for my $GetParam (
            { GovernanceObjectID => $Value },
            { VersionID          => $Value },
    ) {
        my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
            %{$GetParam},
            DynamicFields => 0,
            Silent        => 1,
        );

        next if !$GovernanceObject;
        next if ref $GovernanceObject ne 'HASH';
        next if !$GovernanceObject->{Name};

        return $Value . ' - ' . $GovernanceObject->{Name};
    }

    return $Value;
}

sub _ConfigItemDisplayList {
    my (%Param) = @_;

    my @Values = @{ $Param{Values} || [] };
    my @DisplayValues;

    VALUE:
    for my $Value (@Values) {
        next VALUE if !defined $Value || $Value eq '';

        push @DisplayValues, _ConfigItemDisplayValue(
            Value            => $Value,
            GovernanceObjectObject => $Param{GovernanceObjectObject},
        );
    }

    return join( ', ', @DisplayValues ) || 'N/A';
}

sub _GovernanceObjectGet {
    my (%Param) = @_;

    return if !$Param{GovernanceObjectID};

    return $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $Param{GovernanceObjectID},
        DynamicFields      => 1,
        Silent             => 1,
    );
}

sub _ObjectDynamicFieldValues {
    my (%Param) = @_;

    my $Object = $Param{Object};
    my $Field  = $Param{Field};

    return if !$Object || ref $Object ne 'HASH';
    return if !$Field;

    my @Values = _NormalizeArray( $Object->{ 'DynamicField_' . $Field } );
    return @Values if @Values;

    my $XMLData = $Object->{XMLData};
    return if !$XMLData || ref $XMLData ne 'HASH';
    return if !exists $XMLData->{$Field};

    my $XMLValue = $XMLData->{$Field};
    my @Items = ref $XMLValue eq 'ARRAY' ? @{$XMLValue} : ($XMLValue);
    my @XMLValues;

    ITEM:
    for my $Item (@Items) {
        next ITEM if !defined $Item;
        next ITEM if !ref $Item && $Item eq '';

        if ( ref $Item eq 'HASH' ) {
            push @XMLValues, _NormalizeArray(
                exists $Item->{Content} ? $Item->{Content} : $Item
            );
            next ITEM;
        }

        push @XMLValues, _NormalizeArray($Item);
    }

    return grep { defined $_ && $_ ne '' } @XMLValues;
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

    my $GovernanceObjectObject = $Kernel::OM->Get(
        'Kernel::System::GovernanceObject'
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

    if ( _TicketOnHold($Ticket) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMServiceLibrarian: Ticket is onhold, skip governance context resolution TicketID=$TicketID",
        );
        return 1;
    }

    if ( _NormalizeValue( $Ticket->{'DynamicField_ZTicket-StateBook'} ) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMServiceLibrarian: Ticket already has ZTicket-StateBook, skip governance context resolution TicketID=$TicketID",
        );
        return 1;
    }

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

    my %PlatformServiceSupportMap;
    my @TicketPlatforms;

    APPLICATION:
    for my $ApplicationID (@TicketApplications) {
        next APPLICATION if !$ApplicationID;

        my $Application = _GovernanceObjectGet(
            GovernanceObjectID => $ApplicationID,
        );
        next APPLICATION if !$Application;

        my @PlatformIDs = _ObjectDynamicFieldValues(
            Object => $Application,
            Field  => 'ZTSMAppSystem-Platform',
        );

        PLATFORM:
        for my $PlatformID (@PlatformIDs) {
            next PLATFORM if !$PlatformID;
            push @TicketPlatforms, $PlatformID;

            my $Platform = _GovernanceObjectGet(
                GovernanceObjectID => $PlatformID,
            );
            next PLATFORM if !$Platform;

            for my $PlatformMapID (
                _ObjectDynamicFieldValues(
                    Object => $Platform,
                    Field  => 'ZTSMPlatform-ServiceSupportMap',
                )
                )
            {
                next if !$PlatformMapID;
                $PlatformServiceSupportMap{$PlatformMapID} = 1;
            }
        }
    }

    # ------------------------------------------------------------ #
    # FIND SERVICE SUPPORT MAPS
    # ------------------------------------------------------------ #

    my @CandidateIDs = $GovernanceObjectObject->GovernanceObjectSearch(

        Result => 'ARRAY',

        Classes => ['ServiceSupportMap'],

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
    my $WinnerPlatformFailsafe;

	MAP:
	for my $MapID (@CandidateIDs) {

		my $Map = $GovernanceObjectObject->GovernanceObjectGet(

			GovernanceObjectID => $MapID,

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
        my $PlatformFailsafe = $PlatformServiceSupportMap{$MapID} ? 1 : 0;

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

			next MAP if !$Matched && !$PlatformFailsafe;

			#
			# Specificity score
			#

			$Score += 100 if $Matched;
		}

        if ($PlatformFailsafe) {
            $Score += 50;
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
            $WinnerPlatformFailsafe = $PlatformFailsafe;
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

    my $WinnerID = $Winner->{GovernanceObjectID};

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

    my $ServiceDisplay = _ServiceDisplayValue(
        ServiceID => $ServiceID,
    );

    my $StateBookDisplay = _ConfigItemDisplayValue(
        Value            => $StateBookID,
        GovernanceObjectObject => $GovernanceObjectObject,
    );

    my $ApprovalModelDisplay = _ConfigItemDisplayValue(
        Value            => $ApprovalModel,
        GovernanceObjectObject => $GovernanceObjectObject,
    );

    my $ApplicationDisplay = _ConfigItemDisplayList(
        Values           => \@TicketApplications,
        GovernanceObjectObject => $GovernanceObjectObject,
    );

    my $EnvironmentDisplay = _ConfigItemDisplayList(
        Values           => \@TicketEnvironments,
        GovernanceObjectObject => $GovernanceObjectObject,
    );

    my $LocationDisplay = _ConfigItemDisplayList(
        Values           => \@TicketLocations,
        GovernanceObjectObject => $GovernanceObjectObject,
    );

    my $PlatformDisplay = _ConfigItemDisplayList(
        Values           => \@TicketPlatforms,
        GovernanceObjectObject => $GovernanceObjectObject,
    );

    my $SuccessBody
        = "** Note: This is a system-generated orchestration update message.\n\n"
        . "Governance Resolution:\n"
        . "Successful\n\n"
        . "Resolved Service Support Map:\n"
        . $WinnerName
        . "\n\n"
        . "Resolved StateBook:\n"
        . $StateBookDisplay
        . "\n\n"
        . "Resolved ApprovalModel:\n"
        . $ApprovalModelDisplay
        . "\n\n"
        . "Specificity Score:\n"
        . $HighestScore
        . "\n\n"
        . "Platform Failsafe:\n"
        . ( $WinnerPlatformFailsafe ? 'Applied' : 'Not applied' )
        . "\n\n"
        . "Service:\n"
        . $ServiceDisplay
        . "\n\n"
        . "Application:\n"
        . $ApplicationDisplay
        . "\n\n"
        . "Platform:\n"
        . $PlatformDisplay
        . "\n\n"
        . "Environment:\n"
        . $EnvironmentDisplay
        . "\n\n"
        . "Location:\n"
        . $LocationDisplay;

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

    return 1;
}

1;
