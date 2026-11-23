# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
# --
# $origin: otobo - 6037c557df653c401757d56455482d1cbab358c1 - Kernel/System/DynamicField/Driver/BaseDatabase.pm
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

package Kernel::System::DynamicField::Driver::BaseDatabase;

## nofilter(TidyAll::Plugin::OTOBO::Perl::ParamObject)

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use parent qw(Kernel::System::DynamicField::Driver::Base);

# core modules
# Rother OSS / DynamicFieldDatabaseExtensions
use List::Util qw(uniq);
# EO DynamicFieldDatabaseExtensions

# CPAN modules
use List::AllUtils qw(any last_index);

# OTOBO modules
use Kernel::Language              qw(Translatable);
use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
# Rother OSS / DynamicFieldDatabaseExtensions
    'Kernel::System::Cache',
# EO DynamicFieldDatabaseExtensions
    'Kernel::System::DB',
    'Kernel::System::DynamicFieldDB',
    'Kernel::System::DynamicFieldValue',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::DynamicField::Driver::BaseDatabase - base module for the Database dynamic field

=head1 DESCRIPTION

Base module for the Database dynamic field.

=head1 PUBLIC INTERFACE

Modules that are derived from this base module implement the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=cut

sub ValueGet {
    my ( $Self, %Param ) = @_;

    # get raw values of the dynamic field
    my $DFValue = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ValueGet(
        FieldID  => $Param{DynamicFieldConfig}{ID},
        ObjectID => $Param{ObjectID},
    );

    if ( $Param{DynamicFieldConfig}{Config}{Multiselect} ) {

        return if !$DFValue;
        return if !IsArrayRefWithData($DFValue);
        return if !IsHashRefWithData( $DFValue->[0] );

        my @ReturnData;
        for my $Item ( $DFValue->@* ) {
            if ( $Param{Set} ) {
                $ReturnData[ $Item->{IndexSet} ] //= [];
                push $ReturnData[ $Item->{IndexSet} ]->@*, $Item->{ValueText};
            }
            else {
                push @ReturnData, $Item->{ValueText};
            }
        }
        return \@ReturnData;
    }

    return $Self->ValueStructureFromDB(
        ValueDB    => $DFValue,
        ValueKey   => 'ValueText',
        Set        => $Param{Set},
        MultiValue => $Param{DynamicFieldConfig}{Config}{MultiValue},
        BaseArray  => !$Param{DynamicFieldConfig}{Config}{MultiValue},
    );
}

