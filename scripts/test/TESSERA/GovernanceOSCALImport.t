use strict;
use warnings;
use Test::More;
use JSON::PP ();

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
is( $Control->{name}, 'Input Validation', 'OSCAL title becomes object name' );
like( $Control->{description}, qr/Control Statement\nValidate all application inputs/, 'statement is in description' );
like( $Control->{description}, qr/Control Recommendation\nStrictly validating inputs/, 'guidance is in description' );
is( $Control->{fields}{'ZRM-Policy'}, 'Policy: Application Security', 'control references its domain Policy' );
is( $Control->{fields}{'ZRM-RiskStmt'}, 'RiskStatement: Input Validation', 'portable RiskStatement reference planned' );
ok( !exists $Control->{fields}{'ZRM-ImpactFactor'}, 'TESSERA-only factors are not invented' );
ok( !exists $Control->{fields}{'ZRM-ControlCategory'}, 'OSCAL domain is not confused with TESSERA control category' );

my ($Policy) = grep { $_->{class} eq 'Policy' && $_->{name} eq 'Application Security' } @{ $Plan->{Documents} };
is( $Policy->{fields}{'ZRM-Annex'}, 'AS', 'OSCAL group id becomes Policy annex' );
like( $Policy->{description}, qr/prevent application vulnerabilities/, 'OSCAL group overview becomes Policy description' );
is( $Policy->{fields}{'ZRM-Parent'}, 'Policy: Instruction Manual 8 Reform', 'domain Policy references catalog parent Policy' );

done_testing;
