use strict;
use warnings;
use Test::More;
use Digest::SHA qw(sha256_hex);
# SHA-256 validation below uses the real native backend. Only its unused legacy
# MD5 import is stubbed because that core CPAN dependency is absent on Windows.
BEGIN {package Crypt::PasswdMD5;sub import {};$INC{'Crypt/PasswdMD5.pm'}=1}
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::CustomerAuth::DB;
use Kernel::System::TESSERA::LocalIdentity;
use Kernel::System::Auth::TESSERALocalIdentity;
{
 package NAService;our @ISA=('Kernel::System::TESSERA::LocalIdentity');
 sub _row {return {CustomerRowID=>7,AgentID=>10,Enabled=>1}}
 sub RoutingReady {return 1}
 sub _subject {return {UserLogin=>'customer-person',ValidID=>1}}
 package NAConfig;sub Get {my %m=('Customer::AuthModule::DB::Table'=>'customer_user','Customer::AuthModule::DB::CustomerKey'=>'login','Customer::AuthModule::DB::CustomerPassword'=>'pw');return $m{$_[1]}}
 package NARequest;sub RemoteAddr {return '127.0.0.1'}
 package NAEncode;sub EncodeInput {}sub EncodeOutput {}
 package NALog;sub Log {}
 package NAUser;sub GetUserData {return (UserID=>10,UserLogin=>'agent-person',ValidID=>1)}
 package NADB;
 sub Prepare {my ($s,%p)=@_;$s->{row}=[ $main::hash, 'customer-person' ];return 1}
 sub FetchrowArray {my ($s)=@_;return @{delete($s->{row})||[]}}
 package NAOM;sub Get {my ($s,$n)=@_;return $main::service if $n eq 'Kernel::System::TESSERA::LocalIdentity';my %m=('Kernel::Config'=>'NAConfig','Kernel::System::Web::Request'=>'NARequest','Kernel::System::Encode'=>'NAEncode','Kernel::System::Log'=>'NALog','Kernel::System::User'=>'NAUser','Kernel::System::DB'=>'NADB');return bless {},$m{$n}||die $n}
 package Kernel;our $OM=bless {},'NAOM';
}
our $service=bless {},'NAService';our $hash=sha256_hex('initial-local-test');
my $agent=Kernel::System::Auth::TESSERALocalIdentity->new(Count=>'');my $customer=Kernel::System::CustomerAuth::DB->new(Count=>'');
is($customer->Auth(User=>'customer-person',Pw=>'initial-local-test'),'customer-person','native customer backend accepts master hash');
is($agent->Auth(User=>'agent-person',Pw=>'initial-local-test'),'agent-person','linked agent uses actual native customer hash verifier');
ok(!$agent->Auth(User=>'agent-person',Pw=>'wrong-password'),'native hash verifier rejects wrong agent password');
$hash=sha256_hex('changed-local-test');
ok(!$customer->Auth(User=>'customer-person',Pw=>'initial-local-test'),'old master hash no longer authenticates customer');
ok(!$agent->Auth(User=>'agent-person',Pw=>'initial-local-test'),'old master hash no longer authenticates agent');
is($customer->Auth(User=>'customer-person',Pw=>'changed-local-test'),'customer-person','new master hash authenticates customer');
is($agent->Auth(User=>'agent-person',Pw=>'changed-local-test'),'agent-person','new master hash authenticates agent without copying agent credential');
done_testing;
