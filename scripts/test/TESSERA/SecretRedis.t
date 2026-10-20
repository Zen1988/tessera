use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use lib 'Custom';
use Kernel::System::TESSERA::SecretRedis;

our ( $Password, $Fail, $Connections, $Writes, $RequireFail, $Stored, $Selected, @Patterns );
$Password = 'fixture-one';
my $Root = tempdir(CLEANUP=>1);
sub project {
    open my $FH, '>:raw', "$Root/redis-password" or die 'fixture write';
    print {$FH} $Password;
    close $FH or die 'fixture close';
}
project();
{
    package FixtureOM;
    sub Get { bless {}, $_[1] }
    package Kernel::Config;
    sub Get { { PasswordSecret => 'redis-password', Server => 'fixture:6379' } }
    package Kernel::System::Main;
    sub Require { !$main::RequireFail }
    package Redis;
    sub new { my ($T,%P)=@_; $main::Connections++; bless \%P,$T }
    sub ping { die "AUTH $main::Password private" if $main::Fail; 1 }
    sub select { $main::Selected=$_[1]; 1 }
    sub del { $main::Writes++; die "AUTH $main::Password private" if $main::Fail; 1 }
    sub sadd { 1 }
    sub set { $main::Writes++; $main::Stored=$_[2]; 1 }
    sub get { $main::Stored }
    sub flushdb { 1 }
    sub smembers { ('keep','remove') }
    sub scan { push @main::Patterns,$_[3]; (0,['fixture-key']) }
    package Kernel::System::Storable;
    sub Serialize { my($S,%P)=@_; 'serialized:'.$P{Data}{_Data} }
    sub Deserialize { my($S,%P)=@_; $P{Data}=~s/^serialized://; {_Data=>$P{Data}} }
}
{
    no warnings 'redefine';
    local *Kernel::System::TESSERA::Secrets::Read = sub { Kernel::System::TESSERA::Secrets::_ReadAt($Root,$_[0]) };
    local $Kernel::OM = bless {}, 'FixtureOM';
    my $R = Kernel::System::TESSERA::SecretRedis->new();
    ok( $R->Delete(Type=>'T', Key=>'K'), 'backend authenticates and executes' );
    is( $Connections, 1, 'first connection' );
    $R->Delete(Type=>'T', Key=>'K');
    is( $Connections, 1, 'unchanged credential retains connection' );
    $Password = 'fixture-two';
    project();
    $R->Delete(Type=>'T', Key=>'K');
    is( $Connections, 2, 'rotation replaces connection before next operation' );
    is( $R->{Redis}{password}, 'fixture-two', 'new client receives current password' );
    is( $Selected, 0, 'database selected after authentication' );
    ok( $R->Set(Type=>'T',Key=>'K',Value=>'payload',TTL=>30), 'cache set with serialization' );
    is( $R->Get(Type=>'T',Key=>'K'), 'payload', 'cache get with deserialization' );
    ok( $R->CleanUp(Expired=>1), 'native expiry cleanup no-op' );
    ok( $R->CleanUp(), 'namespace flush' );
    ok( $R->CleanUp(KeepTypes=>['keep']), 'cleanup preserves kept namespaces' );
    is_deeply( \@Patterns, ['remove:*'], 'only non-kept namespace scanned' );
    @Patterns=();
    ok( $R->CleanUp(Type=>'literal*'), 'exact type cleanup' );
    is_deeply( \@Patterns, ['literal\\*:*'], 'glob in namespace escaped' );
    $Fail = 1;
    my $Before = $Writes;
    eval { $R->Delete(Type=>'T', Key=>'K') };
    is( $@, "TESSERA Redis: secret or cache operation failed\n", 'operation exception sanitized' );
    is( $Writes, $Before+1, 'ambiguous write not retried' );
    ok( !$R->{Redis} && !exists $R->{Password}, 'failed client discarded' );
    eval { $R->Delete(Type=>'T', Key=>'K') };
    unlike( $@, qr/fixture-two|AUTH|private/, 'authentication failure sanitized' );
    $Fail = 0;
    ok( $R->Delete(Type=>'T', Key=>'K'), 'recovers on subsequent operation' );
    undef $Password;
    unlink "$Root/redis-password";
    $Before = $Writes;
    eval { $R->Delete(Type=>'T', Key=>'K') };
    like( $@, qr/secret or cache operation failed/, 'missing mounted key fails closed' );
    is( $Writes, $Before, 'old client not used when secret missing' );
    ok( !$R->{Redis}, 'old client removed on missing secret' );
    $Password = 'fixture-three';
    project();
    $RequireFail = 1;
    eval { $R->Delete(Type=>'T', Key=>'K') };
    like( $@, qr/secret or cache operation failed/, 'missing dependency fails closed' );
}
done_testing();
