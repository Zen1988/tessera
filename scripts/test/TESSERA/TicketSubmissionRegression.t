use strict;
use warnings;
use Test::More;

my $Root = '.';

sub ContentGet {
    my ($Path) = @_;
    open my $FH, '<:raw', $Path or die "Cannot read $Path: $!";
    local $/;
    my $Content = <$FH>;
    close $FH;
    return $Content;
}

for my $Relative (
    'Kernel/Package/GovernanceDB/Kernel/Modules/CustomerTicketMessage.pm',
    'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerTicketMessage.pm',
) {
    my $Content = ContentGet("$Root/$Relative");
    like(
        $Content,
        qr{defined \$GetParam\{Dest\} && \$GetParam\{Dest\} =~ /\^\(\\d},
        "$Relative guards an absent queue destination before matching it",
    );
}

my $Search = ContentGet(
    "$Root/Kernel/Package/GovernanceDB/Kernel/System/GovernanceObject/GovernanceObjectSearch.pm"
);
like( $Search, qr{return 1 if grep \{ defined \$_ && \$_ eq 'Name' \} \@SortBy;},
    'GovernanceObject Name sorting requires the version-table join' );

my $Policy = ContentGet(
    "$Root/Kernel/Package/GovernanceDB/Kernel/System/TESSERA/PolicyEngine.pm"
);
like( $Policy, qr{our \@ObjectDependencies\s*=},
    'PolicyEngine declares dependencies on the concrete ObjectManager class' );
for my $Dependency (qw(DateTime GovernanceObject ITSMConfigItem Ticket YAML)) {
    like( $Policy, qr{Kernel::System::\Q$Dependency\E}, "PolicyEngine declares $Dependency dependency" );
}

my $CustomerMessage = ContentGet(
    "$Root/Kernel/Package/GovernanceDB/Kernel/Modules/CustomerTicketMessage.pm"
);
like( $CustomerMessage, qr{sub _ZTSMActiveCreateStateGet},
    'customer ticket creation validates that its initial state is active' );
like( $CustomerMessage, qr{TypeName.*?new\|open\|pending}s,
    'closed and removed state types cannot be used for ordinary customer ticket creation' );
like( $CustomerMessage, qr{backend-article-created.*?backend-article-create-failed}s,
    'submission tracing distinguishes article persistence from article failure' );
like( $CustomerMessage, qr{backend-dynamicfield-valueset-exception},
    'Dynamic Field backend exceptions are isolated and reported after ticket allocation' );
like( $CustomerMessage, qr{service article snapshot failed},
    'service snapshot failure cannot abort mandatory article creation' );

done_testing;
