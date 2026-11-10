use strict;
use warnings;
use Test::More;
use lib '.';
use Kernel::System::TESSERA::ScriptEngine;
my $Script={VERSION=>1,'CALL WEB SERVICE'=>[
 {SERVICE=>'Inventory',INVOKER=>'InventorySync',AS=>'SYNC',WITH=>{InventoryID=>7,Hosts=>[{ConfigItemID=>1,Address=>'127.0.0.1'}]}},
 {SERVICE=>'AWX',INVOKER=>'JobLaunchCallback',AS=>'RUN',WITH=>{inventory=>'EXTERNAL.SYNC.InventoryID',limit=>'EXTERNAL.SYNC.Limit',TemplateID=>42}}],
 RETURN=>{VALUE=>'EXTERNAL.RUN.ExecutionUID'}};
my $E=Kernel::System::TESSERA::ScriptEngine->new();
ok(!$E->ScriptEvaluate(Script=>$Script)->{Success},'authored web calls have no ambient network permission');
my @Calls;
$E=Kernel::System::TESSERA::ScriptEngine->new(WebServiceProvider=>sub {my %P=@_;push @Calls,\%P;
 return {Success=>1,Data=>$P{Invoker} eq 'InventorySync'?{InventoryID=>7,Limit=>'tessera-ci-1'}:{ExecutionUID=>'A'x40}};});
my $R=$E->ScriptEvaluate(Script=>$Script,UserID=>9);
ok($R->{Success},'authorized provider executes configured pipeline');is($R->{Value},'A'x40,'script returns durable execution reference');
is($Calls[1]{Data}{inventory},7,'earlier result resolves into next call');is($Calls[1]{Data}{limit},'tessera-ci-1','sync target limit propagated');is($Calls[0]{UserID},9,'actor passed to trusted provider');
@Calls=();ok(!$E->ScriptEvaluate(Script=>$Script,AllowedSearchType=>'ITSMConfigItem.Product')->{Success},'stored selection cannot gain network effects');is(scalar @Calls,0,'selection denied before effect');
$E=Kernel::System::TESSERA::ScriptEngine->new(WebServiceProvider=>sub {push @Calls,1;return {Success=>0}});
ok(!$E->ScriptEvaluate(Script=>$Script)->{Success},'failed sync stops script');is(scalar @Calls,1,'launch not reached after failed sync');
for my $Call ({SERVICE=>'https://arbitrary',INVOKER=>'Run',AS=>'X',WITH=>{}},{SERVICE=>'A',INVOKER=>'Run',AS=>'X',WITH=>{},URL=>'x'}) {
 ok(!$E->ScriptParse(Script=>{'CALL WEB SERVICE'=>$Call,RETURN=>1})->{Success},'URL/extra call fields rejected');
}
$E=Kernel::System::TESSERA::ScriptEngine->new(WebServiceProvider=>sub {die 'private-secret'});
$R=$E->ScriptEvaluate(Script=>$Script);ok(!$R->{Success},'provider exceptions fail closed');unlike($R->{Error},qr/private-secret/,'provider diagnostics not leaked');
done_testing();
