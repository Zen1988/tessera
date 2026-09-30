use strict;
use warnings;
use Test::More;
use YAML::XS ();

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptEngine;
use Kernel::System::TESSERA::PolicyEngine;

my $Engine = Kernel::System::TESSERA::ScriptEngine->new();

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
            'ZTicket-Application' => {
                'DynamicField_ZTSMAppSystem-Platform' => {
                    'DynamicField_RoleMap' => [
                        {
                            GovernanceRole => 13,
                            SupportProfile => 59,
                        },
                    ],
                },
            },
        },
    },
);
ok( $Result->{Success}, 'typed governance role script evaluates' );
is( $Result->{Status}, 'RETURNED', 'script returns a terminal result' );
is( $Result->{Value}, 59, 'support profile value is returned' );
is( $Result->{ValueType}, 'GovernanceObject.SupportProfile', 'declared return type is preserved' );
is( $Result->{Value}, 59, 'Application.Platform.RoleMap resolves the matching role to SupportProfile' );

my $Ambiguous = $Engine->ScriptEvaluate(
    Script => $Script,
    Context => {
        'CURRENT OBJECT' => 13,
        TICKET => {
            'ZTicket-Application' => {
                'ZTSMAppSystem-Platform' => {
                    RoleMap => [
                        { GovernanceRole => 13, SupportProfile => 59 },
                        { GovernanceRole => 13, SupportProfile => 60 },
                    ],
                },
            },
        },
    },
);
is( $Ambiguous->{Status}, 'UNKNOWN', 'ambiguous resolution fails closed' );
like( $Ambiguous->{Error}, qr/must resolve exactly one row; found 2/i, 'RoleMap ambiguity reason is returned' );

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

my @IterationCalls;
my $AssignmentEngine = Kernel::System::TESSERA::ScriptEngine->new(
    TicketProvider => sub {
        my (%Param) = @_;
        push @IterationCalls, $Param{Iteration};
        return [] if $Param{Iteration} eq '3';
        return [
            { TicketID => 41, 'DynamicField_ZTicket-OwnerGroup' => 91 },
            { TicketID => 42, 'DynamicField_ZTicket-OwnerGroup' => 91 },
            { TicketID => 43, 'DynamicField_ZTicket-Owner'      => 'individual.user' },
        ];
    },
);
my $AssignmentResult = $AssignmentEngine->ScriptEvaluate(
    Script => {
        VERSION => 1,
        RETURN  => { ASSIGNMENTS => { 'TICKET TYPE' => 'Endorsement' }, AS => 'Collection<SupportAssignment>' },
    },
    Context => { TICKET => { TicketID => 50, 'DynamicField_ZTicket-Parent' => 10, 'DynamicField_ZIN-Iteration' => 3 } },
);
is_deeply( \@IterationCalls, [ 3, 2 ], 'assignment resolution prefers current iteration then falls back to previous iteration' );
is( $AssignmentResult->{ValueType}, 'Collection<SupportAssignment>', 'assignment collection has the declared DTO type' );
is( scalar @{ $AssignmentResult->{Value} }, 2, 'assignment collection deduplicates typed targets' );
is( $AssignmentResult->{Value}->[0]->{Type}, 'GovernanceObject.SupportProfile', 'OwnerGroup becomes a SupportProfile assignment' );
is( $AssignmentResult->{Value}->[1]->{Type}, 'CustomerUser', 'Owner fallback becomes a CustomerUser assignment' );

@IterationCalls = ();
$AssignmentEngine->ScriptEvaluate(
    Script => { VERSION => 1, RETURN => { ASSIGNMENTS => { 'TICKET TYPE' => 'Assessment' } } },
    Context => { TICKET => { TicketID => 51, 'DynamicField_ZTicket-Parent' => 10, 'DynamicField_ZIN-Iteration' => '' } },
);
is_deeply( \@IterationCalls, [''], 'empty iteration is handled as the initial unnumbered iteration' );

