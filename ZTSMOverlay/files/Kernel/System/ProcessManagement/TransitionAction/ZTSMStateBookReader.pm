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
    'Kernel::System::GeneralCatalog',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article',
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

    if ( ref $Value eq 'HASH' ) {

        return $Value->{Content}
            if defined $Value->{Content}
            && $Value->{Content} ne '';

        return $Value->{Key}
            if defined $Value->{Key}
            && $Value->{Key} ne '';

        return $Value->{Value}
            if defined $Value->{Value}
            && $Value->{Value} ne '';
    }

    return $Value;
}

sub _FieldCandidates {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        my @Result;
        for my $Item ( @{$Value} ) {
            push @Result, _FieldCandidates($Item);
        }
        return @Result;
    }

    if ( ref $Value eq 'HASH' ) {
        my @Result;

        KEY:
        for my $Key (qw(Value DisplayValue Name Content Key)) {
            next KEY if !defined $Value->{$Key};
            next KEY if $Value->{$Key} eq '';
            push @Result, _FieldCandidates( $Value->{$Key} );
        }

        return @Result;
    }

    return ($Value);
}

sub _StateNameResolve {
    my (%Param) = @_;

    my $StateObject = $Kernel::OM->Get('Kernel::System::State');
    my @Candidates  = _FieldCandidates( $Param{Value} );
    my %Seen;

    if ( $Param{FieldName} ) {
        my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $Param{FieldName},
        );

        if ($DynamicFieldConfig) {
            my $PossibleValues;

            if (
                $DynamicFieldConfig->{FieldType}
                && $DynamicFieldConfig->{FieldType} eq 'GeneralCatalog'
            ) {
                $PossibleValues = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                    Class => $DynamicFieldConfig->{Config}->{Class},
                );
            }

            my @LookupCandidates = @Candidates;

            CANDIDATELOOKUP:
            for my $Candidate (@LookupCandidates) {
                next CANDIDATELOOKUP if !defined $Candidate;
                next CANDIDATELOOKUP if $Candidate eq '';
                next CANDIDATELOOKUP if $Seen{"lookup::$Candidate"}++;

                my $DisplayValue = $PossibleValues->{$Candidate}
                    || $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueLookup(
                    DynamicFieldConfig => $DynamicFieldConfig,
                    Key                => $Candidate,
                );

                next CANDIDATELOOKUP if !defined $DisplayValue;
                next CANDIDATELOOKUP if $DisplayValue eq '';
                next CANDIDATELOOKUP if $DisplayValue eq $Candidate;

                push @Candidates, _FieldCandidates($DisplayValue);
            }
        }
    }

    %Seen = ();

    CANDIDATE:
    for my $Candidate (@Candidates) {

        next CANDIDATE if !defined $Candidate;
        next CANDIDATE if $Candidate eq '';
        next CANDIDATE if $Seen{"state::$Candidate"}++;
        next CANDIDATE if $Candidate =~ m{\A\d+\z};

        my $StateID = $StateObject->StateLookup(
            State => $Candidate,
        );

        next CANDIDATE if !$StateID;

        my %State = $StateObject->StateGet(
            ID => $StateID,
        );

        return $State{Name}
            if %State
            && $State{Name};
    }

    return;
}

sub _RecordValue {
    my ( $Record, $Name ) = @_;

    return if ref $Record ne 'HASH';

    return _NormalizeValue( $Record->{$Name} )
        if exists $Record->{$Name};

    return _NormalizeValue( $Record->{"DynamicField_$Name"} )
        if exists $Record->{"DynamicField_$Name"};

    return;
}

