use strict;
use warnings;
use Test::More;
use lib '.';
use Kernel::System::TESSERA::ScriptEngine;
my $E = Kernel::System::TESSERA::ScriptEngine->new();
my $Context = {EXTERNAL => {JobID => 8, Status => 'successful', Response => {
    artifacts => {tessera_result => {message => 'hello from Ansible', count => 2}},
    results => [{event => 'runner_on_ok', event_data => {res => {changed => 0}}}, {event => 'runner_on_failed', event_data => {res => {msg => 'example failure'}}}],
    content => "verbose stdout\nsecond line",
}}};
for my $Case (
    ['EXTERNAL.Status', 'successful'],
    ['EXTERNAL.Response.artifacts.tessera_result.message', 'hello from Ansible'],
    ['EXTERNAL.Response.artifacts.tessera_result.count', 2],
    ['EXTERNAL.Response.results[event=runner_on_failed].event_data.res.msg', 'example failure'],
    ['EXTERNAL.Response.content', "verbose stdout\nsecond line"],
) {
    my $R = $E->ScriptEvaluate(Script => {VERSION => 1, RETURN => {VALUE => $Case->[0]}}, Context => $Context);
    ok($R->{Success}, "$Case->[0] readable");
    is($R->{Value}, $Case->[1], 'value preserved');
}
ok(!$E->ScriptEvaluate(Script => {RETURN => {VALUE => 'EXTERNAL.missing'}}, Context => $Context)->{Success}, 'missing external field fails closed');
ok(!$E->ScriptEvaluate(Script => {RETURN => {VALUE => 'EXTERNAL.Status'}}, Context => {EXTERNAL => bless({}, 'Bad')})->{Success}, 'external object rejected');
ok(!$E->ScriptParse(Script => {RETURN => 1, HTTP => 'https://example.invalid'})->{Success}, 'no HTTP operation introduced');
done_testing();
