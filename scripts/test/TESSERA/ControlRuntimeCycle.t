use strict;
use warnings;
use Test::More;

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ControlRuntime;

my $Runtime = Kernel::System::TESSERA::ControlRuntime->new();
my $Now = 2_000_000_000;

my $Due = $Runtime->ControlDue( Cycle => '1 year 1 time', LastRun => '', Now => $Now );
ok( $Due->{Due}, 'a Control instance that never ran is due' );

$Due = $Runtime->ControlDue( Cycle => '1 year 1 time', LastRun => $Now - 31_556_952, Now => $Now );
ok( $Due->{Due}, 'one run per year becomes due after one year' );

$Due = $Runtime->ControlDue( Cycle => '1 year 2 times', LastRun => $Now - 15_000_000, Now => $Now );
ok( !$Due->{Due}, 'two runs per year are not due before half-year interval' );

$Due = $Runtime->ControlDue( Cycle => 'quarterly', LastRun => $Now - 8_000_000, Now => $Now );
ok( $Due->{Due}, 'named quarterly cycle is supported' );

$Due = $Runtime->ControlDue( Cycle => 'whenever convenient', LastRun => '', Now => $Now );
is( $Due->{Status}, 'UNKNOWN', 'unsupported free text fails closed' );

done_testing;
