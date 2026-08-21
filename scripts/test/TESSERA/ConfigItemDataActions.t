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
        '_CaseFold', 'UPDATE_CLEAR', '_ClearFields', 'destructive confirmation is required',
        '_DefinitionFieldNames', 'DefinitionRef', 'ClassID', 'return {} if !$Param{ClassID}', "Subaction eq 'Model'",
    ],
    'Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/Document.pm' => [
        'ZTAM-AssetTag', 'ZTAM-Application', 'DynamicField_ZTSM-Code', '<running id>',
        'description     => $Self->_RichTextValueForDocument',
    ],
    'Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm' => [
        "FieldType} eq 'RichText'", '_RichTextValueForDocument', 'HTMLUtils',
        'Class}: $GovernanceObject->{Name}', 'DynamicFields => 0',
    ],
    'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/var/httpd/htdocs/js/ZTSM.Agent.ConfigItem.DataActions.js' => [
        "Query.get('Filter')", 'CurrentClassID',
    ],
    'Kernel/Package/GovernanceDB/var/httpd/htdocs/js/ZTSM.Agent.ConfigItem.Workbook.js' => [
        'SheetNames', 'ZTSMWorkbookDecision', 'ZTSMWorkbookTemplate',
        'Subaction=Download', 'Instructions', '_Selections',
    ],
    'Kernel/Package/GovernanceDB/Kernel/System/ZTSMWorkbookXLSX.pm' => [
        'data_validation', 'FieldMetadata', 'GeneralCatalog', 'Instructions', 'Allowed values', '_Selections',
        "bg_color => '#E7E6E6'", "bg_color => '#A9D18E'", "bg_color => '#F4B183'",
        'ReferencedObjectType', 'Reference', "Meta->{Reference} ? 'reference'", 'Structured',
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

my $GovernanceDocumentPath = "$Root/Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm";
open my $GovernanceDocumentFH, '<:raw', $GovernanceDocumentPath or die "Cannot read $GovernanceDocumentPath: $!";
local $/;
my $GovernanceDocument = <$GovernanceDocumentFH>;
close $GovernanceDocumentFH;
like(
    $GovernanceDocument,
    qr{sub _SingleReferenceForDocument.*?GovernanceObjectGet\(.*?DynamicFields\s*=>\s*0}s,
    'Governance reference export resolves portable identity without recursively loading target Dynamic Fields',
);

done_testing();
