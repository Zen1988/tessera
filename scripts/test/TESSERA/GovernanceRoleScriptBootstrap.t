use strict;
use warnings;
use Test::More;

my $BootstrapPath = 'Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm';
open my $BootstrapFH, '<:raw', $BootstrapPath or die "Cannot read $BootstrapPath: $!";
local $/;
my $Bootstrap = <$BootstrapFH>;
close $BootstrapFH;

my @ExportedRoles = (
    qw(
        PLATFORM::NETWORK PLATFORM::SERVICE PLATFORM::INFRA PLATFORM::SYSTEM PLATFORM::HELPDESK
        PLATFORM::BACKUP PLATFORM::SECURITY PLATFORM::DEFAULT PLATFORM::DATABASE PLATFORM::OWNER PLATFORM::DC
        APPLICATION::OWNER APPLICATION::SUPPORT APPLICATION::NETWORK APPLICATION::SYSTEM APPLICATION::DATABASE
        APPLICATION::SECURITY APPLICATION::DEFAULT
        TICKET::ENDORSER TICKET::APPROVER TICKET::ASSESSOR TICKET::IMPLEMENTER TICKET::REQUESTER
        TICKET::VERIFIER TICKET::DIAGNOSE
        SUPPORT::PRIMARY SUPPORT::SECONDARY SUPPORT::ESCALATION
        TESSERA::CMDB::READ TESSERA::CMDB::API TESSERA::CMDB::API::READONLY
        TESSERA::TICKET::API TESSERA::TICKET::API::READONLY TESSERA::MELT::API
        TESSERA::MELT::API::READONLY TESSERA::GDB::API TESSERA::GDB::API::READONLY
    )
);
for my $Role (@ExportedRoles) {
    like( $Bootstrap, qr/Name\s*=>\s*'\Q$Role\E'/, "$Role is a first-class create-if-missing GovernanceRole" );
}
like( $Bootstrap, qr/my \$RequesterScript = <<'END_REQUESTER_SCRIPT'/, 'requester script is embedded in bootstrap' );
like( $Bootstrap, qr/LET THIS:\s*TICKET/, 'scripted GovernanceRoles bind the runtime Ticket as THIS' );
like( $Bootstrap, qr/Platform\.RoleMap\[GovernanceRole=CURRENT OBJECT\]\.SupportProfile/, 'Platform roles carry executable RoleMap programs' );
like( $Bootstrap, qr/ZTicket-Application\.RoleMap\[GovernanceRole=CURRENT OBJECT\]\.SupportProfile/, 'Application roles carry executable RoleMap programs' );
for my $Mapping (
    [ 'TICKET::ASSESSOR',    'Assessment' ],
    [ 'TICKET::ENDORSER',    'Endorsement' ],
    [ 'TICKET::APPROVER',    'Approval' ],
    [ 'TICKET::IMPLEMENTER', 'Implementation' ],
    [ 'TICKET::VERIFIER',    'Verification' ],
    )
{
    like( $Bootstrap, qr/'\Q$Mapping->[0]\E'\s*=>\s*'\Q$Mapping->[1]\E'/, "$Mapping->[0] uses $Mapping->[1] evidence" );
}
like( $Bootstrap, qr/TICKET FIELD COLLECTION/, 'evidence roles use the executable ticket collection operation' );
like( $Bootstrap, qr/Collection<GovernanceObject\.SupportProfile>/, 'evidence roles return strict SupportProfile collections' );
like( $Bootstrap, qr/FALLBACK OFFSET:\s*-1/, 'evidence roles declare numeric previous-iteration fallback explicitly' );
like( $Bootstrap, qr/FIELD: ZIN-Outcome.*?Severity Confirmed.*?Root Cause Observed/s, 'DIAGNOSE explicitly allowlists affected outcomes' );
like( $Bootstrap, qr/FIELD: RiskAssessmentOutcome.*?Mitigation Control in Place.*?Risk Accepted/s, 'ASSESSOR explicitly allowlists affected outcomes' );
unlike( $Bootstrap, qr/\$NormalizedCurrent ne \$NormalizedLegacy/, 'bootstrap never upgrades an existing GovernanceRole script' );
like( $Bootstrap, qr/sub _GovernanceRoleDynamicFieldValueSet/, 'bootstrap has a first-class GovernanceRole field writer' );
like( $Bootstrap, qr/ObjectID\s*=>\s*\$GovernanceObject->\{VersionID\}/, 'script value is stored against the GovernanceObject VersionID' );
like( $Bootstrap, qr/DynamicField::Backend'\)->ValueSet/, 'script writer uses the DynamicField backend' );
like( $Bootstrap, qr/DynamicField::Backend'\)->ValueGet/, 'script writer verifies the persisted value' );
unlike(
    $Bootstrap,
    qr/if \( \$Self->_BootstrapValueHasContent\(\$CurrentScript\) \)/,
    'bootstrap does not inspect an existing GovernanceRole script for replacement',
);
like( $Bootstrap, qr/next ROLE if \$ExistingID;/, 'bootstrap leaves every existing GovernanceRole unchanged' );
like( $Bootstrap, qr/Unknown reference shapes are treated as authored content/, 'bootstrap fails closed against intrusive script replacement' );
like(
    $Bootstrap,
    qr/'DynamicField_ZTSM-ScriptEngine'\s*=>\s*\$RoleDefinition->\{Script\}/,
    'bootstrap writes the exact exported script field',
);
like( $Bootstrap, qr/'DynamicField_ZTSM-Code'\s*=>\s*\$Role/, 'bootstrap writes the exported role code' );
like( $Bootstrap, qr/'DynamicField_ZTSM-Status'\s*=>\s*'Active'/, 'bootstrap writes the exported active status' );
unlike( $Bootstrap, qr/Name\s*=>\s*'ASSET'/, 'legacy ASSET capability is not created on fresh installs' );

my $ResolverPath = 'Kernel/Package/GovernanceDB/Kernel/System/TESSERA/GovernanceRoleResolver.pm';
open my $ResolverFH, '<:raw', $ResolverPath or die "Cannot read $ResolverPath: $!";
my $Resolver = <$ResolverFH>;
close $ResolverFH;
like( $Resolver, qr/\\ATESSERA::/, 'TESSERA namespace is detected as reserved' );
like( $Resolver, qr/RESERVED_CAPABILITY/, 'reserved TESSERA capabilities cannot execute resolver scripts' );

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
    like( $RoleDirector, qr/eq 'Collection<SupportAssignment>'/, "$RoleDirectorPath recognizes typed assignment collections" );
    like( $RoleDirector, qr/Collection<GovernanceObject\.SupportProfile>/, "$RoleDirectorPath recognizes strict SupportProfile collections" );
    like( $RoleDirector, qr/sub _AssignmentCollectionReconcile/, "$RoleDirectorPath implements typed collection reconciliation" )
        if $RoleDirectorPath =~ m{GenericAgent};
    like( $RoleDirector, qr/TicketStateSet\(.*?closed no action/s, "$RoleDirectorPath handles empty or surplus assignment targets neutrally" );
    like( $RoleDirector, qr/FieldName\s*=>\s*'ZTicket-OwnerGroup'/, "$RoleDirectorPath retains the OwnerGroup assignment path" );
    like( $RoleDirector, qr/FieldName\s*=>\s*'ZTicket-Owner'/, "$RoleDirectorPath retains the individual owner assignment path" );
}

done_testing;
