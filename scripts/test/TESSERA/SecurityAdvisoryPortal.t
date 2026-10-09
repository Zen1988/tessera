use strict;use warnings;use Test::More;use Template;use lib '.';
use Kernel::System::TESSERA::SecurityAdvisory;
{
 package FakeOM;sub Get {my ($s,$n)=@_;return $s->{$n}||die $n;}
 package FakePermission;sub CustomerHasRole {my($s,%p)=@_;$s->{role}=$p{Role};return $s->{allow};}
 package FakeYAML;sub Dump {my($s,%p)=@_;return $p{Data};}
 package FakeCatalog;sub ItemList {my($s,%p)=@_;return $p{Class}=~/Deployment/?{1=>'Production'}:{2=>'Operational'};}
 package FakeDocument;sub Import {my($s,%p)=@_;$s->{last}=\%p;$s->{calls}++;return {Success=>1,ConfigItemID=>42};}
 package FakeActivity;sub ActivityAdd {1}
 package FakeCI;sub ConfigItemAttachmentAdd {my($s,%p)=@_;$s->{last}=\%p;return $s->{allow};}
}
$Kernel::OM=bless {},'FakeOM';
my $perm=bless {allow=>1},'FakePermission';$Kernel::OM->{'Kernel::System::ITSMConfigItem::CustomerEntitlement'}=$perm;
$Kernel::OM->{'Kernel::System::YAML'}=bless {},'FakeYAML';
$Kernel::OM->{'Kernel::System::GeneralCatalog'}=bless {},'FakeCatalog';
my $doc=bless {},'FakeDocument';$Kernel::OM->{'Kernel::System::ITSMConfigItem::Document'}=$doc;
$Kernel::OM->{'Kernel::System::ITSMConfigItem::Activity'}=bless {},'FakeActivity';
my $ci=bless {allow=>1},'FakeCI';$Kernel::OM->{'Kernel::System::ITSMConfigItem'}=$ci;
my $s=Kernel::System::TESSERA::SecurityAdvisory->new();
ok($s->AccessCheck(CustomerUserID=>'customer'),'assigned customer allowed');is($perm->{role},'TESSERA::CMDB::SECOPS','exact reserved capability');
my $m={PanelID=>1,Products=>[{ID=>3,Name=>'Chrome'},{ID=>4,Name=>'Windows'}],Fields=>[{Name=>'ZTAM-Application',FieldType=>'GovernanceObject',Config=>{},Choices=>[{ID=>7,Name=>'Application: Test'}]},{Name=>'ZTAM-Status',FieldType=>'Dropdown',Config=>{DefaultValue=>'open',PossibleNone=>0},Choices=>[{ID=>'open',Name=>'open'}]}]};
my $y=$s->ProductCondition(Model=>$m,ProductIDs=>[3,4,3]);is_deeply($y->{SEARCH}{WHERE}{Name}{EQUALS},['Chrome','Windows'],'selected Products form name-based condition');
eval{$s->ProductCondition(Model=>$m,ProductIDs=>[9])};like($@,qr/Invalid Product/,'forged Product rejected');
my $row={Name=>'CVE advisory'};my $r=$s->Create(CustomerUserID=>'customer',Model=>$m,Row=>$row);is($r->{ConfigItemID},42,'creates advisory');is($doc->{last}{Data}{class},'SecurityAdvisory','class restricted');is($doc->{last}{Data}{fields}{'ZTAM-Application'},'','blank bulk Application remains blank');
for my $bad ({Name=>'bad',Class=>'Product'},{Name=>'bad','ZTAM-RMF'=>1},{Name=>'bad','ZTAM-Application'=>99},{Name=>'bad','ZTAM-Status'=>''}) {eval{$s->Create(CustomerUserID=>'customer',Model=>$m,Row=>$bad)};ok($@,'invalid row blocked');}
is($doc->{calls},1,'invalid rows cause no native writes');
$r=$s->Create(CustomerUserID=>'customer',Model=>$m,Row=>$row,Attachments=>[{Filename=>'proof.txt',Content=>'proof',ContentType=>'text/plain'}]);is($ci->{last}{ConfigItemID},42,'attachment goes to created advisory');
$ci->{allow}=0;$r=$s->Create(CustomerUserID=>'customer',Model=>$m,Row=>$row,Attachments=>[{Filename=>'proof.txt',Content=>'proof',ContentType=>'text/plain'}]);like($r->{AttachmentWarning},qr/proof.txt/,'partial attachment failure retains created record result');
$perm->{allow}=0;eval{$s->Create(CustomerUserID=>'customer',Model=>$m,Row=>$row)};like($@,qr/access required/,'direct service denied even with forged model');
open my $fh,'<','Kernel/Output/HTML/Templates/Standard/CustomerSecurityAdvisory.tt' or die $!;my $src=do{local $/;<$fh>};my $out='';my $tt=Template->new();
ok($tt->process(\$src,{Data=>{Fields=>[{Name=>'ZTAM-AdvancedCondition',Value=>''}],Products=>[{ID=>1,Name=>'<Product>'}]},Env=>sub{''}},\$out),'portal template renders');like($out,qr/Security Operation Management/,'requested button/page title');like($out,qr/&lt;Product&gt;/,'catalog names escaped');like($out,qr/AttachmentRow1/,'bulk attachment row mapping');unlike($out,qr/ZTAM-RMF/,'no RMF form');
$perm->{allow}=1;
{
 no warnings 'redefine';
 *FakeCI::DefinitionGet=sub {return {DefinitionRef=>{Sections=>{Meta=>{Content=>[map {{DF=>$_}} qw(ZTAM-Annex ZTAM-EventSeverity ZTAM-Source ZTAM-Status ZTAM-Application ZTAM-ContractEntitlement)]}}},DynamicFieldRef=>{map {$_=>{Name=>$_,Label=>$_,FieldType=>'Text'}} qw(ZTAM-Annex ZTAM-EventSeverity ZTAM-Source ZTAM-Status ZTAM-Application ZTAM-ContractEntitlement)}}};
 *FakeCI::ConfigItemSearch=sub {my($s,%p)=@_;return $p{Result} eq 'COUNT'?2:(1,2)};
 *FakeCI::ConfigItemGet=sub {my($s,%p)=@_;return {ConfigItemID=>$p{ConfigItemID},Class=>'SecurityAdvisory',CreateTime=>'2026-09-30 12:00:00','DynamicField_ZTAM-Annex'=>'Annex A','DynamicField_ZTAM-Status'=>'open','DynamicField_ZTAM-EventSeverity'=>'Critical','DynamicField_ZTAM-DueDate'=>'2026-10-01 00:00:00'}};
 *FakePermission::ConfigItemDiscoveryCheck=sub {my($s,%p)=@_;is($p{RequireRole},'TESSERA::CMDB::SECOPS','overview checks exact capability per record');return $p{ConfigItemID}==1};
}
my $overview=$s->Overview(CustomerUserID=>'customer',Model=>{ClassID=>1,PanelID=>1},Today=>'2026-10-01');
is(scalar @{$overview->{Rows}},1,'unauthorized records excluded from overview and export');
is_deeply([map {$_->{Name}} @{$overview->{Columns}}],[qw(ZTAM-Annex ZTAM-EventSeverity ZTAM-Source ZTAM-Status)],'role columns follow leading annex severity source and omit app/entitlement');
my @objects=(
 {CreateTime=>'2026-10-01 00:00:00','DynamicField_ZTAM-Status'=>'closed','DynamicField_ZTAM-DueDate'=>'2026-10-01','DynamicField_ZTAM-EventSeverity'=>'Critical'},
 {CreateTime=>'2026-09-30 23:59:59','DynamicField_ZTAM-Status'=>'open','DynamicField_ZTAM-DueDate'=>'2026-10-08','DynamicField_ZTAM-EventSeverity'=>'High'},
 {CreateTime=>'2026-09-01 00:00:00','DynamicField_ZTAM-Status'=>'open','DynamicField_ZTAM-DueDate'=>'2026-10-09','DynamicField_ZTAM-EventSeverity'=>'Medium'},
 {CreateTime=>'2026-08-31 23:59:59','DynamicField_ZTAM-Status'=>'open','DynamicField_ZTAM-DueDate'=>'2026-10-16'},
 {CreateTime=>'2026-10-10 00:00:00','DynamicField_ZTAM-Status'=>'open','DynamicField_ZTAM-DueDate'=>'2026-10-17'});
