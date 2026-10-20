use strict;
use warnings;
use Test::More;
use YAML::XS ();
use DateTime;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::ScriptEngine;
use Kernel::System::TESSERA::ControlRuntime;
use Kernel::System::TESSERA::RiskMasterTicket;
use Kernel::System::TESSERA::ScriptBlocks qw(SplitSource);
sub Read { open my $F,'<',$_[0] or die $!; local $/; <$F> }
my $RiskText=Read('Kernel/Package/GovernanceDB/var/governancedb/policy/product_eosl_entitlement_risk_assignment.yml');
my $EvaluationText=Read('Kernel/Package/GovernanceDB/var/governancedb/policy/product_eosl_evaluation.yml');
my $MasterText=Read('Kernel/Package/GovernanceDB/var/governancedb/policy/entitlement_risk_master_ticket.yml');
my $Engine=Kernel::System::TESSERA::ScriptEngine->new();
my $Runtime=Kernel::System::TESSERA::ControlRuntime->new();
my $Now=DateTime->new(year=>2026,month=>10,day=>13,time_zone=>'Asia/Singapore')->epoch;
{ package EntitlementClock; sub ToString {'2026-10-13 00:00:00'} }
{ package EntitlementOM;
 sub Get { my($S,$Name)=@_; return $S->{Engine} if $Name =~ /::(?:PolicyEngine|ScriptEngine)$/; $S }
 sub Create { bless {},'EntitlementClock' }
 sub Load {my($S,%P)=@_; YAML::XS::Load($P{Data})}
 sub Permission { !$_[0]{Deny} }
 sub DynamicFieldGet {
   my($S,%P)=@_; my $N=$P{Name};
   return {Name=>$N,ObjectType=>'MELTObject'} if $N=~/^MELT-/;
   return {Name=>$N,ObjectType=>'GovernanceObject',Config=>{ReferencedObjectType=>'GovernanceObject'}} if $N eq 'ZTSMTechnologyProfile-Parent';
   return {Name=>$N,ObjectType=>'ITSMConfigItem',FieldType=>'Set',Config=>{Include=>[{DF=>'ZTAM-Installed'}]}} if $N eq 'ZTAM-Runtime';
   return {Name=>$N,ObjectType=>'ITSMConfigItem',Config=>{ReferencedObjectType=>'GovernanceObject'}} if $N=~/^Contract-/;
   return {Name=>$N,ObjectType=>'ITSMConfigItem',Config=>{ReferencedObjectType=>'ITSMConfigItem'}};
 }
 sub ConfigItemGet {my($S,%P)=@_;$S->{CI}{$P{ConfigItemID}}}
 sub ConfigItemSearch {
   my($S,%P)=@_;my @CI=grep {$_->{Class} eq $P{Classes}[0]} values %{$S->{CI}};
   for my $F (grep {/^DynamicField_/} keys %P) {@CI=grep {($_->{$F}||'') eq $P{$F}{Equals}} @CI}
   return sort {$a<=>$b} map {$_->{ConfigItemID}} @CI;
 }
 sub GovernanceObjectGet {my($S,%P)=@_;$S->{GO}{$P{GovernanceObjectID}}}
 sub GovernanceObjectSearch {
   my($S,%P)=@_;return sort {$a<=>$b} map {$_->{GovernanceObjectID}}
     grep {$_->{Class} eq $P{Classes}[0] && $_->{Name} eq ($P{NameExact}||$P{Name})} values %{$S->{GO}};
 }
 sub Resolve {my($S,%P)=@_; $S->{RoleCalls}++;return $S->{RoleResult}||{Success=>1,Value=>503,ValueType=>'GovernanceObject.SupportProfile'} }
 sub ItemList {my($S,%P)=@_;$P{Class}=~/::Class$/ ? {1=>'Risk'} : {2=>'Active',3=>'Resolved'} }
 sub MELTObjectSearch {my($S,%P)=@_;return sort {$a<=>$b} grep {$_[0]{Risks}{$_}{ZTSMStatusID}==2} keys %{$S->{Risks}}}
 sub MELTObjectGet {my($S,%P)=@_;$S->{Risks}{$P{MELTObjectID}}}
 sub MELTObjectAdd {my($S,%P)=@_;my $ID=200+keys %{$S->{Risks}};$S->{Risks}{$ID}={%P,Class=>'Risk',MELTObjectID=>$ID};$ID}
 sub MELTObjectUpdate {my($S,%P)=@_;my $ID=delete $P{MELTObjectID};@{$S->{Risks}{$ID}}{keys %P}=values %P;1}
 sub ActivityAdd {my($S,%P)=@_;push @{$S->{Activities}},\%P;1}
 sub PIDCreate {1} sub PIDDelete {1}
 sub ValueSet {my($S,%P)=@_;$S->{Saved}{$P{DynamicFieldConfig}{Name}}=$P{Value};1}
 sub Ensure {my($S,%P)=@_;push @{$S->{Ensured}},$P{RiskID};1}
 sub ValidateOwnership {my($S,%P)=@_;Kernel::System::TESSERA::RiskMasterTicket->new()->ValidateOwnership(%P)}
 sub Log {1}
}
sub Setup {
 my %CI=(
  1=>{Class=>'Product',Name=>'Product A','DynamicField_ZTAM-EoServiceLife'=>'2026-12-10','DynamicField_ZTAM-TechnologyProfile'=>[11]},
  10=>{Class=>'Workload',Name=>'Asset A','DynamicField_ZTAM-Model'=>1,'DynamicField_ZTAM-Application'=>100,'DynamicField_ZTAM-ContractEntitlement'=>[700,701,702]},
  700=>{Class=>'ContractEntitlement','DynamicField_Contract-Coverage'=>[10],'DynamicField_Contract-SupportProfie'=>500},
  701=>{Class=>'ContractEntitlement','DynamicField_Contract-Coverage'=>[11],'DynamicField_Contract-SupportProfie'=>501},
  702=>{Class=>'ContractEntitlement','DynamicField_Contract-Coverage'=>[10],'DynamicField_Contract-SupportProfie'=>500},
  90=>{Class=>'Control',VersionID=>1090},
 );
 my %GO=(10=>{Class=>'TechnologyProfile',Name=>'Infrastructure'},11=>{Class=>'TechnologyProfile',Name=>'Dell','DynamicField_ZTSMTechnologyProfile-Parent'=>[10]},
  12=>{Class=>'TechnologyProfile',Name=>'Other technology'},
  100=>{Class=>'Application',Name=>'Application A'},
  50=>{Class=>'RiskStatement',Name=>'EOS Assets','DynamicField_ZRM-Annex'=>'IS-9','DynamicField_ZRM-RMF'=>120},
  120=>{Class=>'Framework',Name=>'Framework','DynamicField_ZRM-RiskMgtStateBook'=>130},
  500=>{Class=>'SupportProfile',Name=>'Server team'},501=>{Class=>'SupportProfile',Name=>'Platform team'},503=>{Class=>'SupportProfile',Name=>'Application team'},
  900=>{Class=>'GovernanceRole',Name=>'APPLICATION::DEFAULT'},
  60=>{Class=>'EventSeverity',Name=>'Critical'},61=>{Class=>'EventSeverity',Name=>'High'},62=>{Class=>'EventSeverity',Name=>'Medium'});
 $CI{$_}{ConfigItemID}=$_ for keys %CI;
 for my $ID (keys %GO) {$GO{$ID}{GovernanceObjectID}=$ID;$GO{$ID}{ZTSMStatus}='Active'}
 $GO{120}{'DynamicField_MasterTicket'}=SplitSource(Field=>'MasterTicket',Source=>$MasterText);
 $Kernel::OM=bless {CI=>\%CI,GO=>\%GO,Engine=>$Engine,Risks=>{},Activities=>[],Saved=>{},Ensured=>[]},'EntitlementOM';
}
my $Objective={GovernanceObjectID=>400,Class=>'ControlObjective','DynamicField_ZRM-RiskClass'=>'MELTObject.Risk','DynamicField_ZRM-CreateRisk'=>1,
 'DynamicField_ZRM-RiskStmt'=>[50],'DynamicField_PolicyEvaluation'=>SplitSource(Field=>'PolicyEvaluation',Source=>$EvaluationText),
 'DynamicField_FieldAsssignment'=>SplitSource(Field=>'FieldAsssignment',Source=>$RiskText)};
