use strict;
use warnings;
use Test::More;

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::PolicyEngine;

my $Engine = Kernel::System::TESSERA::PolicyEngine->new();

my $Source = <<'POLICY';
NEW @TICKET
SET @TICKET.Title = "Annual input validation attestation"
SET @TICKET.Queue = "Governance"
SET @TICKET.CustomerUser = "customer.login"
SET @TICKET.Attestation = [
  { ZRM-Query = "Confirm server-side input validation is implemented.", ZRM-Response = "" },
  { ZRM-Query = "Confirm invalid input is rejected.", ZRM-Response = "" }
]
SUBMIT
EXPECT:
@TICKET.Attestation[0].ZRM-Response EQUALS "Yes"
AND @TICKET.Attestation[1].ZRM-Response EQUALS "Yes"
THEN PASS
ELSE FAIL
POLICY

my $Parsed = $Engine->ProgramParse( Source => $Source );
ok( $Parsed->{Success}, 'manual attestation program parses' );
ok( $Parsed->{Program}{TicketRequested}, 'service-backed ticket draft is requested' );
ok( $Parsed->{Program}{SubmitRequested}, 'draft is submitted after assignments' );
is( $Parsed->{Program}{Assignments}{Title}, 'Annual input validation attestation', 'native ticket assignment parsed' );
is( scalar @{ $Parsed->{Program}{Attestation} }, 2, 'two attestation rows parsed' );
is( $Parsed->{Program}{Attestation}[1]{'ZRM-Query'}, 'Confirm invalid input is rejected.', 'query preserved' );
is( $Parsed->{Program}{PassResult}, 'Pass', 'pass result parsed' );
is( $Parsed->{Program}{ElseResult}, 'Fail', 'fail result parsed' );

my $Result = $Engine->ProgramEvaluate(
    Program => $Parsed,
    Context => {
        TICKET => {
            DynamicField_Attestation => [
                { 'ZRM-Query' => 'First',  'ZRM-Response' => 'Yes' },
                { 'ZRM-Query' => 'Second', 'ZRM-Response' => 'Yes' },
            ],
        },
    },
);
ok( $Result->{Success}, 'completed response can be evaluated' );
is( $Result->{Result}, 'Pass', 'all expected responses pass' );

$Result = $Engine->ProgramEvaluate(
    Program => $Parsed,
    Context => {
        TICKET => {
            DynamicField_Attestation => [
                { 'ZRM-Response' => 'Yes' },
                { 'ZRM-Response' => 'No' },
            ],
        },
    },
);
is( $Result->{Result}, 'Fail', 'a failed response maps to Fail' );

my $Indexed = $Engine->ProgramParse(
    Source => <<'POLICY',
NEW @TICKET
LET @TICKET.Attestation[0].ZRM-Query = "First question"
LET @TICKET.Attestation[0].ZRM-Response = ""
SUBMIT
EXPECT:
@TICKET.Attestation[0].ZRM-Response IS NOT EMPTY
THEN PASS
ELSE FAIL
POLICY
);
ok( $Indexed->{Success}, 'indexed attestation authoring parses' );
is( $Indexed->{Program}{Attestation}[0]{'ZRM-Query'}, 'First question', 'indexed query materializes into row' );

done_testing;
