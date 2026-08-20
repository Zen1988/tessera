use strict;
use warnings;
use Test::More;

sub content {
    my ($Path) = @_;
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    return <$FH>;
}

my $Bootstrap = content('Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm');
like( $Bootstrap, qr/CREATE TABLE ztsm_api_key/, 'API key store is installed idempotently' );
like( $Bootstrap, qr{Custom/var/governancedb/faq/tessera_external_api\.md}, 'managed FAQ resolves the Custom package deployment path' );
like( $Bootstrap, qr/WHERE f_name = \?.*?tessera-external-api-reference/s, 'managed FAQ uses its stable internal name for idempotency' );
like( $Bootstrap, qr/GroupLookup\( Group => 'faq' \).*?SetCategoryGroup/s, 'managed FAQ category is visible to the FAQ permission group' );
like( $Bootstrap, qr/TESSERA managed FAQ article could not be created/, 'managed FAQ failures are logged instead of silently ignored' );
like( $Bootstrap, qr/CREATE TABLE ztsm_external_change/, 'generic external staging store is installed' );
like( $Bootstrap, qr/CREATE TABLE ztsm_external_change_history/, 'staging lifecycle history is immutable and separate' );
like( $Bootstrap, qr/tessera-cmdb-api.*tessera-melt-api.*tessera-governance-api/s, 'object capability groups are bootstrapped' );
like( $Bootstrap, qr/CMDBAPI.*MELTAPI.*GovernanceAPI/s, 'API GovernanceRole objects are bootstrapped' );
like( $Bootstrap, qr/IntegrationRequest/, 'review ticket type is create-only bootstrapped' );

my $Key = content('Kernel/Package/GovernanceDB/Kernel/System/TESSERA/APIKey.pm');
like( $Key, qr/GenerateRandomString\( Length => 64 \)/, 'API keys use a high-entropy secret' );
like( $Key, qr/sha256_hex\(\$Token\)/, 'only a one-way API key hash is persisted' );
like( $Key, qr/sub KeyRenew.*?OverlapSeconds.*?replaced_by/s, 'key renewal supports controlled overlap and replacement lineage' );
like( $Key, qr/sub KeyRevoke.*?revoke_time/s, 'keys can be revoked immediately' );
like( $Key, qr/INSERT INTO ztsm_api_key.*?key_hash/s, 'the API key store persists the hash column' );
unlike( $Key, qr/key_secret|plaintext_key/i, 'plaintext API keys have no persistence field' );

my $Permission = content('Kernel/Package/GovernanceDB/Kernel/System/TESSERA/APIPermission.pm');
like( $Permission, qr/MELT-AccessPermission/, 'MELT Risk uses its exported ContractEntitlement access field' );
like( $Permission, qr/grep \{ \$_ eq 'tessera-api' \} \@Groups/, 'base API customer group is required' );
like( $Permission, qr/grep \{ \$_ eq \$Rule->\{Group\} \} \@Groups/, 'object capability customer group is also required' );
like( $Permission, qr/SubmittedEntitlementsCheck.*?for my \$ID/s, 'every submitted entitlement must be authorized' );

my $Stage = content('Kernel/Package/GovernanceDB/Kernel/System/TESSERA/ExternalChange.pm');
like( $Stage, qr/Only Create and Update are supported/, 'external delete is rejected' );
like( $Stage, qr/IdempotencyKey.*?StageGetByIdempotency/s, 'staging submission is idempotent' );
like( $Stage, qr/_TicketArticleAdd/, 'staging lifecycle records ticket articles' );
like( $Stage, qr/RevertRequested.*?Reverted.*?RevertFailed/s, 'revert is a compensating lifecycle' );

my $Common = content('Kernel/Package/GovernanceDB/Kernel/GenericInterface/Operation/TESSERA/Common.pm');
like( $Common, qr/TESSERA::API::Enabled/, 'API fails closed while disabled' );
like( $Common, qr/Authorization.*?Bearer/s, 'API authenticates through the Bearer header' );

