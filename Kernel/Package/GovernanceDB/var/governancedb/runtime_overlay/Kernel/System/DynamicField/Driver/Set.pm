# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::System::DynamicField::Driver::Set;

## nofilter(TidyAll::Plugin::OTOBO::Perl::ParamObject)

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use parent qw(Kernel::System::DynamicField::Driver::Base);

# core modules
use List::Util qw(max pairs);

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::Output::HTML::DynamicField::Mask',
    'Kernel::System::Log',
    'Kernel::System::Cache',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::System::DynamicField::Driver::Set - driver for the Set dynamic field

=for stopwords multivalue

=head1 DESCRIPTION

DynamicFields Set Driver delegate
In the perl backend sets handle their data as array of hashes, where the outer array runs over the set index (i.e. the multi value index of the set, or 0),
and the hash stores the field values. A set containing the dynamic fields "Person" and "Pets" could thus have the content:
[ { Person => "Max", Pets => ["Cat"] }, { Person => "Anna", Pets => ["Dog","Parrot"] } ]
In ValueSet() and ValueGet() this data would be given to the dynamic fields "Person" and "Pet" as ["Max", "Dog"] and [["Cat"], ["Dog","Parrot"]] respectively,
the array still representing the SetIndex, with the parameter Set => 1.
To be able to correctly render edit masks in the frontend and above all receive the data of the frontend correctly, for all EditField methods, this driver
changes the DynamicFieldConfig of the inner fields and appends the set index as "_$SetIndex" to the name of the fields. Therefore all frontend methods for
the inner fields must exclusively be called via this driver. (Note however, that this suffix is not used for all variables. Please always check the context.)

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=head2 new()

usually, you want to create an instance of this
by using Kernel::System::DynamicField::Backend->new();

=cut

sub new {
    my ($Type) = @_;

    # allocate new hash for object
    my $Self = bless {}, $Type;

    # set field behaviors
    $Self->{Behaviors} = {
        'IsACLReducible'               => 0,
        'IsNotificationEventCondition' => 0,
        'IsSortable'                   => 0,
        'IsFiltrable'                  => 0,
        'IsStatsCondition'             => 0,
        'IsCustomerInterfaceCapable'   => 1,
        'IsSetCapable'                 => 0,
        'SetsDynamicContent'           => 1,
        'IsSetField'                   => 1,
    };

    return $Self;
}

