package Kernel::System::TESSERA::AsyncExecution;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);

our @ObjectDependencies = (
    'Kernel::System::DB', 'Kernel::System::JSON', 'Kernel::System::Main',
    'Kernel::System::Scheduler', 'Kernel::System::Daemon::SchedulerDB',
    'Kernel::System::GenericInterface::Webservice', 'Kernel::Config', 'Kernel::System::PID',
    'Kernel::System::Time',
);
sub new { my ($Type) = @_; return bless {}, $Type; }

sub ProviderEnsure {
    my ($Self)=@_;
    my $Webservice=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    my $Existing=$Webservice->WebserviceGet(Name=>'TESSERAAsyncExecutionCallback');
    return 1 if $Existing && $Existing->{ID};
    return $Webservice->WebserviceAdd(Name=>'TESSERAAsyncExecutionCallback',ValidID=>1,UserID=>1,
        Config=>{
            Debugger=>{DebugThreshold=>'error',TestMode=>'0'},
            Provider=>{
                Operation=>{ExecutionCallback=>{Type=>'TESSERA::ExecutionCallback',
                    Description=>'Complete a saved TESSERA external execution',MappingInbound=>{},MappingOutbound=>{}}},
                Transport=>{Type=>'HTTP::REST',Config=>{MaxLength=>'1048576',KeepAlive=>'0',
                    RouteOperationMapping=>{ExecutionCallback=>{RequestMethod=>['POST'],Route=>'/ExecutionCallback'}}}},
            },
        }) ? 1 : 0;
}

sub _Handler {
    my ($Self,$Key) = @_;
    return if !$Key || $Key !~ /\A[A-Za-z][A-Za-z0-9_]{0,99}\z/;
    my $Registry=$Kernel::OM->Get('Kernel::Config')->Get('TESSERA::AsyncExecution::Handlers') || {};
    my $Handler=$Registry->{$Key};
    return if ref $Handler ne 'HASH' || ($Handler->{Module}||'') !~ /\AKernel::System::[A-Za-z0-9_:]+\z/
        || ($Handler->{Function}||'') !~ /\A[A-Za-z][A-Za-z0-9_]*\z/;
    return $Handler;
}

# Trusted backend callers select a registered continuation and a configured OTOBO web service.
# No YAML or request parameter is interpreted as Perl code or a network destination.
sub Start {
    my ($Self,%P)=@_;
    return {Success=>0,Error=>'Invalid execution target or continuation.'}
        if !$P{TargetType} || $P{TargetType}!~/\A[A-Za-z][A-Za-z0-9_]{0,49}\z/
        || !$P{TargetID} || $P{TargetID}!~/\A[1-9][0-9]*\z/
        || !$P{ActorID} || $P{ActorID}!~/\A[1-9][0-9]*\z/
        || ref $P{Continuation} ne 'HASH' || !_Handler($Self,$P{HandlerKey})
        || ref $P{Payload} ne 'HASH' || !$P{WebserviceID} || $P{WebserviceID}!~/\A[1-9][0-9]*\z/
        || !$P{Invoker} || $P{Invoker}!~/\A[A-Za-z][A-Za-z0-9_-]{0,99}\z/;
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$P{WebserviceID});
    return {Success=>0,Error=>'Configured requester invoker is unavailable.'}
        if ref $WS ne 'HASH' || ($WS->{ValidID}||0)!=1
        || !$WS->{Config}{Requester}{Invoker}{$P{Invoker}};
    my $HTTPTimeout=$WS->{Config}{Requester}{Transport}{Config}{Timeout};
    return {Success=>0,Error=>'Web service request timeout must be between 1 and 60 seconds.'}
        if !defined $HTTPTimeout || $HTTPTimeout!~/\A[0-9]+\z/ || $HTTPTimeout<1 || $HTTPTimeout>60;
    my $JSON=$Kernel::OM->Get('Kernel::System::JSON');
    my $Context=$JSON->Encode(Data=>$P{Continuation},SortKeys=>1);
    return {Success=>0,Error=>'Continuation is too large.'} if !defined $Context || length($Context)>65536;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return {Success=>0,Error=>'Execution queue is full.'}
        if !$DB->Prepare(SQL=>"SELECT COUNT(*) FROM ztsm_async_execution WHERE state IN ('PENDING','READY','QUEUED','RUNNING')")
        || (($DB->FetchrowArray())[0]||0)>=1000;
    my $Main=$Kernel::OM->Get('Kernel::System::Main');
    my $UID=$Main->GenerateRandomString(Length=>40);
    my $Token=$Main->GenerateRandomString(Length=>64);
    return {Success=>0,Error=>'Could not generate execution identity.'} if !$UID || !$Token;
    my $Hash=sha256_hex($Token);
    my $Timeout=$P{TimeoutSeconds}||3600;
    return {Success=>0,Error=>'Timeout must be between 60 seconds and 7 days.'}
        if $Timeout!~/\A[0-9]+\z/ || $Timeout<60 || $Timeout>604800;
    my $Deadline=$Kernel::OM->Get('Kernel::System::Time')->SystemTime2TimeStamp(SystemTime=>time+$Timeout);
    my $OK=$DB->Do(SQL=>'INSERT INTO ztsm_async_execution (execution_uid, token_hash, handler_key, target_type, target_id, actor_id, continuation, state, deadline_time, create_time, change_time) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, current_timestamp)',
        Bind=>[\$UID,\$Hash,\$P{HandlerKey},\$P{TargetType},\$P{TargetID},\$P{ActorID},\$Context,\('PENDING'),\$Deadline]);
    return {Success=>0,Error=>'Could not save execution.'} if !$OK;
    my $Queued=$Kernel::OM->Get('Kernel::System::Scheduler')->TaskAdd(
        Type=>'GenericInterface',Name=>'TESSERA.AsyncDispatch.'.$P{Invoker},Attempts=>3,
        Data=>{WebserviceID=>$P{WebserviceID},Invoker=>$P{Invoker},
            Data=>{%{$P{Payload}},ExecutionUID=>$UID,CallbackToken=>$Token}});
    if (!$Queued) {
        $DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'DISPATCH_ERROR', change_time = current_timestamp WHERE execution_uid = ? AND state = 'PENDING'",Bind=>[\$UID]);
        return {Success=>0,Error=>'Could not queue OTOBO web service dispatch.',ExecutionUID=>$UID};
    }
    return {Success=>1,Status=>'PENDING',ExecutionUID=>$UID};
}

