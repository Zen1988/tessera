# --
# Kernel/System/TESSERA/ScriptEngine.pm
# --

package Kernel::System::TESSERA::ScriptEngine;

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::GovernanceObject',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Ticket',
    'Kernel::System::YAML',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {
        SearchProvider => $Param{SearchProvider},
        TicketProvider => $Param{TicketProvider},
        MaxSearchLimit => $Param{MaxSearchLimit} || 1000,
    }, $Type;
}

sub ScriptParse {
    my ( $Self, %Param ) = @_;

    my $Script = $Param{Script};
    if ( ref $Script ne 'HASH' ) {
        my $Source = defined $Param{Source} ? $Param{Source} : '';
        return { Success => 0, Status => 'UNKNOWN', Error => 'TESSERA script source is empty.' }
            if $Source !~ m{\S};

        my $Loaded = eval {
            $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => $Source );
        };
        return {
            Success => 0,
            Status  => 'UNKNOWN',
            Error   => 'TESSERA script is not valid YAML: ' . ( $@ || 'unknown YAML error' ),
        } if ref $Loaded ne 'HASH';
        $Script = $Loaded;
    }

    my $Version = defined $Script->{VERSION} ? $Script->{VERSION} : 1;
    return { Success => 0, Status => 'UNKNOWN', Error => "Unsupported TESSERA script version '$Version'." }
        if "$Version" ne '1';

    my $Searches = $Script->{SEARCH};
    $Searches = [$Searches] if ref $Searches eq 'HASH';
    $Searches ||= [];
    return { Success => 0, Status => 'UNKNOWN', Error => 'SEARCH must be a mapping or list.' }
        if ref $Searches ne 'ARRAY';

    my %Variable;
    for my $Search ( @{$Searches} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => 'Each SEARCH entry must be a mapping.' }
            if ref $Search ne 'HASH';
        for my $Required ( 'FOR', 'CLASS', 'AS' ) {
            return { Success => 0, Status => 'UNKNOWN', Error => "SEARCH requires $Required." }
                if !defined $Search->{$Required} || $Search->{$Required} eq '';
        }
        return { Success => 0, Status => 'UNKNOWN', Error => "Duplicate variable '$Search->{AS}'." }
            if $Variable{ $Search->{AS} }++;
        my $Limit = defined $Search->{LIMIT} ? $Search->{LIMIT} : 100;
        return { Success => 0, Status => 'UNKNOWN', Error => "SEARCH '$Search->{AS}' LIMIT must be a positive integer." }
            if $Limit !~ m{\A\d+\z} || !$Limit;
        return { Success => 0, Status => 'UNKNOWN', Error => "SEARCH '$Search->{AS}' exceeds the maximum limit." }
            if $Limit > $Self->{MaxSearchLimit};
        $Search->{LIMIT} = 0 + $Limit;
    }

    return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN is required.' }
        if !exists $Script->{RETURN};

    return { Success => 1, Status => 'READY', Script => $Script, Searches => $Searches };
}

sub ScriptEvaluate {
    my ( $Self, %Param ) = @_;

    my $Parsed = $Param{Parsed};
    $Parsed = $Self->ScriptParse( Source => $Param{Source}, Script => $Param{Script} )
        if ref $Parsed ne 'HASH';
    return $Parsed if !$Parsed->{Success};

    my $Context = ref $Param{Context} eq 'HASH' ? $Param{Context} : {};
    my %Variables;
    my @Trace;

    for my $Search ( @{ $Parsed->{Searches} } ) {
        my $Result = $Self->_ScriptSearch(
            Search    => $Search,
            Context   => $Context,
            Variables => \%Variables,
            UserID    => $Param{UserID} || 1,
        );
        return {
            Success => 0,
            Status  => 'UNKNOWN',
            Error   => $Result->{Error},
            Trace   => \@Trace,
        } if !$Result->{Success};
        $Variables{ $Search->{AS} } = $Result->{Value};
        push @Trace, sprintf 'SEARCH %s[%s] AS %s => %d result(s)',
            $Search->{FOR}, $Search->{CLASS}, $Search->{AS}, scalar @{ $Result->{Value} };
    }

    my $Required = $Self->_ScriptRequire(
        Require   => $Parsed->{Script}->{REQUIRE},
        Variables => \%Variables,
    );
    if ( !$Required->{Success} ) {
        return {
            Success => 0,
            Status  => 'UNKNOWN',
            Error   => $Required->{Error},
            Trace   => \@Trace,
        };
    }

    my $Returned = $Self->_ScriptReturn(
        Return    => $Parsed->{Script}->{RETURN},
        Context   => $Context,
        Variables => \%Variables,
        UserID    => $Param{UserID} || 1,
    );
    $Returned->{Trace} = \@Trace;
    return $Returned;
}

sub _ScriptSearch {
    my ( $Self, %Param ) = @_;

    my $Search = $Param{Search};
    my $Where  = ref $Search->{WHERE} eq 'HASH' ? $Search->{WHERE} : {};
    my %ResolvedWhere;
    for my $Field ( keys %{$Where} ) {
        my $Condition = $Where->{$Field};
        return { Success => 0, Error => "WHERE condition for '$Field' must be a mapping." }
            if ref $Condition ne 'HASH';
        my ($Operator) = keys %{$Condition};
        return { Success => 0, Error => "WHERE condition for '$Field' requires exactly one operator." }
            if !defined $Operator || keys(%{$Condition}) != 1;
        my $Value = $Self->_ScriptValueResolve(
            Value     => $Condition->{$Operator},
            Context   => $Param{Context},
            Variables => $Param{Variables},
        );
        return $Value if !$Value->{Success};
        $ResolvedWhere{$Field} = { uc($Operator) => $Value->{Value} };
    }

    if ( ref $Self->{SearchProvider} eq 'CODE' ) {
        my $Values = eval {
            $Self->{SearchProvider}->(
                For    => $Search->{FOR},
                Class  => $Search->{CLASS},
                Where  => \%ResolvedWhere,
                Limit  => $Search->{LIMIT},
                UserID => $Param{UserID},
            );
        };
        return { Success => 0, Error => 'SEARCH provider failed: ' . $@ } if $@;
        return { Success => 0, Error => 'SEARCH provider must return an array reference.' }
            if ref $Values ne 'ARRAY';
        return { Success => 1, Value => $Values };
    }

    return $Self->_ScriptNativeSearch(
        For    => $Search->{FOR},
        Class  => $Search->{CLASS},
        Where  => \%ResolvedWhere,
        Limit  => $Search->{LIMIT},
        UserID => $Param{UserID},
    );
}

