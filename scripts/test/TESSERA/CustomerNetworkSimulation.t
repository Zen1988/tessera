use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use Template;
use YAML::XS qw(LoadFile);
use lib '.', 'Custom', 'Kernel/Package/GovernanceDB';
use Kernel::System::TESSERA::CustomerNetworkSimulation;
use Kernel::Modules::CustomerNetworkSimulation;
{
    package SimulationOM;
    sub Get {$_[0]}
    sub CustomerUserDataGet {my ($S,%P)=@_;return (ValidID=>1) if exists $S->{Allowed}{$P{User}};return}
    sub CustomerHasCMDBReadRole {my ($S,%P)=@_;return exists $S->{Allowed}{$P{CustomerUserID}}}
    sub ConfigItemDetailAccessCheck {my ($S,%P)=@_;push @{$S->{Checks}},[$P{CustomerUserID},$P{ConfigItemID}];return $S->{Allowed}{$P{CustomerUserID}}{$P{ConfigItemID}}}
    sub GetConfig {$_[0]}
    sub GovernanceObjectSearch {my ($S,%P)=@_;return sort {$a<=>$b} grep {$S->{GO}{$_}{Class} eq $P{Classes}[0]} keys %{$S->{GO}}}
    sub GovernanceObjectGet {my ($S,%P)=@_;return Storable::dclone($S->{GO}{$P{GovernanceObjectID}}) if $S->{GO}{$P{GovernanceObjectID}};return}
    sub ConfigItemSearch {my ($S,%P)=@_;return sort {$a<=>$b} keys %{$S->{CI}}}
    sub ConfigItemGet {my ($S,%P)=@_;return Storable::dclone($S->{CI}{$P{ConfigItemID}}) if $S->{CI}{$P{ConfigItemID}};return}
    sub _ReferenceObjects {my ($S,%P)=@_;my @V=ref $P{Value} eq 'ARRAY'?@{$P{Value}}:($P{Value});return map {$S->{GO}{$_}} grep {defined $_ && $S->{GO}{$_} && $S->{GO}{$_}{Class} eq $P{Class} && $S->{GO}{$_}{ZTSMStatus} eq 'Active'} @V}
    sub DefinitionGet {return {DynamicFieldRef=>{'ZTAM-Application'=>{FieldType=>'GovernanceObject'},'ZTAM-Environment'=>{FieldType=>'GovernanceObject'},'ZTAM-NetworkAdapter'=>{FieldType=>'Set',Config=>{Include=>[{DF=>'ZTAM-IpAddress',Definition=>{FieldType=>'Text'}}]}}}}}
    sub SystemDataGet {my ($S,%P)=@_;return $S->{Data}{$P{Key}}}
    sub SystemDataAdd {my ($S,%P)=@_;die 'duplicate record' if exists $S->{Data}{$P{Key}};$S->{Data}{$P{Key}}=$P{Value};return 1}
    sub SystemDataUpdate {my ($S,%P)=@_;die 'missing record' if !exists $S->{Data}{$P{Key}};$S->{Data}{$P{Key}}=$P{Value};return 1}
    sub Prepare {return !$_[0]{LockFailure}}
    sub FetchrowArray {return (1)}
    sub WebserviceList {return $_[0]{NoConnection}?{}:$_[0]{MultipleConnections}?{12=>'Navis',13=>'Navis2'}:{12=>'Navis'}}
    sub WebserviceGet {my $S=shift;return {ValidID=>1,Config=>{Requester=>{Transport=>{Type=>'HTTP::TESSERAIntegration',Config=>{Preset=>'Navis',CustomerSimulation=>{Enabled=>1,SourceNamespace=>'collected-net',IdentityNamespace=>'CMDB'}}}}}}}
    sub GenerateRandomString {return 'N'x40}
    sub CustomerHeader {'<header>Preview</header>'}
    sub CustomerNavigationBar {''}
    sub CustomerFooter {''}
    sub Output {my ($S,%P)=@_;$S->{Captured}=$P{Data};my $TT=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard');my $HTML='';die $TT->error if !$TT->process($P{TemplateFile}.'.tt',{Data=>$P{Data},Env=>sub {'/customer.pl'}},\$HTML);return $HTML}
    sub CustomerNoPermission {'DENIED'}
    sub CustomerErrorScreen {my ($S,%P)=@_;return $P{Message}}
    sub RequestMethod {$_[0]{Method} || 'GET'}
    sub GetParam {my ($S,%P)=@_;return $S->{Params}{$P{Param}}}
    sub ChallengeTokenCheck {$_[0]{ChallengeOK}}
}
# Config Get and object-manager Get are separate native objects.
{
    package SimulationConfig;
    sub Get {my ($S,$Key)=@_;return $S->{OM}{Config}{$Key}}
    package SimulationManager;
    our @ISA=('SimulationOM');
    sub Get {my ($S,$Name)=@_;return $S->{ConfigObject} if $Name eq 'Kernel::Config';return $S->{Backend} if $Name eq 'Kernel::System::TESSERA::CustomerNetworkSimulation';return $S}
}
my $Build='20000000-0000-4000-8000-000000000001';my $Session='40000000-0000-4000-8000-000000000001';
my $OM=bless {GO=>{},CI=>{},Data=>{},Checks=>[],Allowed=>{alice=>{101=>1,102=>1,104=>1,201=>1},bob=>{103=>1}},Config=>{
    CustomerPanelUserID=>1,'TESSERA::CustomerNetworkSimulation::Enabled'=>1,
    'TESSERA::CustomerNetworkSimulation::AllowedCustomerUsers'=>['alice'],
    'TESSERA::CustomerNetworkSimulation::Bindings'=>JSON::PP->new->encode({10=>{WebserviceID=>12,BuildID=>$Build,Namespace=>'CMDB'}}),
}},'SimulationManager';
$OM->{ConfigObject}=bless {OM=>$OM},'SimulationConfig';local $Kernel::OM=$OM;
for my $E ([10,'PROD'],[20,'UAT']) {$OM->{GO}{$E->[0]}={GovernanceObjectID=>$E->[0],Class=>'Environment',Name=>$E->[1],ZTSMStatus=>'Active'}}
for my $A ([100,'Payments'],[200,'HR']) {$OM->{GO}{$A->[0]}={GovernanceObjectID=>$A->[0],Class=>'Application',Name=>$A->[1],ZTSMStatus=>'Active'}}
for my $Row ([101,'Source',10,100,'192.0.2.10','Workload'],[102,'Destination',10,200,'198.51.100.5','Workload'],[103,'SECRET-ASSET',10,200,'10.99.0.1','Workload'],[104,'UAT source',20,100,'192.0.2.20','Workload'],[201,'Firewall',10,100,'203.0.113.1','NetworkNode']) {
    my ($ID,$Name,$Env,$App,$IP,$Class)=@$Row;
    $OM->{CI}{$ID}={ConfigItemID=>$ID,ClassID=>$Class eq 'Workload'?1:2,Class=>$Class,Name=>$Name,
        'DynamicField_ZTAM-Environment'=>[$Env],'DynamicField_ZTAM-Application'=>[$App],
        'DynamicField_ZTAM-NetworkAdapter'=>[{'ZTAM-IpAddress'=>$IP}]};
}
my (@Calls,$FailTrace,$FailRecommendations);
my @Devices=map {sprintf('30000000-0000-4000-8000-%012d',$_)} (1,2,3);
my $Graph={build_id=>$Build,status=>'completed',nodes=>[map {{id=>$Devices[$_],type=>'device',external_identity=>{status=>'mapped',namespace=>'CMDB',object_class=>$_==1?'NetworkNode':'Workload',id=>''.(101,201,102)[$_]}}} (0,1,2)],connections=>[]};
my $Backend=Kernel::System::TESSERA::CustomerNetworkSimulation->new(Requester=>sub {
    my %P=@_;push @Calls,\%P;
    return {Success=>1,Data=>dclone($Graph)} if $P{Invoker} eq 'GraphGet';
    if ($P{Invoker} eq 'Trace') {die 'PRIVATE failure body' if $FailTrace;return {Success=>1,Data=>{code=>'TRACE_RESULT_READY',caller_session_id=>$P{Data}{caller_session_id},graph_build_id=>$Build,trace_session_id=>$Session,
        results=>[{source=>'192.0.2.10',destination=>'198.51.100.5',protocol=>'tcp',destination_port=>443,hops=>[map {{device_id=>$_,name=>'UNTRUSTED-NAVIS-NAME'}} @Devices],
        connection_verdict=>{status=>'unknown'},findings=>[{device_id=>$Devices[1],code=>'POLICY_COVERAGE_INCOMPLETE',message=>'PRIVATE-REMOTE-TEXT'}]}]}}}
    die 'PRIVATE recommendation error' if $FailRecommendations;
    return {Success=>1,Data=>{code=>'RECOMMENDATIONS_AVAILABLE',caller_session_id=>$P{Data}{CallerSessionID},trace_session_id=>$Session,recommendations=>[
        {status=>'ready',result=>{device_id=>$Devices[1],status=>'draft',action=>'allow',source=>'192.0.2.10',destination=>'198.51.100.5',protocol=>'tcp',destination_port=>443,reason=>'PRIVATE-REASON'}}]}};
});$OM->{Backend}=$Backend;
ok($Backend->AccessCheck(CustomerUserID=>'alice'),'valid entitled customer can explore CMDB');
ok(!$Backend->AccessCheck(CustomerUserID=>'unknown'),'unknown identity denied');
my $M=$Backend->Model(CustomerUserID=>'alice');ok(!exists $M->{EnvironmentID},'no mandatory environment scope');
is_deeply([map {$_->{ID}} @{$M->{Assets}}],[101,102,104,201],'entitled assets across environments listed');
is($M->{Assets}[0]{Endpoints}[0]{Address},'192.0.2.10','IP extracted from actual NetworkAdapter set');
is_deeply([sort map {$_->{Name}} @{$M->{Applications}}],[qw(HR Payments)],'applications derive from authorized asset references');
unlike(JSON::PP->new->encode($M),qr/SECRET-ASSET|10\.99\.0\.1/,'hidden details never returned');
my $UAT=$Backend->Model(CustomerUserID=>'alice',EnvironmentID=>20);is_deeply([map {$_->{ID}} @{$UAT->{Assets}}],[101,102,104,201],'legacy environment parameter does not control endpoint scope');
is_deeply([map {$_->{ID}} @{$Backend->Model(CustomerUserID=>'alice',EnvironmentID=>999)->{Assets}}],[101,102,104,201],'forged environment never broadens entitlement');
is($Backend->Model(CustomerUserID=>'bob')->{CanSimulate},0,'CMDB read is separate from simulation authorization');
my %Input=(CustomerUserID=>'alice',SourceEndpoint=>'101@0',DestinationEndpoint=>'102@0',Protocol=>'tcp',DestinationPort=>443,SubmissionToken=>'a'x40);
my $ID=$Backend->Analyze(%Input);
is_deeply([map {$_->{Invoker}} @Calls],[qw(Trace GraphGet RecommendationsGet)],'TESSERA owns all Navis calls');
ok(!grep({exists $_->{ActorID}} @Calls),'customer identity never becomes agent ActorID');
my $Result=$Backend->Result(CustomerUserID=>'alice',AnalysisID=>$ID)->{Result};
is($Result->{Status},'ANALYZED','analysis evidence persisted');
is_deeply([map {$_->{ID}} @{$Result->{Hops}}],[101,201,102],'Navis devices map back to caller-native CMDB IDs');
is(scalar @{$Result->{Edges}},2,'only evidence-backed hop sequence creates edges');
is($Result->{Recommendations}[0]{Name},'Firewall','recommendation uses authorized CMDB label');
unlike(JSON::PP->new->encode($Result),qr/PRIVATE|UNTRUSTED|30000000|Authentication|WebserviceID|Namespace/,'presentation omits remote identifiers, text and credentials');
is($Backend->Analyze(%Input),$ID,'same submission returns same saved analysis');is(scalar @Calls,3,'duplicate submission cannot replay trace');
ok(!eval {$Backend->Analyze(%Input,DestinationPort=>80);1},'changed content cannot reuse submission token');
ok(!eval {$Backend->Result(CustomerUserID=>'bob',AnalysisID=>$ID);1},'cross-customer result ID denied');
ok(!eval {$Backend->Analyze(%Input,SourceEndpoint=>'103@0',SubmissionToken=>'b'x40);1},'hidden source asset cannot be selected by ID');
ok(grep({$_->{ID}==104} @{$M->{Assets}}),'UAT source can be chosen without changing environment');
ok(!eval {$Backend->Analyze(%Input,SourceApplication=>200,SubmissionToken=>'b'x40);1},'application and endpoint mismatch denied');
ok(!eval {$Backend->Analyze(%Input,DestinationEndpoint=>'192.0.2.10',SubmissionToken=>'b'x40);1},'raw IP cannot bypass authorized endpoint resolution');
ok(!eval {$Backend->Analyze(%Input,DestinationPort=>'',SubmissionToken=>'b'x40);1},'empty transport port is rejected server-side');
delete $OM->{Allowed}{alice}{201};my $Hidden=$Backend->Result(CustomerUserID=>'alice',AnalysisID=>$ID)->{Result};
my ($Masked)=grep {$_->{Restricted}} @{$Hidden->{DisplayNodes}};
ok($Masked,'restricted hop remains an anonymous graph vertex');is($Masked->{ApplicationName},'Payments','restricted node discloses only approved Application affiliation');
is(scalar @{$Hidden->{DisplayEdges}},2,'anonymous graph preserves candidate shape');unlike(JSON::PP->new->encode($Masked),qr/Firewall|203\.0\.113|201|30000000/,'grey node contains no hidden device identity/address/class');
ok($Hidden->{Withheld},'revoked intermediate hop withholds path');is(scalar @{$Hidden->{Edges}},0,'no edge leaks through hidden hop');
is(scalar @{$Hidden->{Recommendations}},0,'no recommendations leak through hidden path');
unlike(JSON::PP->new->encode($Hidden),qr/Firewall|201|PRIVATE/,'revoked intermediate details disappear on reload');
$OM->{Allowed}{alice}{201}=1;delete $OM->{Allowed}{alice}{101};
ok(!eval {$Backend->Result(CustomerUserID=>'alice',AnalysisID=>$ID);1},'revoked endpoint blocks saved analysis access');$OM->{Allowed}{alice}{101}=1;
$OM->{GO}{10}{Name}='Production';
is(scalar @{$Backend->Model(CustomerUserID=>'alice')->{Assets}},4,'PROD name is not a selection dependency');$OM->{GO}{10}{Name}='PROD';
ok(!exists $Calls[0]{Data}{graph_build_id},'on-demand trace sends no pinned build');
is($Calls[0]{Data}{namespace},'collected-net','collection namespace inherited from integration');
is($Calls[1]{Data}{BuildID},$Build,'graph read uses exact trace-selected UUID');
$OM->{MultipleConnections}=1;ok(!eval {$Backend->_binding();1},'multiple configured connections fail closed');delete $OM->{MultipleConnections};
$OM->{NoConnection}=1;ok(!eval {$Backend->_binding();1},'missing integration never falls back to legacy bindings');delete $OM->{NoConnection};
my $Clone=dclone($OM->{CI}{101});$Clone->{ConfigItemID}=106;$OM->{CI}{106}=$Clone;$OM->{Allowed}{alice}{106}=1;
ok(!eval {$Backend->Analyze(%Input,SubmissionToken=>'b'x40);1},'duplicate IP in one environment is ambiguous');delete $OM->{CI}{106};delete $OM->{Allowed}{alice}{106};
$OM->{Config}{'TESSERA::CustomerNetworkSimulation::AllowedCustomerUsers'}=[];
ok(!eval {$Backend->Result(CustomerUserID=>'alice',AnalysisID=>$ID);1},'revoking simulation grant blocks old results');$OM->{Config}{'TESSERA::CustomerNetworkSimulation::AllowedCustomerUsers'}=['alice'];
ok(!eval {$Backend->Analyze(%Input,SubmissionToken=>'b'x40);1},'per-customer cooldown limits fresh requests');
for my $Key (grep {/::Rate::/} keys %{$OM->{Data}}) {$OM->{Data}{$Key}=0}
$FailTrace=1;my $Lost=$Backend->Analyze(%Input,SubmissionToken=>'b'x40);$FailTrace=0;
is($Backend->Result(CustomerUserID=>'alice',AnalysisID=>$Lost)->{Result}{Status},'TRACE_INTENT','uncertain trace retains durable intent');
my $CallsBefore=scalar @Calls;$Backend->Analyze(%Input,SubmissionToken=>'b'x40);is(scalar @Calls,$CallsBefore,'uncertain trace never replays on resubmission');
ok(!eval {$Backend->Refresh(CustomerUserID=>'alice',AnalysisID=>$Lost);1},'cannot refresh an unsaved trace');
$OM->{Method}='GET';$OM->{Params}={Subaction=>'Analyze'};$OM->{UserChallengeToken}='real';$OM->{ChallengeOK}=1;
my $Page=Kernel::Modules::CustomerNetworkSimulation->new(UserID=>'alice');
like($Page->Run(),qr/protected POST/,'customer UI rejects GET analysis');
$OM->{Method}='POST';$OM->{Params}{ChallengeToken}='wrong';like($Page->Run(),qr/protected POST/,'customer UI rejects CSRF mismatch');
$OM->{Params}{ChallengeToken}='real';$OM->{ChallengeOK}=0;like($Page->Run(),qr/Invalid request token/,'native challenge verification enforced');
$OM->{Params}={};$OM->{Method}='GET';my $OldName=$OM->{CI}{101}{Name};$OM->{CI}{101}{Name}='</script><img src=x onerror=bad>';
my $FullPage=$Page->Run();like($FullPage,qr/Explore a connection/,'actual customer module renders workspace');
unlike($OM->{Captured}{Payload},qr/<\/script>|<img/,'JSON payload escapes script-breaking asset names');
unlike($FullPage,qr/<img src=x/,'rendered module never executes asset labels');$OM->{CI}{101}{Name}=$OldName;
my $BeforeRefresh=scalar @Calls;$Backend->Refresh(CustomerUserID=>'alice',AnalysisID=>$ID);
is(scalar @Calls,$BeforeRefresh+1,'recommendation refresh makes one remote call');is($Calls[-1]{Invoker},'RecommendationsGet','refresh cannot replay the trace POST');
ok(!eval {$Backend->Refresh(CustomerUserID=>'alice',AnalysisID=>$ID);1},'recommendation polling is bounded');
my $Stored=$Backend->_read($ID);$Stored->{Trace}{results}[0]{coverage}{devices}=[{device_id=>'99999999-0000-4000-8000-000000000000'}];$Backend->_store($Stored);
ok($Backend->Result(CustomerUserID=>'alice',AnalysisID=>$ID)->{Result}{Withheld},'hidden devices in nested coverage also withhold the path');
delete $Stored->{Trace}{results}[0]{coverage};$Backend->_store($Stored);
my $TT=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard');my $HTML='';
my $Selection={Protocol=>'tcp',DestinationPort=>443,SourceApplication=>'100',SourceSystem=>'101',SourceEndpoint=>'101@0',DestinationApplication=>'200',DestinationSystem=>'102',DestinationEndpoint=>'102@0'};
my $Payload=JSON::PP->new->canonical->encode({Assets=>$M->{Assets},Result=>$Result,Selection=>$Selection});$Payload=~s/</\\u003c/g;
ok($TT->process('CustomerNetworkSimulation.tt',{Data=>{%$M,Selection=>$Selection,Result=>$Result,Payload=>$Payload,SubmissionToken=>'s'x40},Env=>sub {'/customer.pl'}},\$HTML),'workspace renders');
unlike($HTML,qr/SimulationEnvironment|name="EnvironmentID"/,'customer form has no environment selector');
like($HTML,qr/<caption>Authorized main-candidate path/,'accessible path table provided');
like($HTML,qr/aria-labelledby="SimulationGraphTitle"/,'SVG has accessible title');
unlike($HTML,qr/PRIVATE|SECRET-ASSET/,'template has no hidden evidence');
my $Safe=$HTML;ok($TT->process('CustomerNetworkSimulation.tt',{Data=>{%$M,Error=>'<script>injected</script>',Selection=>{},Payload=>'{}'},Env=>sub {'/customer.pl'}},\$Safe),'error state renders');
unlike($Safe,qr/<script>injected/,'provider/user text is escaped');
for my $File ('Export/ConfigItem_2026-10-19-01.yml') {
    my $Export=LoadFile($File);for my $Class (qw(Workload NetworkNode)) {
        my ($Def)=grep {($_->{Class}{Name} || '') eq $Class} @$Export;
        ok($Def->{DynamicFields}{'ZTAM-Application'} && $Def->{DynamicFields}{'ZTAM-Environment'},"$Class exact exported reference fields exist");
        my @IP=grep {($_->{DF} || '') eq 'ZTAM-IpAddress'} @{$Def->{DynamicFields}{'ZTAM-NetworkAdapter'}{Config}{Include}};
        is(scalar @IP,1,"$Class uses exported nested IpAddress field");
    }
}
# Retain a synthetic full-page preview for visual QA, with page-owned assets.
open my $Preview,'>','.artifacts/customer-network-simulation-preview.html' or die $!;
print {$Preview} '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Network simulation preview</title><link rel="stylesheet" href="../var/httpd/htdocs/skins/Customer/default/css/TESSERA.Customer.NetworkSimulation.css"><body>'.$HTML.'<script src="../var/httpd/htdocs/js/TESSERA.Customer.NetworkSimulation.js"></script></body></html>';close $Preview;
my $Named=Kernel::System::TESSERA::NavisPlan->new()->Request(Flow=>{source=>'192.0.2.10',destination=>'198.51.100.5',protocol=>'tcp',destination_port=>443,action=>'allow'},OnDemand=>1,TopologyName=>'application 1',CallerID=>'tessera-'.('c'x40));
is($Named->{topology_name},'application 1','stable application name sent directly to Navis');ok(!exists $Named->{graph_build_id},'named resolution does not pin an old UUID');
my $GraphWithGap=dclone($Graph);push @{$GraphWithGap->{nodes}},{id=>'unmanaged:50000000-0000-4000-8000-000000000001',type=>'unmanaged',placeholder=>JSON::PP::true,device_id=>undef};
my $Identities=Kernel::System::TESSERA::NavisPlan->new()->Graph($GraphWithGap,$Build);
is(scalar keys %$Identities,3,'unmanaged graph placeholder never becomes a device identity');
my $Visibility={nodes=>[
 {id=>$Devices[0],device_id=>$Devices[0],type=>'device',trace_status=>'visited'},
 {id=>'unmanaged:50000000-0000-4000-8000-000000000001',type=>'unmanaged',placeholder=>JSON::PP::true,device_id=>undef,name=>'PRIVATE GAP LABEL',addresses=>['PRIVATE ADDRESS']},
 {id=>$Devices[2],device_id=>$Devices[2],type=>'device',trace_status=>'not_traced'}],connections=>[
 {source=>$Devices[0],target=>'unmanaged:50000000-0000-4000-8000-000000000001',kind=>'visibility_gap'},
 {source=>'unmanaged:50000000-0000-4000-8000-000000000001',target=>$Devices[2],kind=>'untraced_remainder'}]};
my $Projection=$Backend->_graphProjection({Graph=>$GraphWithGap,Binding=>{Namespace=>'CMDB'}},{visibility_graph=>$Visibility},{$Devices[0]=>$M->{Assets}[0],$Devices[2]=>$M->{Assets}[1]});
ok($Projection->{HasVisibilityGap},'missing network is distinct from restricted device');
unlike(JSON::PP->new->encode($Projection),qr/PRIVATE|unmanaged:|50000000/,'visibility projection removes raw gap identifiers/addresses/reasons');
is($Projection->{DisplayNodes}[2]{TraceStatus},'not_traced','known destination beyond gap is not claimed evaluated');
$OM->{GO}{100}{DynamicField_Navis}='application 1';
my $ConfiguredModel=$Backend->Model(CustomerUserID=>'alice');my ($ConfiguredApp)=grep {$_->{ID}==100} @{$ConfiguredModel->{Applications}};ok($ConfiguredApp->{HasTopology},'configured Application is available as a topology choice');
my $AppBinding=$Backend->_applicationBinding($Backend->_binding(),$M,100);is($AppBinding->{GraphName},'application 1','Application Navis field supplies stable topology name');is($AppBinding->{ApplicationID},100,'binding records authorized Application context');
ok(!eval {$Backend->_applicationBinding($Backend->_binding(),$M,999);1},'unlisted Application ID cannot select a graph');
ok(!eval {$Backend->_applicationBinding($Backend->_binding(),$M,200);1},'Application with no Navis name cannot silently use default');
for my $Key (grep {/::Rate::/} keys %{$OM->{Data}}) {$OM->{Data}{$Key}=0}
my $NamedID=$Backend->Analyze(%Input,TopologyApplicationID=>100,SubmissionToken=>'m'x40);
my $SavedNamed=$Backend->_read($NamedID);is($SavedNamed->{SubmittedRequest}{topology_name},'application 1','actual named request stored without pinning stale UUID');ok(!exists $SavedNamed->{SubmittedRequest}{graph_build_id},'named Application request has no fixed graph UUID');
is($SavedNamed->{Request}{graph_build_id},$Build,'resolved graph UUID remains immutable per-trace evidence');
is($Backend->Result(CustomerUserID=>'alice',AnalysisID=>$NamedID)->{Result}{TopologyApplicationID},100,'saved named trace restores its explicit Application context');
$OM->{GO}{100}{DynamicField_Navis}='changed label';ok(!eval {$Backend->Result(CustomerUserID=>'alice',AnalysisID=>$NamedID);1},'changed Application mapping cannot silently relabel saved evidence');$OM->{GO}{100}{DynamicField_Navis}='application 1';
# Additional full-page fixtures exercise grey/unknown graph presentation.
for my $Case (['restricted',$Hidden],['gap',{%$Result,%$Projection}]) {
    my ($Name,$View)=@$Case;my $JSON=JSON::PP->new->canonical->encode({Assets=>$M->{Assets},Result=>$View,Selection=>{SourceEndpoint=>'101@0',DestinationEndpoint=>'102@0',SourceApplication=>'100',DestinationApplication=>'200',SourceSystem=>'101',DestinationSystem=>'102',Protocol=>'tcp',DestinationPort=>443}});
    $JSON=~s/</\\u003c/g;my $Rendered='';
    die $TT->error if !$TT->process('CustomerNetworkSimulation.tt',{Data=>{%$M,Result=>$View,Selection=>JSON::PP->new->decode($JSON)->{Selection},Payload=>$JSON,SubmissionToken=>'v'x40},Env=>sub {'/customer.pl'}},\$Rendered);
    open my $P,'>','.artifacts/network-'.$Name.'-preview.html' or die $!;
    print {$P} '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="stylesheet" href="../var/httpd/htdocs/skins/Customer/default/css/TESSERA.Customer.NetworkSimulation.css"><body>'.$Rendered.'<script src="../var/httpd/htdocs/js/TESSERA.Customer.NetworkSimulation.js"></script></body></html>';close $P;
}
# Browser-supplied graph selectors are outside the customer input contract.
for my $Key (grep {/::Rate::/} keys %{$OM->{Data}}) {$OM->{Data}{$Key}=0}
my $InjectedID=$Backend->Analyze(%Input,SubmissionToken=>'z'x40,GraphID=>'attacker',BuildID=>'attacker',graph_build_id=>'attacker',topology_name=>'attacker',TopologyName=>'attacker');
my $Injected=$Backend->_read($InjectedID)->{SubmittedRequest};
ok(!exists $Injected->{graph_build_id},'customer cannot inject a graph UUID');
ok(!exists $Injected->{topology_name},'customer cannot inject a graph label into default trace');
unlike($HTML,qr/name=["'](?:graph_build_id|BuildID|GraphID|TopologyName|topology_name)["']/i,'customer form has no raw graph selector input');

done_testing();
