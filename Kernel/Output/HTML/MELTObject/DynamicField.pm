# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://ncs.com.sg
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

# TODO: Maybe rename to AgentZoom or similar
package Kernel::Output::HTML::MELTObject::DynamicField;

use strict;
use warnings;

# core modules
use List::Util qw(first);

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsHashRefWithData IsArrayRefWithData);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::MELTObject',
    'Kernel::System::Main',
);

=head1 NAME

Kernel::Output::HTML::MELTObject::DynamicField - MELT Object specific dynamic field output

=head1 DESCRIPTION

Functions to generate DynamicField HTML for MELTObjects

=head1 PUBLIC INTERFACE

=head2 new()

create a DynamicFieldOutput object. Do not use it directly, instead use:

    my $DynamicFieldOutputObject = $Kernel::OM->Get('Kernel::Output::HTML::MELTObject::DynamicField');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

=head2 PageRender()

Returns the HTML for a page of AgentMELTObjectZoom

    my $DynamicFieldHTML = $DynamicFieldOutputObject(
        MELTObject => $MELTObject,
        Definition => $Definition,
        PageRef    => $Page,        # either PageRef or Page is required
        Page       => 'Name',
    );

=cut

sub PageRender {
    my ( $Self, %Param ) = @_;

    # Check needed stuff.
    for my $Needed (qw(MELTObject Definition)) {
        if ( !IsHashRefWithData( $Param{$Needed} ) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $DefinitionRef = $Param{Definition}{DefinitionRef};
    my $Page          = $Param{PageRef} // first { $_->{Name} eq $Param{Page} } $DefinitionRef->{Pages}->@*;
    if ( !IsHashRefWithData($Page) || !IsArrayRefWithData( $Page->{Content} ) ) {
        my $ErrorMessage = defined $Param{PageRef}
            ? 'PageRef not valid.'
            : $Param{Page} ? "Page $Param{Page} not valid for DefinitionID $Param{Definition}{DefinitionID} of class $Param{Definition}{Class}."
            :                'Need Page or PageRef!';

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => $ErrorMessage,
        );

        return;
    }

    my %Layout;
    if ( $Page->{Layout} ) {
        $Layout{Columns} = $Page->{Layout}{Columns} ? int( $Page->{Layout}{Columns} ) : 1;

        # basic corrections for grid-template-rows
        my @Widths = $Page->{Layout}{ColumnWidth} ? ( $Page->{Layout}{ColumnWidth} =~ /([\d\.]*\w+)/g ) : ();

        if ( @Widths < $Layout{Columns} ) {
            push @Widths, ('1fr') x ( $Layout{Columns} - @Widths );
        }

        $Layout{Widths} = join( ' ', @Widths[ 0 .. $Layout{Columns} - 1 ] );
    }
    else {
        %Layout = (
            Columns => 1,
            Widths  => '1fr',
        );
    }

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    {
        my $Sections = $DefinitionRef->{Sections} // {};
        my %KeyToCss = qw/Row row Column column/;

        CONTENTBLOCK:
        for my $ContentBlock ( $Page->{Content}->@* ) {

            # The role is included in the section name
            my $Section = $Sections->{ $ContentBlock->{Section} };

            next CONTENTBLOCK unless $Section;

            my $GridArea;
            for my $Key (qw/Row Column/) {
                if ( $ContentBlock->{ $Key . 'Start' } ) {
                    $GridArea .= 'grid-' . $KeyToCss{$Key} . '-start:' . int( $ContentBlock->{ $Key . 'Start' } ) . ';';
                }
                if ( $ContentBlock->{ $Key . 'Span' } ) {
                    $GridArea .= 'grid-' . $KeyToCss{$Key} . '-end:span ' . int( $ContentBlock->{ $Key . 'Span' } ) . ';';
                }
            }

            $LayoutObject->Block(
                Name => 'ContentCell',
                Data => {
                    GridArea => $GridArea,
                    Type     => $Section->{Type}
                },
            );

            $Self->_SectionRender(
                %Param,
                LayoutObject => $LayoutObject,
                Section      => $Section,
            );
        }
    }

    return $LayoutObject->Output(
        TemplateFile => 'MELTObjectDetails',
        Data         => \%Layout,
    );
}

sub _SectionRender {
    my ( $Self, %Param ) = @_;

    if ( $Param{Section}{Type} ) {
        if ( $Param{Section}{Type} eq 'MELTObjectLinks' ) {
            return $Self->_RenderCILinks(%Param);
        }
        elsif ( $Param{Section}{Type} eq 'ReferencedSection' ) {
            return $Self->_RenderReferencedSection(%Param);
        }
        elsif ( $Param{Section}{Type} eq 'Description' ) {
            return $Self->_RenderDescriptionSection(%Param);
        }
        elsif ( $Param{Section}{Type} ne 'DynamicFields' ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Invalid section type '$Param{Section}{Type}'!",
            );

            return;
        }
    }

    # Get HTML from additional modules
    elsif ( $Param{Section}{Module} ) {
        my $Module = 'Kernel::Output::HTML::MELTObject::Section::' . $Param{Section}{Module};

        if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't load section module '$Module'",
            );

            return '';
        }

        my $Object = $Kernel::OM->Get($Module);
        my $HTML   = $Object->Run(%Param);
        $Param{LayoutObject}->Block(
            Name => 'GenericHTML',
            Data => {
                HTML => $HTML,
            },
        );

        return 1;
    }

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $RowHasValue = sub {
        return 1 if grep { defined $Param{MELTObject}{ 'DynamicField_' . $_->{DF} } } $_[0]->@*;
        return 0;
    };
    my $GridHasValue = sub {
        for my $Row ( $_[0]->@* ) {
            return 1 if $RowHasValue->($Row);
        }
        return 0;
    };

    my $DynamicFieldList;

    ROW:
    for my $Row ( $Param{Section}{Content}->@* ) {
        if ( $Row->{Header} ) {
            $Param{LayoutObject}->Block(
                Name => 'HeaderRow',
                Data => {
                    Header => $Row->{Header},
                }
            );

            $DynamicFieldList = 0;
        }

        elsif ( $Row->{DF} ) {
            next ROW if !defined $Param{MELTObject}{ 'DynamicField_' . $Row->{DF} };

            if ( !$DynamicFieldList ) {
                $Param{LayoutObject}->Block(
                    Name => 'FieldDisplayRow',
                    Data => {
                        Widths => '1fr 1fr',
                    }
                );

                $DynamicFieldList = 1;
            }

            my $DynamicField = $Param{Definition}{DynamicFieldRef}{ $Row->{DF} };

            next ROW if !$DynamicField;

            my $DisplayValue = $DynamicFieldBackendObject->DisplayValueRender(
                DynamicFieldConfig => $DynamicField,
                Value              => $Param{MELTObject}{ 'DynamicField_' . $Row->{DF} },
                LayoutObject       => $Param{LayoutObject},
                HTMLOutput         => 1,
            );

            $Param{LayoutObject}->Block(
                Name => 'FieldDisplayCell',
                Data => {
                    Label    => $Row->{Label} || $DynamicField->{Label},
                    Type     => 'Label',
                    CSSClass => $DynamicField->{FieldType} eq 'Set' ? 'DynamicFieldSetLabel' : undef,
                },
            );

            if ( $DynamicField->{FieldType} eq 'Set' || $DynamicField->{FieldType} eq 'RichText' ) {
                $Param{LayoutObject}->Block(
                    Name => 'FieldDisplayCell',
                    Data => {
                        $DisplayValue->%*,
                        Type => 'FullRow',
                    },
                );
            }
            elsif ( $DisplayValue->{Link} ) {
                $Param{LayoutObject}->Block(
                    Name => 'FieldDisplayCell',
                    Data => {
                        $DynamicField->{Name} => $DisplayValue->{Title},
                        $Param{MELTObject}->%*,
                        $DisplayValue->%*,

                        # Include unique parameter with dynamic field name in case of collision with others.
                        #   Please see bug#13362 for more information.
                        "DynamicField_$DynamicField->{Name}" => $DisplayValue->{Title},
                        Type                                 => 'ValueLink',
                    },
                );
            }
            elsif ( $DynamicField->{FieldType} eq 'Attachment' ) {
                $Param{LayoutObject}->Block(
                    Name => 'FieldDisplayCell',
                    Data => {
                        $DisplayValue->%*,
                        Type => 'ValueRaw',
                    },
                );
            }
            else {
                $Param{LayoutObject}->Block(
                    Name => 'FieldDisplayCell',
                    Data => {
                        $DisplayValue->%*,
                        Type => 'Value',
                    },
                );
            }
        }

        elsif ( $Row->{Grid} ) {
            next ROW if !$GridHasValue->( $Row->{Grid}{Rows} );

            my $Columns = int( $Row->{Grid}{Columns} );

            # basic corrections for grid-template-rows
            my @Widths = $Row->{Grid}{ColumnWidth} ? ( $Row->{Grid}{ColumnWidth} =~ /([\d\.]*\w+)/g ) : ();

            if ( @Widths < $Columns ) {
                push @Widths, ('1fr') x ( $Columns - @Widths );
            }

            $Param{LayoutObject}->Block(
                Name => 'FieldDisplayRow',
                Data => {
                    Widths => join( ' ', @Widths[ 0 .. $Columns - 1 ] ),

                }
            );

            GRIDROW:
            for my $GridRow ( $Row->{Grid}{Rows}->@* ) {
                next GRIDROW if !$RowHasValue->($GridRow);

                my $ColumnIndex = 0;
                my @DisplayValues;
                FIELD:
                for my $Field ( $GridRow->@* ) {
                    next FIELD if !$Field->{DF};

                    $ColumnIndex++;

                    my $DynamicField = $Param{Definition}{DynamicFieldRef}{ $Field->{DF} };

                    $DisplayValues[$ColumnIndex] = $DynamicFieldBackendObject->DisplayValueRender(
                        DynamicFieldConfig => $DynamicField,
                        Value              => $Param{MELTObject}{ 'DynamicField_' . $Field->{DF} },
                        LayoutObject       => $Param{LayoutObject},
                        HTMLOutput         => 1,
                    );

                    # TODO: grid column from definition
                    $Param{LayoutObject}->Block(
                        Name => 'FieldDisplayCell',
                        Data => {
                            Label      => $Field->{Label} || $DynamicField->{Label},
                            GridColumn => "grid-column-start: $ColumnIndex;",
                            Type       => 'Label',
                        }
                    );
                }

                for my $Index ( 1 .. $ColumnIndex ) {
                    $Param{LayoutObject}->Block(
                        Name => 'FieldDisplayCell',
                        Data => {
                            $DisplayValues[$Index]->%*,
                            GridColumn => "grid-column-start: $Index;",
                            Type       => 'Value',
                        },
                    );
                }
            }

            $DynamicFieldList = 0;
        }
    }

    return 1;
}

