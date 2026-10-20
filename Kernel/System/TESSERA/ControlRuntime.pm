# --
# Kernel/System/TESSERA/ControlRuntime.pm
# --

package Kernel::System::TESSERA::ControlRuntime;

use strict;
use warnings;
use Kernel::System::TESSERA::ScriptBlocks qw(ObjectSource);
use Digest::SHA qw(sha256_hex);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::DateTime',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::System::TESSERA::PolicyEngine',
    'Kernel::System::TESSERA::RiskMasterTicket',
    'Kernel::System::Ticket',
    'Kernel::System::YAML',
    'Kernel::System::PID',
    'Kernel::System::ITSMConfigItem::Activity',
    'Kernel::System::GovernanceObject::Activity',
    'Kernel::System::Daemon::SchedulerDB',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub _EvidenceTime {
    my ( $Epoch ) = @_;
    my $Date = $Kernel::OM->Create('Kernel::System::DateTime', ObjectParams => { Epoch => $Epoch });
    my $Zone = $Date->can('UserDefaultTimeZoneGet') ? $Date->UserDefaultTimeZoneGet() : 'UTC';
    die "Cannot convert Control evidence time to $Zone.\n"
        if $Date->can('ToTimeZone') && !$Date->ToTimeZone( TimeZone => $Zone );
    return $Date->ToString() . " ($Zone)";
}

sub Run {
    my ( $Self, %Param ) = @_;
    my $Results = $Self->DispatchDueControls( %Param, UserID => $Param{UserID} || 1 );
    for my $Result (@{$Results}) {
        next if ( $Result->{Status} || '' ) ne 'UNKNOWN';
        $Kernel::OM->Get('Kernel::System::Log')->Log( Priority => 'error',
            Message => 'Control evaluation ' . ( $Result->{ConfigItemID} || '?' ) . ': ' . ( $Result->{Reason} || 'UNKNOWN' ) );
    }
    return 1;
}

sub DispatchDueControls {
    my ( $Self, %Param ) = @_;

    my $UserID = $Param{UserID} || 1;
    my $Now    = defined $Param{Now} ? $Param{Now} : time;
    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my @IDs = $ConfigItemObject->ConfigItemSearch(
        Result  => 'ARRAY',
        Classes => ['Control'],
        UserID  => $UserID,
    );

    my @Results;
    CONTROL:
    for my $ConfigItemID (@IDs) {
        my $Control = $ConfigItemObject->ConfigItemGet(
            ConfigItemID  => $ConfigItemID,
            DynamicFields => 1,
        );
        next CONTROL if ref $Control ne 'HASH' || !%{$Control};

        my $ObjectiveID = _Scalar( $Control->{'DynamicField_ZRM-ControlObjective'} );
        if (!$ObjectiveID) {
            push @Results, { ConfigItemID => $ConfigItemID, Status => 'UNKNOWN', Reason => 'ControlObjective is missing.' };
            next CONTROL;
        }
        my $Objective = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ObjectiveID,
            DynamicFields      => 1,
            Silent             => 1,
        );
        if ( ref $Objective ne 'HASH' || !%{$Objective} ) {
            push @Results, { ConfigItemID => $ConfigItemID, Status => 'UNKNOWN', Reason => 'ControlObjective cannot be resolved.' };
            next CONTROL;
        }

        if ( ( $Objective->{ZTSMStatus} || '' ) ne 'Active' ) {
            push @Results, { ConfigItemID => $ConfigItemID, Status => 'INACTIVE', Reason => 'ControlObjective is not Active.' };
            next CONTROL;
        }

        my $Cycle = _Scalar( $Objective->{'DynamicField_ZRM-ControlCycle'} );
        my $LastRun = _Scalar( $Control->{'DynamicField_ZRM-LastRun'} );
        my $Due = $Self->ControlDue( Cycle => $Cycle, LastRun => $LastRun, Now => $Now );
        if ( !$Due->{Due} ) {
            push @Results, { ConfigItemID => $ConfigItemID, Status => $Due->{Status}, Reason => $Due->{Reason} };
            next CONTROL;
        }

        my $ControlType = _Scalar( $Objective->{'DynamicField_ZRM-ControlType'} ) || '';
        if ( lc($ControlType) eq 'manual' ) {
            push @Results, {
                ConfigItemID => $ConfigItemID,
                Status       => 'AWAITING_EVIDENCE',
                Reason       => 'Manual control is due; no service or workflow ticket is created automatically.',
            };
            next CONTROL;
        }

        push @Results, $Self->_AutomaticEvaluate(
            Control      => $Control,
            Objective    => $Objective,
            ConfigItemID => $ConfigItemID,
            Now          => $Now,
            UserID       => $UserID,
        );
    }

    return \@Results;
}

sub ControlDue {
    my ( $Self, %Param ) = @_;

    my $Cycle = defined $Param{Cycle} ? $Param{Cycle} : '';
    $Cycle =~ s{\A\s+|\s+\z}{}g;
    return { Due => 0, Status => 'UNKNOWN', Reason => 'Control cycle is empty.' } if $Cycle eq '';

    my ( $Amount, $Unit, $Times );
    if ( $Cycle =~ m{\A(\d+)\s*(HOUR|DAY|WEEK|MONTH|YEAR)S?(?:\s+(\d+)\s+TIMES?)?\z}i ) {
        ( $Amount, $Unit, $Times ) = ( $1, uc($2), $3 || 1 );
    }
    elsif ( $Cycle =~ m{\A(HOURLY|DAILY|WEEKLY|MONTHLY|QUARTERLY|ANNUALLY|YEARLY)\z}i ) {
        my %Named = (
            HOURLY => [ 1, 'HOUR' ], DAILY => [ 1, 'DAY' ], WEEKLY => [ 1, 'WEEK' ], MONTHLY => [ 1, 'MONTH' ],
            QUARTERLY => [ 3, 'MONTH' ], ANNUALLY => [ 1, 'YEAR' ], YEARLY => [ 1, 'YEAR' ],
        );
        ( $Amount, $Unit, $Times ) = ( @{ $Named{ uc $Cycle } }, 1 );
    }
    else {
        return { Due => 0, Status => 'UNKNOWN', Reason => "Unsupported control cycle '$Cycle'." };
    }
    return { Due => 0, Status => 'UNKNOWN', Reason => 'Control cycle frequency must be greater than zero.' } if !$Times;

    my %Seconds = ( HOUR => 3600, DAY => 86400, WEEK => 604800, MONTH => 2629746, YEAR => 31556952 );
    my $Interval = int( $Amount * $Seconds{$Unit} / $Times );
    my $LastRunEpoch = _Epoch( $Param{LastRun} );
    return { Due => 1, Status => 'DUE', Reason => 'Control has never run.' } if !defined $LastRunEpoch;

    my $Now = defined $Param{Now} ? $Param{Now} : time;
    return $Now >= $LastRunEpoch + $Interval
        ? { Due => 1, Status => 'DUE', Reason => 'Control cycle has elapsed.' }
        : { Due => 0, Status => 'NOT_DUE', Reason => 'Control instance is still within its cycle.' };
}

