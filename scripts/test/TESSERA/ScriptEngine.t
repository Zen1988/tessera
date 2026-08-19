use strict;
use warnings;
use Test::More;
use YAML::XS ();

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptEngine;
use Kernel::System::TESSERA::PolicyEngine;

my @SearchCalls;
my $Engine = Kernel::System::TESSERA::ScriptEngine->new(
    SearchProvider => sub {
        my (%Param) = @_;
        push @SearchCalls, \%Param;
        return [
            {
                Name => 'Cloud Primary Assignment',
                'DynamicField_ZTSMSupportAssignment-SupportProfile' => 59,
            },
        ];
    },
);

my $Script = YAML::XS::LoadFile(
    'Kernel/Package/GovernanceDB/var/governancedb/script/governance_role_dynamic_resolver.yml'
);

my $Parsed = $Engine->ScriptParse( Script => $Script );
ok( $Parsed->{Success}, 'English YAML structure parses' );

my $Result = $Engine->ScriptEvaluate(
    Parsed  => $Parsed,
    Context => {
        'CURRENT OBJECT' => 13,
        TICKET => {
            'DynamicField_ZTicket-Application' => 88,
        },
    },
);
ok( $Result->{Success}, 'typed governance role script evaluates' );
is( $Result->{Status}, 'RETURNED', 'script returns a terminal result' );
is( $Result->{Value}, 59, 'support profile value is returned' );
is( $Result->{ValueType}, 'GovernanceObject.SupportProfile', 'declared return type is preserved' );
is( $SearchCalls[0]->{Where}->{'ZTSMSupportAssignment-Role'}->{EQUALS}, 13, 'CURRENT OBJECT is resolved' );
is( $SearchCalls[0]->{Where}->{'ZTSMSupportAssignment-Application'}->{EQUALS}, 88, 'ticket context is resolved' );

my $Ambiguous = Kernel::System::TESSERA::ScriptEngine->new(
    SearchProvider => sub { return [ { Name => 'One' }, { Name => 'Two' } ]; },
)->ScriptEvaluate( Script => $Script, Context => { 'CURRENT OBJECT' => 13, TICKET => { 'ZTicket-Application' => 88 } } );
is( $Ambiguous->{Status}, 'UNKNOWN', 'ambiguous resolution fails closed' );
like( $Ambiguous->{Error}, qr/exactly one SupportAssignment/i, 'author-provided ambiguity reason is returned' );

my $Unsafe = $Engine->ScriptParse(
    Script => {
        VERSION => 1,
        SEARCH  => { FOR => 'GovernanceObject', CLASS => 'SupportProfile', AS => 'Profiles', LIMIT => 1001 },
        RETURN  => { FROM => 'FIRST Profiles' },
    },
);
ok( !$Unsafe->{Success}, 'searches above the engine maximum are rejected' );

my $Policy = Kernel::System::TESSERA::PolicyEngine->new();
my $Legacy = $Policy->Evaluate( Source => '@TICKET.Priority EQUALS "5 very high"', Context => { TICKET => { Priority => '5 very high' } } );
is( $Legacy->{Status}, 'SATISFIED', 'PolicyEngine remains a compatible facade' );

my $RequesterScript = YAML::XS::LoadFile(
    'Kernel/Package/GovernanceDB/var/governancedb/script/governance_role_requester.yml'
);
my $RequesterResult = $Engine->ScriptEvaluate(
    Script  => $RequesterScript,
    Context => {
        TICKET => {
            CustomerUser => {
                __Value => 'requester.login',
                'DynamicField_ZUser-SupportProfile' => 59,
            },
        },
    },
);
is( $RequesterResult->{Value}, 59, 'REQUESTER returns the customer user support profile when present' );
is( $RequesterResult->{ValueType}, 'GovernanceObject.SupportProfile', 'REQUESTER support profile result is typed' );

$RequesterResult = $Engine->ScriptEvaluate(
    Script  => $RequesterScript,
    Context => {
        TICKET => {
            CustomerUser => { __Value => 'requester.login' },
        },
    },
);
is( $RequesterResult->{Value}, 'requester.login', 'REQUESTER falls back to the customer user' );
is( $RequesterResult->{ValueType}, 'CustomerUser', 'REQUESTER fallback result is typed' );

done_testing;