sub ValueSet {
    my ( $Self, %Param ) = @_;

    if ( $Param{DynamicFieldConfig}{Config}{Multiselect} ) {

        my $Value;
        if ( $Param{Set} ) {
            if ( IsArrayRefWithData( $Param{Value} ) ) {
                VALUEITEM:
                for my $ValueIndex ( 0 .. $#{ $Param{Value} } ) {
                    my $ValueItem = $Param{Value}[$ValueIndex];
                    if ( ref $ValueItem eq 'ARRAY' ) {
                        push $Value->@*, map { { IndexSet => $ValueIndex, ValueText => $_ } } $ValueItem->@*;
                    }
                    else {
                        push $Value->@*, map { { IndexSet => $ValueIndex, ValueText => $_ } } ( split /,/, $ValueItem // '' );
                    }
                }
            }
        }

        elsif ( ref $Param{Value} eq 'ARRAY' ) {
            $Value = [ map { { ValueText => $_ } } $Param{Value}->@* ];
        }
        else {
            $Value = [ map { { ValueText => $_ } } ( split /,/, $Param{Value} // '' ) ];
        }

        my $Success = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ValueSet(
            FieldID  => $Param{DynamicFieldConfig}->{ID},
            ObjectID => $Param{ObjectID},
            Value    => $Value,
            UserID   => $Param{UserID},
        );
        $Self->_TESSERADatabaseDisplayCacheInvalidate($Param{DynamicFieldConfig}{ID}, $Value) if $Success;
        return $Success;
    }

    my $DBValue = $Self->ValueStructureToDB(
        Value      => $Param{Value},
        ValueKey   => 'ValueText',
        Set        => $Param{Set},
        MultiValue => $Param{DynamicFieldConfig}{Config}{MultiValue},
    );

    my $Success = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ValueSet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
        Value    => $DBValue,
        UserID   => $Param{UserID},
    );
    $Self->_TESSERADatabaseDisplayCacheInvalidate($Param{DynamicFieldConfig}{ID}, $DBValue) if $Success;
    return $Success;
}

sub _TESSERADatabaseDisplayCacheInvalidate {
    my ($Self, $FieldID, $Rows) = @_;
    return if ref $Rows ne 'ARRAY';
    my %Seen;
    for my $Row (@{$Rows}) {
        next if ref $Row ne 'HASH' || !defined $Row->{ValueText} || $Seen{$Row->{ValueText}}++;
        for my $Interface (qw(AgentInterface CustomerInterface)) {
            $Kernel::OM->Get('Kernel::System::Cache')->Delete(
                Type => 'DynamicFieldDB',
                Key => "$FieldID-$Interface-$Row->{ValueText}",
            );
        }
    }
    return 1;
}

sub ValueIsDifferent {
    my ( $Self, %Param ) = @_;

    # handle array comparison
    if ( ref $Param{Value1} eq 'ARRAY' ) {

        # strip trailing empty values and map empty strings to undef
        #   for comparison of frontend value with database value
        my @Values = map { ( defined $_ && $_ eq '' ) ? undef : $_ } $Param{Value1}->@*;
        if ( any { defined $_ } @Values ) {
            splice( @Values, ( last_index { defined $_ } @Values ) + 1 );
        }
        else {
            @Values = ();
        }
        $Param{Value1} = \@Values;

        # special case where the values are different but they should be reported as equals
        if ( !defined $Param{Value2} && !$Param{Value1}->@* ) {
            return;
        }
    }

    if ( ref $Param{Value2} eq 'ARRAY' ) {

        # strip trailing empty values and map empty strings to undef
        #   for comparison of frontend value with database value
        my @Values = map { ( defined $_ && $_ eq '' ) ? undef : $_ } $Param{Value2}->@*;
        if ( any { defined $_ } @Values ) {
            splice( @Values, ( last_index { defined $_ } @Values ) + 1 );
        }
        else {
            @Values = ();
        }
        $Param{Value2} = \@Values;

        # special case where the values are different but they should be reported as equals
        if ( !defined $Param{Value1} && !$Param{Value2}->@* ) {
            return;
        }
    }

    # special cases where the values are different but they should be reported as equals
    # NOTE in case that either Value1 or Value2 is an array ref, we rely on stringified
    #   array references not being empty for this to work
    return if !defined $Param{Value1} && ( defined $Param{Value2} && $Param{Value2} eq '' );
    return if !defined $Param{Value2} && ( defined $Param{Value1} && $Param{Value1} eq '' );

    # Compare the results.
    return DataIsDifferent(
        Data1 => \$Param{Value1},
        Data2 => \$Param{Value2},
    );
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    # check values
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    my $Success;
    for my $Value (@Values) {
        $Success = $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->ValueValidate(
            Value => {
                ValueText => $Value,
            },
            UserID => $Param{UserID},
        );
        return if !$Success;
    }

    return $Success;
}

sub FieldValueValidate {
    my ( $Self, %Param ) = @_;

    # Check for defined value.
    if ( !defined $Param{Value} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Need Value in Database DynamicField!",
        );
        return;
    }

    my @Values;
    if ( IsArrayRefWithData( $Param{Value} ) ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    $Kernel::OM->ObjectParamAdd(
        'Kernel::System::DynamicFieldDB' => {
            DynamicFieldConfig => $Param{DynamicFieldConfig},
        },
    );
    my $DynamicFieldDBObject = $Kernel::OM->Get('Kernel::System::DynamicFieldDB');

    for my $Value (@Values) {
        my @SearchResult = $DynamicFieldDBObject->DatabaseSearchByConfig(
            Config => $Param{DynamicFieldConfig}->{Config},
            Search => $Value,
        );
        return if !IsArrayRefWithData( \@SearchResult );
    }

    return 1;
}

sub SearchSQLGet {
    my ( $Self, %Param ) = @_;

    my %Operators = (
        Equals            => '=',
        GreaterThan       => '>',
        GreaterThanEquals => '>=',
        SmallerThan       => '<',
        SmallerThanEquals => '<=',
    );

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Operators{ $Param{Operator} } ) {
        my $SQL = " $Param{TableAlias}.value_text $Operators{$Param{Operator}} '";
        $SQL .= $DBObject->Quote( $Param{SearchTerm} ) . "' ";
        return $SQL;
    }

    if ( $Param{Operator} eq 'Like' ) {

        my $SQL = $DBObject->QueryCondition(
            Key   => "$Param{TableAlias}.value_text",
            Value => $Param{SearchTerm},
        );

        return $SQL;
    }

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        'Priority' => 'error',
        'Message'  => "Unsupported Operator $Param{Operator}",
    );

    return;
}

