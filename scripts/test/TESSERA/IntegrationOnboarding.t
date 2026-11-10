use strict;
use warnings;
use utf8;
use Test::More;
use JSON::PP ();
use MIME::Base64 qw(decode_base64);
use Storable qw(dclone);
use lib '.', 'Custom', 'Kernel/Package/GovernanceDB';
use Kernel::System::TESSERA::IntegrationAuth;
use Kernel::System::TESSERA::IntegrationOnboarding;
use Kernel::GenericInterface::Transport::HTTP::TESSERAIntegration;
use Kernel::System::TESSERA::NavisPlan;
use Kernel::System::TESSERA::NavisControl;
use Kernel::GenericInterface::Invoker::TESSERA::Request;
use Template;
use POSIX qw(strftime);
use Kernel::Modules::AgentTESSERAIntegration;
use Kernel::GenericInterface::Transport;
use Kernel::GenericInterface::Invoker;
my $Now=1000;my $Secret='s :+é';my @HTTP;my $TokenNumber=0;
my $A=Kernel::System::TESSERA::IntegrationAuth->new(Clock=>sub {$Now},Secret=>sub {$Secret},HTTP=>sub {
    my %P=@_;push @HTTP,\%P;return {Status=>200,Body=>JSON::PP->new->encode({access_token=>'opaque-'.++$TokenNumber,token_type=>'Bearer',expires_in=>300})};
});
my $Auth={Provider=>'ClientCredentialsBasic',TokenURL=>'https://navis.test/nauth/token',ClientID=>'client :+é',SecretName=>'navis-client',Scope=>'graph:read analysis:run'};
is($A->Token(Profile=>$Auth,Identity=>'one'),'opaque-1','token acquired');
is(decode_base64(substr($HTTP[0]{Headers}{Authorization},6)),'client+%3A%2B%C3%A9:s+%3A%2B%C3%A9','credentials separately form encoded before Basic');
is($HTTP[0]{Body},'grant_type=client_credentials&scope=graph%3Aread+analysis%3Arun','exact token form');
unlike($HTTP[0]{Body},qr/client_secret|client_id/,'credentials absent from form');
is($A->Token(Profile=>$Auth,Identity=>'one'),'opaque-1','process cache reused');
is(scalar @HTTP,1,'no extra token request');$Now+=271;
is($A->Token(Profile=>$Auth,Identity=>'one'),'opaque-2','early refresh');
$Secret='rotated';is($A->Token(Profile=>$Auth,Identity=>'one'),'opaque-3','mounted rotation invalidates cache');
is($A->Token(Profile=>$Auth,Identity=>'two'),'opaque-4','connection isolation');
my $Other={%$Auth,Scope=>'graph:read'};is($A->Token(Profile=>$Other,Identity=>'one'),'opaque-5','scope isolation');
for my $URL ('http://bad.test/token','https://user:pw@bad.test/token','https://bad.test/token#fragment','https://bad.test/token?q=secret') {
    ok(!eval {$A->Validate({%$Auth,TokenURL=>$URL});1},'unsafe token endpoint rejected');
}
ok(!eval {$A->Validate({%$Auth,Provider=>'Arbitrary::Module'});1},'unregistered provider rejected');
ok(!eval {$A->Validate({%$Auth,SecretName=>'../other'});1},'secret traversal rejected');
for my $Bad ({access_token=>'x',token_type=>'Bearer',expires_in=>0},{access_token=>"bad\ntoken",token_type=>'Bearer',expires_in=>300},{access_token=>'x',token_type=>'Basic',expires_in=>300},{error=>'invalid_client'}) {
    my $B=Kernel::System::TESSERA::IntegrationAuth->new(Secret=>sub {'secret'},HTTP=>sub {{Status=>200,Body=>JSON::PP->new->encode($Bad)}});
    ok(!eval {$B->Token(Profile=>$Auth,Identity=>'invalid',Invalidate=>1);1},'invalid token response rejected');
}
{
    package IntegrationOM;
    sub Get {$_[0]}
    sub Require {my ($S,$Module)=@_;my $File=$Module;$File=~s{::}{/}g;return eval {require "$File.pm";1}}
    sub GetUserData {return (ValidID=>1)}
    sub PermissionCheck {my ($S,%P)=@_;$P{UserID}==7}
    sub Prepare {return 1}
    sub FetchrowArray {return (1)}
    sub WebserviceList {my ($S)=@_;return {map {$_=>$S->{WS}{$_}{Name}} keys %{$S->{WS}}}}
    sub WebserviceGet {my ($S,%P)=@_;return dclone($S->{WS}{$P{ID}}) if $S->{WS}{$P{ID}};return}
    sub WebserviceAdd {my ($S,%P)=@_;my $ID=++$S->{Next};$S->{WS}{$ID}={ID=>$ID,%P};return $ID}
    sub WebserviceUpdate {my ($S,%P)=@_;$S->{WS}{$P{ID}}={%P};return 1}
    sub SystemDataGet {my ($S,%P)=@_;return $S->{Data}{$P{Key}}}
    sub SystemDataAdd {my ($S,%P)=@_;die if exists $S->{Data}{$P{Key}};$S->{Data}{$P{Key}}=$P{Value};return 1}
    sub SystemDataUpdate {my ($S,%P)=@_;$S->{Data}{$P{Key}}=$P{Value};return 1}
    sub _Get {my ($S,$ID)=@_;return $S->{Rows}{$ID}}
    sub Start {my ($S,%P)=@_;push @{$S->{Launches}},\%P;return {Success=>1,ExecutionUID=>sprintf('%040x',scalar @{$S->{Launches}})}}
    sub dclone {Storable::dclone($_[0])}
}
local $Kernel::OM=bless {WS=>{},Next=>10,Data=>{},Rows=>{},Launches=>[]},'IntegrationOM';
my $B=Kernel::System::TESSERA::IntegrationOnboarding->new(Auth=>$A);
my $Connection={Preset=>'Navis',Origin=>'https://navis.test',InstanceID=>'instance',Authentication=>$Auth};
ok(!eval {$B->Save(UserID=>8,Name=>'Test',Connection=>$Connection);1},'unauthorized backend save denied');
my $ID=$B->Save(UserID=>7,Name=>'Navis',Connection=>$Connection);
is($Kernel::OM->{WS}{$ID}{ValidID},2,'new service disabled');
is($Kernel::OM->{WS}{$ID}{Config}{Requester}{Transport}{Type},'HTTP::TESSERAIntegration','native web service with safe transport');
ok(!eval {$B->Save(UserID=>7,Name=>'Navis',Connection=>$Connection);1},'duplicate create rejected instead of silently adopting');
is($B->Save(UserID=>7,ID=>$ID,Name=>'Navis',Connection=>$Connection,Enabled=>1),$ID,'same service explicitly updated');
is(scalar keys %{$Kernel::OM->{WS}},1,'repeated save creates no duplicate');
unlike(JSON::PP->new->encode($Kernel::OM->{WS}),qr/opaque-|rotated|client_secret/,'stored service contains no credentials or tokens');
my $Config=$Kernel::OM->{WS}{$ID}{Config}{Requester}{Transport}{Config};
my @Calls;my @Statuses=(401,200);
my $TA=Kernel::System::TESSERA::IntegrationAuth->new(Secret=>sub {'private'},HTTP=>sub {
    my %P=@_;push @Calls,\%P;
    return {Status=>200,Body=>' {"access_token":"private-token","token_type":"Bearer","expires_in":300}'} if $P{URL}=~/token$/;
    return {Status=>shift(@Statuses) || 200,Body=>'{"ok":true}'};
});
my $T=Kernel::GenericInterface::Transport::HTTP::TESSERAIntegration->new(TransportConfig=>{Config=>$Config},Auth=>$TA);
ok($T->RequesterPerformRequest(Operation=>'GraphGet',Data=>{BuildID=>'abc'})->{Success},'GET refreshes once after 401');
is(scalar(grep {$_->{URL}=~/\/graph$/} @Calls),2,'GET attempted twice');
@Calls=();@Statuses=(401,200);
ok(!$T->RequesterPerformRequest(Operation=>'Trace',Data=>{source=>'x'})->{Success},'POST 401 not automatically replayed');
is(scalar(grep {$_->{URL}=~/traces$/} @Calls),1,'single mutating request');
@Calls=();ok(!$T->RequesterPerformRequest(Operation=>'GraphGet',Data=>{BuildID=>'../escape'})->{Success},'path injection rejected');
is(scalar @Calls,0,'invalid input never reaches network');
@Statuses=(403);ok(!$T->RequesterPerformRequest(Operation=>'GraphGet',Data=>{BuildID=>'abc'})->{Success},'403 fails without refresh loop');
my $Planner=Kernel::System::TESSERA::NavisPlan->new();
open my $FH,'<','examples/navis/fixture-input.json' or die $!;local $/;my $Fixture=JSON::PP->new->decode(<$FH>);close $FH;
my $Q=$Planner->Request(Flow=>$Fixture->{flow},BuildID=>$Fixture->{graph_build_id},CallerID=>'tessera-'.('a'x40));
my $F=$Fixture->{fixture};$F->{trace}{caller_session_id}=$Q->{caller_session_id};$F->{recommendations}{caller_session_id}=$Q->{caller_session_id};
my %PlanArgs=(Request=>$Q,Trace=>$F->{trace},Recommendations=>$F->{recommendations},Graph=>$F->{graph},Snapshot=>$Fixture->{cmdb_snapshot},Namespace=>$Fixture->{identity_namespace},Action=>'allow');
my $Plan=$Planner->Prepare(%PlanArgs);
is(scalar @{$Plan->{Plans}},3,'TESSERA compiles three vendor intents from Navis evidence');
is($Plan->{Plans}[0]{Target}{ConfigItemID},'000012313213','opaque CMDB identity preserved');
ok(!$Plan->{ApplyReady},'recommendations do not authorize apply');
is($Plan->{Summary}[0]{Status},'unknown','unknown analysis preserved');
my $Wrong=dclone($F->{graph});$Wrong->{nodes}[1]{external_identity}=$Wrong->{nodes}[0]{external_identity};
ok(!eval {$Planner->Prepare(%PlanArgs,Graph=>$Wrong);1},'ambiguous graph identities rejected');
my $None=$Planner->Prepare(%PlanArgs,Snapshot=>[]);is(scalar @{$None->{Plans}},0,'no CMDB authorization means no targets');
my @Navis;my $Controller=Kernel::System::TESSERA::NavisControl->new(Async=>$Kernel::OM,Requester=>sub {
    my %P=@_;push @Navis,\%P;my %Reply=(GraphGet=>$F->{graph},Trace=>$F->{trace},RecommendationsGet=>$F->{recommendations},Ingest=>{ingestion_id=>'10000000-0000-4000-8000-000000000001',status=>'pending_identity'});
    my $D=dclone($Reply{$P{Invoker}});$D->{caller_session_id}=$P{Data}{caller_session_id} if $P{Invoker} eq 'Trace';
    $D->{caller_session_id}=$P{Data}{CallerSessionID} if $P{Invoker} eq 'RecommendationsGet';return {Success=>1,Data=>$D};
});
my $Context={ActorID=>7,NavisWebserviceID=>$ID,BuildID=>$Fixture->{graph_build_id},TargetType=>'Ticket',TargetID=>25,Snapshot=>$Fixture->{cmdb_snapshot},Namespace=>'CMDB'};
my $Analyzed=$Controller->Analyze(Context=>$Context,ActorID=>7,Data=>$Fixture->{flow});
ok($Analyzed->{Success},'TESSERA performs Navis analysis');
is_deeply([map {$_->{Invoker}} @Navis],[qw(GraphGet Trace RecommendationsGet)],'TESSERA controls context, trace and recommendations');
is(scalar @{$Kernel::OM->{Launches}},0,'analysis never launches AWX');
my $AnalysisID=$Analyzed->{Data}{AnalysisID};my $Saved=$Controller->Get(Context=>$Context,ActorID=>7,AnalysisID=>$AnalysisID)->{Data};
ok(!eval {$Controller->Execute(Context=>$Context,ActorID=>7,AnalysisID=>$AnalysisID);1},'plan requires independent digest authorization');
$Context->{ApprovedPlanDigest}=$Saved->{PlanDigest};
$Context->{Apply}={AWXWebserviceID=>99,TemplateID=>42,InventoryID=>7,Limit=>'approved-firewalls'};
$Context->{Readback}={AWXWebserviceID=>99,TemplateID=>43,InventoryID=>7,Limit=>'approved-firewalls'};
my $Run=$Controller->Execute(Context=>$Context,ActorID=>7,AnalysisID=>$AnalysisID);
ok($Run->{Success},'authorized exact plan dispatches AWX work');
my $Work=$Kernel::OM->{Launches}[0]{Payload}{extra_vars}{tessera_work};
is($Work->{Phase},'APPLY','AWX receives apply instruction only');
ok(!exists $Work->{Graph} && !exists $Work->{Recommendations} && !exists $Work->{Authentication},'AWX receives no intelligence inputs or credentials');
ok(!eval {$Controller->Execute(Context=>$Context,ActorID=>7,AnalysisID=>$AnalysisID);1},'duplicate dispatch rejected');
my $UID=$Run->{ExecutionUID};$Kernel::OM->{Rows}{$UID}={State=>'RUNNING',HandlerKey=>'NavisControl',ActorID=>7,TargetType=>'Ticket',TargetID=>25,ExitCode=>0,Continuation=>JSON::PP->new->encode({AnalysisID=>$AnalysisID,Phase=>'APPLY'}),Response=>JSON::PP->new->encode({AnalysisID=>$AnalysisID,PlanDigest=>$Saved->{PlanDigest},Simulation=>JSON::PP::false,Status=>'APPLIED'})};
ok($Controller->Completed(ExecutionUID=>$UID),'authenticated apply completion triggers TESSERA readback');
is($Kernel::OM->{Launches}[1]{Payload}{extra_vars}{tessera_work}{Phase},'READBACK','TESSERA requests separate observed firewall sync');
is(scalar @Navis,3,'no ingestion before readback');
my $ReadUID=sprintf('%040x',2);
my $Envelope={source=>{namespace=>'CMDB',object_class=>'NetworkNode',external_device_id=>'000012313213'},adapter=>{name=>'navis',input_format=>'normalized-json',format_version=>'1'},data_type=>'policy',collected_at=>strftime('%Y-%m-%dT%H:%M:%SZ',gmtime),completeness=>'partial',payload=>{entries=>[]}};
$Kernel::OM->{Rows}{$ReadUID}={State=>'RUNNING',HandlerKey=>'NavisControl',ActorID=>7,TargetType=>'Ticket',TargetID=>25,ExitCode=>0,Continuation=>JSON::PP->new->encode({AnalysisID=>$AnalysisID,Phase=>'READBACK'}),Response=>JSON::PP->new->encode({AnalysisID=>$AnalysisID,PlanDigest=>$Saved->{PlanDigest},Envelopes=>[$Envelope]})};
ok($Controller->Completed(ExecutionUID=>$ReadUID),'TESSERA stages authenticated readback in Navis');
is($Navis[-1]{Invoker},'Ingest','TESSERA sends observed rules to Navis');
is($Controller->Get(Context=>$Context,ActorID=>7,AnalysisID=>$AnalysisID)->{Data}{Status},'NAVIS_STAGED_OPERATOR_PROCESSING_REQUIRED','staging never claims worker/build completion');
ok($Controller->Completed(ExecutionUID=>$ReadUID),'repeated completion is harmless');
is(scalar(grep {$_->{Invoker} eq 'Ingest'} @Navis),1,'readback callback cannot duplicate ingestion');
ok(!eval {$Controller->Get(Context=>{%$Context,TargetID=>26},ActorID=>7,AnalysisID=>$AnalysisID);1},'target scope isolation');
my $Final=$Controller->Get(Context=>$Context,ActorID=>7,AnalysisID=>$AnalysisID)->{Data};
is($Final->{ReadbackVerification}[0]{Status},'UNKNOWN','partial readback never becomes verified configuration');
ok(!$Final->{ReadbackVerification}[0]{ConnectivityVerified},'rule readback is never connectivity verification');
my $Invoker=Kernel::GenericInterface::Invoker::TESSERA::Request->new(WebserviceID=>$ID,Invoker=>'GraphGet');
ok($Invoker->PrepareRequest(Data=>{BuildID=>'abc'})->{Success},'registered invoker accepts enabled service');
$Kernel::OM->{WS}{$ID}{ValidID}=2;
ok(!$Invoker->PrepareRequest(Data=>{BuildID=>'abc'})->{Success},'native direct requester path cannot use disabled connection');
$Kernel::OM->{WS}{$ID}{ValidID}=1;
my $Before=dclone($Kernel::OM->{WS}{$ID});$Kernel::OM->{WS}{$ID}{Config}{Requester}{Transport}{Config}{Origin}='https://other.test';
ok(!eval {$Controller->Get(Context=>$Context,ActorID=>7,AnalysisID=>$AnalysisID);1},'connection drift invalidates saved analysis');
$Kernel::OM->{WS}{$ID}=$Before;
ok(!eval {$Controller->Completed(ExecutionUID=>'e'x40);1},'fabricated completion rejected');
my $Taint=Kernel::System::TESSERA::IntegrationAuth->new(Secret=>sub {'private'},HTTP=>sub {die 'LEAK-SECRET-RESPONSE'});
my $SafeT=Kernel::GenericInterface::Transport::HTTP::TESSERAIntegration->new(TransportConfig=>{Config=>$Config},Auth=>$Taint);
my $Failure=$SafeT->RequesterPerformRequest(Operation=>'GraphGet',Data=>{BuildID=>'abc'});
ok(!$Failure->{Success},'provider exception fails closed');unlike(JSON::PP->new->encode($Failure),qr/LEAK-SECRET/,'raw provider error never reaches debugger');
my $BadScope=Kernel::System::TESSERA::IntegrationAuth->new(Secret=>sub {'private'},HTTP=>sub {{Status=>200,Body=>'{"access_token":"token","token_type":"Bearer","expires_in":300,"scope":"unrelated"}'}});
ok(!eval {$BadScope->Token(Profile=>$Auth,Identity=>'scope-test',Invalidate=>1);1},'downscoped token cannot silently satisfy requested scopes');
my $Generic={Preset=>'Generic',Origin=>'https://another.test',Authentication=>{%$Auth,TokenURL=>'https://auth.another.test/token'},Routes=>{Fetch=>{Method=>'GET',Path=>'/things/:ThingID',Parameters=>['ThingID']}}};
ok($B->Validate(dclone($Generic)),'generic service uses independent configured token endpoint and routes');
ok(!eval {$B->Validate({%$Generic,Routes=>{Fetch=>{Method=>'GET',Path=>'/../escape',Parameters=>[]}}});1},'dot-segment route rejected');
my $TT=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard');my $Rendered='';
ok($TT->process('AgentTESSERAIntegration.tt',{Data=>{Name=>'<script>bad</script>',Inputs=>[],Connections=>[],Routes=>'{}'},Env=>sub {'/index.pl'}},\$Rendered),'agent onboarding template renders');
unlike($Rendered,qr/<script>/,'connection values HTML escaped');like($Rendered,qr/name="ChallengeToken"/,'CSRF token emitted');
like($Rendered,qr/for="Name"/,'connection field has explicit label');
my $Uncertain=Kernel::System::TESSERA::NavisControl->new(Requester=>sub {
    my %P=@_;return {Success=>1,Data=>dclone($F->{graph})} if $P{Invoker} eq 'GraphGet';die 'Remote POST response lost';
});
my $Lost=$Uncertain->Analyze(Context=>$Context,ActorID=>7,Data=>$Fixture->{flow});
ok(!$Lost->{Success},'uncertain trace fails with analysis reference');
is($Uncertain->Get(Context=>$Context,ActorID=>7,AnalysisID=>$Lost->{Data}{AnalysisID})->{Data}{Status},'TRACE_INTENT','POST intent retained before uncertain network outcome');
ok(!eval {$Uncertain->Recommendations(Context=>$Context,ActorID=>7,AnalysisID=>$Lost->{Data}{AnalysisID});1},'no implicit trace replay from recommendation continuation');
my $WorkerText;{open my $W,'<','examples/navis/workflow.yml' or die $!;local $/;$WorkerText=<$W>}
unlike($WorkerText,qr/NAVIS_URL|NAVIS_TOKEN|navis_preparation|tessera_navis|\/v1\//,'AWX workflow contains no Navis orchestration');
ok(!eval {$Controller->Get(Context=>{%$Context,Snapshot=>[]},ActorID=>7,AnalysisID=>$AnalysisID);1},'revoked CMDB snapshot scope cannot read saved analysis');
my $Facade=Kernel::GenericInterface::Transport->new(DebuggerObject=>bless({},'IntegrationDebugger'),TransportConfig=>{Type=>'HTTP::TESSERAIntegration',Config=>$Kernel::OM->{WS}{$ID}{Config}{Requester}{Transport}{Config}});
isa_ok($Facade,'Kernel::GenericInterface::Transport','native GI transport loader');
$Facade->{BackendObject}{Auth}=$TA;@Statuses=(200);
ok($Facade->RequesterPerformRequest(Operation=>'GraphGet',Data=>{BuildID=>'abc'})->{Success},'native GI facade executes new transport');
my $NativeInvoker=Kernel::GenericInterface::Invoker->new(DebuggerObject=>bless({},'IntegrationDebugger'),Invoker=>'GraphGet',InvokerType=>'TESSERA::Request',WebserviceID=>$ID);
isa_ok($NativeInvoker,'Kernel::GenericInterface::Invoker','native GI invoker loader');
ok($NativeInvoker->PrepareRequest(Data=>{BuildID=>'abc'})->{Success},'native GI facade prepares registered invoker');
{
    package IntegrationUIOM;
    sub Get {my ($S,$Name)=@_;return $S->{Backend} if $Name eq 'Kernel::System::TESSERA::IntegrationOnboarding';return $S->{UI}}
    package IntegrationUI;
    sub RequestMethod {$_[0]{Method}}
    sub GetParam {my ($S,%P)=@_;return $P{Param} eq 'ChallengeToken'?$S->{SubmittedToken}:''}
    sub NoPermission {'DENIED'}
    sub ErrorScreen {my ($S,%P)=@_;return $P{Message}}
    sub ChallengeTokenCheck {$_[0]{ChallengeOK}}
}
{
    my $UI=bless {Method=>'GET',UserChallengeToken=>'real',SubmittedToken=>'real',ChallengeOK=>1},'IntegrationUI';
    local $Kernel::OM=bless {Backend=>$B,UI=>$UI},'IntegrationUIOM';
    # Backend authority is independently checked before inspecting form data.
    my $Module=Kernel::Modules::AgentTESSERAIntegration->new(UserID=>7,Subaction=>'Test');
    {no warnings 'redefine';local *Kernel::System::TESSERA::IntegrationOnboarding::Authorized=sub {1};
        like($Module->Run(),qr/protected POST/,'UI rejects GET side effect');
        $UI->{Method}='POST';$UI->{SubmittedToken}='wrong';like($Module->Run(),qr/protected POST/,'UI rejects CSRF mismatch');
        $UI->{SubmittedToken}='real';$UI->{ChallengeOK}=0;like($Module->Run(),qr/Invalid request token/,'native challenge check required');
    }
    {no warnings 'redefine';local *Kernel::System::TESSERA::IntegrationOnboarding::Authorized=sub {0};
        is($Module->Run(),'DENIED','agent module independently rejects unauthorized identity');
    }
}
done_testing();
