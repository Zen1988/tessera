use strict;use warnings;use Test::More;use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::GovernanceObject::Document;
use Kernel::System::TESSERA::ScriptBlocks qw(SplitSource Assemble);
{package RecoveryDocument;our @ISA=('Kernel::System::GovernanceObject::Document');sub _ClassIDResolve{1}sub _GeneralCatalogIDResolve{1}sub _ExistingObjectIDResolve{250}}
{package RecoveryOM;sub Get{$_[0]}sub Permission{1}sub DefinitionGet{$_[0]{Definition}}sub GovernanceObjectUpdate{my($S,%P)=@_;$S->{Writes}++;$S->{Written}={%P};1}}
my %Definition;
for my $Field (qw(PolicyFilter PolicyEvaluation)) {
 my $Member='ZRM-'.$Field;
 $Definition{$Member}={Name=>$Member,FieldType=>'TextArea',Config=>{}};
 $Definition{$Field}={Name=>$Field,FieldType=>'Set',Config=>{Include=>[{DF=>'ZTemplate-ScriptIndex',Definition=>{Name=>'ZTemplate-ScriptIndex',FieldType=>'Text',Config=>{}}},{DF=>$Member,Definition=>$Definition{$Member}}]}};
}
local $Kernel::OM=bless {Definition=>{DefinitionID=>1,DynamicFieldRef=>\%Definition},Writes=>0},'RecoveryOM';
my $D=bless {},'RecoveryDocument';my $Filter="VERSION: 1\nRETURN: true\n";my $Policy="VERSION: 1\nRETURN: false\n";
my %Fields=(PolicyFilter=>SplitSource(Field=>'PolicyFilter',Source=>$Filter),PolicyEvaluation=>SplitSource(Field=>'PolicyEvaluation',Source=>$Policy),'ZRM-PolicyFilter'=>'','ZRM-PolicyEvaluation'=>'');
my $Result=$D->Import(Data=>{class=>'ControlObjective',number=>'GO-CONTROLO-00000250',name=>'End-of-Support (EOS) Assets',ztsm_status=>'Active',fields=>\%Fields},UserID=>1);
ok($Result->{Success},'real Document import accepts migrated Set rows');
is($Kernel::OM->{Writes},1,'one update performed');
ok(!exists $Kernel::OM->{Written}{'DynamicField_ZRM-PolicyFilter'},'empty legacy filter is not forwarded as competing storage write');
ok(!exists $Kernel::OM->{Written}{'DynamicField_ZRM-PolicyEvaluation'},'empty legacy evaluation is not forwarded as competing storage write');
is(Assemble(Field=>'PolicyFilter',Rows=>$Kernel::OM->{Written}{DynamicField_PolicyFilter}),$Filter,'filter survives import conversion');
is(Assemble(Field=>'PolicyEvaluation',Rows=>$Kernel::OM->{Written}{DynamicField_PolicyEvaluation}),$Policy,'evaluation survives import conversion');
is($Fields{'ZRM-PolicyFilter'},'','caller payload remains unchanged');
$Fields{'ZRM-PolicyFilter'}='conflicting legacy';
$Result=$D->Import(Data=>{class=>'ControlObjective',ztsm_status=>'Active',fields=>\%Fields},UserID=>1);
ok(!$Result->{Success},'conflicting nonempty standalone member is rejected');is($Kernel::OM->{Writes},1,'conflict rejected before any write');
$Fields{'ZRM-PolicyFilter'}='';delete $Definition{PolicyFilter};
$Result=$D->Import(Data=>{class=>'ControlObjective',ztsm_status=>'Active',fields=>\%Fields},UserID=>1);
ok(!$Result->{Success},'unavailable new Set cannot silently report success');like($Result->{Message},qr/unavailable/,'definition mismatch is actionable');is($Kernel::OM->{Writes},1,'missing definition rejected before any write');
$Definition{PolicyFilter}={Name=>'PolicyFilter',FieldType=>'Set',Config=>{Include=>[]}};
for my $Blank (undef, '', []) {
 my %Empty=(PolicyFilter=>$Blank,PolicyEvaluation=>SplitSource(Field=>'PolicyEvaluation',Source=>$Policy));
 $Result=$D->Import(Data=>{class=>'ControlObjective',ztsm_status=>'Active',fields=>\%Empty},UserID=>1);
 ok($Result->{Success},'empty workbook Set accepted');
 is_deeply($Kernel::OM->{Written}{DynamicField_PolicyFilter},[],'explicit empty Set remains an empty list through real import');
 is(Assemble(Field=>'PolicyEvaluation',Rows=>$Kernel::OM->{Written}{DynamicField_PolicyEvaluation}),$Policy,'populated sibling survives empty Set import');
}
for my $Malformed ('not a list', {}) {
 my $Before=$Kernel::OM->{Writes};
 $Result=$D->Import(Data=>{class=>'ControlObjective',ztsm_status=>'Active',fields=>{PolicyFilter=>$Malformed}},UserID=>1);
 ok(!$Result->{Success},'populated scalar or mapping remains invalid');
 is($Kernel::OM->{Writes},$Before,'malformed Set rejected before writes');
}
$Result=$D->Import(Data=>{class=>'ControlObjective',ztsm_status=>'Active',fields=>{PolicyEvaluation=>[]}},UserID=>1);
ok($Result->{Success},'omitted Set column accepted');
ok(!exists $Kernel::OM->{Written}{DynamicField_PolicyFilter},'omitted Set does not request clearing existing data');
{ package RecoveryReferenceDocument; our @ISA=('RecoveryDocument');
 sub _SingleReferenceFromDocument {my($S,%P)=@_;return 99 if ($P{Value}//'') eq 'valid';return undef;}
}
my $RD=bless {},'RecoveryReferenceDocument';
$Definition{'ZRM-RiskStmt'}={Name=>'ZRM-RiskStmt',FieldType=>'GovernanceObject',Config=>{MultiValue=>1}};
my $BeforeReference=$Kernel::OM->{Writes};
$Result=$RD->Import(Data=>{class=>'ControlObjective',ztsm_status=>'Active',fields=>{'ZRM-RiskStmt'=>['missing']}},UserID=>1);
ok(!$Result->{Success},'unresolved populated reference rejects entire import');
like($Result->{Message},qr/ZRM-RiskStmt.*Reference cannot be resolved uniquely/s,'error identifies reference field');
is($Kernel::OM->{Writes},$BeforeReference,'reference failure cannot erase existing selection');
$Result=$RD->Import(Data=>{class=>'ControlObjective',ztsm_status=>'Active',fields=>{'ZRM-RiskStmt'=>['valid']}},UserID=>1);
ok($Result->{Success},'resolved reference still imports');
is_deeply($Kernel::OM->{Written}{'DynamicField_ZRM-RiskStmt'},[99],'resolved reference selection retained');
done_testing();