my $Control={Class=>'Control',ConfigItemID=>90,Name=>'Control A','DynamicField_ZRM-CIInstance'=>1,'DynamicField_ZRM-ControlObjective'=>400};
my %P=(Control=>$Control,Objective=>$Objective,ConfigItemID=>90,Now=>$Now,UserID=>1);
Setup();my $R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'Fail','Covered EOS policy violation completes evaluation');
is(scalar keys %{$Kernel::OM->{Risks}},2,'Two different matching SupportProfiles produce two Risks');
my @Risks=sort {$a->{Name} cmp $b->{Name}} values %{$Kernel::OM->{Risks}};
like($Risks[0]{Name},qr/^Application A - Platform team:/,'SupportProfile follows Application in name');
is_deeply($Risks[0]{'DynamicField_MELT-RelatedCI'},[1,10,701],'Risk links only its matching entitlement plus source/asset');
is_deeply($Risks[1]{'DynamicField_MELT-RelatedCI'},[1,10,700,702],'Same SupportProfile deduplicates entitlements into one Risk');
like($Risks[1]{'DynamicField_MELT-Reference'},qr/:100:50:500:1$/,'Stable identity includes SupportProfile and Product IDs');
$Runtime->_AutomaticEvaluate(%P);
is(scalar keys %{$Kernel::OM->{Risks}},2,'Repeated run reuses partition identities');
for my $Risk (@Risks) {
 my $M=$Engine->FieldAssignmentsEvaluate(Source=>$MasterText,ObjectType=>'Ticket',Class=>'ServiceRequest',UserID=>1,
   Context=>{RISK=>$Risk,FRAMEWORK=>$Kernel::OM->{GO}{120}});
 ok($M->{Success},'Framework resolver reads the persisted Risk entitlement links') or diag explain $M;
 is($M->{Value}{'ZTicket-OwnerGroup'},$Risk== $Risks[0] ? 501 : 500,'Framework maps matching SupportProfile to ticket owner');
}
ok($Kernel::OM->{Saved}{'ZRM-LastRun'},'Completed partitioned evaluation advances timestamp');
is($Kernel::OM->{RoleCalls}||0,0,'Entitlement path never evaluates fallback role');
$Kernel::OM->{GO}{500}{Name}='Renamed server team';
$Runtime->_AutomaticEvaluate(%P);
is(scalar keys %{$Kernel::OM->{Risks}},2,'SupportProfile rename retains partition identities');
ok(grep({$_->{Name}=~/Application A - Renamed server team:/} values %{$Kernel::OM->{Risks}}),'Risk display name follows profile rename');

