use strict;
use warnings;
use Test::More;

my $Root = $ENV{TESSERA_TEST_ROOT} || '.';

my %Expected = (
    'Kernel/Package/GovernanceDB/Kernel/Output/HTML/ITSMConfigItem/ZTSMOverviewSmall.pm' => [
        'ZTSMConfigItemDocumentAction', 'ZTSMGeneralCatalogDocumentAction', 'ZTSMConfigItemWorkbookAction',
    ],
    'Kernel/Package/GovernanceDB/Kernel/Modules/AgentITSMConfigItemWorkbook.pm' => [
        'REVIEW_SAME_ASSET', 'ZTAM-Application', 'ZTAM-Environment', 'ZTAM-Location',
        'lc( $_->{name}', '_CaseFold', 'UPDATE_CLEAR', '_ClearFields', 'destructive confirmation is required',
        '_DefinitionFieldNames', 'DefinitionRef', 'ClassID', 'return {} if !$Param{ClassID}', "Subaction eq 'Model'",
    ],
    'Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/Document.pm' => [
        'ZTAM-AssetTag', 'ZTAM-Application', 'DynamicField_ZTSM-Code', '<running id>',
        'description     => $Self->_RichTextValueForDocument',
    ],
    'Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm' => [
        "FieldType} eq 'RichText'", '_RichTextValueForDocument', 'HTMLUtils',
        'Class}: $GovernanceObject->{Name}',
    ],
    'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/var/httpd/htdocs/js/ZTSM.Agent.ConfigItem.DataActions.js' => [
        "Query.get('Filter')", 'CurrentClassID',
    ],
    'Kernel/Package/GovernanceDB/var/httpd/htdocs/js/ZTSM.Agent.ConfigItem.Workbook.js' => [
        'XLSX.writeFile', 'JSON.stringify(Value)', 'SheetNames', 'ZTSMWorkbookDecision', 'ZTSMWorkbookTemplate',
        'fetch(ModelURL', 'Subaction=Model',
    ],
);

for my $RelativePath ( sort keys %Expected ) {
    open my $FH, '<:raw', "$Root/$RelativePath" or die "Cannot read $RelativePath: $!";
    local $/;
    my $Content = <$FH>;
    close $FH;
    for my $Marker ( @{ $Expected{$RelativePath} } ) {
        like( $Content, qr/\Q$Marker\E/, "$RelativePath contains $Marker" );
    }
}

done_testing();
