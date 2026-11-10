use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib '.';
use Kernel::System::TESSERA::NetworkIntelligence;
my $Engine=Kernel::System::TESSERA::NetworkIntelligence->new(Requester=>sub {
    my %P=@_;
    return {Success=>1,Data=>{Path=>{sourceId=>$P{Data}{SourceID},destinationId=>$P{Data}{DestinationID},
        isComplete=>JSON::PP::true,collectedAt=>time(),hopCount=>0,hops=>[]}}};
});
my $Context={ActorID=>1,NetXMSWebserviceID=>2,
    Endpoints=>{source=>{NodeID=>10,Address=>'10.1.0.10',PlatformID=>50},destination=>{NodeID=>11,Address=>'10.2.0.10',PlatformID=>50}},
    ConfigItems=>[
        {Class=>'NetworkSegment',ConfigItemID=>101,Fields=>{'ZCI-CIDR'=>'10.1.0.0/24','ZCI-Zone'=>701,'ZTAM-Platform'=>50}},
        {Class=>'NetworkSegment',ConfigItemID=>102,Fields=>{'ZCI-CIDR'=>'10.2.0.0/24','ZCI-Zone'=>702,'ZTAM-Platform'=>50}},
        {Class=>'NetworkAddressPool',ConfigItemID=>103,Fields=>{'ZCI-Network'=>101,'ZCI-RangeStart'=>'10.1.0.1','ZCI-RangeEnd'=>'10.1.0.100'}},
        {Class=>'NetworkDomain',ConfigItemID=>201,Fields=>{'ZTAM-NetworkDomainType'=>301}},
        {Class=>'NetworkDomain',ConfigItemID=>202,Fields=>{'ZTAM-NetworkDomainType'=>302}},
    ],SegmentDomains=>{101=>201,102=>202},
    DomainBindings=>{201=>{Layer=>'Overlay',Enforcement=>[{InventoryName=>'nsx-a',ConfigItemID=>401,Platform=>'nsx',Context=>'default'}]},202=>{Layer=>'Underlay'}},
    Flow=>{Protocol=>'tcp',DestinationPorts=>[443]},Nodes=>{}};
sub discover { $Engine->Discover(Context=>$_[0],Data=>{Source=>'source',Destination=>'destination'},ActorID=>1) }
my $R=discover($Context);
ok($R->{Success},'Overlay enforcement resolved without a routed firewall hop');
is($R->{Data}{Candidates}[0]{Platform},'nsx','NSX selected from domain');
is($R->{Data}{Source}{Network}{DomainID},201,'Source actual domain retained');
is($R->{Data}{Destination}{Network}{DomainID},202,'Same platform can have a different destination domain');
is($R->{Data}{Source}{Network}{AddressPoolID},103,'Address pool resolved');
is($R->{Data}{Source}{Network}{NetworkZoneID},701,'CMDB zone retained separately');
ok(!exists $R->{Data}{Candidates}[0]{SourceZone},'CMDB zone never becomes a firewall zone');
for my $Case (
    ['missing domain relation',sub {delete $_[0]{SegmentDomains}{101}}],
    ['unknown domain',sub {$_[0]{SegmentDomains}{101}=999}],
    ['missing domain binding',sub {delete $_[0]{DomainBindings}{201}}],
    ['unknown layer',sub {$_[0]{DomainBindings}{201}{Layer}='VMware'}],
    ['overlay without enforcement',sub {delete $_[0]{DomainBindings}{201}{Enforcement}}],
    ['actor mismatch',sub {$_[0]{ActorID}=2}],
    ['equal subnet matches',sub {my $CI=dclone($_[0]{ConfigItems}[0]);$CI->{ConfigItemID}=104;push @{$_[0]{ConfigItems}},$CI}],
    ['overlapping pools',sub {my $CI=dclone($_[0]{ConfigItems}[2]);$CI->{ConfigItemID}=105;push @{$_[0]{ConfigItems}},$CI}],
    ['conflicting manager context',sub {$_[0]{DomainBindings}{202}{Enforcement}=[{InventoryName=>'nsx-a',ConfigItemID=>401,Platform=>'nsx',Context=>'other'}]}],
) {
    my $C=dclone($Context);$Case->[1]->($C);ok(!discover($C)->{Success},$Case->[0].' blocks');
}
my $C=dclone($Context);
push @{$C->{ConfigItems}},{Class=>'NetworkSegment',ConfigItemID=>110,Fields=>{'ZCI-CIDR'=>'10.1.0.0/16','ZTAM-Platform'=>50}};
ok(discover($C)->{Success},'Longest prefix wins over a broader subnet');
is(discover($C)->{Data}{Source}{Network}{SegmentID},101,'Most specific segment selected');
my $Scoped=dclone($Context);
my $Duplicate=dclone($Scoped->{ConfigItems}[0]);$Duplicate->{ConfigItemID}=104;
push @{$Scoped->{ConfigItems}},$Duplicate;
$Scoped->{Endpoints}{source}{SegmentID}=101;
ok(discover($Scoped)->{Success},'Backend explicit segment disambiguates overlapping address spaces');
$Scoped->{Endpoints}{source}{SegmentID}=102;
ok(!discover($Scoped)->{Success},'Explicit segment must still contain the endpoint address');
my $Evidence={Digest=>$R->{Data}{Digest},Devices=>[{%{$R->{Data}{Candidates}[0]},Status=>'COLLECTED',CollectedAt=>time(),
    Findings=>{SourceGroups=>['/infra/domains/default/groups/source'],Unresolved=>[]},EvidenceHash=>'a'x64}]};
