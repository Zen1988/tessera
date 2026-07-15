# --
# OTOBO is a web-based ticketing system for service organisations.
# --

package Kernel::System::DynamicField::Driver::DynamicFieldGroup;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

use parent qw(Kernel::System::DynamicField::Driver::Set);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ($Type) = @_;

    my $Self = $Type->SUPER::new();

    $Self->{Behaviors}->{IsSetCapable} = 1;

    return $Self;
}

sub ValueGet {
    my ( $Self, %Param ) = @_;

    return $Self->SUPER::ValueGet(%Param) if !$Param{Set};

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Param{DynamicFieldConfig}{Config}{Include},
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return if !$DynamicField;

    my @GroupValue;

    FIELD:
    for my $Name ( sort keys $DynamicField->%* ) {
        my $DynamicFieldConfig = $Self->_NestedStorageFieldConfigGet(
            DynamicFieldConfig => $DynamicField->{$Name},
        );

        my $FieldValue = $BackendObject->ValueGet(
            %Param,
            DynamicFieldConfig => $DynamicFieldConfig,
            Set                => 1,
            ObjectName         => undef,
        );

        next FIELD if !IsArrayRefWithData($FieldValue);

        OUTER:
        for my $OuterIndex ( 0 .. $#$FieldValue ) {
            next OUTER if !defined $FieldValue->[$OuterIndex];

            my @InnerValue = ref $FieldValue->[$OuterIndex] eq 'ARRAY'
                ? $FieldValue->[$OuterIndex]->@*
                : ( $FieldValue->[$OuterIndex] );

            INNER:
            for my $InnerIndex ( 0 .. $#InnerValue ) {
                next INNER if !defined $InnerValue[$InnerIndex];

                $GroupValue[$OuterIndex][$InnerIndex]{$Name} = $InnerValue[$InnerIndex];
            }
        }
    }

    return if !@GroupValue;
    return \@GroupValue;
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    return $Self->SUPER::ValueSet(%Param) if !$Param{Set};

    my @GroupByOuter = defined $Param{Value} ? $Param{Value}->@* : ();

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Param{DynamicFieldConfig}{Config}{Include},
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return if !$DynamicField;

    FIELD:
    for my $Name ( sort keys $DynamicField->%* ) {
        my @FieldValue;

        OUTER:
        for my $OuterIndex ( 0 .. $#GroupByOuter ) {
            next OUTER if ref $GroupByOuter[$OuterIndex] ne 'ARRAY';

            INNER:
            for my $InnerIndex ( 0 .. $#{ $GroupByOuter[$OuterIndex] } ) {
                next INNER if ref $GroupByOuter[$OuterIndex][$InnerIndex] ne 'HASH';

                $FieldValue[$OuterIndex][$InnerIndex] = $GroupByOuter[$OuterIndex][$InnerIndex]{$Name};
            }
        }

        my $DynamicFieldConfig = $Self->_NestedStorageFieldConfigGet(
            DynamicFieldConfig => $DynamicField->{$Name},
        );

        if (
            !$BackendObject->ValueSet(
                %Param,
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => \@FieldValue,
                Set                => 1,
                ObjectName         => undef,
            )
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error setting nested Value for DynamicField $Name",
            );

            return;
        }
    }

    return 1;
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    return $Self->SUPER::ValueValidate(%Param) if !$Param{Set};

    my @GroupByOuter = defined $Param{Value} ? $Param{Value}->@* : ();

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Param{DynamicFieldConfig}{Config}{Include},
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return if !$DynamicField;

    OUTER:
    for my $OuterIndex ( 0 .. $#GroupByOuter ) {
        next OUTER if ref $GroupByOuter[$OuterIndex] ne 'ARRAY';

        INNER:
        for my $InnerIndex ( 0 .. $#{ $GroupByOuter[$OuterIndex] } ) {
            next INNER if ref $GroupByOuter[$OuterIndex][$InnerIndex] ne 'HASH';

            FIELD:
            for my $Name ( sort keys $DynamicField->%* ) {
                return if !$BackendObject->ValueValidate(
                    %Param,
                    DynamicFieldConfig => $DynamicField->{$Name},
                    Value              => $GroupByOuter[$OuterIndex][$InnerIndex]{$Name},
                );
            }
        }
    }

    return 1;
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    return $Self->SUPER::EditFieldRender( $Self->_GroupParamNormalize(%Param) );
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    return $Self->SUPER::EditFieldValueGet( $Self->_GroupParamNormalize(%Param) );
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    return $Self->SUPER::EditFieldValueValidate( $Self->_GroupParamNormalize(%Param) );
}

sub GetFieldState {
    my ( $Self, %Param ) = @_;

    return $Self->SUPER::GetFieldState( $Self->_GroupParamNormalize(%Param) );
}

sub _FieldClassBaseGet {
    return 'DynamicFieldSet DynamicFieldGroup';
}

sub _FieldSetClassGet {
    return 'DynamicFieldSet DynamicFieldGroup';
}

sub _GroupParamNormalize {
    my ( $Self, %Param ) = @_;

    return %Param if ref $Param{DynamicFieldConfig} ne 'HASH';

    my $DynamicFieldConfig = {
        $Param{DynamicFieldConfig}->%*,
        Config => {
            %{ $Param{DynamicFieldConfig}->{Config} || {} },
        },
    };

    my $Name          = $DynamicFieldConfig->{Name}          || '';
    my $ProcessSuffix = $DynamicFieldConfig->{ProcessSuffix} || '';

    if ($Name) {
        $DynamicFieldConfig->{ProcessSuffix} = $ProcessSuffix . '_' . $Name;
    }

    $Param{DynamicFieldConfig} = $DynamicFieldConfig;

    return %Param;
}

sub _NestedStorageFieldConfigGet {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = {
        $Param{DynamicFieldConfig}->%*,
        Config => {
            %{ $Param{DynamicFieldConfig}->{Config} || {} },
            MultiValue => 1,
        },
    };

    return $DynamicFieldConfig;
}

1;
