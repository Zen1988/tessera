use strict;
use warnings;
use Test::More;
{
 package HConfig;sub Get {return $main::enabled if $_[1] eq 'TESSERA::LocalIdentity::Enabled';return 'plain' if $_[1] eq 'AuthModule::DB::CryptType';return}
 package HLink;sub AgentPasswordTarget {die 'routing error' if $main::resolvefail;return $main::linked?{Linked=>1,CustomerUserID=>'master'}:{Linked=>0}}
 package HCustomer;sub SetPassword {my ($s,%p)=@_;$main::masterPW=$p{PW};return !$main::writefail}
 package HDB;sub Do {$main::nativewrites++;return 1}
 package HLog;sub Log {}
 package HEncode;sub EncodeOutput {}
 package HUser;sub UserLookup {return 'agent'}sub GetUserData {return (UserLogin=>'agent')}
 package HOM;sub Get {my ($s,$n)=@_;my %m=('Kernel::Config'=>'HConfig','Kernel::System::TESSERA::LocalIdentity'=>'HLink','Kernel::System::CustomerUser'=>'HCustomer','Kernel::System::DB'=>'HDB','Kernel::System::Log'=>'HLog','Kernel::System::Encode'=>'HEncode');return bless {},$m{$n}||die $n}
 package Kernel;our $OM=bless {},'HOM';
}
open my $f,'<','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/User.pm' or die $!;my $source=do{local $/;<$f>};close $f;
my ($set)=$source=~/(sub SetPassword \{.*?)(?=\n=head2 UserLookup)/s;die 'native SetPassword not found' if !$set;
my ($update)=$source=~/(sub UserUpdate \{.*?)(?=\n    # check needed stuff)/s;die 'native UserUpdate guard not found' if !$update;
{package HUser;eval $set;die $@ if $@;eval $update.'return {RemainingPassword=>$Param{UserPw}};}';die $@ if $@;}
our ($enabled,$linked,$resolvefail,$writefail,$nativewrites,$masterPW)=(1,1,0,0,0,'old');
my $u=bless {UserTable=>'users',UserTableUserPW=>'pw',UserTableUser=>'login',Lower=>'LOWER'},'HUser';
ok($u->SetPassword(UserLogin=>'agent',PW=>'shared-new'),'native agent password path succeeds');is($masterPW,'shared-new','native agent password change writes customer master');is($nativewrites,0,'linked password never stored in users.pw');
$resolvefail=1;ok(!$u->SetPassword(UserLogin=>'agent',PW=>'bad'),'routing failure rejects password write');is($nativewrites,0,'routing failure cannot fall through to independent agent password');$resolvefail=0;
my $r=$u->UserUpdate(UserID=>10,UserPw=>'admin-reset');is($masterPW,'admin-reset','native administrator agent reset reaches customer master');ok(!defined $r->{RemainingPassword},'admin update removes independent password mutation');
$writefail=1;ok(!$u->UserUpdate(UserID=>10,UserPw=>'failed'),'failed customer reset aborts native admin update');$writefail=0;
$linked=0;ok($u->SetPassword(UserLogin=>'agent',PW=>'legacy'),'unlinked agent uses original native writer');is($nativewrites,1,'unlinked native password behavior preserved');
$enabled=0;$linked=1;ok($u->SetPassword(UserLogin=>'agent',PW=>'feature-off'),'default-disabled installation preserves native password path');is($nativewrites,2,'opt-in guard leaves legacy behavior unchanged by default');
done_testing;
