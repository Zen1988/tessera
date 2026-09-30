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

my @Exports = sort glob File::Spec->catfile( $Root, 'Export', 'Export_DynamicFields_*.yml' );
die 'No authoritative Dynamic Field export found' if !@Exports;
my $Export = Slurp( $Exports[-1] );
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
like( $Template, qr{Data\.WorkspaceHTML.*?ZTSMRiskAssessmentRemarks.*?Data\.OutcomeHTML.*?Submit Assessment}s, 'outcome selection follows assessment rows and remarks before submission' );
is( $OverlayAction, $Action, 'packaged module and deployed runtime overlay are byte-identical' );

my $Runtime = $Action;
$Runtime =~ s{^use Kernel::[^;]+;\r?\n}{}mg;
my $Loaded = eval $Runtime;
die $@ if $@;
{
    no strict 'refs';
    *{'Kernel::Modules::CustomerTicketZTSMAction::IsHashRefWithData'} = sub {
        my ($Value) = @_;
        return ref $Value eq 'HASH' && scalar keys %{$Value};
    };
}
{
    package RiskOutcomeTestAction;
    our @ISA = ('Kernel::Modules::CustomerTicketZTSMAction');
    sub _RiskAssessmentFieldConfigs { return { RiskAssessmentOutcome => $main::OutcomeConfig } }
    sub _RiskAssessmentWorkspaceHTML { return '<div id="ZTSMRiskAssessmentRows"></div>' }
}
our $OutcomeConfig = {
    FieldType => 'Dropdown',
    ObjectType => 'Ticket',
    Config => { PossibleValues => {
        'At Risk - Mitigation Planned' => 'At Risk - Mitigation Planned',
        'Risk Accepted'                => 'Risk Accepted',
    } },
};
my $RuntimeAction = bless {}, 'RiskOutcomeTestAction';
my $OutcomeHTML = $RuntimeAction->_RiskAssessmentOutcomeHTML( Config => $OutcomeConfig );
like( $OutcomeHTML, qr{name="RiskAssessmentOutcome"}, 'custom Assessment renders the outcome selector' );
like( $OutcomeHTML, qr{<span class="ZTSMRiskAssessmentOutcomeCaption" id="RiskAssessmentOutcomeCaption">Risk Assessment Outcome}, 'custom Assessment shows the required outcome caption' );
like( $OutcomeHTML, qr{<option value="Risk Accepted">Risk Accepted</option>}, 'selector includes exported Dropdown choices' );
ok( $RuntimeAction->_RiskAssessmentOutcomeValid( Outcome => 'Risk Accepted' ), 'submission accepts a configured outcome' );
ok( !$RuntimeAction->_RiskAssessmentOutcomeValid( Outcome => 'Unknown outcome' ), 'submission rejects an unconfigured outcome' );
my %WorkspaceData = $RuntimeAction->_RiskAssessmentWorkspaceData(
    TicketID => 306,
    Ticket   => { TicketNumber => 'ICAT-TI-20260000023' },
);
unlike( $WorkspaceData{WorkspaceHTML}, qr/RiskAssessmentOutcome/, 'risk rows no longer contain the overall outcome' );
like( $WorkspaceData{OutcomeHTML}, qr/name="RiskAssessmentOutcome"/, 'outcome is supplied separately for final form placement' );

done_testing();
