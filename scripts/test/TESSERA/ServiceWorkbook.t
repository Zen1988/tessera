use strict;
use warnings;
use Test::More;

sub Slurp {
    my ($Path) = @_;
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    return <$FH>;
}

my $Module = Slurp('Kernel/Package/GovernanceDB/Kernel/Modules/AdminServiceWorkbook.pm');
my $Codec  = Slurp('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Autoload/ServiceImportExport.pm');
my $Config = Slurp('Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/GovernanceDB.xml');
my $Template = Slurp('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/AdminServiceWorkbook.tt');
my $JS = Slurp('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/var/httpd/htdocs/js/ZTSM.Agent.Service.Workbook.js');

like( $Module, qr/sub _ExportModel/, 'Service workbook builds an Excel export model' );
like( $Module, qr/ZTSMWorkbookXLSX.*?Build/s, 'Service workbook uses the shared XLSX builder' );
like( $Module, qr/Subaction eq 'Preview'.*?Subaction eq 'Commit'/s, 'Excel import is preview-first' );
like( $Module, qr/ChallengeTokenCheck/, 'Service workbook commit checks the challenge token' );
like( $Module, qr/ImportServices\(/, 'Service workbook commits through the authoritative Service importer' );
like( $Module, qr/qw\(Name Parent Type Criticality Valid DestQueue TicketTypes Comment ShortDescription LongDescription\)/,
    'Service workbook includes the core portable Service columns' );
like( $Module, qr/DynamicFieldListGet.*?ObjectType => \['Service'\]/s,
    'Service Dynamic Fields are included from the installed model' );
like( $Codec, qr/ValueForExport.*?ValueFromImport/s,
    'Service YAML and Excel share name-based Dynamic Field reference conversion' );
like( $Config, qr/Frontend::Module###AdminServiceWorkbook/, 'Service Excel frontend is registered in authoritative package SysConfig' );
like( $Config, qr/sheetjs-0\.20\.3\/xlsx\.full\.min\.js/, 'Service Excel frontend loads SheetJS' );
like( $Template, qr/Download empty template.*?Export Services.*?Preview XLSX/s,
    'Service Excel UI provides template, export, and import preview actions' );
like( $JS, qr/Book\.Sheets\.Services/, 'Service Excel importer reads the Services worksheet' );

done_testing();
