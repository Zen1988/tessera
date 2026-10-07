use strict;
use warnings;
use Test::More;
open my $FH,'<','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerITSMConfigItem.pm' or die $!;
my $Source=do {local $/;<$FH>};
my ($Code)=$Source =~ /(sub _ZTSMAssetDashboard \{.*?)(?=sub _ZTSMAssetExport)/s;
eval "package DashboardPage; sub IsHashRefWithData {ref \$_[0] eq 'HASH' && keys %{\$_[0]}} $Code; 1" or die $@;
{
 package DashboardPage;
 sub _ZTSMVirtualValueGet {my($S,%P)=@_;return $P{ConfigItem}{AssetType};}
 package DashboardOM;
 sub Get {$_[0]}
 sub ConfigItemGet {my($S,%P)=@_;return $S->{Assets}{$P{ConfigItemID}};}
 sub TicketSearch {my($S,%P)=@_;push @{$S->{Searches}},\%P;return 5 if $P{Result} eq 'COUNT';return (101..105);}
 sub TicketCustomerPermission {my($S,%P)=@_;return $P{UserID} eq 'customer-a' && $P{TicketID}!=104;}
 sub TicketGet {my($S,%P)=@_;push @{$S->{Reads}},$P{TicketID};return %{$S->{Tickets}{$P{TicketID}}};}
 sub DynamicFieldGet {my($S,%P)=@_;push @{$S->{FieldNames}},$P{Name};return {} if $P{Name} eq 'RiskAssessment';return {Name=>$P{Name}};}
 sub ValueGet {my($S,%P)=@_;return $S->{Rows}{$P{ObjectID}};}
 sub MELTObjectGet {my($S,%P)=@_;return $S->{Risks}{$P{MELTObjectID}};}
}
local $Kernel::OM=bless {
 Assets=>{1=>{Name=>'Server',AssetType=>'Managed Appliance'},2=>{Name=>'Switch',AssetType=>'Network Controller'},3=>{Name=>'Server 2',AssetType=>'Managed Appliance'},4=>{Name=>'Other'}},
 Tickets=>{
 101=>{TicketID=>101,StateType=>'open','DynamicField_ZRM-RiskTargetCI'=>[1,999]},
 102=>{TicketID=>102,StateType=>'open','DynamicField_ZRM-OriginatedEvent'=>[50]},
 103=>{TicketID=>103,StateType=>'closed','DynamicField_ZRM-RiskTargetCI'=>[4]},
 104=>{TicketID=>104,StateType=>'open','DynamicField_ZRM-RiskTargetCI'=>[4]},
 105=>{TicketID=>105,StateType=>'open','DynamicField_ZRM-OriginatedEvent'=>[51]},
 },
 Rows=>{101=>[{'ZRM-RiskTargetCI'=>[1,2]}],102=>{Nested=>[{'ZRM-RiskTargetCI'=>[2]}]}},
 Risks=>{50=>{Class=>'Risk','DynamicField_MELT-RelatedCI'=>[1,2,999]},51=>{Class=>'Control','DynamicField_MELT-RelatedCI'=>[4]}},
 Searches=>[],Reads=>[],FieldNames=>[],
},'DashboardOM';
my $Page=bless {UserID=>'customer-a'},'DashboardPage';
my $Result=$Page->_ZTSMAssetDashboard(ConfigItemIDs=>[1,2,3,4,1]);
is($Result->{Total},4,'authorized filtered assets counted once');
is($Result->{RiskCount},2,'unique assets with accessible active risk links counted once');
is_deeply([map {$_->{ID}} @{$Result->{RiskAssets}}],[1,2],'unentitled targets, closed/denied tickets, non-Risk events excluded');
is_deeply([map {[$_->{Type},$_->{Count}]} @{$Result->{Distribution}}],
 [['Managed Appliance',2],['Network Controller',1],['Unspecified',1]],'type distribution uses display type and includes missing type bucket');
is($Result->{Distribution}[0]{Percent},'50.0','distribution percentages use unique asset total');
ok(!grep({$_==104} @{$Kernel::OM->{Reads}}),'inaccessible ticket is never read');
is_deeply($Kernel::OM->{FieldNames},['RiskAssessment','ZRM-RiskAssessment'],'legacy namespaced Set fallback supported');
for my $Search (@{$Kernel::OM->{Searches}}) {is($Search->{StateType},'Open','backend searches active tickets only');}
$Page->{UserID}='other-customer';
$Result=$Page->_ZTSMAssetDashboard(ConfigItemIDs=>[1,2,3,4]);
is($Result->{RiskCount},0,'another account does not learn inaccessible ticket risk links');
$Result=$Page->_ZTSMAssetDashboard(ConfigItemIDs=>[]);
is_deeply($Result,{Total=>0,RiskCount=>0,Distribution=>[],RiskAssets=>[]},'empty set is valid dashboard with zero counts');
$Page->{UserID}='customer-a';
$Result=$Page->_ZTSMAssetDashboard(ConfigItemIDs=>[3]);
is($Result->{RiskCount},0,'risk links outside current asset filters are not counted');
is($Result->{Total},1,'dashboard follows same filtered asset set as list/export');
done_testing();