sub _ScriptNativeSearch {
    my ( $Self, %Param ) = @_;

    my %Search = (
        Result  => 'ARRAY',
        Classes => [ $Param{Class} ],
        Limit   => $Param{Limit},
        UserID  => $Param{UserID},
    );
    for my $Field ( keys %{ $Param{Where} } ) {
        my ($Operator) = keys %{ $Param{Where}->{$Field} };
        my $Value = $Param{Where}->{$Field}->{$Operator};
        if ( $Field eq 'Name' ) {
            return { Success => 0, Error => "Name supports EQUALS or CONTAINS, not $Operator." }
                if $Operator ne 'EQUALS' && $Operator ne 'CONTAINS';
            $Search{Name} = $Operator eq 'CONTAINS' ? '%' . $Value . '%' : $Value;
            next;
        }
        if ( $Field eq 'Validity' ) {
            return { Success => 0, Error => 'Validity currently supports EQUALS only.' }
                if $Operator ne 'EQUALS';
            next if lc("$Value") eq 'valid';
            return { Success => 0, Error => "Unsupported Validity value '$Value'." };
        }
        my %OperatorMap = ( EQUALS => 'Equals', CONTAINS => 'Like' );
        return { Success => 0, Error => "Dynamic field '$Field' does not support $Operator." }
            if !$OperatorMap{$Operator};
        $Value = '*' . $Value . '*' if $Operator eq 'CONTAINS';
        $Search{'DynamicField_' . $Field} = { $OperatorMap{$Operator} => $Value };
    }

    my ( $Object, $GetMethod, $IDKey );
    if ( $Param{For} eq 'GovernanceObject' ) {
        $Object    = $Kernel::OM->Get('Kernel::System::GovernanceObject');
        $GetMethod = 'GovernanceObjectGet';
        $IDKey     = 'GovernanceObjectID';
    }
    elsif ( $Param{For} eq 'ITSMConfigItem' ) {
        $Object    = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
        $GetMethod = 'ConfigItemGet';
        $IDKey     = 'ConfigItemID';
    }
    else {
        return { Success => 0, Error => "Unsupported SEARCH object type '$Param{For}'." };
    }

    my $SearchMethod = $Param{For} eq 'GovernanceObject' ? 'GovernanceObjectSearch' : 'ConfigItemSearch';
    my @IDs = eval { $Object->$SearchMethod(%Search) };
    return { Success => 0, Error => "SEARCH $Param{For}[$Param{Class}] failed: $@" } if $@;
    my @Objects;
    for my $ID (@IDs) {
        my $Item = eval { $Object->$GetMethod( $IDKey => $ID, DynamicFields => 1, Silent => 1 ) };
        push @Objects, $Item if ref $Item eq 'HASH';
    }
    return { Success => 1, Value => \@Objects };
}

sub _ScriptRequire {
    my ( $Self, %Param ) = @_;
    return { Success => 1 } if !defined $Param{Require};
    my $Require = $Param{Require};
    return { Success => 0, Error => 'REQUIRE must be a mapping.' } if ref $Require ne 'HASH';
    for my $Variable ( keys %{$Require} ) {
        next if $Variable eq 'OTHERWISE';
        my $Rule = $Require->{$Variable};
        return { Success => 0, Error => "REQUIRE variable '$Variable' is unknown." }
            if !exists $Param{Variables}->{$Variable};
        return { Success => 0, Error => "REQUIRE '$Variable' must be a mapping." }
            if ref $Rule ne 'HASH';
        if ( exists $Rule->{'HAS EXACTLY'} ) {
            my $Expected = $Rule->{'HAS EXACTLY'};
            my $Actual = scalar @{ $Param{Variables}->{$Variable} };
            return {
                Success => 0,
                Error   => $Require->{OTHERWISE} || "$Variable must contain exactly $Expected result(s); found $Actual.",
            } if $Actual != $Expected;
        }
    }
    return { Success => 1 };
}

