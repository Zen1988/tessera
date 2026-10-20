package Kernel::System::TESSERA::RiskMasterTicket;

use strict;
use warnings;
use Kernel::System::TESSERA::ScriptBlocks qw(ObjectSource);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

our @ObjectDependencies = (
    'Kernel::System::MELTObject', 'Kernel::System::GovernanceObject',
    'Kernel::System::TESSERA::ScriptEngine', 'Kernel::System::TESSERA::GovernanceRoleResolver',
    'Kernel::System::Ticket',
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

    my $Source = ObjectSource(Object => $Framework, Field => 'MasterTicket');
    my $StateBookID = _SingleID( $Framework->{'DynamicField_ZRM-RiskMgtStateBook'} );
    return 1 if !$Source || !$StateBookID;
    my $Evaluated = $Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine')->FieldAssignmentsEvaluate(
        Source => $Source, ObjectType => 'Ticket', Class => 'ServiceRequest',
        UserID => $Param{UserID} || 1,
        Context => { RISK => $Risk, FRAMEWORK => $Framework },
    );
    die "Framework Master Ticket mapping failed: " . ( $Evaluated->{Error} || 'unknown error' ) . "\n"
        if !$Evaluated->{Success} || ref $Evaluated->{Value} ne 'HASH';
    my $TicketMap = $Evaluated->{Value};
    my %Allowed = map { $_ => 1 } qw(Type Service CustomerUser Title ZRM-OriginatedEvent ZRM-Framework ZTicket-Application ZTicket-StateBook ZTicket-OwnerGroup);
    for my $Field ( keys %{$TicketMap} ) {
        die "Unsupported Master Ticket assignment $Field.\n" if !$Allowed{$Field};
    }
    die "Framework Master Ticket must assign ServiceRequest, originating Risk, and Framework StateBook.\n"
        if ( $TicketMap->{Type} || '' ) ne 'ServiceRequest'
        || ( $TicketMap->{'ZRM-OriginatedEvent'} || '' ) ne $RiskID
        || ( $TicketMap->{'ZTicket-StateBook'} || '' ) ne $StateBookID
        || !$TicketMap->{Service} || !$TicketMap->{CustomerUser};

    my $ApplicationID;
    my $MappedFrameworkID;
    if (exists $TicketMap->{'ZRM-Framework'}) {
        $MappedFrameworkID = _SingleID($TicketMap->{'ZRM-Framework'});
        die "Master Ticket Framework must resolve exactly one Framework.\n" if !$MappedFrameworkID;
        my $MappedFramework = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $MappedFrameworkID, DynamicFields => 0, Silent => 1,
        );
        die "Master Ticket mapped Framework is unavailable.\n"
            if ref $MappedFramework ne 'HASH' || ($MappedFramework->{Class} || '') ne 'Framework';
    }
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
        # Cancellation ends this execution cycle, not management of an active Risk.
        # Reconciliation starts a fresh Framework-mapped cycle and retains this ledger.
        my $Restart = $LatestState =~ m{\Aclosed (?:unsuccessful|rejected|cancelled|canceled)\z} ? 1 : 0;
        if ( !$Restart ) {
            die "Existing master ServiceRequest has incompatible routing.\n"
                if !$Self->_FieldsEnsure(
                TicketID => $LatestTicketID, RiskID => $RiskID, StateBookID => $StateBookID,
                ApplicationID => $ApplicationID,
                FrameworkID => $MappedFrameworkID,
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

    # Resolve policy-authored ownership only for a fresh cycle. Existing ledgers
    # keep their original assignment even when the Framework or RoleMap changes.
    my $OwnerGroupID;
    if (exists $TicketMap->{'ZTicket-OwnerGroup'}) {
        $OwnerGroupID = $Self->_OwnerGroupResolve(
            Value => $TicketMap->{'ZTicket-OwnerGroup'},
            ApplicationID => $ApplicationID, CustomerUser => $CustomerUser,
            RiskID => $RiskID, FrameworkID => $MappedFrameworkID,
        );
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
            FrameworkID => $MappedFrameworkID,
            ServiceID => $ServiceID, OwnerGroupID => $OwnerGroupID,
        );
    my $RestartReason = $Param{RestartReason}
        || ( @Existing ? 'The previous Risk Management cycle ended without successful completion.' : '' );
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

# Validate the Framework's authored owner before partitioned Risk writes.
# Evaluate only ownership, without fabricating a not-yet-created Risk ID.
sub ValidateOwnership {
    my ($Self,%P)=@_;
    my $Risk=$P{Risk};
    my $FrameworkID=_SingleID($Risk->{'DynamicField_MELT-RMF'});
    die "Partitioned Risk requires a Framework.\n" if !$FrameworkID;
    my $Framework=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID=>$FrameworkID,DynamicFields=>1,Silent=>1);
    die "Partitioned Risk Framework cannot be read.\n" if ref $Framework ne 'HASH' || ($Framework->{Class}||'') ne 'Framework';
    my $Engine=$Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine');
    my $Program=$Engine->ScriptSourceLoad(Source=>ObjectSource(Object=>$Framework,Field=>'MasterTicket')||'');
    die "Framework must author partitioned Risk ticket ownership.\n" if ref $Program ne 'HASH'
        || ref $Program->{RETURN} ne 'HASH' || ref $Program->{RETURN}{'FIELD ASSIGNMENTS'} ne 'HASH'
        || !exists $Program->{RETURN}{'FIELD ASSIGNMENTS'}{'ZTicket-OwnerGroup'};
    my $OwnerProgram={%$Program,RETURN=>{%{$Program->{RETURN}},'FIELD ASSIGNMENTS'=>{
        'ZTicket-OwnerGroup'=>$Program->{RETURN}{'FIELD ASSIGNMENTS'}{'ZTicket-OwnerGroup'}}}};
    my $Result=$Engine->FieldAssignmentsEvaluate(Script=>$OwnerProgram,ObjectType=>'Ticket',Class=>'ServiceRequest',
        UserID=>$P{UserID}||1,Context=>{RISK=>$Risk,FRAMEWORK=>$Framework});
    die "Framework partition ownership cannot be evaluated.\n" if !$Result->{Success};
    my $Owner=$Self->_OwnerGroupResolve(Value=>$Result->{Value}{'ZTicket-OwnerGroup'},
        ApplicationID=>_SingleID($Risk->{'DynamicField_MELT-RelatedGO'}),FrameworkID=>$FrameworkID,UserID=>$P{UserID}||1);
    die "Framework owner differs from the matched partition SupportProfile.\n"
        if $Owner != $P{SupportProfileID};
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
        ( $Param{FrameworkID} ? ( [ 'ZRM-Framework', $Param{FrameworkID} ] ) : () ),
        ( $Param{ApplicationID} ? ( [ 'ZTicket-Application', $Param{ApplicationID} ] ) : () ),
        ( $Param{OwnerGroupID} ? ( [ 'ZTicket-OwnerGroup', $Param{OwnerGroupID} ] ) : () ),
        [ 'ZTicket-StateBook', $Param{StateBookID} ],
    ) {
        my ( $Name, $Value ) = @{$Entry};
        my $Current = _SingleID( $Ticket{"DynamicField_$Name"} );
        die "Master ServiceRequest has a conflicting $Name.\n"
            if $Current && $Current ne $Value;
        next if $Current;
        # An already-orchestrated ticket keeps its original governance snapshot.
        next if ($Name eq 'ZTicket-Application' || $Name eq 'ZRM-Framework')
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

# Framework YAML may name a SupportProfile directly or an executable GovernanceRole.
# Roles are resolved by the shared resolver; the ticket stores the final profile ID.
sub _OwnerGroupResolve {
    my ($Self, %Param) = @_;
    my $Value = _SingleID($Param{Value}) || _Scalar($Param{Value});
    die "Master Ticket OwnerGroup must identify one SupportProfile or GovernanceRole.\n"
        if !defined $Value || $Value eq '';
    my $GO = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $Object;
    if ($Value =~ m{\A\d+\z}) {
        $Object = $GO->GovernanceObjectGet(
            GovernanceObjectID => $Value, DynamicFields => 1, Silent => 1,
        );
    }
    else {
        my @IDs = $GO->GovernanceObjectSearch(
            Result => 'ARRAY', Classes => ['SupportProfile', 'GovernanceRole'],
            Name => $Value, Limit => 2, UserID => 1,
        );
        die "Master Ticket OwnerGroup '$Value' is missing or ambiguous.\n" if @IDs != 1;
        $Object = $GO->GovernanceObjectGet(
            GovernanceObjectID => $IDs[0], DynamicFields => 1, Silent => 1,
        );
        die "Master Ticket OwnerGroup name did not match exactly.\n"
            if ref $Object ne 'HASH' || ($Object->{Name} || '') ne $Value;
    }
    die "Master Ticket OwnerGroup object is unavailable.\n" if ref $Object ne 'HASH';
    my $ProfileID;
    if (($Object->{Class} || '') eq 'SupportProfile') {
        $ProfileID = _SingleID($Object->{GovernanceObjectID});
    }
    elsif (($Object->{Class} || '') eq 'GovernanceRole') {
        my $Resolved = $Kernel::OM->Get('Kernel::System::TESSERA::GovernanceRoleResolver')->Resolve(
            GovernanceRole => $Object, UserID => 1,
            Ticket => {
                Type => 'ServiceRequest', CustomerUser => $Param{CustomerUser},
                'DynamicField_ZTicket-Application' => $Param{ApplicationID},
                'DynamicField_ZRM-OriginatedEvent' => $Param{RiskID},
                'DynamicField_ZRM-Framework' => $Param{FrameworkID},
            },
        );
        die "Master Ticket OwnerGroup role resolution failed: " . ($Resolved->{Error} || 'unknown error') . "\n"
            if !$Resolved->{Success} || ($Resolved->{ValueType} || '') ne 'GovernanceObject.SupportProfile';
        $ProfileID = _SingleID($Resolved->{Value});
    }
    die "Master Ticket OwnerGroup must resolve exactly one SupportProfile.\n" if !$ProfileID;
    my $Profile = $GO->GovernanceObjectGet(
        GovernanceObjectID => $ProfileID, DynamicFields => 0, Silent => 1,
    );
    die "Master Ticket OwnerGroup resolved SupportProfile is unavailable.\n"
        if ref $Profile ne 'HASH' || ($Profile->{Class} || '') ne 'SupportProfile';
    return $ProfileID;
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
