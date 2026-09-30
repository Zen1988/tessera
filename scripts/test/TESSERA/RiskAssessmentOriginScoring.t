use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $Root = File::Spec->catdir( $FindBin::Bin, '..', '..', '..' );
my $SourceFile = File::Spec->catfile(
    $Root, qw(Kernel Package GovernanceDB Kernel Modules CustomerTicketZTSMAction.pm)
);
open my $FH, '<', $SourceFile or die "Cannot read $SourceFile: $!";
local $/;
my $Source = <$FH>;
close $FH;
$Source =~ s{^use Kernel::[^;]+;\r?\n}{}mg;
my $Loaded = eval $Source;
die $@ if $@;

{
    no strict 'refs';
    *{'Kernel::Modules::CustomerTicketZTSMAction::IsHashRefWithData'} = sub {
        my ($Value) = @_;
        return ref $Value eq 'HASH' && scalar keys %{$Value};
    };
}

{
    package RiskScoringTestOM;
    sub new { return bless {}, shift }
    sub Get {
        my ( $Self, $Name ) = @_;
        return $Self;
    }
    sub Load { return $main::Engine }
    sub ItemGet {
        my ( $Self, %Param ) = @_;
        return { Name => '3' } if $Param{ItemID} == 901 || $Param{ItemID} == 902;
        return { Name => '3' } if $Param{ItemID} == 903 || $Param{ItemID} == 905;
        return { Name => '2' } if $Param{ItemID} == 904 || $Param{ItemID} == 906;
        return { Name => '4' } if $Param{ItemID} == 907;
        return;
    }
    sub ItemList {
        my ( $Self, %Param ) = @_;
        return { 903 => '3', 906 => '2', 907 => '4' } if $Param{Class} eq 'ZRM::Impact';
        return { 904 => '2', 905 => '3' } if $Param{Class} eq 'ZRM::Likelihood';
        return {};
    }
    sub GovernanceObjectGet {
        my ( $Self, %Param ) = @_;
        return $main::GO{ $Param{GovernanceObjectID} };
    }
    sub ConfigItemGet {
        my ( $Self, %Param ) = @_;
        return $main::CI{ $Param{ConfigItemID} };
    }
    sub DynamicFieldGet {
        my ( $Self, %Param ) = @_;
        return { FieldType => 'GovernanceObject', ObjectType => 'ITSMConfigItem',
            Config => { ClassIDs => [380] } }
            if $Param{Name} eq 'ZTAM-Environment';
        return { FieldType => 'GovernanceObject', ObjectType => 'GovernanceObject',
            Config => { ClassIDs => [380] } }
            if $Param{Name} eq 'ZTSMAppSystem-CriticalityProfile';
        return { FieldType => 'GeneralCatalog', Config => { Class => 'ZRM::Impact' } }
            if $Param{Name} eq 'ZRM-InherentImpact' || $Param{Name} eq 'ZRM-ResidualImpact';
        return { FieldType => 'GeneralCatalog', Config => { Class => 'ZRM::Likelihood' } }
            if $Param{Name} eq 'ZRM-InherentLikelihood' || $Param{Name} eq 'ZRM-ResidualLikelihood';
        return;
    }
    sub ValueEvaluate {
        my ( $Self, %Param ) = @_;
        return { Known => 1, Value => 500 }
            if $Param{Expression} eq '@RISK.MELT-RelatedGO[Application][0]';
        return { Known => 0, Reason => 'Unexpected Application selector' };
    }
}

