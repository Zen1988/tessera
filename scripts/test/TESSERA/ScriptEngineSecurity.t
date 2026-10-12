use strict;
use warnings;
use Test::More;
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptEngine;
my $E = Kernel::System::TESSERA::ScriptEngine->new(SearchProvider => sub { die 'must not search' });
my $Cycle = {}; $Cycle->{RETURN} = $Cycle;
for my $Case (
    ['cycle', $Cycle],
    ['code reference', {RETURN => sub { die 'must not execute' }}],
    ['blessed object', {RETURN => bless({}, 'Malicious')}],
    ['scalar reference', {RETURN => \1}],
    ['expanded size', {RETURN => [('x' x 140000) x 8]}],
) {
    ok(!$E->ScriptParse(Script => $Case->[1])->{Success}, "$Case->[0] rejected");
}
my $Deep = {RETURN => 1}; for (1..34) { $Deep = {RETURN => $Deep} }
ok(!$E->ScriptParse(Script => $Deep)->{Success}, 'excessive depth rejected');
for my $Source (
    "VERSION: 1\nRETURN: 1\nRETURN: 2\n",
    "RETURN: 1\n---\nRETURN: 2\n",
    "RETURN: &loop [*loop]\n",
    'x' x 376201,
    "RETURN: [broken\n",
) {
    my $Loaded = eval { $E->ScriptSourceLoad(Source => $Source); 1 };
    ok(!$Loaded, 'unsafe YAML rejected');
    unlike($@, qr/broken|RETURN:|loop/, 'diagnostic excludes source');
}
my $Loaded = $E->ScriptSourceLoad(Source => "VERSION: 1\nSEARCH: []\nRETURN: &value hello\nREQUIRE: [*value]\n");
is($Loaded->{RETURN}, 'hello', 'ordinary scalar anchors retained');
ok(!eval { $E->ScriptSourceLoad(Source => "RETURN: !!perl/code 'die q(unsafe)'\n"); 1 }, 'code tags rejected');
ok(!$E->ScriptEvaluate(Parsed => {Success => 1, Script => {VERSION => 9, RETURN => 1}, Searches => []})->{Success}, 'forged parsed version rejected');
ok(!$E->ScriptEvaluate(Parsed => {Success => 1, Script => {SEARCH => {FOR => 'Ticket', AS => 'X', LIMIT => 1001}, RETURN => 1}, Searches => []})->{Success}, 'forged parsed search limit rejected before provider');
ok(!$E->ScriptParse(Script => {RETURN => 1, SQL => 'DELETE'})->{Success}, 'unknown top-level operation rejected');
ok(!$E->ScriptParse(Script => {RETURN => 1, SEARCH => {FOR => [], CLASS => 'X', AS => 'Y'}})->{Success}, 'non-scalar search routing rejected');
ok(!$E->FieldAssignmentsEvaluate(Source => 'x' x 376201)->{Success}, 'assignment source bounded');
ok(!$E->FieldAssignmentsEvaluate(Script => $Cycle)->{Success}, 'assignment tree checked');
is($E->Evaluate(Source => 'x' x 376201)->{Status}, 'UNKNOWN', 'legacy policy source bounded');
ok(!$E->ProgramParse(Source => [1])->{Success}, 'legacy program source type checked');
my $Nested = '1'; $Nested = 'NUMBER(' . $Nested . ')' for 1..40;
ok(!$E->ValueEvaluate(Expression => $Nested)->{Known}, 'deep expressions rejected');
ok(!$E->ScriptEvaluate(Script => {SEARCH => {FOR => 'Ticket', AS => 'T'}, RETURN => 1}, AllowedSearchType => 'ITSMConfigItem.Product')->{Success}, 'stored selection cannot search unrelated objects before typed return');
done_testing();
