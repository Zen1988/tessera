use strict;
use warnings;
use Test::More;
use lib '.';
use Kernel::System::ITSMConfigItem::CustomerEntitlement;
{
    package DirectoryEntitlementOM;
    sub Get {return $_[0]}
    sub CustomerUserDataGet {return (UserLogin=>'alice',UserEmail=>'alice@example.test',ValidID=>1)}
    sub CustomerIDs {return ('Example')}
    sub GovernanceObjectSearch {my ($S,%P)=@_;return (100) if $P{Classes}[0] eq 'SupportAssignment';return ()}
    sub GovernanceObjectGet {my ($S,%P)=@_;return $S->{Objects}{$P{GovernanceObjectID}} if $P{GovernanceObjectID};return}
    sub ConfigItemGet {my ($S,%P)=@_;return {ConfigItemID=>10,Class=>'ContractEntitlement','DynamicField_Contract-SupportProfie'=>20} if $P{ConfigItemID}==10;return}
    sub VersionConfigItemIDGet {return}
    sub Log {return}
}
local $Kernel::OM=bless {Objects=>{
    100=>{GovernanceObjectID=>100,Class=>'SupportAssignment',ZTSMStatus=>'Active','DynamicField_ZTSMSupportAssignment-UserAccount'=>'alice','DynamicField_ZTSMSupportAssignment-SupportProfile'=>20,'DynamicField_ZTSMSupportAssignment-Role'=>30},
    20=>{GovernanceObjectID=>20,Class=>'SupportProfile',ZTSMStatus=>'Active'},
    30=>{GovernanceObjectID=>30,Class=>'GovernanceRole',Name=>'TESSERA::CMDB::READ',ZTSMStatus=>'Active'},
}},'DirectoryEntitlementOM';
my $S=Kernel::System::ITSMConfigItem::CustomerEntitlement->new();
ok($S->CustomerHasCMDBReadRole(CustomerUserID=>'alice'),'active matching capability grants CMDB read');
ok($S->ContractEntitlementAccessCheck(CustomerUserID=>'alice',ContractEntitlementID=>10),'active membership grants matching discovery scope');
$Kernel::OM->{Objects}{100}{ZTSMStatus}='Inactive';
ok(!$S->CustomerHasCMDBReadRole(CustomerUserID=>'alice'),'retired directory assignment revokes CMDB read');
ok(!$S->ContractEntitlementAccessCheck(CustomerUserID=>'alice',ContractEntitlementID=>10),'retired directory assignment revokes matching discovery');
$Kernel::OM->{Objects}{100}{ZTSMStatus}='Active';$Kernel::OM->{Objects}{20}{ZTSMStatus}='Inactive';
ok(!$S->ContractEntitlementAccessCheck(CustomerUserID=>'alice',ContractEntitlementID=>10),'inactive SupportProfile cannot grant scope');
$Kernel::OM->{Objects}{20}{ZTSMStatus}='Active';$Kernel::OM->{Objects}{30}{ZTSMStatus}='Inactive';
ok(!$S->CustomerHasCMDBReadRole(CustomerUserID=>'alice'),'inactive role cannot grant capability');
$Kernel::OM->{Objects}{30}{ZTSMStatus}='Active';
$Kernel::OM->{Objects}{100}{'DynamicField_ZTSMSupportAssignment-UserAccount'}='Example';
ok(!$S->CustomerHasCMDBReadRole(CustomerUserID=>'alice'),'company membership never substitutes for customer identity');
done_testing();