sub _RenderCILinks {
    my ( $Self, %Param ) = @_;

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    my $Direction = $Param{Section}{LinkedAs} || 'Source';
    my $Types     = IsArrayRefWithData( $Param{Section}{LinkTypes} ) ? $Param{Section}{LinkTypes} : undef;

    my $LinkedMELTObjects = $MELTObjectObject->LinkedMELTObjects(

        # TODO: What about versions
        MELTObjectID => $Param{MELTObject}{MELTObjectID},
        Direction    => $Direction,
        Types        => $Types,
        UserID       => 1,
    );

    return if !$LinkedMELTObjects;

    my %LinkedClasses;

    for my $Link ( $LinkedMELTObjects->@* ) {
        my $MELTObject = $MELTObjectObject->MELTObjectGet(
            MELTObjectID => $Link->{MELTObjectID},
        );

        # TODO: Think about sorting
        push @{ $LinkedClasses{ $MELTObject->{Class} } }, {
            Name         => $MELTObject->{Name},
            MELTObjectID => $Link->{MELTObjectID},
        };
    }

    # TODO: Access rights; classes for agents; for customers?
    # TODO: Configuration options for the tile; class restrictions, df restrictions, ?

    if ( $Param{Section}{Header} ) {
        $Param{LayoutObject}->Block(
            Name => 'HeaderRow',
            Data => {
                Header => $Param{Section}{Header},
            }
        );
    }

    my $Action = $Param{LayoutObject}{UserType} && $Param{LayoutObject}{UserType} eq 'Customer'
        ? 'CustomerMELTObjectZoom'
        : 'AgentMELTObjectZoom';

    for my $Class ( sort keys %LinkedClasses ) {
        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayRow',
            Data => {
                Widths => '1fr 1fr',
            }
        );

        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayCell',
            Data => {
                Label => $Class,
                Type  => 'Label',
            },
        );

        for my $CI ( sort { $a->{Name} cmp $b->{Name} } $LinkedClasses{$Class}->@* ) {
            $Param{LayoutObject}->Block(
                Name => 'FieldDisplayCell',
                Data => {
                    Title      => $CI->{Name},
                    Value      => $CI->{Name},
                    Link       => $Param{LayoutObject}{Baselink} . "Action=$Action;MELTObjectID=$CI->{MELTObjectID}",
                    Type       => 'ValueLink',
                    GridColumn => 'grid-column-start:2',
                },
            );
        }
    }

    return 1;
}

