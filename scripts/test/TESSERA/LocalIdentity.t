use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::LocalIdentity;
use Kernel::System::Auth::TESSERALocalIdentity;
BEGIN {$INC{'Kernel/System/CustomerAuth/DB.pm'}=1;$INC{'Kernel/System/Auth/DB.pm'}=1}
{
 package Kernel::System::CustomerAuth::DB;sub new {bless {},$_[0]}sub Auth {my ($s,%p)=@_;return $p{Pw} eq $main::db->{masterPW}?$p{User}:undef}
 package Kernel::System::Auth::DB;sub new {bless {},$_[0]}sub Auth {$main::fallback++;return 'legacy-agent'}
 package LConfig;sub Get {return $main::config{$_[1]}}
 package LAdmin;sub _admin {die 'not admin' if !$main::admin}
 package LDirectory;sub ExternalUser {return $main::external}
 package LCache;sub CleanUp {return 1}
 package LCustomer;
 sub CustomerUserDataGet {return (UserLogin=>'person',UserFirstname=>'Person',UserLastname=>'Test',UserEmail=>'person@example.invalid',ValidID=>$main::valid,Source=>'CustomerUser')}
 package LUsers;
 sub TESSERALocalPasswordRouting {return 1}
 sub UserLookup {my ($s,%p)=@_;return 'person' if $p{UserID};return $main::db->{agent}?$main::db->{agent}{UserID}:undef}
 sub UserAdd {my ($s,%p)=@_;$main::db->{agent}={%p,UserID=>10};return 10}
 sub GetUserData {return %{$main::db->{agent}||{}}}
 sub GenerateRandomPassword {return 'not-the-customer-password'}
 sub SetPassword {my ($s,%p)=@_;$main::db->{agentPW}=$p{PW};return 1}
 sub UserUpdate {my ($s,%p)=@_;die 'sync failed' if $main::syncfail;$main::db->{agent}={%{$main::db->{agent}},%p};return 1}
 package LGroup;
 sub GroupList {return (2=>'agents',3=>'external-group')}
 sub RoleList {return (4=>'operators')}
 sub PermissionGroupUserAdd {my ($s,%p)=@_;$main::db->{groups}{$p{GID}}=$p{Permission};return 1}
 sub PermissionRoleUserAdd {my ($s,%p)=@_;$main::db->{roles}{$p{RID}}=$p{Active};return 1}
 package LHandle;sub commit {return !$main::commitfail}
 package LDB;
 sub Prepare {
  my ($s,%p)=@_;my $q=$p{SQL};my @b=map {$$_} @{$p{Bind}||[]};$s->{rows}=[];
  if ($q=~/SELECT ENGINE/) {$s->{rows}=[['InnoDB']]}
  elsif ($q=~/GET_LOCK|RELEASE_LOCK/) {$s->{rows}=[[1]]}
  elsif ($q=~/SELECT id, login FROM customer_user/) {$s->{rows}=[[7,'person']]}
  elsif ($q=~/SELECT id FROM customer_user/) {$s->{rows}=[[7]]}
  elsif ($q=~/FROM tessera_local_identity/) {my $l=$s->{link};$s->{rows}=[[$l->{customer},$l->{agent},$l->{enabled},$l->{json}]] if $l}
  return 1;
 }
 sub FetchrowArray {my ($s)=@_;return @{shift @{$s->{rows}}||[]}}
 sub BeginWork {my ($s)=@_;$s->{before}=Storable::dclone({map {$_=>$s->{$_}} qw(agent link groups roles audit agentPW)});return 1}
 sub Rollback {my ($s)=@_;for (keys %{$s->{before}}){$s->{$_}=$s->{before}{$_}}return 1}
 sub Do {
  my ($s,%p)=@_;my @b=map {$$_} @{$p{Bind}||[]};
  if ($p{SQL}=~/INSERT INTO tessera_local_identity \(/) {$s->{link}={customer=>$b[0],agent=>$b[1],enabled=>$b[2],json=>$b[3]}}
  elsif ($p{SQL}=~/UPDATE tessera_local_identity SET/) {@{$s->{link}}{qw(enabled json)}=@b[0,1]}
  elsif ($p{SQL}=~/INSERT INTO tessera_local_identity_audit/) {push @{$s->{audit}},$b[2]}
  return 1;
 }
 package LOM;sub Get {my ($s,$n)=@_;return $main::db if $n eq 'Kernel::System::DB';return $main::service if $n eq 'Kernel::System::TESSERA::LocalIdentity';my %m=('Kernel::Config'=>'LConfig','Kernel::System::TESSERA::ProviderIdentity'=>'LAdmin','Kernel::System::TESSERA::DirectorySync'=>'LDirectory','Kernel::System::Cache'=>'LCache','Kernel::System::CustomerUser'=>'LCustomer','Kernel::System::User'=>'LUsers','Kernel::System::Group'=>'LGroup');return bless {},$m{$n}||die $n}
 package Kernel;our $OM=bless {},'LOM';
}
our ($admin,$external,$valid,$syncfail,$commitfail,$fallback)=(1,0,1,0,0,0);
our %config=('TESSERA::LocalIdentity::Enabled'=>1,AuthModule=>'Kernel::System::Auth::TESSERALocalIdentity','AuthModule::UseSyncBackend'=>'',
 CustomerUser=>{Module=>'Kernel::System::CustomerUser::DB',Params=>{Table=>'customer_user'}},'Customer::AuthModule'=>'Kernel::System::CustomerAuth::DB',
 'Customer::AuthModule::DB::Table'=>'customer_user','Customer::AuthModule::DB::CustomerKey'=>'login','Customer::AuthModule::DB::CustomerPassword'=>'pw');
our $db=bless {rows=>[],masterPW=>'first-password',groups=>{3=>{ro=>1}},roles=>{},audit=>[],dbh=>bless({},'LHandle')},'LDB';
our $service=Kernel::System::TESSERA::LocalIdentity->new();my $s=$service;
ok($s->RoutingReady(),'sole router and native password hook ready');
$config{AuthModule1}='Kernel::System::Auth::DB';ok(!$s->RoutingReady(),'additional DB fallback prevents linking');delete $config{AuthModule1};
my %p=(UserID=>99,CustomerUserID=>'person',Enabled=>1,Groups=>[2],Roles=>[4]);
$admin=0;ok(!eval {$s->Configure(%p);1},'nonadmin cannot create agent link');$admin=1;
$external=1;ok(!eval {$s->Configure(%p);1},'external identity cannot receive local shadow auth');$external=0;
$valid=2;ok(!eval {$s->Configure(%p);1},'invalid customer cannot receive agent access');$valid=1;
ok(!eval {$s->Configure(%p,Groups=>[],Roles=>[]);1},'agent access requires explicit grants');
is($s->Configure(%p),10,'secondary agent created from primary customer');
is($db->{agent}{UserFirstname},'Person','profile copied from main record');
is($db->{agentPW},'not-the-customer-password','no customer password copied to agent record');
is_deeply($db->{groups}{3},{ro=>1},'unmanaged agent group preserved');
my $a=Kernel::System::Auth::TESSERALocalIdentity->new(Count=>'');
is($a->Auth(User=>'person',Pw=>'first-password'),'person','agent authenticates with customer password');
ok(!$a->Auth(User=>'person',Pw=>'wrong'),'linked wrong password denied');is($fallback,0,'failed linked auth never falls back to old agent password');
$db->{masterPW}='second-password';ok(!$a->Auth(User=>'person',Pw=>'first-password'),'old customer password immediately stops working for agent');
is($a->Auth(User=>'person',Pw=>'second-password'),'person','new customer password works without agent password synchronization');
is($s->AgentPasswordTarget(AgentLogin=>'person')->{CustomerUserID},'person','agent password writer resolves master customer');
$s->Configure(%p,Enabled=>0);ok(!$a->Auth(User=>'person',Pw=>'second-password'),'disabled agent access denies auth');
is($db->{agent}{ValidID},2,'disabled secondary agent marked invalid');is($db->{masterPW},'second-password','disabling agent leaves master credential intact');
$s->Configure(%p);$valid=2;ok(!$a->Auth(User=>'person',Pw=>'second-password'),'customer invalidation denies agent auth');$s->SyncCustomer(CustomerUserID=>'person',UserID=>99);is($db->{agent}{ValidID},2,'customer validity synchronizes to secondary record');$valid=1;
$s->SyncCustomer(CustomerUserID=>'person',UserID=>99);is($db->{agent}{ValidID},2,'profile synchronization does not undo agent revocation');
$s->Configure(%p);is($db->{agent}{ValidID},1,'explicit administrator action can re-enable agent');
$syncfail=1;my $before=Storable::dclone($db->{link});ok(!eval {$s->Configure(%p,Enabled=>0);1},'profile failure rejects whole operation');is_deeply($db->{link},$before,'profile failure rolls back link change');$syncfail=0;
$commitfail=1;ok(!eval {$s->Configure(%p,Enabled=>0);1},'commit failure rejected');is_deeply($db->{link},$before,'commit failure rolls back');$commitfail=0;
$db->{link}=undef;$db->{agent}{UserID}=11;ok(!eval {$s->Configure(%p);1},'matching login cannot silently adopt existing agent');
ok(!eval {$s->Configure(%p,ConfirmExisting=>1,ExistingAgentID=>12);1},'wrong existing-agent confirmation denied');
is($s->Configure(%p,ConfirmExisting=>1,ExistingAgentID=>11),11,'explicit existing-agent linking accepted');
$db->{link}=undef;$db->{agent}{UserID}=1;ok(!eval {$s->Configure(%p,ConfirmExisting=>1,ExistingAgentID=>1);1},'root cannot be linked');
$db->{agent}=undef;is($a->Auth(User=>'unlinked',Pw=>'legacy'),'legacy-agent','unlinked native agent authentication retained');
ok($s->StorageEnsure(),'linked identity tables initialize');ok($s->StorageEnsure(),'repeat setup is additive');
done_testing;
