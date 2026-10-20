use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'Custom', '.';
use Kernel::System::Cache::Redis;

our ( $Config, $Connections, $Writes, $Fail, $Stored, @Logs, @Select, @SetArgs );
$Config = { Server => 'fixture:6379', DatabaseNumber => 3, PasswordSecret => 'redis-password' };
my $Root = tempdir(CLEANUP=>1);
sub project {
    open my $FH, '>:raw', "$Root/redis-password" or die 'fixture open';
    print {$FH} $_[0];
    close $FH or die 'fixture close';
}
{
    package OverrideOM;
    sub Get { bless {}, $_[1] }
    package Kernel::Config;
    sub Get { $main::Config }
    package Kernel::System::Main;
    sub Require { 1 }
    package Kernel::System::Log;
    sub Log { my($S,%P)=@_; push @main::Logs,$P{Message}; 1 }
    package Kernel::System::Storable;
    sub Serialize { my($S,%P)=@_; 'fixture:'.$P{Data}{_Data} }
    sub Deserialize { my($S,%P)=@_; $P{Data}=~s/^fixture://; {_Data=>$P{Data}} }
    package Redis;
    sub new { my($T,%P)=@_; $main::Connections++; bless \%P,$T }
    sub ping { die 'AUTH fixture-password private' if $main::Fail; 1 }
    sub select { push @main::Select,$_[1]; 1 }
    sub sadd { 1 }
    sub set { $main::Writes++; @main::SetArgs=@_[1..$#_]; $main::Stored=$_[2]; die 'AUTH fixture-password private' if $main::Fail; 1 }
    sub get { $main::Stored }
    sub del { $main::Writes++; 1 }
    sub flushdb { 1 }
    sub smembers { () }
    package Redis::Fast;
    our @ISA=('Redis');
}
{
    no warnings 'redefine';
    local *Kernel::System::TESSERA::Secrets::Read = sub { Kernel::System::TESSERA::Secrets::_ReadAt($Root,$_[0]) };
    local $Kernel::OM = bless {}, 'OverrideOM';
    like( $INC{'Kernel/System/Cache/Redis.pm'}, qr{Custom[/\\]Kernel[/\\]System[/\\]Cache[/\\]Redis.pm}, 'Custom wins module resolution' );
    project('fixture-password');
    my $R=Kernel::System::Cache::Redis->new();
    ok($R->Set(Type=>'Test',Key=>'key',Value=>'payload',TTL=>60),'recovered native Set authenticates');
    is($R->{Redis}{password},'fixture-password','file-backed password reaches client');
    is($R->{Redis}{server},'fixture:6379','server preserved');
    is_deeply(\@Select,[3],'database selection preserved');
    is_deeply(\@SetArgs,['Test:key','fixture:payload','EX',60],'key serialization and expiry preserved');
    is($R->Get(Type=>'Test',Key=>'key'),'payload','native Get round trip');
    is($Connections,1,'unchanged password keeps connection');
    project("fixture-rotated\n");
    ok($R->Delete(Type=>'Test',Key=>'key'),'operation after projection rotation');
    is($Connections,2,'rotation rebuilds native backend connection');
    is($R->{Redis}{password},"fixture-rotated\n",'reader exact-byte contract preserved');
    my $Before=$Writes;
    $Fail=1;
    ok(!$R->Set(Type=>'Test',Key=>'key',Value=>'payload',TTL=>60),'ambiguous write returns native failure');
    is($Writes,$Before+1,'no write retry');
    ok(!$R->{Redis} && !exists $R->{Password},'failed authenticated client discarded');
    unlike(join('',@Logs),qr/AUTH|fixture-password|fixture-rotated|private/,'logs contain no credentials or driver exception');
    ok(!$R->Get(Type=>'Test',Key=>'key'),'authentication failure returns native failure');
    $Fail=0;
    ok($R->Delete(Type=>'Test',Key=>'key'),'subsequent call recovers');
    unlink "$Root/redis-password";
    $Before=$Writes;
    ok(!$R->Delete(Type=>'Test',Key=>'key'),'missing key fails closed');
    is($Writes,$Before,'old client not used without mounted key');
    like($Logs[-1],qr/TESSERA Redis: secret, authentication or cache operation failed/,'meaningful sanitized failure');
    project('fixture-fast');
    $Config->{RedisFast}=1;
    my $Fast=Kernel::System::Cache::Redis->new();
    ok($Fast->Delete(Type=>'Test',Key=>'key'),'Fast path authenticates too');
    isa_ok($Fast->{Redis},'Redis::Fast');
    is($Fast->{Redis}{password},'fixture-fast','Fast receives mounted credential');
    $Config={Server=>'fixture:6379',DatabaseNumber=>0};
    unlink "$Root/redis-password";
    my $Plain=Kernel::System::Cache::Redis->new();
    ok($Plain->Delete(Type=>'Test',Key=>'key'),'no PasswordSecret retains native unauthenticated mode');
    ok(!exists $Plain->{Redis}{password},'no password injected in legacy mode');
    ok($Plain->Delete(Type=>'Test',Key=>'key'),'existing unauthenticated connection reusable');
    $Config->{PasswordSecret}='';
    my $Empty=Kernel::System::Cache::Redis->new();
    ok(!$Empty->Delete(Type=>'Test',Key=>'key'),'explicit empty secret name cannot bypass authentication');
    $Config->{PasswordSecret}='../escape';
    my $Bad=Kernel::System::Cache::Redis->new();
    ok(!$Bad->Delete(Type=>'Test',Key=>'key'),'malformed secret name fails closed');
    unlike(join('',@Logs),qr{\.\./escape|AUTH|fixture-password},'malformed input not echoed');
}
done_testing();
