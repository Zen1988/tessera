package Kernel::System::TESSERA::RiskMasterTicket;

use strict;
use warnings;

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

our @ObjectDependencies = (
    'Kernel::System::MELTObject', 'Kernel::System::GovernanceObject',
    'Kernel::System::TESSERA::ScriptEngine', 'Kernel::System::Ticket',
    'Kernel::System::Service', 'Kernel::System::CustomerUser',
    'Kernel::System::DynamicField', 'Kernel::System::DynamicField::Backend',
    'Kernel::System::PID', 'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;
    my $Data = $Param{Data};
    if ( ref $Data eq 'HASH' ) {
        my $RiskID = $Data->{MELTObjectID} || $Data->{ObjectID};
        return 1 if !$RiskID;
        $Self->Ensure( RiskID => $RiskID, UserID => $Param{UserID} || 1 );
        return 1;
    }
    my @RiskIDs = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectSearch(
        Result => 'ARRAY', Classes => ['Risk'],
        Limit => 10001, UserID => 1,
    );
    die "Risk master ticket reconciliation exceeds 10000 Risks.\n" if @RiskIDs > 10000;
    $Self->Ensure( RiskID => $_, UserID => 1 ) for @RiskIDs;
    return 1;
}

sub Ensure {
    my ( $Self, %Param ) = @_;
    my $RiskID = $Param{RiskID};
    return 1 if !$RiskID || $RiskID !~ m{\A\d+\z};

    my $PID = $Kernel::OM->Get('Kernel::System::PID');
    my $Lock = "TESSERA.RiskMasterTicket.$RiskID";
    return 1 if !$PID->PIDCreate( Name => $Lock );
    my $Success = eval { $Self->_EnsureLocked(%Param) };
    my $Error = $@;
    $PID->PIDDelete( Name => $Lock );
    if ($Error) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Risk master ticket creation failed for MELT Risk $RiskID: $Error",
        );
        return;
    }
    return $Success;
}