sub SearchSQLOrderFieldGet {
    my ( $Self, %Param ) = @_;

    return "$Param{TableAlias}.value_text";
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig       = $Param{DynamicFieldConfig}->{Config};
    my $FieldName         = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel        = $Param{DynamicFieldConfig}->{Label};
    my $FieldLabelEscaped = $Param{LayoutObject}->Ascii2Html(
        Text => $Param{LayoutObject}{LanguageObject}->Translate($FieldLabel),
    );

    my $Value = '';

    # Prepare the value to be comma separated and set the field value.
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    elsif ( IsStringWithData( $Param{Value} ) ) {
        @Values = ( $Param{Value} );
    }

    if ( $FieldConfig->{Multiselect} ) {

        # prevent joining undef values
        @Values = map { $_ // '' } @Values;

        # Set new line separator.
        my $ItemSeparator = ', ';
        $Value = join $ItemSeparator, @Values;
    }
    else {
        $Value = \@Values;
    }

    # Extract the dynamic field value from the web request and set it if present. Do this after
    #   stored value is retrieved and processed, so it can be overridden if form has refreshed for
    #   some reasons (i.e. attachment has been uploaded). See bug#12453 for more information.
    my $FieldValue = $Self->EditFieldValueGet(
        %Param,
    );

    # set values from ParamObject if present
    if ( $FieldConfig->{MultiValue} ) {
        if ( $FieldValue->@* ) {
            $Value = $FieldValue;
        }
    }
    elsif ( defined $FieldValue ) {
        $Value = $FieldValue;
    }

    if ( !ref $Value ) {
        $Value = [$Value];
    }
    elsif ( !$Value->@* ) {
        $Value = [undef];
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldDB W50pc';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass .= ' ' . $Param{Class};
    }

    # set classes according to mandatory and acl hidden params
    if ( $Param{ACLHidden} && $Param{Mandatory} ) {
        $FieldClass .= ' Validate_Required_IfVisible';
    }
    elsif ( $Param{Mandatory} ) {
        $FieldClass .= ' Validate_Required';
    }

    # set error css class
    if ( $Param{ServerError} ) {
        $FieldClass .= ' ServerError';
    }

    # get translations
    my $DetailedSearchMsg = $Param{LayoutObject}->{LanguageObject}->Translate("Detailed search");
    my $DetailsMsg        = $Param{LayoutObject}->{LanguageObject}->Translate("Details");
    my $RemoveValueMsg    = $Param{LayoutObject}->{LanguageObject}->Translate("Remove value");

    # Handling for DF database in CustomerTicketProcess screen (see bug#14036).
    my $DynamicFieldDBContainer = 'DynamicFieldDBContainer';
    if ( $Param{ParamObject}->GetParam( Param => 'Action' ) eq 'CustomerTicketProcess' ) {
        $DynamicFieldDBContainer .= ' DynamicFieldDBContainerProcess';
    }

    my %FieldTemplateData = (
        FieldName               => $FieldName,
        FieldLabel              => $FieldLabelEscaped,
        DetailedSearchMsg       => $DetailedSearchMsg,
        FieldClass              => $FieldClass,
        DetailsMsg              => $DetailsMsg,
        RemoveValueMsg          => $RemoveValueMsg,
        DynamicFieldDBContainer => $DynamicFieldDBContainer,
        MultiValue              => $FieldConfig->{MultiValue} || 0,
        Readonly                => $Param{Readonly},
    );

    if ( $FieldConfig->{Tooltip} ) {
        $FieldTemplateData{WithTooltip} = 'oooWithTT';
    }

    my $AutoCompleteConfig = $Kernel::OM->Get('Kernel::Config')->Get('AutoComplete::Agent')
        ->{'DynamicFieldDBSearch'};
    my $ActiveAutoComplete = $AutoCompleteConfig->{AutoCompleteActive} || 0;

    my $FieldTemplateFile = $Param{CustomerInterface}
        ?
        'DynamicField/Customer/BaseDatabase'
        :
        'DynamicField/Agent/BaseDatabase';

    my %Error = (
        ServerError => $Param{ServerError},
        Mandatory   => $Param{Mandatory},
    );
    my @ResultHTML;
    for my $ValueIndex ( 0 .. $#{$Value} ) {
        $FieldTemplateData{FieldID} = $FieldConfig->{MultiValue} ? $FieldName . '_' . $ValueIndex : $FieldName;

        if ( !$ValueIndex ) {
            if ( $Error{ServerError} ) {
                $Error{DivIDServerError} = $FieldTemplateData{FieldID} . 'ServerError';
                $Error{ErrorMessage}     = Translatable( $Param{ErrorMessage} || 'This field is required.' );
            }
            if ( $Error{Mandatory} ) {
                $Error{DivIDMandatory}       = $FieldTemplateData{FieldID} . 'Error';
                $Error{FieldRequiredMessage} = Translatable('This field is required.');
            }
        }
        push @ResultHTML, $Param{LayoutObject}->Output(
            TemplateFile => $FieldTemplateFile,
            Data         => {
                %FieldTemplateData,
                %Error,
                Value => $Value->[$ValueIndex],
            },
        );
    }

    my $TemplateHTML;
    if ( $FieldConfig->{MultiValue} && !$Param{Readonly} ) {
        $FieldTemplateData{FieldID} = $FieldName . '_Template';

        if ( $Param{Mandatory} ) {
            $FieldClass .= ' ValidationIgnore';
        }

        $TemplateHTML = $Param{LayoutObject}->Output(
            TemplateFile => $FieldTemplateFile,
            Data         => {
                %FieldTemplateData,
                FieldClass => $FieldClass,
            },
        );
    }

    $Param{LayoutObject}->AddJSData(
        Key   => 'ActiveAutoComplete',
        Value => $ActiveAutoComplete,
    );

    # call EditLabelRender on the common Driver
    my $LabelString = $Self->EditLabelRender(
        %Param,
        Mandatory => $Param{Mandatory} || '0',
        FieldName => $FieldConfig->{MultiValue} ? $FieldName . '_0' : $FieldName,
    );

    my $Data = {
        Label => $LabelString,
    };

    # decide which structure to return
    if ( $FieldConfig->{MultiValue} ) {
        $Data->{MultiValue}         = \@ResultHTML;
        $Data->{MultiValueTemplate} = $TemplateHTML;
    }
    else {
        $Data->{Field} = $ResultHTML[0];
    }

    return $Data;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

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
        if ( $Param{DynamicFieldConfig}{Config}{MultiValue} ) {
            my @Data = $Param{ParamObject}->GetArray( Param => $FieldName );

            # delete the template value
            pop @Data;

            $Value = \@Data;
        }
        else {
            $Value = $Param{ParamObject}->GetParam( Param => $FieldName );
        }
    }

    if ( defined $Param{ReturnTemplateStructure} && $Param{ReturnTemplateStructure} eq 1 ) {
        return {
            $FieldName => $Value,
        };
    }

    # for this field the normal return and the ReturnValueStructure are the same
    return $Value;
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    # get the field value from the http request
    my $Value = $Self->EditFieldValueGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        ParamObject        => $Param{ParamObject},

        # not necessary for this Driver but place it for consistency reasons
        ReturnValueStructure => 1,
    );

    my $ServerError;

    # ref comparison because EditFieldValueGet returns an array reference except when using template value
    if ( ref $Value ne 'ARRAY' ) {
        $Value = [$Value];
    }

    if ( $Param{Mandatory} && !$Value->@* ) {
        return {
            ServerError => 1,
        };
    }

    for my $ValueItem ( @{$Value} ) {

        # perform necessary validations
        if ( $Param{Mandatory} && !$ValueItem ) {
            return {
                ServerError => 1,
            };
        }
    }

    # return resulting structure
    return {
        ServerError => $ServerError,
    };
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;

    # activate HTMLOutput when it wasn't specified
    my $HTMLOutput = $Param{HTMLOutput} // 1;

    # get raw Value strings from field value
    my @Values = !ref $Param{Value}
        ? ( $Param{Value} )
        : scalar $Param{Value}->@* ? $Param{Value}->@*
        :                            ('');

    $Param{ValueMaxChars} ||= '';