sub _Get {
    my ($Self,$UID)=@_;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Prepare(SQL=>'SELECT execution_uid, token_hash, handler_key, target_type, target_id, actor_id, continuation, state, exit_code, response FROM ztsm_async_execution WHERE execution_uid = ?',Bind=>[\$UID],Limit=>1);
    my @R=$DB->FetchrowArray();return if !@R;
    my %H; @H{qw(ExecutionUID TokenHash HandlerKey TargetType TargetID ActorID Continuation State ExitCode Response)}=@R;
    return \%H;
}

sub Callback {
    my ($Self,%P)=@_;
    return {Success=>0,Error=>'Invalid callback.'} if !$P{ExecutionUID} || $P{ExecutionUID}!~/\A[A-Za-z0-9]{40}\z/
        || !$P{CallbackToken} || $P{CallbackToken}!~/\A[A-Za-z0-9]{64}\z/
        || !defined $P{ExitCode} || $P{ExitCode}!~/\A-?(?:0|[1-9][0-9]{0,8})\z/
        || !defined $P{Response};
    $P{Response}=$Kernel::OM->Get('Kernel::System::JSON')->Encode(Data=>$P{Response},SortKeys=>1)
        if ref $P{Response};
    return {Success=>0,Error=>'Invalid callback.'} if !defined $P{Response} || length($P{Response})>1048576;
    my $Row=$Self->_Get($P{ExecutionUID});
    return {Success=>0,Error=>'Invalid callback.'} if !$Row;
    my $A=sha256_hex($P{CallbackToken});my $Diff=0;
    for my $I (0..63) {$Diff|=ord(substr($A,$I,1))^ord(substr($Row->{TokenHash},$I,1));}
    return {Success=>0,Error=>'Invalid callback.'} if $Diff;
    if ($Row->{State} ne 'PENDING') {
        return {Success=>1,Duplicate=>1,Status=>$Row->{State}}
            if defined $Row->{ExitCode} && $Row->{ExitCode} eq $P{ExitCode} && ($Row->{Response}//'') eq $P{Response};
        return {Success=>0,Error=>'Conflicting or late callback.'};
    }
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    my $OK=$DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'READY', exit_code = ?, response = ?, change_time = current_timestamp WHERE execution_uid = ? AND token_hash = ? AND state = 'PENDING'",
        Bind=>[\$P{ExitCode},\$P{Response},\$P{ExecutionUID},\$Row->{TokenHash}]);
    return {Success=>0,Error=>'Could not store callback.'} if !$OK;
    my $Latest=$Self->_Get($P{ExecutionUID});
    return {Success=>0,Error=>'Conflicting callback.'} if $Latest->{ExitCode} ne $P{ExitCode} || ($Latest->{Response}//'') ne $P{Response};
    $Self->_QueueResume($P{ExecutionUID});
    return {Success=>1,Status=>'READY'};
}

sub _QueueResume {
    my ($Self,$UID)=@_;
    my $PID=$Kernel::OM->Get('Kernel::System::PID');
    my $Lock='TESSERA.AsyncResumeSchedule.'.$UID;
    return if !$PID->PIDCreate(Name=>$Lock);
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    my $Row=$Self->_Get($UID);
    if (!$Row || $Row->{State} ne 'READY') {$PID->PIDDelete(Name=>$Lock);return;}
    if (!$DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'QUEUED', change_time = current_timestamp WHERE execution_uid = ? AND state = 'READY'",Bind=>[\$UID])) {
        $PID->PIDDelete(Name=>$Lock);return;
    }
    my $Task=$Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB')->TaskAdd(
        Type=>'Cron',Name=>'TESSERA.AsyncResume.'.$UID,Attempts=>3,MaximumParallelInstances=>1,
        Data=>{Module=>'Kernel::System::TESSERA::AsyncExecution',Function=>'Resume',Params=>[ExecutionUID=>$UID]});
    if (!$Task || $Task==-1) {
        $DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'READY', change_time = current_timestamp WHERE execution_uid = ? AND state = 'QUEUED'",Bind=>[\$UID]);
        $PID->PIDDelete(Name=>$Lock);return;
    }
    $PID->PIDDelete(Name=>$Lock);
    return 1;
}

