use strict;
use warnings;

use Test::More;

my $Root = $ENV{TESSERA_TEST_ROOT} || '.';

my %Expected = (
    'Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/CustomerEntitlement.pm' => [
        'DynamicField_ZTAM-ContractEntitlement',
        'DynamicField_ZTAM-SupportProfile',
        'DynamicField_Contract-SupportProfie',
        'DynamicField_ZTSMSupportAssignment-UserAccount',
        'DynamicField_ZTSMSupportAssignment-SupportProfile',
        q{RequireRole    => 'ASSET'},
    ],
    'Kernel/Modules/AgentReferenceSearch.pm' => [
        'ConfigItemIDsFilter',
        'RequireAssetRole => 0',
    ],
    'Kernel/Modules/CustomerITSMConfigItem.pm' => [
        'CustomerHasAssetRole',
        'RequireAssetRole => 1',
    ],
    'Kernel/Modules/CustomerITSMConfigItemSearch.pm' => [
        'CustomerHasAssetRole',
        'RequireAssetRole => 1',
    ],
    'Kernel/Modules/CustomerITSMConfigItemZoom.pm' => [
        'ConfigItemDetailAccessCheck',
    ],
    'Kernel/Modules/CustomerITSMConfigItemAttachment.pm' => [
        'ConfigItemDetailAccessCheck',
    ],
    'Kernel/System/ITSMConfigItem/Permission.pm' => [
        'ConfigItemDetailAccessCheck',
        'Legacy group/company/condition grants must not bypass this boundary',
    ],
);

for my $RelativePath ( sort keys %Expected ) {
    my $Path = "$Root/$RelativePath";
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    my $Content = <$FH>;
    close $FH;

    for my $Marker ( @{ $Expected{$RelativePath} } ) {
        like( $Content, qr/\Q$Marker\E/, "$RelativePath contains $Marker" );
    }
}

my $Bootstrap = "$Root/Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm";
open my $BootstrapFH, '<:raw', $Bootstrap or die "Cannot read $Bootstrap: $!";
local $/;
my $BootstrapContent = <$BootstrapFH>;
close $BootstrapFH;
like( $BootstrapContent, qr/\n\s*ASSET\n/, 'bootstrap idempotently ensures ASSET GovernanceRole' );

my $SOPM = "$Root/Kernel/Package/GovernanceDB/GovernanceDB.sopm";
open my $SOPMFH, '<:raw', $SOPM or die "Cannot read $SOPM: $!";
local $/;
my $SOPMContent = <$SOPMFH>;
close $SOPMFH;
like( $SOPMContent, qr{<Version>0\.1\.74</Version>}, 'package version is 0.1.74' );
like( $SOPMContent, qr{<Framework>11\.1\.x</Framework>}, 'package targets OTOBO 11.1.x' );
like( $SOPMContent, qr{ztsm_assets\.svg}, 'asset icon is packaged' );
like( $SOPMContent, qr{CustomerEntitlement\.pm}, 'central entitlement service is packaged' );

done_testing();
