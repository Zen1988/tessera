use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib '.';
use Kernel::GenericInterface::Invoker::AWX::JobLaunchCallback;
use Kernel::GenericInterface::Invoker::AWX::InventoryHosts;
use Kernel::GenericInterface::Invoker::AWX::InventoryHostCreate;
use Kernel::GenericInterface::Invoker::AWX::InventoryHostUpdate;
use Kernel::System::TESSERA::AsyncExecution;
{package NewInvokerOM;
 sub Get {my($S,$Name)=@_;return $S->{URL} if $Name eq 'TESSERA::AWX::CallbackURL';return {AWXTest=>{Module=>'Kernel::System::TESSERA::AWXExecution',Function=>'RecordTestCompletion'}} if $Name eq 'TESSERA::AsyncExecution::Handlers';$S}
 sub WebserviceGet {$_[0]{WS}}
 sub GenerateRandomString {my($S,%P)=@_;'A'x$P{Length}}
 sub Encode {my($S,%P)=@_;JSON::PP->new->canonical->encode($P{Data})}
 sub Prepare {$_[0]{Fetched}=0;1} sub FetchrowArray {return if $_[0]{Fetched}++;return (0)}
 sub Do {my($S,%P)=@_;push @{$S->{Writes}},\%P;1}
 sub TaskAdd {my($S,%P)=@_;$S->{Task}=\%P;1}
 sub SystemTime2TimeStamp {'2099-01-01 00:00:00'}
}
sub config {
 my($Name)=@_;open my $FH,'<','var/webservices/examples/'.$Name or die $!;local $/;my $D=JSON::PP->new->decode(<$FH>);close $FH;return {ValidID=>1,Config=>$D};
}
local $Kernel::OM=bless {WS=>config('TESSERAAWX.yml'),URL=>'https://tessera.example/otobo/nph-genericinterface.pl/Webservice/Test/ExecutionCallback'},'NewInvokerOM';
my $L=Kernel::GenericInterface::Invoker::AWX::JobLaunchCallback->new(DebuggerObject=>{},WebserviceID=>12,Invoker=>'JobLaunchCallback');
my %Input=(TemplateID=>42,ExecutionUID=>'A'x40,CallbackToken=>'B'x64,extra_vars=>{business=>'x'});
my $R=$L->PrepareRequest(Data=>\%Input);ok($R->{Success},'callback launcher prepares');
is($R->{Data}{extra_vars}{tessera_callback}{ExecutionUID},'A'x40,'correlation sent in reserved variable');
is($R->{Data}{extra_vars}{tessera_callback}{CallbackToken},'B'x64,'only execution-scoped capability sent');
ok(!exists $R->{Data}{CallbackToken} && !exists $R->{Data}{ExecutionUID},'no unsupported AWX top-level token fields');
ok(!exists $Input{extra_vars}{tessera_callback},'caller data unchanged');
ok(!$L->PrepareRequest(Data=>{%Input,credentials=>[1]})->{Success},'target credentials still prohibited');
ok(!$L->PrepareRequest(Data=>{%Input,extra_vars=>{tessera_callback=>{}}})->{Success},'caller cannot replace callback envelope');
$Kernel::OM->{URL}='http://not-https/ExecutionCallback';ok(!$L->PrepareRequest(Data=>\%Input)->{Success},'insecure callback URL refused');
$Kernel::OM->{WS}=config('TESSERAAWXInventory.yml');
for my $Name (qw(InventoryHosts InventoryHostCreate InventoryHostUpdate)) {
 my $Class='Kernel::GenericInterface::Invoker::AWX::'.$Name;
 my $O=$Class->new(DebuggerObject=>{},WebserviceID=>14,Invoker=>$Name);
 my $Data=$Name eq 'InventoryHosts'?{InventoryID=>7,page=>2}:{InventoryID=>7,name=>'tessera-ci-9',variables=>{ansible_host=>'host.example'},$Name eq 'InventoryHostUpdate'?(HostID=>123):()};
 my $Out=$O->PrepareRequest(Data=>$Data);ok($Out->{Success},"$Name input accepted");
 if ($Name eq 'InventoryHosts') {
  is($Out->{Data}{order_by},'id','stable pagination');
  ok($O->HandleResponse(ResponseSuccess=>1,Data=>{count=>1,next=>undef,results=>[{inventory=>7}]})->{Success},'scoped inventory list accepted');
  ok(!$O->HandleResponse(ResponseSuccess=>1,Data=>{count=>1,results=>[{inventory=>8}]})->{Success},'foreign inventory host rejected');
 }
 else {
  is(JSON::PP->new->decode($Out->{Data}{variables})->{ansible_host},'host.example','variables serialized for AWX');
  ok(!$O->PrepareRequest(Data=>{%{$Data},variables=>{ansible_password=>'secret'}})->{Success},'inventory credential values rejected');
  $O->PrepareRequest(Data=>$Data);
  ok($O->HandleResponse(ResponseSuccess=>1,Data=>{id=>123,inventory=>7,name=>'tessera-ci-9',enabled=>1})->{Success},'write identity verified');
  ok(!$O->HandleResponse(ResponseSuccess=>1,Data=>{id=>123,inventory=>8,name=>'tessera-ci-9',enabled=>1})->{Success},'write scope mismatch rejected');
 }
}
$Kernel::OM->{WS}=config('TESSERAAWX.yml');$Kernel::OM->{URL}='https://tessera.example/Webservice/Test/ExecutionCallback';
my $Async=Kernel::System::TESSERA::AsyncExecution->new();
my %Start=(HandlerKey=>'AWXTest',TargetType=>'IntegrationTest',TargetID=>1,ActorID=>7,Continuation=>{},WebserviceID=>12,Invoker=>'JobLaunchCallback',Payload=>{TemplateID=>42});
$R=$Async->Start(%Start);ok($R->{Success},'callback execution saved and scheduled');
is($Kernel::OM->{Task}{Type},'Cron','AWX dispatch uses dedicated persisted-intent worker');
is($Kernel::OM->{Task}{Attempts},1,'AWX launch is not blindly retried');
like($Kernel::OM->{Writes}[0]{SQL},qr/request_data/,'input history persisted');
my $Request=${$Kernel::OM->{Writes}[0]{Bind}[-1]};unlike($Request,qr/CallbackToken/,'history snapshot excludes callback capability');
my $Count=@{$Kernel::OM->{Writes}};
ok(!$Async->Start(%Start,Payload=>{TemplateID=>42,credentials=>[1]})->{Success},'unsafe launch rejected before persistence');
is(scalar @{$Kernel::OM->{Writes}},$Count,'invalid credential launch does not persist secrets or schedule');
ok(!$Async->Start(%Start,Payload=>{TemplateID=>42,CallbackToken=>'fake'})->{Success},'caller cannot supply runtime-owned token');
done_testing();