Setup();$Kernel::OM->{CI}{20}={ConfigItemID=>20,Class=>'Workload',Name=>'Asset B','DynamicField_ZTAM-Model'=>1,
 'DynamicField_ZTAM-Application'=>100,'DynamicField_ZTAM-ContractEntitlement'=>[701]};
$Runtime->_AutomaticEvaluate(%P);
my @Split=sort {$a->{Name} cmp $b->{Name}} values %{$Kernel::OM->{Risks}};
is_deeply($Split[0]{'DynamicField_MELT-RelatedCI'},[1,10,20,701],'Each partition collects only assets covered by its team');
is_deeply($Split[1]{'DynamicField_MELT-RelatedCI'},[1,10,700,702],'Other partition excludes unmatched asset');

Setup();my $Exact=YAML::XS::Load($RiskText);
$Exact->{RETURN}{'GROUP FINDINGS'}{'GROUP BY'}{'PARTITION BY'}{COVERAGE}{'INCLUDE CHILDREN'}=0;
my $ExactObjective={%$Objective,'DynamicField_FieldAsssignment'=>SplitSource(Field=>'FieldAsssignment',Source=>YAML::XS::Dump($Exact))};
$R=$Runtime->_AutomaticEvaluate(%P,Objective=>$ExactObjective);
is($R->{Status},'Fail','Exact TechnologyProfile matching still completes');
is(scalar keys %{$Kernel::OM->{Risks}},1,'Disabled child coverage excludes parent-only teams');
my ($ExactRisk)=values %{$Kernel::OM->{Risks}};
like($ExactRisk->{Name},qr/Platform team/,'Exact covered team remains');

