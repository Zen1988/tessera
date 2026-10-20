use strict;
use warnings;
use Test::More;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::AsyncExecution;
use Kernel::System::TESSERA::ControlRuntime;
{
 package AsyncTestOM;
 sub Get { $_[0] }
 sub GenerateRandomString {my($S,%P)=@_; 'A'x$P{Length}}
 sub GetConfig { $_[0]{Config} }
 sub WebserviceGet {my($S,%P)=@_;return $S->{Provider} if $P{Name};{ValidID=>1,Config=>{Requester=>{Invoker=>{Launch=>{Type=>'Test'}},Transport=>{Config=>{Timeout=>10}}}}}}
 sub WebserviceAdd {my($S,%P)=@_;$S->{Provider}={ID=>44};$S->{ProviderConfig}=\%P;44}
 sub Encode {my($S,%P)=@_;require JSON::PP;JSON::PP->new->canonical->encode($P{Data})}
 sub Decode {my($S,%P)=@_;require JSON::PP;JSON::PP->new->decode($P{Data})}
 sub SystemTime2TimeStamp {'2026-10-13 18:00:00'}
 sub Prepare {my($S,%P)=@_;$S->{SQL}=$P{SQL};$S->{Rows}= $P{SQL}=~/COUNT/ ? [[0]] : [];1}
 sub FetchrowArray {my($S)=@_;my $Row=shift @{$S->{Rows}};return $Row?@$Row:()}
 sub Do {my($S,%P)=@_;push @{$S->{Writes}},\%P;1}
 sub TaskAdd {my($S,%P)=@_;push @{$S->{Tasks}},\%P;1}
 sub PIDCreate {1} sub PIDDelete {1}
 sub RunResult {my($S,%P)=@_;push @{$S->{Handled}},\%P;1}
}
{ package AsyncTestConfig;
 sub Get {my($S,$K)=@_;$K eq 'TESSERA::AsyncExecution::Handlers'
    ? {Sample=>{Module=>'Kernel::System::TestAsyncHandler',Function=>'RunResult'}}:undef}
}
{ package AsyncTestRuntime; our @ISA=('Kernel::System::TESSERA::AsyncExecution');
 sub _Get {$_[0]{Row}}
 sub _QueueResume {$_[0]{Queued}++;1}
}
my $OM=bless {},'AsyncTestOM';$Kernel::OM=$OM;
my $Config=bless {},'AsyncTestConfig';
{ no warnings 'redefine'; local *AsyncTestOM::Get=sub {my($S,$Name)=@_;return $Config if $Name eq 'Kernel::Config';$S};
 my $S=AsyncTestRuntime->new();
 ok($S->ProviderEnsure(),'Provider callback web service created');
 is($OM->{ProviderConfig}{Config}{Provider}{Transport}{Config}{RouteOperationMapping}{ExecutionCallback}{Route},'/ExecutionCallback','POST callback route configured');
 ok($S->ProviderEnsure(),'Provider installation is idempotent');
 my $A=$S->Start(HandlerKey=>'Sample',TargetType=>'ControlObjective',TargetID=>9,ActorID=>7,
    Continuation=>{Step=>'after remote'},Payload=>{Job=>'run'},WebserviceID=>3,Invoker=>'Launch');
 ok($A->{Success},'Start persists and queues without waiting for remote completion');
 is($A->{Status},'PENDING','Dispatch acceptance is pending');
 is($OM->{Tasks}[0]{Type},'GenericInterface','Outbound dispatch uses native OTOBO web service scheduler');
 is($OM->{Tasks}[0]{Data}{Data}{ExecutionUID},$A->{ExecutionUID},'Remote request carries correlation ID');
 ok($OM->{Tasks}[0]{Data}{Data}{CallbackToken},'Remote request carries per-run callback credential');
 my $Hash=Digest::SHA::sha256_hex($OM->{Tasks}[0]{Data}{Data}{CallbackToken});
 $S->{Row}={State=>'PENDING',TokenHash=>$Hash,ExecutionUID=>$A->{ExecutionUID}};
 is($S->Callback(ExecutionUID=>$A->{ExecutionUID},CallbackToken=>'B'x64,ExitCode=>0,Response=>'done')->{Success},0,'Wrong callback token rejected');
 is($S->Callback(ExecutionUID=>$A->{ExecutionUID},CallbackToken=>'A'x64,Response=>'accepted')->{Success},0,'Missing exit code remains pending');
 $S->{Row}{State}='PENDING';$S->{Row}{ExitCode}=0;$S->{Row}{Response}='done';
 ok($S->Callback(ExecutionUID=>$A->{ExecutionUID},CallbackToken=>'A'x64,ExitCode=>0,Response=>'done')->{Success},'Exit zero accepted');
 is($S->{Queued},1,'Callback queues continuation once');
 $S->{Row}{State}='READY';
 ok($S->Callback(ExecutionUID=>$A->{ExecutionUID},CallbackToken=>'A'x64,ExitCode=>0,Response=>'done')->{Duplicate},'Duplicate terminal callback is idempotent');
 is($S->{Queued},1,'Duplicate callback cannot enqueue another continuation');
 is($S->Callback(ExecutionUID=>$A->{ExecutionUID},CallbackToken=>'A'x64,ExitCode=>1,Response=>'failed')->{Success},0,'Conflicting callback rejected');
 $S->{Row}{State}='QUEUED';$S->{Row}{HandlerKey}='Sample';$S->{Row}{Continuation}='{"Step":"after remote"}';
 $S->{Row}{TargetType}='ControlObjective';$S->{Row}{TargetID}=9;$S->{Row}{ActorID}=7;
 $S->{Row}{ExitCode}=1;$S->{Row}{Response}='failed';
 { no warnings 'redefine'; local *AsyncTestOM::Get=sub {my($S,$Name)=@_;return $Config if $Name eq 'Kernel::Config';$S};
   ok($S->Resume(ExecutionUID=>$A->{ExecutionUID}),'Nonzero exit resumes registered failure handler'); }
 is($OM->{Handled}[0]{ExitCode},1,'Handler receives nonzero exit code');
 is($OM->{Handled}[0]{Context}{Step},'after remote','Handler receives saved continuation');
}
done_testing();
