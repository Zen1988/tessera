use strict;
use warnings;
use Test::More;
use Template;
use JSON::PP;
use Cwd qw(abs_path);
use lib '.';

require(abs_path('Kernel/Package/GovernanceDB/Kernel/System/TESSERA/WorkplaceSearch.pm'));
require(abs_path('Kernel/Package/GovernanceDB/Kernel/System/TESSERA/FAQAccess.pm'));
require(abs_path('Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/CustomerEntitlement.pm'));
require(abs_path('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerElasticsearchQuickResult.pm'));

{ package WorkspaceFixture;
  sub Get {my ($S,$Key)=@_; return ['external','public'] if $Key eq 'FAQ::Customer::StateTypes';return ['public'] if $Key eq 'FAQ::Public::StateTypes';return {} }
  sub PackageIsInstalled {1}
  sub DynamicFieldGet {return {ObjectType=>'FAQ',FieldType=>'GovernanceObject',ValidID=>1}}
  sub FAQGet {my ($S,%P)=@_; return (ItemID=>$P{ItemID}, Approved=>1,ValidID=>1,StateTypeID=>2,Title=>'FAQ title',Number=>'F1', 'DynamicField_FAQApplication'=>$S->{Value})}
  sub StateTypeList {return {2=>'external',3=>'public'}}
  sub ValidIDsGet {1}
  sub CustomerHasCMDBReadRole {$_[0]{Role}}
  sub ConfigItemSearch {my ($S,%P)=@_;return 3 if $P{Result} eq 'COUNT';return (1,2,3)}
  sub ConfigItemDetailAccessCheck {my ($S,%P)=@_;push @{$S->{Checks}},\%P;return $S->{Role} && $P{CustomerUserID} eq 'customer' && $P{ConfigItemID}==2}
  sub ConfigItemGet {my ($S,%P)=@_;return {ConfigItemID=>$P{ConfigItemID},Name=>'<asset>',Number=>'CI2'}}
  sub CustomerSearchDetail {return ['first','second']}
  sub CustomerUserDataGet {my ($S,%P)=@_;return (ValidID=>$P{User} eq 'first'?1:2,UserFullname=>'Person',UserEmail=>'person@example.test',UserPhone=>'123',Password=>'secret',DynamicField_Secret=>'private')}
  sub Run {my ($S,%P)=@_;push @{$S->{Requests}},\%P;return {Success=>0} if $S->{Fail};my $Key=$P{Data}{Return}[0];my @IDs=@{$P{Data}{Filter}[0]{ids}{values}};return {Success=>1,Data=>{Total=>scalar @IDs,Records=>[map {{$Key=>$_}} @IDs]}}}
}
{ package WorkspaceEntitlement;
  our @ISA=('Kernel::System::ITSMConfigItem::CustomerEntitlement');
  sub _AssignmentsGet {my ($S,%P)=@_;return [] if $P{CustomerUserID} ne 'customer' || !$S->{Assigned};return [{'DynamicField_ZTSMSupportAssignment-Application'=>[20]}]}
  sub _ReferenceObjects {my ($S,%P)=@_;return if $P{Value} eq 'bad';return ({GovernanceObjectID=>$P{Value},Class=>'Application',ZTSMStatus=>'Active'})}
}
{ package WorkspaceOM;
  sub Get {my($S,$Name)=@_;return $S->{Access} if $Name eq 'Kernel::System::TESSERA::FAQAccess';return $S->{Entitlement} if $Name eq 'Kernel::System::ITSMConfigItem::CustomerEntitlement' && $S->{Entitlement};return $S->{Fixture}}
}
my $F=bless {Role=>1,WebserviceID=>7},'WorkspaceFixture';
my $E=bless {Assigned=>1},'WorkspaceEntitlement';
my $A=Kernel::System::TESSERA::FAQAccess->new();
local $Kernel::OM=bless {Fixture=>$F,Entitlement=>$E,Access=>$A},'WorkspaceOM';
for my $Empty (undef,'',[],[''],[undef,[]]) {ok($A->ApplicationCheck(CustomerUserID=>'anyone',Value=>$Empty),'empty Application applies to everyone')}
ok($A->ApplicationCheck(CustomerUserID=>'customer',Value=>[10,20]),'any selected Application may match');
ok(!$A->ApplicationCheck(CustomerUserID=>'other',Value=>[20]),'another user cannot use assignment');
ok(!$A->ApplicationCheck(CustomerUserID=>'customer',Value=>[30]),'different Application denied');
ok(!$A->ApplicationCheck(CustomerUserID=>'customer',Value=>['bad',20]),'unresolved selected Application denies whole scope');
ok(!$A->ApplicationCheck(CustomerUserID=>'customer',Value=>{unexpected=>20}),'malformed nonempty value denied');
$E->{Assigned}=0;ok(!$A->ApplicationCheck(CustomerUserID=>'customer',Value=>[20]),'revoked assignment immediately denied');$E->{Assigned}=1;
ok($A->ApplicationCheck(Public=>1,Value=>[]),'empty public article unrestricted');
ok(!$A->ApplicationCheck(Public=>1,Value=>[20]),'public endpoint cannot reveal scoped FAQ');
ok(!$A->ApplicationCheck(Value=>[]),'missing authenticated customer denied');
$F->{Value}=[];ok($A->Get(CustomerUserID=>'other',ItemID=>1),'published unscoped FAQ is readable');
$F->{Value}=[20];ok(!$A->Get(CustomerUserID=>'other',ItemID=>1),'direct get enforces application');
ok($A->Get(CustomerUserID=>'customer',ItemID=>1),'direct get accepts matching assignment');
ok(!$A->Get(Public=>1,ItemID=>1),'public get denies application scope');
ok(!$A->Get(CustomerUserID=>'customer',ItemID=>'1 OR 1=1'),'malformed direct ID denied');