# Rother OSS / DynamicFieldDatabaseExtensions
    my $ExtendedValue = 0;
    if ( $Param{LayoutObject} ) {
        my %ExtendedValueActions = (
            'AgentITSMConfigItemZoom'    => 1,
            'AgentTicketZoom'            => 1,
            'CustomerITSMConfigItemZoom' => 1,
            'CustomerTicketZoom'         => 1,
        );
        $ExtendedValue = $ExtendedValueActions{$Param{LayoutObject}{Action}} ? 1 : 0;
    }

# EO DynamicFieldDatabaseExtensions

    my @ReadableValues;
    my @ReadableTitles;

# Rother OSS / DynamicFieldDatabaseExtensions
    # only initialize object if neccessary in an attempt to reduce database traffic
    my $DynamicFieldDBObject;
    my $ExtendedValueStructure = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFieldDB::ExtendedValueStructure');
    my @Headers = ('General');
    if ( $ExtendedValueStructure && $ExtendedValue ) {
        $Kernel::OM->ObjectParamAdd(
            'Kernel::System::DynamicFieldDB' => {
                DynamicFieldConfig => $Param{DynamicFieldConfig},
            },
        );
        $DynamicFieldDBObject = $Kernel::OM->Get('Kernel::System::DynamicFieldDB');

        # build header list
        my $DisplayfieldHeaders = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFieldDB::DisplayfieldHeaders');
        if ( IsArrayRefWithData($DisplayfieldHeaders) ) {
            @Headers = uniq (@Headers, $DisplayfieldHeaders->@*);
        }
    }

    # flag if headers were actually used, to be able to maintain standard behavior if not
    my $HeadersUsed = 0;
    my %HeaderfieldsHash;

    # set headers used flag
    if ( $ExtendedValueStructure ) {
        HEADER:
        for my $Header ( @Headers ) {

            # collect fields associated to current header
            my @Headerfields;

            # array for collecting strings per header field
            DISPLAYFIELD:
            for my $Counter ( 1 .. $Param{DynamicFieldConfig}->{Config}->{PossibleValues}->{ValueCounter} ) {

                next DISPLAYFIELD unless $Param{DynamicFieldConfig}->{Config}->{PossibleValues}->{"Displayfield_$Counter"};


                # NOTE using $Header for comparison instead of $SanitizedHeader because selected headers are not sanitized in AdminDynamicFieldDB
                if ( $Param{DynamicFieldConfig}->{Config}->{PossibleValues}->{"Displayfield_$Counter"} eq $Header ) {
                    push @Headerfields, {
                        Name => $Param{DynamicFieldConfig}->{Config}->{PossibleValues}->{"FieldLabel_$Counter"},
                        Type => $Param{DynamicFieldConfig}->{Config}->{PossibleValues}->{"FieldDatatype_$Counter"},
                    };
                }
            }

            # skip headers with no associated fields
            next HEADER unless @Headerfields;

            $HeadersUsed = 1;
            $HeaderfieldsHash{$Header} = \@Headerfields;
        }
    }
