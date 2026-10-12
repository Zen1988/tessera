use strict;use warnings;use Test::More;
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptBlocks qw(Assemble ObjectSource SplitSource);
use Kernel::System::TESSERA::ScriptEngine;
my $Source="VERSION: 1\nRETURN: &text '" . ('hello ' x 1100) . "'\nSCRIPT: *text\n";
my $Rows=SplitSource(Field=>'PolicyFilter',Source=>$Source);
ok(@$Rows>1,'long source uses multiple database blocks');
is(Assemble(Field=>'PolicyFilter',Rows=>[reverse @$Rows]),$Source,'numeric sorting reconstructs original exactly');
my $Engine=Kernel::System::TESSERA::ScriptEngine->new();
ok($Engine->ScriptParse(Source=>Assemble(Field=>'PolicyFilter',Rows=>$Rows))->{Success},'cross-block scalar and anchor parsed as one document');
my @Numeric=map {{'ZTemplate-ScriptIndex'=>$_,'ZRM-PolicyFilter'=>"$_,"}} reverse 1..12;
is(Assemble(Field=>'PolicyFilter',Rows=>\@Numeric),join('',map{"$_,"}1..12),'two-digit indices sort numerically');
for my $Case (
 ['duplicate',[{'ZTemplate-ScriptIndex'=>1,'ZRM-PolicyFilter'=>'a'},{'ZTemplate-ScriptIndex'=>1,'ZRM-PolicyFilter'=>'b'}]],
 ['gap',[{'ZTemplate-ScriptIndex'=>1,'ZRM-PolicyFilter'=>'a'},{'ZTemplate-ScriptIndex'=>3,'ZRM-PolicyFilter'=>'b'}]],
 ['zero',[{'ZTemplate-ScriptIndex'=>0,'ZRM-PolicyFilter'=>'a'}]],
 ['negative',[{'ZTemplate-ScriptIndex'=>-1,'ZRM-PolicyFilter'=>'a'}]],
 ['fraction',[{'ZTemplate-ScriptIndex'=>'1.1','ZRM-PolicyFilter'=>'a'}]],
 ['leading zero',[{'ZTemplate-ScriptIndex'=>'01','ZRM-PolicyFilter'=>'a'}]],
 ['three-digit',[{'ZTemplate-ScriptIndex'=>100,'ZRM-PolicyFilter'=>'a'}]],
 ['empty block',[{'ZTemplate-ScriptIndex'=>1,'ZRM-PolicyFilter'=>''}]],
 ['oversized block',[{'ZTemplate-ScriptIndex'=>1,'ZRM-PolicyFilter'=>'x'x3801}]],
 ['invalid row',[1]],
 ['ambiguous scalar',[{'ZTemplate-ScriptIndex'=>[1,2],'ZRM-PolicyFilter'=>'a'}]],
) {ok(!eval{Assemble(Field=>'PolicyFilter',Rows=>$Case->[1]);1},"$Case->[0] rejected")}
is(Assemble(Field=>'PolicyFilter',Rows=>[{'ZTemplate-ScriptIndex'=>[1],'ZRM-PolicyFilter'=>['yaml']}]),'yaml','native single-value Set wrappers accepted');
is(Assemble(Field=>'PolicyFilter',Rows=>[{}]),'','empty optional widget accepted');
is(ObjectSource(Object=>{'DynamicField_ZRM-PolicyFilter'=>'legacy'},Field=>'PolicyFilter'),'','old scalar never executes as fallback');
is(ObjectSource(Object=>{'DynamicField_AdvancedCondition'=>[{'ZTAM-ConditionIndex'=>1,'ZTAM-AdvancedCondition'=>'yaml'}]},Field=>'ZTAM-AdvancedCondition'),'yaml','member reference resolves authoritative owning Set');
for my $Field(qw(AdvancedCondition FieldAsssignment MasterTicket PolicyEvaluation PolicyFilter RiskAggregationEngine RiskScoringEngine ScriptEngine ZTemplate-AutomationScript)){
 my $Unicode="αβ\r\n  a: 1\n";
 is(Assemble(Field=>$Field,Rows=>SplitSource(Field=>$Field,Source=>$Unicode)),$Unicode,"$Field preserves whitespace/unicode");
}
my $Max='x'x(3800*99);my $MaxRows=SplitSource(Field=>'ScriptEngine',Source=>$Max);
is(scalar @$MaxRows,99,'99 maximum-size blocks supported');
is(length Assemble(Field=>'ScriptEngine',Rows=>$MaxRows),376200,'all 99 blocks assemble');
# Exercise the save validator shared by native ValueSet/ValueValidate and form validation.
open my $F,'<','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm' or die $!;local $/;my $Driver=<$F>;close $F;
my ($Guard)=$Driver=~/(sub _ScriptBlockValidationError \{.*)\z/s;eval $Guard;die $@ if $@;
like(_ScriptBlockValidationError({Name=>'PolicyFilter'},[{'ZTemplate-ScriptIndex'=>1,'ZRM-PolicyFilter'=>'a'},{'ZTemplate-ScriptIndex'=>1,'ZRM-PolicyFilter'=>'b'}]),qr/Duplicate/,'save guard rejects duplicate before writes');
ok(!defined _ScriptBlockValidationError({Name=>'OrdinarySet'},[{anything=>1}]),'ordinary Sets unaffected');
open $F,'<','Kernel/Package/GovernanceDB/Kernel/System/ZTSMBlueBookRuntime.pm' or die $!;my $Runtime=<$F>;close $F;
my ($Selector)=$Runtime=~/(sub TemplateSectionFields \{.*)\z/s;eval $Selector;die $@ if $@;
my $Sections={'General Fields::Assessment'=>{Content=>[{DF=>'ZTemplate-RiskAssessment'}]},'General Fields::Automation'=>{Content=>[{DF=>'ZTemplate-AutomationScript'}]}};
is_deeply(TemplateSectionFields(Sections=>$Sections,TicketType=>'Assessment'),{'ZTemplate-RiskAssessment'=>1},'Assessment selects exact section, preserving mapping');
is_deeply(TemplateSectionFields(Sections=>$Sections,TicketType=>'Automation'),{'ZTemplate-AutomationScript'=>1},'Automation selects its own section');
is_deeply(TemplateSectionFields(Sections=>$Sections,TicketType=>'Other'),{},'unmatched type cannot hydrate Assessment');
is_deeply(TemplateSectionFields(Sections=>{X=>{Header=>'Assessment',Content=>[{DF=>'ZTemplate-RiskAssessment'}]}},TicketType=>'Assessment'),{},'header text does not control section selection');
ok(!eval{TemplateSectionFields(Sections=>{%$Sections,'Other::Assessment'=>{Content=>[]}},TicketType=>'Assessment');1},'ambiguous matching sections rejected');
my $LineMax = (('x' x 3798) . "\n") x 99; $LineMax .= 'x' x (376200-length($LineMax));
is(Assemble(Field=>'ScriptEngine',Rows=>SplitSource(Field=>'ScriptEngine',Source=>$LineMax)),$LineMax,'newline preference cannot exceed 99 blocks at maximum length');
done_testing();
