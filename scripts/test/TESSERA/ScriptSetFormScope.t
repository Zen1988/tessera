use strict;use warnings;use Test::More;use lib 'Kernel/Package/GovernanceDB','.';
require Kernel::System::DynamicField::Driver::Set;
{package Kernel::System::Web::Request;sub GetArray{my($S,%P)=@_;return @{$S->{$P{Param}}||[]}}sub GetParam{my($S,%P)=@_;return $S->{$P{Param}} ? $S->{$P{Param}}[0] : undef}sub GetParamNames{keys %{$_[0]}}}
{package FormScopeOM;sub Get{$_[0]}sub EditFieldValueGet{my($S,%P)=@_;$P{ParamObject}->GetParam(Param=>'DynamicField_'.$P{DynamicFieldConfig}{Name})}sub EditFieldValueValidate{{ServerError=>0}}}
my $Driver=bless {},'Kernel::System::DynamicField::Driver::Set';
{no warnings 'redefine';*Kernel::System::DynamicField::Driver::Set::_GetIncludedDynamicFields=sub{my($S,%P)=@_;return {map {$_=>{Name=>$_,FieldType=>'Text',Config=>{}}} @{$P{InputFieldDefinition}}}}}
local $Kernel::OM=bless {},'FormScopeOM';my $Request=bless {},'Kernel::System::Web::Request';
my %Config;for my $Set(qw(RiskScoringEngine RiskAggregationEngine MasterTicket)) {
 my $Member='ZRM-'.$Set;$Config{$Set}={Name=>$Set,Config=>{MultiValue=>1,Include=>['ZTemplate-ScriptIndex',$Member]}};
 $Request->{'SetIndex_'.$Set}=[0];$Request->{'DynamicField_ZTemplate-ScriptIndex__Set_'.$Set.'_0'}=[1];$Request->{'DynamicField_'.$Member.'__Set_'.$Set.'_0'}=[$Set.' program'];
}
my %Values;
for my $Set(sort keys %Config) {
 my $Rows=$Driver->EditFieldValueGet(DynamicFieldConfig=>$Config{$Set},ParamObject=>$Request);
 is($Rows->[0]{'ZTemplate-ScriptIndex'},1,"$Set reads its own first index");is($Rows->[0]{'ZRM-'.$Set},$Set.' program',"$Set retains its own source");
 $Values{'DynamicField_'.$Set}=$Rows;
 my $V=$Driver->EditFieldValueValidate(DynamicFieldConfig=>$Config{$Set},ParamObject=>$Request,GetParam=>{DynamicField=>\%Values});
 ok(!$V->{ServerError},"$Set accepts index1 independently of other Sets");
 ok(!exists $Config{$Set}{ProcessSuffix},'cached field configuration not mutated');
}
# Each Set can have a different number of consecutive blocks.
$Request->{'SetIndex_RiskScoringEngine'}=[0,1];$Request->{'DynamicField_ZTemplate-ScriptIndex__Set_RiskScoringEngine_1'}=[2];$Request->{'DynamicField_ZRM-RiskScoringEngine__Set_RiskScoringEngine_1'}=['second'];
$Values{DynamicField_RiskScoringEngine}=$Driver->EditFieldValueGet(DynamicFieldConfig=>$Config{RiskScoringEngine},ParamObject=>$Request);
ok(!$Driver->EditFieldValueValidate(DynamicFieldConfig=>$Config{RiskScoringEngine},ParamObject=>$Request,GetParam=>{DynamicField=>\%Values})->{ServerError},'two consecutive blocks valid in scoring Set');
is(scalar @{$Values{DynamicField_MasterTicket}},1,'MasterTicket remains one row');
$Values{DynamicField_RiskScoringEngine}[1]{'ZTemplate-ScriptIndex'}=1;
my $Bad=$Driver->EditFieldValueValidate(DynamicFieldConfig=>$Config{RiskScoringEngine},ParamObject=>$Request,GetParam=>{DynamicField=>\%Values});
ok($Bad->{ServerError},'duplicate within one Set rejected');like($Bad->{ErrorMessage},qr/Duplicate/,'duplicate error is explicit');
my $Ord={Name=>'OrdinarySet',ProcessSuffix=>'_P'};is(Kernel::System::DynamicField::Driver::Set::_ScriptSetFormConfig($Ord),$Ord,'ordinary Sets unchanged');
my $Scoped=Kernel::System::DynamicField::Driver::Set::_ScriptSetFormConfig({Name=>'MasterTicket',ProcessSuffix=>'_P'});
is($Scoped->{ProcessSuffix},'_P__Set_MasterTicket','process suffix preserved');is(Kernel::System::DynamicField::Driver::Set::_ScriptSetFormConfig($Scoped)->{ProcessSuffix},$Scoped->{ProcessSuffix},'scoping is idempotent');
my $Stored=Kernel::System::DynamicField::Driver::Set::_ScriptSetStoredRows({Name=>'MasterTicket'},[{'ZTemplate-ScriptIndex'=>1,'ZRM-MasterTicket'=>'a'},{'ZTemplate-ScriptIndex'=>2}]);
is_deeply($Stored,[{'ZTemplate-ScriptIndex'=>1,'ZRM-MasterTicket'=>'a'}],'longer sibling counter cannot create phantom rows');
$Stored=Kernel::System::DynamicField::Driver::Set::_ScriptSetStoredRows({Name=>'RiskScoringEngine'},[{'ZTemplate-ScriptIndex'=>1,'ZRM-RiskScoringEngine'=>'a'},{'ZRM-RiskScoringEngine'=>'b'}]);
is($Stored->[1]{'ZTemplate-ScriptIndex'},2,'shorter sibling counter cannot erase own second index');
done_testing();
