use strict;use warnings;use Test::More;use XML::LibXML;use YAML::XS qw(Load);
use lib 'Kernel/Package/GovernanceDB','.';use Kernel::System::TESSERA::RiskRegister;
my $doc=XML::LibXML->load_xml(location=>'Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/GovernanceDB.xml');my($item)=$doc->findnodes('//Setting[@Name="TESSERA::RiskRegister::Columns"]/Value/Item');
is($item->getAttribute('ValueType'),'YAML','native YAML editor selected');my $yaml=$item->textContent;my $columns=Load($yaml);is(ref $columns,'ARRAY','default parses into ordered mappings');is(scalar @$columns,13,'all thirteen initial columns present');
{package YAMLMappingOM;sub Get{my($S,$name)=@_;return $S->{YAML} if $name eq 'TESSERA::RiskRegister::Columns';return $S}sub Load{my($S,%P)=@_;YAML::XS::Load($P{Data})}sub DynamicFieldGet{return{ID=>1,FieldType=>'Text'}}}
local $Kernel::OM=bless {YAML=>$yaml},'YAMLMappingOM';my $R=Kernel::System::TESSERA::RiskRegister->new;is_deeply($R->Columns,$columns,'runtime loads actual packaged YAML setting');$Kernel::OM->{YAML}='invalid scalar';eval{$R->Columns};like($@,qr/mapping is missing/,'malformed mapping shape blocked');done_testing;