sub RunControlNow {
    my ($Self,%P)=@_;
    my $ID=$P{ConfigItemID}; my $UserID=$P{UserID};
    return {Success=>0,Status=>'DENIED',Reason=>'An authenticated agent and Control ID are required.'}
        if !$ID || $ID !~ /\A[1-9][0-9]*\z/ || !$UserID || $UserID !~ /\A[1-9][0-9]*\z/;
    my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    return {Success=>0,Status=>'DENIED',Reason=>'Control write permission is required.'}
        if !$CI->Permission(Scope=>'Item',ItemID=>$ID,UserID=>$UserID,Type=>'rw');
    my $Control=$CI->ConfigItemGet(ConfigItemID=>$ID,DynamicFields=>1);
    return {Success=>0,Status=>'DENIED',Reason=>'The target must be a Control.'}
        if ref $Control ne 'HASH' || ($Control->{Class}||'') ne 'Control';
    my $ObjectiveID=_Scalar($Control->{'DynamicField_ZRM-ControlObjective'});
    my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    return {Success=>0,Status=>'DENIED',Reason=>'ControlObjective read permission is required.'}
        if !$ObjectiveID || !$GO->Permission(Scope=>'Item',ItemID=>$ObjectiveID,UserID=>$UserID,Type=>'ro');
    my $Objective=$GO->GovernanceObjectGet(GovernanceObjectID=>$ObjectiveID,DynamicFields=>1,Silent=>1);
    return {Success=>0,Status=>'INACTIVE',Reason=>'ControlObjective must be Active.'}
        if ref $Objective ne 'HASH' || ($Objective->{Class}||'') ne 'ControlObjective' || ($Objective->{ZTSMStatus}||'') ne 'Active';
    return {Success=>0,Status=>'AWAITING_EVIDENCE',Reason=>'Run now applies to automatic Controls; manual Controls require evidence.'}
        if lc(_Scalar($Objective->{'DynamicField_ZRM-ControlType'})||'') ne 'automatic';
    my $RiskClass=_Scalar($Objective->{'DynamicField_ZRM-RiskClass'});
    if ($RiskClass) {
        my ($Kind,$Class)=$RiskClass =~ /\A(MELTObject|GovernanceObject)\.([A-Za-z][A-Za-z0-9_-]*)\z/;
        return {Success=>0,Status=>'DENIED',Reason=>'Invalid Risk destination.'} if !$Kind;
        my $Prefix=$Kind eq 'MELTObject' ? 'ZTSM::MELT' : 'ZTSM::GovernanceObject';
        my %Classes=reverse %{$Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(Class=>"$Prefix\::Class")||{}};
        return {Success=>0,Status=>'DENIED',Reason=>'Risk destination write permission is required.'}
            if !$Classes{$Class} || !$Kernel::OM->Get("Kernel::System::$Kind")->Permission(Scope=>'Class',ClassID=>$Classes{$Class},UserID=>$UserID,Type=>'rw');
    }
    # Bypass only the due-time gate. Existing policy, identity and evidence rules apply.
    return $Self->_AutomaticEvaluate(Control=>$Control,Objective=>$Objective,ConfigItemID=>$ID,
        UserID=>$UserID,Now=>defined $P{Now} ? $P{Now} : time,RunSource=>'Agent Run now');
}

sub _RunObjectiveGet {
    my ($Self,%P)=@_;
    my ($ID,$UserID)=@P{qw(GovernanceObjectID UserID)};
    die "An authenticated agent and ControlObjective ID are required.\n"
        if !$ID || $ID !~ /\A[1-9][0-9]*\z/ || !$UserID || $UserID !~ /\A[1-9][0-9]*\z/;
    my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    die "ControlObjective write permission is required.\n"
        if !$GO->Permission(Scope=>'Item',ItemID=>$ID,UserID=>$UserID,Type=>'rw');
    my $Objective=$GO->GovernanceObjectGet(GovernanceObjectID=>$ID,DynamicFields=>1,Silent=>1);
    die "Run now requires an Active automatic ControlObjective.\n" if ref $Objective ne 'HASH'
        || ($Objective->{Class}||'') ne 'ControlObjective' || ($Objective->{ZTSMStatus}||'') ne 'Active'
        || lc(_Scalar($Objective->{'DynamicField_ZRM-ControlType'})||'') ne 'automatic';
    return $Objective;
}

sub QueueControlObjective {
    my ($Self,%P)=@_;
    $Self->_RunObjectiveGet(%P);
    my $PID=$Kernel::OM->Get('Kernel::System::PID');
    my $Name='TESSERA.ControlObjectiveRun.'.$P{GovernanceObjectID};
    my $QueueLock=$Name.'.Queue';
    return {Status=>'BUSY',Reason=>'This ControlObjective is already being queued.'} if !$PID->PIDCreate(Name=>$QueueLock);
    my $TaskID=eval {$Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB')->TaskAdd(
        Type=>'Cron',Name=>$Name,Attempts=>1,MaximumParallelInstances=>1,
        Data=>{Module=>'Kernel::System::TESSERA::ControlRuntime',Function=>'RunControlObjectiveNow',
            Params=>[GovernanceObjectID=>$P{GovernanceObjectID},UserID=>$P{UserID}]})};
    my $Error=$@;
    $PID->PIDDelete(Name=>$QueueLock);
    die $Error if $Error;
    return {Status=>'BUSY',Reason=>'This ControlObjective already has a pending run.'} if defined $TaskID && $TaskID==-1;
    die "Could not queue ControlObjective evaluation.\n" if !$TaskID;
    return {Status=>'QUEUED',TaskID=>$TaskID,Reason=>'Run queued. The daemon will evaluate all instances without waiting for their next cycle.'};
}

sub RunControlObjectiveNow {
    my ($Self,%P)=@_;
    my $Objective=$Self->_RunObjectiveGet(%P);
    my $PID=$Kernel::OM->Get('Kernel::System::PID');
    my $Lock='TESSERA.ControlObjectiveRun.'.$P{GovernanceObjectID};
    die "This ControlObjective is already running.\n" if !$PID->PIDCreate(Name=>$Lock);
    my $OK=eval {
        my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem');
        my @IDs=$CI->ConfigItemSearch(Result=>'ARRAY',Classes=>['Control'],UserID=>1,Limit=>10001,
            'DynamicField_ZRM-ControlObjective'=>{Equals=>$P{GovernanceObjectID}});
        die "ControlObjective instance list exceeds 10000.\n" if @IDs>10000;
        # Refuse the whole batch before execution when any instance is outside the actor's scope.
        for my $ID (@IDs) {
            die "Run now requires write access to every Control instance.\n"
                if !$CI->Permission(Scope=>'Item',ItemID=>$ID,UserID=>$P{UserID},Type=>'rw');
        }
        my (%Count,@Results);
        for my $ID (@IDs) {
            my $Result=$Self->RunControlNow(ConfigItemID=>$ID,UserID=>$P{UserID});
            $Count{$Result->{Status}||'UNKNOWN'}++;
            push @Results,{ConfigItemID=>$ID,Status=>$Result->{Status}||'UNKNOWN'};
        }
        die "Cannot record ControlObjective run summary.\n" if !$Kernel::OM->Get('Kernel::System::GovernanceObject::Activity')->ActivityAdd(
            GovernanceObjectID=>$P{GovernanceObjectID},EventType=>'ControlObjectiveRun',Source=>'Agent Run now',
            Subject=>'Ad-hoc ControlObjective run completed',Body=>'Evaluated instances: '.scalar(@IDs)."\n"
                .join("\n",map {$_ . ': ' . $Count{$_}} sort keys %Count),
            Payload=>{Counts=>\%Count,Results=>\@Results},UserID=>$P{UserID});
        1;
    };
    my $Error=$@;
    $PID->PIDDelete(Name=>$Lock);
    die $Error if !$OK;
    return 1;
}

