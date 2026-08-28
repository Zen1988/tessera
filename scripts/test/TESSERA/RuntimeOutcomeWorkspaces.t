use strict;
use warnings;

use File::Spec;
use FindBin qw($Bin);
use Test::More;

my $Root = File::Spec->rel2abs( File::Spec->catdir( $Bin, '..', '..', '..' ) );

sub Slurp {
    my ($Path) = @_;
    open my $FH, '<', $Path or die "Could not read $Path: $!";
    local $/;
    return <$FH>;
}

my $Action = Slurp( File::Spec->catfile( $Root, qw(Kernel Package GovernanceDB var governancedb runtime_overlay Kernel Modules CustomerTicketZTSMAction.pm) ) );
my $Zoom   = Slurp( File::Spec->catfile( $Root, qw(Kernel Package GovernanceDB var governancedb runtime_overlay Kernel Modules CustomerTicketZoom.pm) ) );
my $Bootstrap = Slurp( File::Spec->catfile( $Root, qw(Kernel Package GovernanceDB Kernel System GovernanceDB Bootstrap.pm) ) );

for my $Field (qw(IncidentState ResolutionOutcome TreatmentTicket RiskTreatmentOutcome)) {
    like( $Bootstrap, qr/Name\s*=>\s*'$Field'/, "bootstrap creates exported $Field field" );
}

like( $Zoom, qr/Types\s*=>\s*\['Resolution'\]/, 'Resolution has a dedicated runtime action' );
like( $Zoom, qr/Fields\s*=>\s*\[\s*'ZTicket-Result',\s*'ResolutionOutcome'\s*\]/, 'Resolution renders rich work detail before outcome' );
like( $Zoom, qr/sub _ZTSMRiskTreatmentHTML/, 'Risk Treatment renders approved plans as context' );
like( $Zoom, qr/Fields\s*=>\s*\[\s*'TreatmentTicket',\s*'ZTicket-Result',\s*'RiskTreatmentOutcome'\s*\]/, 'Risk Treatment renders reference, detail, and outcome in order' );
like( $Zoom, qr/Fields\s*=>\s*\['IncidentState'\]/, 'Confirmation uses the exported IncidentState field' );

like( $Action, qr/sub _ResolutionLoopbackApply/, 'unsuccessful resolution has centralized diagnosis loopback' );
like( $Action, qr/for my \$RelatedTicketID \( \$ParentTicketID, \@RelatedTicketIDs \)/, 'loopback synchronizes iteration across the ticket family' );
like( $Action, qr/Connected Ticket Status at Submission/, 'Risk Treatment article snapshots connected ticket status' );
like( $Action, qr/Details of Work Done/, 'rich work detail is included in execution evidence' );
like( $Action, qr/\$ConfirmationStatus eq 'self-recovered'/, 'self-recovered confirmation is successful' );
like( $Action, qr/\$ConfirmationStatus eq 'no longer observed'/, 'no-longer-observed confirmation is successful' );

done_testing();
