use strict;
use warnings;
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use lib '.';
{ package NetXMSTestOM; sub Get { return $_[0] } sub WebserviceGet { return $_[0]{WS} } }
open my $FH,'<','var/webservices/examples/TESSERANetXMS.yml' or die $!;
my $Config=decode_json(do {local $/; <$FH>}); close $FH;
local $Kernel::OM=bless {WS=>{ValidID=>1,Config=>$Config}},'NetXMSTestOM';
my %Objects;
for my $Name (sort grep {!/^PathTrace/} keys %{$Config->{Requester}{Invoker}}) {
    my $Class="Kernel::GenericInterface::Invoker::NetXMS::$Name";
    (my $File="$Class.pm")=~s{::}{/}g; require $File;
    my $I=$Class->new(DebuggerObject=>bless({},'Debugger'),WebserviceID=>12,Invoker=>$Name);
    $Objects{$Name}=$I;
    my $Input=$Name eq 'History' ? {ObjectID=>1,DCIID=>2,timeFrom=>0,timeTo=>100}
        : $Name eq 'AlarmGet' ? {AlarmID=>3} : $Name=~/\A(?:ObjectGet|CurrentValues|DataCollection)\z/ ? {ObjectID=>1} : {};
    my $Before=dclone($Input);
    ok($I->PrepareRequest(Data=>$Input)->{Success},"$Name prepares");
    is_deeply($Input,$Before,'input unchanged');
    my $Raw={id=>1,extra=>{values=>[1,JSON::PP::true,'test']}};
    my $R=$I->HandleResponse(ResponseSuccess=>1,Data=>$Raw);
    ok($R->{Success},'structured observation returned');
    is($R->{Data}{WebserviceID},12,'source instance retained');
    is($R->{Data}{Completeness},'UNVERIFIED','HTTP success does not certify topology');
    is_deeply($R->{Data}{Response},$Raw,'full response retained');
    $Raw->{extra}{values}[0]=9;
    is($R->{Data}{Response}{extra}{values}[0],1,'response copied');
    ok(!$I->HandleResponse(ResponseSuccess=>0,Data=>{token=>'secret'})->{Success},'transport error fails closed');
}
my $I=$Objects{ObjectGet};
for my $Bad ({},{ObjectID=>'../1'},{ObjectID=>0},{ObjectID=>[]},{ObjectID=>1,URL=>'https://other'},{ObjectID=>1,token=>'secret'},{ObjectID=>1,query=>'script'}) {
    ok(!$I->PrepareRequest(Data=>$Bad)->{Success},'invalid input rejected');
}
for my $Change (
    sub {$Config->{Requester}{Transport}{Config}{Host}='http://host'},
    sub {$Config->{Requester}{Transport}{Config}{Host}='https://user:pass@host'},
    sub {$Config->{Requester}{Transport}{Config}{SSL}{SSLVerifyHostname}='No'},
    sub {$Config->{Requester}{Transport}{Config}{SSL}{SSLVerifyMode}=''},
    sub {$Config->{Requester}{Transport}{Config}{Timeout}=0},
    sub {$Config->{Requester}{Transport}{Config}{InvokerControllerMapping}{ObjectGet}{Command}='POST'},
    sub {$Config->{Requester}{Transport}{Config}{InvokerControllerMapping}{ObjectGet}{Controller}='/v1/users'},
    sub {$Config->{Requester}{Invoker}{ObjectGet}{MappingOutbound}={Type=>'Simple'}},
) {
    my $Before=dclone($Config); $Change->();
    ok(!$I->PrepareRequest(Data=>{ObjectID=>1})->{Success},'unsafe transport rejected');
    %$Config=%$Before;
}
ok($I->PrepareRequest(Data=>{ObjectID=>1})->{Success},'valid transport restored');
for my $Bad (undef,'text',{reason=>'secret'},{error=>'secret'},{payload=>'x' x 4194305}) {
    my $R=$I->HandleResponse(ResponseSuccess=>1,Data=>$Bad);
    ok(!$R->{Success},'invalid/remote error/oversized response rejected');
    unlike($R->{ErrorMessage},qr/secret/,'no remote error body echoed');
}
my $Cycle={}; $Cycle->{cycle}=$Cycle;
ok(!$I->HandleResponse(ResponseSuccess=>1,Data=>$Cycle)->{Success},'cycle rejected'); delete $Cycle->{cycle};
ok($Objects{Objects}->HandleResponse(ResponseSuccess=>1,Data=>[])->{Success},'empty collection is valid');
my $H=$Objects{History};
ok(!$H->PrepareRequest(Data=>{ObjectID=>1,DCIID=>2,timeFrom=>2,timeTo=>1})->{Success},'reversed history rejected');
ok(!$H->PrepareRequest(Data=>{ObjectID=>1,DCIID=>2,timeFrom=>0,timeTo=>1,maxRows=>1001})->{Success},'history bound enforced');
is($H->PrepareRequest(Data=>{ObjectID=>1,DCIID=>2,timeFrom=>0,timeTo=>1})->{Data}{maxRows},1000,'bounded history default');
ok(!$I->HandleResponse(ResponseSuccess=>1,Data=>[])->{Success},'detail array rejected');
require Kernel::System::TESSERA::AutomationWebService;
require Kernel::System::TESSERA::ScriptEngine;
{ package NetXMSTestOM;
  sub Run {
      my ($Self,%P)=@_;
      $Self->{Calls}++;
      my $C='Kernel::GenericInterface::Invoker::NetXMS::ServerInfo';
      my $Invoker=$C->new(DebuggerObject=>bless({},'Debugger'),%P);
      my $Prepared=$Invoker->PrepareRequest(Data=>$P{Data});
      return $Prepared if !$Prepared->{Success};
      return $Invoker->HandleResponse(ResponseSuccess=>1,Data=>{version=>'fixture'});
  }
}
my $Provider=Kernel::System::TESSERA::AutomationWebService->new(AllowedCalls=>{NetXMS=>{ServerInfo=>12}});
my $Engine=Kernel::System::TESSERA::ScriptEngine->new(WebServiceProvider=>sub {$Provider->Call(@_)});
my $Script={VERSION=>1,'CALL WEB SERVICE'=>[{SERVICE=>'NetXMS',INVOKER=>'ServerInfo',AS=>'SERVER',WITH=>{}}],RETURN=>{VALUE=>'EXTERNAL.SERVER.Response.version'}};
my $Result=$Engine->ScriptEvaluate(Script=>$Script,UserID=>1);
ok($Result->{Success},'existing authorized automation invokes native NetXMS connector');
is($Result->{Value},'fixture','script can interpret full response fields');
is($Kernel::OM->{Calls},1,'one native requester call');
ok(!$Provider->Call(Service=>'NetXMS',Invoker=>'Objects',Data=>{},UserID=>1)->{Success},'unbound operation denied');
is($Kernel::OM->{Calls},1,'denied operation never reaches requester');
done_testing();