my $FAQ = content('Kernel/Package/GovernanceDB/var/governancedb/faq/tessera_external_api.md');
my $FAQInstaller = content('Kernel/Package/GovernanceDB/Kernel/System/TESSERA/FAQInstaller.pm');
like( $FAQInstaller, qr/CategoryAdd\(/, 'managed FAQ uses the built-in category workflow' );
like( $FAQInstaller, qr/FAQAdd\(/, 'managed FAQ uses the built-in article creation workflow' );
like( $FAQInstaller, qr/FAQUpdate\(/, 'managed FAQ uses the built-in article update workflow' );
unlike( $FAQInstaller, qr/SQL\s*=>\s*['"]\s*(?:INSERT\s+INTO|UPDATE)\s+faq_item/i, 'managed FAQ never writes article content directly to the database' );
like( $FAQInstaller, qr/return \$Self->_Fail/, 'managed FAQ installer reports a failing result' );
my $SOPM = content('Kernel/Package/GovernanceDB/TESSERA-Base.sopm');
like( $SOPM, qr/Kernel::System::TESSERA::FAQInstaller.*?die 'TESSERA managed FAQ installation failed.'/s, 'package setup fails visibly when the built-in FAQ workflow fails' );
like( $SOPM, qr/<CodeInstall.*?FAQInstaller.*?<CodeUpgrade.*?FAQInstaller.*?<CodeReinstall.*?FAQInstaller/s, 'managed FAQ covers install, upgrade, and reinstall lifecycles' );
like( $SOPM, qr/<CodeUpgrade.*?FAQInstaller.*?GovernanceDB::Bootstrap/s, 'managed FAQ executes before the broader upgrade bootstrap can fail' );
unlike( content('Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/ZTSMExternalAPI.xml'), qr/TESSERAManagedFAQEnsure/, 'managed FAQ no longer depends on a scheduler fallback' );
like( $FAQInstaller, qr/return \$ItemID if \$Unchanged/, 'repeat package lifecycle execution does not create repeated FAQ history' );
like( $FAQInstaller, qr{\$Home/var/governancedb/faq/tessera_external_api\.md.*?next FILE if !-f \$File}s, 'managed FAQ reads the actual package destination without noisy missing-file probes' );
like( $FAQInstaller, qr/FROM faq_category fc.*?fc\.name = \?.*?Misc/s, 'managed FAQ inherits permissions from the existing visible Misc category' );
like( $FAQInstaller, qr/FAQ::ApprovalGroup.*?'users'/s, 'managed FAQ has installation-aware permission fallbacks' );
unlike( $FAQInstaller, qr/required FAQ group 'faq'/, 'managed FAQ does not hard-require a conventional group name' );
like( $Bootstrap, qr/can\('UpdateTypServiceACLs'\).*?skipped legacy service ticket type ACL regeneration/s, 'missing legacy Service ACL API cannot abort OTOBO 11.1 bootstrap' );
unlike( $Bootstrap, qr/InstallDefaults.*?_ExternalAPIFAQEnsure\(\)/s, 'FAQ installation has one authoritative lifecycle path' );
like( $FAQ, qr/Key lifecycle.*?--action renew/s, 'FAQ documents key renewal' );
like( $FAQ, qr/External connector integration.*?allowlisted/s, 'FAQ documents safe Script Engine connector use' );
like( $FAQ, qr/TESSERA Script Engine language.*?SEARCH:.*?REQUIRE:.*?RETURN:/s, 'FAQ includes the English YAML search and typed-return language' );
like( $FAQ, qr/ControlObjective risk field assignments.*?FIELD ASSIGNMENTS:.*?MELT-Control: THIS/s, 'FAQ documents ControlObjective-owned risk assignments' );
like( $FAQ, qr/Conditions and values.*?IS NOT EMPTY.*?PRODUCT OF/s, 'FAQ documents conditions, conversions, dates, and arithmetic' );
like( $FAQ, qr/Attestation ticket programs.*?NEW \@TICKET.*?SUBMIT/s, 'FAQ documents bounded ticket programs' );
like( $FAQ, qr/MELT-AccessPermission/, 'FAQ documents the authoritative MELT entitlement field' );

done_testing();
