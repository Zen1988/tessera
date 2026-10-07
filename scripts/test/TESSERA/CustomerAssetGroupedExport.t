use strict;
use warnings;
use Test::More;
use Archive::Zip;
use JSON::PP;
require './Kernel/Package/GovernanceDB/Kernel/System/ZTSMWorkbookXLSX.pm';
my $Writer=Kernel::System::ZTSMWorkbookXLSX->new();
my $SourcePath='Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerITSMConfigItem.pm';
open my $FH,'<',$SourcePath or die $!;
my $Source=do {local $/;<$FH>};
my ($Export)=$Source =~ /(sub _ZTSMAssetExport \{.*?)(?=sub _ZTSMVirtualFilterApply)/s;
eval "package GroupedAssetPage; sub IsHashRefWithData {ref \$_[0] eq 'HASH' && keys %{\$_[0]}} $Export;1" or die $@;
{
 package GroupedAssetOM;
 sub Get {my($S,$Name)=@_;return $S->{Writer} if $Name eq 'Kernel::System::ZTSMWorkbookXLSX'; return $S;}
 sub Create {$_[0]}
 sub Format {'2026-10-06_15-00'}
 sub Attachment {my($S,%P)=@_;return \%P;}
 sub Encode {my($S,%P)=@_;return JSON::PP->new->encode($P{Data});}
 sub ConfigItemGet {my($S,%P)=@_;push @{$S->{ReadIDs}},$P{ConfigItemID};return $S->{Items}{$P{ConfigItemID}};}
 sub DefinitionGet {my($S,%P)=@_;return $S->{Definitions}{$P{DefinitionID}};}
 sub ValueGet {my($S,%P)=@_;return $S->{Values}{$P{ObjectID}}{$P{DynamicFieldConfig}{Name}};}
 sub DisplayValueRender {my($S,%P)=@_;return {Title=>$P{Value},Value=>$P{Value}};}
}
my @Classes=qw(Workload NetworkNode FacilityEquipment PeripheralNode Product);
my @Types=qw(ZTAM-WorkloadType ZTAM-NetworkNodeType ZTAM-FacilityEquipmentType ZTAM-PeripheralNodeType ProductField);
local $Kernel::OM=bless {Writer=>$Writer,Items=>{},Definitions=>{},Values=>{},ReadIDs=>[]},'GroupedAssetOM';
for my $I (1..5) {
 $Kernel::OM->{Items}{$I}={ConfigItemID=>$I,VersionID=>$I,DefinitionID=>$I,Number=>'000'.$I,
 Name=>($I==1?'=literal asset':'Asset '.$I),Class=>$Classes[$I-1],CurDeplState=>'Production'};
 my $Field={Name=>$Types[$I-1],FieldType=>'Text',Config=>{}};
 $Kernel::OM->{Definitions}{$I}={DynamicFieldRef=>{$Types[$I-1]=>$Field}};
 $Kernel::OM->{Values}{$I}{$Types[$I-1]}='Type '.$I;
}
$Kernel::OM->{Definitions}{1}{DynamicFieldRef}{ExistingSet}={Name=>'ExistingSet',FieldType=>'Set',Config=>{}};
$Kernel::OM->{Values}{1}{ExistingSet}={Value=>['structured value']};
my $Page=bless {},'GroupedAssetPage';
my $Result=$Page->_ZTSMAssetExport(ConfigItemIDs=>[1..5]);
is_deeply($Kernel::OM->{ReadIDs},[1..5],'export reads only the supplied authorized asset set');
is($Result->{ContentType},'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','actual XLSX download');
my $Zip=Archive::Zip->new();open my $Memory,'<',\$Result->{Content} or die $!;
is($Zip->readFromFileHandle($Memory),0,'generated export is a valid ZIP workbook');
my $Workbook=$Zip->contents('xl/workbook.xml');
for my $Class (@Classes) {like($Workbook,qr/name="$Class"/,'worksheet for represented '.$Class);}
is(scalar(()=$Workbook=~/<sheet /g),5,'five represented classes create five tabs, no fixed four-tab cap');
my $Strings=$Zip->contents('xl/sharedStrings.xml');
like($Strings,qr/>Number</,'Number retained in export');like($Strings,qr/>Class</,'Class retained in export');
like($Strings,qr/structured value/,'structured CMDB field contents retained as JSON');
like($Strings,qr/>0001</,'leading-zero CMDB number preserved');like($Strings,qr/>=literal asset</,'literal leading equals text retained');
for my $Type (@Types) {like($Strings,qr/\Q$Type\E/,'actual class field name exported');}
for my $I (1..5) {
 my $Sheet=$Zip->contents("xl/worksheets/sheet$I.xml");
 is(scalar(()=$Sheet=~/<row /g),2,'one header and one asset per class sheet');
 is(scalar(()=$Sheet=~/<c /g), $I==5 ? 12 : 10, 'each class exports only its own field schema');
 unlike($Sheet,qr/<f[ >]/,'user values never become Excel formulas');
}
# Invalid and colliding class sheet names are safe and unique.
my $Other=$Writer->ExportSheets(Sheets=>[map {{Name=>$_,Head=>['Number'],Data=>[['001']]}} ('A/B','A:B','a_b')]);
my $OtherZip=Archive::Zip->new();open my $OtherMemory,'<',\$Other; $OtherZip->readFromFileHandle($OtherMemory);
my $Names=$OtherZip->contents('xl/workbook.xml');
like($Names,qr/name="A_B"/,'invalid sheet-name characters sanitized');
like($Names,qr/name="A_B_2"/,'sanitized collision gets unique suffix');
like($Names,qr/name="a_b_3"/,'case-insensitive sheet collision resolved');
done_testing();