my @CollectionCalls;
my $CollectionEngine = Kernel::System::TESSERA::ScriptEngine->new(
    TicketProvider => sub {
        my (%Param) = @_;
        push @CollectionCalls, $Param{Iteration};
        return [] if $Param{Iteration} eq '3';
        return [
            { TicketID => 61, 'DynamicField_ZIN-Outcome' => 'Not Applicable', 'DynamicField_ZTicket-OwnerGroup' => 91 },
            { TicketID => 62, 'DynamicField_ZIN-Outcome' => 'Cause Observed', 'DynamicField_ZTicket-OwnerGroup' => 92 },
            { TicketID => 63, 'DynamicField_ZIN-Outcome' => 'Cause Observed', 'DynamicField_ZTicket-OwnerGroup' => 92 },
        ];
    },
);
my $CollectionScript = {
    VERSION => 1,
    'LET THIS' => 'TICKET',
    RETURN  => {
        'TICKET FIELD COLLECTION' => {
            'TICKET TYPE' => 'Diagnosis',
            'STATE TYPE'  => 'closed',
            PARENT => { FIELD => 'ZTicket-Parent', VALUE => 'THIS.ZTicket-Parent' },
            ITERATION => {
                FIELD                   => 'ZIN-Iteration',
                VALUE                   => 'THIS.ZIN-Iteration',
                'CURRENT FIRST'         => 1,
                'FALLBACK OFFSET'       => -1,
                'UNNUMBERED WHEN EMPTY' => 1,
            },
            FILTER => { FIELD => 'ZIN-Outcome', IN => [ 'Cause Observed', 'Root Cause Observed' ] },
            FIELD          => 'ZTicket-OwnerGroup',
            DISTINCT       => 1,
            'IGNORE EMPTY' => 1,
            AS             => 'Collection<GovernanceObject.SupportProfile>',
        },
    },
};
my $CollectionResult = $CollectionEngine->ScriptEvaluate(
    Script  => $CollectionScript,
    Context => { TICKET => { TicketID => 70, 'DynamicField_ZTicket-Parent' => 10, 'DynamicField_ZIN-Iteration' => 3 } },
);
is_deeply( \@CollectionCalls, [ 3, 2 ], 'typed ticket collection applies the explicit -1 iteration fallback' );
is_deeply( $CollectionResult->{Value}, [92], 'typed ticket collection filters outcomes and returns distinct OwnerGroups' );
is( $CollectionResult->{ValueType}, 'Collection<GovernanceObject.SupportProfile>', 'typed ticket collection preserves its strict collection type' );

@CollectionCalls = ();
my $NoAffectedEngine = Kernel::System::TESSERA::ScriptEngine->new(
    TicketProvider => sub {
        my (%Param) = @_;
        push @CollectionCalls, $Param{Iteration};
        return [ { TicketID => 71, 'DynamicField_ZIN-Outcome' => 'Not Applicable', 'DynamicField_ZTicket-OwnerGroup' => 91 } ];
    },
);
my $NoAffected = $NoAffectedEngine->ScriptEvaluate(
    Script  => $CollectionScript,
    Context => { TICKET => { TicketID => 72, 'DynamicField_ZTicket-Parent' => 10, 'DynamicField_ZIN-Iteration' => 3 } },
);
is_deeply( \@CollectionCalls, [3], 'existing current evidence prevents stale previous-iteration fallback after outcome filtering' );
is_deeply( $NoAffected->{Value}, [], 'non-affected current evidence returns a successful empty collection' );

@CollectionCalls = ();
my $Unnumbered = $CollectionEngine->ScriptEvaluate(
    Script  => $CollectionScript,
    Context => { TICKET => { TicketID => 73, 'DynamicField_ZTicket-Parent' => 10, 'DynamicField_ZIN-Iteration' => '' } },
);
is_deeply( \@CollectionCalls, [''], 'typed ticket collection explicitly searches unnumbered evidence when context iteration is empty' );

my $InvalidThis = $Engine->ScriptParse(
    Script => { VERSION => 1, 'LET THIS' => 'CMDB', RETURN => { VALUE => 'THIS' } },
);
ok( !$InvalidThis->{Success}, 'LET THIS rejects object types that the engine does not yet implement' );

