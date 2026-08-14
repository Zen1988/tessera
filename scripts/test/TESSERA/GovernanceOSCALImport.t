use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);

BEGIN {
    package Kernel::OM;
    sub Get { return bless {}, 'Local::JSON' if $_[1] eq 'Kernel::System::JSON'; die "Unexpected dependency $_[1]" }
    package Local::JSON;
    sub Decode { my ( $Self, %Param ) = @_; return JSON::PP::decode_json( $Param{Data} ) }
}

$Kernel::OM = bless {}, 'Kernel::OM';

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::GovernanceObject::OSCALImport;

my $File = 'Export/tech-standards-master/catalogs/im8-reform.json';
open my $FH, '<:raw', $File or die "Cannot read $File: $!";
local $/;
my $Content = <$FH>;
close $FH;

my $Plan = Kernel::System::GovernanceObject::OSCALImport->new()->Plan( Content => $Content );
ok( $Plan->{Success}, 'GovTech OSCAL catalog parses' ) or diag( $Plan->{Message} || 'no message' );
is( $Plan->{Counts}{Policy}, 16, 'catalog parent plus one Policy for each OSCAL domain' );
ok( $Plan->{Counts}{ControlObjective} > 0, 'ControlObjectives planned' );
is( $Plan->{Counts}{RiskStatement}, $Plan->{Counts}{ControlObjective}, 'every current control has a RiskStatement' );

my ($Control) = grep { $_->{class} eq 'ControlObjective' && $_->{fields}{'ZRM-Annex'} eq 'AS-1' } @{ $Plan->{Documents} };
is( $Control->{name}, 'Input Validation', 'OSCAL title remains the clean object name' );
is( $Control->{fields}{'ZRM-Annex'}, 'AS-1', 'Annex remains in the exported identity field' );
is( $Control->{fields}{'ZRM-Version'}, '2025.05.13', 'Version remains in the exported identity field' );
like( $Control->{description}, qr/Control Statement: Validate all application inputs/, 'statement has a clear colon label' );
like( $Control->{description}, qr/Control Statement:.*\n\nControl Recommendation:/s, 'statement and recommendation are separate paragraphs' );
like( $Control->{description}, qr/Control Recommendation: Strictly validating inputs/, 'recommendation has a clear colon label' );
unlike( $Control->{description}, qr/(?:^|\n)References:/, 'OSCAL link references are not placed in the description' );
unlike( $Control->{description}, qr/IM8 Cloud Security/, 'control-specific reference prose remains outside the description' );
like( $Control->{fields}{'ZRM-PolicyReference'}, qr/^MVSP 2\.5: Security libraries; IM8 Cloud Security/, 'OSCAL links map to the ControlObjective reference field' );
is_deeply( $Control->{fields}{'ZRM-Policy'}, ['Policy: Application Security'], 'catalog-only control references its domain Policy' );
is( $Control->{fields}{'ZRM-RiskStmt'}, 'RiskStatement: Input Validation', 'clean portable RiskStatement preview reference planned' );
is_deeply(
    $Control->{oscal_refs}{'ZRM-RiskStmt'},
    [ { class => 'RiskStatement', annex => 'AS-1', version => '2025.05.13' } ],
    'ControlObjective relationship resolves to the same-Annex same-version RiskStatement',
);
is_deeply(
    $Control->{oscal_refs}{'ZRM-Policy'},
    [ { class => 'Policy', annex => 'AS', version => '2025.05.13' } ],
    'ControlObjective relationship resolves to its versioned domain Policy',
);
ok( !exists $Control->{fields}{'ZRM-ImpactFactor'}, 'TESSERA-only factors are not invented' );
ok( !exists $Control->{fields}{'ZRM-ControlCategory'}, 'OSCAL domain is not confused with TESSERA control category' );
ok( !exists $Control->{fields}{'ZRM-ControlClass'}, 'OSCAL domain is not imported as customer-authored control target language' );
ok( !exists $Control->{fields}{'ZRM-PolicyFilter'}, 'OSCAL prose is not imported as programmable policy filter logic' );
ok( !exists $Control->{fields}{'ZRM-PolicyEvaluation'}, 'OSCAL prose is not imported as programmable policy evaluation logic' );

my ($RiskStatement) = grep { $_->{class} eq 'RiskStatement' && $_->{fields}{'ZRM-Annex'} eq 'AS-1' } @{ $Plan->{Documents} };
is( $RiskStatement->{fields}{'ZRM-PolicyReference'}, $Control->{fields}{'ZRM-PolicyReference'}, 'RiskStatement receives the same OSCAL control references' );

