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
like( $Bootstrap, qr/^\s*RiskTreatment\s*$/m, 'bootstrap creates the RiskTreatment ticket type' );
like( $Action, qr/GetParam\(\s*Param\s*=>\s*'RiskAssessmentOutcome'/, 'submission reads the assessment outcome' );
like( $Action, qr/FieldName\s*=>\s*'RiskAssessmentOutcome'/, 'submission persists the assessment outcome' );
like( $Action, qr/sub _RiskAssessmentOutcomeValid/, 'submission validates against the installed field configuration' );
like( $Action, qr/sub _RiskAssessmentCompletionWeightage/, 'assessment outcome and plan determine BlueBook completion weightage' );
unlike( $Action, qr/_RiskAssessmentOutcomeAdvanceValidate\(/, 'outcome does not block Assessment submission' );
unlike( $Action, qr/_RiskAssessmentRowsValidate\(/, 'missing mitigation plan does not block Assessment submission' );
like( $Action, qr/sub _RiskTreatmentOutcomeSuccessful/, 'successful RiskTreatment outcomes have an explicit predicate' );
like( $Action, qr/State => 'closed unsuccessful', TicketID => \$ParentTicketID/, 'failed treatment closes its parent ServiceRequest unsuccessfully' );
like( $Action, qr/RiskMasterTicket.*?RestartReason/s, 'failed treatment starts a new mapped Risk Management cycle' );
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
is( $RuntimeAction->_RiskAssessmentCompletionWeightage(
    Outcome => 'At Risk - No Mitigation', Rows => [ { 'ZRM-RiskPlan' => 'Plan' } ],
), 0, 'no mitigation outcome completes submission with zero weightage' );
is( $RuntimeAction->_RiskAssessmentCompletionWeightage(
    Outcome => 'Risk Accepted', Rows => [ { 'ZRM-RiskPlan' => '' } ],
), 1, 'risk acceptance submission receives full weightage and can reach approval' );
is( $RuntimeAction->_RiskAssessmentCompletionWeightage(
    Outcome => 'At Risk - Mitigation Planned',
    Rows => [ { 'ZRM-RiskPlan' => '' } ],
), 0, 'planned mitigation without a plan completes with zero weightage' );
is( $RuntimeAction->_RiskAssessmentCompletionWeightage(
    Outcome => 'At Risk - Mitigation Control in Place',
    Rows => [ { 'ZRM-InherentCalculatedRisk' => '9', 'ZRM-ResidualCalculatedRisk' => '6', 'ZRM-RiskPlan' => '' } ],
), 0, 'lower residual risk without a plan completes with zero weightage' );
is( $RuntimeAction->_RiskAssessmentCompletionWeightage(
    Outcome => 'At Risk - Mitigation Planned',
    Rows => [ { 'ZRM-InherentCalculatedRisk' => '9', 'ZRM-ResidualCalculatedRisk' => '6', 'ZRM-RiskPlan' => 'Plan' } ],
), 1, 'planned and evidenced mitigation earns full weightage' );
ok( $RuntimeAction->_RiskTreatmentOutcomeSuccessful( Outcome => 'Mitigated' ), 'mitigated treatment closes the Risk' );
ok( $RuntimeAction->_RiskTreatmentOutcomeSuccessful( Outcome => 'Remediated' ), 'remediated treatment closes the Risk' );
for my $Outcome ( 'Accepted', 'Avoided', 'Cancelled / No Longer Applicable', 'Partially Treated', 'Transferred', 'Unsuccessful' ) {
    ok( !$RuntimeAction->_RiskTreatmentOutcomeSuccessful( Outcome => $Outcome ), "$Outcome leaves Risk open and restarts the failed workflow" );
}
my %WorkspaceData = $RuntimeAction->_RiskAssessmentWorkspaceData(
    TicketID => 306,
    Ticket   => { TicketNumber => 'ICAT-TI-20260000023' },
);
unlike( $WorkspaceData{WorkspaceHTML}, qr/RiskAssessmentOutcome/, 'risk rows no longer contain the overall outcome' );
like( $WorkspaceData{OutcomeHTML}, qr/name="RiskAssessmentOutcome"/, 'outcome is supplied separately for final form placement' );

for my $Type (qw(Approval Endorsement Assessment)) {
    my $Config = { Actions => { Reject => {
        State => 'closed successful', Types => [$Type], Label => 'Reject',
    } } };
    my $Rejected = Kernel::Modules::CustomerTicketZTSMAction::_ActionConfig(
        Config => $Config, Action => 'Reject', Type => $Type,
    );
    is( $Rejected->{State}, 'closed rejected', "$Type rejection cannot be configured as successful" );
    is( $Config->{Actions}->{Reject}->{State}, 'closed successful', 'action resolution does not mutate shared configuration' );
}
like( $Action, qr/RuntimeAction eq 'Reject'.*?FieldName => 'ZTicket-Outcome'.*?Value => '-1'/s,
    'rejection records failure outcome before closure and orchestration' );


{
    package AssessmentSetNameOM;
    sub Get { return $_[0] }
    sub DynamicFieldGet {
        my ($Self, %Param) = @_;
        push @{$Self->{Lookups}}, $Param{Name};
        return $Self->{Fields}{$Param{Name}} || {};
    }
    sub ValueGet {
        my ($Self, %Param) = @_;
        $Self->{ReadID} = $Param{DynamicFieldConfig}{ID};
        return $Self->{Rows};
    }
    sub ValueSet {
        my ($Self, %Param) = @_;
        $Self->{WriteID} = $Param{DynamicFieldConfig}{ID};
        $Self->{Rows} = $Param{Value};
        return 1;
    }
}
for my $Name ('RiskAssessment', 'ZRM-RiskAssessment') {
    my $OM = bless {
        Fields => {$Name => {ID => 302, Name => $Name, ObjectType => 'Ticket', FieldType => 'Set'}},
        Rows => [{'ZRM-RiskStatement' => [630], 'ZRM-InherentCalculatedRisk' => '9', 'ZRM-RiskPlan' => 'Preserved plan'}],
    }, 'AssessmentSetNameOM';
    local $Kernel::OM = $OM;
    my $Rows = $RuntimeAction->_RiskAssessmentRowsGet(TicketID => 321);
    is($Rows->[0]{'ZRM-InherentCalculatedRisk'}, '9', "$Name reads existing score");
    is($OM->{ReadID}, 302, "$Name retains existing field identity on read");
    ok($RuntimeAction->_TicketDynamicFieldSet(FieldName => 'RiskAssessment', TicketID => 321, UserID => 1, Value => $Rows), "$Name saves through the canonical Set name");
    is($OM->{WriteID}, 302, "$Name writes the same field identity");
    is($OM->{Rows}[0]{'ZRM-RiskPlan'}, 'Preserved plan', "$Name preserves authored plan");
    is($OM->{Lookups}[0], 'RiskAssessment', 'unprefixed Set is the primary lookup');
}

my $BlueRuntime = Slurp(File::Spec->catfile($Root, 'Kernel', 'Package', 'GovernanceDB', 'Kernel', 'System', 'ZTSMBlueBookRuntime.pm'));
my ($BlueWrite) = $BlueRuntime =~ /(sub _TicketFieldSet \{.*?)(?=\nsub ChildProcessContextGet)/s;
die 'BlueBook Set writer not found' if !$BlueWrite;
eval "package AssessmentBlueWrite; $BlueWrite";
die $@ if $@;
for my $Name ('RiskAssessment', 'ZRM-RiskAssessment') {
    my $OM = bless {Fields => {$Name => {ID => 302, Name => $Name, ObjectType => 'Ticket'}}}, 'AssessmentSetNameOM';
    local $Kernel::OM = $OM;
    ok(AssessmentBlueWrite::_TicketFieldSet(FieldName => 'RiskAssessment', TicketID => 321, Value => [{ 'ZRM-InherentCalculatedRisk' => '9' }]), "$Name BlueBook template writes with actual missing-field behavior");
    is($OM->{WriteID}, 302, "$Name BlueBook retains Set identity");
}
{
    local $Kernel::OM = bless {Fields => {}}, 'AssessmentSetNameOM';
    ok(!$RuntimeAction->_RiskAssessmentRowsGet(TicketID => 321), 'missing both Set names returns no rows');
    ok(!AssessmentBlueWrite::_TicketFieldSet(FieldName => 'RiskAssessment', TicketID => 321, Value => []), 'missing both Set names does not write');
}
ok(!$RuntimeAction->_RiskAssessmentOutcomeValid(Outcome => ''), 'empty outcome is rejected before submission');
{
    my $OM = bless {Fields => {
        'ZRM-RiskAssessment' => {ID => 302, Config => {Include => [
            {DF => 'ZRM-RiskPlan', Mandatory => 1},
            {DF => 'ZRM-RiskDetail', Mandatory => 0},
            {Grid => {Rows => [[{DF => 'ZRM-RiskAction', Mandatory => 1}]]}},
        ]}},
        'ZRM-RiskPlan' => {Label => 'Risk Plan'},
        'ZRM-RiskAction' => {Label => 'Risk Action'},
    }}, 'AssessmentSetNameOM';
    local $Kernel::OM = $OM;
    like($RuntimeAction->_RiskAssessmentRequiredFieldsValidate(Rows => [{}]), qr/Risk row 1: please fill in Risk Action/, 'blank row rejects required Grid field');
    like($RuntimeAction->_RiskAssessmentRequiredFieldsValidate(Rows => [{'ZRM-RiskAction' => [123], 'ZRM-RiskPlan' => '  '}]), qr/Risk Plan/, 'whitespace does not satisfy mandatory field');
    ok(!$RuntimeAction->_RiskAssessmentRequiredFieldsValidate(Rows => [{'ZRM-RiskAction' => [123], 'ZRM-RiskPlan' => 'Plan'}]), 'populated mandatory fields pass with optional detail empty');
    like($RuntimeAction->_RiskAssessmentRequiredFieldsValidate(Rows => [{'ZRM-RiskAction' => [123], 'ZRM-RiskPlan' => 'Plan'}, {}]), qr/Risk row 2/, 'every submitted row is validated');
    ok(!exists $OM->{WriteID}, 'required validation performs no storage writes');
}
like($Action, qr/_RiskAssessmentRequiredFieldsValidate\( Rows => \$Rows \).*?_RiskAssessmentTemplateHydrateIfEmpty/s, 'required validation precedes hydration and persistence');
my $RequiredRow = $RuntimeAction->_RiskAssessmentRowHTML(
    Index => 0, Row => {'ZRM-Framework'=>[1]},
    Columns => [
        {Field => 'ZRM-RiskAction', Type => 'Dropdown', Label => 'Risk Action'},
        {Field => 'ZRM-RiskPlan', Type => 'TextArea', Label => 'Risk Plan'},
        {Field => 'ZRM-RiskDetail', Type => 'TextArea', Label => 'Risk Detail'},
        {Field => 'ZRM-RiskStatement', Type => 'Reference', Label => 'Risk Statement'},
    ], Targets => [],
    Configs => {
        'ZRM-RiskAction' => {FieldType => 'Dropdown', Config => {PossibleValues => {Mitigate => 'Mitigate'}}},
        'ZRM-RiskStatement' => {FieldType => 'Reference', Label => 'Risk Statement', Config => {}},
    },
    Required => {'ZRM-RiskAction' => 1, 'ZRM-RiskPlan' => 1, 'ZRM-RiskStatement' => 1},
);
like($RequiredRow, qr/Risk Action <span class="Marker"/, 'configured required action shows a star');
like($RequiredRow, qr/name="RA_0_ZRM-RiskAction" required="required" aria-required="true"/, 'required select blocks native submission');
like($RequiredRow, qr/name="RA_0_ZRM-RiskPlan" rows="3" required="required"/, 'required textarea blocks native submission');
like($RequiredRow, qr/data-field-name="RA_0_ZRM-RiskStatement" data-required="1"/, 'reference validation uses selected identifier');
unlike($RequiredRow, qr/Risk Detail <span class="Marker"/, 'optional detail remains unmarked');
like($RequiredRow, qr/name="Autocomplete_DynamicField_ZRM-RiskStatement_0"[^>]*readonly="readonly"/, 'reference display is read-only for search-modal selection');
if ($ARGV[0]) {
    open my $Fixture, '>:raw', $ARGV[0] or die $!;
    print {$Fixture} $RequiredRow;
}
done_testing();