delete $Kernel::OM->{Entitlement};
my $W=Kernel::System::TESSERA::WorkplaceSearch->new();
my $R=$W->Search(Scope=>'Asset',CustomerUserID=>'customer',Query=>'needle');
is($R->{Total},1,'asset total excludes unauthorized matches');
is($R->{Rows}[0]{ID},2,'only specifically entitled readable asset returned');
is(scalar @{$F->{Checks}},3,'every candidate authorized with live detail check');
is($F->{Checks}[0]{CustomerUserID},'customer','actual session customer used');
$F->{Role}=0;$F->{Checks}=[];$R=$W->Search(Scope=>'Asset',CustomerUserID=>'customer',Query=>'needle');
is($R->{Total},0,'no CMDB read capability means no asset results');is(scalar @{$F->{Checks}},0,'missing capability avoids asset work');$F->{Role}=1;
$R=$W->Search(Scope=>'People',CustomerUserID=>'anyone',Query=>'person');
is($R->{Total},1,'any customer can find valid people across company boundaries');
is_deeply([sort keys %{$R->{Rows}[0]}],[sort qw(Type Name Description Contact)],'directory response contains only display/contact data');
is($R->{Rows}[0]{Description},'person@example.test','directory email displayed');
my $Before=scalar @{$F->{Requests}};
my $Matches=$W->_Matches(IDs=>[1..12050],Index=>'configitem',Key=>'ConfigItemID',Query=>'needle',Fields=>['Name']);
is(scalar @$Matches,12050,'all candidates beyond ES10000 result window remain reachable');
is(scalar @{$F->{Requests}}-$Before,49,'bounded250-ID batches cover complete scope');
ok(!grep({$_->{Data}{Limit}>250 || $_->{Data}{From}} @{$F->{Requests}}),'every query bounded with no deep offset');
is_deeply($F->{Requests}[0]{Data}{Return},['ConfigItemID'],'index only returns candidate identifier');
$F->{Fail}=1;$R=$W->Search(Scope=>'People',CustomerUserID=>'anyone',Query=>'person');ok($R->{Unavailable},'index failure distinct from empty successful results');$F->{Fail}=0;

