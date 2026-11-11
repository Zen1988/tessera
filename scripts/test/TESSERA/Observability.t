use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::Observability;
{
 package OConfig; sub Get {return $main::enabled}
 package OIdentity; sub Authenticate {return $main::client if $main::auth}
 package OActor; sub GetUserData {return (UserID=>2,ValidID=>1)}
 package OPermission; sub MELTObjectCheck {return $main::permission && $_[2] ne 'denied'}
 package OVisible; sub Visible {my ($s,%p)=@_;return $p{TicketID}!=2}
 sub Report {return {Columns=>[{Label=>'Risk category'}],Rows=>[{TicketID=>1,TicketNumber=>'T1',Cells=>['Resolved catalog name'],RiskRow=>{secret=>'hidden'}}]}}
 package OTicket; sub TicketGet {my ($s,%p)=@_;return (TicketID=>$p{TicketID},TicketNumber=>'T'.$p{TicketID},Title=>'Visible ticket',Secret=>'hidden')}
 package OActivity; sub ActivityAdd {die 'activity failure' if $main::activity_fail;push @{$main::db->{activities}},\{@_[1..$#_]};return 1}
 package OHandle;sub commit {return !$main::commit_fail}
 package ODB;
 sub Prepare {
  my ($s,%p)=@_;my @b=map {$$_} @{$p{Bind}||[]};my $q=$p{SQL};die 'Native DB appends LIMIT after FOR UPDATE' if $q=~/FOR UPDATE/ && $p{Limit};$s->{rows}=[];
  if ($q=~/SELECT ENGINE/) {$s->{rows}=[['InnoDB']]}
  elsif ($q=~/GET_LOCK/) {$s->{rows}=[[1]]}
  elsif ($q=~/RELEASE_LOCK/) {$s->{rows}=[[1]]}
  elsif ($q=~/COUNT/) {$s->{rows}=[[scalar keys %{$s->{ledger}}]]}
  elsif ($q=~/SELECT id, cycle_key/) {my $r=$s->{ledger}{$b[1]};$s->{rows}=[[$r->{id},$r->{cycle},$r->{status},$r->{target}]] if $r}
  elsif ($q=~/SELECT id FROM ticket/) {$s->{rows}=[[1],[2],[3]]}
  return 1;
 }
 sub FetchrowArray {my ($s)=@_;return @{shift(@{$s->{rows}})||[]}}
 sub BeginWork {my ($s)=@_;$s->{before}=Storable::dclone({ledger=>$s->{ledger},activities=>$s->{activities}});return 1}

 sub Rollback {my ($s)=@_;@{$s}{qw(ledger activities)}=@{$s->{before}}{qw(ledger activities)};return 1}
 sub Do {
  my ($s,%p)=@_;my @b=map {$$_} @{$p{Bind}||[]};
  if ($p{SQL}=~/INSERT INTO tessera_monitor_alert/) {$s->{ledger}{$b[1]}={id=>scalar(keys %{$s->{ledger}})+1,cycle=>$b[2],status=>$b[3],target=>$b[4],payload=>$b[5]}}
  elsif ($p{SQL}=~/UPDATE tessera_monitor_alert/) {for my $r(values %{$s->{ledger}}){next if $r->{id}!=$b[3];@{$r}{qw(cycle status payload)}=@b[0..2]}}
  return 1;
 }
 package OOM;sub Get {
  my ($s,$n)=@_;my %m=('Kernel::Config'=>'OConfig','Kernel::System::TESSERA::ProviderIdentity'=>'OIdentity','Kernel::System::User'=>'OActor','Kernel::System::TESSERA::APIPermission'=>'OPermission','Kernel::System::MELTObject::Activity'=>'OActivity','Kernel::System::TESSERA::RiskRegister'=>'OVisible','Kernel::System::Ticket'=>'OTicket');
  return $main::db if $n eq 'Kernel::System::DB';return bless {},$m{$n}||die $n;
 }
 package Kernel;our $OM=bless {},'OOM';
}
our ($enabled,$auth,$permission)=(1,1,1);
our ($activity_fail,$commit_fail)=(0,0);
our $db=bless {ledger=>{},activities=>[],dbh=>bless({},'OHandle')},'ODB';
our $client={SourceName=>'prometheus-test',TargetMELTObjectID=>7,ActorID=>2,Identity=>{CustomerUserID=>'monitor'},TicketQueueIDs=>[1]};
my $s=Kernel::System::TESSERA::Observability->new();
my $token='ztsm_'.('a'x12).'.'.('b'x64);
ok($s->Authorize(Header=>'Bearer '.$token,Grant=>'report:tickets'),'authenticated provider identity accepted');
$enabled=0;ok(!$s->Authorize(Header=>'Bearer '.$token),'disabled API denied');$enabled=1;
ok(!$s->Authorize(Header=>'Bearer '.$token."\r\nInjected: yes"),'header injection denied');
$auth=0;ok(!$s->Authorize(Header=>'Bearer '.$token),'revoked/invalid provider identity denied');$auth=1;
my $a={status=>'firing',fingerprint=>'abcdef0123456789',startsAt=>'2026-11-11T01:00:00Z',endsAt=>'2026-11-11T02:00:00Z',labels=>{alertname=>'Test',severity=>'warning'},annotations=>{summary=>'<script>harmless marker</script>'}};
my $batch=sub {return {version=>'4',status=>'firing',alerts=>[dclone($a)]}};
my $normal=$s->Normalize($batch->());is($normal->[0]{Labels}{alertname},'Test','native v4 labels parsed');
is($normal->[0]{Annotations}{summary},$a->{annotations}{summary},'untrusted text remains inert evidence');
is(Kernel::System::TESSERA::Observability::_time('2026-11-11T09:00:00+08:00'),Kernel::System::TESSERA::Observability::_time($a->{startsAt}),'equivalent timezone timestamps normalized');
for my $bad ('2026-02-30T00:00:00Z','2026-11-11T25:00:00Z','x') {ok(!eval {Kernel::System::TESSERA::Observability::_time($bad);1},'invalid timestamp rejected')}
my $bad=$batch->();$bad->{truncatedAlerts}=1;ok(!eval {$s->Normalize($bad);1},'truncated notification rejected');
$bad=$batch->();$bad->{alerts}[0]{labels}{evil}={code=>'x'};ok(!eval {$s->Normalize($bad);1},'structured labels rejected');
$bad=$batch->();$bad->{alerts}=[map {dclone($a)} 1..101];ok(!eval {$s->Normalize($bad);1},'oversized batch rejected');
my $r=$s->Ingest(Client=>$client,Data=>$batch->());is($r->{Changed},1,'first firing recorded');is(scalar @{$db->{activities}},1,'MELT evidence recorded');
$r=$s->Ingest(Client=>$client,Data=>$batch->());is($r->{Duplicates},1,'repeated notification deduplicated');
$a->{endsAt}='2026-11-11T03:00:00Z';$r=$s->Ingest(Client=>$client,Data=>$batch->());is($r->{Changed},0,'moving firing endsAt causes no duplicate activity');
$a->{status}='resolved';$r=$s->Ingest(Client=>$client,Data=>$batch->());is($r->{Changed},1,'resolution recorded');
$a->{status}='firing';$r=$s->Ingest(Client=>$client,Data=>$batch->());is($r->{Changed},0,'late firing cannot reopen resolved cycle');
$a->{startsAt}='2026-11-11T04:00:00Z';$r=$s->Ingest(Client=>$client,Data=>$batch->());is($r->{Changed},1,'new recurrence recorded');
$a->{startsAt}='2026-11-11T01:00:00Z';$a->{status}='resolved';$r=$s->Ingest(Client=>$client,Data=>$batch->());is($r->{Changed},0,'old resolution cannot close later recurrence');
$a->{startsAt}='2026-11-11T05:00:00Z';$a->{status}='firing';$activity_fail=1;my $before=dclone($db->{ledger});ok(!eval {$s->Ingest(Client=>$client,Data=>$batch->());1},'evidence failure fails delivery');is_deeply($db->{ledger},$before,'evidence failure rolls back ledger');$activity_fail=0;
$commit_fail=1;ok(!eval {$s->Ingest(Client=>$client,Data=>$batch->());1},'commit failure fails delivery');is_deeply($db->{ledger},$before,'commit failure rolls back ledger');$commit_fail=0;
$permission=0;ok(!eval {$s->Ingest(Client=>$client,Data=>$batch->());1},'MELT entitlement revocation denies ingestion');$permission=1;
$r=$s->Report(Client=>$client,Data=>{Resource=>'tickets',Limit=>2});is(scalar @{$r->{Rows}},1,'inaccessible candidate excluded before response');is($r->{NextCursor},2,'candidate cursor advances even through denied row');ok(!exists $r->{Rows}[0]{Secret},'ticket projection excludes private fields');
$r=$s->Report(Client=>$client,Data=>{Resource=>'risks'});is($r->{Rows}[0]{Column1},'Resolved catalog name','risk reporting reuses resolved values');ok(!exists $r->{Rows}[0]{RiskRow},'raw risk structures excluded');
for my $query ({Resource=>'tickets',SQL=>'DROP'}, {Resource=>'tickets',Limit=>'1 OR 1=1'}, {Resource=>'tickets',Cursor=>[]}) {ok(!eval {$s->Report(Client=>$client,Data=>$query);1},'malicious report parameters rejected')}
done_testing;
