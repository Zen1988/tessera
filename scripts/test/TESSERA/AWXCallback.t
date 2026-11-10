use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use Digest::SHA qw(sha256_hex);
use lib '.', 'Kernel/Package/GovernanceDB';
use Kernel::System::TESSERA::AsyncExecution;
use Kernel::System::TESSERA::AWXExecution;
use Kernel::GenericInterface::Invoker::AWX::JobLaunchCallback;
use Kernel::GenericInterface::Operation::TESSERA::ExecutionCallback;
{ package CallbackAsync;
 our @ISA=('Kernel::System::TESSERA::AsyncExecution');
 sub _Get {return Storable::dclone($_[0]{OM}{Row})}
 sub _QueueResume {$_[0]{Queued}++;1}
 package CallbackOM;
 sub Get {my($S,$Name)=@_;return $S->{Async} if $Name eq 'Kernel::System::TESSERA::AsyncExecution';$S}
 sub Header {$_[0]{Header}}
 sub SystemTime2TimeStamp {'2026-10-26 12:00:00'}
 sub Encode {my($S,%P)=@_;JSON::PP->new->canonical->encode($P{Data})}
 sub Connect {$_[0]}
 sub do {my($S,$SQL,$Unused,$Now,$UID,$Hash)=@_;return '0E0' if $S->{Row}{State} ne 'PENDING' || $Hash ne $S->{Row}{TokenHash};$S->{Row}{State}='DISPATCHING';1}
 sub Do {
  my($S,%P)=@_;push @{$S->{Writes}},$P{SQL};my @B=map {$$_} @{$P{Bind} || []};
  if ($P{SQL}=~/SET dispatch_data/) {$S->{Row}{DispatchData}=$B[0]}
  elsif ($P{SQL}=~/SET state = \?/) {$S->{Row}{State}=$B[0] if $S->{Row}{State} eq 'DISPATCHING'}
  elsif ($P{SQL}=~/SET state = 'READY', exit_code/) {if ($S->{Row}{State}=~/^(PENDING|WAITING|DISPATCHING|DISPATCH_UNKNOWN)$/) {@{$S->{Row}}{qw(State ExitCode Response)}=('READY',$B[0],$B[1])}}
  elsif ($P{SQL}=~/ADD COLUMN (\w+)/) {push @{$S->{Columns}},$1}
  1;
 }
 sub Prepare {1} sub FetchrowArray {return} sub GetColumnNames {@{$_[0]{Columns}}}
 sub Run {
  my($S,%P)=@_;$S->{Requests}++;$S->{Sent}=$P{Data};
  if ($S->{CallbackDuringLaunch}) {$S->{Async}->Callback(ExecutionUID=>$S->{Row}{ExecutionUID},CallbackToken=>$S->{Token},ExitCode=>0,Response=>{message=>'done'})}
  return $S->{Fail}?{Success=>0}:{Success=>1,Data=>{JobID=>123,InputAccepted=>1,Response=>{extra_vars=>JSON::PP->new->encode({tessera_callback=>{CallbackToken=>$S->{Token}}})}}};
 }
 sub WebserviceGet {$_[0]{WS}}
}
my $Token='A'x64;my $UID='B'x40;
my $OM=bless {Token=>$Token,Columns=>[qw(execution_uid token_hash)]},'CallbackOM';
my $Async=CallbackAsync->new();$Async->{OM}=$OM;$OM->{Async}=$Async;local $Kernel::OM=$OM;
sub reset_row {$OM->{Row}={ExecutionUID=>$UID,TokenHash=>sha256_hex($Token),ActorID=>7,State=>'PENDING',Deadline=>'2099-01-01 00:00:00',RequestData=>'non-secret snapshot'};delete $OM->{Fail};delete $OM->{CallbackDuringLaunch};$OM->{Requests}=0;$Async->{Queued}=0}
reset_row();
my $Dispatch=Kernel::System::TESSERA::AWXExecution->new();
my %Args=(ExecutionUID=>$UID,CallbackToken=>$Token,WebserviceID=>12,Invoker=>'JobLaunchCallback',Payload=>{TemplateID=>42});
ok($Dispatch->Dispatch(%Args),'dispatch completes');is($OM->{Requests},1,'one AWX launch');is($OM->{Row}{State},'WAITING','launch acceptance waits for callback');
ok($Dispatch->Dispatch(%Args),'accepted launch worker replay no-op');is($OM->{Requests},1,'accepted launch cannot be replayed while waiting');
unlike($OM->{Row}{DispatchData},qr/\Q$Token\E/,'callback token redacted even inside JSON-string extra_vars');
# A duplicate scheduler invocation must not relaunch, even while callback pending.
# Dispatch intent is represented by dispatch_data after acceptance as well.
$OM->{Row}{State}='DISPATCH_UNKNOWN';ok($Dispatch->Dispatch(%Args),'uncertain worker replay is a no-op');is($OM->{Requests},1,'uncertain dispatch never blindly retried');
my $R=$Async->Callback(ExecutionUID=>$UID,CallbackToken=>$Token,ExitCode=>0,Response=>{message=>'finished',accidental_token=>$Token});
ok($R->{Success},'authenticated result resolves uncertain dispatch');is($OM->{Row}{State},'READY','callback persisted');unlike($OM->{Row}{Response},qr/\Q$Token\E/,'plaintext capability never saved in result');
ok($Async->Callback(ExecutionUID=>$UID,CallbackToken=>$Token,ExitCode=>0,Response=>{message=>'finished',accidental_token=>$Token})->{Duplicate},'identical callback retry idempotent');
ok(!$Async->Callback(ExecutionUID=>$UID,CallbackToken=>$Token,ExitCode=>1,Response=>'different')->{Success},'conflicting result rejected');
ok(!$Async->Callback(ExecutionUID=>$UID,CallbackToken=>'C'x64,ExitCode=>0,Response=>'x')->{Success},'wrong token rejected');
my $Public=$Dispatch->Get(ExecutionUID=>$UID,ActorID=>7);ok($Public->{Response} && $Public->{RequestData},'saved inputs and result readable later');ok(!exists $Public->{TokenHash},'status does not disclose token verifier');ok(!$Dispatch->Get(ExecutionUID=>$UID,ActorID=>8),'different actor cannot read execution');
reset_row();$OM->{CallbackDuringLaunch}=1;ok($Dispatch->Dispatch(%Args),'fast callback during launch accepted');is($OM->{Row}{State},'READY','late launch receipt cannot overwrite callback state');
reset_row();$OM->{Row}{Deadline}='2000-01-01 00:00:00';ok(!$Async->Callback(ExecutionUID=>$UID,CallbackToken=>$Token,ExitCode=>0,Response=>'late')->{Success},'expired capability fails before reconciliation cron');
reset_row();$OM->{Fail}=1;ok($Dispatch->Dispatch(%Args),'transport failure stored as uncertain');is($OM->{Row}{State},'DISPATCH_UNKNOWN','uncertainty explicit');ok($Dispatch->Dispatch(%Args),'retry no-op');is($OM->{Requests},1,'transport failure not relaunched');
ok($Async->StorageEnsure(),'additive history storage upgrade');is_deeply($OM->{Columns},[qw(execution_uid token_hash request_data dispatch_data)],'only declared history columns added');my $Writes=@{$OM->{Writes}};ok($Async->StorageEnsure(),'same-version history reinstall');is(scalar @{$OM->{Writes}},$Writes,'no duplicate ALTERs on reinstall');
reset_row();$OM->{Header}='Bearer '.$Token;
my $Op=Kernel::GenericInterface::Operation::TESSERA::ExecutionCallback->new();
ok($Op->Run(Data=>{ExecutionUID=>$UID,ExitCode=>0,Response=>{result=>'ok'}})->{Success},'real provider operation accepts scoped header and saved execution');
$OM->{Header}='Bearer wrong';ok(!$Op->Run(Data=>{ExecutionUID=>$UID,ExitCode=>0,Response=>'x'})->{Success},'provider rejects malformed auth');
done_testing();