# EO DynamicFieldDatabaseExtensions

    for my $ValueItem (@Values) {
        $ValueItem //= '';

        # set title as value after update and before limit
        push @ReadableTitles, $ValueItem;

        # HTML Output transformation
        if ($HTMLOutput) {

# Rother OSS / DynamicFieldDatabaseExtensions
#             $ValueItem = $Param{LayoutObject}->Ascii2Html(
#                 Text => $ValueItem,
#                 Max  => $Param{ValueMaxChars},
#             );
            if ( $ExtendedValueStructure && $ExtendedValue ) {
                my $TemplateFile = '';
                my $Interface = $Param{LayoutObject}{SessionSource} // '';
                if ( $Param{LayoutObject}{SessionSource} ) {
                    if ( $Param{LayoutObject}{SessionSource} eq 'AgentInterface' ) {
                        $TemplateFile = 'DynamicField/Agent/BaseDatabaseDisplayValue';
                    }
                    elsif ( $Param{LayoutObject}{SessionSource} eq 'CustomerInterface' ) {
                        $TemplateFile = 'DynamicField/Customer/BaseDatabaseDisplayValue';
                    }
                }

                # fetch cached ReadableValue for item
                # NOTE $ValueItem is the PossibleValues element marked as Identifier
                my $CachedData = $Kernel::OM->Get('Kernel::System::Cache')->Get(
                    Type => 'DynamicFieldDB',
                    Key  => "$Param{DynamicFieldConfig}->{ID}-$Interface-$ValueItem",
                );
                if ( $CachedData ) {
                    $ValueItem = $CachedData;
                }
                else {

                    # perform database search
                    # NOTE using DatabaseSearchDetails to be able to restrict search to identifier
                    my $SearchResult = $DynamicFieldDBObject->DatabaseSearchDetails(
                        Config     => $Param{DynamicFieldConfig}->{Config},
                        Identifier => $ValueItem,
                    );

                    # array for collecting strings per header
                    HEADER:
                    for my $Header ( @Headers ) {

                        next HEADER unless IsArrayRefWithData($HeaderfieldsHash{$Header});

                        # sanitize header
                        my $SanitizedHeader = $Param{LayoutObject}->Ascii2Html(
                            Text => $Header,
                            Max  => $Param{ValueMaxChars} || '',
                        );

                        $Param{LayoutObject}->Block(
                            Name => 'HeaderSection',
                            Data => {
                                HeaderName => $SanitizedHeader,
                            },
                        );

                        # do not print header for General
                        if ( $SanitizedHeader ne 'General' ) {
                            $Param{LayoutObject}->Block(
                                Name => 'HeaderElement',
                                Data => {
                                    HeaderName => $SanitizedHeader,
                                },
                            );
                        }

                        for my $Field ( $HeaderfieldsHash{$Header}->@* ) {
                            my ($ResultItem) = grep { $_->{Label} eq $Field->{Name} } $SearchResult->@*;
                            my $ValueItem = $ResultItem->{Data};
                            if ( $Field->{Type} eq 'DATE' ) {
                                $ValueItem = $Param{LayoutObject}->{LanguageObject}->FormatTimeString(
                                    $ValueItem,
                                    'DateFormatShort',
                                );
                            }

                            # sanitize field data
                            my $CleanedData = $Param{LayoutObject}->Ascii2Html(
                                Text => $ValueItem,
                                Max  => $Param{ValueMaxChars} || '',
                            );
                            $Param{LayoutObject}->Block(
                                Name => 'ValueElement' ,
                                Data => {
                                    Data        => $ValueItem,
                                    CleanedData => $CleanedData,
                                },
                            );
                        }
                    }

                    # overwrite ReadableValue and set cache
                    if ( $HeadersUsed ) {

                        my $HeaderString = $Param{LayoutObject}->Output(
                            TemplateFile => $TemplateFile,
                        );

                        # NOTE $ValueItem is the PossibleValues element marked as Identifier
                        if ( $Param{DynamicFieldConfig}->{Config}->{CacheTTL} ) {
                            $Kernel::OM->Get('Kernel::System::Cache')->Set(
                                Type  => 'DynamicFieldDB',
                                Key   => "$Param{DynamicFieldConfig}->{ID}-$Interface-$ValueItem",
                                Value => $HeaderString,
                                TTL   => $Param{DynamicFieldConfig}->{Config}->{CacheTTL},
                            );
                        }

                        $ValueItem = $HeaderString;
                    }
                }
            }
# EO DynamicFieldDatabaseExtensions
        }
        else {
            if ( $Param{ValueMaxChars} && length($ValueItem) > $Param{ValueMaxChars} ) {
                $ValueItem = substr( $ValueItem, 0, $Param{ValueMaxChars} ) . '...';
            }
        }

        push @ReadableValues, $ValueItem;
    }

    my $ValueSeparator;
    my $Title = join( ', ', @ReadableTitles );

    # HTMLOutput transformations
    if ($HTMLOutput) {
        $Title = $Param{LayoutObject}->Ascii2Html(
            Text => $Title,
            Max  => $Param{TitleMaxChars} || '',
        );
        $ValueSeparator = '<br/>';
    }
    else {
        if ( $Param{TitleMaxChars} && length($Title) > $Param{TitleMaxChars} ) {
            $Title = substr( $Title, 0, $Param{TitleMaxChars} ) . '...';
        }
        $ValueSeparator = "\n";
    }
