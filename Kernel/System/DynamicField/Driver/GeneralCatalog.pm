# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
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

package Kernel::System::DynamicField::Driver::GeneralCatalog;

## nofilter(TidyAll::Plugin::OTOBO::Perl::ParamObject)

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use parent qw(Kernel::System::DynamicField::Driver::BaseEntity);

# core modules

# CPAN modules

# OTOBO modules

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::System::DynamicField::Driver::GeneralCatalog - driver for the GeneralCatalog dynamic field

=head1 DESCRIPTION

DynamicFields GeneralCatalog Driver delegate. This dynamic field driver gives access to the lists
that are declared in the general catalog.

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=head2 new()

it is usually not necessary to explicitly create instances of dynamic field drivers.
Instances of the drivers are created in the constructor of the
dynamic field backend object C<Kernel::System::DynamicField::Backend>.

=cut

sub new {
    my ($Type) = @_;

    # allocate new hash for object
    my $Self = bless {}, $Type;

    # GeneralCatalog dynamic fields are stored in the database table attribute dynamic_field_value.value_int.
    $Self->{ValueType}      = 'Integer';
    $Self->{ValueKey}       = 'ValueInt';
    $Self->{TableAttribute} = 'value_int';

    # set field behaviors
    $Self->{Behaviors} = {
        'IsACLReducible'               => 1,
        'IsNotificationEventCondition' => 0,
        'IsSortable'                   => 1,
        'IsFiltrable'                  => 1,
        'IsStatsCondition'             => 0,
        'IsCustomerInterfaceCapable'   => 1,
        'IsLikeOperatorCapable'        => 0,    # only the item_ids are stored in dynamic_field_value
        'IsHiddenInTicketInformation'  => 0,
        'IsSetCapable'                 => 1,
    };

    # get the Dynamic Field Backend custom extensions
    my $DynamicFieldDriverExtensions = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFields::Extension::Driver::GeneralCatalog');

    EXTENSION:
    for my $ExtensionKey ( sort keys %{$DynamicFieldDriverExtensions} ) {

        # skip invalid extensions
        next EXTENSION if !IsHashRefWithData( $DynamicFieldDriverExtensions->{$ExtensionKey} );

        # create a extension config shortcut
        my $Extension = $DynamicFieldDriverExtensions->{$ExtensionKey};

        # check if extension has a new module
        if ( $Extension->{Module} ) {

            # check if module can be loaded
            if (
                !$Kernel::OM->Get('Kernel::System::Main')->RequireBaseClass( $Extension->{Module} )
                )
            {
                die "Can't load dynamic fields backend module"
                    . " $Extension->{Module}! $@";
            }
        }

        # check if extension contains more behaviors
        if ( IsHashRefWithData( $Extension->{Behaviors} ) ) {

            %{ $Self->{Behaviors} } = (
                %{ $Self->{Behaviors} },
                %{ $Extension->{Behaviors} }
            );
        }
    }

    return $Self;
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

    my $ItemList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Param{DynamicFieldConfig}{Config}{Class},
    );

    my @ReadableValues;
    my @ReadableTitles;
    for my $ValueItem (@Values) {
        $ValueItem //= '';

        # replace agent login with full name
        if ($ValueItem) {
            $ValueItem = $ItemList->{$ValueItem};
        }

        # set title as value after update and before limit
        push @ReadableTitles, $ValueItem;

        # HTML Output transformation
        if ($HTMLOutput) {
            $ValueItem = $Param{LayoutObject}->Ascii2Html(
                Text => $ValueItem,
                Max  => $Param{ValueMaxChars},
            );
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

    # return a data structure
    return {
        Value => join( $ValueSeparator, @ReadableValues ),
        Title => $Title,
        Link  => undef,                                      # this field type does not support the Link Feature
    };
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    my $Value = '';

    # check value
    my @Values;
    if ( ref $Param{Value} eq 'ARRAY' ) {
        @Values = @{ $Param{Value} };
    }
    else {
        @Values = ( $Param{Value} );
    }

    # my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ClassList();
    my $ItemList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Param{DynamicFieldConfig}{Config}{Class},
    );

    my @ReadableValues;

    for my $Item (@Values) {
        $Item //= '';

        # replace agent login with full name
        if ($Item) {
            $Item = $ItemList->{$Item};
        }

        push @ReadableValues, $Item || '';
    }

    # set new line separator
    my $ItemSeparator = ', ';

    # Output transformations
    $Value = join( $ItemSeparator, @ReadableValues );
    my $Title = $Value;

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

sub PossibleValuesGet {
    my ( $Self, %Param ) = @_;

    my $ItemList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Param{DynamicFieldConfig}{Config}{Class},
    );

    my %PossibleValues = $ItemList->%*;

    # set PossibleNone attribute
    my $FieldPossibleNone;
    if ( defined $Param{OverridePossibleNone} ) {
        $FieldPossibleNone = $Param{OverridePossibleNone};
    }
    else {
        $FieldPossibleNone = $Param{DynamicFieldConfig}{Config}{PossibleNone} || 0;
    }

    # set none value if defined on field config
    if ($FieldPossibleNone) {
        $PossibleValues{''} = '-';
    }

    return \%PossibleValues;
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    # get possible values and pass them on
    $Param{DynamicFieldConfig}{Config}{PossibleValues} = $Self->PossibleValuesGet(%Param);

    return $Self->SUPER::SearchFieldRender(%Param);
}

1;