sub _ScriptReturn {
    my ( $Self, %Param ) = @_;
    my $Return = $Param{Return};
    if ( !ref $Return ) {
        return { Success => 1, Status => 'RETURNED', Value => $Return, ValueType => 'Scalar' };
    }
    return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN must be a scalar or mapping.' }
        if ref $Return ne 'HASH';
    return { Success => 0, Status => 'UNKNOWN', Error => $Return->{UNKNOWN} }
        if exists $Return->{UNKNOWN};

    if ( exists $Return->{ASSIGNMENTS} ) {
        return $Self->_TicketAssignmentsResolve(
            Config  => $Return->{ASSIGNMENTS},
            Context => $Param{Context},
            UserID  => $Param{UserID} || 1,
        );
    }

    if ( exists $Return->{IF} ) {
        my $Condition = $Return->{IF};
        return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN IF must be a mapping.' }
            if ref $Condition ne 'HASH';
        my $Test = $Self->_ScriptValueResolve(
            Value     => $Condition->{VALUE},
            Context   => $Param{Context},
            Variables => $Param{Variables},
            AllowMissing => 1,
        );
        return $Test if !$Test->{Success};
        my $Satisfied;
        if ( exists $Condition->{'IS NOT EMPTY'} ) {
            $Satisfied = defined $Test->{Value} && $Test->{Value} ne '' ? 1 : 0;
        }
        elsif ( exists $Condition->{'IS EMPTY'} ) {
            $Satisfied = !defined $Test->{Value} || $Test->{Value} eq '' ? 1 : 0;
        }
        else {
            return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN IF requires IS EMPTY or IS NOT EMPTY.' };
        }
        my $Branch = $Satisfied ? $Return->{THEN} : $Return->{ELSE};
        return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN IF requires THEN and ELSE mappings.' }
            if ref $Branch ne 'HASH';
        return $Self->_ScriptReturn(
            Return    => $Branch,
            Context   => $Param{Context},
            Variables => $Param{Variables},
            UserID    => $Param{UserID},
        );
    }

    if ( exists $Return->{VALUE} ) {
        my $Value = $Self->_ScriptValueResolve(
            Value     => $Return->{VALUE},
            Context   => $Param{Context},
            Variables => $Param{Variables},
        );
        return $Value if !$Value->{Success};
        return { Success => 1, Status => 'RETURNED', Value => $Value->{Value}, ValueType => $Return->{AS} || 'Scalar' };
    }

    my $From = $Return->{FROM} || '';
    return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN FROM must use FIRST <variable> or EXACTLY ONE <variable>.' }
        if $From !~ m{\A(FIRST|EXACTLY ONE)\s+(.+)\z}i;
    my ( $Mode, $Variable ) = ( uc($1), $2 );
    my $Values = $Param{Variables}->{$Variable};
    return { Success => 0, Status => 'UNKNOWN', Error => "RETURN variable '$Variable' is unknown." }
        if ref $Values ne 'ARRAY';
    return { Success => 0, Status => 'UNKNOWN', Error => "RETURN $Mode $Variable found no values." }
        if !@{$Values};
    return { Success => 0, Status => 'UNKNOWN', Error => "RETURN EXACTLY ONE $Variable found multiple values." }
        if $Mode eq 'EXACTLY ONE' && @{$Values} != 1;

    my $Value = $Values->[0];
    if ( defined $Return->{FIELD} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => "RETURN field '$Return->{FIELD}' cannot be read from a scalar." }
            if ref $Value ne 'HASH';
        my $Field = $Return->{FIELD};
        $Value = exists $Value->{$Field} ? $Value->{$Field} : $Value->{'DynamicField_' . $Field};
        $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
        return { Success => 0, Status => 'UNKNOWN', Error => "RETURN field '$Field' is missing or structured." }
            if !defined $Value || ref $Value;
    }
    return { Success => 1, Status => 'RETURNED', Value => $Value, ValueType => $Return->{AS} || 'Scalar' };
}

sub _TicketAssignmentsResolve {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config};
    return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN ASSIGNMENTS must be a mapping.' }
        if ref $Config ne 'HASH';
    my $TicketType = $Config->{'TICKET TYPE'} || '';
    return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN ASSIGNMENTS requires TICKET TYPE.' }
        if $TicketType eq '';

    my $Ticket = $Param{Context}->{TICKET};
    return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN ASSIGNMENTS requires ticket context.' }
        if ref $Ticket ne 'HASH';
    my $CurrentTicketID = $Ticket->{TicketID};
    my $ParentTicketID = $Ticket->{'DynamicField_ZTicket-Parent'};
    $ParentTicketID = $ParentTicketID->[0]
        if ref $ParentTicketID eq 'ARRAY' && @{$ParentTicketID} == 1;
    my $LedgerTicketID = $ParentTicketID || $CurrentTicketID;
    return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN ASSIGNMENTS cannot resolve the parent ticket reference.' }
        if !$LedgerTicketID;

    my $Iteration = $Ticket->{'DynamicField_ZIN-Iteration'};
    $Iteration = $Iteration->[0] if ref $Iteration eq 'ARRAY' && @{$Iteration} == 1;
    my @Iterations = defined $Iteration && $Iteration ne '' ? ($Iteration) : ('');
    push @Iterations, $Iteration - 1
        if defined $Iteration && $Iteration =~ m{\A\d+\z} && $Iteration > 1;

    ITERATION:
    for my $CandidateIteration (@Iterations) {
        my @FoundTickets;
        if ( ref $Self->{TicketProvider} eq 'CODE' ) {
            my $Provided = eval {
                $Self->{TicketProvider}->(
                    TicketType      => $TicketType,
                    ParentTicketID  => $LedgerTicketID,
                    Iteration       => $CandidateIteration,
                    CurrentTicketID => $CurrentTicketID,
                    UserID          => $Param{UserID} || 1,
                );
            };
            return { Success => 0, Status => 'UNKNOWN', Error => "Ticket assignment provider failed: $@" } if $@;
            return { Success => 0, Status => 'UNKNOWN', Error => 'Ticket assignment provider must return an array reference.' }
                if ref $Provided ne 'ARRAY';
            @FoundTickets = @{$Provided};
        }
        else {
            my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
            my %Search = (
                Result => 'ARRAY',
                Types  => [$TicketType],
                'DynamicField_ZTicket-Parent' => { Equals => $LedgerTicketID },
                UserID => $Param{UserID} || 1,
            );
            $Search{'DynamicField_ZIN-Iteration'} = { Equals => $CandidateIteration }
                if defined $CandidateIteration && $CandidateIteration ne '';
            my @TicketIDs = sort { $a <=> $b } eval { $TicketObject->TicketSearch(%Search) };
            return { Success => 0, Status => 'UNKNOWN', Error => "Ticket assignment search failed: $@" } if $@;
            for my $TicketID (@TicketIDs) {
                my %Found = $TicketObject->TicketGet(
                    TicketID      => $TicketID,
                    DynamicFields => 1,
                    UserID        => $Param{UserID} || 1,
                    Silent        => 1,
                );
                push @FoundTickets, \%Found if %Found;
            }
        }

        my @Assignments;
        my %Seen;
        for my $FoundRef (@FoundTickets) {
            next if ref $FoundRef ne 'HASH';
            my %Found = %{$FoundRef};
            my $TicketID = $Found{TicketID} || 0;
            next if $CurrentTicketID && $TicketID == $CurrentTicketID;
            if ( !defined $CandidateIteration || $CandidateIteration eq '' ) {
                my $FoundIteration = $Found{'DynamicField_ZIN-Iteration'};
                $FoundIteration = $FoundIteration->[0]
                    if ref $FoundIteration eq 'ARRAY' && @{$FoundIteration} == 1;
                next if defined $FoundIteration && !ref $FoundIteration && $FoundIteration ne '';
            }
            my $SupportProfile = $Found{'DynamicField_ZTicket-OwnerGroup'};
            $SupportProfile = $SupportProfile->[0]
                if ref $SupportProfile eq 'ARRAY' && @{$SupportProfile} == 1;
            my ( $Type, $Value );
            if ( defined $SupportProfile && !ref $SupportProfile && $SupportProfile ne '' ) {
                ( $Type, $Value ) = ( 'GovernanceObject.SupportProfile', $SupportProfile );
            }
            else {
                my $CustomerUser = $Found{'DynamicField_ZTicket-Owner'};
                $CustomerUser = $CustomerUser->[0]
                    if ref $CustomerUser eq 'ARRAY' && @{$CustomerUser} == 1;
                next if !defined $CustomerUser || ref $CustomerUser || $CustomerUser eq '';
                ( $Type, $Value ) = ( 'CustomerUser', $CustomerUser );
            }
            next if $Seen{"$Type\0$Value"}++;
            push @Assignments, { Type => $Type, Value => $Value, TicketID => $TicketID };
        }
        next ITERATION if !@Assignments;
        return {
            Success   => 1,
            Status    => 'RETURNED',
            Value     => \@Assignments,
            ValueType => 'Collection<SupportAssignment>',
            Iteration => $CandidateIteration,
        };
    }

    return { Success => 0, Status => 'UNKNOWN', Error => "No $TicketType assignments were found for the current or previous iteration." };
}

