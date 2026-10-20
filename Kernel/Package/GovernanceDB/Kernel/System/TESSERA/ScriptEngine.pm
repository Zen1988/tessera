# --
# Kernel/System/TESSERA/ScriptEngine.pm
# --

package Kernel::System::TESSERA::ScriptEngine;

use strict;
use warnings;

use Scalar::Util qw(looks_like_number refaddr);
use Kernel::System::TESSERA::ReferenceScope;

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
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

# Only plain, bounded data may cross the executable-definition boundary.
# Limits count expanded aliases as well as distinct nodes; recursion fails closed.
sub ScriptDataValidate {
    my ( $Self, $Data ) = @_;
    my ( $Nodes, $Bytes ) = ( 0, 0 );
    my %Active;
    my $Walk;
    $Walk = sub {
        my ( $Value, $Depth ) = @_;
        die "Script structure exceeds limits.\n" if ++$Nodes > 10000 || $Depth > 32;
        if ( !ref $Value ) {
            $Bytes += defined $Value ? length($Value) : 0;
            die "Script data exceeds limits.\n" if $Bytes > 1048576;
            return;
        }
        my $Type = ref $Value;
        die "Script contains a non-data reference.\n" if $Type ne 'HASH' && $Type ne 'ARRAY';
        my $Address = refaddr($Value);
        die "Script contains a recursive alias.\n" if $Active{$Address};
        local $Active{$Address} = 1;
        if ( $Type eq 'HASH' ) {
            for my $Key ( keys %{$Value} ) {
                $Walk->( $Key, $Depth + 1 );
                $Walk->( $Value->{$Key}, $Depth + 1 );
            }
        }
        else { $Walk->( $_, $Depth + 1 ) for @{$Value} }
    };
    my $OK = eval { $Walk->( $Data, 0 ); 1 };
    # Break the closure cycle, including after a validation exception.
    undef $Walk;
    return $OK ? undef : 'Script must contain bounded, acyclic plain data.';
}

sub ScriptSourceLoad {
    my ( $Self, %Param ) = @_;
    my $Source = $Param{Source};
    die "Script source must be a scalar of at most 376200 characters.\n"
        if !defined $Source || ref $Source || length($Source) > 376200;
    no warnings 'once';
    require YAML::XS;
    require Encode;
    # Do not use the generic OTOBO loader: it logs source contents on errors.
    local $YAML::XS::LoadBlessed = 0;
    local $YAML::XS::LoadCode = 0;
    local $YAML::XS::UseCode = 0;
    local $YAML::XS::ForbidDuplicateKeys = 1;
    my @Documents = eval { YAML::XS::Load( Encode::encode('UTF-8', $Source) ) };
    die "Script YAML is invalid.\n" if $@;
    die "Script YAML must contain exactly one document.\n" if @Documents != 1;
    my $Error = $Self->ScriptDataValidate($Documents[0]);
    die "$Error\n" if $Error;
    return $Documents[0];
}

sub PolicyEvaluate {
    my ( $Self, %Param ) = @_;
    my $Error = $Self->ScriptDataValidate($Param{Script});
    return { Success => 0, Status => 'UNKNOWN', Error => $Error } if $Error;
    require Kernel::System::TESSERA::PolicyEvaluation;
    return Kernel::System::TESSERA::PolicyEvaluation->new( Engine => $Self )->Evaluate(%Param);
}

sub ScriptParse {
    my ( $Self, %Param ) = @_;

    my $Script = $Param{Script};
    my $DataError = $Self->ScriptDataValidate($Script);
    return { Success => 0, Status => 'UNKNOWN', Error => $DataError } if $DataError;
    if ( ref $Script ne 'HASH' ) {
        my $Source = defined $Param{Source} ? $Param{Source} : '';
        return { Success => 0, Status => 'UNKNOWN', Error => 'Script source must be a bounded scalar.' }
            if ref $Source || length($Source) > 376200;
        return { Success => 0, Status => 'UNKNOWN', Error => 'TESSERA script source is empty.' }
            if $Source !~ m{\S};

        my $Loaded = eval {
            $Self->ScriptSourceLoad( Source => $Source );
        };
        return {
            Success => 0,
            Status  => 'UNKNOWN',
            Error   => 'TESSERA script is not valid YAML: ' . ( $@ || 'unknown YAML error' ),
        } if ref $Loaded ne 'HASH';
        $Script = $Loaded;
    }

    my %Allowed = map { $_ => 1 } ('SCRIPT', 'VERSION', 'LET THIS', 'SEARCH', 'REQUIRE', 'RETURN');
    return { Success => 0, Status => 'UNKNOWN', Error => 'Unsupported script operation.' }
        if grep { !$Allowed{$_} } keys %{$Script};
    my $Version = defined $Script->{VERSION} ? $Script->{VERSION} : 1;
    return { Success => 0, Status => 'UNKNOWN', Error => "Unsupported TESSERA script version '$Version'." }
        if "$Version" ne '1';

    if ( exists $Script->{'LET THIS'} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => 'LET THIS currently supports only TICKET.' }
            if !defined $Script->{'LET THIS'} || uc( $Script->{'LET THIS'} ) ne 'TICKET';
    }

    my $Searches = $Script->{SEARCH};
    $Searches = [$Searches] if ref $Searches eq 'HASH';
    $Searches ||= [];
    return { Success => 0, Status => 'UNKNOWN', Error => 'SEARCH must be a mapping or list.' }
        if ref $Searches ne 'ARRAY';

    my %Variable;
    for my $Search ( @{$Searches} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => 'Each SEARCH entry must be a mapping.' }
            if ref $Search ne 'HASH';
        return { Success => 0, Status => 'UNKNOWN', Error => 'SEARCH parameters must be scalar.' }
            if grep { ref $Search->{$_} } ('FOR', 'CLASS', 'AS', 'LIMIT');
        return { Success => 0, Status => 'UNKNOWN', Error => 'Unsupported SEARCH object type.' }
            if ($Search->{FOR} || '') !~ /\A(?:Ticket|GovernanceObject|MELTObject|ITSMConfigItem)\z/;
        $Search->{CLASS} ||= $Search->{FOR}
            if ( $Search->{FOR} || '' ) =~ /\ATicket\z/;
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

    # Parsed is a convenience, never a validation/authorization token.
    my $Parsed = $Self->ScriptParse( Source => $Param{Source},
        Script => ref $Param{Parsed} eq 'HASH' ? $Param{Parsed}->{Script} : $Param{Script} );
    return $Parsed if !$Parsed->{Success};
    # A stored selection program cannot read unrelated classes before returning
    # an otherwise valid collection. Enforce caller-owned scope before any read.
    if ( defined $Param{AllowedSearchType} ) {
        for my $Search (@{$Parsed->{Searches}}) {
            return { Success => 0, Status => 'UNKNOWN', Error => 'Selection search exceeds its declared type.' }
                if join('.', $Search->{FOR}, $Search->{CLASS}) ne $Param{AllowedSearchType};
        }
    }

    my $InputContext = ref $Param{Context} eq 'HASH' ? $Param{Context} : {};
    my $Context = { %{$InputContext} };
    if ( exists $Parsed->{Script}->{'LET THIS'} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => 'LET THIS TICKET requires a complete ticket context.' }
            if ref $Context->{TICKET} ne 'HASH';
        $Context->{THIS} = $Context->{TICKET};
        $Context->{'THIS TYPE'} = 'Ticket';
    }
    my %Variables;
    my @Trace;

    for my $Search ( @{ $Parsed->{Searches} } ) {
        my $Result = $Self->_ScriptSearch(
            Search    => $Search,
            Complete  => $Param{Complete},
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
                Limit  => $Search->{LIMIT} + ( $Param{Complete} ? 1 : 0 ),
                UserID => $Param{UserID},
            );
        };
        return { Success => 0, Error => 'SEARCH provider failed: ' . $@ } if $@;
        return { Success => 0, Error => 'SEARCH provider must return an array reference.' }
            if ref $Values ne 'ARRAY';
        return { Success => 0, Error => 'Complete SEARCH exceeded its LIMIT.' }
            if $Param{Complete} && @{$Values} > $Search->{LIMIT};
        return { Success => 1, Value => $Values };
    }

    return $Self->_ScriptNativeSearch(
        For    => $Search->{FOR},
        Class  => $Search->{CLASS},
        Where  => \%ResolvedWhere,
        Limit  => $Search->{LIMIT},
        Complete => $Param{Complete},
        UserID => $Param{UserID},
    );
}