# Render real TT with hostile metadata: no executable markup or URL injection.
open my $FH,'<:encoding(UTF-8)','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/TESSERAWorkplaceSearch.tt' or die $!;
my $Source=do{local $/;<$FH>};my $Out='';my $TT=Template->new();
$TT->process(\$Source,{Data=>{SearchScope=>'All',All=>1,PageSize=>7,Rows=>[{Type=>'Asset',ID=>2,Name=>'<script>alert(1)</script>',Description=>'<img onerror=bad>',Action=>'CustomerITSMConfigItemZoom',Parameter=>'ConfigItemID'}],Types=>[],Shown=>1},Env=>sub{''}},\$Out) or die $TT->error();
unlike($Out,qr/<script>|<img /,'all metadata escaped');like($Out,qr/up to 7 results per type/,'configured preview size accurately shown');like($Out,qr/aria-pressed="true"/,'active filter announced');like($Out,qr/ConfigItemID=2/,'native detail destination retained');

{package WorkspaceControllerFixture;
 sub Get {my($S,$K)=@_;return {Ticket=>{Count=>3}} if $K eq 'Elasticsearch::QuickSearchShow';return 1 if $K eq 'TESSERA::WorkplaceSearch';return 1 if $K eq 'Ticket::Frontend::CustomerDisableCompanyTicketAccess';return}
 sub GetParam {my($S,%P)=@_;return $S->{Params}{$P{Param}}}
 sub CustomerGlobalTicketRead {0}
 sub TicketSearch {my($S,%P)=@_;push @{$S->{TicketQueries}},\%P;return 8 if $P{Result} eq 'COUNT';return {Total=>8,Data=>[{1=>{Title=>'Ticket',TicketNumber=>'T1'}}]}}
 sub Search {my($S,%P)=@_;push @{$S->{Queries}},\%P;return {Total=>8,Rows=>[map {{ID=>$_,Type=>$P{Scope},Name=>'name'}} 1..8]}}
 sub Output {my($S,%P)=@_;return JSON::PP->new->encode($P{Data})}
 sub Attachment {my($S,%P)=@_;return $P{Content}}
}
my $C=bless {Params=>{FulltextES=>'needle',SearchScope=>'All',SearchPage=>1,CustomerUserID=>'forged'}},'WorkspaceControllerFixture';
$Kernel::OM=bless {Fixture=>$C},'WorkspaceOM';
my $Controller=Kernel::Modules::CustomerElasticsearchQuickResult->new(UserID=>'actual-session',UserLogin=>'actual-session',Subaction=>'SearchUpdate');
my $Data=JSON::PP->new->decode($Controller->Run());
is($Data->{SearchScope},'All','Workplace defaults to all types');is(scalar @{$Data->{Types}},4,'all four object types represented');is($Data->{PageSize},3,'custom preview size preserved');
is(scalar @{$Data->{Rows}},10,'All bounds each object type preview');
ok(!grep({$_->{CustomerUserID} ne 'actual-session'} @{$C->{Queries}}),'every service query takes session identity');
is($C->{TicketQueries}[0]{CustomerUserLoginRaw},'actual-session','ordinary ticket requester filter preserved');
ok(!exists $C->{TicketQueries}[0]{UserID},'no privileged ticket actor substitution');
$C->{Params}{SearchScope}='People';$C->{Params}{SearchPage}=999;
$Data=JSON::PP->new->decode($Controller->Run());is($Data->{Page},3,'people page clamped to last permitted page');is($Data->{Rows}[0]{ID},7,'last page begins at correct offset');is($Data->{Shown},2,'all remaining directory results reachable');
$C->{Params}{SearchScope}='untrusted';$Data=JSON::PP->new->decode($Controller->Run());is($Data->{SearchScope},'All','unknown scope cannot select backend object or index');

