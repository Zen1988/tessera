use strict;use warnings;use Test::More;use YAML::XS ();use Storable qw(dclone);
use lib '.', 'Custom', 'Kernel/cpan-lib';
use Kernel::System::TESSERA::ApplicationNavisInstaller;
{
 package AppInstallOM;
 sub Get {$_[0]}
 sub DynamicFieldGet {$_[0]{Field}}
 sub DynamicFieldAdd {my ($S,%P)=@_;$S->{Adds}++;$S->{Field}={ID=>77,%P};return 77}
 sub EventHandlerTransaction {1}
 sub ItemList {{9=>'Application'}}
 sub DefinitionGet {my ($S)=@_;return {Definition=>YAML::XS::Dump($S->{Definition}),DynamicFieldRef=>$S->{Fields} || {}}}
 sub Load {my ($S,%P)=@_;YAML::XS::Load($P{Data})}
 sub Dump {my ($S,%P)=@_;YAML::XS::Dump($P{Data})}
 sub DefinitionAdd {my ($S,%P)=@_;$S->{Versions}++;$S->{Definition}=YAML::XS::Load($P{Definition});$S->{Fields}={Navis=>{}};return {Success=>1}}
}
my $Original={Pages=>[{Name=>'Custom summary',Interfaces=>['Agent'],Content=>[{Section=>'General Fields::Application'}]}],Roles=>{'General Fields'=>{Name=>'My custom Application role'}},Sections=>{Existing=>{Content=>[{Header=>'Preserved'}]}}};
my $OM=bless {Definition=>dclone($Original)},'AppInstallOM';local $Kernel::OM=$OM;
my $I=Kernel::System::TESSERA::ApplicationNavisInstaller->new();
ok($I->Ensure(),'existing/fresh Application gets optional label field and page');
is($OM->{Field}{Name},'Navis','exact owner-selected field name');is($OM->{Field}{ObjectType},'GovernanceObject','native GO field');is($OM->{Field}{FieldType},'Text','stable label text, not UUID binding');
my $Regex=$OM->{Field}{Config}{RegExList}[0]{Value};like('Application 1',qr/$Regex/,'native Text regex accepts spaced labels');like('',qr/$Regex/,'label remains optional');unlike(' leading',qr/$Regex/,'surrounding whitespace rejected');unlike("bad\nname",qr/$Regex/,'control characters rejected');unlike('x'x256,qr/$Regex/,'label length is bounded');
is_deeply($OM->{Definition}{Pages}[0],$Original->{Pages}[0],'existing page retained');is_deeply($OM->{Definition}{Roles},$Original->{Roles},'custom role binding retained');is_deeply($OM->{Definition}{Sections}{Existing},$Original->{Sections}{Existing},'existing section retained');
is($OM->{Definition}{Pages}[1]{Name},'Navis','separate optional Agent page');is($OM->{Definition}{Sections}{Navis}{Content}[0]{DF},'Navis','native field reference');
ok($I->Ensure(),'same-version reinstall succeeds');is($OM->{Adds},1,'no duplicate field');is($OM->{Versions},1,'no repeated definition version');
$OM->{Field}{Label}='Site graph label';ok($I->Ensure(),'compatible administrator label retained');is($OM->{Field}{Label},'Site graph label','label not overwritten');
my $Bad=bless {Definition=>dclone($Original),Field=>{Name=>'Navis',ObjectType=>'Ticket',FieldType=>'Text',ValidID=>1,Config=>{}}},'AppInstallOM';$Kernel::OM=$Bad;
ok(!eval {$I->Ensure();1},'incompatible existing name fails before mutation');ok(!$Bad->{Adds} && !$Bad->{Versions},'no field or layout mutation on conflict');
my $Collision=bless {Definition=>dclone($Original)},'AppInstallOM';push @{$Collision->{Definition}{Pages}},{Name=>'Navis',Content=>[{Section=>'Existing'}]};$Kernel::OM=$Collision;
ok(!eval {$I->Ensure();1},'administrator-owned Navis page collision requires review');ok(!$Collision->{Adds} && !$Collision->{Versions},'layout preflight precedes field creation');
done_testing();
