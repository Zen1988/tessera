use strict;use warnings;use Test::More;
use lib 'Kernel/Package/GovernanceDB','.';
open my $FH,'<','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerTicketZTSMAction.pm' or die $!;
my $Source=do{local $/;<$FH>};$Source=~s{^use Kernel::[^;]+;\r?\n}{}mg;eval $Source;die $@ if $@;
{no strict 'refs';*{'Kernel::Modules::CustomerTicketZTSMAction::IsHashRefWithData'}=sub{ref $_[0] eq 'HASH' && keys %{$_[0]}};}
our $Object={Class=>'Framework','DynamicField_ZRM-LikelihoodScale'=>'3','DynamicField_ZRM-ImpactScale'=>'5'};
{package ScaleOM;sub Get{$_[0]}sub GovernanceObjectGet{$main::Object}sub DynamicFieldGet{{FieldType=>'GeneralCatalog',Config=>{Class=>'Scale'}}}sub ItemList{{101=>'1',102=>'2',103=>'3',104=>'4',105=>'5',110=>'10',111=>'3abc'}}}
local $Kernel::OM=bless{},'ScaleOM';my $A=bless{},'Kernel::Modules::CustomerTicketZTSMAction';
is_deeply($A->_RiskAssessmentScalesGet(FrameworkID=>1),{Likelihood=>3,Impact=>5},'asymmetric Framework scales');
my $R={'ZRM-Framework'=>[1],'ZRM-InherentLikelihood'=>[103],'ZRM-InherentImpact'=>[105],'ZRM-ResidualLikelihood'=>[101],'ZRM-ResidualImpact'=>[102]};
ok(!$A->_RiskAssessmentScalesValidate(Rows=>[$R]),'catalog IDs resolve numeric labels at inclusive limits');
$R->{'ZRM-InherentLikelihood'}=[104];like($A->_RiskAssessmentScalesValidate(Rows=>[$R]),qr/Inherent Likelihood must be between 1 and 3/,'forged out-of-scale choice rejected');
$R->{'ZRM-InherentLikelihood'}=[103];$R->{'ZRM-ResidualImpact'}=[110];like($A->_RiskAssessmentScalesValidate(Rows=>[$R]),qr/Residual Impact/,'residual scale enforced');
$R->{'ZRM-ResidualImpact'}=[111];like($A->_RiskAssessmentScalesValidate(Rows=>[$R]),qr/Residual Impact/,'nonnumeric label rejected');
$R->{'ZRM-ResidualImpact'}=[999];ok($A->_RiskAssessmentScalesValidate(Rows=>[$R]),'unknown catalog ID rejected');
$Object->{'DynamicField_ZRM-ImpactScale'}='0';is_deeply($A->_RiskAssessmentScalesGet(FrameworkID=>1),{},'zero scale fails closed');
$Object->{'DynamicField_ZRM-ImpactScale'}='5.5';is_deeply($A->_RiskAssessmentScalesGet(FrameworkID=>1),{},'fractional scale fails closed');
$Object->{'DynamicField_ZRM-ImpactScale'}=['5','10'];is_deeply($A->_RiskAssessmentScalesGet(FrameworkID=>1),{},'ambiguous scale fails closed');
$Object={Class=>'RiskStatement'};is_deeply($A->_RiskAssessmentScalesGet(FrameworkID=>1),{},'wrong-class object fails closed');
is_deeply($A->_RiskAssessmentScalesGet(FrameworkID=>'1,2'),{},'ambiguous Framework fails closed');
done_testing();
