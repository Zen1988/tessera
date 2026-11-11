use strict;
use warnings;
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use lib '.', 'Custom', 'Kernel/Package/GovernanceDB';
use Kernel::System::TESSERA::IntegrationAuth;
use Kernel::System::TESSERA::IntegrationOnboarding;
use Kernel::GenericInterface::Transport::HTTP::TESSERAIntegration;
use Kernel::GenericInterface::Invoker::AWX::JobLaunch;
use Kernel::GenericInterface::Invoker::AWX::JobEvents;
use Kernel::GenericInterface::Invoker::AWX::JobStdout;
{
 package AWXManagedOM;
 sub Get {$_[0]}
 sub GetUserData {(ValidID=>1)}
 sub PermissionCheck {$_[1] eq 'UserID' && $_[2]==7}
 sub Prepare {1}
 sub FetchrowArray {(1)}
 sub WebserviceList {my($S)=@_;return {map {$_=>$S->{WS}{$_}{Name}} keys %{$S->{WS}}}}
 sub WebserviceGet {my($S,%P)=@_;return $S->{WS}{$P{ID}}?Storable::dclone($S->{WS}{$P{ID}}):undef}
 sub WebserviceAdd {my($S,%P)=@_;my $ID=++$S->{Next};$S->{WS}{$ID}={ID=>$ID,%P};return $ID}
 sub WebserviceUpdate {my($S,%P)=@_;$S->{WS}{$P{ID}}={%P};return 1}
}
local $Kernel::OM=bless {WS=>{4=>{Name=>'ansible.awx',ValidID=>1,Config=>{Requester=>{Transport=>{Type=>'HTTP::REST'}}}}},Next=>10},'AWXManagedOM';
my $Token='TOKEN_One_123';my @HTTP;my $Status=200;my $Response={results=>[{id=>3,username=>'tessera.integrator'}]};
my $Auth=Kernel::System::TESSERA::IntegrationAuth->new(Secret=>sub {$Token},HTTP=>sub {my %P=@_;push @HTTP,\%P;return {Status=>$Status,Body=>JSON::PP->new->encode($Response)}});
my $Profile={Provider=>'StaticBearer',SecretName=>'awx-api-token'};
is($Auth->Token(Profile=>$Profile),'TOKEN_One_123','mounted bearer read without token exchange');
is(scalar @HTTP,0,'PAT does not use client credentials grant');
$Token='TOKEN_Two_456';is($Auth->Token(Profile=>$Profile),'TOKEN_Two_456','rotation immediately reread');
for my $Bad ('bad token',"bad\r\nInjected: true",'',"token\tvalue") {
 local $Auth->{Secret}=sub {$Bad};ok(!eval {$Auth->Token(Profile=>$Profile);1},'invalid/header-injection token denied');
}
for my $Bad ({%$Profile,Token=>'raw-secret'},{%$Profile,TokenURL=>'https://elsewhere/token'},{%$Profile,SecretName=>'../private'},{Provider=>'Unknown',SecretName=>'awx-api-token'}) {
 ok(!eval {$Auth->Validate($Bad);1},'inline tokens, unrelated settings and unsafe references rejected');
}
my $B=Kernel::System::TESSERA::IntegrationOnboarding->new(Auth=>$Auth);
my $C={Preset=>'AWX',Origin=>'https://awx.test',Authentication=>$Profile};
ok(!eval {$B->Save(UserID=>8,Name=>'awx-managed',Connection=>$C);1},'non-admin backend write denied');
my $ID=$B->Save(UserID=>7,Name=>'awx-managed',Connection=>$C);
is($Kernel::OM->{WS}{$ID}{ValidID},2,'new connection disabled until explicitly enabled');
is(scalar @HTTP,0,'disabled save has no external effect');
is($Kernel::OM->{WS}{4}{Config}{Requester}{Transport}{Type},'HTTP::REST','existing legacy service untouched');
ok(!eval {$B->Save(UserID=>7,ID=>4,Name=>'ansible.awx',Connection=>$C);1},'legacy service not silently adopted');
ok(!eval {$B->Save(UserID=>7,Name=>'awx-managed',Connection=>$C);1},'duplicate name refused');
is($B->Save(UserID=>7,ID=>$ID,Name=>'awx-managed',Enabled=>1,Connection=>$C),$ID,'update reuses managed service ID');
is(scalar @HTTP,1,'enable verifies identity once');
is($HTTP[0]{Method},'GET','authentication check read-only');
is($HTTP[0]{URL},'https://awx.test/api/v2/me/','identity check never launches a job');
is($HTTP[0]{Headers}{Authorization},'Bearer TOKEN_Two_456','bearer header supplied only to transport');
my $WS=$Kernel::OM->{WS}{$ID};
unlike(JSON::PP->new->encode($WS),qr/TOKEN_Two_456/,'native stored config contains no token value');
is($WS->{Config}{Requester}{Invoker}{JobLaunch}{Type},'AWX::JobLaunch','typed AWX invokers retained');
is(scalar keys %{$WS->{Config}{Requester}{Invoker}},8,'complete execution invoker set');
my $UID=$WS->{Config}{Requester}{Transport}{Config}{ConnectionUID};
$B->Save(UserID=>7,ID=>$ID,Name=>'awx-managed',Connection=>$C);
is($Kernel::OM->{WS}{$ID}{Config}{Requester}{Transport}{Config}{ConnectionUID},$UID,'editing preserves connection identity');
$Kernel::OM->{WS}{$ID}{ValidID}=1;
for my $Bad ({%$C,Origin=>'http://awx.test'},{%$C,Origin=>'https://awx.test/api/v2/'},{%$C,Origin=>'https://user:pw@awx.test'},{%$C,Authentication=>{Provider=>'ClientCredentialsBasic',TokenURL=>'https://awx.test/token',ClientID=>'x',SecretName=>'awx-api-token'}}) {
 ok(!eval {$B->Validate(dclone($Bad));1},'bad origin or mismatched authentication denied');
}
$Status=401;ok(!eval {$B->Test(UserID=>7,Connection=>$C);1},'rejected PAT fails authentication');
$Status=200;$Response={results=>[]};ok(!eval {$B->Test(UserID=>7,Connection=>$C);1},'no authenticated identity denied');
$Response={results=>[{id=>3}]};
my $Launch=Kernel::GenericInterface::Invoker::AWX::JobLaunch->new(DebuggerObject=>{},WebserviceID=>$ID,Invoker=>'JobLaunch');
my $Prepared=$Launch->PrepareRequest(Data=>{TemplateID=>35});ok($Prepared->{Success},'existing invoker accepts managed AWX preset');
my $Transport=Kernel::GenericInterface::Transport::HTTP::TESSERAIntegration->new(TransportConfig=>$WS->{Config}{Requester}{Transport},Auth=>$Auth);
@HTTP=();$Status=201;$Response={id=>99,status=>'pending'};
my $R=$Transport->RequesterPerformRequest(Operation=>'JobLaunch',Data=>$Prepared->{Data});ok($R->{Success},'AWX201 launch response supported');
is($HTTP[0]{URL},'https://awx.test/api/v2/job_templates/35/launch/','canonical template launch URL');
is($HTTP[0]{Body},'{}','path ID excluded from JSON body');
is(scalar @HTTP,1,'launch sent once');
my $Handled=$Launch->HandleResponse(ResponseSuccess=>1,Data=>$R->{Data});is($Handled->{Data}{JobID},99,'existing AWX result normalization preserved');
$Status=401;@HTTP=();$R=$Transport->RequesterPerformRequest(Operation=>'JobLaunch',Data=>{TemplateID=>35});
ok(!$R->{Success},'unauthorized launch fails');is(scalar @HTTP,1,'POST never replayed');unlike(JSON::PP->new->encode($R),qr/TOKEN_Two_456/,'failure does not expose PAT');
$Status=200;$Response={count=>0,results=>[],next=>undef,previous=>undef};@HTTP=();
my $Events=Kernel::GenericInterface::Invoker::AWX::JobEvents->new(DebuggerObject=>{},WebserviceID=>$ID,Invoker=>'JobEvents');
$Prepared=$Events->PrepareRequest(Data=>{JobID=>99,page=>2,page_size=>100});ok($Prepared->{Success},'event query prepared by existing invoker');
ok($Transport->RequesterPerformRequest(Operation=>'JobEvents',Data=>$Prepared->{Data})->{Success},'managed transport supports paginated GET');
like($HTTP[0]{URL},qr{\Ahttps://awx.test/api/v2/jobs/99/job_events/\?page=2&page_size=100&order_by=counter\z},'query parameters stay on registered origin');
$Status=401;@HTTP=();ok(!$Transport->RequesterPerformRequest(Operation=>'JobGet',Data=>{JobID=>99})->{Success},'expired static token fails GET');is(scalar @HTTP,1,'static bearer not pointlessly retried');
$Status=200;$Response={content=>'test',range=>{start=>0,end=>1,absolute_end=>1}};@HTTP=();
my $Stdout=Kernel::GenericInterface::Invoker::AWX::JobStdout->new(DebuggerObject=>{},WebserviceID=>$ID,Invoker=>'JobStdout');
$Prepared=$Stdout->PrepareRequest(Data=>{JobID=>99,start_line=>0,end_line=>1});
ok($Transport->RequesterPerformRequest(Operation=>'JobStdout',Data=>$Prepared->{Data})->{Success},'bounded stdout query supported');
like($HTTP[0]{URL},qr{stdout/\?format=json&start_line=0&end_line=1\z},'JSON stdout format retained');
ok(!$Transport->RequesterPerformRequest(Operation=>'JobGet',Data=>{JobID=>99,URL=>'https://elsewhere/'})->{Success},'undeclared query parameter rejected');
ok(!$Transport->RequesterPerformRequest(Operation=>'JobGet',Data=>{JobID=>'../1'})->{Success},'path traversal rejected');
ok(!$Transport->RequesterPerformRequest(Operation=>'JobGet',Data=>{JobID=>0})->{Success},'nonpositive identity rejected');
my $Before=dclone($Kernel::OM->{WS}{$ID});$Kernel::OM->{WS}{$ID}{Config}{Requester}{Transport}{Config}{Routes}{JobLaunch}{Path}='/evil/';
ok(!$Launch->PrepareRequest(Data=>{TemplateID=>35})->{Success},'drifted managed route denied by typed invoker');
$Kernel::OM->{WS}{$ID}=$Before;
$Kernel::OM->{WS}{$ID}{Config}{Requester}{Invoker}{JobLaunch}{MappingOutbound}={Type=>'Simple'};
ok(!$Launch->PrepareRequest(Data=>{TemplateID=>35})->{Success},'managed invokers cannot add arbitrary mappings');
done_testing();