# Registered continuation for a completed external web service request. The callback
# worker rechecks the original actor and records the remote outcome before queuing
# ordinary local evaluation on a successful external exit.
sub ContinueAfterExternal {
    my ($Self,%P)=@_;
    return if ($P{TargetType}||'') ne 'ControlObjective'
        || !$P{TargetID} || !$P{ActorID};
    my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    return if !$GO->Permission(Scope=>'Item',ItemID=>$P{TargetID},UserID=>$P{ActorID},Type=>'rw');
    my $Objective=$GO->GovernanceObjectGet(GovernanceObjectID=>$P{TargetID},DynamicFields=>1,Silent=>1);
    return if ref $Objective ne 'HASH' || ($Objective->{Class}||'') ne 'ControlObjective';
    my $Success=defined $P{ExitCode} && $P{ExitCode}==0;
    my $Exit=defined $P{ExitCode} ? $P{ExitCode} : 'No callback before timeout';
    my $Body="External execution: $P{ExecutionUID}\nExit code: $Exit\nResponse: "
        .substr($P{Response}//'',0,4000);
    return if !$Kernel::OM->Get('Kernel::System::GovernanceObject::Activity')->ActivityAdd(
        GovernanceObjectID=>$P{TargetID},EventType=>'ControlObjectiveRun',Source=>'External execution callback',
        Subject=>$Success?'External execution completed':'External execution failed',Body=>$Body,
        Payload=>{ExecutionUID=>$P{ExecutionUID},ExitCode=>$P{ExitCode}},UserID=>$P{ActorID});
    return 1 if !$Success;
    my $Queue=$Self->QueueControlObjective(GovernanceObjectID=>$P{TargetID},UserID=>$P{ActorID});
    return ($Queue->{Status}||'') eq 'QUEUED' ? 1 : 0;
}

sub EvaluateCompletedTicket {
    my ( $Self, %Param ) = @_;
    my $TicketID = $Param{TicketID} || return { Success => 0, Status => 'UNKNOWN', Reason => 'TicketID is required.' };
    my $UserID   = $Param{UserID} || 1;
    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID => $TicketID, DynamicFields => 1, UserID => $UserID, Silent => 1,
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => 'Ticket cannot be resolved.' } if !%Ticket;
    my @ControlIDs = $Param{ConfigItemID} ? ( $Param{ConfigItemID} ) : ();
    return { Success => 0, Status => 'UNKNOWN', Reason => 'ConfigItemID for the Control instance is required.' }
        if @ControlIDs != 1;

    my $Control = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID => $ControlIDs[0], DynamicFields => 1,
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => 'Control instance cannot be resolved.' }
        if ref $Control ne 'HASH' || !%{$Control} || ( $Control->{Class} || '' ) ne 'Control';
    my $ObjectiveID = _Scalar( $Control->{'DynamicField_ZRM-ControlObjective'} );
    my $Objective = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $ObjectiveID, DynamicFields => 1, Silent => 1,
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => 'Linked ControlObjective cannot be resolved.' }
        if ref $Objective ne 'HASH' || !%{$Objective};

    my $Source = ObjectSource(Object => $Objective, Field => 'PolicyEvaluation') || '';
    my $Result = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->ProgramEvaluate(
        Source => $Source, Context => { TICKET => \%Ticket, CONTROLOBJECTIVE => $Objective, CONTROL => $Control },
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => $Result->{Error} } if !$Result->{Success};

    $Self->_ConfigItemFieldSet( ConfigItemID => $ControlIDs[0], FieldName => 'ZRM-Result', Value => $Result->{Result}, UserID => $UserID );
    my $Risk = $Self->ProcessFailedControl(
        Result => $Result->{Result}, Control => $Control, Objective => $Objective,
        ConfigItemID => $ControlIDs[0], Ticket => \%Ticket, UserID => $UserID,
    );
    return { Success => $Risk->{Success}, Status => $Result->{Result}, ConfigItemID => $ControlIDs[0], %{$Risk} };
}

sub ProcessFailedControl {
    my ( $Self, %Param ) = @_;

    my $UserID       = $Param{UserID} || 1;
    my $ConfigItemID = $Param{ConfigItemID};
    my $Control      = $Param{Control};
    if ( ref $Control ne 'HASH' ) {
        return { Success => 0, RiskCreated => 0, Reason => 'ConfigItemID for the Control instance is required.' }
            if !$ConfigItemID;
        $Control = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
            ConfigItemID => $ConfigItemID,
            DynamicFields => 1,
        );
    }
    return { Success => 0, RiskCreated => 0, Reason => 'Control instance cannot be resolved.' }
        if ref $Control ne 'HASH' || !%{$Control} || ( $Control->{Class} || '' ) ne 'Control';
    $ConfigItemID ||= $Control->{ConfigItemID};

    my $Result = defined $Param{Result} ? $Param{Result} : _Scalar( $Control->{'DynamicField_ZRM-Result'} );
    return { Success => 1, RiskCreated => 0 } if lc( $Result || '' ) ne 'fail';

    my $Objective = $Param{Objective};
    my $ObjectiveID = _Scalar( $Control->{'DynamicField_ZRM-ControlObjective'} );
    return { Success => 0, RiskCreated => 0, Reason => 'A Control must reference its ControlObjective.' }
        if !$ObjectiveID;
    if ( ref $Objective ne 'HASH' || !$Objective->{GovernanceObjectID} || "$Objective->{GovernanceObjectID}" ne "$ObjectiveID" ) {
        $Objective = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ObjectiveID,
            DynamicFields      => 1,
            Silent             => 1,
        );
    }
    return { Success => 0, RiskCreated => 0, Reason => 'The parent ControlObjective cannot be resolved.' }
        if ref $Objective ne 'HASH' || !%{$Objective} || ( $Objective->{Class} || '' ) ne 'ControlObjective';

    # Per-target finding programs own Risk creation after a complete evaluation.
    # A result-change event has no finding context and must not create a second Risk.
    my $Program = eval { $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->ScriptSourceLoad(
        Source => ObjectSource(Object => $Objective, Field => 'PolicyEvaluation') || '' ) };
    return { Success => 1, RiskCreated => 0 }
        if ref $Program eq 'HASH' && exists $Program->{TARGET};

    return $Self->_RiskCreateOnFailure(
        Result       => $Result,
        Control      => $Control,
        Objective    => $Objective,
        ConfigItemID => $ConfigItemID,
        Ticket       => $Param{Ticket},
        UserID       => $UserID,
    );
}

