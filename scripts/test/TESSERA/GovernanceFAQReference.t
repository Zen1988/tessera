use strict;
use warnings;
use Test::More;

my $BootstrapPath = 'Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm';
open my $BootstrapFH, '<:raw', $BootstrapPath or die "Cannot read $BootstrapPath: $!";
local $/;
my $Bootstrap = <$BootstrapFH>;
close $BootstrapFH;

unlike(
    $Bootstrap,
    qr/_DynamicFieldDriverObjectTypeEnsure\(\s*Driver\s*=>\s*'FAQ',\s*ObjectType\s*=>\s*'GovernanceObject'/s,
    'bootstrap does not rewrite an existing FAQ Dynamic Field driver setting',
);
like(
    $Bootstrap,
    qr/'DynamicFields::Driver###FAQ'/,
    'FAQ driver registration is included in SysConfig deployment',
);

for my $XMLPath (
    'Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/GovernanceDB.xml',
    'Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/ZTSMGovernanceRuntime.xml',
) {
    open my $XMLFH, '<:raw', $XMLPath or die "Cannot read $XMLPath: $!";
    my $XML = <$XMLFH>;
    close $XMLFH;
    like(
        $XML,
        qr{<Setting Name="DynamicFields::Driver###FAQ".*?<Item Key="ObjectTypes">\s*<Array>\s*<Item>GovernanceObject</Item>}s,
        "$XMLPath permits GovernanceObject to own an FAQ reference field",
    );
}

my $SetDriverPath = 'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/Set.pm';
open my $SetDriverFH, '<:raw', $SetDriverPath or die "Cannot read $SetDriverPath: $!";
my $SetDriver = <$SetDriverFH>;
close $SetDriverFH;
like( $SetDriver, qr/DynamicField::Mask'\)->EditSectionRender/s, 'Set delegates nested fields through the common DynamicField mask renderer' );

my $DefinitionPath = 'Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Definition.pm';
open my $DefinitionFH, '<:raw', $DefinitionPath or die "Cannot read $DefinitionPath: $!";
my $Definition = <$DefinitionFH>;
close $DefinitionFH;
like( $Definition, qr/qw\(Agent GovernanceObject GovernanceObjectVersion CustomerCompany CustomerUser FAQ Ticket\)/, 'GovernanceObject definition import/export recognizes FAQ reference fields' );

my $GenericAgentPath = 'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/GenericAgent.pm';
open my $GenericAgentFH, '<:raw', $GenericAgentPath or die "Cannot read $GenericAgentPath: $!";
my $GenericAgent = <$GenericAgentFH>;
close $GenericAgentFH;
like(
    $GenericAgent,
    qr/sub\s+_TESSERAGenericAgentImportExportMethodGet.*?require\s+Kernel::Autoload::GenericAgentImportExport;.*?\@ObjectDependencies\s*=\s*\@TESSERAGenericAgentObjectDependencies;.*?sub\s+ExportGenericAgents.*?sub\s+ImportGenericAgents/s,
    'GenericAgent lazy-loads import/export methods after construction and restores its authoritative dependencies',
);

my $GenericAgentImportExportPath = 'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Autoload/GenericAgentImportExport.pm';
ok( -f $GenericAgentImportExportPath, 'GenericAgent import/export extension is included in the runtime overlay' );

my $SOPMPath = 'Kernel/Package/GovernanceDB/TESSERA-Base.sopm';
open my $SOPMFH, '<:raw', $SOPMPath or die "Cannot read $SOPMPath: $!";
my $SOPM = <$SOPMFH>;
close $SOPMFH;
like(
    $SOPM,
    qr{runtime_overlay/Kernel/Autoload/GenericAgentImportExport\.pm},
    'GenericAgent import/export extension is declared in the package manifest',
);

done_testing;
