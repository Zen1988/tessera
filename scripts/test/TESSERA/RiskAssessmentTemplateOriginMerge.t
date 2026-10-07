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
    *{'Kernel::Modules::CustomerTicketZTSMAction::IsArrayRefWithData'} = sub {
        my ($Value) = @_;
        return ref $Value eq 'ARRAY' && @{$Value};
    };
}

{
    package RiskTemplateTestOM;
    sub GovernanceObjectSearch { return () }
    sub new { return bless {}, shift }
    sub Get { return $_[0] }
    sub MELTObjectGet {
        return {
            MELTObjectID => 21, Class => 'Risk',
            'DynamicField_MELT-RiskStmt' => [630],
        };
    }
    sub TicketGet { return %main::Parent }
    sub GovernanceObjectGet {
        return {
            GovernanceObjectID => 630, Class => 'RiskStatement',
            'DynamicField_ZRM-ImpactCategoryGO' => [41],
            'DynamicField_ZRM-RiskCategoryGO'   => [42],
            'DynamicField_ZRM-BaseLikelihood'   => [43],
            'DynamicField_ZRM-BaseImpact'       => [44],
        };
    }
}

{
    package RiskTemplateTestAction;
    our @ISA = ('Kernel::Modules::CustomerTicketZTSMAction');
    sub _RiskAssessmentRowsGet { return $main::Rows }
    sub _RiskAssessmentOriginScores {
        return [
            { 'ZRM-RiskTargetGO' => [1493], 'ZRM-RiskTargetCI' => [4147, 4148],
              'ZRM-InherentCalculatedRisk' => '9' },
        ] if $main::ApplicationMode;
        return [
            { 'ZRM-RiskTargetCI' => [4147], 'ZRM-InherentCalculatedRisk' => '9' },
        ];
    }
    sub _TicketDynamicFieldSet {
        my ( $Self, %Param ) = @_;
        for my $Row ( @{ $Param{Value} || [] } ) {
            for my $Field (qw(ZRM-ImpactCategory ZRM-RiskCategory ZRM-InherentLikelihood ZRM-InherentImpact)) {
                next if !exists $Row->{$Field};
                my $IDs = $Row->{$Field};
                die "non-numeric catalog value in $Field" if ref $IDs ne 'ARRAY'
                    || grep { !defined $_ || $_ !~ m{\A\d+\z} } @{$IDs};
            }
        }
        $main::Rows = $Param{Value};
        return 1;
    }
    sub _ZTSMActionLog { return }
}

$Kernel::OM = RiskTemplateTestOM->new();
my $Action = bless {}, 'RiskTemplateTestAction';
my $Ticket = {
    TicketID => 100, 'DynamicField_ZTicket-Parent' => [99],
};
our %Parent = ( TicketID => 99, Type => 'ServiceRequest', 'DynamicField_ZRM-OriginatedEvent' => [21] );

our $Rows = [
    { 'ZRM-RiskStatement' => [600], 'ZRM-RiskPlan' => 'Keep the template plan' },
];
$Action->_RiskAssessmentTemplateHydrateIfEmpty( Ticket => $Ticket );
is( scalar @{$Rows}, 2, 'origin statement is added alongside a different template statement' );
is( $Rows->[0]->{'ZRM-RiskPlan'}, 'Keep the template plan', 'template plan remains intact' );
is( $Rows->[1]->{'ZRM-RiskStatement'}->[0], 630, 'new row uses originating Risk statement' );
is( $Rows->[1]->{'ZRM-RiskTargetCI'}->[0], 4147, 'new row targets affected asset' );
is_deeply( $Rows->[1]->{'ZRM-ImpactCategory'}, [41], 'origin row stores only the numeric impact category ID' );
is_deeply( $Rows->[1]->{'ZRM-RiskCategory'}, [42], 'origin row stores only the numeric risk category ID' );
is_deeply( $Rows->[1]->{'ZRM-InherentLikelihood'}, [43], 'origin row stores only the numeric likelihood ID' );
is_deeply( $Rows->[1]->{'ZRM-InherentImpact'}, [44], 'origin row stores only the numeric impact ID' );