# Run actual bootstrap routines against persistent fake storage over all install phases.
open $FH,'<','Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm' or die $!;
my $Bootstrap=do{local $/;<$FH>};
my($Methods)=$Bootstrap=~/(sub _FAQApplicationFieldEnsure.*?)(?=sub _CustomerUserPreferenceDynamicFieldsEnsure)/s;
eval "package WorkspaceBootstrap; $Methods; 1" or die $@;
{package WorkspaceInstallFixture;
 sub DynamicFieldGet {my($S,%P)=@_;return $S->{Field} && ($S->{Field}{Name} || '') eq $P{Name} ? $S->{Field} : {}}
 sub ItemList {{9=>'Application'}}
 sub DynamicFieldAdd {my($S,%P)=@_;$S->{Field}=\%P;$S->{Added}++;return 42}
 sub EventHandlerTransaction {1}
 sub SettingGet {my($S,%P)=@_;return (IsValid=>1,EffectiveValue=>{Module=>'Kernel::System::DynamicField::ObjectType::FAQ'}) if $P{Name} eq 'DynamicFields::ObjectType###FAQ';return (IsValid=>1,EffectiveValue=>{Module=>'Kernel::System::DynamicField::Driver::GovernanceObject'}) if $P{Name} eq 'DynamicFields::Driver###GovernanceObject';return (EffectiveValue=>$S->{Screens}{$P{Name}}||{ExistingField=>2})}
 sub SettingsSet {my($S,%P)=@_;for my $Setting (@{$P{Settings}}){$S->{Screens}{$Setting->{Name}}=$Setting->{EffectiveValue}}return 1}
}
my $Install=bless {Added=>0},'WorkspaceInstallFixture';$Kernel::OM=bless {Fixture=>$Install},'WorkspaceOM';my $B=bless {},'WorkspaceBootstrap';
for my $Phase (qw(fresh upgrade reinstall future)) {ok($B->_FAQApplicationFieldEnsure(),"$Phase field install succeeds");ok($B->_FAQApplicationScreensEnsure(),"$Phase screen setup succeeds")}
is($Install->{Added},1,'all installation phases create exactly one field');is($Install->{Field}{Config}{MultiValue},1,'field supports multiple application references');is_deeply($Install->{Field}{Config}{ClassIDs},[9],'class ID resolved from live catalog');
is($Install->{Screens}{'FAQ::Frontend::AgentFAQEdit###DynamicField'}{ExistingField},2,'existing screen settings preserved');
$Install->{Screens}{'FAQ::Frontend::AgentFAQEdit###DynamicField'}{'FAQApplication'}=0;$B->_FAQApplicationScreensEnsure();is($Install->{Screens}{'FAQ::Frontend::AgentFAQEdit###DynamicField'}{'FAQApplication'},0,'administrator screen override preserved');
$Install->{Field}{ObjectType}='Ticket';eval{$B->_FAQApplicationFieldEnsure()};like($@,qr/must be an FAQ/,'conflicting existing field stops upgrade without overwriting it');

{package WorkspaceDeniedFAQ;
 sub Get {return}
}
{package WorkspaceDeniedRoute;
 sub GetParam {my($S,%P)=@_;return 1 if $P{Param} eq 'ItemID';return ''}
 sub CustomerNoPermission {'DENIED'}
 sub FAQGet {die 'Forbidden FAQ content was read before access check'}
}
my $Denied=bless {},'WorkspaceDeniedRoute';$Kernel::OM=bless {Fixture=>$Denied,Access=>bless({},'WorkspaceDeniedFAQ')},'WorkspaceOM';
for my $Name (qw(CustomerFAQZoom CustomerFAQPrint PublicFAQZoom PublicFAQPrint)) {
    require(abs_path('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/'.$Name.'.pm'));
    my $Route=bless {AccessRo=>1,UserID=>'customer',UserLogin=>'customer',Subaction=>'DownloadAttachment'},'Kernel::Modules::'.$Name;
    is($Route->Run(),'DENIED',"$Name denies before reading content, including attachment/print requests");
}
done_testing;