sub _AutomaticEvaluate {
    my ( $Self, %Param ) = @_;
    my $PID=$Kernel::OM->Get('Kernel::System::PID');
    my $Lock='TESSERA.ControlRun.' . $Param{ConfigItemID};
    return {Success=>0,ConfigItemID=>$Param{ConfigItemID},Status=>'BUSY',Reason=>'This Control is already running.'}
        if !$PID->PIDCreate(Name=>$Lock);
    my $Result = eval { $Self->_AutomaticEvaluateRun(%Param) };
    my $Error = $@;
    $Result ||= { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN',
        Reason => $Error || 'Automatic evaluation did not complete.' };
    if ( ( $Result->{Status} || '' ) eq 'UNKNOWN' || $Error
        || ( exists $Result->{Success} && !$Result->{Success} ) ) {
        my $Reason = substr( $Error || $Result->{Reason} || 'Evaluation incomplete.', 0, 2000 );
        my $Recorded = eval {
            my $AttemptTime = $Kernel::OM->Create('Kernel::System::DateTime',
                ObjectParams => { Epoch => $Param{Now} })->ToString();
            $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Activity')->ActivityAdd(
                ConfigItemID => $Param{ConfigItemID}, EventType => 'PolicyEvaluation', Source => $Param{RunSource} || 'ControlRuntime',
                Subject => 'Automatic Control run: evaluation error',
                Body => 'Run attempted: ' . _EvidenceTime($Param{Now}) . "\nExecution outcome: Error\n"
                    . "Assessment outcome: Unknown\nReason: $Reason\n"
                    . 'No completed assessment is claimed. The control remains due for retry when its cycle timestamp was not saved.',
                Payload => { ExecutionOutcome => 'Error', AssessmentOutcome => 'UNKNOWN',
                    AttemptTime => $AttemptTime, Reason => $Reason }, UserID => $Param{UserID},
            );
        };
        $Result->{ErrorArticleRecorded} = $Recorded ? 1 : 0;
        $Result->{Success} = 0;
        $Result->{Status} = 'UNKNOWN';
        $Result->{Reason} = $Reason;
        $Kernel::OM->Get('Kernel::System::Log')->Log( Priority => 'error',
            Message => 'Cannot record Control evaluation error article for ' . $Param{ConfigItemID} ) if !$Recorded;
    }
    $PID->PIDDelete(Name=>$Lock);
    return $Result;
}