# Rother OSS / DynamicFieldDatabaseExtensions

    my $ValueStrg = '';
    if ( $HeadersUsed && $Param{LayoutObject}{SessionSource} && $Param{LayoutObject}{SessionSource} eq 'AgentInterface' ) {
        $ValueStrg = '<div class="DynamicFieldDBExtendedValue">' . join( $ValueSeparator, @ReadableValues ) . '</div>';
    }
    else {
        $ValueStrg = '' . join( $ValueSeparator, @ReadableValues );
    }
# EO DynamicFieldDatabaseExtensions

    # set field link from config
    my $Link        = $Param{DynamicFieldConfig}->{Config}->{Link}        || '';
    my $LinkPreview = $Param{DynamicFieldConfig}->{Config}->{LinkPreview} || '';

    # return a data structure
    return {
# Rother OSS / DynamicFieldDatabaseExtensions
#         Value       => '' . join( $ValueSeparator, @ReadableValues ),
        Value       => $ValueStrg,
# EO DynamicFieldDatabaseExtensions
        Title       => '' . $Title,
        Link        => $Link,
        LinkPreview => $LinkPreview,
        Class       => 'DynamicFieldType_Database',
    };
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldName         = 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel        = $Param{DynamicFieldConfig}->{Label};
    my $FieldLabelEscaped = $Param{LayoutObject}->Ascii2Html(
        Text => $Param{LayoutObject}{LanguageObject}->Translate($FieldLabel),
    );

    # set the field value
    my $Value = ( defined $Param{DefaultValue} ? $Param{DefaultValue} : '' );

    # get the field value, this function is always called after the profile is loaded
    my $FieldValue = $Self->SearchFieldValueGet(%Param);

    # set values from profile if present
    if ( defined $FieldValue ) {
        $Value = $FieldValue;
    }

    # check if value is an array reference (GenericAgent Jobs and NotificationEvents)
    if ( IsArrayRefWithData($Value) ) {
        $Value = @{$Value}[0];
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldDB';

    my $HTMLString = <<"EOF";
<input type="text" class="$FieldClass" id="${FieldName}" name="${FieldName}" title="$FieldLabelEscaped" value="$Value" />
EOF

    my $AdditionalText;
    if ( $Param{UseLabelHints} ) {
        $AdditionalText = 'e.g. Text or Te*t';
    }

    # call EditLabelRender on the common Driver
    my $LabelString = $Self->EditLabelRender(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        LayoutObject       => $Param{LayoutObject},
        FieldName          => $FieldName,
        AdditionalText     => $AdditionalText,
    );

    return {
        Field => $HTMLString,
        Label => $LabelString,
    };
}

