use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ProviderIdentity;
use Kernel::GenericInterface::Operation::TESSERA::Common;
{
 package PConfig;sub Get {return 1}
 package PRequest;sub Header {return 'Bearer dummy'}
 package PAdmin;sub Authorized {return $main::admin}
 package PKeys;
 sub KeyAuthenticate {return $main::key_valid ? {KeyID=>11,CustomerUserID=>'subject'} : undef}
 sub KeyCreate {return {KeyID=>12,APIKey=>'test-secret'}}
 sub KeyRevoke {$main::revoked++;return 1}
 package PCustomer;sub CustomerSearch {return (subject=>'Test User',inactive=>'Inactive')}sub CustomerUserDataGet {return (UserLogin=>$_[2],UserFirstname=>'Test',UserLastname=>'User',UserEmail=>'test@example.invalid',ValidID=>$_[2] eq 'inactive'?2:1)}
 package PDB;
 sub Do {my ($s,%p)=@_;push @{$s->{writes}},$p{SQL};return !$main::bind_failure if $p{SQL}=~/INSERT INTO tessera_api_identity_token/;return 1}
 sub Prepare {
  my ($s,%p)=@_;$s->{rows}=[];
  if ($p{SQL}=~/SELECT identity_id/) {$s->{rows}=[[1]] if $main::bound}
  elsif ($p{SQL}=~/SELECT p.id/) {$s->{rows}=[[1,$main::subject,JSON::PP->new->encode($main::settings)]] if $main::identity_enabled}
  elsif ($p{SQL}=~/SELECT id, identity_name/) {$s->{rows}=[[1,'grafana','subject',1,JSON::PP->new->encode($main::settings)]]}
  elsif ($p{SQL}=~/SELECT k.id/) {$s->{rows}=[[11,'old','prefix','expiry','last-used',undef]]}
  elsif ($p{SQL}=~/SELECT id FROM/) {$s->{rows}=[[1]]}
  return 1;
 }
 sub FetchrowArray {my ($s)=@_;return @{shift(@{$s->{rows}})||[]}}
 package POM;sub Get {my ($s,$n)=@_;return $main::db if $n eq 'Kernel::System::DB';return $main::provider if $n eq 'Kernel::System::TESSERA::ProviderIdentity';my %m=('Kernel::Config'=>'PConfig','Kernel::System::Web::Request'=>'PRequest','Kernel::System::TESSERA::IntegrationOnboarding'=>'PAdmin','Kernel::System::TESSERA::APIKey'=>'PKeys','Kernel::System::CustomerUser'=>'PCustomer');return bless {},$m{$n}||die $n}
 package Kernel;our $OM=bless {},'POM';
}
our ($admin,$key_valid,$identity_enabled,$subject,$bind_failure,$revoked)=(1,1,1,'subject',0,0);
our $bound=1;
our $db=bless {rows=>[],writes=>[]},'PDB';
our $settings={Grants=>['report:tickets'],TicketQueueIDs=>[1],MELTObjectIDs=>[]};
our $provider=Kernel::System::TESSERA::ProviderIdentity->new();my $s=$provider;
my $legacy=Kernel::GenericInterface::Operation::TESSERA::Common->new();
ok(!$legacy->APIAuthenticate(),'actual legacy operation rejects scoped provider token');
$bound=0;ok($legacy->APIAuthenticate(),'actual legacy operation retains old key authentication');$bound=1;
ok(!$s->LegacyKeyAllowed(KeyID=>11),'scoped provider key cannot enter unscoped legacy API');
$bound=0;ok($s->LegacyKeyAllowed(KeyID=>99),'existing unbound legacy key remains compatible');$bound=1;
ok($s->Authenticate(Token=>'dummy',Grant=>'report:tickets'),'provider token with current grant accepted');
ok(!$s->Authenticate(Token=>'dummy',Grant=>'ingest:alertmanager'),'read-only token cannot ingest');
$key_valid=0;ok(!$s->Authenticate(Token=>'dummy',Grant=>'report:tickets'),'revoked or expired key denied');$key_valid=1;
$identity_enabled=0;ok(!$s->Authenticate(Token=>'dummy',Grant=>'report:tickets'),'disabled API user denied immediately');$identity_enabled=1;
$subject='other';ok(!$s->Authenticate(Token=>'dummy',Grant=>'report:tickets'),'token cannot change permission subject');$subject='subject';
$settings->{Grants}=['report:risks'];ok(!$s->Authenticate(Token=>'dummy',Grant=>'report:tickets'),'grant removal applies to existing token');$settings->{Grants}=['report:tickets'];
for my $bad ({Grants=>['admin']}, {Grants=>['report:tickets'],TicketQueueIDs=>[]}, {Grants=>['report:alerts'],MELTObjectIDs=>[]}, {Grants=>['ingest:alertmanager'],SourceName=>'a',TargetMELTObjectID=>'1;DROP',ActorID=>1}, {Grants=>['report:risks'],SQL=>'x'}) {
 ok(!eval {$s->_settings($bad);1},'invalid capability or scope rejected');
}
my $new=$s->Issue(UserID=>1,ID=>1,Name=>'grafana-token',Days=>30);is($new->{KeyID},12,'token issued and bound to provider identity');
$bind_failure=1;ok(!eval {$s->Issue(UserID=>1,ID=>1,Name=>'bad-binding',Days=>30);1},'binding failure rejects token');is($revoked,1,'orphaned token immediately revoked');$bind_failure=0;
for my $days (0,366,'1; DROP') {ok(!eval {$s->Issue(UserID=>1,ID=>1,Name=>'invalid-expiry',Days=>$days);1},'unbounded expiry denied')}
ok(!eval {$s->Revoke(UserID=>1,ID=>1,KeyID=>99);1},'cross-identity token revocation denied');
ok($s->Revoke(UserID=>1,ID=>1,KeyID=>11),'owned token revoked');
$admin=0;
for my $method (qw(List Get Tokens Issue Revoke Save)) {ok(!eval {$s->$method(UserID=>2,ID=>1);1},"nonadministrator cannot $method")}
$admin=1;
ok($s->StorageEnsure(),'provider tables initialize');ok($s->StorageEnsure(),'repeated initialization supported');
my $ddl=join '\n',@{$db->{writes}};
unlike($ddl,qr/DROP TABLE|DELETE FROM/,'setup preserves existing identities and token data');
$admin=1;
my $matches=$s->SubjectSearch(UserID=>1,Term=>'su');
is(scalar @$matches,1,'inactive account excluded from selector');
is($matches->[0]{Value},'subject','selector submits exact login');
like($matches->[0]{Label},qr/Test User.*test\@example.invalid.*subject/,'suggestion identifies name email and login');
is_deeply($s->SubjectSearch(UserID=>1,Term=>'s'),[],'short queries do not enumerate users');
$admin=0;ok(!eval {$s->SubjectSearch(UserID=>2,Term=>'su');1},'nonadmin cannot enumerate subjects');
done_testing;