my ($Policy) = grep { $_->{class} eq 'Policy' && $_->{name} eq 'Application Security' } @{ $Plan->{Documents} };
is( $Policy->{fields}{'ZRM-Annex'}, 'AS', 'OSCAL group id becomes Policy annex' );
like( $Policy->{description}, qr/prevent application vulnerabilities/, 'OSCAL group overview becomes Policy description' );
is( $Policy->{fields}{'ZRM-Parent'}, 'Policy: Instruction Manual 8 Reform', 'domain Policy references clean catalog parent Policy' );

my $Zip = Archive::Zip->new();
$Zip->addFile( $File, 'tech-standards-master/catalogs/im8-reform.json' );
for my $ProfileFile ( glob 'Export/tech-standards-master/profiles/*.json' ) {
    ( my $Name = $ProfileFile ) =~ s{.*[\\/]}{};
    $Zip->addFile( $ProfileFile, "tech-standards-master/profiles/$Name" );
}
my ( $TempFH, $TempFile ) = tempfile( SUFFIX => '.zip' );
close $TempFH;
is( $Zip->writeToFileNamed($TempFile), AZ_OK, 'test OSCAL bundle created' );
open my $ZipFH, '<:raw', $TempFile or die "Cannot read $TempFile: $!";
local $/;
my $ZipContent = <$ZipFH>;
close $ZipFH;
unlink $TempFile;

my $BundlePlan = Kernel::System::GovernanceObject::OSCALImport->new()->PlanBundle( Content => $ZipContent );
ok( $BundlePlan->{Success}, 'GovTech OSCAL ZIP bundle parses' ) or diag( $BundlePlan->{Message} || 'no message' );
is( scalar @{ $BundlePlan->{Profiles} }, 6, 'all six low/medium risk profiles resolved' );
is( $BundlePlan->{Counts}{Policy}, 22, 'catalog, domains, and six profile Policies planned' );
my ($BundleControl) = grep { $_->{class} eq 'ControlObjective' && $_->{fields}{'ZRM-Annex'} eq 'AS-1' } @{ $BundlePlan->{Documents} };
is_deeply(
    $BundleControl->{fields}{'ZRM-Policy'},
    [
        'Policy: Application Security',
        'Policy: Low-Risk - Level 1',
        'Policy: Low-Risk - Level 2',
        'Policy: Medium-Risk - Level 0',
        'Policy: Medium-Risk - Level 1',
        'Policy: Medium-Risk - Level 2',
    ],
    'control carries domain plus recursively effective profile Policy memberships',
);

{
    no warnings 'redefine';
    local *Kernel::OM::Get = sub {
        return bless {}, 'Local::PreviousControlObject' if $_[1] eq 'Kernel::System::GovernanceObject';
        die "Unexpected dependency $_[1]";
    };
    my $Inherited = Kernel::System::GovernanceObject::OSCALImport->new()->_PreviousControlProgrammingByAnnex(
        class => 'ControlObjective', annex => 'AS-1', version => '2026.01.01', UserID => 1,
    );
    is_deeply(
        $Inherited,
        {
            'ZRM-ControlClass'     => '@TICKET',
            'ZRM-PolicyFilter'     => 'return $RiskLevel eq q{medium};',
            'ZRM-PolicyEvaluation' => 'return $Evidence->{Passed};',
        },
        'new Annex version inherits only customer-authored programming from the latest prior ControlObjective',
    );
    is_deeply(
        Kernel::System::GovernanceObject::OSCALImport::_ControlProgrammingFromItem({
            'DynamicField_ZRM-PolicyFilter'     => 'existing filter',
            'DynamicField_ZRM-PolicyEvaluation' => 'existing evaluation',
            'DynamicField_ZRM-ControlClass'      => '@GovernanceObject.ControlObjective',
        }),
        {
            'ZRM-ControlClass'     => '@GovernanceObject.ControlObjective',
            'ZRM-PolicyFilter'     => 'existing filter',
            'ZRM-PolicyEvaluation' => 'existing evaluation',
        },
        'same-version re-import preserves all existing programmable policy fields',
    );
}

done_testing;

package Local::PreviousControlObject;
sub GovernanceObjectSearch { return (42, 41) }
sub GovernanceObjectGet {
    my ( $Self, %Param ) = @_;
    return {
        Class                               => 'ControlObjective',
        DynamicField_ZRM_Version            => '2025.05.13',
        'DynamicField_ZRM-Version'           => '2025.05.13',
        'DynamicField_ZRM-PolicyFilter'      => 'return $RiskLevel eq q{medium};',
        'DynamicField_ZRM-PolicyEvaluation'  => 'return $Evidence->{Passed};',
        'DynamicField_ZRM-ControlClass'       => '@TICKET',
    };
}
