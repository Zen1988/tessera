use strict;
use warnings;
use Test::More;

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ControlRuntime;

my $Runtime = Kernel::System::TESSERA::ControlRuntime->new();
my $Now = 2_000_000_000;

my $Due = $Runtime->ControlDue( Cycle => '1 year 1 time', LastRun => '', Now => $Now );
ok( $Due->{Due}, 'a Control instance that never ran is due' );

$Due = $Runtime->ControlDue( Cycle => 'hourly', LastRun => $Now - 3599, Now => $Now );
ok( !$Due->{Due}, 'hourly Control waits for its full hour' );
$Due = $Runtime->ControlDue( Cycle => 'hourly', LastRun => $Now - 3600, Now => $Now );
ok( $Due->{Due}, 'hourly Control becomes due after one hour' );
$Due = $Runtime->ControlDue( Cycle => '1 hour', LastRun => $Now - 3600, Now => $Now );
ok( $Due->{Due}, 'numeric hourly Control cycle is supported' );

$Due = $Runtime->ControlDue( Cycle => '1 year 1 time', LastRun => $Now - 31_556_952, Now => $Now );
ok( $Due->{Due}, 'one run per year becomes due after one year' );

$Due = $Runtime->ControlDue( Cycle => '1 year 2 times', LastRun => $Now - 15_000_000, Now => $Now );
ok( !$Due->{Due}, 'two runs per year are not due before half-year interval' );

$Due = $Runtime->ControlDue( Cycle => 'quarterly', LastRun => $Now - 8_000_000, Now => $Now );
ok( $Due->{Due}, 'named quarterly cycle is supported' );

$Due = $Runtime->ControlDue( Cycle => 'whenever convenient', LastRun => '', Now => $Now );
is( $Due->{Status}, 'UNKNOWN', 'unsupported free text fails closed' );

{
    package ControlFieldAdapters;
    sub Get { $_[0] }
    sub DynamicFieldGet { my ( $Self, %P ) = @_; { Name => $P{Name}, ObjectType => 'ITSMConfigItem' } }
    sub ConfigItemGet { my ( $Self, %P ) = @_; { ConfigItemID => $P{ConfigItemID}, VersionID => 4229 } }
    sub ValueSet { my ( $Self, %P ) = @_; $Self->{WrittenObjectID} = $P{ObjectID}; 1 }
}
{
    local $Kernel::OM = bless {}, 'ControlFieldAdapters';
    ok( $Runtime->_ConfigItemFieldSet(
        ConfigItemID => 4147, FieldName => 'ZRM-LastRun', Value => '2026-09-28 14:00:00', UserID => 1,
    ), 'Control run timestamp is written' );
    is( $Kernel::OM->{WrittenObjectID}, 4229, 'Control field write uses the VersionID read by ConfigItemGet' );
}

for my $Path (
    'Kernel/System/TESSERA/ControlRuntime.pm',
    'Kernel/Package/GovernanceDB/Kernel/System/TESSERA/ControlRuntime.pm',
) {
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    my $Source = <$FH>;
    close $FH;
    like( $Source, qr/Objective\}\{'DynamicField_ZRM-FieldAssignment'\}/, "$Path reads risk instructions from ControlObjective" );
    unlike( $Source, qr/Control\}\{'DynamicField_ZRM-FieldAssignment'\}/, "$Path never reads risk instructions from the Control instance" );
    like( $Source, qr/sub ProcessFailedControl/, "$Path exposes the centralized failed-Control handler" );
}

my $Watcher = 'Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/Event/ControlFailureWatcher.pm';
open my $WatcherFH, '<:raw', $Watcher or die "Cannot read $Watcher: $!";
local $/;
my $WatcherSource = <$WatcherFH>;
close $WatcherFH;
like( $WatcherSource, qr/ConfigItemDynamicFieldUpdate.*ZRM-Result/, 'dedicated watcher listens for Control result changes' );
like( $WatcherSource, qr/ProcessFailedControl/, 'dedicated watcher delegates to the centralized handler' );

done_testing;