my @rows=map {{Object=>$_}} @objects;
my $stats=$s->Metrics(Rows=>\@rows,Today=>'2026-10-09');
is_deeply([map {$_->{Count}} @{$stats->{Metrics}}],[1,4,1,2,1,1,1],'MTD future exclusion closed overdue exclusion and inclusive seven day boundary');
$stats=$s->Metrics(Rows=>\@rows,Today=>'2026-10-01');
is($stats->{Metrics}[0]{Count},2,'first day counts previous calendar month only');
is($stats->{Metrics}[0]{Label},'New last month','first day period accurately labelled');
like($out,qr/id="AdvisoryCreate" hidden/,'new form initially hidden');
like($out,qr/AdvisoryNewToggle/,'explicit new action present');
$perm->{allow}=0;eval{$s->Overview(CustomerUserID=>'customer',Model=>{})};like($@,qr/access required/,'overview fails closed before searching');
for my $metric (@{$stats->{Metrics}}) {is($metric->{Count},scalar @{$stats->{Groups}{$metric->{Key}}},"$metric->{Key} count equals drilldown rows");}
$perm->{allow}=1;
my $detail='';ok($tt->process(\$src,{Data=>{IsDashboard=>1,SelectedMetric=>'High',SelectedLabel=>'High',Metrics=>[{Key=>'High',Label=>'High',Count=>1}],Columns=>[{Label=>'Annex'}],DetailRows=>[{Cells=>['Annex <test>']}]},Env=>sub{''}},\$detail),'dashboard drilldown renders');
like($detail,qr/AdvisoryMetric=High#AdvisoryDetails/,'card links to selected metric and below-list anchor');
like($detail,qr/id="AdvisoryDetails"/,'drilldown displayed below cards');
like($detail,qr/Annex &lt;test&gt;/,'drilldown cells escaped');
done_testing();
