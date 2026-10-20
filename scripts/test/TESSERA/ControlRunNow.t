use strict;
use warnings;
use Test::More;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::ControlRuntime;
use Kernel::Modules::AgentControlObjectiveRun;
{
 package RunAdapters;
 sub Get { $_[0] }
 sub Permission {my($S,%P)=@_; push @{$S->{Permissions}},\%P; !$S->{Deny} && ($P{ItemID}||$P{ClassID}) && (!$S->{DenyID} || $P{ItemID}!=$S->{DenyID})}
 sub GovernanceObjectGet {$_[0]{Objective}}
 sub ConfigItemGet {$_[0]{Control}}
 sub ConfigItemSearch {my($S,%P)=@_;$S->{Search}=\%P; @{$S->{IDs}||[]}}
 sub PIDCreate {my($S,%P)=@_;return if $S->{Busy}; $S->{Locks}{$P{Name}}=1;1}
 sub PIDDelete {my($S,%P)=@_;delete $S->{Locks}{$P{Name}};1}
 sub TaskAdd {my($S,%P)=@_;$S->{Task}=\%P;defined $S->{TaskResult}?$S->{TaskResult}:77}
 sub ActivityAdd {my($S,%P)=@_;$S->{Article}=\%P;1}
 sub ItemList {{5=>'Risk'}}
}
{ package RunCapture; our @ISA=('Kernel::System::TESSERA::ControlRuntime');
 sub _AutomaticEvaluate {my($S,%P)=@_;$S->{Evaluation}=\%P;{Success=>1,Status=>'Pass'}}
}
sub Setup {
 my $OM=bless {Objective=>{Class=>'ControlObjective',Name=>'EOS',ZTSMStatus=>'Active','DynamicField_ZRM-ControlType'=>'automatic'},
 Control=>{Class=>'Control','DynamicField_ZRM-ControlObjective'=>9},IDs=>[11,12]},'RunAdapters';
 $Kernel::OM=$OM; return $OM;
}
my $OM=Setup(); my $Runtime=RunCapture->new();
is($Runtime->RunControlNow(ConfigItemID=>11,UserID=>7)->{Status},'Pass','Authorized ad-hoc evaluation runs');
is($Runtime->{Evaluation}{RunSource},'Agent Run now','Evaluation evidence identifies ad-hoc source');
is($Runtime->{Evaluation}{UserID},7,'Authenticated actor retained');
ok(!grep({$_->{Scope} eq 'Item' && !$_->{ItemID}} @{$OM->{Permissions}}),'Native ItemID permission contract');
$OM->{Deny}=1;
is($Runtime->RunControlNow(ConfigItemID=>11,UserID=>7)->{Status},'DENIED','Denied control cannot execute');
$OM=Setup(); $OM->{Objective}{'DynamicField_ZRM-ControlType'}='manual';
is($Runtime->RunControlNow(ConfigItemID=>11,UserID=>7)->{Status},'AWAITING_EVIDENCE','Manual controls require evidence');
$OM=Setup();
is($Runtime->QueueControlObjective(GovernanceObjectID=>9,UserID=>7)->{Status},'QUEUED','Native daemon task queued');
is($OM->{Task}{MaximumParallelInstances},1,'One pending/running objective task');
is($OM->{Task}{Data}{Function},'RunControlObjectiveNow','Worker invokes shared runtime');
is_deeply($OM->{Task}{Data}{Params},[GovernanceObjectID=>9,UserID=>7],'Worker reuses authenticated actor');
is(scalar keys %{$OM->{Locks}},0,'Queue lock released');
$OM->{TaskResult}=-1;
is($Runtime->QueueControlObjective(GovernanceObjectID=>9,UserID=>7)->{Status},'BUSY','Duplicate queue rejected');
$OM=Setup();
ok($Runtime->RunControlObjectiveNow(GovernanceObjectID=>9,UserID=>7),'All instances execute in worker');
is_deeply($OM->{Search}{'DynamicField_ZRM-ControlObjective'},{Equals=>9},'Search restricted to exact objective');
is($OM->{Article}{Payload}{Counts}{Pass},2,'Objective article summarizes both instances');
is(scalar keys %{$OM->{Locks}},0,'Worker lock released');
$OM=Setup();
ok($Runtime->ContinueAfterExternal(ExecutionUID=>'E1',TargetType=>'ControlObjective',TargetID=>9,ActorID=>7,
    Response=>'remote failed',ExitCode=>3),'Nonzero external completion records evidence');
is($OM->{Article}{Payload}{ExitCode},3,'Failure article preserves exit code');
ok(!$OM->{Task},'External failure does not queue Control evaluation');
$OM=Setup();
ok($Runtime->ContinueAfterExternal(ExecutionUID=>'E2',TargetType=>'ControlObjective',TargetID=>9,ActorID=>7,
    Response=>'no callback'),'Timeout records unknown outcome');
ok(!$OM->{Task},'Timeout does not claim success');
$OM=Setup();
ok($Runtime->ContinueAfterExternal(ExecutionUID=>'E3',TargetType=>'ControlObjective',TargetID=>9,ActorID=>7,
    Response=>'remote success',ExitCode=>0),'Exit zero queues next Control evaluation');
is($OM->{Task}{Data}{Function},'RunControlObjectiveNow','Success resumes via OTOBO daemon');
$OM=Setup(); $OM->{DenyID}=12;delete $Runtime->{Evaluation};
eval {$Runtime->RunControlObjectiveNow(GovernanceObjectID=>9,UserID=>7)};
like($@,qr/write access to every Control/,'Batch scope preflight denies inaccessible instance');
ok(!$Runtime->{Evaluation},'No partial batch evaluation before scope preflight');
is(scalar keys %{$OM->{Locks}},0,'Failed worker releases lock');
$OM=Setup();$OM->{Deny}=1;
eval {$Runtime->RunControlObjectiveNow(GovernanceObjectID=>9,UserID=>7)};
like($@,qr/write permission/,'Worker rechecks revoked objective permission');
{
 package RunWeb;
 sub Get {$_[0]}
 sub GetParam {9}
 sub RequestMethod {$_[0]{Method}}
 sub _RunObjectiveGet {{Name=>'EOS'}}
 sub QueueControlObjective {$_[0]{Queued}++;{Status=>'QUEUED'}}
 sub ChallengeTokenCheck {$_[0]{Checked}++;die 'Invalid challenge' if !$_[0]{Valid};1}
 sub ErrorScreen {'ERROR'} sub Header {''} sub Footer {''} sub Output {'FORM'}
}
my $Web=bless {Method=>'GET'},'RunWeb';$Kernel::OM=$Web;
my $UI=Kernel::Modules::AgentControlObjectiveRun->new(UserID=>7);
is($UI->Run(),'FORM','GET displays form');ok(!$Web->{Queued},'GET never queues');
$UI->{Subaction}='Queue';is($UI->Run(),'ERROR','GET queue request rejected');
$Web->{Method}='POST';eval {$UI->Run()};like($@,qr/Invalid challenge/,'Invalid CSRF proof rejected');
ok(!$Web->{Queued},'Invalid CSRF cannot enqueue');
$Web->{Valid}=1;is($UI->Run(),'FORM','Valid POST accepted');is($Web->{Queued},1,'Exactly one task queued');
done_testing();