sub _ScriptNativeSearch {
    my ( $Self, %Param ) = @_;

    return $Self->_ScriptFlatSearch(%Param) if $Param{For} =~ /\ATicket\z/;

    my %Search = (
        Result  => 'ARRAY',
        Classes => [ $Param{Class} ],
        Limit   => $Param{Limit} + ( $Param{Complete} ? 1 : 0 ),
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
    elsif ( $Param{For} eq 'MELTObject' ) {
        $Object = eval { $Kernel::OM->Get('Kernel::System::MELTObject') };
        return { Success => 0, Error => 'MELTObject is unavailable.' } if !$Object;
        $GetMethod = 'MELTObjectGet';
        $IDKey = 'MELTObjectID';
    }
    elsif ( $Param{For} eq 'ITSMConfigItem' ) {
        $Object    = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
        $GetMethod = 'ConfigItemGet';
        $IDKey     = 'ConfigItemID';
    }
    else {
        return { Success => 0, Error => "Unsupported SEARCH object type '$Param{For}'." };
    }

    my $SearchMethod = $Param{For} eq 'ITSMConfigItem' ? 'ConfigItemSearch' : $Param{For} . 'Search';
    my @IDs = eval { $Object->$SearchMethod(%Search) };
    return { Success => 0, Error => "SEARCH $Param{For}[$Param{Class}] failed: $@" } if $@;
    return { Success => 0, Error => 'Complete SEARCH exceeded its LIMIT; no targets were reconciled.' }
        if $Param{Complete} && @IDs > $Param{Limit};
    my @Objects;
    for my $ID (@IDs) {
        my $Item = eval { $Object->$GetMethod( $IDKey => $ID, DynamicFields => 1, Silent => 1 ) };
        return { Success => 0, Error => "Complete SEARCH could not read target $ID." }
            if $Param{Complete} && ( $@ || ref $Item ne 'HASH' || !%{$Item} );
        push @Objects, $Item if ref $Item eq 'HASH';
    }
    return { Success => 1, Value => \@Objects };
}

sub _ScriptFlatSearch {
    my ( $Self, %Param ) = @_;
    my $Kind = $Param{For};
    return { Success => 0, Error => "$Kind does not have object classes; omit CLASS." }
        if $Param{Class} ne $Kind;
    my $Object = $Kernel::OM->Get("Kernel::System::$Kind");
    my %Search = ( Result => 'ARRAY', Limit => $Param{Limit} + ( $Param{Complete} ? 1 : 0 ) );
    $Search{UserID} = $Param{UserID} if $Kind eq 'Ticket';
    my %TicketFields = ( Type => 'Types', State => 'States', StateType => 'StateType', Queue => 'Queues', CustomerUserID => 'CustomerUserLogin' );
    for my $Field ( keys %{ $Param{Where} } ) {
        my ($Op) = keys %{ $Param{Where}->{$Field} };
        my $Value = $Param{Where}->{$Field}->{$Op};
        return { Success => 0, Error => "$Kind field $Field supports EQUALS only." } if $Op ne 'EQUALS';
        if ( $Kind eq 'Ticket' && $TicketFields{$Field} ) {
            $Search{ $TicketFields{$Field} } = ref $Value eq 'ARRAY' ? $Value : [$Value];
        }
        else {
            return { Success => 0, Error => "Unsupported $Kind search field $Field." };
        }
    }
    my @IDs = $Object->TicketSearch(%Search);
    return { Success => 0, Error => 'Complete SEARCH exceeded its LIMIT.' }
        if $Param{Complete} && @IDs > $Param{Limit};
    my @Values;
    for my $ID (@IDs) {
        my %Value = $Object->TicketGet( TicketID => $ID, DynamicFields => 1, UserID => $Param{UserID} );
        return { Success => 0, Error => "Cannot read $Kind target $ID." } if !%Value;
        $Value{Class} = $Kind;
        push @Values, \%Value;
    }
    return { Success => 1, Value => \@Values };
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

    if ( exists $Return->{'TICKET FIELD COLLECTION'} ) {
        return $Self->_TicketFieldCollectionResolve(
            Config  => $Return->{'TICKET FIELD COLLECTION'},
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
    if ( $From =~ m{\AALL\s+(.+)\z}i ) {
        my $Values = $Param{Variables}->{$1};
        return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN ALL requires a known collection.' }
            if ref $Values ne 'ARRAY';
        my $Type = $Return->{AS} || '';
        return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN ALL requires Collection<ObjectType.Class>.' }
            if $Type !~ m{\ACollection<(ITSMConfigItem|GovernanceObject|MELTObject|Ticket)(?:\.([A-Za-z][A-Za-z0-9_-]*))?>\z};
        my ( $ObjectType, $Class ) = ( $1, $2 );
        my %IDKeys = ( ITSMConfigItem => 'ConfigItemID', GovernanceObject => 'GovernanceObjectID', MELTObject => 'MELTObjectID', Ticket => 'TicketID' );
        my $IDKey = $IDKeys{$ObjectType};
        return { Success => 0, Status => 'UNKNOWN', Error => 'Class is required for class-based object collections.' }
            if !$Class && $ObjectType !~ /\ATicket\z/;
        for my $Value (@{$Values}) {
            return { Success => 0, Status => 'UNKNOWN', Error => 'RETURN ALL target does not match its declared type.' }
                if ref $Value ne 'HASH' || !$Value->{$IDKey} || ( $Class && ( $Value->{Class} || '' ) ne $Class );
        }
        return { Success => 1, Status => 'RETURNED', Value => $Values, ValueType => $Type };
    }
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

sub _TicketFieldCollectionResolve {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config};
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION must be a mapping.' }
        if ref $Config ne 'HASH';

    my %Allowed = map { $_ => 1 } (
        'TICKET TYPE', 'STATE TYPE', 'PARENT', 'ITERATION', 'FILTER',
        'FIELD', 'DISTINCT', 'IGNORE EMPTY', 'AS',
    );
    for my $Key ( keys %{$Config} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => "TICKET FIELD COLLECTION key '$Key' is unsupported." }
            if !$Allowed{$Key};
    }

    my $TicketType = $Config->{'TICKET TYPE'} || '';
    my $Field      = $Config->{FIELD} || '';
    my $ValueType  = $Config->{AS} || '';
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION requires TICKET TYPE.' }
        if $TicketType eq '';
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION requires FIELD.' }
        if $Field eq '';
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION AS must declare Collection<...>.' }
        if $ValueType !~ m{\ACollection<[^<>]+>\z};

    my $ContextTicket = $Param{Context}->{TICKET};
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION requires ticket context.' }
        if ref $ContextTicket ne 'HASH';

    my $Parent = $Config->{PARENT};
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION PARENT must be a mapping.' }
        if ref $Parent ne 'HASH' || !$Parent->{FIELD} || !exists $Parent->{VALUE};
    my $ParentResult = $Self->_ScriptValueResolve(
        Value   => $Parent->{VALUE},
        Context => $Param{Context},
        AllowMissing => 1,
    );
    return $ParentResult if !$ParentResult->{Success};
    my $ParentValue = $ParentResult->{Value};
    $ParentValue = $ParentValue->[0] if ref $ParentValue eq 'ARRAY' && @{$ParentValue} == 1;
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION cannot resolve parent value.' }
        if !defined $ParentValue || ref $ParentValue || $ParentValue eq '';

    my $Iteration = $Config->{ITERATION};
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION ITERATION must be a mapping.' }
        if ref $Iteration ne 'HASH' || !$Iteration->{FIELD} || !exists $Iteration->{VALUE};
    my %AllowedIteration = map { $_ => 1 } ( 'FIELD', 'VALUE', 'CURRENT FIRST', 'FALLBACK OFFSET', 'UNNUMBERED WHEN EMPTY' );
    for my $Key ( keys %{$Iteration} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => "TICKET FIELD COLLECTION ITERATION key '$Key' is unsupported." }
            if !$AllowedIteration{$Key};
    }
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION requires CURRENT FIRST: true.' }
        if !$Iteration->{'CURRENT FIRST'};
    my $Offset = $Iteration->{'FALLBACK OFFSET'};
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION FALLBACK OFFSET must be -1.' }
        if defined $Offset && "$Offset" ne '-1';

    my $IterationResult = $Self->_ScriptValueResolve(
        Value   => $Iteration->{VALUE},
        Context => $Param{Context},
        AllowMissing => 1,
    );
    return $IterationResult if !$IterationResult->{Success};
    my $IterationValue = $IterationResult->{Value};
    $IterationValue = $IterationValue->[0] if ref $IterationValue eq 'ARRAY' && @{$IterationValue} == 1;
    return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION iteration value is structured.' }
        if ref $IterationValue;

    my @Iterations;
    if ( defined $IterationValue && $IterationValue ne '' ) {
        push @Iterations, $IterationValue;
        push @Iterations, $IterationValue - 1
            if defined $Offset && $IterationValue =~ m{\A\d+\z} && $IterationValue > 1;
    }
    elsif ( $Iteration->{'UNNUMBERED WHEN EMPTY'} ) {
        push @Iterations, '';
    }
    else {
        return { Success => 1, Status => 'RETURNED', Value => [], ValueType => $ValueType };
    }

    my $Filter = $Config->{FILTER};
    if ( defined $Filter ) {
        return { Success => 0, Status => 'UNKNOWN', Error => 'TICKET FIELD COLLECTION FILTER must be a mapping with FIELD and IN.' }
            if ref $Filter ne 'HASH' || !$Filter->{FIELD} || ref $Filter->{IN} ne 'ARRAY' || !@{ $Filter->{IN} };
        for my $Key ( keys %{$Filter} ) {
            return { Success => 0, Status => 'UNKNOWN', Error => "TICKET FIELD COLLECTION FILTER key '$Key' is unsupported." }
                if $Key ne 'FIELD' && $Key ne 'IN';
        }
    }

    ITERATION:
    for my $CandidateIteration (@Iterations) {
        my @Tickets;
        if ( ref $Self->{TicketProvider} eq 'CODE' ) {
            my $Provided = eval {
                $Self->{TicketProvider}->(
                    TicketType      => $TicketType,
                    StateType       => $Config->{'STATE TYPE'},
                    ParentField     => $Parent->{FIELD},
                    ParentTicketID  => $ParentValue,
                    IterationField  => $Iteration->{FIELD},
                    Iteration       => $CandidateIteration,
                    CurrentTicketID => $ContextTicket->{TicketID},
                    UserID          => $Param{UserID} || 1,
                );
            };
            return { Success => 0, Status => 'UNKNOWN', Error => "Ticket field collection provider failed: $@" } if $@;
            return { Success => 0, Status => 'UNKNOWN', Error => 'Ticket field collection provider must return an array reference.' }
                if ref $Provided ne 'ARRAY';
            @Tickets = @{$Provided};
        }
        else {
            my %Search = (
                Result => 'ARRAY',
                Types  => [$TicketType],
                "DynamicField_$Parent->{FIELD}" => { Equals => $ParentValue },
                UserID => $Param{UserID} || 1,
            );
            my $StateType = $Config->{'STATE TYPE'};
            $Search{StateType} = ref $StateType eq 'ARRAY' ? $StateType : [$StateType]
                if defined $StateType && ( ref $StateType eq 'ARRAY' || $StateType ne '' );
            $Search{"DynamicField_$Iteration->{FIELD}"} = { Equals => $CandidateIteration }
                if defined $CandidateIteration && $CandidateIteration ne '';
            my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
            my @IDs = sort { $a <=> $b } eval { $TicketObject->TicketSearch(%Search) };
            return { Success => 0, Status => 'UNKNOWN', Error => "Ticket field collection search failed: $@" } if $@;
            for my $ID (@IDs) {
                my %Ticket = $TicketObject->TicketGet(
                    TicketID => $ID, DynamicFields => 1, UserID => $Param{UserID} || 1, Silent => 1,
                );
                push @Tickets, \%Ticket if %Ticket;
            }
        }

        @Tickets = grep {
            ref $_ eq 'HASH'
                && !( $ContextTicket->{TicketID} && ( $_->{TicketID} || 0 ) == $ContextTicket->{TicketID} )
                && (
                    $CandidateIteration ne ''
                    || !defined $_->{"DynamicField_$Iteration->{FIELD}"}
                    || $_->{"DynamicField_$Iteration->{FIELD}"} eq ''
                )
        } @Tickets;
        next ITERATION if !@Tickets;

        my %AllowedFilter;
        %AllowedFilter = map { lc( _NormalizeCollectionScalar($_) ) => 1 } @{ $Filter->{IN} }
            if $Filter;
        my @Values;
        my %Seen;
        TICKET:
        for my $Ticket (@Tickets) {
            if ($Filter) {
                my $Raw = $Ticket->{ $Filter->{FIELD} };
                $Raw = $Ticket->{ 'DynamicField_' . $Filter->{FIELD} } if !defined $Raw;
                my $Display = $Self->_TicketDynamicFieldDisplayValue(
                    Field => $Filter->{FIELD}, Value => $Raw,
                );
                next TICKET if !$AllowedFilter{ lc( _NormalizeCollectionScalar($Display) ) };
            }
            my $Value = $Ticket->{$Field};
            $Value = $Ticket->{'DynamicField_' . $Field} if !defined $Value;
            my @Projected = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
            for my $Item (@Projected) {
                $Item = _NormalizeCollectionScalar($Item);
                next if $Config->{'IGNORE EMPTY'} && $Item eq '';
                next if $Config->{DISTINCT} && $Seen{$Item}++;
                push @Values, $Item;
            }
        }
        return { Success => 1, Status => 'RETURNED', Value => \@Values, ValueType => $ValueType, Iteration => $CandidateIteration };
    }

    return { Success => 1, Status => 'RETURNED', Value => [], ValueType => $ValueType };
}

sub _NormalizeCollectionScalar {
    my ($Value) = @_;
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    return '' if !defined $Value || ref $Value;
    $Value =~ s{\A\s+|\s+\z}{}g;
    return $Value;
}

sub _TicketDynamicFieldDisplayValue {
    my ( $Self, %Param ) = @_;
    my $Value = _NormalizeCollectionScalar( $Param{Value} );
    return $Value if $Value eq '' || !$Param{Field};
    my $Config = eval { $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Param{Field} ) };
    return $Value if ref $Config ne 'HASH' || !$Config->{ID};
    my $Display = eval {
        $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueLookup(
            DynamicFieldConfig => $Config,
            Key                => $Value,
        );
    };
    return _NormalizeCollectionScalar($Display) || $Value;
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
    return { Success => 1, Value => $Param{Context}->{THIS} }
        if uc($Value) eq 'THIS';
    if ( $Value =~ m{\A\@?(TICKET|THIS)(?:\.|\z)}i ) {
        my $Root = uc($1);
        my @Path = split m{\.(?![^\[]*\])}, $Value;
        shift @Path;
        my $Resolved = $Param{Context}->{$Root};
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
    return { Success => 0, Status => 'UNKNOWN', Error => 'Program source must be a bounded scalar.' }
        if ref $Source || length($Source) > 376200;
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
    return { Status => 'UNKNOWN', Reason => 'Policy source must be a bounded scalar.', Trace => [] }
        if ref $Source || length($Source) > 376200;
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

sub ConditionEvaluate {
    my ( $Self, %Param ) = @_;
    return $Self->_ConditionEvaluate(
        Expression => $Param{Expression},
        Context => ref $Param{Context} eq 'HASH' ? $Param{Context} : {},
    );
}

sub GroupedFieldAssignmentsEvaluate {
    my ( $Self, %Param ) = @_;
    my $Rule = $Param{Rule};
    my $DataError = $Self->ScriptDataValidate($Rule);
    die qq{$DataError\n} if $DataError;
    die "GROUP FINDINGS must be a mapping.\n" if ref $Rule ne 'HASH';
    my ( $Kind, $Class ) = _GroupedClass( $Param{Destination} );
    die "Risk destination does not match ControlObjective.ZRM-RiskClass.\n"
        if ( $Param{Destination} || '' ) ne ( $Param{RiskClass} || '' );
    my $GroupRule = $Rule->{'GROUP BY'};
    my $EachRule = $Rule->{'FOR EACH'};
    my $IdentityRule = $Rule->{IDENTITY};
    my $Assignments = $Rule->{'FIELD ASSIGNMENTS'};
    my $Merge = $Rule->{MERGE} || {};
    my $SeverityRule = $Rule->{SEVERITY};
    my $Lifecycle = $Rule->{LIFECYCLE} || { 'CREATE STATUS' => 'Active', 'REUSE STATUS' => 'Active' };
    die "Grouped assignment needs GROUP BY, IDENTITY and FIELD ASSIGNMENTS mappings.\n"
        if grep { ref $_ ne 'HASH' } ( $GroupRule, $IdentityRule, $Assignments, $Merge );
    die "FOR EACH and SEVERITY must be mappings when supplied.\n"
        if ( defined $EachRule && ref $EachRule ne 'HASH' )
        || ( defined $SeverityRule && ref $SeverityRule ne 'HASH' );
    die "LIFECYCLE must be a mapping with create and reuse statuses.\n"
        if ref $Lifecycle ne 'HASH' || !$Lifecycle->{'CREATE STATUS'} || !$Lifecycle->{'REUSE STATUS'};
    if ( $Lifecycle->{'EVENT FIELD'} ) {
        my $Field = $Lifecycle->{'EVENT FIELD'};
        my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Field );
        die "Lifecycle event field is invalid.\n"
            if $Field !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/ || !$Config
            || ( $Config->{ObjectType} || '' ) ne $Kind
            || !$Lifecycle->{'CREATE EVENT VALUE'} || !$Lifecycle->{'CLOSED EVENT VALUE'};
    }
    die "REUSE BY must be NAME or IDENTITY.\n" if ($Rule->{'REUSE BY'} || 'NAME') !~ /\A(?:NAME|IDENTITY)\z/;
    my $IdentityField = $IdentityRule->{FIELD} || '';
    die "Grouped identity must name an assigned field.\n"
        if $IdentityField !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/ || !exists $Assignments->{$IdentityField};
    die "Severity field must be assigned with MAX_PRIORITY merge.\n"
        if $SeverityRule && ( !$SeverityRule->{FIELD}
        || !exists $Assignments->{ $SeverityRule->{FIELD} }
        || ( $Merge->{ $SeverityRule->{FIELD} } || '' ) ne 'MAX_PRIORITY' );
    die "Severity rules require a time zone.\n" if $SeverityRule && !$Rule->{'TIME ZONE'};

    my %Base = (
        SOURCE => $Param{Source},
        CONTROL => $Param{Control},
        CONTROLOBJECTIVE => $Param{Objective},
        SCENARIO => { Value => $Rule->{SCENARIO} },
        EVALUATION => { Now => $Param{Now}, TimeZone => $Rule->{'TIME ZONE'} },
    );
    my $GO = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %Groups;
    my $PartitionRule = $GroupRule->{'PARTITION BY'};
    die "PARTITION BY must be a mapping.\n"
        if exists $GroupRule->{'PARTITION BY'} && ref $PartitionRule ne 'HASH';
    my $Scope = Kernel::System::TESSERA::ReferenceScope->new();
    my $MembersAs = $GroupRule->{'MEMBERS AS'};
    die "GROUP BY MEMBERS AS requires a valid alias when collecting members.\n"
        if ( $GroupRule->{'MEMBER FROM'} || $GroupRule->{'INCLUDE MEMBERS'} )
        && ( !$MembersAs || $MembersAs !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/ );
    for my $Finding ( @{ $Param{Evaluation}{Findings} || [] } ) {
        my %Context = ( %Base, FINDING => $Finding );
        my $Origin = _GroupedPath( \%Context, $GroupRule->{FROM} );
        my $GroupValue = _GroupedField( $Origin, $GroupRule->{FIELD} );
        my @GroupIDs = ref $GroupValue eq 'ARRAY' ? @{$GroupValue} : ($GroupValue);
        die "Finding group reference is missing or ambiguous.\n"
            if !@GroupIDs || grep { !defined $_ || ref $_ || $_ !~ /\A\d+\z/ || !$_ } @GroupIDs;
        my %SeenGroup;
        @GroupIDs = grep { !$SeenGroup{$_}++ } @GroupIDs;
        my $MemberID;
        if ( $GroupRule->{'MEMBER FROM'} ) {
            $MemberID = _GroupedPath( \%Context, $GroupRule->{'MEMBER FROM'} );
            die "Finding member ID is missing or ambiguous.\n"
                if !defined $MemberID || ref $MemberID || $MemberID !~ /\A\d+\z/ || !$MemberID;
        }
        for my $GroupID (@GroupIDs) {
            my $Application = _GroupedResolve($GO,$GroupID,$GroupRule->{AS},$Param{UserID});
            my $Partitions = $PartitionRule ? $Scope->Partition(Rule=>$PartitionRule,
                Context=>{%Context,APPLICATION=>$Application},UserID=>$Param{UserID}) : [{ID=>0,EntitlementIDs=>[]}];
            for my $Partition (@$Partitions) {
                my $Key=$PartitionRule ? "$GroupID:$Partition->{ID}" : $GroupID;
                $Groups{$Key}{GroupID}=$GroupID;
                $Groups{$Key}{Partition}=$Partition if $PartitionRule;
                $Groups{$Key}{Fallback} ||= $Partition->{Fallback} || 0;
                $Groups{$Key}{MemberIDs}{$MemberID}=1 if $MemberID;
                $Groups{$Key}{MemberIDs}{$_}=1 for @{$Partition->{EntitlementIDs}};
                $Groups{$Key}{EntitlementIDs}{$_}=1 for @{$Partition->{EntitlementIDs}};
                die "Finding partition limit exceeded.\n" if keys(%Groups)>10000;
                push @{$Groups{$Key}{Findings}},$Finding;
            }
        }
    }
    if ( $GroupRule->{'INCLUDE MEMBERS'} ) {
        die "GROUP BY INCLUDE MEMBERS must be a list of paths.\n"
            if ref $GroupRule->{'INCLUDE MEMBERS'} ne 'ARRAY';
        for my $Path ( @{ $GroupRule->{'INCLUDE MEMBERS'} } ) {
            my $ID = _GroupedPath( \%Base, $Path );
            die "GROUP BY included member ID is invalid.\n"
                if !defined $ID || ref $ID || $ID !~ /\A\d+\z/ || !$ID;
            $Groups{$_}{MemberIDs}{$ID} = 1 for keys %Groups;
        }
    }
    for my $GroupID ( keys %Groups ) {
        my $Group = _GroupedResolve( $GO, $Groups{$GroupID}{GroupID}, $GroupRule->{AS}, $Param{UserID} );
        my %GroupObject = %{$Group};
        if ($MembersAs) {
            die "GROUP BY member alias conflicts with an object field.\n"
                if exists $GroupObject{$MembersAs} || exists $GroupObject{"DynamicField_$MembersAs"};
            $GroupObject{$MembersAs} = [ sort { $a <=> $b } keys %{ $Groups{$GroupID}{MemberIDs} || {} } ];
        }
        if ($PartitionRule) {
            my $Alias=$PartitionRule->{'MEMBERS AS'};
            die "Partition member alias conflicts with an object field.\n" if exists $GroupObject{$Alias} || exists $GroupObject{"DynamicField_$Alias"};
            $GroupObject{$Alias}=[sort {$a<=>$b} keys %{$Groups{$GroupID}{EntitlementIDs}||{}}];
        }
        $Groups{$GroupID}{Object} = \%GroupObject;
    }

    my @ItemIDs = (0);
    my %Items = ( 0 => {} );
    if ($EachRule) {
        my $ItemValues = _GroupedPath( \%Base, $EachRule->{FROM} );
        @ItemIDs = ref $ItemValues eq 'ARRAY' ? @{$ItemValues} : ($ItemValues);
        die "FOR EACH source is empty.\n" if !@ItemIDs;
        die "FOR EACH source contains an invalid object ID.\n"
            if grep { !defined $_ || ref $_ || $_ !~ /^\d+$/ || !$_ } @ItemIDs;
        my %Seen;
        @ItemIDs = grep { !$Seen{$_}++ } @ItemIDs;
        %Items = map { $_ => _GroupedResolve( $GO, $_, $EachRule->{AS}, $Param{UserID} ) } @ItemIDs;
    }

    my ( $Severity, $Priority, $PriorityByName );
    ( $Severity, $Priority, $PriorityByName ) = $Self->_GroupedSeverity(
        Rule => $SeverityRule, Context => \%Base, UserID => $Param{UserID} ) if $SeverityRule;
    my @Planned;
    for my $GroupID ( sort keys %Groups ) {
        for my $ItemID ( sort { $a <=> $b } @ItemIDs ) {
            my %Context = ( %Base, GROUP => $Groups{$GroupID}{Object}, ITEM => $Items{$ItemID},
                SEVERITY => $Severity );
            if ($PartitionRule) {
                my $Alias=$PartitionRule->{RESOLVE}{ALIAS};
                die "Partition alias conflicts with context.\n" if exists $Context{$Alias};
                $Context{$Alias}=$Groups{$GroupID}{Partition}{Object};
            }
            for my $Alias ( sort keys %{ $Rule->{RESOLVE} || {} } ) {
                die "Invalid resolver alias.\n" if $Alias !~ /\A[A-Z][A-Z0-9_]*\z/ || exists $Context{$Alias};
                my $Resolver = $Rule->{RESOLVE}{$Alias};
                die "Resolver must be a mapping.\n" if ref $Resolver ne 'HASH';
                my $ID = _GroupedPath( \%Context, $Resolver->{FROM} );
                $Context{$Alias} = _GroupedResolve( $GO, $ID, $Resolver->{AS}, $Param{UserID} );
            }
            my $Identity = _GroupedTemplate( $IdentityRule->{TEMPLATE}, \%Context );
            die "Grouped identity is empty.\n" if !$Identity;
            $Context{IDENTITY} = { Value => $Identity };
            my $Name = _GroupedTemplate( $Rule->{NAME}, \%Context );
            die "Grouped Risk name is empty.\n" if !$Name;
            my %Values;
            for my $Field ( sort keys %{$Assignments} ) {
                die "Invalid assignment field.\n" if $Field !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
                my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Field );
                die "Assignment field $Field does not belong to $Kind.\n"
                    if !$Config || ( $Config->{ObjectType} || '' ) ne $Kind;
                my $Expression = $Assignments->{$Field};
                die "Assignment expression must be a scalar path.\n"
                    if ref $Expression || $Expression !~ /\A\@[A-Z][A-Z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_-]*)+\z/;
                $Values{$Field} = _GroupedPath( \%Context, substr( $Expression, 1 ) );
            }
            die "Identity field does not match its template.\n"
                if !defined $Values{$IdentityField} || ref $Values{$IdentityField}
                || "$Values{$IdentityField}" ne $Identity;
            push @Planned, { GroupID => $Groups{$GroupID}{GroupID}, ItemID => $ItemID,
                ($PartitionRule ? (SupportProfileID=>$Groups{$GroupID}{Partition}{ID},
                    SupportProfileName=>$Groups{$GroupID}{Partition}{Object}{Name},
                    EntitlementIDs=>$Groups{$GroupID}{Object}{$PartitionRule->{'MEMBERS AS'}},
                    AssignmentFallback=>$Groups{$GroupID}{Fallback}||0) : ()),
                Identity => $Identity, Name => $Name, Values => \%Values,
                Findings => $Groups{$GroupID}{Findings} };
            die "Grouped Risk plan limit exceeded.\n" if @Planned>10000;
        }
    }

    return {
        Class => [ $Kind, $Class ], IdentityField => $IdentityField,
        Plans => \@Planned, Merge => $Merge, SeverityRule => $SeverityRule,
        Priority => $Priority, PriorityByName => $PriorityByName,
        Lifecycle => $Lifecycle,
        ReuseBy => $Rule->{'REUSE BY'} || 'NAME',
    };
}