sub _ScriptValueResolve {
    my ( $Self, %Param ) = @_;
    my $Value = $Param{Value};
    return { Success => 1, Value => $Value } if ref $Value || !defined $Value;
    return { Success => 1, Value => $Param{Context}->{'CURRENT OBJECT'} }
        if uc($Value) eq 'CURRENT OBJECT';
    if ( $Value =~ m{\A\@?TICKET(?:\.|\z)}i ) {
        my @Path = split m{\.(?![^\[]*\])}, $Value;
        shift @Path;
        my $Resolved = $Param{Context}->{TICKET};
        return { Success => 0, Status => 'UNKNOWN', Error => "Context value '$Value' is unavailable." }
            if ref $Resolved ne 'HASH';
        for my $Segment (@Path) {
            my ( $Field, $FilterField, $FilterValue )
                = $Segment =~ m{\A([^\[]+)(?:\[([^=\]]+)=([^\]]+)\])?\z};
            return { Success => 0, Status => 'UNKNOWN', Error => "Context path segment '$Segment' is invalid." }
                if !defined $Field;
            return { Success => 0, Status => 'UNKNOWN', Error => "Context value '$Value' cannot traverse '$Field'." }
                if ref $Resolved ne 'HASH';
            $Resolved = exists $Resolved->{$Field}
                ? $Resolved->{$Field}
                : $Resolved->{'DynamicField_' . $Field};
            if ( defined $FilterField ) {
                return { Success => 0, Status => 'UNKNOWN', Error => "Context collection '$Field' is unavailable." }
                    if ref $Resolved ne 'ARRAY';
                my $Expected = $Self->_ScriptValueResolve(
                    Value     => $FilterValue,
                    Context   => $Param{Context},
                    Variables => $Param{Variables},
                );
                return $Expected if !$Expected->{Success};
                my @Matching = grep {
                    ref $_ eq 'HASH'
                        && do {
                            my $Candidate = exists $_->{$FilterField}
                                ? $_->{$FilterField}
                                : $_->{'DynamicField_' . $FilterField};
                            $Candidate = $Candidate->[0]
                                if ref $Candidate eq 'ARRAY' && @{$Candidate} == 1;
                            !ref $Candidate
                                && defined $Candidate
                                && defined $Expected->{Value}
                                && "$Candidate" eq "$Expected->{Value}";
                        }
                } @{$Resolved};
                return { Success => 0, Status => 'UNKNOWN', Error => "Context filter '$Segment' must resolve exactly one row; found " . scalar(@Matching) . '.' }
                    if @Matching != 1;
                $Resolved = $Matching[0];
            }
            $Resolved = $Resolved->[0] if ref $Resolved eq 'ARRAY' && @{$Resolved} == 1;
            if ( !defined $Resolved ) {
                return { Success => 1, Value => undef } if $Param{AllowMissing};
                return { Success => 0, Status => 'UNKNOWN', Error => "Context value '$Value' is unavailable." };
            }
        }
        $Resolved = $Resolved->{__Value}
            if ref $Resolved eq 'HASH' && exists $Resolved->{__Value};
        return { Success => 0, Status => 'UNKNOWN', Error => "Context value '$Value' remains structured." }
            if ref $Resolved;
        return { Success => 1, Value => $Resolved };
    }
    return { Success => 1, Value => $Value };
}

