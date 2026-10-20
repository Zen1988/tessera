use strict;
use warnings;
use utf8;
use Test::More;
use DBI;
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::GovernanceObject::Document;
use Kernel::System::GovernanceObject::GovernanceObjectSearch;
use Kernel::System::ITSMConfigItem::Document;

{ package LiteralDocument;
  our @ISA=('Kernel::System::GovernanceObject::Document');
  sub _GeneralCatalogRestrictionIDsGet { (384) }
}
{ package LiteralOM;
  sub Get { $_[0] }
  sub ItemList { {384=>'TechnologyProfile',379=>'Application'} }
  sub GovernanceObjectSearch { my($S,%P)=@_; push @{$S->{Calls}},\%P;
    return @{$S->{ByKey}{NumberExact}||[]} if $S->{ByKey} && exists $P{NumberExact};
    return () if $S->{ByKey}; return @{$S->{IDs}||[]} }
  sub GovernanceObjectGet { {VersionID=>1934} }
  sub Log { 1 }
}
my $D=bless {},'LiteralDocument';
my $Field={FieldType=>'GovernanceObject',Config=>{ClassIDs=>[384]}};
for my $Name ('Monitoring & Observability','A + B','A OR B','A (B): C','100% literal_*','He said "yes"',"O'Brien",'Asia :: Pacific','日本語') {
    local $Kernel::OM=bless {IDs=>[913]},'LiteralOM';
    is($D->_GovernanceReferenceIDResolve(DynamicFieldConfig=>$Field,
        Value=>"  TechnologyProfile:  $Name  ",UserID=>22),913,'Literal identity resolves');
    is($Kernel::OM->{Calls}[0]{NameExact},$Name,'Entire suffix preserved; only outer whitespace trimmed');
    is_deeply($Kernel::OM->{Calls}[0]{ClassIDs},[384],'Class restriction retained');
    is($Kernel::OM->{Calls}[0]{UserID},22,'Actor retained');
}
{
    local $Kernel::OM=bless {IDs=>[913,914]},'LiteralOM';
    ok(!defined $D->_GovernanceReferenceIDResolve(DynamicFieldConfig=>$Field,
        Value=>'TechnologyProfile: Duplicate',UserID=>22),'Duplicate literal name fails closed');
    is(scalar @{$Kernel::OM->{Calls}},1,'Ambiguity cannot fall through to a different identity');
    $Kernel::OM->{Calls}=[];
    ok(!defined $D->_GovernanceReferenceIDResolve(DynamicFieldConfig=>$Field,
        Value=>'Application: Restricted',UserID=>22),'Disallowed class rejected');
    is(scalar @{$Kernel::OM->{Calls}},0,'Disallowed class performs no search');
}
{ package LiteralSearch;
  our @ISA=('Kernel::System::GovernanceObject::GovernanceObjectSearch');
  sub Permission { !$_[0]{Deny} }
}
{ package LiteralDB;
  sub Get { $_[0] }
  sub Create { $_[0] }
  sub Quote { my($S,$V,$Type)=@_; return $V if ($Type||'') eq 'Integer'; $V=~s/'/''/g; $V }
  sub QueryInCondition { my($S,%P)=@_; $P{Key}.' IN ('.join(',',@{$P{Values}}).')' }
  sub QueryCondition { die 'Literal reference reached expression parser' }
  sub Prepare { my($S,%P)=@_;$S->{SQL}=$P{SQL};1 }
  sub FetchrowArray { return }
}
my $Search=bless {},'LiteralSearch';
{
    local $Kernel::OM=bless {ByKey=>{NumberExact=>[913]}},'LiteralOM';
    is($D->_GovernanceReferenceIDResolve(DynamicFieldConfig=>$Field,
        Value=>'TechnologyProfile: GO-TECHNOLO-00000116',UserID=>22),913,'Number fallback remains supported');
    is($Kernel::OM->{Calls}[1]{NumberExact},'GO-TECHNOLO-00000116','Number fallback is also literal');
}
{
    local $Kernel::OM=bless {IDs=>[913]},'LiteralOM';
    is($D->_GovernanceReferenceIDResolve(DynamicFieldConfig=>{%$Field,FieldType=>'GovernanceObjectVersion'},
        Value=>'TechnologyProfile: Monitoring & Observability',UserID=>22),1934,'Version references retain VersionID resolution');
}
for my $Name ('Monitoring & Observability',"O'Brien",'100%_* + OR (x)', 'A "quoted" name') {
    local $Kernel::OM=bless {},'LiteralDB';
    $Search->GovernanceObjectSearch(NameExact=>$Name,ClassIDs=>[384],UserID=>22,Result=>'ARRAY');
    my $Quoted="'".$Kernel::OM->Quote($Name)."'";
    like($Kernel::OM->{SQL},qr/\Qv.name = $Quoted\E/,'Native search uses literal SQL equality');
    like($Kernel::OM->{SQL},qr/JOIN governance_object_item_version/,'Exact name joins current version');
    like($Kernel::OM->{SQL},qr/ci.class_id IN \(384\)/,'Native class boundary retained');
}
{
    local $Kernel::OM=bless {},'LiteralDB';
    $Search->GovernanceObjectSearch(NumberExact=>'GO-TECHNOLO-00000116',ClassIDs=>[384],UserID=>22,Result=>'ARRAY');
    like($Kernel::OM->{SQL},qr/ci.goid = 'GO-TECHNOLO-00000116'/,'Native number lookup uses literal equality');
}
{
    local $Kernel::OM=bless {},'LiteralDB';
    local $Search->{Deny}=1;
    $Search->GovernanceObjectSearch(NameExact=>'Monitoring & Observability',ClassIDs=>[384],UserID=>22,Result=>'ARRAY');
    ok(!$Kernel::OM->{SQL},'Denied actor cannot execute exact lookup');
}
{ package LiteralSQLite;
  our @ISA=('LiteralDB');
  sub Get { $_[1] eq 'Kernel::System::GovernanceObject' ? $_[0]{Search} : $_[0] }
  sub Prepare { my($S,%P)=@_; $S->{SQL}=$P{SQL}; $S->{Statement}=$S->{DBH}->prepare($P{SQL}); $S->{Statement}->execute(); 1 }
  sub FetchrowArray { $_[0]{Statement}->fetchrow_array() }
  sub ItemList { my($S,%P)=@_; return {1=>'Product'} if $P{Class} eq 'ITSM::ConfigItem::Class';
    return {1=>'Production'} if $P{Class} eq 'ITSM::ConfigItem::DeploymentState';
    return {1=>'Operational'} if $P{Class} eq 'ITSM::Core::IncidentState';
    return {384=>'TechnologyProfile'} }
  sub DynamicFieldGet { {} }
  sub Log { 1 }
  sub ConfigItemLookup { 90 }
  sub ConfigItemGet { {ConfigItemID=>90,VersionString=>1} }
  sub DefinitionGet { {DynamicFieldRef=>{'ZTAM-TechnologyProfile'=>{Name=>'ZTAM-TechnologyProfile',FieldType=>'GovernanceObject',Config=>{ClassIDs=>[384]}}}} }
  sub ConfigItemUpdate { my($S,%P)=@_;$S->{Writes}++;$S->{Written}=\%P;1 }
  sub ActivityAdd { 1 }
}
my $DBH=DBI->connect('dbi:SQLite:dbname=:memory:','','',{RaiseError=>1,PrintError=>0});
$DBH->do('CREATE TABLE governance_object_item (id INTEGER, goid TEXT, class_id INTEGER, last_version_id INTEGER)');
$DBH->do('CREATE TABLE governance_object_item_version (id INTEGER, name TEXT)');
$DBH->do("INSERT INTO governance_object_item VALUES (913,'GO-TECHNOLO-00000116',384,1934)");
$DBH->do('INSERT INTO governance_object_item_version VALUES (1934,?)',undef,'Monitoring & Observability');
{
    local $Kernel::OM=bless {DBH=>$DBH,Search=>$Search},'LiteralSQLite';
    for my $Name ('Monitoring & Observability',"O'Brien + SQL",'100%_* OR (x)','Colon: whole name') {
        $DBH->do('UPDATE governance_object_item_version SET name=?',undef,$Name);
        my @IDs=$Search->GovernanceObjectSearch(NameExact=>$Name,ClassIDs=>[384],UserID=>22,Result=>'ARRAY');
        is_deeply(\@IDs,[913],'Generated literal SQL executes and finds exact stored identity');
    }
    $DBH->do('UPDATE governance_object_item_version SET name=?',undef,'Monitoring & Observability');
    my $CI=Kernel::System::ITSMConfigItem::Document->new();
    my %Input=(object_type=>'ITSMConfigItem',class=>'Product',number=>'25412000919',name=>'Dell VxRail V Series (15G)',
        version=>1,deployment_state=>'Production',incident_state=>'Operational',fields=>{
        'ZTAM-TechnologyProfile'=>['TechnologyProfile: Monitoring & Observability']});
    my $Result=$CI->Import(Data=>\%Input,UserID=>22);
    ok($Result->{Success},'Actual CI importer resolves GO reference through native SQL') or diag explain $Result;
    is_deeply($Kernel::OM->{Written}{'DynamicField_ZTAM-TechnologyProfile'},[913],'CI stores resolved TechnologyProfile ID');
    $Input{fields}{'ZTAM-TechnologyProfile'}=['TechnologyProfile: Missing'];
    my $Writes=$Kernel::OM->{Writes};
    $Result=$CI->Import(Data=>\%Input,UserID=>22);
    ok(!$Result->{Success},'Missing CI profile fails closed');
    like($Result->{Message},qr/Field 'ZTAM-TechnologyProfile': Reference cannot be resolved uniquely/,'CI error identifies failing field');
    is($Kernel::OM->{Writes},$Writes,'Missing CI profile performs no update');
}
done_testing;