my $Plan=$Engine->Analyze(Discovery=>$R->{Data},Evidence=>$Evidence);
ok($Plan->{Success},'Evidence interpreted');
is($Plan->{Data}{Plans}[0]{Enforcement},'DistributedFirewall','DFW analysis independent of CMDB zone');
ok(!$Plan->{Data}{ApplyReady},'Collection does not authorize device mutation');
ok(!exists $Plan->{Data}{Plans}[0]{SourceZone},'No invented NSX firewall zone');
{
    package NetworkStore;
    sub Get {$_[0]}
    sub SystemDataGet {my ($S,%P)=@_;$S->{Values}{$P{Key}}}
    sub SystemDataAdd {my ($S,%P)=@_;return if exists $S->{Values}{$P{Key}};$S->{Values}{$P{Key}}=$P{Value};1}
    sub _Get {return {ActorID=>1,HandlerKey=>'NetworkAssessment',State=>'DONE'}}
    sub WebserviceGet {return {ValidID=>1}}
    sub Run {my ($S,%P)=@_;return {Success=>1,Data=>{Path=>{sourceId=>$P{Data}{SourceID},destinationId=>$P{Data}{DestinationID},isComplete=>JSON::PP::true,collectedAt=>time(),hops=>[]}}}}
    sub Start {my ($S,%P)=@_;$S->{Launch}=\%P;return {Success=>1,ExecutionUID=>'b'x40,Status=>'PENDING'}}
}
local $Kernel::OM=bless {Values=>{}},'NetworkStore';
my %Completion=(ExecutionUID=>'a'x40,ActorID=>1,TargetID=>4,Context=>{Discovery=>$R->{Data}},ExitCode=>0,Response=>JSON::PP->new->encode($Evidence));
ok($Engine->Complete(%Completion),'Callback stores interpreted result');
ok($Engine->Complete(%Completion),'Same callback is idempotent');
ok(!$Engine->Complete(%Completion,Response=>'{}'),'Changed callback cannot replace saved evidence');
is($Engine->Get(ExecutionUID=>'a'x40,ActorID=>1)->{Plans}[0]{Enforcement},'DistributedFirewall','Owner reads saved DFW evidence');
ok(!$Engine->Get(ExecutionUID=>'a'x40,ActorID=>2),'Other actor cannot read evidence');
require Kernel::System::TESSERA::AutomationWebService;
my $LaunchContext={%$Context,AWXWebserviceID=>3,TemplateID=>42,InventoryID=>7,TargetID=>4};
my $Provider=Kernel::System::TESSERA::AutomationWebService->new(AllowedCalls=>{Network=>{NetworkAssess=>2,NetworkResult=>2}},NetworkContext=>$LaunchContext);
my $Launched=$Provider->Call(Service=>'Network',Invoker=>'NetworkAssess',Data=>{Source=>'source',Destination=>'destination'},UserID=>1);
ok($Launched->{Success},'Automation adapter discovers and queues collection');
is($Launched->{Data}{ExecutionUID},'b'x40,'Existing execution identity returned to OGL');
is($Kernel::OM->{Launch}{HandlerKey},'NetworkAssessment','Registered network continuation used');
is($Kernel::OM->{Launch}{Payload}{extra_vars}{tessera_network}{Candidates}[0]{Platform},'nsx','Resolved DFW context reaches AWX');
is($Kernel::OM->{Launch}{Payload}{limit},'localhost','Read collection runs through controlled coordinator');
ok(!$Provider->Call(Service=>'Network',Invoker=>'NetworkAssess',Data=>{Source=>'source',Destination=>'destination',Password=>'bad'},UserID=>1)->{Success},'Request cannot pass target credentials');
ok(!$Provider->Call(Service=>'Network',Invoker=>'NetworkAssess',Data=>{Source=>'source',Destination=>'destination'},UserID=>2)->{Success},'Actor cannot replace backend execution context');
done_testing();
