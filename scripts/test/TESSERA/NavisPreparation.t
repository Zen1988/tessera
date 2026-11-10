use strict;
use warnings;
use Test::More;
use YAML::XS qw(LoadFile);
use lib '.';
use Kernel::System::TESSERA::ScriptEngine;
my $Script=LoadFile('examples/navis/automation.yml');
my @Calls;
my $Engine=Kernel::System::TESSERA::ScriptEngine->new(WebServiceProvider=>sub {
    my %P=@_; push @Calls,\%P; return {Success=>1,Data=>{AnalysisID=>'a'x40}};
});
my $R=$Engine->ScriptEvaluate(Script=>$Script,UserID=>9);
ok($R->{Success},'Navis preparation uses real existing script grammar');
is($R->{Value},'a'x40,'returns durable TESSERA analysis reference');
is(scalar @Calls,1,'one TESSERA-controlled analysis');
is($Calls[0]{Invoker},'NavisAnalyze','intelligence remains in TESSERA');
is($Calls[0]{Data}{action},'allow','requested action retained locally');
is($Calls[0]{Data}{destination_port},443,'port retained');
my $NoProvider=Kernel::System::TESSERA::ScriptEngine->new();
ok(!$NoProvider->ScriptEvaluate(Script=>$Script)->{Success},'no ambient network authority');
for my $File (glob('examples/navis/*.yml')) {
    ok(eval {LoadFile($File); 1},"YAML parses: $File");
}
done_testing();
