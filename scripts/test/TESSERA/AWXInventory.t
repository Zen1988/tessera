use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use lib '.';
use Kernel::System::TESSERA::AWXInventory;
{ package InventoryRequester;
 sub Run {
  my($S,%P)=@_;push @{$S->{Calls}},\%P;return {Success=>0} if $S->{Fail} && $P{Invoker} eq $S->{Fail};
  return {Success=>1,Data=>{Response=>{count=>scalar @{$S->{Hosts}},next=>undef,results=>Storable::dclone($S->{Hosts})}}} if $P{Invoker} eq 'InventoryHosts';
  my $D=$P{Data};my $Host={id=>$D->{HostID} || 100+@{$S->{Hosts}},inventory=>$D->{InventoryID},name=>$D->{name},enabled=>1,variables=>JSON::PP->new->canonical->encode($D->{variables})};
  if ($D->{HostID}) {@{$S->{Hosts}}=grep {$_->{id}!=$D->{HostID}} @{$S->{Hosts}}}
  push @{$S->{Hosts}},$Host;return {Success=>1,Data=>{Response=>$Host}};
 }
}
my $Q=bless {Hosts=>[{id=>10,inventory=>7,name=>'manual',enabled=>1,variables=>'{}'}]},'InventoryRequester';
my $S=Kernel::System::TESSERA::AWXInventory->new(Requester=>$Q);
my %Input=(WebserviceID=>14,InventoryID=>7,Hosts=>[{ConfigItemID=>9,Address=>'server.example',Variables=>{environment=>'test'}}]);
my $R=$S->Sync(%Input);ok($R->{Success} && $R->{LaunchAllowed},'inventory sync succeeds');is($R->{Changed},1,'creates missing CI host');is($R->{Limit},'tessera-ci-9','execution limited to snapshot');
is(scalar @{$Q->{Hosts}},2,'manual host retained');
$R=$S->Sync(%Input);ok($R->{Success},'repeat sync succeeds');is($R->{Changed},0,'repeat creates no duplicate or update');
$Input{Hosts}[0]{Address}='new.example';$R=$S->Sync(%Input);is($R->{Changed},1,'changed source updates existing host');is(scalar @{$Q->{Hosts}},2,'update does not duplicate');
my $Vars=JSON::PP->new->decode($Q->{Hosts}[1]{variables});is($Vars->{ansible_host},'new.example','CMDB-mapped address updated');
$Q->{Fail}='InventoryHostUpdate';$Input{Hosts}[0]{Address}='again.example';$R=$S->Sync(%Input);ok(!$R->{Success} && !$R->{LaunchAllowed},'write failure blocks launch');
delete $Q->{Fail};$Q->{Hosts}[1]{variables}='{}';$R=$S->Sync(%Input);ok(!$R->{Success},'unowned stable-name collision refused');
my $Count=@{$Q->{Calls}};
for my $Bad ([{ConfigItemID=>9,Address=>'x',Variables=>{ansible_connection=>'local'}}], [{ConfigItemID=>9,Address=>'x',Variables=>{password=>'secret'}}], [{ConfigItemID=>9,Address=>'x'},{ConfigItemID=>9,Address=>'y'}],[]) {
 ok(!$S->Sync(%Input,Hosts=>$Bad)->{Success},'unsafe or ambiguous snapshot refused before writes');
}
is(scalar @{$Q->{Calls}},$Count,'invalid snapshots do not call AWX');
done_testing();