sub _RenderDescriptionSection {
    my ( $Self, %Param ) = @_;

    $Param{LayoutObject}->Block(
        Name => 'HeaderRow',
        Data => {
            Header => 'Description',
        },
    );

    # render description richtext editor
    $Param{LayoutObject}->Block(
        Name => 'FieldDisplayRow',
        Data => {
            Widths => '1fr',
        },
    );

    $Param{LayoutObject}->Block(
        Name => 'FieldDisplayCell',
        Data => {
            MELTObjectID => $Param{MELTObject}{MELTObjectID},
            VersionID    => $Param{MELTObject}{VersionID},
            Frontend     => $Param{LayoutObject}{UserType} eq 'User' ? 'Agent' : 'Customer',
            Type         => 'Iframe',
        },
    );

    return 1;
}

sub _RenderReferencedSection {
    my ( $Self, %Param ) = @_;

    return unless $Param{LayoutObject};

    my $ReferencedMELTObject = $Self->_ReferencedMELTObjectGet(
        Section    => $Param{Section},
        MELTObject => $Param{MELTObject},
    );
    return unless IsHashRefWithData($ReferencedMELTObject);

    # get definition of referenced MELT Object and pass it on to _SectionRender
    my $ReferencedCIDefinition = $Kernel::OM->Get('Kernel::System::MELTObject')->DefinitionGet(
        DefinitionID => $ReferencedMELTObject->{DefinitionID},
    );

    return unless $ReferencedCIDefinition->{DefinitionID};

    if ( $Param{Section}{FieldListPre} && IsArrayRefWithData( $Param{Section}{FieldListPre} ) ) {
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayRow',
            Data => {
                Widths => '1fr 1fr',
            }
        );

        for my $DFEntry ( $Param{Section}{FieldListPre}->@* ) {
            $Self->_RenderDF(
                Row                       => $DFEntry,
                MELTObject => $Param{MELTObject},
                Definition                => $Param{Definition},
                LayoutObject              => $Param{LayoutObject},
                DynamicFieldBackendObject => $DynamicFieldBackendObject,
            );
        }
    }

    $Self->_SectionRender(
        MELTObject => $ReferencedMELTObject,
        Definition   => $ReferencedCIDefinition,
        Section      => $ReferencedCIDefinition->{DefinitionRef}{Sections}{ $Param{Section}{SectionName} },
        LayoutObject => $Param{LayoutObject},
    );

    if ( $Param{Section}{FieldListPost} && IsArrayRefWithData( $Param{Section}{FieldListPost} ) ) {
        my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayRow',
            Data => {
                Widths => '1fr 1fr',
            }
        );

        for my $DFEntry ( $Param{Section}{FieldListPost}->@* ) {
            $Self->_RenderDF(
                Row                       => $DFEntry,
                MELTObject => $Param{MELTObject},
                Definition                => $Param{Definition},
                LayoutObject              => $Param{LayoutObject},
                DynamicFieldBackendObject => $DynamicFieldBackendObject,
            );
        }
    }

    return 1;
}

