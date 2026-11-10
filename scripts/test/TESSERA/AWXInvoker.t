use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use lib '.';
use Kernel::GenericInterface::Invoker::AWX::JobLaunch;
use Kernel::GenericInterface::Invoker::AWX::WorkflowLaunch;
use Kernel::GenericInterface::Invoker::AWX::JobGet;
use Kernel::GenericInterface::Invoker::AWX::WorkflowGet;
use Kernel::GenericInterface::Invoker::AWX::JobStdout;
use Kernel::GenericInterface::Invoker::AWX::JobEvents;
use Kernel::GenericInterface::Invoker::AWX::WorkflowNodes;

{ package AWXTestOM;
  sub Get { return $_[0] }
  sub WebserviceGet { return $_[0]{WS} }
}
open my $FH, '<', 'var/webservices/examples/TESSERAAWX.yml' or die $!;
my $Config = JSON::PP->new->decode(do { local $/; <$FH> }); close $FH;
local $Kernel::OM = bless {WS => {ValidID => 1, Config => $Config}}, 'AWXTestOM';
my %Objects;
for my $Name (qw(JobLaunch WorkflowLaunch JobGet WorkflowGet JobStdout JobEvents WorkflowNodes)) {
    my $Class = "Kernel::GenericInterface::Invoker::AWX::$Name";
    $Objects{$Name} = $Class->new(DebuggerObject => bless({}, 'Debugger'), WebserviceID => 1, Invoker => $Name);
    my $Input = $Name =~ /Launch/ ? {TemplateID => 42, inventory => 7, extra_vars => {nested => {items => [1, 'hello', JSON::PP::true]}}} : {JobID => 8};
    my $Before = dclone($Input);
    my $R = $Objects{$Name}->PrepareRequest(Data => $Input);
    ok($R->{Success}, "$Name prepares with shipped configuration");
    is_deeply($Input, $Before, "$Name does not mutate caller input");
    if ($Name =~ /Launch/) { is_deeply($R->{Data}, $Input, 'launch payload preserved') }
}
my $L = $Objects{JobLaunch};
for my $Pair (
    ['missing ID', {}], ['path injection', {TemplateID => '../1'}], ['inventory contents', {TemplateID => 1, inventory => {hosts => ['x']}}],
    ['string extra_vars', {TemplateID => 1, extra_vars => 'x: y'}], ['credential', {TemplateID => 1, credentials => [7]}],
    ['nested credential', {TemplateID => 1, extra_vars => {child => {ansible_password => 'do-not-log'}}}],
    ['callback token', {TemplateID => 1, CallbackToken => 'do-not-log'}], ['caller URL', {TemplateID => 1, URL => 'https://other'}],
    ['verbosity bounds', {TemplateID => 1, verbosity => 6}], ['bad type', {TemplateID => 1, job_type => 'delete'}],
    ['undefined scalar', {TemplateID => 1, limit => undef}], ['bad boolean', {TemplateID => 1, diff_mode => 'yes'}],
) {
    my $R = $L->PrepareRequest(Data => $Pair->[1]);
    ok(!$R->{Success}, "$Pair->[0] rejected");
    unlike($R->{ErrorMessage}, qr/do-not-log/, 'rejection does not echo input');
}
for my $V (0..5) { ok($L->PrepareRequest(Data => {TemplateID => 1, verbosity => $V})->{Success}, "verbosity $V supported") }
my $Cycle = {}; $Cycle->{x} = $Cycle;
ok(!$L->PrepareRequest(Data => {TemplateID => 1, extra_vars => $Cycle})->{Success}, 'cycle rejected');
delete $Cycle->{x};
ok(!$L->PrepareRequest(Data => {TemplateID => 1, extra_vars => {x => 'a' x 1048577}})->{Success}, 'oversized input rejected');
for my $Change (
    sub { $Config->{Requester}{Transport}{Config}{Host} = 'http://awx.local' },
    sub { $Config->{Requester}{Transport}{Config}{SSL}{SSLVerifyMode} = 'No' },
    sub { $Config->{Requester}{Transport}{Config}{SSL}{SSLVerifyHostname} = 'No' },
    sub { $Config->{Requester}{Transport}{Config}{Timeout} = 61 },
    sub { $Config->{Requester}{Transport}{Config}{InvokerControllerMapping}{JobLaunch}{Command} = 'GET' },
    sub { $Config->{Requester}{Transport}{Config}{InvokerControllerMapping}{JobLaunch}{Controller} = '/anything/' },
    sub { $Config->{Requester}{Invoker}{JobLaunch}{MappingOutbound} = {Type => 'Simple'} },
) {
    my $Original = dclone($Config); $Change->();
    ok(!$L->PrepareRequest(Data => {TemplateID => 1})->{Success}, 'unsafe/mismatched transport rejected');
    %{$Config} = %{$Original};
}
my $Response = {id => 8, status => 'pending', artifacts => {arbitrary => {one => ['two']}}, extra_vars => '{"x":1}', new_awx_field => 'preserved'};
my $R = $L->HandleResponse(ResponseSuccess => 1, Data => $Response);
ok($R->{Success} && !$R->{Data}{Terminal} && !$R->{Data}{ExecutionSuccess}, 'launch acceptance is not completion');
is_deeply($R->{Data}{Response}, $Response, 'full response retained including unknown AWX fields');
$Response->{artifacts}{arbitrary}{one}[0] = 'changed';
is($R->{Data}{Response}{artifacts}{arbitrary}{one}[0], 'two', 'response is independent copy');
for my $State (qw(new pending waiting running successful failed error canceled)) {
    my $R = $Objects{JobGet}->HandleResponse(ResponseSuccess => 1, Data => {id => 8, status => $State});
    ok($R->{Success}, "$State is valid response");
    is($R->{Data}{ExecutionSuccess}, $State eq 'successful' ? 1 : 0, "$State success flag");
}
ok(!$Objects{JobGet}->HandleResponse(ResponseSuccess => 1, Data => {id => 9, status => 'successful'})->{Success}, 'wrong job rejected');
ok(!$L->HandleResponse(ResponseSuccess => 1, Data => {id => 8, status => 'unknown'})->{Success}, 'unknown status rejected');
$R = $L->HandleResponse(ResponseSuccess => 1, Data => {id => 8, status => 'pending', ignored_fields => {inventory => 99}});
ok($R->{Success} && !$R->{Data}{InputAccepted}, 'ignored input is flagged without losing launch response');
is($R->{Data}{JobID}, 8, 'existing job ID retained for reconciliation');
is($R->{Data}{Outcome}, 'INPUT_REJECTED', 'ignored input outcome explicit');
is_deeply($R->{Data}{IgnoredFields}, ['inventory'], 'ignored input field names available');
$R = $L->HandleResponse(ResponseSuccess => 0, ResponseErrorMessage => 'secret-response');
ok(!$R->{Success} && !exists $R->{Data}{ReSchedule}, 'failed launch never requests retry');
unlike($R->{ErrorMessage}, qr/secret-response/, 'remote error not echoed');
is($R->{Data}{Outcome}, 'UNKNOWN', 'uncertain launch explicit');
my $S = $Objects{JobStdout};
$R = $S->PrepareRequest(Data => {JobID => 8, start_line => 200, end_line => 400});
is($R->{Data}{format}, 'json', 'stdout requests JSON rather than HTML/text');
ok(!$S->PrepareRequest(Data => {JobID => 8, start_line => 2, end_line => 1})->{Success}, 'reversed lines rejected');
ok(!$S->PrepareRequest(Data => {JobID => 8, end_line => 1001})->{Success}, 'unbounded line span rejected');
$R = $S->HandleResponse(ResponseSuccess => 1, Data => {content => "verbose\noutput", range => {start => 0, end => 2, absolute_end => 2}});
is($R->{Data}{Response}{content}, "verbose\noutput", 'stdout unchanged');
ok(!$S->HandleResponse(ResponseSuccess => 1, Data => {content => 'x', range => {}})->{Success}, 'missing stdout range rejected');
for my $Name (qw(JobEvents WorkflowNodes)) {
    $R = $Objects{$Name}->PrepareRequest(Data => {JobID => 8, page => 2});
    is($R->{Data}{page}, 2, "$Name explicit pagination");
    is($R->{Data}{page_size}, 100, "$Name bounded default");
    ok(!$Objects{$Name}->PrepareRequest(Data => {JobID => 8, page_size => 201})->{Success}, 'oversized page rejected');
    my $D = {count => 2, next => 'https://untrusted/never-follow-automatically', previous => undef, results => [{event_data => {res => {nested => [1,2]}}}]};
    $R = $Objects{$Name}->HandleResponse(ResponseSuccess => 1, Data => $D);
    is_deeply($R->{Data}{Response}, $D, "$Name entire page preserved");
    ok(!$Objects{$Name}->HandleResponse(ResponseSuccess => 1, Data => {count => 1, results => 'bad'})->{Success}, 'invalid collection rejected');
}
done_testing();