sub ProgramParse {
    my ( $Self, %Param ) = @_;

    my $Source = defined $Param{Source} ? $Param{Source} : '';
    $Source =~ s{\r\n?}{\n}g;

    my $Program = {
        TicketRequested => $Source =~ m{(?:\A|\n)\s*(?:NEW\s+\@TICKET|CREATE\s+TICKET)\s*(?:\n|\z)}i ? 1 : 0,
        SubmitRequested => $Source =~ m{(?:\A|\n)\s*SUBMIT\s*(?:\n|\z)}i ? 1 : 0,
        Ticket          => {},
        Assignments     => {},
        Attestation     => [],
        ExpectSource    => '',
        PassResult      => 'Pass',
        ElseResult      => 'Fail',
    };

    while ( $Source =~ m{(?:LET|SET)\s+\@TICKET\.([A-Za-z][A-Za-z0-9_-]*)\s*=\s*("(?:\\.|[^"])*"|[-+]?\d+(?:\.\d+)?|TRUE|FALSE|EMPTY)\s*;?}gis ) {
        my ( $Field, $Literal ) = ( $1, $2 );
        my $Value;
        if ( $Literal =~ m{\A"(.*)"\z}s ) {
            $Value = $1;
            $Value =~ s{\\"}{"}g;
            $Value =~ s{\\n}{\n}g;
            $Value =~ s{\\\\}{\\}g;
        }
        elsif ( uc($Literal) eq 'TRUE' )  { $Value = 1; }
        elsif ( uc($Literal) eq 'FALSE' ) { $Value = 0; }
        elsif ( uc($Literal) eq 'EMPTY' ) { $Value = ''; }
        else                              { $Value = 0 + $Literal; }
        $Program->{Assignments}{$Field} = $Value;
    }

    for my $Declaration (
        [ 'TITLE',         'Title' ],
        [ 'QUEUE',         'Queue' ],
        [ 'TYPE',          'Type' ],
        [ 'STATE',         'State' ],
        [ 'PRIORITY',      'Priority' ],
        [ 'OWNER',         'Owner' ],
        [ 'RESPONSIBLE',   'Responsible' ],
        [ 'CUSTOMER USER', 'CustomerUser' ],
    ) {
        my ( $Keyword, $Key ) = @{$Declaration};
        if ( $Source =~ m{(?:\A|\n)\s*\Q$Keyword\E\s+"((?:\\.|[^"])*)"\s*;?}i ) {
            my $Value = $1;
            $Value =~ s{\\"}{"}g;
            $Value =~ s{\\n}{\n}g;
            $Value =~ s{\\\\}{\\}g;
            $Program->{Ticket}{$Key} = $Value;
        }
    }

    if ( $Source =~ m{SET\s+\@TICKET\.Attestation\s*=\s*\[(.*?)\]\s*;?}is ) {
        my $Rows = $1;
        while ( $Rows =~ m{\{(.*?)\}}gs ) {
            my %Row;
            my $Body = $1;
            while ( $Body =~ m{(?:\A|,)\s*(ZRM-(?:Query|Response))\s*=\s*"((?:\\.|[^"])*)"\s*}g ) {
                my ( $Field, $Value ) = ( $1, $2 );
                $Value =~ s{\\"}{"}g;
                $Value =~ s{\\n}{\n}g;
                $Value =~ s{\\\\}{\\}g;
                $Row{$Field} = $Value;
            }
            push @{ $Program->{Attestation} }, \%Row if defined $Row{'ZRM-Query'};
        }
    }

    # Positional declarations are accepted as a compact authoring form. They
    # materialize into the same exported Attestation Dynamic Field Set.
    while ( $Source =~ m{(?:LET|SET)\s+\@TICKET\.Attestation\[(\d+)\]\.(ZRM-(?:Query|Response))\s*=\s*"((?:\\.|[^"])*)"\s*;?}gis ) {
        my ( $Index, $Field, $Value ) = ( $1, $2, $3 );
        $Value =~ s{\\"}{"}g;
        $Value =~ s{\\n}{\n}g;
        $Value =~ s{\\\\}{\\}g;
        $Program->{Attestation}->[$Index] ||= {};
        $Program->{Attestation}->[$Index]{$Field} = $Value;
    }

    if ( $Source =~ m{(?:\A|\n)\s*EXPECT\s*:?[ \t]*\n(.*?)(?:\n\s*THEN\s+(PASS|FAIL|N/A)\b)(?:.*?\n\s*ELSE\s+(PASS|FAIL|N/A)\b)?}is ) {
        my ( $Expect, $Pass, $Else ) = ( $1, $2, $3 );
        $Expect =~ s{\A\s+|\s+\z}{}g;
        $Program->{ExpectSource} = $Expect;
        $Program->{PassResult}   = _ResultNormalize($Pass);
        $Program->{ElseResult}   = _ResultNormalize( $Else || 'Fail' );
    }

    return {
        Success => 0,
        Error   => 'An attestation program requires a non-empty EXPECT block.',
        Program => $Program,
    } if @{ $Program->{Attestation} } && !$Program->{ExpectSource};

    return {
        Success => 0,
        Error   => 'NEW @TICKET requires SUBMIT after its assignments.',
        Program => $Program,
    } if $Program->{TicketRequested} && !$Program->{SubmitRequested};

    return { Success => 1, Program => $Program };
}