sub _GroupedSeverity {
    my ( $Self, %Param ) = @_;
    my $Rule = $Param{Rule};
    die "Severity requires AS, FIELD and ordered RULES.\n"
        if !$Rule->{AS} || !$Rule->{FIELD} || ref $Rule->{RULES} ne 'ARRAY' || !@{ $Rule->{RULES} };
    my %Priorities;
    my ( $Chosen, $Priority );
    for my $Band ( @{ $Rule->{RULES} } ) {
        die "Severity rule needs WHEN, NAME and positive PRIORITY.\n"
            if ref $Band ne 'HASH' || !$Band->{WHEN} || !$Band->{NAME}
            || !defined $Band->{PRIORITY} || $Band->{PRIORITY} !~ /\A\d+\z/ || !$Band->{PRIORITY};
        die "Severity name has conflicting priorities.\n"
            if exists $Priorities{ $Band->{NAME} } && $Priorities{ $Band->{NAME} } != $Band->{PRIORITY};
        $Priorities{ $Band->{NAME} } = $Band->{PRIORITY};
        next if $Chosen;
        my $Match = $Self->ConditionEvaluate( Expression => $Band->{WHEN}, Context => $Param{Context} );
        die "Severity condition is unknown: $Match->{Reason}\n" if $Match->{Status} eq 'UNKNOWN';
        if ( !$Chosen && $Match->{Value} ) { $Chosen = $Band->{NAME}; $Priority = $Band->{PRIORITY} }
    }
    die "No severity rule matched.\n" if !$Chosen;
    my $GO = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my ( $Kind, $Class ) = _GroupedClass( $Rule->{AS} );
    die "Severity must resolve a GovernanceObject.\n" if $Kind ne 'GovernanceObject';
    my @IDs = $GO->GovernanceObjectSearch( Result => 'ARRAY', Classes => [$Class],
        Name => $Chosen, Limit => 10000, UserID => $Param{UserID} );
    my @Exact;
    for my $ID (@IDs) {
        my $Item = $GO->GovernanceObjectGet( GovernanceObjectID => $ID, UserID => $Param{UserID} );
        push @Exact, $Item if ref $Item eq 'HASH' && $Item->{Class} eq $Class
            && ( $Item->{Name} || '' ) eq $Chosen && ( $Item->{ZTSMStatus} || '' ) eq 'Active';
    }
    die "Severity '$Chosen' is missing or ambiguous.\n" if @Exact != 1;
    return ( $Exact[0], $Priority, \%Priorities );
}

