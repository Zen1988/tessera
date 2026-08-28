use strict;
use warnings;

use Test::More;

sub Slurp {
    my ($Path) = @_;
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    return <$FH>;
}

my $GovernanceDocument = Slurp('Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm');
my $ConfigItemDocument = Slurp('Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/Document.pm');
my $Workbook            = Slurp('Kernel/Package/GovernanceDB/Kernel/Modules/AgentGovernanceObjectWorkbook.pm');
my $ImportExport        = Slurp('Kernel/Package/GovernanceDB/Kernel/System/ImportExport/ObjectBackend/GovernanceObject.pm');
my $TicketTable         = Slurp('Kernel/Package/GovernanceDB/Kernel/System/TESSERA/TicketTable.pm');

like( $Workbook, qr/\$Document->Export\(/, 'Excel uses the shared portable GovernanceObject document export' );
like( $ImportExport, qr/GovernanceObject::Document.*?ValueForExport/s,
    'generic CSV and spreadsheet ImportExport uses the same portable value codec' );
like( $TicketTable, qr/sub _PortableDynamicFieldValue.*?ValueForExport/s,
    'ticket table export resolves entity-backed dynamic fields through the portable value codec' );
like( $ConfigItemDocument, qr/use parent qw\(Kernel::System::GovernanceObject::Document\)/,
    'ConfigItem YAML and Excel inherit the same reference serialization contract' );

for my $Type (qw(Service Agent Ticket FAQ MELTObject CustomerCompany CustomerUser)) {
    like( $GovernanceDocument, qr/FieldType\} eq '\Q$Type\E'/, "$Type references have explicit portable serialization" );
}

for my $Type (qw(Type Queue SLA)) {
    like( $GovernanceDocument, qr/FieldType\} eq '\Q$Type\E'/, "$Type entity selector exports a name" );
}

for my $Type (qw(WebService ProcessID ActivityID)) {
    like( $GovernanceDocument, qr/FieldType\} eq '\Q$Type\E'/, "$Type entity selector exports a name" );
}

like( $GovernanceDocument, qr/Config\}->\{ReferencedObjectType\}.*?ne ''/,
    'every declared reference driver is routed through portable reference serialization' );
like( $GovernanceDocument, qr/sub _ConfiguredOptionValueForDocument/,
    'configured dropdown entity keys export their labels' );
like( $GovernanceDocument, qr/sub _SetValueForDocument.*?_ValueForDocument/s,
    'Set-contained fields recursively use the same name conversion' );
like( $GovernanceDocument, qr/IsHashRefWithData\(\$Item\) \? \$Item->\{Name\} : undef/,
    'unresolved GeneralCatalog IDs fail closed instead of leaking numbers' );

done_testing();
