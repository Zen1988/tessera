use strict;
use warnings;
use Test::More;
use JSON::PP;
use Storable qw(dclone);
use lib '.';
use Kernel::GenericInterface::Invoker::NetXMS::PathTrace;
use Kernel::GenericInterface::Invoker::NetXMS::PathTraceL2;
{package PathOM;sub Get {$_[0]} sub WebserviceGet {$_[0]{WS}}}
open my $FH,'<','var/webservices/examples/TESSERANetXMS.yml' or die $!;
my $C=decode_json(do {local $/;<$FH>});close $FH;
local $Kernel::OM=bless {WS=>{ValidID=>1,Config=>$C}},'PathOM';
for my $Name (qw(PathTrace PathTraceL2)) {
    my $Class='Kernel::GenericInterface::Invoker::NetXMS::'.$Name;
    my $I=$Class->new(DebuggerObject=>{},WebserviceID=>2,Invoker=>$Name);
    my $R=$I->PrepareRequest(Data=>{SourceID=>1,DestinationID=>2});
    ok($R->{Success},"$Name prepares fixed query");
    like($R->{Data}{script},$Name eq 'PathTrace' ? qr/\$node\.traceRoute\(destination\)/ : qr/\$node\.traceL2Path\(destination\)/,'fixed API method');
    ok(!$R->{Data}{stream},'synchronous result');
    my $P={sourceId=>1,destinationId=>2,collectedAt=>time(),isComplete=>JSON::PP::true,hopCount=>1,
        hops=>[{nodeId=>2,type=>'DESTINATION',ifIndex=>0}]};
    ok($I->HandleResponse(ResponseSuccess=>1,Data=>{result=>encode_json($P)})->{Success},'valid path accepted');
    for my $Change (sub {$_[0]{sourceId}=9},sub {$_[0]{hopCount}=2},sub {$_[0]{isComplete}='true'},sub {$_[0]{hops}[0]{type}='UNKNOWN'}) {
        my $Bad=dclone($P);$Change->($Bad);
        ok(!$I->HandleResponse(ResponseSuccess=>1,Data=>{result=>encode_json($Bad)})->{Success},'bad path rejected');
    }
    for my $Bad ({SourceID=>1,DestinationID=>'2); malicious()'},{SourceID=>1,DestinationID=>2,script=>'anything'},
        {SourceID=>1,DestinationID=>2,URL=>'https://elsewhere'}) {
        ok(!$I->PrepareRequest(Data=>$Bad)->{Success},'caller cannot change script or destination service');
    }
}
done_testing();
