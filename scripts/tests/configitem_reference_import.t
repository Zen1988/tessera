use strict;
use warnings;
use lib '.';
use Test::More;
use Kernel::System::ITSMConfigItem::Document;
{ package MockOM; sub Get { $main::mock } }
{ package Mock;
sub ItemList { my ($s,%p)=@_; return { 1=>'Product' } if $p{Class} eq 'ITSM::ConfigItem::Class'; return {2=>'Production',3=>'Operational'}; }
sub ConfigItemSearch { my ($s,%p)=@_; main::is($p{QueryCondition},0,'literal matching selected'); main::is($p{UserID},2,'caller permission identity retained'); return () if $p{Name} eq 'Missing'; return (5036,5037) if $p{Name} eq 'Duplicate'; return (5036); }
sub DefinitionGet { return {DynamicFieldRef=>{'ZTAM-EoServiceLife'=>{Name=>'ZTAM-EoServiceLife',FieldType=>'Date'},'ZTAM-Parent'=>{Name=>'ZTAM-Parent',FieldType=>'ConfigItem',Config=>{ClassIDs=>[1]}}}}; }
sub ConfigItemLookup {577}
sub ConfigItemGet {return {Name=>'E660F',VersionString=>'1','DynamicField_ZTAM-Parent'=>572};}
sub ConfigItemUpdate {my ($s,%p)=@_; $main::writes++; $main::saved=$p{'DynamicField_ZTAM-Parent'}; return 1;}
sub ActivityAdd {1}
}
our ($mock,$writes,$saved); $mock=bless {},'Mock'; $Kernel::OM=bless {},'MockOM';
my $codec=bless {},'Kernel::System::ITSMConfigItem::Document';
for my $name ('Product: Dell VxRail E Series (15G)',' Product : Dell VxRail E Series (15G)  ','Product: Name + AND & (test)') {
 is($codec->_ConfigItemReferenceIDResolve(Value=>$name,UserID=>2,DynamicFieldConfig=>{FieldType=>'ConfigItem',Config=>{ClassIDs=>[1]}}),5036,'punctuation/space reference resolves');
}
my $doc={class=>'Product',number=>'123',name=>'E660F',deployment_state=>'Production',incident_state=>'Operational',fields=>{'ZTAM-Parent'=>['Product: Dell VxRail E Series (15G)']}};
for (1..2) {$writes=0; my $r=$codec->Import(Data=>$doc,UserID=>2); ok($r->{Success},'repeat import succeeds'); is_deeply($saved,[5036],'parent retained as ID'); is($writes,1,'one update');}
for my $bad ('Missing','Duplicate') { $doc->{fields}{'ZTAM-Parent'}=['Product: '.$bad]; $writes=0; my $r=$codec->Import(Data=>$doc,UserID=>2); ok(!$r->{Success},'bad reference rejects row'); like($r->{Message},qr/ZTAM-Parent.*unresolved/,'field-specific error'); is($writes,0,'existing record untouched'); }
$doc->{fields}{'ZTAM-Parent'}=[]; $writes=0; ok($codec->Import(Data=>$doc,UserID=>2)->{Success},'explicit blank remains supported'); is_deeply($saved,[],'intentional clearing supported');
$doc->{fields}{'ZTAM-EoServiceLife'}='2027-02-30'; $writes=0;
my $badDate=$codec->Import(Data=>$doc,UserID=>2,Source=>'Excel Import');
ok(!$badDate->{Success},'invalid date rejects whole row'); is($writes,0,'invalid date leaves record untouched');
$doc->{fields}{'ZTAM-EoServiceLife'}=46660;
ok($codec->Import(Data=>$doc,UserID=>2,Source=>'Excel Import')->{Success},'serial date row imports');
done_testing();
