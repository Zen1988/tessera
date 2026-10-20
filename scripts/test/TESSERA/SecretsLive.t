# Execute explicitly in an isolated OTOBO Linux staging environment, as otobo:
# TESSERA_SECRET_LIVE_TEST=1 perl -I. -ICustom -IKernel/cpan-lib scripts/test/TESSERA/SecretsLive.t
# Optional interactive Redis rotation: also set TESSERA_SECRET_ROTATION_TEST=1,
# then rotate server credential AND mounted key after the TAP readiness line.
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(sleep);
use lib '.', 'Custom', 'Kernel/cpan-lib';
BEGIN {
    plan skip_all => 'explicit isolated live-test opt-in required'
        if !$ENV{TESSERA_SECRET_LIVE_TEST};
}
use Kernel::System::ObjectManager;
use Kernel::System::TESSERA::Secrets;
local $Kernel::OM = Kernel::System::ObjectManager->new();
my $Config = $Kernel::OM->Get('Kernel::Config');
my $Module = $Config->Get('Cache::Module');
ok( $Module eq 'Kernel::System::TESSERA::SecretRedis' || $Module eq 'Kernel::System::Cache::Redis', 'supported secret backend configured' );
ok( $Config->Get('Cache::Redis')->{PasswordSecret}, 'PasswordSecret explicitly configured' );
my $DB = $Kernel::OM->Get('Kernel::System::DB');
ok( $DB->Prepare( SQL => 'SELECT 1' ), 'fresh process authenticates to MariaDB' );
my @Row = $DB->FetchrowArray();
is( $Row[0], 1, 'MariaDB query result' );
$DB->FetchrowArray(); # finish result set
my $R = $Kernel::OM->Get($Module);
my $Key = "secret-integration-$$-" . time;
ok( $R->Set( Type => 'TESSERASecretIntegration', Key => $Key, Value => 'nonsecret-fixture', TTL => 300 ), 'Redis authenticated write' );
is( $R->Get( Type => 'TESSERASecretIntegration', Key => $Key ), 'nonsecret-fixture', 'Redis serialization round trip' );
ok( $R->Delete( Type => 'TESSERASecretIntegration', Key => $Key ), 'Redis cleanup' );
SKIP: {
    skip 'interactive server and Kubernetes rotation not requested', 2 if !$ENV{TESSERA_SECRET_ROTATION_TEST};
    my $Initial = Kernel::System::TESSERA::Secrets::Read('redis-password');
    my $Old = $R->{Redis};
    diag 'READY: rotate staging Redis credential and Kubernetes mounted redis-password; waiting up to 180 seconds';
    my $Deadline = time + 180;
    my $Changed;
    while (time < $Deadline) {
        my $Current = eval { Kernel::System::TESSERA::Secrets::Read('redis-password') };
        if ( defined $Current && $Current ne $Initial ) { $Changed = 1; last }
        sleep 1;
    }
    ok( $Changed, 'updated projection observed by same process' );
    eval { $R->Get( Type => 'TESSERASecretIntegration', Key => $Key ) };
    my $New = $R->{Redis};
    ok( $New && $New != $Old && eval { $New->ping() }, 'replacement client authenticates after rotation' );
}
done_testing();