sub ValueGet {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my @SetValue;

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject
    );

    return if !$DynamicField;

    for my $Name ( sort keys $DynamicField->%* ) {

        my $FieldValue = $BackendObject->ValueGet(
            %Param,
            DynamicFieldConfig => $DynamicField->{$Name},
            Set                => 1,
            ObjectName         => undef,
        );

        if ($FieldValue) {
            for my $SetIndex ( 0 .. $#{$FieldValue} ) {
                $SetValue[$SetIndex]{$Name} = $FieldValue->[$SetIndex];
            }
        }
    }

    return if !@SetValue;
    return \@SetValue;
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    my @SetValue = defined $Param{Value} ? $Param{Value}->@* : ( {} );

    my $ParamObject        = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject
    );

    return if !$DynamicField;

    # if we've been coming via some form, parts may be invisible
    my @HiddenFields;

    my $FormID = $ParamObject->GetParam( Param => 'FormID' );
    if ($FormID) {

        my $Visibility = $Kernel::OM->Get('Kernel::System::Cache')->Get(
            Type => 'HiddenFields',
            Key  => $FormID,
        );

        # check if any of our Set inner fields are hidden
        for my $DFName ( keys $DynamicField->%* ) {

            my $Fullname = "DynamicField_$DFName";
            if ( exists $Visibility->{$Fullname} && $Visibility->{$Fullname} == 0 ) {

                push @HiddenFields, $DFName;
            }
        }
    }

    for my $Name ( sort keys $DynamicField->%* ) {

        # the values for an included dynamic field are the values from the respective column
        my @FieldValue = map { $_->{$Name} } @SetValue;

        # check if this set field is hidden
        my $IsHidden = grep { $_ eq $Name } @HiddenFields;
        if ( $IsHidden && $ParamObject ) {

            # restore hidden field values from old values
            my $OldValues = $BackendObject->ValueGet(
                %Param,
                DynamicFieldConfig => $DynamicField->{$Name},
                Set                => 1,
                ObjectName         => undef,
            ) // [];

            if ( $Param{DynamicFieldConfig}{Config}{MultiValue} ) {

                my $IndexMax = $#FieldValue;

                # gather OriginSetIndex values
                # to detect if we had delete/append operations
                my @OriginSetIndex = $ParamObject->GetArray(
                    Param => 'OriginSetIndex_' . $Param{DynamicFieldConfig}->{Name},
                );

                for my $Index ( 0 .. $IndexMax ) {

                    my $OriginIndex = $OriginSetIndex[$Index];

                    if ( $OriginIndex == $Index ) {

                        # index is still at original position,
                        # no delete/append happend
                        # but since the field is hidden,
                        # replace the incoming value
                        $FieldValue[$Index] = $OldValues->[$Index];
                    }
                    elsif ( $OriginIndex == -1 ) {

                        # index did not exist initially,
                        # value is result of append,
                        # make sure hidden field gets empty value
                        $FieldValue[$Index] = undef;
                    }
                    else {

                        # index has moved due to delete/append
                        # so replace incoming value with the
                        # value from DB at the *original* index
                        $FieldValue[$Index] = $OldValues->[$OriginIndex];
                    }
                }
            }
            else {

                @FieldValue = $OldValues->@*;
            }
        }

        # finally store the value
        if (
            !$BackendObject->ValueSet(
                %Param,
                DynamicFieldConfig => $DynamicField->{$Name},
                Value              => \@FieldValue,
                Set                => 1,
                ObjectName         => undef,
            )
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error setting Value for DynamicField $DynamicField"
            );

            return;
        }
    }

    return 1;
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    my @SetValue = defined $Param{Value} ? $Param{Value}->@* : ();

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject
    );

    return if !$DynamicField;

    for my $Name ( sort keys $DynamicField->%* ) {
        for my $SetIndex ( 0 .. $#SetValue ) {

            return if !$BackendObject->ValueValidate(
                %Param,
                DynamicFieldConfig => $DynamicField->{$Name},
                Value              => $SetValue[$SetIndex]{$Name},
            );
        }
    }

    return 1;
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # check and set class if necessary
    my $FieldClass = $Self->_FieldClassBaseGet();
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass .= ' ' . $Param{Class};
    }

    if ( $Param{ServerError} ) {
        $FieldClass .= ' ServerError';
    }

    my %FieldTemplateData = (
        'FieldClass' => $FieldClass,
        'FieldName'  => $FieldName,
    );

    if ( $Param{ServerError} ) {
        $FieldTemplateData{ServerError}      = $Param{ServerError};
        $FieldTemplateData{ErrorMessage}     = $Param{ErrorMessage} || 'This field is required.';
        $FieldTemplateData{DivIDServerError} = $FieldName . 'ServerError';
    }

    my $FieldTemplateFile = $Self->_FieldTemplateFileGet(
        CustomerInterface => $Param{CustomerInterface},
    );

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject
    );

    return if !$DynamicField;

    DYNAMICFIELD:
    for my $Name ( sort keys $DynamicField->%* ) {
        if ( !IsHashRefWithData( $DynamicField->{$Name} ) ) {
            delete $DynamicField->{$Name};

            next DYNAMICFIELD;
        }

        # prevent overwriting names in cached data later
        $DynamicField->{$Name} = { $DynamicField->{$Name}->%* };
    }

    # call EditLabelRender on the common backend
    my $LabelString = $Self->EditLabelRender(
        %Param,
        Mandatory => $Param{Mandatory} || '0',
        FieldName => $FieldName,
    );

    my $Data = {
        Label => $LabelString,
    };

    my @ResultHTML;
    my @SetValue = $Param{Value} ? $Param{Value}->@* : ( {} );

    # TODO: Improve
    my $StoreBlockData = delete $Param{LayoutObject}{BlockData};

    # pass visibility state of set to inner fields
    my %Visibility = map { ( "DynamicField_$_" => 1 ) } keys $DynamicField->%*;
    if ( $Param{ACLHidden} ) {
        for my $Key ( keys %Visibility ) {
            $Visibility{$Key} = 0;
        }
    }

    if ( $Param{Visibility} ) {
        %Visibility = (
            %Visibility,
            $Param{Visibility}->%*,
        );
    }

    for my $SetIndex ( 0 .. $#SetValue ) {
        my %Value;
        for my $Name ( sort keys $DynamicField->%* ) {
            $Value{"DynamicField_$Name"}          = $Visibility{"DynamicField_$Name"} ? $SetValue[$SetIndex]{$Name} : undef;
            $DynamicField->{$Name}{Name}          = $Name . ( $Param{DynamicFieldConfig}{ProcessSuffix} // '' ) . '_' . $SetIndex;
            $DynamicField->{$Name}{ProcessSuffix} = $Param{DynamicFieldConfig}{ProcessSuffix};
        }

        my $RenderContent = $Self->_RenderContentGet(
            DynamicFieldConfig => $Param{DynamicFieldConfig},
        );

        my $DynamicFieldHTML = $Kernel::OM->Get('Kernel::Output::HTML::DynamicField::Mask')->EditSectionRender(
            Content            => $RenderContent,
            DynamicFields      => $DynamicField,
            UpdatableFields    => $Param{UpdatableFields},
            LayoutObject       => $Param{LayoutObject},
            ParamObject        => $Param{ParamObject},
            DynamicFieldValues => \%Value,
            CustomerInterface  => $Param{CustomerInterface},

            # can be set by preceding GetFieldState()
            PossibleValuesFilter => $Self->{PossibleValuesFilter}{ $Param{DynamicFieldConfig}->{Name} }[$SetIndex] // {},
            Visibility           => \%Visibility,

            # TODO:
            #            Errors               => $Param{DFErrors},
            Object => $Param{Object},
        );

        $ResultHTML[$SetIndex] = $Param{LayoutObject}->Output(
            TemplateFile => $FieldTemplateFile,
            Data         => {
                Name              => $Param{DynamicFieldConfig}->{Name},
                Index             => $SetIndex,
                DynamicFieldHTML  => $DynamicFieldHTML,
                FieldSetClass     => $Self->_FieldSetClassGet(),
                RenderLayoutClass => $Self->_RenderLayoutClassGet(
                    DynamicFieldConfig => $Param{DynamicFieldConfig},
                ),
            },
        );

        delete $Param{LayoutObject}{BlockData};
    }

    # decide which structure to return
    if ( $FieldConfig->{MultiValue} ) {
        for my $Name ( sort keys $DynamicField->%* ) {
            $DynamicField->{$Name}{Name}          = $Name . ( $Param{DynamicFieldConfig}{ProcessSuffix} // '' ) . '_Template';
            $DynamicField->{$Name}{ProcessSuffix} = $Param{DynamicFieldConfig}{ProcessSuffix};
        }

        # can be set by preceding GetFieldState()
        my %TemplateValues = map { 'DynamicField_' . $_ => $Self->{TemplateValues}{ $Param{DynamicFieldConfig}->{Name} }{$_} }
            keys %{ $Self->{TemplateValues}{ $Param{DynamicFieldConfig}->{Name} } // {} };

        my $RenderContent = $Self->_RenderContentGet(
            DynamicFieldConfig => $Param{DynamicFieldConfig},
        );

        my $DynamicFieldHTML = $Kernel::OM->Get('Kernel::Output::HTML::DynamicField::Mask')->EditSectionRender(
            Content            => $RenderContent,
            DynamicFields      => $DynamicField,
            UpdatableFields    => $Param{UpdatableFields},
            LayoutObject       => $Param{LayoutObject},
            ParamObject        => $Param{ParamObject},
            DynamicFieldValues => \%TemplateValues,
            CustomerInterface  => $Param{CustomerInterface},
            Visibility         => \%Visibility,

            # can be set by preceding GetFieldState()
            PossibleValuesFilter => $Self->{PossibleValuesFilter}{ $Param{DynamicFieldConfig}->{Name} }[ $#SetValue + 1 ] // {},
            Object               => $Param{Object},
        );

        my $TemplateHTML = $Param{LayoutObject}->Output(
            TemplateFile => $FieldTemplateFile,
            Data         => {
                Name              => $Param{DynamicFieldConfig}->{Name},
                Index             => 'Template',
                DynamicFieldHTML  => $DynamicFieldHTML,
                FieldSetClass     => $Self->_FieldSetClassGet(),
                RenderLayoutClass => $Self->_RenderLayoutClassGet(
                    DynamicFieldConfig => $Param{DynamicFieldConfig},
                ),
            },
        );

        $Data->{MultiValue}         = \@ResultHTML;
        $Data->{MultiValueTemplate} = $TemplateHTML;
    }
    else {
        $Data->{Field} = $ResultHTML[0];
    }

    # restore Layout BlockData
    $Param{LayoutObject}{BlockData} = $StoreBlockData;

    return $Data;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}{Name};

    my $Value;

    # check if there is a Template and retrieve the dynamic field value from there
    if ( IsHashRefWithData( $Param{Template} ) && defined $Param{Template}->{$FieldName} ) {
        $Value = $Param{Template}->{$FieldName};
    }

    # otherwise get dynamic field value from the web request
    elsif (
        defined $Param{ParamObject}
        && ref $Param{ParamObject} eq 'Kernel::System::Web::Request'
        )
    {
        my @SetData;

        my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
        my $DynamicField = $Self->_GetIncludedDynamicFields(
            InputFieldDefinition => $Include,
            DynamicFieldObject   => $DynamicFieldObject,
        );

        return if !$DynamicField;

        DYNAMICFIELD:
        for my $Name ( sort keys $DynamicField->%* ) {
            if ( !IsHashRefWithData( $DynamicField->{$Name} ) ) {
                delete $DynamicField->{$Name};

                next DYNAMICFIELD;
            }

            # prevent overwriting names in cached data later
            $DynamicField->{$Name} = { $DynamicField->{$Name}->%* };
        }

        my @SetIndex = $Self->_SubmittedSetIndexListGet(
            DynamicFieldConfig => $Param{DynamicFieldConfig},
            DynamicField       => $DynamicField,
            ParamObject        => $Param{ParamObject},
        );

        return if !@SetIndex;

        for my $SetIndex (@SetIndex) {
            my $OutputIndex = @SetData;

            for my $Name ( sort keys $DynamicField->%* ) {
                my $DynamicFieldConfig = { $DynamicField->{$Name}->%* };
                $DynamicFieldConfig->{Name}          = $Name . ( $Param{DynamicFieldConfig}{ProcessSuffix} // '' ) . '_' . $SetIndex;
                $DynamicFieldConfig->{ProcessSuffix} = $Param{DynamicFieldConfig}{ProcessSuffix};

                $SetData[$OutputIndex]{$Name} = $BackendObject->EditFieldValueGet(
                    %Param,
                    DynamicFieldConfig => $DynamicFieldConfig,
                );
            }
        }

        return if !@SetData;
        $Value = \@SetData;
    }

    if ( defined $Param{ReturnTemplateStructure} && $Param{ReturnTemplateStructure} eq '1' ) {
        return {
            $FieldName => $Value,
        };
    }

    # TODO check if below comment is true
    # for this field the normal return and the ReturnValueStructure are the same
    return $Value;
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    if (
        ( !defined $Param{GetParam}{DynamicField} || !defined $Param{GetParam}{DynamicField}{"DynamicField_$Param{DynamicFieldConfig}{Name}"} )
        && !$Param{Mandatory}
        )
    {
        return {
            ServerError  => undef,
            ErrorMessage => undef,
        };
    }

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $SetDFConfig = $Param{DynamicFieldConfig};
    my $Result;
    my $Include      = $SetDFConfig->{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return 1 if !$DynamicField;

    DYNAMICFIELD:
    for my $Name ( sort keys $DynamicField->%* ) {
        if ( !IsHashRefWithData( $DynamicField->{$Name} ) ) {
            delete $DynamicField->{$Name};

            next DYNAMICFIELD;
        }

        # prevent overwriting names in cached data later
        $DynamicField->{$Name} = { $DynamicField->{$Name}->%* };
    }

    my @SetIndex = $Self->_SubmittedSetIndexListGet(
        DynamicFieldConfig => $SetDFConfig,
        DynamicField       => $DynamicField,
        ParamObject        => $Param{ParamObject},
    );

    for my $SetIndex (@SetIndex) {

        for my $Name ( sort keys $DynamicField->%* ) {
            my $DynamicFieldConfig = { $DynamicField->{$Name}->%* };
            $DynamicFieldConfig->{Name}          = $Name . ( $SetDFConfig->{ProcessSuffix} // '' ) . '_' . $SetIndex;
            $DynamicFieldConfig->{ProcessSuffix} = $SetDFConfig->{ProcessSuffix};

            $Result->{ $DynamicFieldConfig->{Name} } = $BackendObject->EditFieldValueValidate(
                %Param,
                DynamicFieldConfig => $DynamicFieldConfig,
            );
        }
    }

    if (
        $Param{Mandatory}
        && !$Self->_SubmittedSetHasData(
            DynamicFieldConfig => $SetDFConfig,
            DynamicField       => $DynamicField,
            SetIndex           => \@SetIndex,
            ParamObject        => $Param{ParamObject},
        )
        )
    {
        return {
            ServerError  => 1,
            ErrorMessage => 'This field is required.',
        };
    }

    return $Result || {
        ServerError  => undef,
        ErrorMessage => undef,
    };
}

sub _SubmittedSetHasData {
    my ( $Self, %Param ) = @_;

    return if !$Param{ParamObject};
    return if !IsHashRefWithData( $Param{DynamicField} );

    my $ProcessSuffix = $Param{DynamicFieldConfig}->{ProcessSuffix} // '';

    SETINDEX:
    for my $SetIndex ( @{ $Param{SetIndex} || [] } ) {
        NAME:
        for my $Name ( sort keys $Param{DynamicField}->%* ) {
            my $Prefix    = 'DynamicField_' . $Name . $ProcessSuffix . '_' . $SetIndex;
            my $FieldType = $Param{DynamicField}->{$Name}->{FieldType} || '';

            if ( $FieldType eq 'Date' || $FieldType eq 'DateTime' ) {
                my $Used = $Param{ParamObject}->GetParam( Param => $Prefix . 'Used' );
                return 1 if defined $Used && "$Used" =~ m{\S};

                next NAME;
            }

            for my $ParamName (
                $Prefix,
                )
            {
                my @Value = $Param{ParamObject}->GetArray( Param => $ParamName );
                if (!@Value) {
                    my $Value = $Param{ParamObject}->GetParam( Param => $ParamName );
                    @Value = defined $Value ? ($Value) : ();
                }

                VALUE:
                for my $Value (@Value) {
                    next VALUE if !defined $Value;
                    return 1 if "$Value" =~ m{\S};
                }
            }
        }
    }

    return;
}

sub _SubmittedSetIndexListGet {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $DynamicField       = $Param{DynamicField};
    my $ParamObject        = $Param{ParamObject};

    return (0) if !$DynamicFieldConfig->{Config}{MultiValue};
    return (0) if !$ParamObject;

    my %SetIndex;

    my @DataAll = $ParamObject->GetArray(
        Param => 'SetIndex_' . $DynamicFieldConfig->{Name},
    );

    DATA:
    for my $Index (@DataAll) {
        next DATA if !defined $Index;
        next DATA if $Index !~ /^\d+\z/;

        $SetIndex{$Index} = 1;
    }

    my @ParamNames = $ParamObject->GetParamNames();
    my $ProcessSuffix = $DynamicFieldConfig->{ProcessSuffix} // '';

    FIELD:
    for my $Name ( sort keys $DynamicField->%* ) {
        my $Prefix = 'DynamicField_' . $Name . $ProcessSuffix . '_';

        PARAM:
        for my $ParamName (@ParamNames) {
            next PARAM if !defined $ParamName;
            next PARAM if $ParamName !~ /^\Q$Prefix\E(\d+)(?:\D.*)?\z/;

            $SetIndex{$1} = 1;
        }
    }

    my @SetIndex = sort { $a <=> $b } keys %SetIndex;

    return @SetIndex;
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    if ( !$Param{Value} ) {
        return {
            Value => '',
            Title => '',
        };
    }

    # activate HTMLOutput when it wasn't specified
    my $HTMLOutput = $Param{HTMLOutput} // 1;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my %SetValue = (
        Value => [],
        Title => [],
    );

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return 1 if !$DynamicField;

    my @FieldOrdered = $Self->_GetIncludedFieldOrdered(
        Include => $Include,
    );

    for my $Name (@FieldOrdered) {
        my $DynamicFieldConfig = $DynamicField->{$Name};
        my $Label;

        if ($HTMLOutput) {
            $Label = $Param{LayoutObject}->Output(
                Template => '[% Translate( Data.Label ) | html %]',
                Data     => {
                    Label => $DynamicFieldConfig->{Label},
                },
            );
        }
        else {
            $Label = $Param{LayoutObject}->{LanguageObject}->Translate( $DynamicFieldConfig->{Label} );
        }

        VALUE:
        for my $SetIndex ( 0 .. $#{ $Param{Value} } ) {
            next VALUE if !defined $Param{Value}[$SetIndex]{$Name};

            my $Element = $BackendObject->DisplayValueRender(
                %Param,
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => $Param{Value}[$SetIndex]{$Name},
            );

            next VALUE if !defined $Element->{Value} || $Element->{Value} eq '';

            if ($HTMLOutput) {
                if ( $Element->{Link} ) {
                    $SetValue{Value}[$SetIndex]
                        .= "<label>$Label</label><p class=\"Value\"><a href=\"$Element->{Link}\" title=\"$Element->{Title}\">$Element->{Value}</a></p><div class=\"Clear\"></div>";
                }
                else {
                    $SetValue{Value}[$SetIndex]
                        .= "<label>$Label</label><p class=\"Value\"><span title=\"$Element->{Title}\">$Element->{Value}</span></p><div class=\"Clear\"></div>";
                }
            }
            else {
                $SetValue{Value}[$SetIndex] .= "$Label: $Element->{Value}\n";
                $SetValue{Title}[$SetIndex] .= "$Label: $Element->{Title}\n";
            }
        }
    }

    if ( !scalar $SetValue{Value}->@* ) {
        return {
            Value => '',
            Title => '',
        };
    }

    @{ $SetValue{Value} } = map { $_ // '' } $SetValue{Value}->@*;
    @{ $SetValue{Title} } = map { $_ // '' } $SetValue{Title}->@*;

    my %Value;
    if ($HTMLOutput) {
        $Value{Value} = '<div class="SetDisplayValue">'
            . join( '</div><div class="SetDisplayValue">', $SetValue{Value}->@* )
            . '</div>';
        $Value{Title} = '';
    }
    else {
        $Value{Value} = join( "\n", $SetValue{Value}->@* );
        $Value{Title} = join( "; ", $SetValue{Title}->@* );
    }

    return \%Value;
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => 'Dynamic field type Set is currently not searchable!',
    );

    return;
}

sub SearchFieldValueGet {
    my ( $Self, %Param ) = @_;

    return;
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    $Param{Value} ||= [];

    my %SetValue = (
        Value => [],
        Title => [],
    );

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return if !$DynamicField;

    my @FieldOrdered = $Self->_GetIncludedFieldOrdered(
        Include => $Include,
    );

    for my $Name (@FieldOrdered) {
        my $DynamicFieldConfig = $DynamicField->{$Name};

        VALUE:
        for my $SetIndex ( 0 .. $#{ $Param{Value} } ) {
            next VALUE if !defined $Param{Value}[$SetIndex]{$Name};

            my $Element = $BackendObject->ReadableValueRender(
                %Param,
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => $Param{Value}[$SetIndex]{$Name},
            );

            $SetValue{Value}[$SetIndex] .= " $DynamicFieldConfig->{Label}: $Element->{Value};";
            $SetValue{Title}[$SetIndex] .= " $DynamicFieldConfig->{Label}: $Element->{Title};";
        }
    }

    my %Value;
    for my $Return (qw/Value Title/) {
        $Value{$Return} = join ' - ', map { $_ // '' } $SetValue{$Return}->@*;
        $Value{$Return} //= '';
    }

    return \%Value;
}

sub TemplateValueTypeGet {
    my ( $Self, %Param ) = @_;

    return;
}

sub RandomValueSet {
    my ( $Self, %Param ) = @_;

    my @Value;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # create 1 to 3 sets for MultiValue, else 1
    my $SetCount = $Param{DynamicFieldConfig}{Config}{MultiValue} ? int( rand(3) ) + 1 : 1;

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return { Success => 0 } if !$DynamicField;

    for my $Pair ( pairs $DynamicField->%* ) {
        my ( $Name, $DynamicFieldConfig ) = $Pair->@*;

        my $Return = $BackendObject->RandomValueSet(
            %Param,
            DynamicFieldConfig => $DynamicFieldConfig,
            SetCount           => $SetCount,
        );

        return { Success => 0 } if !$Return->{Success};

        for my $SetIndex ( 0 .. $SetCount - 1 ) {
            $Value[$SetIndex]{$Name} = $Return->[$SetIndex];
        }
    }

    return {
        Success => 1,
        Value   => \@Value,
    };
}

sub ValueLookup {
    my ( $Self, %Param ) = @_;

    return    unless defined $Param{Key};
    return [] unless ref $Param{Key} eq 'ARRAY';

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $Include      = $Param{DynamicFieldConfig}{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return if !$DynamicField;

    my @FieldOrdered = $Self->_GetIncludedFieldOrdered(
        Include => $Include,
    );

    for my $Name (@FieldOrdered) {
        my $DynamicFieldConfig = $DynamicField->{$Name};

        VALUE:
        for my $SetIndex ( 0 .. $#{ $Param{Key} } ) {
            next VALUE unless defined $Param{Key}[$SetIndex]{$Name};

            $Param{Key}[$SetIndex]{$Name} = $BackendObject->ValueLookup(
                %Param,
                DynamicFieldConfig => $DynamicFieldConfig,
                Key                => $Param{Key}[$SetIndex]{$Name},
            );
        }
    }

    return $Param{Key};
}

sub SearchFieldPreferences {
    my ( $Self, %Param ) = @_;

    # this field makes no use of SearchFieldPreferences
    # nevertheless, function needs to be overwritten to make sure that the call doesn't reach SearchFieldPreferences in BaseSelect
    return;
}

sub ValueIsDifferent {
    my ( $Self, %Param ) = @_;

    my $IncludedFields = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Param{DynamicFieldConfig}{Config}{Include},
        DynamicFieldObject   => $Kernel::OM->Get('Kernel::System::DynamicField'),
    );

    my @SetValue1 = @{ $Param{Value1} || [] };
    my @SetValue2 = @{ $Param{Value2} || [] };

    for my $Index ( 0 .. max( $#SetValue1, $#SetValue2 ) ) {

        for my $FieldName ( keys $IncludedFields->%* ) {

            my $Value1 = $SetValue1[$Index] || {};
            my $Value2 = $SetValue2[$Index] || {};

            my $InnerValueIsDifferent = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueIsDifferent(
                %Param,
                DynamicFieldConfig => $IncludedFields->{$FieldName},
                Value1             => $Value1->{$FieldName},
                Value2             => $Value2->{$FieldName},
            );

            return 1 if $InnerValueIsDifferent;
        }
    }

    return 0;
}

sub GetFieldState {
    my ( $Self, %Param ) = @_;

    my %GetParam  = $Param{GetParam}->%*;
    my %DFParam   = %{ $GetParam{DynamicField} // {} };
    my $SetConfig = $Param{DynamicFieldConfig};
    my @SetValue  = $DFParam{"DynamicField_$SetConfig->{Name}"} ? $DFParam{"DynamicField_$SetConfig->{Name}"}->@* : ( {} );

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $Include      = $SetConfig->{Config}{Include};
    my $DynamicField = $Self->_GetIncludedDynamicFields(
        InputFieldDefinition => $Include,
        DynamicFieldObject   => $DynamicFieldObject,
    );

    return if !$DynamicField;

    my %Return;

    #  check if whole Set re-appears
    my $WholeSetReAppears = 0;
    if ( $Param{CachedVisibility} && $Param{CachedVisibility}{"DynamicField_$SetConfig->{Name}"} == 0 )
    {
        $WholeSetReAppears = 1;
    }

    my $PassVisibility = 0;
    if ( $Param{CachedVisibility} ) {
        my $InnerField = ( keys $DynamicField->%* )[0];

        # if we are not in the first run for this mask, we provide the cached visibility for the inner fields
        if ( exists $Param{CachedVisibility}{"DynamicField_$InnerField\_0"} ) {
            $PassVisibility = 1;
        }
    }

    for my $SetIndex ( 0 .. $#SetValue ) {

        for my $Name ( keys $DynamicField->%* ) {
            $DFParam{"DynamicField_$Name"} = $SetValue[$SetIndex]{$Name};
        }

        my %IndexVisibility;

        # if we have a cached visibility, we use it for set inner fields, too
        if ($PassVisibility) {

            # if the whole set is reappearing, we must treat all inner fields as reappearing
            if ($WholeSetReAppears) {
                %IndexVisibility = map { 'DynamicField_' . $_ => 0 } keys $DynamicField->%*;
            }
            else {
                for my $Name ( keys $DynamicField->%* ) {
                    $IndexVisibility{"DynamicField_$Name"} =
                        $Param{CachedVisibility}{"DynamicField_$Name\_$SetIndex"} // $Param{CachedVisibility}{"DynamicField_$Name\_Template"};
                }
            }
        }

        my $LoopProtection = 100;
        my %SetFieldStates = $Param{FieldRestrictionsObject}->GetFieldStates(
            %Param,
            DynamicFields => $DynamicField,
            GetParam      => {
                %GetParam,
                %DFParam,
                DynamicField => \%DFParam,
            },
            LoopProtection   => \$LoopProtection,
            SetIndex         => $SetIndex,
            CachedVisibility => $PassVisibility ? \%IndexVisibility : undef,
            NoDefaultValue   => 1,
        );

        for my $Name ( keys $SetFieldStates{Fields}->%* ) {

            my $DFName = "DynamicField_" . $Name;
            if (
                exists $IndexVisibility{$DFName} &&
                $IndexVisibility{$DFName} == 0   &&
                $SetFieldStates{Visibility}{$DFName}
                )
            {
                my $ParamObject = $Param{ParamObject} // $Kernel::OM->Get('Kernel::System::Web::Request');
                if ( $ParamObject && $Param{ObjectID} ) {

                    my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
                    my $OldValues     = $BackendObject->ValueGet(
                        ObjectID           => $Param{ObjectID},
                        DynamicFieldConfig => $DynamicField->{$Name},
                        Set                => 1,
                        ObjectName         => undef,
                    ) // [];

                    if ( $DynamicField->{$Name}{Config}{MultiValue} ) {

                        # gather OriginSetIndex values
                        # to detect if we had delete/append operations
                        my @OriginSetIndex = $ParamObject->GetArray(
                            Param => 'OriginSetIndex_' . $SetConfig->{Name},
                        );

                        if (@OriginSetIndex) {

                            my $OriginIndex = $OriginSetIndex[$SetIndex];
                            if ( $OriginIndex == $SetIndex ) {

                                # index is still at original position,
                                # no delete/append happend
                                # but since the field is hidden,
                                # replace the incoming value
                                $SetFieldStates{NewValues}{$Name} = $OldValues->[$SetIndex];
                            }
                            elsif ( $OriginIndex == -1 ) {

                                # index did not exist initially,
                                # value is result of append,
                                # make sure hidden field gets empty value
                                $SetFieldStates{NewValues}{$Name} = undef;
                            }
                            else {

                                # index has moved due to delete/append
                                # so replace incoming value with the
                                # value from DB at the *original* index
                                $SetFieldStates{NewValues}{$Name} = $OldValues->[$OriginIndex];
                            }
                        }
                    }
                }
            }

            my $SuffixedName = $Name . ( $SetConfig->{ProcessSuffix} || '' );

            # prepare the return used by the frontend modules for AJAX updates
            $Return{Sets}{$Name}{DynamicFieldConfig}                             = $DynamicField->{$Name};
            $Return{Sets}{$Name}{FieldStates}{ $SuffixedName . '_' . $SetIndex } = $SetFieldStates{Fields}{$Name};
            $Return{Sets}{$Name}{Values}{ $SuffixedName . '_' . $SetIndex }      = exists $SetFieldStates{NewValues}{$Name}
                ?
                $SetFieldStates{NewValues}{$Name}
                : $DFParam{"DynamicField_$Name"};

            # set the new value of the set itself copied to GetParam in the frontend modules
            if ( $SetFieldStates{NewValues}{ 'DynamicField_' . $Name } ) {
                $Return{NewValue}[$SetIndex]{$Name} = $SetFieldStates{NewValues}{ 'DynamicField_' . $Name };
            }

            # store the reduced possible values in this object for a possible subsequent EditFieldRender
            $Self->{PossibleValuesFilter}{ $SetConfig->{Name} }[$SetIndex]{ 'DynamicField_' . $Name } = $SetFieldStates{Fields}{$Name}{PossibleValues};
        }

        for my $DFName ( keys $SetFieldStates{Visibility}->%* ) {

            # the returned visibility will only be cached if the changed element affects visibility

            # ajax visibility
            $Return{Visibility}{ $DFName . '_' . $SetIndex } = $SetFieldStates{Visibility}{$DFName};

            # initial render visibility
            $Return{Visibility}{$DFName} = $SetFieldStates{Visibility}{$DFName};
        }
    }

    if ( $SetConfig->{Config}{MultiValue} ) {
        for my $Name ( keys $DynamicField->%* ) {
            $DFParam{"DynamicField_$Name"} = undef;
        }

        my %IndexVisibility;
        if ($PassVisibility) {

            # if the whole set is reappearing, we must treat all inner fields as reappearing
            if ($WholeSetReAppears) {
                %IndexVisibility = map { 'DynamicField_' . $_ => 0 } keys $DynamicField->%*;
            }
            else {
                for my $Name ( keys $DynamicField->%* ) {
                    $IndexVisibility{"DynamicField_$Name"} = $Param{CachedVisibility}{"DynamicField_$Name\_Template"};
                }
            }
        }

        my $LoopProtection = 100;
        my %SetFieldStates = $Param{FieldRestrictionsObject}->GetFieldStates(
            %Param,
            DynamicFields => $DynamicField,
            GetParam      => {
                %GetParam,
                %DFParam,
                DynamicField => \%DFParam,
            },
            LoopProtection   => \$LoopProtection,
            CachedVisibility => $PassVisibility ? \%IndexVisibility : undef,
            NoDefaultValue   => 1,
        );

        for my $Name ( sort keys $SetFieldStates{Fields}->%* ) {

            my $SuffixedName = $Name . ( $SetConfig->{ProcessSuffix} || '' );

            # prepare the return used by the frontend modules for AJAX updates
            $Return{Sets}{$Name}{DynamicFieldConfig}                         = $DynamicField->{$Name};
            $Return{Sets}{$Name}{FieldStates}{ $SuffixedName . '_Template' } = $SetFieldStates{Fields}{$Name};
            $Return{Sets}{$Name}{Values}{ $SuffixedName . '_Template' }      = exists $SetFieldStates{NewValues}{$Name}
                ?
                $SetFieldStates{NewValues}{$Name}
                : $DFParam{"DynamicField_$Name"};

            # store the reduced possible values in this object for a possible subsequent EditFieldRender
            $Self->{PossibleValuesFilter}{ $SetConfig->{Name} }[ $#SetValue + 1 ]{ 'DynamicField_' . $Name } = $SetFieldStates{Fields}{$Name}{PossibleValues};
            $Self->{TemplateValues}{ $SetConfig->{Name} }{$Name} = exists $SetFieldStates{NewValues}{$Name}
                ?
                $SetFieldStates{NewValues}{$Name}
                : $DFParam{"DynamicField_$Name"};
        }

        for my $DFName ( keys $SetFieldStates{Visibility}->%* ) {
            $Return{Visibility}{ $DFName . '_Template' } = $SetFieldStates{Visibility}{$DFName};
        }
    }

    if ($WholeSetReAppears) {

        my $ParamObject = $Param{ParamObject} // $Kernel::OM->Get('Kernel::System::Web::Request');
        if ( $ParamObject && $Param{ObjectID} ) {

            my $BackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
            my $OldValues     = $BackendObject->ValueGet(
                ObjectID           => $Param{ObjectID},
                DynamicFieldConfig => $SetConfig,
                Set                => 1,
                ObjectName         => undef,
            ) // [];

            my @InnerFields = map { $_->{DF} } $SetConfig->{Config}->{Include}->@*;

            for my $SetIndex ( 0 .. $#SetValue ) {

                for my $DFName (@InnerFields) {

                    $Return{Sets}{$DFName}{DynamicFieldConfig} = $DynamicField->{$DFName};
                    $Return{Sets}{$DFName}{Values}{ $DFName . "_" . $SetIndex } = $OldValues->[$SetIndex]->{$DFName};
                    if ( !exists $Return{Sets}{$DFName}{FieldStates}{ $DFName . '_' . $SetIndex } ) {
                        $Return{Sets}{$DFName}{FieldStates}{ $DFName . '_' . $SetIndex } = {
                            'PossibleValues'  => undef,
                            'NotACLReducible' => 1,
                        };
                    }
                }
            }
        }
    }

    # fill up NewValue with existing ones
    if ( exists $Return{NewValue} ) {
        $Return{NewValue} = $Self->_MergeValues(
            GetParamValue => $DFParam{"DynamicField_$SetConfig->{Name}"},
            NewValue      => $Return{NewValue},
        );
    }
    return %Return;
}

=head1 PRIVATE FUNCTIONS

=head2 _GetIncludedDynamicFields($Include, $DynamicFieldObject)

Helper Function for getting the Dynamic Fields from an Include, i.e.
$DynamicFields = $GetIncludedDynamicFields->($Param{DynamicFieldConfig}{Config}{Include});
This subroutine takes three arguments:
$Include: a list of hash references containing information about the items to include
$DynamicFieldObject: an object used to retrieve dynamic field information
and returns either the DynamicFields or undef in case of an error.

=cut

sub _GetIncludedDynamicFields {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my %DynamicField;

    # This subroutine takes a DFEntry and the DynamicFieldObject as arguments
    # It retrieves the dynamic field definition for the given DFEntry
    # If the definition is not available, it retrieves it from the DynamicFieldObject
    # Returns the dynamic field definition
    my $GetDynamicField = sub {

        my ($DFEntry) = @_;

        my $DynamicField = $DFEntry->{Definition} // $DynamicFieldObject->DynamicFieldGet(
            Name => $DFEntry->{DF},
        );

        return if !IsHashRefWithData($DynamicField);

        my %DynamicFieldCopy = %{$DynamicField};
        $DynamicFieldCopy{Config} = {
            %{ $DynamicFieldCopy{Config} || {} },
        };

        $Self->_LegacyGovernanceSetReferenceConfigApply(
            DynamicFieldConfig => \%DynamicFieldCopy,
        );

        if (
            ( $DynamicFieldCopy{FieldType} || '' ) eq 'GeneralCatalog'
            && !$DynamicFieldCopy{Config}{Class}
            )
        {
            $DynamicFieldCopy{FieldType} = 'Text';
        }

        return \%DynamicFieldCopy;
    };

    ITEM:
    for my $IncludeItem ( @{ $Param{InputFieldDefinition} } ) {

        if ( $IncludeItem->{Grid} ) {

            for my $Row ( @{ $IncludeItem->{Grid}{Rows} } ) {

                DFENTRY:
                for my $DFEntry ( $Row->@* ) {

                    my $DynamicField = $GetDynamicField->($DFEntry);
                    if ( IsHashRefWithData($DynamicField) ) {
                        if ( $DFEntry->{Label} ) {
                            $DynamicField->{Label} = $DFEntry->{Label};
                        }
                        $DynamicField->{Mandatory}      = $DFEntry->{Mandatory};
                        $DynamicField->{Readonly}       = $DFEntry->{Readonly};
                        $DynamicField{ $DFEntry->{DF} } = $DynamicField;
                    }
                    else {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "DynamicFieldConfig missing for field: $DFEntry->{DF}, or is not a Ticket Dynamic Field!",
                        );

                        next DFENTRY;
                    }
                }
            }
        }
        elsif ( $IncludeItem->{DF} ) {

            my $DynamicField = $GetDynamicField->($IncludeItem);
            if ($DynamicField) {
                if ( $IncludeItem->{Label} ) {
                    $DynamicField->{Label} = $IncludeItem->{Label};
                }
                $DynamicField->{Mandatory}          = $IncludeItem->{Mandatory};
                $DynamicField->{Readonly}           = $IncludeItem->{Readonly};
                $DynamicField{ $IncludeItem->{DF} } = $DynamicField;
            }
            else {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "DynamicFieldConfig missing for field: $IncludeItem->{DF}, or is not a Ticket Dynamic Field!",
                );
                next ITEM;
            }
        }
        else {
            next ITEM;
        }
    }

    return \%DynamicField;
}

sub _LegacyGovernanceSetReferenceConfigApply {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    return if !IsHashRefWithData($DynamicFieldConfig);

    my $Name   = $DynamicFieldConfig->{Name} || '';
    my $Config = $DynamicFieldConfig->{Config} ||= {};

    my %GovernanceObjectClassByField = (
        'ZBlue-Profile'    => ['GovernanceRole'],
        'ZBlue-Role'       => ['GovernanceRole'],
        'ZBlue-Template'   => ['Template'],
        'ZBlue-PurpleBook' => ['BlueBook'],
    );

    my %GovernanceObjectFieldDefaults = (
        'ZBlue-Profile' => {
            MultiValue   => 0,
            PossibleNone => 0,
        },
        'ZBlue-Role' => {
            MultiValue   => 0,
            PossibleNone => 1,
        },
        'ZBlue-Template' => {
            MultiValue   => 0,
            PossibleNone => 1,
        },
        'ZBlue-PurpleBook' => {
            MultiValue   => 0,
            PossibleNone => 1,
        },
    );

    if (
        ( $DynamicFieldConfig->{FieldType} || '' ) eq 'GovernanceObject'
        && !IsArrayRefWithData( $Config->{ClassIDs} )
        && IsArrayRefWithData( $GovernanceObjectClassByField{$Name} )
        )
    {
        my @ClassIDs = $Self->_GovernanceObjectClassIDsResolve(
            Classes => $GovernanceObjectClassByField{$Name},
        );

        if (@ClassIDs) {
            $Config->{ClassIDs}     = \@ClassIDs;
            $Config->{DisplayType}  ||= 'GovernanceObjectName';
            $Config->{DefaultValue} = '' if !defined $Config->{DefaultValue};
            $Config->{Link}         = '' if !defined $Config->{Link};
            $Config->{LinkPreview}  = '' if !defined $Config->{LinkPreview};
        }
    }

    if ( IsHashRefWithData( $GovernanceObjectFieldDefaults{$Name} ) ) {
        for my $Key ( sort keys %{ $GovernanceObjectFieldDefaults{$Name} } ) {
            $Config->{$Key} = $GovernanceObjectFieldDefaults{$Name}->{$Key}
                if !defined $Config->{$Key};
        }
    }

    my %GeneralCatalogClassByField = (
        'ZBlue-TicketType' => 'ZTSM::Type',
    );

    my %GeneralCatalogFieldDefaults = (
        'ZBlue-TicketType' => {
            MultiValue   => 0,
            PossibleNone => 0,
        },
    );

    if (
        ( $DynamicFieldConfig->{FieldType} || '' ) eq 'GeneralCatalog'
        && !$Config->{Class}
        && $GeneralCatalogClassByField{$Name}
        )
    {
        $Config->{Class} = $GeneralCatalogClassByField{$Name};
    }

    if ( IsHashRefWithData( $GeneralCatalogFieldDefaults{$Name} ) ) {
        for my $Key ( sort keys %{ $GeneralCatalogFieldDefaults{$Name} } ) {
            $Config->{$Key} = $GeneralCatalogFieldDefaults{$Name}->{$Key}
                if !defined $Config->{$Key};
        }
    }

    return 1;
}

sub _GovernanceObjectClassIDsResolve {
    my ( $Self, %Param ) = @_;

    return if !IsArrayRefWithData( $Param{Classes} );

    my $ClassID2Name = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::GovernanceObject::Class',
    ) || {};

    my %ClassIDByNormalizedName = map {
        my $Name = $ClassID2Name->{$_} // '';
        $Name =~ s{\s+}{}g;
        lc $Name => $_;
    } grep { defined $ClassID2Name->{$_} } keys %{$ClassID2Name};

    my @ClassIDs;
    my %Seen;
    CLASS:
    for my $Class ( @{ $Param{Classes} } ) {
        next CLASS if !defined $Class || $Class eq '';

        if ( $Class =~ m{\A\d+\z}xms ) {
            next CLASS if $Seen{$Class}++;
            push @ClassIDs, $Class;
            next CLASS;
        }

        my $Normalized = $Class;
        $Normalized =~ s{\s+}{}g;
        my $ClassID = $ClassIDByNormalizedName{ lc $Normalized };
        next CLASS if !$ClassID;
        next CLASS if $Seen{$ClassID}++;

        push @ClassIDs, $ClassID;
    }

    return @ClassIDs;
}

sub _GetIncludedFieldOrdered {
    my ( $Self, %Param ) = @_;

    my @Return;

    ITEM:
    for my $IncludeItem ( @{ $Param{Include} } ) {

        if ( $IncludeItem->{Grid} ) {
            for my $Row ( @{ $IncludeItem->{Grid}{Rows} } ) {

                COLUMN:
                for my $DFEntry ( $Row->@* ) {
                    next COLUMN if !$DFEntry->{DF};

                    push @Return, $DFEntry->{DF};
                }
            }
        }
        elsif ( $IncludeItem->{DF} ) {
            push @Return, $IncludeItem->{DF};
        }
    }

    return @Return;
}

sub _RenderContentGet {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Include            = $DynamicFieldConfig->{Config}{Include} || [];

    return $Include if !IsArrayRefWithData($Include);

    my @Fields = $Self->_RenderFieldListGet(
        Include => $Include,
    );

    return $Include if !@Fields;

    if ( ( $DynamicFieldConfig->{Config}{RenderLayout} || 'Vertical' ) ne 'Horizontal' ) {
        return [ map { { $_->%* } } @Fields ];
    }

    return [
        {
            Grid => {
                Columns => scalar @Fields,
                Rows    => [ \@Fields ],
            },
        },
    ];
}

sub _RenderFieldListGet {
    my ( $Self, %Param ) = @_;

    my $Include = $Param{Include};

    return if !IsArrayRefWithData($Include);

    my @Fields;

    ELEMENT:
    for my $Element ( $Include->@* ) {

        next ELEMENT if !IsHashRefWithData($Element);

        if ( $Element->{DF} ) {
            push @Fields, { $Element->%* };
            next ELEMENT;
        }

        next ELEMENT if !IsHashRefWithData( $Element->{Grid} );
        next ELEMENT if !IsArrayRefWithData( $Element->{Grid}{Rows} );

        ROW:
        for my $Row ( $Element->{Grid}{Rows}->@* ) {

            next ROW if ref $Row ne 'ARRAY';

            FIELD:
            for my $Field ( $Row->@* ) {

                next FIELD if !IsHashRefWithData($Field);
                next FIELD if !$Field->{DF};

                push @Fields, { $Field->%* };
            }
        }
    }

    return @Fields;
}

sub _RenderLayoutClassGet {
    my ( $Self, %Param ) = @_;

    my $RenderLayout = $Param{DynamicFieldConfig}{Config}{RenderLayout} || 'Vertical';

    return ' DynamicFieldSetLayoutHorizontal' if $RenderLayout eq 'Horizontal';
    return ' DynamicFieldSetLayoutVertical';
}

sub _FieldClassBaseGet {
    return 'DynamicFieldSet';
}

sub _FieldSetClassGet {
    return 'DynamicFieldSet';
}

sub _FieldTemplateFileGet {
    my ( $Self, %Param ) = @_;

    return $Param{CustomerInterface}
        ? 'DynamicField/Customer/Set'
        : 'DynamicField/Agent/Set';
}

1;
