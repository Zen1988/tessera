use strict;use warnings;use Test::More;use JSON::PP ();use Storable qw(dclone);use lib '.', 'Custom', 'Kernel/cpan-lib';
use Kernel::System::TESSERA::ChangeClassificationInstaller;
{
 package CCI;
 sub Get {$_[0]}
 sub SettingGet {my ($S)=@_;return (IsValid=>1,EffectiveValue=>Storable::dclone($S->{Registration}))}
 sub GlobalEffectiveValueGet {my ($S)=@_;return $S->{Override}?{Module=>'Override'}:$S->{Registration}}
 sub SettingsSet {my ($S,%P)=@_;$S->{Registration}=Storable::dclone($P{Settings}[0]{EffectiveValue});$S->{ConfigWrites}++;return 1}
 sub DynamicFieldGet {my ($S,%P)=@_;return $S->{Fields}{$P{Name}} || {}}
 sub DynamicFieldAdd {my ($S,%P)=@_;return if $S->{FailCreate};$S->{Creates}++;$P{ID}=$S->{Creates};$S->{Fields}{$P{Name}}=Storable::dclone(\%P);return $P{ID}}
 sub EventHandlerTransaction {1}
 sub TypeGet {my ($S)=@_;return (ID=>50,Name=>'Change::Major',ValidID=>$S->{LegacyValidity})}
 sub ValidLookup {2}
 sub TypeUpdate {my ($S,%P)=@_;$S->{LegacyValidity}=$P{ValidID};$S->{TypeUpdates}++;return 1}
}
my $M=bless {Registration=>{Module=>'Kernel::System::DynamicField::Driver::Dropdown',DisplayName=>'Dropdown',ConfigDialog=>'AdminDynamicFieldDropdown',ObjectTypes=>[]},Fields=>{},LegacyValidity=>1},'CCI';
local $Kernel::OM=$M;my $B=Kernel::System::TESSERA::ChangeClassificationInstaller->new();
ok($B->Ensure(),'fresh installation succeeds with native missing-field empty hash');
is($M->{Creates},2,'exactly two fields created');
is($M->{Fields}{ChangeType}{FieldType},'Dropdown','ChangeType is native Dropdown');
is($M->{Fields}{ChangeType}{Config}{DefaultValue},'Normal','ChangeType default Normal');
is_deeply($M->{Fields}{ChangeType}{Config}{PossibleValues},{Normal=>'Normal',Standard=>'Standard',Emergency=>'Emergency'},'exact change type options');
is($M->{Fields}{ChangeClassification}{Config}{DefaultValue},'Not-Assessed','classification defaults Not-Assessed');
is_deeply($M->{Fields}{ChangeClassification}{Config}{PossibleValues},{Normal=>'Normal','Not-Assessed'=>'Not-Assessed',Major=>'Major'},'exact classification options');
is($M->{Registration}{Module},'Kernel::System::DynamicField::Driver::TESSERAChangeDropdown','protected write driver registered');
is_deeply($M->{Registration}{ObjectTypes},[],'unrestricted native driver remains unrestricted');
is($M->{LegacyValidity},2,'existing obsolete type retired without deleting its ID');
ok($B->Ensure(),'same-version reinstall succeeds');is($M->{Creates},2,'reinstall creates no duplicate fields');is($M->{ConfigWrites},1,'reinstall does not rewrite driver settings');is($M->{TypeUpdates},1,'reinstall does not repeatedly update retired type');
my $ID=$M->{Fields}{ChangeClassification}{ID};$M->{Fields}{ChangeClassification}{Label}='Administrator label';
ok($B->Ensure(),'compatible existing field retained');is($M->{Fields}{ChangeClassification}{ID},$ID,'existing field ID and values remain attached');is($M->{Fields}{ChangeClassification}{Label},'Administrator label','administrator presentation retained');
$M->{Fields}{ChangeClassification}{ObjectType}='Article';
ok(!eval {$B->Ensure();1},'conflicting existing field is rejected');is($M->{Fields}{ChangeClassification}{ObjectType},'Article','conflicting record not overwritten');$M->{Fields}{ChangeClassification}{ObjectType}='Ticket';
$M->{Registration}{Module}='Kernel::System::CustomDropdown';
ok(!eval {$B->Ensure();1},'unknown third-party Dropdown override requires a compatibility merge');is($M->{Registration}{Module},'Kernel::System::CustomDropdown','third-party configuration preserved');
$M->{Registration}{Module}='Kernel::System::DynamicField::Driver::TESSERAChangeDropdown';$M->{Override}=1;
ok(!eval {$B->Ensure();1},'file override cannot silently disable classification backend guard');
done_testing();