sub _ReferencedMELTObjectGet {
    my ( $Self, %Param ) = @_;

    # check needed params
    return unless IsHashRefWithData( $Param{MELTObject} );
    return unless IsHashRefWithData( $Param{Section} );

    # fetch config of referenced field
    my $ReferencedFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => $Param{Section}{ReferenceField},
    );

    return unless IsHashRefWithData($ReferencedFieldConfig);

    # fetch MELT Object depending on field type
    my %MELTObjectGetParams = (
        DynamicFields => 1,
    );
    if ( $ReferencedFieldConfig->{FieldType} eq 'MELTObject' ) {
        $MELTObjectGetParams{MELTObjectID} = $Param{MELTObject}{"DynamicField_$ReferencedFieldConfig->{Name}"}[0];
    }
    elsif ( $ReferencedFieldConfig->{FieldType} eq 'MELTObjectVersion' ) {
        $MELTObjectGetParams{VersionID} = $Param{MELTObject}{"DynamicField_$ReferencedFieldConfig->{Name}"}[0];
    }

    return unless ( $MELTObjectGetParams{MELTObjectID} || $MELTObjectGetParams{VersionID} );

    # return referenced MELT Object
    return $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
        %MELTObjectGetParams,
    );
}

sub _RenderDF {
    my ( $Self, %Param ) = @_;

    return if !$Param{Row}{DF};
    return if !defined $Param{MELTObject}{ 'DynamicField_' . $Param{Row}{DF} };

    my $DynamicField = $Param{Definition}{DynamicFieldRef}{ $Param{Row}{DF} };

    return if !$DynamicField;

    my $DisplayValue = $Param{DynamicFieldBackendObject}->DisplayValueRender(
        DynamicFieldConfig => $DynamicField,
        Value              => $Param{MELTObject}{ 'DynamicField_' . $Param{Row}{DF} },
        LayoutObject       => $Param{LayoutObject},
        HTMLOutput         => 1,
    );

    $Param{LayoutObject}->Block(
        Name => 'FieldDisplayCell',
        Data => {
            Label => $Param{Row}{Label} || $DynamicField->{Label},
            Type  => 'Label',
        },
    );

    if ( $DynamicField->{FieldType} eq 'Set' || $DynamicField->{FieldType} eq 'RichText' ) {
        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayCell',
            Data => {
                $DisplayValue->%*,
                Type => 'FullRow',
            },
        );
    }
    elsif ( $DisplayValue->{Link} ) {
        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayCell',
            Data => {
                $DynamicField->{Name} => $DisplayValue->{Title},
                $Param{MELTObject}->%*,
                $DisplayValue->%*,

                # Include unique parameter with dynamic field name in case of collision with others.
                #   Please see bug#13362 for more information.
                "DynamicField_$DynamicField->{Name}" => $DisplayValue->{Title},
                Type                                 => 'ValueLink',
            },
        );
    }
    elsif ( $DynamicField->{FieldType} eq 'Attachment' ) {
        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayCell',
            Data => {
                $DisplayValue->%*,
                Type => 'ValueRaw',
            },
        );
    }
    else {
        $Param{LayoutObject}->Block(
            Name => 'FieldDisplayCell',
            Data => {
                $DisplayValue->%*,
                Type => 'Value',
            },
        );
    }

    return 1;
}

1;