sub ProgramEvaluate {
    my ( $Self, %Param ) = @_;

    my $Parsed = $Param{Program};
    $Parsed = $Self->ProgramParse( Source => $Param{Source} ) if ref $Parsed ne 'HASH';
    return $Parsed if !$Parsed->{Success};

    my $Program = $Parsed->{Program};
    my $Evaluation = $Self->Evaluate(
        Source  => $Program->{ExpectSource},
        Label   => 'EXPECT',
        Context => $Param{Context},
    );
    my $Result = $Evaluation->{Status} eq 'SATISFIED'
        ? $Program->{PassResult}
        : $Evaluation->{Status} eq 'NOT_SATISFIED'
            ? $Program->{ElseResult}
            : undef;

    return {
        Success    => defined $Result ? 1 : 0,
        Result     => $Result,
        Evaluation => $Evaluation,
        Error      => defined $Result ? undef : 'EXPECT could not be evaluated; result remains UNKNOWN.',
    };
}

sub Evaluate {
    my ( $Self, %Param ) = @_;

    my $Source = defined $Param{Source} ? $Param{Source} : '';
    my $Label  = $Param{Label} || 'Policy';
    my $Context = ref $Param{Context} eq 'HASH' ? $Param{Context} : {};

    my @Lines = $Self->_PolicyLines($Source);
    return {
        Status => 'UNKNOWN',
        Reason => "$Label is empty.",
        Trace  => [],
    } if !@Lines;

    my $Result;
    my @Trace;
    my @Reasons;

    LINE:
    for my $Line (@Lines) {
        my $Join = 'AND';
        if ( $Line =~ s{\A(AND|OR)\s+}{}i ) {
            $Join = uc $1;
        }

        my $Condition = $Self->_ConditionEvaluate(
            Expression => $Line,
            Context    => $Context,
        );

        push @Trace, "$Line => $Condition->{Status}";
        push @Reasons, $Condition->{Reason} if $Condition->{Reason};

        if ( !defined $Result ) {
            $Result = $Condition->{Value};
            next LINE;
        }

        $Result = $Join eq 'OR'
            ? _TruthOr( $Result, $Condition->{Value} )
            : _TruthAnd( $Result, $Condition->{Value} );
    }

    my $Status = !defined $Result ? 'UNKNOWN' : $Result ? 'SATISFIED' : 'NOT_SATISFIED';
    return {
        Status => $Status,
        Value  => $Result,
        Reason => join( ' ', @Reasons ),
        Trace  => \@Trace,
    };
}

sub ValueEvaluate {
    my ( $Self, %Param ) = @_;

    return $Self->_Value(
        Expression => defined $Param{Expression} ? $Param{Expression} : '',
        Context    => ref $Param{Context} eq 'HASH' ? $Param{Context} : {},
    );
}

sub FieldAssignmentsEvaluate {
    my ( $Self, %Param ) = @_;

    my $Source = defined $Param{Source} ? $Param{Source} : '';
    return { Success => 0, Status => 'UNKNOWN', Error => 'Field-assignment script is empty.' }
        if $Source !~ m{\S} && ref $Param{Script} ne 'HASH';

    my ( $Target, $Assignments );
    my $Loaded = $Param{Script};
    $Loaded = eval { $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => $Source ) }
        if ref $Loaded ne 'HASH';
    if ( ref $Loaded eq 'HASH' ) {
        my $Version = defined $Loaded->{VERSION} ? $Loaded->{VERSION} : 1;
        return { Success => 0, Status => 'UNKNOWN', Error => "Unsupported TESSERA script version '$Version'." }
            if "$Version" ne '1';
        my $Return = $Loaded->{RETURN};
        return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN must be a mapping.' }
            if ref $Return ne 'HASH';
        $Target      = $Return->{AS} || '';
        $Assignments = $Return->{'FIELD ASSIGNMENTS'};
        return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN FIELD ASSIGNMENTS must be a mapping.' }
            if ref $Assignments ne 'HASH';
    }
    else {
        # Compatibility for ControlObjective values authored before field assignments
        # became a first-class YAML ScriptEngine return type.
        $Assignments = {};
        for my $Line ( split m{\r?\n}, $Source ) {
            $Line =~ s{\s*\#.*\z}{};
            $Line =~ s{\A\s+|\s+\z}{}g;
            next if $Line eq '';
            return { Success => 0, Status => 'UNKNOWN', Error => "Unsupported field-assignment line: $Line" }
                if $Line !~ m{\ASET\s+\@?([A-Za-z][A-Za-z0-9_-]*\.[A-Za-z][A-Za-z0-9_-]*)\.([A-Za-z][A-Za-z0-9_-]*)\s*(?:=\s*)?(.+?)\s*;?\z}i;
            my ( $LineTarget, $Field, $Expression ) = ( $1, $2, $3 );
            $Target ||= $LineTarget;
            return { Success => 0, Status => 'UNKNOWN', Error => 'A field-assignment script cannot target multiple object classes.' }
                if lc($Target) ne lc($LineTarget);
            $Assignments->{$Field} = $Expression;
        }
    }

    $Target =~ s{\A\s*\@?}{};
    $Target =~ s{\s+\z}{};
    my $Expected = join '.', $Param{ObjectType} || '', $Param{Class} || '';
    return { Success => 0, Status => 'UNKNOWN', Error => "Field-assignment target '$Target' does not match '$Expected'." }
        if lc($Target) ne lc($Expected);

    my %Values;
    for my $Field ( sort keys %{$Assignments} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => "Invalid field-assignment field '$Field'." }
            if $Field !~ m{\A[A-Za-z][A-Za-z0-9_-]*\z};
        my $Expression = $Assignments->{$Field};
        return { Success => 0, Status => 'UNKNOWN', Error => "Field assignment '$Field' must be a scalar expression." }
            if ref $Expression;
        my $Value = defined $Expression && uc($Expression) eq 'THIS'
            ? { Known => 1, Value => $Param{ThisValue} }
            : $Self->ValueEvaluate( Expression => $Expression, Context => $Param{Context} );
        return { Success => 0, Status => 'UNKNOWN', Error => $Value->{Reason} || "Cannot calculate '$Field'." }
            if !$Value->{Known};
        $Values{$Field} = $Value->{Value};
    }

    return {
        Success   => 1,
        Status    => 'RETURNED',
        Value     => \%Values,
        ValueType => "FieldAssignments<$Expected>",
    };
}

