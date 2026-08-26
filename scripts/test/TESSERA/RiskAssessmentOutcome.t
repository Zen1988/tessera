use strict;
use warnings;

use Test::More;
use File::Spec;

my $Root = File::Spec->rel2abs('.');

sub Slurp {
    my ($Path) = @_;
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    return <$FH>;
}

my $Export = Slurp( File::Spec->catfile( $Root, 'Export', 'Export_DynamicFields_2026-08-26 05_11_04.yml' ) );
my $Bootstrap = Slurp( File::Spec->catfile( $Root, 'Kernel', 'Package', 'GovernanceDB', 'Kernel', 'System', 'GovernanceDB', 'Bootstrap.pm' ) );
my $Action = Slurp( File::Spec->catfile( $Root, 'Kernel', 'Package', 'GovernanceDB', 'Kernel', 'Modules', 'CustomerTicketZTSMAction.pm' ) );
my $OverlayAction = Slurp( File::Spec->catfile( $Root, 'Kernel', 'Package', 'GovernanceDB', 'var', 'governancedb', 'runtime_overlay', 'Kernel', 'Modules', 'CustomerTicketZTSMAction.pm' ) );
my $Template = Slurp( File::Spec->catfile( $Root, 'Kernel', 'Package', 'GovernanceDB', 'var', 'governancedb', 'runtime_overlay', 'Kernel', 'Output', 'HTML', 'Templates', 'Standard', 'CustomerTicketZTSMRiskAssessment.tt' ) );

for my $Outcome (
    'At Risk - Mitigation Control in Place',
    'At Risk - Mitigation Planned',
    'At Risk - No Mitigation',
    'Not Applicable',
    'Risk Accepted',
    )
{
    like( $Export, qr/\Q$Outcome\E/, "authoritative export contains $Outcome" );
    like( $Bootstrap, qr/\Q$Outcome\E/, "bootstrap preserves $Outcome" );
}

like( $Bootstrap, qr/Name\s*=>\s*'RiskAssessmentOutcome'/, 'bootstrap creates the exact exported field name' );
like( $Action, qr/GetParam\(\s*Param\s*=>\s*'RiskAssessmentOutcome'/, 'submission reads the assessment outcome' );
like( $Action, qr/FieldName\s*=>\s*'RiskAssessmentOutcome'/, 'submission persists the assessment outcome' );
like( $Action, qr/sub _RiskAssessmentOutcomeValid/, 'submission validates against the installed field configuration' );
like( $Action, qr/Risk Assessment Outcome:<\/strong>/, 'summary article records the explicit outcome' );
like( $Action, qr/required="required"/, 'assessment UI requires an outcome' );
like( $Template, qr/\.ZTSMRiskAssessmentOutcome/, 'assessment template owns outcome layout styling' );
is( $OverlayAction, $Action, 'packaged module and deployed runtime overlay are byte-identical' );

done_testing();
