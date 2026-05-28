# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookReader.pm
# --
# Copyright (C) 2026 Zen
#
# Purpose:
# - Read StateBook
# - Sort StateBook sequence
# - Find current lifecycle state
# - Advance lifecycle ONLY if BlueBook empty
#
# IMPORTANT:
# This module DOES NOT:
# - spawn child ticket
# - process BlueLevel
# - process synchronization
#
# Those belong to:
# - BlueBookStepper
# - ChildEngine
#
# Powered by Zen ☕
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader;

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

sub _NormalizeValue {
    my ($Value) = @_;

    return if !$Value;

    if ( ref $Value eq 'ARRAY' ) {
        return $Value->[0];
    }

    return $Value;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get(
        'Kernel::System::Log'
    );

    my $ConfigItemObject = $Kernel::OM->Get(
        'Kernel::System::ITSMConfigItem'
    );

    my $TicketObject = $Kernel::OM->Get(
        'Kernel::System::Ticket'
    );
	
	my $DynamicFieldObject = $Kernel::OM->Get(
		'Kernel::System::DynamicField'
	);

	my $DynamicFieldBackendObject = $Kernel::OM->Get(
		'Kernel::System::DynamicField::Backend'
	);

    # ------------------------------------------------------------ #
    # VALIDATE
    # ------------------------------------------------------------ #

    return if !$Param{Ticket};

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};

    return if !$TicketID;

    # ------------------------------------------------------------ #
    # LOAD CURRENT STATE
    # ------------------------------------------------------------ #

    my $CurrentState = $Ticket->{State};

    return if !$CurrentState;

    # ------------------------------------------------------------ #
    # LOAD STATEBOOK
    # ------------------------------------------------------------ #

    my $StateBookID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-StateBook'}
    );

    return if !$StateBookID;

    my $StateBook = $ConfigItemObject->ConfigItemGet(

        ConfigItemID  => $StateBookID,

        DynamicFields => 1,
    );

    if (
        !$StateBook
        ||
        ref $StateBook ne 'HASH'
    ) {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                "TESSERA: Failed loading StateBook=$StateBookID",
        );

        return;
    }

    # ------------------------------------------------------------ #
    # LOAD STATE RECORDS
    # ------------------------------------------------------------ #

    my $StateRecords
        = $StateBook->{XMLData}->{'ZState-Record'};

    return if !$StateRecords;
	if ( ref $StateRecords eq 'HASH' ) {
		$StateRecords = [$StateRecords];
	}
    return if ref $StateRecords ne 'ARRAY';

    # ------------------------------------------------------------ #
    # PARSE RECORDS
    # ------------------------------------------------------------ #

    my @ParsedRecords;

    RECORD:
    for my $Record ( @{$StateRecords} ) {

        next RECORD
            if ref $Record ne 'HASH';

        my $Sequence = _NormalizeValue(
            $Record->{'ZState-Seq'}->{Content}
        );

        my $State = _NormalizeValue(
            $Record->{'ZState-State'}->{Content}
        );

        my $BlueBook = _NormalizeValue(
            $Record->{'ZState-Book'}->{Content}
        );

        next RECORD if !$Sequence;
        next RECORD if !$State;

        push @ParsedRecords, {

            Sequence => $Sequence,

            State => $State,

            BlueBook => $BlueBook,
        };
    }

    return if !@ParsedRecords;

    # ------------------------------------------------------------ #
    # SORT BY SEQUENCE
    # ------------------------------------------------------------ #

    @ParsedRecords = sort {
        $a->{Sequence} <=> $b->{Sequence}
    } @ParsedRecords;

    # ------------------------------------------------------------ #
    # FIND CURRENT RECORD
    # ------------------------------------------------------------ #

    my $CurrentIndex = -1;

    for my $Index ( 0 .. $#ParsedRecords ) {

        if (
            $ParsedRecords[$Index]->{State}
            eq
            $CurrentState
        ) {

            $CurrentIndex = $Index;
            last;
        }
    }

    if ( $CurrentIndex < 0 ) {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  "TESSERA: Current state not found in StateBook "
                . "TicketID=$TicketID "
                . "State=$CurrentState",
        );

        return;
    }

    my $CurrentRecord = $ParsedRecords[$CurrentIndex];

    # ------------------------------------------------------------ #
    # CURRENT STATE HAS BLUEBOOK
    # ------------------------------------------------------------ #

    if ( $CurrentRecord->{BlueBook} ) {

		my $BlueBookID = $CurrentRecord->{BlueBook};

		#
		# Snapshot BlueBook runtime
		#

		my $DynamicFieldConfig
			= $DynamicFieldObject->DynamicFieldGet(
				Name => 'ZTicket-BlueBook',
			);

		if ($DynamicFieldConfig) {

			$DynamicFieldBackendObject->ValueSet(

				DynamicFieldConfig => $DynamicFieldConfig,

				ObjectID => $TicketID,

				Value => $BlueBookID,

				UserID => 1,
			);
		}

		#
		# Optional stage snapshot
		#

		my $StageFieldConfig
			= $DynamicFieldObject->DynamicFieldGet(
				Name => 'ZTicket-Stage',
			);

		if ($StageFieldConfig) {

			$DynamicFieldBackendObject->ValueSet(

				DynamicFieldConfig => $StageFieldConfig,

				ObjectID => $TicketID,

				Value => $CurrentState,

				UserID => 1,
			);
		}

		$LogObject->Log(

			Priority => 'notice',

			Message =>
				  "ZTSM: BlueBook resolved "
				. "TicketID=$TicketID "
				. "State=$CurrentState "
				. "BlueBook=$BlueBookID",
		);

		#
		# BlueBookReader handles execution choreography
		#

		return 1;
	}

    # ------------------------------------------------------------ #
    # FIND NEXT STATE
    # ------------------------------------------------------------ #

    my $NextIndex = $CurrentIndex + 1;

    return 1
        if $NextIndex > $#ParsedRecords;

    my $NextRecord = $ParsedRecords[$NextIndex];

    return if !$NextRecord;
    return if ref $NextRecord ne 'HASH';

    my $NextState = $NextRecord->{State};

    return if !$NextState;

    # ------------------------------------------------------------ #
    # MOVE LIFECYCLE STATE
    # ------------------------------------------------------------ #

    my $Success = $TicketObject->TicketStateSet(

        TicketID => $TicketID,

        State => $NextState,

        UserID => 1,
    );

    if ( !$Success ) {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  "TESSERA: Failed moving lifecycle "
                . "TicketID=$TicketID "
                . "State=$NextState",
        );

        return;
    }

    # ------------------------------------------------------------ #
    # LOG
    # ------------------------------------------------------------ #

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "TESSERA: Lifecycle advanced "
            . "TicketID=$TicketID "
            . "From=$CurrentState "
            . "To=$NextState",
    );

    return 1;
}

1;
