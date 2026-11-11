use strict;
use warnings;
use Test::More;
use JSON::PP ();
# REST::Client is requester-only; this suite exercises the native provider code.
BEGIN {$INC{'REST/Client.pm'}=1}
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::GenericInterface::Transport::HTTP::TESSERAObservability;
{
 package OTRequest;
 sub RequestURI {return $main::uri}sub RequestMethod {return $main::method}
 sub GetParam {return $main::body}sub ContentType {return 'application/json; charset=utf-8'}
 package OTEncode;sub EncodeInput {}sub EncodeOutput {}
 package OTJSON;sub Encode {my ($s,%p)=@_;return JSON::PP->new->encode($p{Data})}sub Decode {my ($s,%p)=@_;return eval {JSON::PP->new->decode($p{Data})}}
 package OTDebug;sub Debug {}sub Error {}
 package OTOM;sub Get {my ($s,$n)=@_;my %m=('Kernel::System::Web::Request'=>'OTRequest','Kernel::System::Encode'=>'OTEncode','Kernel::System::JSON'=>'OTJSON');return bless {},$m{$n}||die $n}
 package Kernel;our $OM=bless {},'OTOM';
}
our ($uri,$method,$body)=('/otobo/nph-genericinterface.pl/Webservice/TESSERAObservability/v1/tickets?Limit=10','GET','');
sub transport {return Kernel::GenericInterface::Transport::HTTP::TESSERAObservability->new(DebuggerObject=>bless({},'OTDebug'),TransportConfig=>{Config=>{MaxLength=>100,RouteOperationMapping=>{Observability=>{Route=>'/v1/:Resource',RequestMethod=>['GET','POST']}}}})}
my $s=transport();my $r=$s->ProviderProcessRequest();ok($r->{Success},'native REST parses provider request');is($r->{Data}{Resource},'tickets','native route extracts resource');is($r->{Data}{Limit},10,'native route extracts pagination');
$method='POST';$uri='/otobo/nph-genericinterface.pl/Webservice/TESSERAObservability/v1/alertmanager';$body='{"Resource":"tickets","version":"4"}';
$s=transport();$r=$s->ProviderProcessRequest();is($r->{Data}{Resource},'alertmanager','body cannot override server route');
sub response {
 my ($t,%p)=@_;my $caught;eval {$t->ProviderGenerateResponse(%p)};$caught=$@;
 ok(ref $caught && $caught->isa('Kernel::System::Web::Exception'),'provider throws native HTTP exception');return $caught->as_psgi();
}
my $out=response($s,Success=>1,Data=>{HTTPStatus=>403,Body=>{Error=>'denied'}});is($out->[0],403,'authorization response is a real HTTP 403');my %h=@{$out->[1]};is($h{'Content-Type'},'application/json; charset=UTF-8','error response is JSON');is($h{'Cache-Control'},'no-store','API response is not cached');ok(!exists $h{'Access-Control-Allow-Origin'},'no cross-origin credential grant');
$body='x'x101;$s=transport();$r=$s->ProviderProcessRequest();ok(!$r->{Success},'native request-size limit rejects oversized body');$out=response($s,Success=>0);is($out->[0],413,'native oversized request keeps HTTP 413');
$body='not JSON';$s=transport();$r=$s->ProviderProcessRequest();ok(!$r->{Success},'native malformed JSON rejected');$out=response($s,Success=>0);is($out->[0],400,'malformed request gets HTTP 400');
done_testing;
