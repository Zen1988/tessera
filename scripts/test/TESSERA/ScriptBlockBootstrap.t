use strict;use warnings;use Test::More;use JSON::PP qw(decode_json);use lib 'Kernel/Package/GovernanceDB','.';
open my $F,'<','Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm' or die $!;local $/;my $Source=<$F>;close $F;
my ($Method)=$Source=~/(sub _ScriptBlockFieldsEnsure \{.*)\z/s;eval "package BlockBootstrap; $Method";die $@ if $@;
{package BlockBootstrap;sub _DynamicFieldUpdateForce {my($Self,%P)=@_;$Kernel::OM->{Fields}{$P{Name}}={%P};$Kernel::OM->{Updates}++;1}}
{package BlockOM;sub Get{$_[0]}sub GetHome{1}sub FileRead{my($S,%P)=@_;open my $F,'<',$P{Location} or die $!;local $/;my $C=<$F>;return \$C}sub Decode{my($S,%P)=@_;JSON::PP::decode_json($P{Data})}sub DynamicFieldGet{my($S,%P)=@_;return $S->{Fields}{$P{Name}}}sub DynamicFieldAdd{my($S,%P)=@_;$S->{Fields}{$P{Name}}={%P};$S->{Adds}++;1}sub EventHandlerTransaction{1}}
# Config Get shares the object-manager name; return Home only for config lookup.
{no warnings 'redefine';*BlockOM::Get=sub{my($S,$Name)=@_;return 'Kernel/Package/GovernanceDB' if $Name eq 'Home';return $S}}
local $Kernel::OM=bless {Fields=>{},Adds=>0,Updates=>0},'BlockOM';my $B=bless {},'BlockBootstrap';
ok($B->_ScriptBlockFieldsEnsure(),'fresh fields created');my $Count=$Kernel::OM->{Adds};ok($Count>=9,'exported wrappers and members created');
is($Kernel::OM->{Fields}{'ZTemplate-ScriptIndex'}{Config}{RegExList}[0]{Value},'^[1-9][0-9]?$','fresh index accepts 1..99');
ok($B->_ScriptBlockFieldsEnsure(),'same-version reinstall');is($Kernel::OM->{Adds},$Count,'reinstall creates no duplicate fields');is($Kernel::OM->{Updates},0,'reinstall leaves current definitions unchanged');
$Kernel::OM->{Fields}{'ZTemplate-ScriptIndex'}{Config}{RegExList}[0]{Value}='^[0-9]$';
$Kernel::OM->{Fields}{'ZTAM-ConditionIndex'}{Config}{RegExList}[0]{Value}='custom';
ok($B->_ScriptBlockFieldsEnsure(),'upgrade old index');is($Kernel::OM->{Updates},1,'only shipped single-digit rule updated');is($Kernel::OM->{Fields}{'ZTAM-ConditionIndex'}{Config}{RegExList}[0]{Value},'custom','custom admin rule preserved');
ok($B->_ScriptBlockFieldsEnsure(),'future repeated upgrade');is($Kernel::OM->{Updates},1,'upgrade remains idempotent');done_testing();
