# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMStateBookResume.pm
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookResume;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Log',
    'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader',
    'Kernel::System::State',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _NormalizeValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Content} if defined $Value->{Content} && $Value->{Content} ne '';
        return $Value->{Key}     if defined $Value->{Key}     && $Value->{Key} ne '';
        return $Value->{Value}   if defined $Value->{Value}   && $Value->{Value} ne '';
        return;
    }

    return $Value;
}

sub _FieldCandidates {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        my @Result;
        ITEM:
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
                )
            {
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

                my $DisplayValue = ( $PossibleValues && $PossibleValues->{$Candidate} )
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

sub _TicketFieldSet {
    my (%Param) = @_;

    return if !$Param{TicketID};
    return if !$Param{FieldName};

    my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => $Param{FieldName},
    );

    return if !$DynamicFieldConfig;

    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID} || 1,
    );
}

sub _RecordsParse {
    my (%Param) = @_;

    my $StateBook = $Param{StateBook};

    return if !$StateBook || ref $StateBook ne 'HASH';

    my $XMLData = ref $StateBook->{XMLData} eq 'HASH' ? $StateBook->{XMLData} : {};

    my $StateRecords
        = $XMLData->{'ZState-StateRecord'}
        || $StateBook->{'DynamicField_ZState-StateRecord'}
        || $XMLData->{'ZState-Record'}
        || $StateBook->{'DynamicField_ZState-Record'};

    return if !$StateRecords;

    if ( ref $StateRecords eq 'HASH' ) {
        $StateRecords = [$StateRecords];
    }

    return if ref $StateRecords ne 'ARRAY';

    my @ParsedRecords;

    RECORD:
    for my $Record ( @{$StateRecords} ) {
        next RECORD if ref $Record ne 'HASH';

        my $Sequence = _RecordValue( $Record, 'ZState-Seq' );
        my $State    = _StateNameResolve(
            Value     => _RecordValue( $Record, 'ZState-State' ),
            FieldName => 'ZState-State',
        );

        next RECORD if !$Sequence;
        next RECORD if !$State;

        push @ParsedRecords, {
            Sequence => $Sequence,
            State    => $State,
            BlueBook => _RecordValue( $Record, 'ZState-Book' ),
        };
    }

    return sort {
        $a->{Sequence} <=> $b->{Sequence}
    } @ParsedRecords;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if !$Param{Ticket};

    my $Ticket   = $Param{Ticket};
    my $TicketID = $Ticket->{TicketID};
    my $UserID   = $Param{UserID} || 1;

    return if !$TicketID;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $StateBookID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-StateBook'} )
        || $Param{StateBookID};

    if ( !$StateBookID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMStateBookResume: Missing ZTicket-StateBook TicketID=$TicketID",
        );
        return;
    }

    my $StateBook = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $StateBookID,
        DynamicFields => 1,
    );

    if ( !$StateBook || ref $StateBook ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMStateBookResume: Failed loading StateBook=$StateBookID TicketID=$TicketID",
        );
        return;
    }

    my @Records = _RecordsParse(
        StateBook => $StateBook,
    );

    if ( !@Records ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMStateBookResume: No usable StateBook records TicketID=$TicketID StateBook=$StateBookID",
        );
        return;
    }

    my $CurrentState    = $Ticket->{State};
    my $CurrentStage    = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Stage'} );
    my $CurrentBlueBook = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
    my @StateCandidates = grep { defined $_ && $_ ne '' } ( $CurrentState, $CurrentStage );

    my $CurrentIndex = -1;

    CANDIDATE:
    for my $Candidate (@StateCandidates) {
        for my $Index ( 0 .. $#Records ) {
            next if $Records[$Index]->{State} ne $Candidate;

            if (
                $CurrentBlueBook
                && $Records[$Index]->{BlueBook}
                && $Records[$Index]->{BlueBook} eq $CurrentBlueBook
                )
            {
                $CurrentIndex = $Index;
                last CANDIDATE;
            }

            $CurrentIndex = $Index
                if $CurrentIndex < 0;
        }
    }

    if ( $CurrentIndex < 0 ) {
        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  "ZTSMStateBookResume: Current StateBook stage not found "
                . "TicketID=$TicketID "
                . "State="
                . ( $CurrentState || '' )
                . " Stage="
                . ( $CurrentStage || '' ),
        );
        return;
    }

    _TicketFieldSet(
        TicketID  => $TicketID,
        FieldName => 'ZTicket-BlueLevel',
        Value     => '',
        UserID    => $UserID,
    );

    my $ResolvedState = $Records[$CurrentIndex]->{State};
    my $NextIndex     = $CurrentIndex + 1;

    if ( $NextIndex > $#Records ) {
        _TicketFieldSet(
            TicketID  => $TicketID,
            FieldName => 'ZTicket-BlueBook',
            Value     => '',
            UserID    => $UserID,
        );

        _TicketFieldSet(
            TicketID  => $TicketID,
            FieldName => 'ZTicket-Stage',
            Value     => $CurrentState,
            UserID    => $UserID,
        );

        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMStateBookResume: StateBook complete TicketID=$TicketID State=$ResolvedState",
        );

        return 1;
    }

    my $NextRecord = $Records[$NextIndex];
    my $NextState  = $NextRecord->{State};
    my $NextStateID = $Kernel::OM->Get('Kernel::System::State')->StateLookup(
        State => $NextState,
    );

    if ( !$NextStateID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMStateBookResume: State lookup failed TicketID=$TicketID State=$NextState",
        );
        return;
    }

    ZTSMArticleCreate(
        %Param,
        TicketID => $TicketID,
        Subject  => 'DO-NOT-REPLY: Ticket lifecycle resumed.',
        Body     =>
              "** Note: This is a system-generated orchestration update message.\n\n"
            . "Lifecycle State:\n"
            . "Resumed\n\n"
            . "From:\n"
            . $ResolvedState
            . "\n\n"
            . "To:\n"
            . $NextState,
        HistoryComment => "ZTSM: StateBook resumed $ResolvedState -> $NextState",
        UserID         => $UserID,
    );

    my $Success = $TicketObject->TicketStateSet(
        TicketID => $TicketID,
        StateID  => $NextStateID,
        UserID   => $UserID,
    );

    if ( !$Success ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMStateBookResume: Failed moving TicketID=$TicketID State=$NextState",
        );
        return;
    }

    _TicketFieldSet(
        TicketID  => $TicketID,
        FieldName => 'ZTicket-Stage',
        Value     => $NextState,
        UserID    => $UserID,
    );

    _TicketFieldSet(
        TicketID  => $TicketID,
        FieldName => 'ZTicket-BlueBook',
        Value     => '',
        UserID    => $UserID,
    );

    _TicketFieldSet(
        TicketID  => $TicketID,
        FieldName => 'ZTicket-BlueLevel',
        Value     => '',
        UserID    => $UserID,
    );

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSMStateBookResume: Advanced one state "
            . "TicketID=$TicketID "
            . "From=$ResolvedState "
            . "To=$NextState",
    );

    my %StateBookTicket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
        Silent        => 1,
    );

    if ( !%StateBookTicket ) {
        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  "ZTSMStateBookResume: Failed reloading ticket before StateBook handoff "
                . "TicketID=$TicketID "
                . "State=$NextState",
        );

        return 1;
    }

    my $StateBookReaderResult = $Kernel::OM->Get(
        'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader'
    )->Run(
        %Param,
        Ticket => \%StateBookTicket,
        UserID => $UserID,
    );

    if ( !$StateBookReaderResult ) {
        $LogObject->Log(
            Priority => 'error',
            Message  =>
                  "ZTSMStateBookResume: StateBook handoff returned false "
                . "TicketID=$TicketID "
                . "State=$NextState",
        );
    }

    return 1;
}

1;