sub _PolicyLines {
    my ( $Self, $Source ) = @_;

    $Source =~ s{\r\n?}{\n}g;
    my @Lines;
    for my $Line ( split m{\n}, $Source ) {
        $Line =~ s{\s*\#.*\z}{};
        $Line =~ s{\A\s+|\s+\z}{}g;
        next if $Line eq '';
        next if $Line =~ m{\A(?:APPLIES\s+WHEN|REQUIRE|FILTER|EVALUATE)\s*:?[\s]*\z}i;
        $Line =~ s{\A(?:APPLIES\s+WHEN|REQUIRE)\s+}{}i;
        push @Lines, $Line;
    }
    return @Lines;
}

sub _ConditionEvaluate {
    my ( $Self, %Param ) = @_;

    my $Expression = $Param{Expression};
    my @Operators = (
        [ 'IS NOT EMPTY',      'NOT_EMPTY' ],
        [ 'IS EMPTY',          'EMPTY' ],
        [ 'IS ON OR AFTER',    'GE' ],
        [ 'IS ON OR BEFORE',   'LE' ],
        [ 'IS GREATER THAN',   'GT' ],
        [ 'IS LESS THAN',      'LT' ],
        [ 'IS AT LEAST',       'GE' ],
        [ 'IS AT MOST',        'LE' ],
        [ 'DOES NOT EQUAL',    'NE' ],
        [ 'EQUALS',            'EQ' ],
        [ 'CONTAINS',          'CONTAINS' ],
        [ 'STARTS WITH',       'STARTS' ],
        [ 'ENDS WITH',         'ENDS' ],
    );

    for my $Operator (@Operators) {
        my ( $Words, $Code ) = @{$Operator};
        if ( $Code eq 'EMPTY' || $Code eq 'NOT_EMPTY' ) {
            next if $Expression !~ m{\A(.+?)\s+\Q$Words\E\z}i;
            my $Left = $Self->_Value( Expression => $1, Context => $Param{Context} );
            return _Unknown($Left) if !$Left->{Known};
            my $Empty  = !defined $Left->{Value} || $Left->{Value} eq '';
            my $Result = $Code eq 'EMPTY' ? $Empty : !$Empty;
            return _Boolean($Result);
        }

        next if $Expression !~ m{\A(.+?)\s+\Q$Words\E\s+(.+)\z}i;
        my $Left  = $Self->_Value( Expression => $1, Context => $Param{Context} );
        my $Right = $Self->_Value( Expression => $2, Context => $Param{Context} );
        return _Unknown( !$Left->{Known} ? $Left : $Right ) if !$Left->{Known} || !$Right->{Known};

        my ( $A, $B ) = ( $Left->{Value}, $Right->{Value} );
        my $Numeric = looks_like_number($A) && looks_like_number($B);
        my $Result;
        $Result = $Numeric ? $A == $B : "$A" eq "$B" if $Code eq 'EQ';
        $Result = $Numeric ? $A != $B : "$A" ne "$B" if $Code eq 'NE';
        $Result = $Numeric ? $A >  $B : "$A" gt "$B" if $Code eq 'GT';
        $Result = $Numeric ? $A <  $B : "$A" lt "$B" if $Code eq 'LT';
        $Result = $Numeric ? $A >= $B : "$A" ge "$B" if $Code eq 'GE';
        $Result = $Numeric ? $A <= $B : "$A" le "$B" if $Code eq 'LE';
        $Result = index( lc "$A", lc "$B" ) >= 0 if $Code eq 'CONTAINS';
        $Result = index( lc "$A", lc "$B" ) == 0 if $Code eq 'STARTS';
        $Result = length("$B") <= length("$A") && lc( substr( "$A", -length("$B") ) ) eq lc "$B" if $Code eq 'ENDS';
        return _Boolean($Result);
    }

    return {
        Status => 'UNKNOWN',
        Value  => undef,
        Reason => "Unsupported condition: $Expression.",
    };
}

sub _Value {
    my ( $Self, %Param ) = @_;

    my $Expression = $Param{Expression};
    $Expression =~ s{\A\s+|\s+\z}{}g;

    if ( $Expression =~ m{\A(NUMBER|STRING|DATE|DATETIME)\s*\((.*)\)\z}i ) {
        my $Type  = uc $1;
        my $Inner = $Self->_Value( Expression => $2, Context => $Param{Context} );
        return $Inner if !$Inner->{Known};
        return $Self->_Convert( Type => $Type, Value => $Inner->{Value} );
    }

    if ( $Expression =~ m{\APRODUCT\s+OF\s*\[(.*)\]\z}i ) {
        my @Parts = split m{\s*,\s*}, $1;
        return { Known => 0, Reason => 'PRODUCT OF requires at least one value.' } if !@Parts;
        my $Product = 1;
        for my $Part (@Parts) {
            my $Value = $Self->_Value( Expression => $Part, Context => $Param{Context} );
            return $Value if !$Value->{Known};
            return { Known => 0, Reason => "PRODUCT OF value '$Value->{Value}' is not numeric." }
                if !looks_like_number( $Value->{Value} );
            $Product *= $Value->{Value};
        }
        return { Known => 1, Value => $Product };
    }

    for my $Operator ( '*', '/' ) {
        my $Position = _TopLevelOperator( $Expression, $Operator );
        next if $Position < 0;
        my $Left = $Self->_Value(
            Expression => substr( $Expression, 0, $Position ),
            Context    => $Param{Context},
        );
        my $Right = $Self->_Value(
            Expression => substr( $Expression, $Position + 1 ),
            Context    => $Param{Context},
        );
        return !$Left->{Known} ? $Left : $Right if !$Left->{Known} || !$Right->{Known};
        return { Known => 0, Reason => "Arithmetic requires numeric values." }
            if !looks_like_number( $Left->{Value} ) || !looks_like_number( $Right->{Value} );
        return { Known => 0, Reason => 'Division by zero.' } if $Operator eq '/' && !$Right->{Value};
        return {
            Known => 1,
            Value => $Operator eq '*' ? $Left->{Value} * $Right->{Value} : $Left->{Value} / $Right->{Value},
        };
    }

    if ( $Expression =~ m{\A(\d+)\s+(DAY|DAYS|WEEK|WEEKS|MONTH|MONTHS|YEAR|YEARS)\s+AGO\z}i ) {
        my ( $Amount, $Unit ) = ( $1, lc $2 );
        $Unit =~ s{s\z}{};
        my %DateTimeUnit = ( day => 'Days', week => 'Weeks', month => 'Months', year => 'Years' );
        my $DateTime = $Kernel::OM->Create('Kernel::System::DateTime');
        $DateTime->Subtract( $DateTimeUnit{$Unit} => $Amount );
        return { Known => 1, Value => $DateTime->ToEpoch() };
    }

    if ( uc $Expression eq 'NOW' ) {
        return { Known => 1, Value => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch() };
    }

    if ( $Expression =~ m{\A\@([A-Za-z][A-Za-z0-9]*)(\..+)\z} ) {
        my ( $Root, $Path ) = ( uc $1, $2 );
        my $Object = $Param{Context}->{$Root};
        return { Known => 0, Reason => "Object root \@$Root is unavailable." }
            if ref $Object ne 'HASH';

        my $Value = $Object;
        my @Segments = $Path =~ m{\.([A-Za-z][A-Za-z0-9_-]*)(?:\[(\d+)\])?}g;
        # The regex capture list is flattened into field/index pairs.
        while (@Segments) {
            my $Field = shift @Segments;
            my $Index = shift @Segments;
            return { Known => 0, Reason => "Field path $Expression cannot traverse a non-object value." }
                if ref $Value ne 'HASH';
            my $Key = exists $Value->{$Field} ? $Field : 'DynamicField_' . $Field;
            return { Known => 0, Reason => "Field $Expression is unavailable." }
                if !exists $Value->{$Key};
            $Value = $Value->{$Key};
            if ( defined $Index && $Index ne '' ) {
                return { Known => 0, Reason => "Field $Expression is not a row collection." }
                    if ref $Value ne 'ARRAY';
                return { Known => 0, Reason => "Row $Index in $Expression is unavailable." }
                    if !defined $Value->[$Index];
                $Value = $Value->[$Index];
            }
        }
        $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
        return { Known => 0, Reason => "Field $Expression contains a structured or multiple value." } if ref $Value;
        return { Known => 1, Value => $Value };
    }

    return { Known => 1, Value => $1 } if $Expression =~ m{\A"(.*)"\z}s;
    return { Known => 1, Value => 0 + $Expression } if looks_like_number($Expression);
    return { Known => 1, Value => 1 } if uc $Expression eq 'TRUE';
    return { Known => 1, Value => 0 } if uc $Expression eq 'FALSE';
    return { Known => 1, Value => '' } if uc $Expression eq 'EMPTY';

    return { Known => 0, Reason => "Unsupported value expression: $Expression." };
}

sub _Convert {
    my ( $Self, %Param ) = @_;
    my $Value = $Param{Value};
    return { Known => 0, Reason => "$Param{Type} cannot convert an empty value." }
        if !defined $Value || $Value eq '';

    if ( $Param{Type} eq 'NUMBER' ) {
        return { Known => 0, Reason => "NUMBER cannot convert '$Value'." } if !looks_like_number($Value);
        return { Known => 1, Value => 0 + $Value };
    }
    if ( $Param{Type} eq 'STRING' ) {
        return { Known => 1, Value => "$Value" };
    }

    my $DateTime = eval {
        $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => { String => "$Value" },
        );
    };
    return { Known => 0, Reason => "$Param{Type} cannot convert '$Value'." }
        if !$DateTime;
    return { Known => 1, Value => $DateTime->ToEpoch() };
}

