use strict;
use warnings;
use Test::More;

my $BootstrapPath = 'Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm';
open my $BootstrapFH, '<:raw', $BootstrapPath or die "Cannot read $BootstrapPath: $!";
local $/;
my $Bootstrap = <$BootstrapFH>;
close $BootstrapFH;

for my $Role (qw(REQUESTER REQUESTER-DEFAULT REQUESTER-SUPPORT-GROUP)) {
    like(
        $Bootstrap,
        qr/\Q$Role\E[^\n]*=>\s*\$RequesterScript/,
        "$Role receives the requester resolver",
    );
}
for my $Role (qw(DIAGNOSE ASSESSOR ENDORSER APPROVER IMPLEMENTER VERIFIER SUPPORT ASSET ESCALATION)) {
    like(
        $Bootstrap,
        qr/qw\([^)]*\b\Q$Role\E\b[^)]*\)/,
        "$Role receives the SupportAssignment resolver",
    );
}
like( $Bootstrap, qr/my \$RequesterScript = <<'END_REQUESTER_SCRIPT'/, 'requester script is embedded in bootstrap' );
like( $Bootstrap, qr/my \$DynamicResolverScript = <<'END_DYNAMIC_RESOLVER_SCRIPT'/, 'dynamic resolver is embedded in bootstrap' );
like(
    $Bootstrap,
    qr/next ROLE if \$Self->_BootstrapValueHasContent\(\$CurrentScript\)/,
    'bootstrap preserves every existing non-empty GovernanceRole script regardless of value shape',
);
like( $Bootstrap, qr/Unknown reference shapes are treated as authored content/, 'bootstrap fails closed against intrusive script replacement' );
like(
    $Bootstrap,
    qr/'DynamicField_ZTSM-ScriptEngine'\s*=>\s*\$ScriptFor\{\$Role\}/,
    'bootstrap writes the exact exported script field',
);

for my $RoleDirectorPath (
    'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/GenericAgent/ZTSMRoleDirector.pm',
    'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/ProcessManagement/TransitionAction/ZTSMRoleDirector.pm',
    )
{
    open my $RoleDirectorFH, '<:raw', $RoleDirectorPath or die "Cannot read $RoleDirectorPath: $!";
    my $RoleDirector = <$RoleDirectorFH>;
    close $RoleDirectorFH;
    like( $RoleDirector, qr/eq 'GovernanceObject\.SupportProfile'/, "$RoleDirectorPath recognizes typed SupportProfile results" );
    like( $RoleDirector, qr/eq 'CustomerUser'/, "$RoleDirectorPath recognizes typed CustomerUser results" );
    like( $RoleDirector, qr/FieldName\s*=>\s*'ZTicket-OwnerGroup'/, "$RoleDirectorPath retains the OwnerGroup assignment path" );
    like( $RoleDirector, qr/FieldName\s*=>\s*'ZTicket-Owner'/, "$RoleDirectorPath retains the individual owner assignment path" );
}

done_testing;
