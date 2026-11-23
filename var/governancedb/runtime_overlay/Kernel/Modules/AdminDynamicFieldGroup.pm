# --
# OTOBO is a web-based ticketing system for service organisations.
# --

package Kernel::Modules::AdminDynamicFieldGroup;

use strict;
use warnings;

use parent qw(Kernel::Modules::AdminDynamicFieldSet);

use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

sub _CheckInclude {
    my ( $Self, %Param ) = @_;

    my $CheckResult = $Self->SUPER::_CheckInclude(%Param);

    return $CheckResult if !IsHashRefWithData($CheckResult);
    return $CheckResult if IsHashRefWithData( $CheckResult->{Errors} );

    my $DynamicFieldObject = $Param{DynamicFieldObject};

    FIELD:
    for my $FieldName ( $Self->_IncludeFieldNamesGet( IncludeFrontend => $Param{IncludeFrontend} ) ) {
        my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
            Name => $FieldName,
        );

        next FIELD if !IsHashRefWithData($DynamicField);

        if ( $DynamicField->{Config}->{MultiValue} ) {
            return {
                Include => [],
                Errors  => {
                    IncludeServerError        => 'ServerError',
                    IncludeServerErrorMessage => sprintf(
                        Translatable('The multi-value dynamic field "%s" can not be used inside a Dynamic Field Group.'),
                        $FieldName,
                    ),
                },
            };
        }

        next FIELD if ( $DynamicField->{FieldType} || '' ) ne 'Set'
            && ( $DynamicField->{FieldType} || '' ) ne 'DynamicFieldGroup';

        return {
            Include => [],
            Errors  => {
                IncludeServerError        => 'ServerError',
                IncludeServerErrorMessage => sprintf(
                    Translatable('The dynamic field "%s" can not be used inside a Dynamic Field Group. Use groups inside Sets only.'),
                    $FieldName,
                ),
            },
        };
    }

    return $CheckResult;
}

sub _IncludeFieldNamesGet {
    my ( $Self, %Param ) = @_;

    my @FieldNames;

    LINE:
    for my $Line ( @{ $Param{IncludeFrontend} || [] } ) {
        if ( IsHashRefWithData( $Line->{Grid} ) && IsArrayRefWithData( $Line->{Grid}->{Rows} ) ) {
            ROW:
            for my $Row ( $Line->{Grid}->{Rows}->@* ) {
                next ROW if ref $Row ne 'ARRAY';

                push @FieldNames, map { $_->{DF} } grep { IsHashRefWithData($_) && $_->{DF} } $Row->@*;
            }

            next LINE;
        }

        push @FieldNames, $Line->{DF} if IsHashRefWithData($Line) && $Line->{DF};
    }

    return @FieldNames;
}

1;