$Rows = [
    { 'ZRM-RiskStatement' => [630], 'ZRM-RiskPlan' => 'Keep the same-statement template plan' },
];
$Action->_RiskAssessmentTemplateHydrateIfEmpty( Ticket => $Ticket );
is( scalar @{$Rows}, 1, 'same-statement template row is reused' );
is( $Rows->[0]->{'ZRM-RiskPlan'}, 'Keep the same-statement template plan', 'same-statement template plan remains intact' );
is( $Rows->[0]->{'ZRM-RiskTargetCI'}->[0], 4147, 'same-statement row receives affected asset' );
is( $Rows->[0]->{'ZRM-InherentCalculatedRisk'}, '9', 'same-statement row receives Framework score' );

$Rows = [ { 'ZRM-RiskStatement' => [600] } ];
$Ticket->{'DynamicField_ZRM-OriginatedEvent'} = [22];
$Action->_RiskAssessmentTemplateHydrateIfEmpty( Ticket => $Ticket );
is( scalar @{$Rows}, 1, 'conflicting child origin cannot override parent ServiceRequest' );
delete $Ticket->{'DynamicField_ZRM-OriginatedEvent'};
$Action->_RiskAssessmentTemplateHydrateIfEmpty( Ticket => $Ticket );
is( $Rows->[1]->{'ZRM-RiskStatement'}->[0], 630, 'parent ServiceRequest supplies statement when child origin is empty' );

our $ApplicationMode = 1;
$Rows = [
    { 'ZRM-RiskStatement' => [630], 'ZRM-RiskTargetCI' => [4147],
      'ZRM-RiskPlan' => 'Keep the authored plan', 'ZRM-InherentCalculatedRisk' => '9' },
    { 'ZRM-RiskStatement' => [630], 'ZRM-RiskTargetCI' => [4148],
      'ZRM-RiskPlan' => 'Keep the authored plan', 'ZRM-InherentCalculatedRisk' => '9' },
];
$Action->_RiskAssessmentTemplateHydrateIfEmpty( Ticket => $Ticket );
is( scalar @{$Rows}, 1, 'existing asset rows collapse into one Application Risk row' );
is_deeply( $Rows->[0]->{'ZRM-RiskTargetGO'}, [1493], 'merged row targets the Application' );
is_deeply( $Rows->[0]->{'ZRM-RiskTargetCI'}, [4147, 4148], 'merged row retains all affected CIs' );
is( $Rows->[0]->{'ZRM-RiskPlan'}, 'Keep the authored plan', 'authored plan is preserved during collapse' );
is( $Rows->[0]->{'ZRM-InherentCalculatedRisk'}, '9', 'merged row carries the single Framework score' );
$Action->_RiskAssessmentTemplateHydrateIfEmpty( Ticket => $Ticket );
is( scalar @{$Rows}, 1, 'Application Risk merge is idempotent' );

my $RowHTML = $Action->_RiskAssessmentRowHTML(
    Index   => 0,
    Row     => { 'ZRM-RiskDetail' => 'Engineer narrative' },
    Columns => [ { Field => 'ZRM-RiskDetail', Type => 'TextArea', Label => 'Risk Detail' } ],
    Targets => [],
    Configs => {},
);
like(
    $RowHTML,
    qr{<div class="ZTSMRiskAssessmentField ZTSMRiskAssessmentField_ZRM-RiskDetail"[^>]* role="group" aria-labelledby="RA_0_ZRM-RiskDetail_Caption"><span class="ZTSMRiskAssessmentCaption" id="RA_0_ZRM-RiskDetail_Caption">Risk Detail</span>},
    'assessment row renders a visible named caption for its editable field',
);

done_testing();
