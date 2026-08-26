use strict;
use warnings;
use Test::More;

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::ZTSMWorkbookXLSX;

sub Content {
    my ($Path) = @_;
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    return <$FH>;
}

my @JavaScript = (
    'Kernel/Package/GovernanceDB/var/httpd/htdocs/js/ZTSM.Agent.ConfigItem.Workbook.js',
    'Kernel/Package/GovernanceDB/var/httpd/htdocs/js/ZTSM.Agent.Object.Workbook.js',
    'Kernel/Package/MELT/var/httpd/htdocs/js/ZTSM.Agent.MELTObject.Workbook.js',
);

for my $Path (@JavaScript) {
    my $Source = Content($Path);
    like(
        $Source,
        qr{parseInt\(Row\.CandidateCount,\s*10\)\s*\|\|\s*0},
        "$Path normalizes JSON string counts before choosing a default",
    );
    like(
        $Source,
        qr{Status\s*===\s*'MATCH_NUMBER'\s*\|\|\s*\w+\s*===\s*1},
        "$Path defaults an exact number or unique class/name match to update",
    );
    like(
        $Source,
        qr{Status\s*===\s*'CREATE_CANDIDATE'\s*&&\s*\w+\s*===\s*0},
        "$Path defaults a genuinely new row to create",
    );
    like(
        $Source,
        qr{data-default=},
        "$Path records the inferred operation on each decision control",
    );
    like(
        $Source,
        qr{\.value\s*=\s*\w+\.getAttribute\('data-default'\)},
        "$Path applies the inferred operation as the live DOM selection",
    );
    like(
        $Source,
        qr{ambiguous identity},
        "$Path requires manual choice only for ambiguous identity",
    );
}

for my $Path (
    'Kernel/Package/GovernanceDB/Kernel/Modules/AgentGovernanceObjectWorkbook.pm',
    'Kernel/Package/GovernanceDB/Kernel/Modules/AgentITSMConfigItemWorkbook.pm',
    'Kernel/Package/MELT/Kernel/Modules/AgentMELTObjectWorkbook.pm',
) {
    my $Source = Content($Path);
    like(
        $Source,
        qr{New rows default to create; number or unique name matches default to update},
        "$Path explains the preview defaults",
    );
}

for my $Path (
    'Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/Document.pm',
    'Kernel/Package/MELT/Kernel/System/MELTObject/Document.pm',
) {
    my $Source = Content($Path);
    like(
        $Source,
        qr{WHERE ci\.class_id = \? AND v\.name = \?},
        "$Path resolves import identity with a literal bound name",
    );
    unlike(
        $Source,
        qr{(?:GovernanceObject|MELTObject)Search\([\s\S]{0,250}?Name\s*=>\s*\$Param\{Name\}},
        "$Path does not parse exact import names as search expressions",
    );
}

for my $Path (
    'Kernel/Package/GovernanceDB/Kernel/Modules/AgentGovernanceObjectWorkbook.pm',
    'Kernel/Package/GovernanceDB/Kernel/Modules/AgentITSMConfigItemWorkbook.pm',
    'Kernel/Package/MELT/Kernel/Modules/AgentMELTObjectWorkbook.pm',
) {
    my $Source = Content($Path);
    like(
        $Source,
        qr{my \$Result = eval \{[\s\S]{0,1800}?->Import\(},
        "$Path isolates unexpected import failures to the current row",
    );
    like(
        $Source,
        qr{my \$Failure = \$@},
        "$Path reports the isolated row failure in the completed summary",
    );
    like(
        $Source,
        qr{sha256_hex\(\s*encode\(\s*'UTF-8',\s*\$Payload\s*\)\s*\)},
        "$Path hashes Unicode workbook payloads as UTF-8 bytes",
    );
}

my $Workbook = Kernel::System::ZTSMWorkbookXLSX->new();
my $Normalized = $Workbook->ImportRowsNormalize(
    Rows => [
        {
            'ZTSM-ScriptEngine' => "'---\nSCRIPT: Resolve Platform Network\nVERSION: 1",
            PairedQuote         => "'preserve me'",
            OrdinaryText        => 'unchanged',
            Structured          => [ "'---\nRETURN: true", "'paired'" ],
        },
    ],
);
is(
    $Normalized->[0]->{'ZTSM-ScriptEngine'},
    "---\nSCRIPT: Resolve Platform Network\nVERSION: 1",
    'workbook import removes one unmatched leading Excel text apostrophe',
);
is( $Normalized->[0]->{PairedQuote}, "'preserve me'", 'paired single-quoted text is preserved' );
is( $Normalized->[0]->{OrdinaryText}, 'unchanged', 'ordinary workbook text is unchanged' );
is( $Normalized->[0]->{Structured}->[0], "---\nRETURN: true", 'nested imported values receive the same normalization' );
is( $Normalized->[0]->{Structured}->[1], "'paired'", 'nested paired quotes remain intact' );

done_testing;