Setup();delete $Kernel::OM->{CI}{10}{'DynamicField_ZTAM-ContractEntitlement'};
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'Fail','Missing entitlement uses Application default and retains policy violation');
is(scalar keys %{$Kernel::OM->{Risks}},1,'Fallback creates one Application-default Risk');
my ($Fallback)=values %{$Kernel::OM->{Risks}};
like($Fallback->{Name},qr/^Application A - Application team:/,'Fallback SupportProfile names the Risk');
my $M=$Engine->FieldAssignmentsEvaluate(Source=>$MasterText,ObjectType=>'Ticket',Class=>'ServiceRequest',Context=>{RISK=>$Fallback,FRAMEWORK=>$Kernel::OM->{GO}{120}});
is($M->{Value}{'ZTicket-OwnerGroup'},503,'Fallback master resolves Application default owner');
ok(grep({($_->{Payload}{AssignmentFallback}||0)==1} @{$Kernel::OM->{Activities}}),'Risk article identifies fallback assignment');

for my $Case ('cycle','uncovered','dangling','ambiguous support','wrong class','inactive support','missing application','missing role','role error','permission','framework owner mismatch') {
 Setup();
 $Kernel::OM->{GO}{10}{'DynamicField_ZTSMTechnologyProfile-Parent'}=11 if $Case eq 'cycle';
 $Kernel::OM->{CI}{$_}{'DynamicField_Contract-Coverage'}=[12] for $Case eq 'uncovered' ? (700,701,702) : ();
 $Kernel::OM->{CI}{10}{'DynamicField_ZTAM-ContractEntitlement'}=[999] if $Case eq 'dangling';
 $Kernel::OM->{CI}{700}{'DynamicField_Contract-SupportProfie'}=[500,501] if $Case eq 'ambiguous support';
 $Kernel::OM->{GO}{500}{Class}='Application' if $Case eq 'wrong class';
 $Kernel::OM->{GO}{500}{ZTSMStatus}='Inactive' if $Case eq 'inactive support';
 delete $Kernel::OM->{CI}{10}{'DynamicField_ZTAM-Application'} if $Case eq 'missing application';
 if ($Case eq 'missing role' || $Case eq 'role error') {
  delete $Kernel::OM->{CI}{10}{'DynamicField_ZTAM-ContractEntitlement'};
  delete $Kernel::OM->{GO}{900} if $Case eq 'missing role';
  $Kernel::OM->{RoleResult}={Success=>0,Error=>'RoleMap row missing'} if $Case eq 'role error';
 }
 $Kernel::OM->{Deny}=1 if $Case eq 'permission';
 if ($Case eq 'framework owner mismatch') {
  my $Wrong=YAML::XS::Load($MasterText);
  delete $Wrong->{RETURN}{'RESOLVE REFERENCES'};
  $Wrong->{RETURN}{'FIELD ASSIGNMENTS'}{'ZTicket-OwnerGroup'}='"APPLICATION::DEFAULT"';
  $Kernel::OM->{GO}{120}{'DynamicField_MasterTicket'}=SplitSource(Field=>'MasterTicket',Source=>YAML::XS::Dump($Wrong));
 }
 $R=$Runtime->_AutomaticEvaluate(%P,UserID=>$Case eq 'permission' ? 22 : 1);
 is($R->{Status},'UNKNOWN',"$Case fails closed");
 is(scalar keys %{$Kernel::OM->{Risks}},0,"$Case preflight creates no Risk");
 is($R->{ErrorArticleRecorded},1,"$Case records a Control error article");
 like($R->{Reason},qr/Application 100 and GovernanceRole 900: RoleMap row missing/,
  'Fallback article identifies the failing Application, role and resolver reason') if $Case eq 'role error';
 ok(!$Kernel::OM->{Saved}{'ZRM-LastRun'},"$Case does not suppress retry");
}
done_testing;