sub Resume {
    my ($Self,%P)=@_;
    my $PID=$Kernel::OM->Get('Kernel::System::PID');
    my $Lock='TESSERA.AsyncResumeRun.'.($P{ExecutionUID}||'');
    return 1 if !$PID->PIDCreate(Name=>$Lock);
    my $Row=$Self->_Get($P{ExecutionUID});
    if (!$Row || $Row->{State} ne 'QUEUED') {$PID->PIDDelete(Name=>$Lock);return 1;}
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    if (!$DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'RUNNING', change_time = current_timestamp WHERE execution_uid = ? AND state = 'QUEUED'",Bind=>[\$P{ExecutionUID}])) {
        $PID->PIDDelete(Name=>$Lock);return 0;
    }
    my $Handler=$Self->_Handler($Row->{HandlerKey});
    my $Context=$Kernel::OM->Get('Kernel::System::JSON')->Decode(Data=>$Row->{Continuation});
    my $Done=eval {
        die 'Continuation is unavailable.' if !$Handler || ref $Context ne 'HASH';
        my $Module=$Kernel::OM->Get($Handler->{Module});
        my $Function=$Handler->{Function};
        $Module->$Function(ExecutionUID=>$P{ExecutionUID},TargetType=>$Row->{TargetType},TargetID=>$Row->{TargetID},
            ActorID=>$Row->{ActorID},Context=>$Context,ExitCode=>$Row->{ExitCode},Response=>$Row->{Response});
    };
    my $State=$Done ? 'DONE' : 'ERROR';
    $DB->Do(SQL=>'UPDATE ztsm_async_execution SET state = ?, change_time = current_timestamp WHERE execution_uid = ? AND state = ?',
        Bind=>[\$State,\$P{ExecutionUID},\('RUNNING')]);
    $PID->PIDDelete(Name=>$Lock);
    return $Done ? 1 : 0;
}

sub Reconcile {
    my ($Self)=@_;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    if ($DB->Prepare(SQL=>"SELECT execution_uid FROM ztsm_async_execution WHERE state = 'PENDING' AND deadline_time < current_timestamp ORDER BY id",Limit=>100)) {
        my @Expired;while(my @R=$DB->FetchrowArray()){push @Expired,$R[0]}
        for my $UID (@Expired) {
            $DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'READY', response = 'Callback timeout', change_time = current_timestamp WHERE execution_uid = ? AND state = 'PENDING'",Bind=>[\$UID]);
        }
    }
    my $Stale=$Kernel::OM->Get('Kernel::System::Time')->SystemTime2TimeStamp(SystemTime=>time-1800);
    if ($DB->Prepare(SQL=>"SELECT execution_uid FROM ztsm_async_execution WHERE state = 'QUEUED' AND change_time < ? ORDER BY id",Bind=>[\$Stale],Limit=>100)) {
        my @Lost;while(my @R=$DB->FetchrowArray()){push @Lost,$R[0]}
        for my $UID (@Lost) {
            $DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'READY', change_time = current_timestamp WHERE execution_uid = ? AND state = 'QUEUED'",Bind=>[\$UID]);
        }
    }
    # A crashed continuation might have made a side effect already. Stop it for
    # review instead of replaying an uncertain step automatically.
    $DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = 'ERROR', change_time = current_timestamp WHERE state = 'RUNNING' AND change_time < ?",Bind=>[\$Stale]);
    return if !$DB->Prepare(SQL=>"SELECT execution_uid FROM ztsm_async_execution WHERE state = 'READY' ORDER BY id",Limit=>100);
    my @UID;while(my @R=$DB->FetchrowArray()){push @UID,$R[0]}
    $Self->_QueueResume($_) for @UID;
    return 1;
}
1;