our $Engine = {
    VERSION => 1,
    ASSESSMENT => 'INHERENT',
    'APPLIES TO' => [ 'ITSMConfigItem.Workload' ],
    'RISK STATEMENTS' => { FROM => '@RISK.MELT-RiskStmt[RiskStatement][0]' },
    BASE => {
        IMPACT => { FROM => 'CURRENT RISK STATEMENT.ZRM-BaseImpact' },
        LIKELIHOOD => { FROM => 'CURRENT RISK STATEMENT.ZRM-BaseLikelihood' },
    },
    'FACTOR RULE' => { 'WHEN ZERO' => 1, 'WHEN ABOVE ONE' => 1, 'WHEN MISSING' => 1 },
    FACTORS => [
        { REFERENCE => 'ZTAM-Environment', IMPACT => 'ZRM-ImpactFactor', LIKELIHOOD => 'ZRM-LikelihoodFactor' },
    ],
    CALCULATE => {
        'INHERENT IMPACT' => 'CEIL(BASE.IMPACT * PRODUCT(NORMALIZE(FACTORS.IMPACT, FACTOR RULE)))',
        'INHERENT LIKELIHOOD' => 'CEIL(BASE.LIKELIHOOD * PRODUCT(NORMALIZE(FACTORS.LIKELIHOOD, FACTOR RULE)))',
        'INHERENT RISK' => 'INHERENT IMPACT * INHERENT LIKELIHOOD',
    },
    'ASSESSMENT RESULT' => {
        'TICKET TYPE' => 'Assessment', FIELD => 'ZRM-RiskAssessment',
        'ROW TARGET' => 'ZRM-RiskTargetCI',
        'ROW RISK STATEMENT' => 'ZRM-RiskStatement',
        'SCORE FIELD' => 'ZRM-InherentCalculatedRisk',
    },
};

our %GO = (
    1597 => { Class => 'Framework', Name => 'Application Risk Management', 'DynamicField_ZRM-RiskScoringEngine' => 'test YAML' },
    201 => { Class => 'Environment', ClassID => 380, 'DynamicField_ZRM-ImpactFactor' => '0.8',
        'DynamicField_ZRM-LikelihoodFactor' => '0.5' },
    500 => { Class => 'Application', 'DynamicField_ZTSMAppSystem-CriticalityProfile' => [201] },
);
our %CI = (
    574 => { Class => 'Product' },
    2135 => { Class => 'Workload', 'DynamicField_ZTAM-Environment' => [201] },
    2136 => { Class => 'Workload' },
);
$Kernel::OM = RiskScoringTestOM->new();
my $Action = bless {}, 'Kernel::Modules::CustomerTicketZTSMAction';
my $Risk = {
    'DynamicField_MELT-RMF' => [1597],
    'DynamicField_MELT-RelatedCI' => [574, 2135, 2136],
};
my $Statement = {
    Class => 'RiskStatement',
    'DynamicField_ZRM-RMF' => [1597],
    'DynamicField_ZRM-BaseImpact' => [901],
    'DynamicField_ZRM-BaseLikelihood' => [902],
};

my $Rows = $Action->_RiskAssessmentOriginScoresEvaluate(
    Risk => $Risk, Statement => $Statement,
);
is( scalar @{$Rows}, 2, 'only applicable Workloads are scored' );
is( $Rows->[0]->{'ZRM-InherentCalculatedRisk'}, '6', 'rounded dimensions produce the Framework risk score' );
is_deeply( $Rows->[0]->{'ZRM-InherentImpact'}, [903], 'adjusted impact rounds to catalog value 3' );
is_deeply( $Rows->[0]->{'ZRM-InherentLikelihood'}, [904], 'adjusted likelihood rounds to catalog value 2' );
is( $Rows->[1]->{'ZRM-InherentCalculatedRisk'}, '9', 'missing optional factor is neutral' );

$GO{201}->{'DynamicField_ZRM-ImpactFactor'} = '-1';
eval { $Action->_RiskAssessmentOriginScoresEvaluate( Risk => $Risk, Statement => $Statement ) };
like( $@, qr/negative/, 'negative factor fails closed' );
$GO{201}->{'DynamicField_ZRM-ImpactFactor'} = '0.8';
$GO{201}->{ClassID} = 379;
eval { $Action->_RiskAssessmentOriginScoresEvaluate( Risk => $Risk, Statement => $Statement ) };
like( $@, qr/wrong Governance Object class/, 'wrong-class reference fails closed' );

