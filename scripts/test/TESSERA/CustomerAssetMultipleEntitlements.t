use strict;
use warnings;
use Test::More;
require './Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/CustomerEntitlement.pm';
{
    package MultiEntitlementOM;
    sub Get { $_[0] }
    sub ConfigItemGet { my ($Self,%Param)=@_;return $Self->{Items}{$Param{ConfigItemID}}; }
    package MultiEntitlementService;
    our @ISA = ('Kernel::System::ITSMConfigItem::CustomerEntitlement');
    sub _ConfigItemReferenceGet {
        my ($Self,%Param)=@_;
        return $Self->{Entitlements}{$Param{Value}};
    }
    sub _ReferenceObjects {
        my ($Self,%Param)=@_;
        return if !defined $Param{Value};
        return ({GovernanceObjectID=>$Param{Value}});
    }
    sub _AssignmentsGet {
        my ($Self,%Param)=@_;
        return [] if $Param{CustomerUserID} ne 'test-customer';
        return [] if $Param{RequireRole} && (!$Self->{Role} || $Self->{Role} ne $Param{RequireRole});
        return [{ 'DynamicField_ZTSMSupportAssignment-SupportProfile'=>200 }];
    }
    sub _Denied { return; }
}
my $Item={ConfigItemID=>99,'DynamicField_ZTAM-ContractEntitlement'=>[10,20]};
local $Kernel::OM=bless {Items=>{99=>$Item}},'MultiEntitlementOM';
my $Service=bless {
    Role=>'TESSERA::CMDB::READ',
    Entitlements=>{
        10=>{ConfigItemID=>10,'DynamicField_Contract-SupportProfie'=>100},
        20=>{ConfigItemID=>20,'DynamicField_Contract-SupportProfie'=>200},
        30=>{ConfigItemID=>30},
    },
},'MultiEntitlementService';
my %Request=(CustomerUserID=>'test-customer',ConfigItemID=>99);
ok($Service->ConfigItemDetailAccessCheck(%Request),'second entitlement grants detail only through matching read assignment');
ok($Service->ConfigItemDiscoveryCheck(%Request),'second entitlement grants discovery through matching assignment');
is_deeply($Service->ConfigItemIDsFilter(%Request,ConfigItemIDs=>[99],RequireCMDBReadRole=>1),[99],'list/export central filter includes multi-entitled asset');
$Item->{'DynamicField_ZTAM-ContractEntitlement'}=[20,10];
ok($Service->ConfigItemDetailAccessCheck(%Request),'entitlement order does not change authorization');
$Item->{'DynamicField_ZTAM-ContractEntitlement'}=[10,30];
ok(!$Service->ConfigItemDetailAccessCheck(%Request),'nonmatching and missing profiles never grant access');
$Item->{'DynamicField_ZTAM-ContractEntitlement'}=[10,999];
ok(!$Service->ConfigItemDetailAccessCheck(%Request),'unresolved or ambiguous reference does not grant access');
$Item->{'DynamicField_ZTAM-ContractEntitlement'}=[999,20];
ok($Service->ConfigItemDetailAccessCheck(%Request),'independent valid matching entitlement still grants access');
$Item->{'DynamicField_ZTAM-ContractEntitlement'}=[20];
ok($Service->ConfigItemDetailAccessCheck(%Request),'single entitlement keeps existing behavior');
ok(!$Service->ConfigItemDetailAccessCheck(%Request,CustomerUserID=>'other-customer'),'another account is denied');
$Service->{Role}='SUPPORT::OPERATOR';
ok($Service->ConfigItemDiscoveryCheck(%Request),'matching assignment can discover without CMDB read role');
ok(!$Service->ConfigItemDetailAccessCheck(%Request),'discovery never grants full detail without matching CMDB read role');
is_deeply($Service->ConfigItemIDsFilter(%Request,ConfigItemIDs=>[99],RequireCMDBReadRole=>1),[],'portal list excludes discovery-only entitlement');
$Item->{'DynamicField_ZTAM-ContractEntitlement'}=[];
ok(!$Service->ConfigItemDiscoveryCheck(%Request),'no entitlements fails closed');
ok(!$Service->ConfigItemDetailAccessCheck(%Request,CustomerUserID=>''),'missing customer fails closed');
done_testing();