sub GroupedReferenceResolve {
    my ( $Self, %Param ) = @_;
    return _GroupedResolve(
        $Kernel::OM->Get('Kernel::System::GovernanceObject'),
        $Param{ID}, $Param{AS}, $Param{UserID},
    );
}

sub _GroupedResolve {
    my ( $GO, $ID, $Specification, $UserID ) = @_;
    my ( $Kind, $Class ) = _GroupedClass( $Specification );
    die "Grouped reference must target GovernanceObject.\n" if $Kind ne 'GovernanceObject';
    $ID = $ID->[0] if ref $ID eq 'ARRAY' && @{$ID} == 1;
    die "Grouped reference is missing or ambiguous.\n" if !defined $ID || ref $ID || $ID !~ /\A\d+\z/ || !$ID;
    my $Object = $GO->GovernanceObjectGet( GovernanceObjectID => $ID, DynamicFields => 1, UserID => $UserID );
    die "Grouped reference does not match $Specification.\n"
        if ref $Object ne 'HASH' || ( $Object->{Class} || '' ) ne $Class;
    return $Object;
}

sub _GroupedClass {
    my ($Specification) = @_;
    die "Invalid object class '$Specification'.\n"
        if !$Specification || $Specification !~ /\A(MELTObject|GovernanceObject)\.([A-Za-z][A-Za-z0-9_-]*)\z/;
    return ( $1, $2 );
}