$GO{201}->{ClassID} = 380;
$Engine->{'APPLIES TO'} = [ 'GovernanceObject.Application' ];
$Engine->{'SCORING CONTEXT'} = {
    FROM => '@RISK.MELT-RelatedGO[Application][0]',
    CLASS => 'GovernanceObject.Application',
};
$Engine->{FACTORS} = [
    { REFERENCE => 'ZTSMAppSystem-CriticalityProfile', IMPACT => 'ZRM-ImpactFactor',
      LIKELIHOOD => 'ZRM-LikelihoodFactor' },
];
$Engine->{'ASSESSMENT RESULT'}->{'ROW TARGET'} = 'ZRM-RiskTargetGO';
$Engine->{'ASSESSMENT RESULT'}->{'RELATED ASSETS FIELD'} = 'ZRM-RiskTargetCI';
$Engine->{'ASSESSMENT RESULT'}->{'RELATED ASSETS FROM'} = 'CURRENT RISK.MELT-RelatedCI';
$Risk->{'DynamicField_MELT-RelatedGO'} = [500];
$Rows = $Action->_RiskAssessmentOriginScoresEvaluate( Risk => $Risk, Statement => $Statement );
is( scalar @{$Rows}, 1, 'Application Framework calculates one row for the Risk' );
is_deeply( $Rows->[0]->{'ZRM-RiskTargetGO'}, [500], 'Application is the row target' );
is_deeply( $Rows->[0]->{'ZRM-RiskTargetCI'}, [574, 2135, 2136], 'all Risk assets remain linked as evidence' );
is( $Rows->[0]->{'ZRM-InherentCalculatedRisk'}, '6', 'Application profile factors calculate rounded dimensions once' );
is( $Action->{RiskAssessmentFrameworkBreakdown}->{'GO:500'}->{LikelihoodFactor}, '0.5',
    'scoring breakdown exposes likelihood factor for the UI' );

$Action->{RiskAssessmentSourceStatementID} = 630;
my $Evidence = $Action->_RiskAssessmentFrameworkEvidenceHTML(
    Row => { 'ZRM-RiskStatement' => [630], 'ZRM-RiskTargetGO' => [500],
        'ZRM-InherentLikelihood' => [904], 'ZRM-InherentImpact' => [903],
        'ZRM-InherentCalculatedRisk' => '6' },
);
like( $Evidence, qr/Likelihood: 3 x 0\.5 = 1\.5; rounded up to 2/,
    'article evidence records the factor and rounded catalog dimension' );
like( $Evidence, qr/Framework inherent score: 2 x 3 = 6/,
    'article evidence records the selected dimension product' );
like( $Evidence, qr/ZTSMAppSystem-CriticalityProfile.*impact 0\.8 -&gt; 0\.8/, 'article evidence names the contributing factor and raw value' );
$Engine->{EVIDENCE} = { FORMAT => '{framework_name}: likelihood {base_likelihood} x {likelihood_factor_chain} = {framework_likelihood}; impact {framework_impact}; score {framework_score}; selected {submitted_likelihood} x {submitted_impact} = {submitted_score}.' };
$Rows = $Action->_RiskAssessmentOriginScoresEvaluate( Risk => $Risk, Statement => $Statement );
my $AdjustedRow = {
    'ZRM-RiskStatement' => [630], 'ZRM-RiskTargetGO' => [500],
    'ZRM-InherentLikelihood' => [905], 'ZRM-InherentImpact' => [907],
    'ZRM-InherentCalculatedRisk' => '9',
};
$Action->_RiskAssessmentRowScoresApply( Rows => [$AdjustedRow] );
is( $AdjustedRow->{'ZRM-InherentCalculatedRisk'}, '12', 'server derives 3 x 4 instead of accepting the stale Framework score' );
$Evidence = $Action->_RiskAssessmentFrameworkEvidenceHTML( Row => $AdjustedRow );
like( $Evidence, qr/Application Risk Management: likelihood 3 x 0\.5 = 2; impact 3; score 6; selected 3 x 4 = 12/, 'Framework YAML formats the suggested and submitted calculation' );
eval { $Action->_RiskAssessmentRowScoresApply( Rows => [ { %{$AdjustedRow}, 'ZRM-InherentImpact' => [9999] } ] ) };
like( $@, qr/not a valid 1-5 catalog selection/, 'server rejects an invalid catalog dimension' );
is( $Action->_RiskAssessmentFrameworkEvidenceHTML(
        Row => { 'ZRM-RiskStatement' => [999], 'ZRM-RiskTargetGO' => [500] },
    ), '', 'unrelated template rows do not receive originating Framework evidence' );

done_testing();
