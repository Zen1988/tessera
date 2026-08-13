# --
# Kernel/System/TESSERA/PolicyEngine.pm
# --

package Kernel::System::TESSERA::PolicyEngine;

use strict;
use warnings;

use Scalar::Util qw(looks_like_number);

our @ObjectDependencies = (
    'Kernel::System::DateTime',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
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

    if ( $Expression =~ m{\A\@([A-Za-z][A-Za-z0-9]*)(?:\.([A-Za-z][A-Za-z0-9_-]*))\z} ) {
        my ( $Root, $Field ) = ( uc $1, $2 );
        my $Object = $Param{Context}->{$Root};
        return { Known => 0, Reason => "Object root \@$Root is unavailable." }
            if ref $Object ne 'HASH';
        my $Key = exists $Object->{$Field} ? $Field : 'DynamicField_' . $Field;
        return { Known => 0, Reason => "Field \@$Root.$Field is unavailable." }
            if !exists $Object->{$Key};
        my $Value = $Object->{$Key};
        $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
        return { Known => 0, Reason => "Field \@$Root.$Field contains multiple values." } if ref $Value;
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