sub _EnsureLocked {
    my ( $Self, %Param ) = @_;
    my $RiskID = $Param{RiskID};
    my $Risk = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
        MELTObjectID => $RiskID, DynamicFields => 1, Silent => 1,
    );
    return 1 if ref $Risk ne 'HASH' || ( $Risk->{Class} || '' ) ne 'Risk';
    return 1 if ( _Scalar( $Risk->{'DynamicField_MELT-EventStatus'} ) || '' ) eq 'Closed';
    my $FrameworkID = _SingleID( $Risk->{'DynamicField_MELT-RMF'} );
    return 1 if !$FrameworkID;
    my $Framework = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $FrameworkID, DynamicFields => 1, Silent => 1,
    );
    die "Risk Framework $FrameworkID is unavailable.\n"
        if ref $Framework ne 'HASH' || ( $Framework->{Class} || '' ) ne 'Framework';

    my $Source = _Scalar( $Framework->{'DynamicField_ZRM-MasterTicket'} );
    my $StateBookID = _SingleID( $Framework->{'DynamicField_ZRM-RiskMgtStateBook'} );
    return 1 if !$Source || !$StateBookID;
    my $Evaluated = $Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine')->FieldAssignmentsEvaluate(
        Source => $Source, ObjectType => 'Ticket', Class => 'ServiceRequest',
        Context => { RISK => $Risk, FRAMEWORK => $Framework },
    );
    die "Framework Master Ticket mapping failed: " . ( $Evaluated->{Error} || 'unknown error' ) . "\n"
        if !$Evaluated->{Success} || ref $Evaluated->{Value} ne 'HASH';
    my $TicketMap = $Evaluated->{Value};
    my %Allowed = map { $_ => 1 } qw(Type Service CustomerUser Title ZRM-OriginatedEvent ZTicket-Application ZTicket-StateBook);
    for my $Field ( keys %{$TicketMap} ) {
        die "Unsupported Master Ticket assignment $Field.\n" if !$Allowed{$Field};
    }
    die "Framework Master Ticket must assign ServiceRequest, originating Risk, and Framework StateBook.\n"
        if ( $TicketMap->{Type} || '' ) ne 'ServiceRequest'
        || ( $TicketMap->{'ZRM-OriginatedEvent'} || '' ) ne $RiskID
        || ( $TicketMap->{'ZTicket-StateBook'} || '' ) ne $StateBookID
        || !$TicketMap->{Service} || !$TicketMap->{CustomerUser};

    my $ApplicationID;
    if ( exists $TicketMap->{'ZTicket-Application'} ) {
        $ApplicationID = _SingleID( $TicketMap->{'ZTicket-Application'} );
        die "Framework Master Ticket must resolve exactly one Application.\n" if !$ApplicationID;
        my $Application = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ApplicationID, DynamicFields => 0, Silent => 1,
        );
        die "Framework Master Ticket Application is unavailable.\n"
            if ref $Application ne 'HASH' || ( $Application->{Class} || '' ) ne 'Application';
    }

    my $StateBook = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $StateBookID, DynamicFields => 0, Silent => 1,
    );
    die "Framework Risk Management StateBook is unavailable.\n"
        if ref $StateBook ne 'HASH' || ( $StateBook->{Class} || '' ) ne 'StateBook';

    my %Services = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
        Valid => 1, UserID => 1,
    );
    my @ServiceIDs = grep { $Services{$_} eq $TicketMap->{Service} } keys %Services;
    die "Master Ticket service is missing or ambiguous.\n" if @ServiceIDs != 1;
    my $ServiceID = $ServiceIDs[0];
    my %Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
        ServiceID => $ServiceID, UserID => 1,
    );
    die "Master Ticket service has no destination queue.\n" if !$Service{DestQueueID};

    my $CustomerUser = $TicketMap->{CustomerUser};
    my %Customer = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
        User => $CustomerUser,
    );
    die "Master Ticket customer user is unavailable.\n"
        if !$Customer{UserLogin} || !$Customer{UserCustomerID};

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my @Existing = $TicketObject->TicketSearch(
        Result => 'ARRAY', Limit => 1000, Types => ['ServiceRequest'],
        'DynamicField_ZRM-OriginatedEvent' => { Equals => $RiskID },
        UserID => 1, Permission => 'ro',
    );
    @Existing = sort { $a <=> $b } @Existing;
    if (@Existing) {
        my $LatestTicketID = $Existing[-1];
        my %LatestTicket = $TicketObject->TicketGet(
            TicketID => $LatestTicketID, DynamicFields => 1, UserID => 1, Silent => 1,
        );
        my $LatestState = lc( $LatestTicket{State} || '' );
        my $Restart = $LatestState =~ m{\Aclosed (?:unsuccessful|rejected)\z} ? 1 : 0;
        if ( !$Restart ) {
            die "Existing master ServiceRequest has incompatible routing.\n"
                if !$Self->_FieldsEnsure(
                TicketID => $LatestTicketID, RiskID => $RiskID, StateBookID => $StateBookID,
                ApplicationID => $ApplicationID,
                ServiceID => $ServiceID,
            );
            my @Assessments = $TicketObject->TicketSearch(
                Result => 'ARRAY', Limit => 100, Types => ['Assessment'],
                'DynamicField_ZTicket-Parent' => { Equals => $LatestTicketID },
                UserID => 1, Permission => 'ro',
            );
            require Kernel::System::ZTSMBlueBookRuntime;
            Kernel::System::ZTSMBlueBookRuntime::RiskAssessmentAutomationEvidenceEnsure(
                TicketID => $_,
            ) for @Assessments;
            return 1;
        }
    }

    my $Title = $TicketMap->{Title} || $Risk->{Name} || 'Risk management';
    $Title .= " [MELT Risk $RiskID]";

    my $TicketID = $TicketObject->TicketCreate(
        TN => undef, Title => $Title, QueueID => $Service{DestQueueID},
        Type => 'ServiceRequest', ServiceID => $ServiceID,
        State => 'new', Lock => 'unlock', Priority => '3 normal',
        CustomerID => $Customer{UserCustomerID}, CustomerUser => $CustomerUser,
        OwnerID => 1, UserID => 1,
    );
    die "Master ServiceRequest could not be created.\n" if !$TicketID;
    die "Master ServiceRequest source fields could not be set.\n"
        if !$Self->_FieldsEnsure(
            TicketID => $TicketID, RiskID => $RiskID, StateBookID => $StateBookID,
            ApplicationID => $ApplicationID,
            ServiceID => $ServiceID,
        );
    my $RestartReason = $Param{RestartReason}
        || ( @Existing ? 'The previous Risk Management cycle closed unsuccessful.' : '' );
    my $PreviousTicketID = $Param{PreviousTicketID} || ( @Existing ? $Existing[-1] : '' );
    my $Subject = $RestartReason
        ? 'DO-NOT-REPLY: Risk management cycle restarted.'
        : 'DO-NOT-REPLY: Risk management initiated.';
    my $Body = 'Originating MELT Risk: ' . ( $Risk->{Number} || $RiskID )
        . "\nFramework: " . ( $Framework->{Name} || $FrameworkID );
    if ($RestartReason) {
        $Body .= "\n\nRestart reason: $RestartReason"
            . "\nPrevious ServiceRequest: $PreviousTicketID";
    }
    ZTSMArticleCreate(
        TicketID => $TicketID, UserID => 1,
        Subject => $Subject, Body => $Body,
        HistoryComment => $RestartReason
            ? 'TESSERA: Risk master ticket cycle restarted'
            : 'TESSERA: Risk master ticket created',
    );
    return 1;
}