sub _ArticleCreate {
    my (%Param) = @_;

    return if !$Param{TicketID};
    return if !$Param{Subject};
    return if !$Param{Body};

    my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
        ChannelName => 'Internal',
    );

    return $ArticleBackendObject->ArticleCreate(
        TicketID             => $Param{TicketID},
        SenderType           => 'system',
        IsVisibleForCustomer => 1,
        Subject              => $Param{Subject},
        Body                 => $Param{Body},
        ContentType          => 'text/plain; charset=utf-8',
        HistoryType          => 'AddNote',
        HistoryComment       => $Param{HistoryComment},
        UserID               => $Param{UserID} || 1,
    );
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

    if ( !$Param{Ticket} ) {
        return;
    }

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};

    if ( !$TicketID ) {
        return;
    }

    # ------------------------------------------------------------ #
    # LOAD CURRENT STATE
    # ------------------------------------------------------------ #

    my $CurrentState = $Ticket->{State};

    if ( !$CurrentState ) {
        return;
    }

    # ------------------------------------------------------------ #
    # LOAD STATEBOOK
    # ------------------------------------------------------------ #

    my $StateBookID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-StateBook'}
    ) || $Param{StateBookID};

    if ( !$StateBookID ) {
        return;
    }

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
        = $StateBook->{XMLData}->{'ZState-StateRecord'}
        || $StateBook->{'DynamicField_ZState-StateRecord'}
        || $StateBook->{XMLData}->{'ZState-Record'}
        || $StateBook->{'DynamicField_ZState-Record'};

    if ( !$StateRecords ) {
        return;
    }
	if ( ref $StateRecords eq 'HASH' ) {
		$StateRecords = [$StateRecords];
	}
    if ( ref $StateRecords ne 'ARRAY' ) {
        return;
    }

    # ------------------------------------------------------------ #
    # PARSE RECORDS
    # ------------------------------------------------------------ #

    my @ParsedRecords;

    RECORD:
    for my $Record ( @{$StateRecords} ) {

        next RECORD
            if ref $Record ne 'HASH';

        my $Sequence = _RecordValue( $Record, 'ZState-Seq' );

        my $State = _StateNameResolve(
            Value     => _RecordValue( $Record, 'ZState-State' ),
            FieldName => 'ZState-State',
        );

        my $BlueBook = _RecordValue( $Record, 'ZState-Book' );

        if ( !$Sequence ) {
            next RECORD;
        }
        if ( !$State ) {
            next RECORD;
        }

        push @ParsedRecords, {

            Sequence => $Sequence,

            State => $State,

            BlueBook => $BlueBook,
        };
    }

    if ( !@ParsedRecords ) {
        return;
    }

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
    # WALK EMPTY STATES UNTIL BLUEBOOK BOUNDARY
    # ------------------------------------------------------------ #

    my $ResolvedRecord = $CurrentRecord;
    my $ResolvedState  = $CurrentState;

    while ( !$ResolvedRecord->{BlueBook} ) {

        my $NextIndex = $CurrentIndex + 1;

        return 1
            if $NextIndex > $#ParsedRecords;

        my $NextRecord = $ParsedRecords[$NextIndex];

        return if !$NextRecord;
        return if ref $NextRecord ne 'HASH';

        my $NextState = $NextRecord->{State};

        return if !$NextState;

        my $NextStateID = $Kernel::OM->Get('Kernel::System::State')->StateLookup(
            State => $NextState,
        );

        if ( !$NextStateID ) {
            return;
        }

        _ArticleCreate(
            TicketID => $TicketID,
            UserID   => 1,
            Subject  => 'DO-NOT-REPLY: Ticket lifecycle advanced.',
            Body     =>
                  "** Note: This is a system-generated orchestration update message.\n\n"
                . "Lifecycle State:\n"
                . "Advanced\n\n"
                . "From:\n"
                . $ResolvedState
                . "\n\n"
                . "To:\n"
                . $NextState,
            HistoryComment =>
                  'ZTSM: Lifecycle advanced '
                . $ResolvedState
                . ' -> '
                . $NextState,
        );

        my $Success = $TicketObject->TicketStateSet(

            TicketID => $TicketID,

            StateID => $NextStateID,

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

        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  "TESSERA: Lifecycle advanced "
                . "TicketID=$TicketID "
                . "From=$ResolvedState "
                . "To=$NextState",
        );

        $CurrentIndex   = $NextIndex;
        $ResolvedRecord = $NextRecord;
        $ResolvedState  = $NextState;
    }

    # ------------------------------------------------------------ #
    # CURRENT STATE HAS BLUEBOOK
    # ------------------------------------------------------------ #

	if ( $ResolvedRecord->{BlueBook} ) {

		my $BlueBookID = $ResolvedRecord->{BlueBook};

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

				Value => $ResolvedState,

				UserID => 1,
			);
		}

		$LogObject->Log(

			Priority => 'notice',

			Message =>
				  "ZTSM: BlueBook resolved "
				. "TicketID=$TicketID "
				. "State=$ResolvedState "
				. "BlueBook=$BlueBookID",
		);

		#
		# BlueBookReader handles execution choreography
		#

		return 1;
	}

    return 1;
}

1;