my $FieldAssignments = $Engine->FieldAssignmentsEvaluate(
    Script => {
        VERSION => 1,
        RETURN  => {
            AS                  => 'MELTObject.Risk',
            'FIELD ASSIGNMENTS' => {
                'MELT-Control' => 'THIS',
                'MELT-RMF'     => '@CONTROLOBJECTIVE.ZRM-RMF',
            },
        },
    },
    ObjectType => 'MELTObject',
    Class      => 'Risk',
    ThisValue  => 731,
    Context    => { CONTROLOBJECTIVE => { 'DynamicField_ZRM-RMF' => 392 } },
);
ok( $FieldAssignments->{Success}, 'ControlObjective field assignments execute through ScriptEngine' );
is( $FieldAssignments->{Value}->{'MELT-Control'}, 731, 'THIS resolves to the individual Control instance' );
is( $FieldAssignments->{Value}->{'MELT-RMF'}, 392, 'ControlObjective context expressions resolve through the shared value engine' );
is( $FieldAssignments->{ValueType}, 'FieldAssignments<MELTObject.Risk>', 'field assignments return a typed target contract' );

my $WrongTarget = $Engine->FieldAssignmentsEvaluate(
    Script     => { VERSION => 1, RETURN => { AS => 'MELTObject.Alert', 'FIELD ASSIGNMENTS' => {} } },
    ObjectType => 'MELTObject',
    Class      => 'Risk',
);
is( $WrongTarget->{Status}, 'UNKNOWN', 'field-assignment target mismatch fails closed' );

my $MasterTicketScript = YAML::XS::LoadFile('docs/examples/framework/risk-master-ticket.yml');
my $MasterTicketAssignments = $Engine->FieldAssignmentsEvaluate(
    Script => $MasterTicketScript, ObjectType => 'Ticket', Class => 'ServiceRequest',
    Context => {
        RISK => { MELTObjectID => 21, Name => 'EOSL: ICA IaaS Extension', 'DynamicField_MELT-RelatedGO' => [1493] },
        FRAMEWORK => { 'DynamicField_ZRM-RiskMgtStateBook' => [165] },
    },
);
ok( $MasterTicketAssignments->{Success}, 'Framework master ticket YAML uses ScriptEngine assignments' );
is( $MasterTicketAssignments->{Value}->{'ZRM-OriginatedEvent'}, 21, 'source MELT Risk maps into SR' );
is( $MasterTicketAssignments->{Value}->{'ZTicket-Application'}, 1493, 'Risk Application maps into SR before orchestration' );
is( $MasterTicketAssignments->{Value}->{'ZTicket-StateBook'}, 165, 'Framework workflow maps into SR' );
is( $MasterTicketAssignments->{Value}->{Service}, 'Risk::Management', 'Risk service is an authored assignment' );

{
    package RiskReferenceSelectorTestOM;
    sub new { return bless {}, shift }
    sub Get { return $_[0] }
    sub GovernanceObjectGet {
        my ( $Self, %Param ) = @_;
        my %Class = ( 630 => 'RiskStatement', 631 => 'Application', 632 => 'RiskStatement' );
        return { Class => $Class{ $Param{GovernanceObjectID} } }
            if $Class{ $Param{GovernanceObjectID} };
        return;
    }
}
{
    local $Kernel::OM = RiskReferenceSelectorTestOM->new();
    my $Context = { RISK => { 'DynamicField_MELT-RiskStmt' => [630, 631, 632] } };
    my $Selected = $Engine->ValueEvaluate(
        Expression => '@RISK.MELT-RiskStmt[RiskStatement][1]', Context => $Context,
    );
    is( $Selected->{Value}, 632, 'class filter runs before zero-based index selection' );
    my $OutOfRange = $Engine->ValueEvaluate(
        Expression => '@RISK.MELT-RiskStmt[RiskStatement][2]', Context => $Context,
    );
    ok( !$OutOfRange->{Known}, 'out-of-range typed reference fails closed' );
    my $Malformed = $Engine->ValueEvaluate(
        Expression => '@RISK.MELT-RiskStmt[RiskStatement][0]garbage', Context => $Context,
    );
    ok( !$Malformed->{Known}, 'trailing path text cannot be silently ignored' );
}

done_testing;
