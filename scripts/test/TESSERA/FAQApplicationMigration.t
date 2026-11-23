use strict;use warnings;use Test::More;
my $Root=$ENV{TESSERA_TEST_PACKAGE_ROOT} || 'Kernel/Package/GovernanceDB';
open my $FH,'<:encoding(UTF-8)',"$Root/Kernel/System/GovernanceDB/Bootstrap.pm" or die $!;
my $Source=do{local $/;<$FH>};my($Methods)=$Source=~/(sub _FAQApplicationFieldEnsure.*?)(?=sub _CustomerUserPreferenceDynamicFieldsEnsure)/s;
eval "package FAQMigrationBootstrap; $Methods; 1" or die $@;
{package FAQMigrationFixture;
 sub DynamicFieldGet {my($S,%P)=@_;return $S->{Fields}{$P{Name}} || {}}
 sub DynamicFieldAdd {my($S,%P)=@_;push @{$S->{Events}},'create';$S->{Fields}{$P{Name}}={%P,ID=>88};$S->{Adds}++;return 88}
 sub DynamicFieldUpdate {my($S,%P)=@_;push @{$S->{Events}},'rename';delete $S->{Fields}{'ZFAQ-Application'};$S->{Fields}{$P{Name}}=\%P;$S->{Updates}++;return 1}
 sub ItemList {{6=>'Application'}}
 sub EventHandlerTransaction {1}
 sub ConfigurationXML2DB {my($S)=@_;push @{$S->{Events}},'native-registration-import';return if $S->{ImportFail};$S->{Settings}{'DynamicFields::ObjectType###FAQ'}={IsValid=>1,EffectiveValue=>{Module=>'Kernel::System::DynamicField::ObjectType::FAQ'}};$S->{Settings}{'DynamicFields::Driver###GovernanceObject'}={IsValid=>1,EffectiveValue=>{Module=>'Kernel::System::DynamicField::Driver::GovernanceObject'}};return 1}
 sub SettingGet {my($S,%P)=@_;return %{$S->{Settings}{$P{Name}} || {}}}
 sub SettingsSet {my($S,%P)=@_;for my $Setting (@{$P{Settings}}){$S->{Settings}{$Setting->{Name}}={%$Setting};push @{$S->{Events}},'deploy:'.$Setting->{Name}}return 1}
}
{package FAQMigrationOM;sub Get {$_[0]{Fixture}}}
sub fixture {
 my $F=bless {Fields=>{},Settings=>{},Events=>[],Values=>{21=>{7=>[101,102]}},Adds=>0,Updates=>0},'FAQMigrationFixture';
 $Kernel::OM=bless {Fixture=>$F},'FAQMigrationOM';return $F;
}
my $B=bless {},'FAQMigrationBootstrap';
my $F=fixture();
ok($B->_FAQApplicationFieldEnsure(),'fresh install imports missing native registration before creating field');
is_deeply($F->{Events},['native-registration-import','create'],'registration exists before the field API is called');
is($F->{Fields}{FAQApplication}{ObjectType},'FAQ','new field uses native FAQ object type');
is($F->{Fields}{FAQApplication}{Name},'FAQApplication','new field has owner-approved unprefixed name');
ok(!exists $F->{Fields}{'ZFAQ-Application'},'no ZFAQ namespace or prefixed field is created');
is($F->{Adds},1,'one new field');
$B->_FAQApplicationFieldEnsure();is($F->{Adds},1,'same-version reinstall is idempotent');

$F=fixture();$F->{Fields}{'ZFAQ-Application'}={ID=>21,Name=>'ZFAQ-Application',Label=>'Application',ObjectType=>'FAQ',FieldType=>'GovernanceObject',FieldOrder=>10300,ValidID=>1,Config=>{ClassIDs=>[6],MultiValue=>1,AdminOwned=>'keep'}};
ok($B->_FAQApplicationFieldEnsure(),'compatible legacy field is migrated');
is($F->{Fields}{FAQApplication}{ID},21,'migration preserves field ID');
is($F->{Fields}{FAQApplication}{Config}{AdminOwned},'keep','migration preserves administrator configuration');
is_deeply($F->{Values},{21=>{7=>[101,102]}},'FAQ application values stay attached to the same field ID');
is($F->{Adds},0,'migration does not create a duplicate field');
is($F->{Updates},1,'migration performs one rename');
$B->_FAQApplicationFieldEnsure();is($F->{Updates},1,'rename is not repeated on reinstall');
for my $Screen (qw(AgentFAQAdd AgentFAQEdit)) {$F->{Settings}{'FAQ::Frontend::'.$Screen.'###DynamicField'}={EffectiveValue=>{'ZFAQ-Application'=>0,Other=>2}}}
$B->_FAQApplicationScreensEnsure();
is_deeply($F->{Settings}{'FAQ::Frontend::AgentFAQEdit###DynamicField'}{EffectiveValue},{FAQApplication=>0,Other=>2},'screen key migration preserves an existing disabled override and unrelated fields');

$F->{Fields}{'ZFAQ-Application'}={ID=>22,ObjectType=>'FAQ',FieldType=>'GovernanceObject'};
eval{$B->_FAQApplicationFieldEnsure()};like($@,qr/Both FAQApplication and ZFAQ-Application exist/,'two existing fields require explicit merge rather than data loss');
is(scalar keys %{$F->{Fields}},2,'both conflicting records remain untouched');

$F=fixture();$F->{ImportFail}=1;
eval{$B->_FAQApplicationFieldEnsure()};like($@,qr/Cannot import native Dynamic Field registration/,'missing registration produces a distinct installation error');
is($F->{Adds},0,'field creation is never attempted without required registration');

$F=fixture();$F->ConfigurationXML2DB();$F->{Settings}{'DynamicFields::ObjectType###FAQ'}{IsValid}=0;
$F->{Settings}{'DynamicFields::Driver###GovernanceObject'}{EffectiveValue}{ObjectTypes}=['Ticket','CustomerUser'];
$B->_FAQApplicationFieldEnsure();
is($F->{Settings}{'DynamicFields::ObjectType###FAQ'}{IsValid},1,'native FAQ registration is enabled before creation');
is_deeply($F->{Settings}{'DynamicFields::Driver###GovernanceObject'}{EffectiveValue}{ObjectTypes},['Ticket','CustomerUser','FAQ'],'restricted driver retains existing object types and adds FAQ');
$B->_FAQApplicationFieldEnsure();is_deeply($F->{Settings}{'DynamicFields::Driver###GovernanceObject'}{EffectiveValue}{ObjectTypes},['Ticket','CustomerUser','FAQ'],'driver registration does not accumulate duplicates');

$F=fixture();$F->ConfigurationXML2DB();$F->{Settings}{'DynamicFields::Driver###GovernanceObject'}{EffectiveValue}{Module}='Administrator::OtherDriver';
eval{$B->_FAQApplicationFieldEnsure()};like($@,qr/Conflicting Dynamic Field handler/,'unknown administrator driver is not overwritten');
is($F->{Adds},0,'conflicting handler stops before creating field');
done_testing;