sub SearchFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $Value;

    # get dynamic field value from param object
    if ( defined $Param{ParamObject} ) {
        $Value = $Param{ParamObject}->GetParam(
            Param => 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name}
        );
    }

    # otherwise get the value from the profile
    elsif ( defined $Param{Profile} ) {
        $Value = $Param{Profile}->{ 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} };
    }
    else {
        return;
    }

    if ( defined $Param{ReturnProfileStructure} && $Param{ReturnProfileStructure} eq 1 ) {
        return {
            'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} => $Value,
        };
    }

    return $Value;
}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # get field value
    my $Value = $Self->SearchFieldValueGet(%Param);

    # set operator
    my $Operator = 'Equals';

    # search for a wild card in the value
    if ( $Value && $Value =~ m{\*} ) {

        # change operator
        $Operator = 'Like';
    }

    # return search parameter structure
    return {
        Parameter => {
            $Operator => $Value,
        },
        Display => $Value,
    };
}

sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    return {
        Name    => $Param{DynamicFieldConfig}->{Label},
        Element => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name},
    };
}

sub StatsSearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};

    # set operator
    my $Operator = 'Equals';

    # search for a wild card in the value
    if ( $Value && $Value =~ m{\*} ) {

        # change operator
        $Operator = 'Like';
    }

    return {
        $Operator => $Value,
    };
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    # set Value and Title variables
    my $Value = '';
    my $Title = '';

    # check value
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    # prevent joining undefined values
    @Values = map { $_ // '' } @Values;

    # set new line separator
    my $ItemSeparator = ', ';

    # Output transformations
    $Value = join $ItemSeparator, @Values;

    # prepare title
    $Title = $Value;

    if ( $Param{TitleMaxChars} && length $Title > $Param{TitleMaxChars} ) {
        $Title = substr( $Title, 0, $Param{TitleMaxChars} ) . '...';
    }

    # return a data structure
    return {
        Value => $Value,
        Title => $Title,
    };
}

