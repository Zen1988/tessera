use strict;
use warnings;

use Test::More;

my $Root = $ENV{TESSERA_TEST_ROOT} || '.';

my %Expected = (
    'Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/CustomerEntitlement.pm' => [
        'DynamicField_ZTAM-ContractEntitlement',
        'DynamicField_ZTSMSupportAssignment-UserAccount',
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

my $EntitlementPath = "$Root/Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/CustomerEntitlement.pm";
open my $EntitlementFH, '<:raw', $EntitlementPath or die "Cannot read $EntitlementPath: $!";
local $/;
my $EntitlementContent = <$EntitlementFH>;
close $EntitlementFH;
unlike( $EntitlementContent, qr/DynamicField_ZTAM-SupportProfile/, 'ConfigItem access does not require a direct SupportProfile' );
like( $EntitlementContent, qr/DynamicField_Contract-SupportProfie/, 'ContractEntitlement resolves its exact exported SupportProfile field' );
like( $EntitlementContent, qr/DynamicField_ZTSMSupportAssignment-SupportProfile/, 'access requires the corresponding SupportAssignment SupportProfile' );

my $Bootstrap = "$Root/Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm";
open my $BootstrapFH, '<:raw', $Bootstrap or die "Cannot read $Bootstrap: $!";
local $/;
my $BootstrapContent = <$BootstrapFH>;
close $BootstrapFH;
like( $BootstrapContent, qr/\n\s*ASSET\n/, 'bootstrap idempotently ensures ASSET GovernanceRole' );
like(
    $BootstrapContent,
    qr{my \$TypeID = \$TypeObject->TypeLookup\(.*?next TYPE if \$TypeID;.*?\$TypeObject->TypeAdd\(}s,
    'ticket type bootstrap creates only missing types',
);
unlike(
    $BootstrapContent,
    qr{TypeUpdate\(\s*ID\s*=>\s*\$TypeID.*?ValidID\s*=>\s*1}s,
    'ticket type bootstrap never re-enables an existing disabled type',
);

my $SOPM = "$Root/Kernel/Package/GovernanceDB/TESSERA-Base.sopm";
open my $SOPMFH, '<:raw', $SOPM or die "Cannot read $SOPM: $!";
local $/;
my $SOPMContent = <$SOPMFH>;
close $SOPMFH;
like( $SOPMContent, qr{<Name>TESSERA-Base</Name>}, 'package identity is TESSERA-Base' );
like( $SOPMContent, qr{<Version>0\.0\.27</Version>}, 'TESSERA-Base package version is 0.0.27' );
my $AssetOverviewPath = "$Root/Kernel/Package/GovernanceDB/Kernel/Output/HTML/ITSMConfigItem/ZTSMCustomerOverviewSmall.pm";
open my $AssetOverviewFH, '<:raw', $AssetOverviewPath or die "Cannot read $AssetOverviewPath: $!";
local $/;
my $AssetOverviewContent = <$AssetOverviewFH>;
close $AssetOverviewFH;
like(
    $AssetOverviewContent,
    qr{DYNAMICFIELDNAME:\s*for.*?next\s+DYNAMICFIELDNAME\s+if\s+!IsHashRefWithData\(\$DynamicFieldConfig\)}s,
    'custom asset backend skips unavailable fields through its defined loop label',
);
like( $SOPMContent, qr{<Framework>11\.1\.x</Framework>}, 'package targets OTOBO 11.1.x' );
like( $SOPMContent, qr{ztsm_assets\.svg}, 'asset icon is packaged' );
like( $SOPMContent, qr{CustomerEntitlement\.pm}, 'central entitlement service is packaged' );

my $CustomerListPath = "$Root/Kernel/Modules/CustomerITSMConfigItem.pm";
open my $CustomerListFH, '<:raw', $CustomerListPath or die "Cannot read $CustomerListPath: $!";
local $/;
my $CustomerListContent = <$CustomerListFH>;
close $CustomerListFH;
like( $CustomerListContent, qr{Subaction\}\s+eq\s+'Export'}, 'customer asset export has an explicit read-only subaction' );
like( $CustomerListContent, qr{ConfigItemIDs\s*=>\s*\\\@OriginalViewableConfigItems}, 'asset export uses the filtered entitled ConfigItem set' );
like( $CustomerListContent, qr{FieldType.*?'Set'.*?DynamicFieldGroup.*?JSONObject->Encode}s, 'structured asset fields are exported as JSON cells' );
like( $CustomerListContent, qr{for my \$ColumnName \(qw\(Name ZTSMAssetTag}, 'asset Name and generated columns use the text-filter path' );
like( $CustomerListContent, qr{index\( lc \$Value, lc \$Filters->\{\$Column\} \) < 0}, 'asset text filtering is case-insensitive substring matching' );
like( $BootstrapContent, qr{ZTSM\.Customer\.AssetFilters\.js}, 'bootstrap deploys the customer asset text-filter JavaScript on upgrades' );

my $CustomerServiceFieldsPath = "$Root/Kernel/Package/GovernanceDB/Kernel/Output/HTML/Templates/Standard/ZTSMCustomerTicketMessageServiceFields.tt";
open my $CustomerServiceFieldsFH, '<:raw', $CustomerServiceFieldsPath or die "Cannot read $CustomerServiceFieldsPath: $!";
local $/;
my $CustomerServiceFieldsContent = <$CustomerServiceFieldsFH>;
close $CustomerServiceFieldsFH;
like(
    $CustomerServiceFieldsContent,
    qr{textarea\.RichText.*?min-height:\s*260px\s*!important}s,
    'customer service form retains a usable plain-text fallback height',
);
like(
    $CustomerServiceFieldsContent,
    qr{\.ck-editor__editable\s*\{\s*min-height:\s*0\s*!important;}s,
    '11.1 CKEditor height remains controlled dynamically by its resizable holder',
);
like(
    $CustomerServiceFieldsContent,
    qr{function\s+ZTSMServiceExtensionRichTextReflow.*?requestAnimationFrame.*?triggerHandler\('resize'\)}s,
    'RichText caption insertion requests the native 11.1 holder resize calculation',
);
like(
    $CustomerServiceFieldsContent,
    qr{if\s*\(ZTSMServiceExtensionRichTextTopInsert\(Target,\s*(?:Tooltip|Label)\)\)\s*\{\s*ZTSMServiceExtensionRichTextReflow\(Holder\)}s,
    'RichText reflow runs only when TESSERA changes the CKEditor top chrome',
);

my $CustomerListTemplatePath = "$Root/Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerITSMConfigItem.tt";
open my $CustomerListTemplateFH, '<:raw', $CustomerListTemplatePath or die "Cannot read $CustomerListTemplatePath: $!";
local $/;
my $CustomerListTemplateContent = <$CustomerListTemplateFH>;
close $CustomerListTemplateFH;
like( $CustomerListTemplateContent, qr{Subaction=Export|Data\.ExportLink}, 'customer asset page exposes the export download action' );

my $CustomerDefaultsPath = "$Root/Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Preferences/ZTSMCustomerDefaults.pm";
open my $CustomerDefaultsFH, '<:raw', $CustomerDefaultsPath or die "Cannot read $CustomerDefaultsPath: $!";
local $/;
my $CustomerDefaultsContent = <$CustomerDefaultsFH>;
close $CustomerDefaultsFH;
like( $CustomerDefaultsContent, qr{sub _DynamicFieldObjectIDGet}, 'customer defaults resolve the CustomerUser DynamicField mapping for deletion' );
like( $CustomerDefaultsContent, qr{ValueDelete\(\s*DynamicFieldConfig.*?ObjectID\s*=>\s*\$ObjectID}s, 'customer defaults delete values with the required ObjectID' );
unlike( $CustomerDefaultsContent, qr{ValueDelete\([^)]*ObjectName}s, 'customer defaults never pass unsupported ObjectName to ValueDelete' );
like( $CustomerDefaultsContent, qr{\$Success\s*=\s*!\$ObjectID\s*\?\s*1}s, 'clearing an unmapped empty preference is an idempotent success' );

my $ArticleHelperPath = "$Root/Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMArticleHelper.pm";
open my $ArticleHelperFH, '<:raw', $ArticleHelperPath or die "Cannot read $ArticleHelperPath: $!";
local $/;
my $ArticleHelperContent = <$ArticleHelperFH>;
close $ArticleHelperFH;
like( $ArticleHelperContent, qr{no warnings 'redefine';}, 'article helper tolerates OTOBO persistent-worker package reloads without duplicate-definition warnings' );

done_testing();
