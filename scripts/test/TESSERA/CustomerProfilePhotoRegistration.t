use strict; use warnings; use Test::More; use XML::LibXML;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::SysConfig::ValueType::FrontendRegistration;
my $Doc=XML::LibXML->load_xml(location=>'Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/GovernanceDB.xml');
my @Items;
for my $Item ($Doc->findnodes('//Setting[@Name="CustomerFrontend::Module###CustomerProfilePhoto"]/Value/Item/Hash/Item')) {
 my %I=(Key=>$Item->getAttribute('Key'),Content=>$Item->textContent);
 $I{Array}=[{}] if $Item->findnodes('Array');push @Items,\%I;
}
my $Validator=Kernel::System::SysConfig::ValueType::FrontendRegistration->new();
my $Value=$Validator->EffectiveValueGet(Value=>[{Hash=>[{Item=>\@Items}]}]);
my %Result=$Validator->SettingEffectiveValueCheck(XMLContentParsed=>{Value=>[]},EffectiveValue=>$Value);
ok($Result{Success},'actual XML photo registration passes native OTOBO validator');is($Value->{NavBarName},'','non-navigation endpoint defines required empty NavBarName');
my %Broken=%$Value;delete $Broken{NavBarName};my %Rejected=$Validator->SettingEffectiveValueCheck(XMLContentParsed=>{Value=>[]},EffectiveValue=>\%Broken);ok(!$Rejected{Success},'native validator reproduces 123 failure');like($Rejected{Error},qr/NavBarName/,'missing key explains deployment failure');
open my $FH,'<','Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm' or die $!;my $Source=do{local $/;<$FH>};$Source=~/(sub _CustomerPhotoRegistrationRepair \{.*?)(?=sub _SysConfigDeploy)/s or die 'repair not found';eval 'package PhotoRegistrationRepair;'.$1;die $@ if $@;
{ package RegistrationOM;sub Get{$_[0]}sub SettingGet{my($S,%P)=@_;return (IsValid=>1,EffectiveValue=>$S->{Value});}sub SettingsSet{my($S,%P)=@_;$S->{Writes}++;$S->{Value}=$P{Settings}[0]{EffectiveValue};return 1;}}
local $Kernel::OM=bless {Value=>{Description=>'Administrator description',Title=>'Custom photo title',Group=>['custom-group']},Writes=>0},'RegistrationOM';
my $Repair=bless {},'PhotoRegistrationRepair';ok($Repair->_CustomerPhotoRegistrationRepair(),'existing missing-key override repaired');is($Kernel::OM->{Value}{NavBarName},'','repair sets only missing required key');is($Kernel::OM->{Value}{Title},'Custom photo title','administrator title preserved');is_deeply($Kernel::OM->{Value}{Group},['custom-group'],'administrator access groups preserved');ok($Repair->_CustomerPhotoRegistrationRepair(),'same-version repair idempotent');is($Kernel::OM->{Writes},1,'repeat does not write again');
done_testing;