sub _FieldsEnsure {
    my ( $Self, %Param ) = @_;
    my $TicketID = $Param{TicketID};
    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID => $TicketID, DynamicFields => 1, UserID => 1, Silent => 1,
    );
    return if !%Ticket || ( $Ticket{Type} || '' ) ne 'ServiceRequest'
        || ( $Ticket{ServiceID} || '' ) ne $Param{ServiceID};
    for my $Entry (
        [ 'ZRM-OriginatedEvent', $Param{RiskID} ],
        ( $Param{ApplicationID} ? ( [ 'ZTicket-Application', $Param{ApplicationID} ] ) : () ),
        [ 'ZTicket-StateBook', $Param{StateBookID} ],
    ) {
        my ( $Name, $Value ) = @{$Entry};
        my $Current = _SingleID( $Ticket{"DynamicField_$Name"} );
        die "Master ServiceRequest has a conflicting $Name.\n"
            if $Current && $Current ne $Value;
        next if $Current;
        # An already-orchestrated ticket keeps its original governance snapshot.
        next if $Name eq 'ZTicket-Application'
            && _SingleID( $Ticket{'DynamicField_ZTicket-StateBook'} );
        my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $Name,
        );
        die "Master ServiceRequest is missing field $Name.\n"
            if ref $Config ne 'HASH' || ( $Config->{ObjectType} || '' ) ne 'Ticket';
        my $Success = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
            DynamicFieldConfig => $Config, ObjectID => $TicketID,
            Value => $Value, UserID => 1,
        );
        die "Master ServiceRequest could not set $Name.\n" if !$Success;
    }
    return 1;
}

sub _SingleID {
    my ($Value) = @_;
    return if !defined $Value;
    if ( ref $Value eq 'ARRAY' ) {
        return if @{$Value} != 1;
        $Value = $Value->[0];
    }
    if ( ref $Value eq 'HASH' ) {
        $Value = $Value->{Key} // $Value->{Value} // $Value->{GovernanceObjectID};
    }
    return if !defined $Value || ref $Value || $Value !~ m{\A\d+\z};
    return $Value;
}

sub _Scalar {
    my ($Value) = @_;
    return if !defined $Value;
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    return if ref $Value;
    return $Value;
}

1;