sub _GroupedPath {
    my ( $Context, $Path ) = @_;
    die "Invalid assignment path.\n" if !$Path || $Path !~ /\A[A-Z][A-Z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_-]*)+\z/;
    my ( $Root, @Parts ) = split /\./, $Path;
    my $Value = $Context->{$Root};
    for my $Part (@Parts) {
        die "Assignment path '$Path' cannot be resolved.\n" if ref $Value ne 'HASH';
        $Value = _GroupedField( $Value, $Part );
        die "Assignment path '$Path' is missing.\n" if !defined $Value;
    }
    return $Value;
}

sub _GroupedField {
    my ( $Object, $Field ) = @_;
    die "Invalid source field.\n" if ref $Object ne 'HASH' || !$Field || $Field !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
    return $Object->{$Field} if exists $Object->{$Field};
    return $Object->{"DynamicField_$Field"};
}

sub _GroupedTemplate {
    my ( $Template, $Context ) = @_;
    die "Invalid assignment template.\n" if !defined $Template || ref $Template;
    $Template =~ s/\{([A-Z][A-Z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_-]*)+)\}/_GroupedTemplateValue($Context,$1)/ge;
    die "Unresolved assignment template.\n" if $Template =~ /[{}]/;
    return $Template;
}

sub _GroupedTemplateValue {
    my ( $Context, $Path ) = @_;
    my $Value = _GroupedPath( $Context, $Path );
    die "Template path '$Path' must be a scalar.\n" if ref $Value;
    return $Value;
}