sub _TopLevelOperator {
    my ( $Expression, $Operator ) = @_;
    my ( $Depth, $Quoted ) = ( 0, 0 );
    for my $Index ( 0 .. length($Expression) - 1 ) {
        my $Character = substr( $Expression, $Index, 1 );
        $Quoted = !$Quoted if $Character eq '"';
        next if $Quoted;
        $Depth++ if $Character eq '(' || $Character eq '[';
        $Depth-- if $Character eq ')' || $Character eq ']';
        return $Index if !$Depth && $Character eq $Operator;
    }
    return -1;
}

sub _Boolean {
    my ($Value) = @_;
    return { Status => $Value ? 'SATISFIED' : 'NOT_SATISFIED', Value => $Value ? 1 : 0 };
}

sub _Unknown {
    my ($Value) = @_;
    return { Status => 'UNKNOWN', Value => undef, Reason => $Value->{Reason} || 'Value is unknown.' };
}

sub _ResultNormalize {
    my ($Value) = @_;
    return 'N/A' if uc($Value) eq 'N/A';
    return ucfirst lc $Value;
}

sub _TruthAnd {
    my ( $A, $B ) = @_;
    return 0 if defined $A && !$A;
    return 0 if defined $B && !$B;
    return undef if !defined $A || !defined $B;
    return 1;
}

sub _TruthOr {
    my ( $A, $B ) = @_;
    return 1 if defined $A && $A;
    return 1 if defined $B && $B;
    return undef if !defined $A || !defined $B;
    return 0;
}

1;
