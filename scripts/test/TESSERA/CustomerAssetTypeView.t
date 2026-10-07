use strict;
use warnings;
use Test::More;
require './Kernel/Package/GovernanceDB/Kernel/Output/HTML/ITSMConfigItem/ZTSMCustomerOverviewSmall.pm';
{
 package AssetTypeOM;
 sub Get {$_[0]{Object}}
 package AssetTypeObjects;
 sub Get {
  my($S,$Key)=@_;
  return {'01'=>{Name=>'All'}} if $Key eq 'Customer::ConfigItem::PermissionConditions';
  return {Default=>$S->{Columns},'01'=>$S->{Columns}} if $Key eq 'Customer::ConfigItem::PermissionConditionColumns';
  return {};
 }
 sub GetPreferences {return ()}
 sub DefinitionGet {my($S,%P)=@_;return {DynamicFieldRef=>{Type=>{Name=>$S->{Field},Label=>'Type',FieldType=>'GeneralCatalog'}}};}
 sub ValueGet {return 17}
 sub DisplayValueRender {my($S,%P)=@_;return {Title=>'Resolved catalog type',Value=>'Resolved catalog type'};}
}
my $Objects=bless {Columns=>['Number','Name','Class','ZTSMAssetTag']},'AssetTypeObjects';
local $Kernel::OM=bless {Object=>$Objects},'AssetTypeOM';
my $View=Kernel::Output::HTML::ITSMConfigItem::ZTSMCustomerOverviewSmall->new(UserID=>'test-user',Action=>'CustomerITSMConfigItem',Filter=>'01',Filters=>{'01'=>{Name=>'All'}});
is_deeply($View->{ColumnsEnabled},['Name','ZTSMAssetType','ZTSMAssetTag'],'old configured identifiers removed and type added without manual preference reset');
is_deeply($Objects->{Columns},['Number','Name','Class','ZTSMAssetTag'],'renderer does not mutate shared configuration');
my @Fields=qw(ZTAM-WorkloadType ZTAM-NetworkNodeType ZTAM-FacilityEquipmentType ZTAM-PeripheralNodeType);
for my $Field (@Fields) {
 $Objects->{Field}=$Field;
 is($View->_ZTSMVirtualValueGet(ConfigItem=>{VersionID=>1,DefinitionID=>1},Candidates=>\@Fields),
 'Resolved catalog type',"$Field resolves through current class definition and backend display");
}
done_testing();