sub FieldAssignmentsEvaluate {
    my ( $Self, %Param ) = @_;

    my $Source = defined $Param{Source} ? $Param{Source} : '';
    return { Success => 0, Status => 'UNKNOWN', Error => 'Field-assignment script is empty.' }
        if $Source !~ m{\S} && ref $Param{Script} ne 'HASH';

    return { Success => 0, Status => 'UNKNOWN', Error => 'Script source must be a bounded scalar.' }
        if ref $Source || length($Source) > 376200;
    my $DataError = $Self->ScriptDataValidate($Param{Script});
    return { Success => 0, Status => 'UNKNOWN', Error => $DataError } if $DataError;
    my ( $Target, $Assignments );
    my $Loaded = $Param{Script};
    $Loaded = eval { $Self->ScriptSourceLoad( Source => $Source ) }
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
    my %AssignmentContext = %{ $Param{Context} || {} };
    if (ref $Loaded eq 'HASH' && exists $Loaded->{RETURN}{'RESOLVE REFERENCES'}) {
        my $Resolvers=$Loaded->{RETURN}{'RESOLVE REFERENCES'};
        my $OK=eval {
            die "RESOLVE REFERENCES must be a mapping.\n" if ref $Resolvers ne 'HASH';
            my $Scope=Kernel::System::TESSERA::ReferenceScope->new();
            for my $Alias (sort keys %$Resolvers) {
                die "Invalid reference alias.\n" if $Alias !~ /\A[A-Z][A-Z0-9_]*\z/ || exists $AssignmentContext{$Alias};
                $AssignmentContext{$Alias}=$Scope->Resolve(Rule=>$Resolvers->{$Alias},Context=>\%AssignmentContext,UserID=>$Param{UserID}||1);
            }
            1;
        };
        return {Success=>0,Status=>'UNKNOWN',Error=>$@||'Reference resolution failed.'} if !$OK;
    }
    for my $Field ( sort keys %{$Assignments} ) {
        return { Success => 0, Status => 'UNKNOWN', Error => "Invalid field-assignment field '$Field'." }
            if $Field !~ m{\A[A-Za-z][A-Za-z0-9_-]*\z};
        my $Expression = $Assignments->{$Field};
        return { Success => 0, Status => 'UNKNOWN', Error => "Field assignment '$Field' must be a scalar expression." }
            if ref $Expression;
        my $Value = defined $Expression && uc($Expression) eq 'THIS'
            ? { Known => 1, Value => $Param{ThisValue} }
            : $Self->ValueEvaluate( Expression => $Expression, Context => \%AssignmentContext );
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
    return { Known => 0, Reason => 'Expression exceeds limits.' }
        if !defined $Expression || ref $Expression || length($Expression) > 376200
            || ($Self->{ValueDepth} || 0) >= 32;
    local $Self->{ValueDepth} = ($Self->{ValueDepth} || 0) + 1;
    $Expression =~ s{\A\s+|\s+\z}{}g;

    if ( $Expression =~ m{\A(NUMBER|STRING|DATE|DATETIME)\s*\((.*)\)\z}i ) {
        my $Type  = uc $1;
        my $Inner = $Self->_Value( Expression => $2, Context => $Param{Context} );
        return $Inner if !$Inner->{Known};
        return $Self->_Convert( Type => $Type, Value => $Inner->{Value}, Context => $Param{Context} );
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

    if ( $Expression =~ m{\ATODAY(?:\s*\+\s*(\d+)\s+(DAY|MONTH|YEAR)S?)?\z}i ) {
        my ( $Amount, $Unit ) = ( $1 || 0, lc( $2 || 'day' ) . 's' );
        require DateTime;
        my $Evaluation = $Param{Context}->{EVALUATION};
        return { Known => 0, Reason => 'TODAY requires a pinned evaluation clock and timezone.' }
            if ref $Evaluation ne 'HASH' || !defined $Evaluation->{Now} || !$Evaluation->{TimeZone};
        my $Date = eval {
            DateTime->from_epoch( epoch => $Evaluation->{Now}, time_zone => $Evaluation->{TimeZone} )
                ->truncate( to => 'day' )->add( $Unit => $Amount, end_of_month => 'limit' )->ymd;
        };
        return { Known => 0, Reason => "Invalid calendar expression: $@" } if $@;
        return { Known => 1, Value => $Date };
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
        while ( length $Path ) {
            return { Known => 0, Reason => "Invalid field path $Expression." }
                if $Path !~ s{\A\.([A-Za-z][A-Za-z0-9_-]*)}{};
            my $Field = $1;
            return { Known => 0, Reason => "Field path $Expression cannot traverse a non-object value." }
                if ref $Value ne 'HASH';
            my $Key = exists $Value->{$Field} ? $Field : 'DynamicField_' . $Field;
            return { Known => 0, Reason => "Field $Expression is unavailable." }
                if !exists $Value->{$Key};
            $Value = $Value->{$Key};
            if ( $Path =~ s{\A\[([A-Za-z][A-Za-z0-9_-]*)\]}{} ) {
                my $Class = $1;
                $Value = [$Value] if defined $Value && !ref $Value;
                return { Known => 0, Reason => "Field $Expression is not a reference collection." }
                    if ref $Value ne 'ARRAY';
                my @Matching;
                for my $ID ( @{$Value} ) {
                    return { Known => 0, Reason => "Field $Expression contains an invalid Governance Object reference." }
                        if !defined $ID || ref $ID || $ID !~ m{\A\d+\z};
                    my $Reference = eval {
                        $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
                            GovernanceObjectID => $ID, DynamicFields => 1, Silent => 1,
                        );
                    };
                    return { Known => 0, Reason => "Field $Expression contains an unresolved Governance Object reference." }
                        if $@ || ref $Reference ne 'HASH' || !%{$Reference};
                    push @Matching, $ID if ( $Reference->{Class} || '' ) eq $Class;
                }
                $Value = \@Matching;
            }
            if ( $Path =~ s{\A\[(\d+)\]}{} ) {
                my $Index = $1;
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

    if ( $Param{Type} eq 'DATE' && ref $Param{Context}->{EVALUATION} eq 'HASH' ) {
        return { Known => 0, Reason => "DATE requires an ISO date, got '$Value'." }
            if $Value !~ m{\A(\d{4})-(\d{2})-(\d{2})(?: 00:00:00)?\z};
        my ( $Year, $Month, $Day ) = ( $1, $2, $3 );
        require DateTime;
        my $Epoch = eval { DateTime->new( year => $Year, month => $Month, day => $Day,
            time_zone => $Param{Context}->{EVALUATION}->{TimeZone} )->epoch };
        return { Known => 0, Reason => "DATE cannot convert '$Value'." } if $@;
        return { Known => 1, Value => $Epoch };
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