sub TemplateValueTypeGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # set the field types
    my $EditValueType   = 'SCALAR';
    my $SearchValueType = 'SCALAR';

    # return the correct structure
    if ( $Param{FieldType} eq 'Edit' ) {
        return {
            $FieldName => $EditValueType,
        };
    }
    elsif ( $Param{FieldType} eq 'Search' ) {
        return {
            'Search_' . $FieldName => $SearchValueType,
        };
    }
    else {
        return {
            $FieldName             => $EditValueType,
            'Search_' . $FieldName => $SearchValueType,
        };
    }
}

sub RandomValueSet {
    my ( $Self, %Param ) = @_;

    my $Value = int( rand(500) );

    my $Success = $Self->ValueSet(
        %Param,
        Value => $Value,
    );

    if ( !$Success ) {
        return {
            Success => 0,
        };
    }
    return {
        Success => 1,
        Value   => $Value,
    };
}

sub ObjectMatch {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # return false if field is not defined
    return 0 if ( !defined $Param{ObjectAttributes}->{$FieldName} );

    # return false if not match
    if ( $Param{ObjectAttributes}->{$FieldName} ne $Param{Value} ) {
        return 0;
    }

    return 1;
}

sub HistoricalValuesGet {
    my ( $Self, %Param ) = @_;

    # return the historical values from database
    return $Kernel::OM->Get('Kernel::System::DynamicFieldValue')->HistoricalValueGet(
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Text',
    );
}

sub ValueLookup {
    my ( $Self, %Param ) = @_;

    return $Param{Key} // '';
}

1;