sub _AutomaticEvaluateRun {
    my ( $Self, %Param ) = @_;
    my $Source = ObjectSource(Object => $Param{Objective}, Field => 'PolicyEvaluation') || '';
    my $Script = eval { $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->ScriptSourceLoad( Source => $Source ) };
    if ( ref $Script eq 'HASH' && exists $Script->{TARGET} ) {
        my $Result = eval { $Self->_TargetEvaluate( %Param, Script => $Script ) };
        return $Result if !$@ && $Result;
        return { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN', Reason => $@ || 'Target evaluation failed.' };
    }
    my $Result = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->Evaluate(
        Source => $Source, Label => 'ZRM-PolicyEvaluation',
        Context => { CONTROL => $Param{Control}, CONTROLOBJECTIVE => $Param{Objective} },
    );
    return { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN', Reason => $Result->{Reason} }
        if $Result->{Status} eq 'UNKNOWN';
    my $ControlResult = $Result->{Status} eq 'SATISFIED' ? 'Pass' : 'Fail';
    $Self->_PassedControlRisksDeactivate(%Param) if $ControlResult eq 'Pass';
    die "Cannot save Control result.\n" if !$Self->_ConfigItemFieldSet( ConfigItemID => $Param{ConfigItemID}, FieldName => 'ZRM-Result', Value => $ControlResult, UserID => $Param{UserID} );
    my $Now = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => { Epoch => $Param{Now} },
    )->ToString();
    my $Risk = $Self->ProcessFailedControl(
        Result => $ControlResult, Control => $Param{Control}, Objective => $Param{Objective},
        ConfigItemID => $Param{ConfigItemID}, UserID => $Param{UserID},
    );
    return { ConfigItemID => $Param{ConfigItemID}, Status => $ControlResult, %{$Risk} }
        if exists $Risk->{Success} && !$Risk->{Success};
    die "Cannot record Control evaluation article.\n" if !$Kernel::OM->Get('Kernel::System::ITSMConfigItem::Activity')->ActivityAdd(
        ConfigItemID=>$Param{ConfigItemID},EventType=>'PolicyEvaluation',Source=>$Param{RunSource}||'ControlRuntime',
        Subject=>'Automatic Control run: completed',Body=>'Run completed: ' . _EvidenceTime($Param{Now}) . "\nExecution outcome: Completed\nAssessment outcome: $ControlResult",
        Payload=>{ExecutionOutcome=>'Completed',AssessmentOutcome=>$ControlResult},UserID=>$Param{UserID});
    die "Cannot save completed Control timestamp.\n" if !$Self->_ConfigItemFieldSet(
        ConfigItemID=>$Param{ConfigItemID},FieldName=>'ZRM-LastRun',Value=>$Now,UserID=>$Param{UserID});
    return { ConfigItemID => $Param{ConfigItemID}, Status => $ControlResult, %{$Risk} };
}

sub _TargetEvaluate {
    my ( $Self, %Param ) = @_;
    my %Types = (
        'ZRM-CIInstance' => ['ITSMConfigItem', 'ConfigItemID', 'ConfigItemGet'],
        'ZRM-GOInstance' => ['GovernanceObject', 'GovernanceObjectID', 'GovernanceObjectGet'],
        'ZRM-MOInstance' => ['MELTObject', 'MELTObjectID', 'MELTObjectGet'],
        'ZRM-TKInstance' => ['Ticket', 'TicketID', 'TicketGet'],
    );
    my @Fields = grep { _Scalar( $Param{Control}{"DynamicField_$_"} ) } keys %Types;
    die "Control must have exactly one target.\n" if @Fields != 1;
    my ( $Kind, $IDKey, $Get ) = @{ $Types{ $Fields[0] } };
    my $Object = $Kernel::OM->Get("Kernel::System::$Kind");
    my %Get = ( $IDKey => _Scalar( $Param{Control}{"DynamicField_$Fields[0]"} ), DynamicFields => 1, UserID => $Param{UserID} );
    my $This = $Kind eq 'Ticket' ? { $Object->$Get(%Get) } : $Object->$Get(%Get);
    die "Control target cannot be read.\n" if ref $This ne 'HASH' || !%{$This};
    my $Type = $Kind eq 'Ticket' ? $Kind : "$Kind.$This->{Class}";
    my $Result = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->PolicyEvaluate(
        Script => $Param{Script}, TargetType => $Type, Now => $Param{Now}, UserID => $Param{UserID},
        Context => { THIS => $This, CONTROL => $Param{Control}, CONTROLOBJECTIVE => $Param{Objective} },
    );
    die (( $Result->{Error} || 'Target evaluation incomplete.' ) . "\n") if !$Result->{Success};
    my @Risks;
    if ( $Result->{Status} eq 'Pass' && !exists $Result->{Batches} ) {
        $Self->_PassedControlRisksDeactivate(%Param);
    }
    if ( $Result->{Status} eq 'Fail' && _Truthy( _Scalar( $Param{Objective}{'DynamicField_ZRM-CreateRisk'} ) ) ) {
        my $Assignment = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->ScriptSourceLoad(
            Source => ObjectSource(Object => $Param{Objective}, Field => 'FieldAsssignment') || '' );
        if ( ref $Assignment eq 'HASH' && ref $Assignment->{RETURN} eq 'HASH'
            && ref $Assignment->{RETURN}->{'GROUP FINDINGS'} eq 'HASH' ) {
            my @Batches = exists $Result->{Batches} ? @{$Result->{Batches}}
                : ({Source => $This, Evaluation => $Result});
            for my $Batch (@Batches) {
                my $Prepared = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->GroupedFieldAssignmentsEvaluate(
                    Rule => $Assignment->{RETURN}->{'GROUP FINDINGS'}, Destination => $Assignment->{RETURN}{AS},
                    RiskClass => _Scalar($Param{Objective}{'DynamicField_ZRM-RiskClass'}),
                    Source => $Batch->{Source}, Control => $Param{Control}, Objective => $Param{Objective},
                    Evaluation => $Batch->{Evaluation}, ConfigItemID => $Param{ConfigItemID},
                    Now => $Param{Now}, UserID => $Param{UserID});
                for my $Plan (@{$Prepared->{Plans}}) {
                    next if !exists $Plan->{SupportProfileID};
                    my %Risk = (Class=>'Risk',Name=>$Plan->{Name},
                        map {('DynamicField_'.$_=>$Plan->{Values}{$_})} keys %{$Plan->{Values}});
                    die "Partitioned Risk owner validation failed.\n" if !$Kernel::OM->Get('Kernel::System::TESSERA::RiskMasterTicket')->ValidateOwnership(
                        Risk=>\%Risk,SupportProfileID=>$Plan->{SupportProfileID},UserID=>$Param{UserID});
                }
                $Batch->{PreparedRiskPlans}=$Prepared;
            }
            # Evaluate all selections before writes; each source partitions composite identities.
            for my $Batch (@Batches) {
                push @Risks, @{ $Self->_GroupedFindingRisksCreate(
                    %Param, Evaluation => $Batch->{Evaluation}, SourceObject => $Batch->{Source},
                    PreparedRiskPlans => $Batch->{PreparedRiskPlans},
                    Destination => $Assignment->{RETURN}{AS},
                    Rule => $Assignment->{RETURN}->{'GROUP FINDINGS'} ) };
            }
        }
        else {
            for my $Finding ( @{ $Result->{Findings} } ) {
                push @Risks, $Self->_FindingRiskCreate( %Param, Finding => $Finding, Evaluation => $Result );
            }
        }
    }
    my $Body = "Execution outcome: Completed\nResult: " . $Result->{Status} . "\nTarget: " . ( $This->{Name} || $This->{Title} || $This->{$IDKey} )
        . "\nField: " . ( $Result->{Field} || '' ) . "\nValue: " . ( $Result->{Value} // '' )
        . "\nCondition: " . ( $Result->{Condition} || '' ) . "\nReason: " . ( $Result->{Reason} || '' )
        . "\nAffected objects: " . scalar( @{ $Result->{Findings} } );
    die "Cannot record evaluation evidence.\n" if !$Kernel::OM->Get('Kernel::System::ITSMConfigItem::Activity')->ActivityAdd(
        ConfigItemID => $Param{ConfigItemID}, EventType => 'PolicyEvaluation', Source => $Param{RunSource} || 'ControlRuntime',
        Subject => 'Automatic Control evaluation: ' . $Result->{Status}, Body => $Body,
        Payload => { %{$Result}, RiskObjects => \@Risks }, UserID => $Param{UserID},
    );
    die "Cannot store Control result.\n" if !$Self->_ConfigItemFieldSet(
        ConfigItemID => $Param{ConfigItemID}, FieldName => 'ZRM-Result', Value => $Result->{Status}, UserID => $Param{UserID} );
    my $Now = $Kernel::OM->Create('Kernel::System::DateTime', ObjectParams => { Epoch => $Param{Now} })->ToString();
    die "Cannot store Control LastRun.\n" if !$Self->_ConfigItemFieldSet(
        ConfigItemID => $Param{ConfigItemID}, FieldName => 'ZRM-LastRun', Value => $Now, UserID => $Param{UserID} );
    return { Success => 1, ConfigItemID => $Param{ConfigItemID}, Status => $Result->{Status}, Findings => scalar @{ $Result->{Findings} }, RiskObjects => \@Risks };
}

sub _PassedControlRisksDeactivate {
    my ( $Self, %Param ) = @_;
    return if _Scalar( $Param{Objective}{'DynamicField_ZRM-RiskClass'} ) ne 'MELTObject.Risk';
    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %Statuses = reverse %{ $Catalog->ItemList( Class => 'ZTSM::MELT::Status', Valid => 1 ) || {} };
    die "Active/Resolved Risk statuses are unavailable.\n" if !$Statuses{Active} || !$Statuses{Resolved};
    my $Object = $Kernel::OM->Get('Kernel::System::MELTObject');
    my @IDs = $Object->MELTObjectSearch( Result => 'ARRAY', Classes => ['Risk'],
        ZTSMStatusIDs => [$Statuses{Active}], Limit => 10001,
        'DynamicField_MELT-Control' => { Equals => $Param{ConfigItemID} }, UserID => $Param{UserID} );
    die "Risk resolution search is incomplete.\n" if @IDs >= 10001;
    for my $ID (@IDs) {
        my $Risk = $Object->MELTObjectGet( MELTObjectID => $ID, DynamicFields => 1, UserID => $Param{UserID} );
        die "Risk cannot be read for resolution.\n" if ref $Risk ne 'HASH';
        next if _Scalar( $Risk->{'DynamicField_MELT-Control'} ) ne $Param{ConfigItemID};
        next if _Scalar( $Risk->{'DynamicField_MELT-EventStatus'} ) eq 'Closed';
        die "Cannot mark Risk Resolved.\n" if !$Object->MELTObjectUpdate(
            MELTObjectID => $ID, ZTSMStatusID => $Statuses{Resolved}, UserID => $Param{UserID} );
        die "Cannot record Risk resolution evidence.\n" if !$Kernel::OM->Get('Kernel::System::MELTObject::Activity')->ActivityAdd(
            MELTObjectID => $ID, EventType => 'ControlResolution', Source => 'ControlRuntime',
            Subject => 'Control passed; Risk marked Resolved',
            Body => 'Control ' . $Param{ConfigItemID} . ' passed. Risk retained as history.',
            Payload => { ControlID => $Param{ConfigItemID}, Result => 'Pass' }, UserID => $Param{UserID} );
    }
    return 1;
}

sub _GroupedFindingRisksCreate {
    my ( $Self, %Param ) = @_;
    my $PlanData = $Param{PreparedRiskPlans} || $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->GroupedFieldAssignmentsEvaluate(
        Rule => $Param{Rule}, Destination => $Param{Destination},
        RiskClass => _Scalar( $Param{Objective}{'DynamicField_ZRM-RiskClass'} ),
        Source => $Param{SourceObject}, Control => $Param{Control},
        Objective => $Param{Objective}, Evaluation => $Param{Evaluation},
        ConfigItemID => $Param{ConfigItemID}, Now => $Param{Now}, UserID => $Param{UserID},
    );
    my ( $Kind, $Class ) = @{ $PlanData->{Class} };
    my $IdentityField = $PlanData->{IdentityField};
    my $ReuseBy = $PlanData->{ReuseBy} || 'NAME';
    my $Merge = $PlanData->{Merge};
    my $SeverityRule = $PlanData->{SeverityRule};
    my $Priority = $PlanData->{Priority};
    my $PriorityByName = $PlanData->{PriorityByName};
    my $Lifecycle = $PlanData->{Lifecycle};
    my @Planned = @{ $PlanData->{Plans} };
    my $GO = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $Prefix = $Kind eq 'MELTObject' ? 'ZTSM::MELT' : 'ZTSM::GovernanceObject';
    my %Classes = reverse %{ $Catalog->ItemList( Class => "$Prefix\::Class", Valid => 1 ) || {} };
    my %Statuses = reverse %{ $Catalog->ItemList( Class => "$Prefix\::Status", Valid => 1 ) || {} };
    my $CreateStatusID = $Statuses{ $Lifecycle->{'CREATE STATUS'} };
    my $ReuseStatusID = $Statuses{ $Lifecycle->{'REUSE STATUS'} };
    die "Risk class or authored lifecycle status is unavailable.\n"
        if !$Classes{$Class} || !$CreateStatusID || !$ReuseStatusID;
    my $Object = $Kernel::OM->Get("Kernel::System::$Kind");
    my $Search = $Kind . 'Search';
    my $Get = $Kind . 'Get';
    my $Add = $Kind . 'Add';
    my $Update = $Kind . 'Update';
    my $IDKey = $Kind . 'ID';
    my @Results;
    for my $Plan (@Planned) {
        my $ReuseKey = $ReuseBy eq 'IDENTITY' ? $Plan->{Identity} : $Plan->{Name};
        my $Lock = 'TESSERA.Finding.' . sha256_hex("$Kind\0$Class\0$ReuseStatusID\0$ReuseKey");
        my $PID = $Kernel::OM->Get('Kernel::System::PID');
        die "Risk identity is busy; retry on the next dispatch.\n" if !$PID->PIDCreate( Name => $Lock );
        my $ID = eval {
            my @Candidates = $Object->$Search( Result => 'ARRAY', Classes => [$Class],
                ZTSMStatusIDs => [$ReuseStatusID], Limit => 10001,
                UserID => $Param{UserID} );
            die "Risk identity search is incomplete.\n" if @Candidates >= 10001;
            my @Existing;
            for my $CandidateID (@Candidates) {
                my $Candidate = $Object->$Get( $IDKey => $CandidateID,
                    DynamicFields => 1, UserID => $Param{UserID} );
                die "Existing Risk cannot be read.\n"
                    if ref $Candidate ne 'HASH' || $Candidate->{Class} ne $Class;
                next if $ReuseBy eq 'IDENTITY'
                    ? (_Scalar($Candidate->{"DynamicField_$IdentityField"}) || '') ne $Plan->{Identity}
                    : ($Candidate->{Name} || '') ne $Plan->{Name};
                my $EventField = $Lifecycle->{'EVENT FIELD'};
                next if $EventField
                    && ( $Candidate->{"DynamicField_$EventField"} || '' ) eq $Lifecycle->{'CLOSED EVENT VALUE'};
                push @Existing, $CandidateID;
            }
            die "Risk identity is ambiguous.\n" if @Existing > 1;
            my $ObjectID = $Existing[0];
            if ($ObjectID) {
                my $Current = $Object->$Get( $IDKey => $ObjectID, DynamicFields => 1, UserID => $Param{UserID} );
                die "Existing Risk cannot be read.\n" if ref $Current ne 'HASH' || $Current->{Class} ne $Class;
                my %Changes;
                for my $Field ( keys %{ $Plan->{Values} } ) {
                    my $New = $Plan->{Values}{$Field};
                    my $Old = $Current->{"DynamicField_$Field"};
                    my $Mode = $Merge->{$Field} || 'REQUIRE_EQUAL';
                    if ( $Mode eq 'UNION' ) {
                        die "UNION requires an array.\n" if ref $New ne 'ARRAY';
                        my @Old = ref $Old eq 'ARRAY' ? @{$Old} : grep { defined $_ && $_ ne '' } ($Old);
                        my %Union = map { $_ => 1 } @Old, @{$New};
                        my @Combined = sort { $a <=> $b } keys %Union;
                        $Changes{"DynamicField_$Field"} = \@Combined
                            if join(',', @Combined) ne join(',', sort { $a <=> $b } @Old);
                    }
                    elsif ( $Mode eq 'MAX_PRIORITY' ) {
                        die "MAX_PRIORITY must target the authored severity field.\n"
                            if $Field ne $SeverityRule->{FIELD};
                        my $OldName = '';
                        if ($Old) {
                            my $ExistingSeverity = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')
                                ->GroupedReferenceResolve( ID => $Old, AS => $SeverityRule->{AS}, UserID => $Param{UserID} );
                            $OldName = $ExistingSeverity->{Name};
                            die "Existing severity has no authored priority.\n" if !exists $PriorityByName->{$OldName};
                        }
                        $Changes{"DynamicField_$Field"} = $New
                            if !$Old || $Priority > $PriorityByName->{$OldName};
                    }
                    elsif ( $Mode eq 'KEEP_FIRST' ) { next }
                    elsif ( $Mode eq 'REQUIRE_EQUAL' ) {
                        $Old = $Old->[0] if ref $Old eq 'ARRAY' && @{$Old} == 1;
                        $New = $New->[0] if ref $New eq 'ARRAY' && @{$New} == 1;
                        die "Existing Risk field $Field conflicts with assignment.\n"
                            if !defined $Old || ref $Old || ref $New || "$Old" ne "$New";
                    }
                    else { die "Unsupported merge mode $Mode.\n" }
                }
                $Changes{Name} = $Plan->{Name} if ( $Current->{Name} || '' ) ne $Plan->{Name};
                die "Risk reconciliation failed.\n" if %Changes && !$Object->$Update(
                    $IDKey => $ObjectID, UserID => $Param{UserID}, %Changes );
            }
            else {
                my %Fields = map { ( "DynamicField_$_" => $Plan->{Values}{$_} ) } keys %{ $Plan->{Values} };
                if ( $Lifecycle->{'EVENT FIELD'} ) {
                    my $Key = 'DynamicField_' . $Lifecycle->{'EVENT FIELD'};
                    die "Lifecycle event field conflicts with assignment.\n" if exists $Fields{$Key};
                    $Fields{$Key} = $Lifecycle->{'CREATE EVENT VALUE'};
                }
                $ObjectID = $Object->$Add( ClassID => $Classes{$Class}, ZTSMStatusID => $CreateStatusID,
                    Name => $Plan->{Name}, UserID => $Param{UserID}, %Fields );
                die "Risk creation failed.\n" if !$ObjectID;
            }
            for my $Finding ( @{ $Plan->{Findings} } ) {
                die "Cannot append Risk evidence.\n"
                    if !$Kernel::OM->Get("Kernel::System::$Kind\::Activity")->ActivityAdd(
                        $IDKey => $ObjectID, EventType => 'ControlFinding', Source => 'ControlRuntime',
                        Subject => 'Control finding: ' . ( $Param{Control}{Name} || $Param{ConfigItemID} ),
                        Body => 'Policy finding for group ' . $Plan->{GroupID}
                            . ' and item ' . $Plan->{ItemID}
                            . ($Plan->{SupportProfileName} ? "\nSupportProfile: $Plan->{SupportProfileName}" : '')
                            . ($Plan->{AssignmentFallback} ? "\nAssignment: Application default (no linked entitlement)." : ''),
                        Payload => { ControlID => $Param{ConfigItemID}, ObjectiveID => $Param{Objective}{GovernanceObjectID},
                            GroupID => $Plan->{GroupID}, ItemID => $Plan->{ItemID}, Finding => $Finding,
                            (exists $Plan->{SupportProfileID} ? (SupportProfileID=>$Plan->{SupportProfileID},
                                EntitlementIDs=>$Plan->{EntitlementIDs},AssignmentFallback=>$Plan->{AssignmentFallback}) : ()),
                            EvaluationDate => $Param{Evaluation}{EvaluationDate} }, UserID => $Param{UserID} );
            }
            $ObjectID;
        };
        my $Error = $@;
        $PID->PIDDelete( Name => $Lock );
        die $Error if $Error;
        if ( $Kind eq 'MELTObject' && $Class eq 'Risk' ) {
            my $Ensured = $Kernel::OM->Get('Kernel::System::TESSERA::RiskMasterTicket')->Ensure(
                RiskID => $ID, UserID => $Param{UserID},
            );
            die "Partitioned Risk master ticket could not be ensured.\n"
                if exists $Plan->{SupportProfileID} && !$Ensured;
        }
        push @Results, { ObjectType => $Kind, Class => $Class, ObjectID => $ID };
    }
    return \@Results;
}


sub _FindingRiskCreate {
    my ( $Self, %Param ) = @_;
    my $Target = _Scalar( $Param{Objective}{'DynamicField_ZRM-RiskClass'} ) || '';
    $Target =~ s/^\@//;
    die "Invalid RiskClass.\n" if $Target !~ /\A(MELTObject|GovernanceObject)\.([A-Za-z][A-Za-z0-9_-]*)\z/;
    my ( $Kind, $Class ) = ($1, $2);
    my $Source = ObjectSource(Object => $Param{Objective}, Field => 'FieldAsssignment') || '';
    my $Script = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->ScriptSourceLoad( Source => $Source );
    my $IdentityField = ref $Script eq 'HASH' && ref $Script->{RETURN} eq 'HASH' ? $Script->{RETURN}->{IDENTITY} : '';
    die "Finding assignments require RETURN IDENTITY with an assigned field.\n" if !$IdentityField;
    my $Assignments = $Self->_RiskAssignmentsParse(
        Source => $Source, ObjectType => $Kind, Class => $Class, ConfigItemID => $Param{ConfigItemID},
        Context => { CONTROL => $Param{Control}, CONTROLOBJECTIVE => $Param{Objective}, FINDING => $Param{Finding} },
    );
    die (( $Assignments->{Error} || 'Risk assignments failed.' ) . "\n") if !$Assignments->{Success};
    my $Values = $Assignments->{Values};
    my $Identity = $Values->{$IdentityField};
    die "Risk identity must be a populated scalar.\n" if !defined $Identity || ref $Identity || $Identity eq '';
    my $PID = $Kernel::OM->Get('Kernel::System::PID');
    my $Lock = 'TESSERA.Finding.' . sha256_hex("$Kind\0$Class\0$IdentityField\0$Identity");
    die "Risk identity is busy; retry on the next dispatch.\n" if !$PID->PIDCreate( Name => $Lock );
    my $RiskID = eval {
        my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
        my $Prefix = $Kind eq 'MELTObject' ? 'ZTSM::MELT' : 'ZTSM::GovernanceObject';
        my %Classes = reverse %{ $Catalog->ItemList( Class => "$Prefix\::Class", Valid => 1 ) || {} };
        my %Statuses = reverse %{ $Catalog->ItemList( Class => "$Prefix\::Status", Valid => 1 ) || {} };
        die "Risk destination or Active status is unavailable.\n" if !$Classes{$Class} || !$Statuses{Active};
        my $Object = $Kernel::OM->Get("Kernel::System::$Kind");
        my $Search = $Kind . 'Search';
        my @Existing = $Object->$Search( Result => 'ARRAY', Classes => [$Class], Limit => 2,
            "DynamicField_$IdentityField" => { Equals => $Identity }, UserID => $Param{UserID} );
        die "Risk identity is ambiguous.\n" if @Existing > 1;
        my $ID = $Existing[0];
        if (!$ID) {
            my $Add = $Kind . 'Add';
            my %Fields = map { ("DynamicField_$_" => $Values->{$_}) } keys %{$Values};
            $ID = $Object->$Add( ClassID => $Classes{$Class}, ZTSMStatusID => $Statuses{Active},
                Name => 'Policy finding: ' . ( $Param{Finding}{Target}{Name} || $Param{Finding}{Asset}{Name} || $Identity ), UserID => $Param{UserID}, %Fields );
            die "Risk creation failed.\n" if !$ID;
        }
        my $Body = 'Failing source: ' . ( $Param{Finding}{Source}{Name} || '' )
            . "\nAffected target: " . ( $Param{Finding}{Target}{Name} || $Param{Finding}{Asset}{Name} || '' )
            . "\n" . $Param{Evaluation}{Field} . ': ' . $Param{Evaluation}{Value}
            . "\nCondition: " . $Param{Evaluation}{Condition};
        $Body .= "\nReference: " . $_->{Path} . ' -> ' . ( $_->{Object}{Name} || '' ) for @{ $Param{Finding}{Matches} || [] };
        die "Cannot append Risk evidence.\n" if !$Kernel::OM->Get("Kernel::System::$Kind\::Activity")->ActivityAdd(
            $Kind . 'ID' => $ID, EventType => 'ControlFinding', Source => 'ControlRuntime',
            Subject => 'Control finding: ' . ( $Param{Control}{Name} || $Param{ConfigItemID} ), Body => $Body,
            Payload => { ControlID => $Param{ConfigItemID}, ObjectiveID => $Param{Objective}{GovernanceObjectID},
                Finding => $Param{Finding}, Value => $Param{Evaluation}{Value}, Condition => $Param{Evaluation}{Condition}, EvaluationDate => $Param{Evaluation}{EvaluationDate}, TimeZone => $Param{Evaluation}{TimeZone} }, UserID => $Param{UserID},
        );
        $ID;
    };
    my $Error = $@;
    $PID->PIDDelete( Name => $Lock );
    die $Error if $Error;
    return { ObjectType => $Kind, Class => $Class, ObjectID => $RiskID };
}

sub _RiskCreateOnFailure {
    my ( $Self, %Param ) = @_;
    return { Success => 1, RiskCreated => 0 } if lc( $Param{Result} || '' ) ne 'fail';
    return { Success => 1, RiskCreated => 0 } if !_Truthy( _Scalar( $Param{Objective}{'DynamicField_ZRM-CreateRisk'} ) );

    my $Target = _Scalar( $Param{Objective}{'DynamicField_ZRM-RiskClass'} ) || '';
    $Target =~ s{\A\s*\@?}{};
    $Target =~ s{\s+\z}{};
    return { Success => 0, RiskCreated => 0, RiskError => 'ZRM-RiskClass is required when ZRM-CreateRisk is selected.' }
        if $Target !~ m{\A(MELTObject|GovernanceObject)\.([A-Za-z][A-Za-z0-9_-]*)\z};
    my ( $ObjectType, $Class ) = ( $1, $2 );
    my $Source = ObjectSource(Object => $Param{Objective}, Field => 'FieldAsssignment') || '';
    my $Assignments = $Self->_RiskAssignmentsParse(
        Source => $Source, ObjectType => $ObjectType, Class => $Class,
        Context => { CONTROL => $Param{Control}, CONTROLOBJECTIVE => $Param{Objective}, TICKET => $Param{Ticket} || {} },
        ConfigItemID => $Param{ConfigItemID},
    );
    return { Success => 0, RiskCreated => 0, RiskError => $Assignments->{Error} } if !$Assignments->{Success};

    my $CatalogClass = $ObjectType eq 'MELTObject' ? 'ZTSM::MELT::Class' : 'ZTSM::GovernanceObject::Class';
    my $StatusClass  = $ObjectType eq 'MELTObject' ? 'ZTSM::MELT::Status' : 'ZTSM::GovernanceObject::Status';
    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %ClassID = reverse %{ $Catalog->ItemList( Class => $CatalogClass, Valid => 1 ) || {} };
    my %StatusID = reverse %{ $Catalog->ItemList( Class => $StatusClass, Valid => 1 ) || {} };
    return { Success => 0, RiskCreated => 0, RiskError => "Risk class '$Target' is unavailable or inactive." } if !$ClassID{$Class};
    my $ActiveID = $StatusID{Active} || $StatusID{Production} || ( sort { $a <=> $b } values %StatusID )[0];
    return { Success => 0, RiskCreated => 0, RiskError => "No active status is available for '$ObjectType'." } if !$ActiveID;

    my $Object = eval { $Kernel::OM->Get("Kernel::System::$ObjectType") };
    return { Success => 0, RiskCreated => 0, RiskError => "$ObjectType is not installed." } if !$Object;
    my ($IdentityField) = grep {
        defined $Assignments->{Values}{$_} && "$Assignments->{Values}{$_}" eq "$Param{ConfigItemID}"
    } keys %{ $Assignments->{Values} };
    if ($IdentityField) {
        my $SearchMethod = $ObjectType . 'Search';
        my @Existing = $Object->$SearchMethod(
            Result => 'ARRAY', Limit => 1, Classes => [$Class],
            "DynamicField_$IdentityField" => { Equals => $Param{ConfigItemID} },
        );
        return {
            Success => 1, RiskCreated => 0, RiskObjectType => $ObjectType,
            RiskObjectID => $Existing[0], RiskClass => $Class,
        } if @Existing;
    }
    my $Name = 'Control failure: ' . ( $Param{Control}{Name} || $Param{Control}{Number} || $Param{ConfigItemID} );
    my %Create = ( ClassID => $ClassID{$Class}, ZTSMStatusID => $ActiveID, Name => $Name, UserID => $Param{UserID} );
    $Create{"DynamicField_$_"} = $Assignments->{Values}{$_} for keys %{ $Assignments->{Values} };
    my $Method = $ObjectType . 'Add';
    my $RiskID = $Object->$Method(%Create);
    return { Success => 0, RiskCreated => 0, RiskError => "Failed to create '$Target'." } if !$RiskID;
    return { Success => 1, RiskCreated => 1, RiskObjectType => $ObjectType, RiskObjectID => $RiskID, RiskClass => $Class };
}

sub _RiskAssignmentsParse {
    my ( $Self, %Param ) = @_;
    my $Evaluated = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->FieldAssignmentsEvaluate(
        Source     => $Param{Source},
        ObjectType => $Param{ObjectType},
        Class      => $Param{Class},
        Context    => $Param{Context},
        ThisValue  => $Param{ConfigItemID},
    );
    return { Success => 0, Error => $Evaluated->{Error} } if !$Evaluated->{Success};

    for my $FieldName ( keys %{ $Evaluated->{Value} } ) {
        my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $FieldName );
        return { Success => 0, Error => "Dynamic Field '$FieldName' does not belong to $Param{ObjectType}." }
            if !$Field || ( $Field->{ObjectType} || '' ) ne $Param{ObjectType};
    }
    return { Success => 1, Values => $Evaluated->{Value} };
}

sub _ConfigItemFieldSet {
    my ( $Self, %Param ) = @_;
    my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Param{FieldName} );
    return if !$Field || ( $Field->{ObjectType} || '' ) ne 'ITSMConfigItem';
    my $Control = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID => $Param{ConfigItemID}, Silent => 1,
    );
    return if ref $Control ne 'HASH' || !$Control->{VersionID};
    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $Field, ObjectID => $Control->{VersionID}, Value => $Param{Value}, UserID => $Param{UserID},
    );
}

sub _Scalar {
    my ($Value) = @_;
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    return if ref $Value;
    return $Value;
}

sub _Truthy {
    my ($Value) = @_;
    return 0 if !defined $Value || $Value eq '' || $Value =~ m{\A(?:0|no|false|off)\z}i;
    return 1;
}

sub _Epoch {
    my ($Value) = @_;
    return if !defined $Value || $Value eq '';
    return 0 + $Value if $Value =~ m{\A\d+\z};
    return if $Value !~ m{\A(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})\z};
    require Time::Local;
    return eval { Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 ) };
}

1;
