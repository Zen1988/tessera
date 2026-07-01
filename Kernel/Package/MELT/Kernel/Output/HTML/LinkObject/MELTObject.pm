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

package Kernel::Output::HTML::LinkObject::MELTObject;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::Output::HTML::Layout;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::HTMLUtils',
    'Kernel::System::MELTObject',
    'Kernel::System::Log',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::Output::HTML::LinkObject::MELT Object - layout backend module

=head1 DESCRIPTION

All layout functions of link object (MELT Object)

=head2 new()

create an object

    $BackendObject = Kernel::Output::HTML::LinkObject::MELTObject->new(
        UserLanguage => 'en',
        UserID       => 1,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = bless {}, $Type;

    # check needed objects
    for my $Needed (qw(UserLanguage UserID)) {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    # We need our own LayoutObject instance to avoid blockdata collisions
    #   with the main page.
    $Self->{LayoutObject} = Kernel::Output::HTML::Layout->new( %{$Self} );

    # define needed variables
    $Self->{ObjectData} = {
        Object     => 'MELTObject',
        Realname   => 'MELTObject',
        ObjectName => 'SourceObjectID',
    };

    return $Self;
}

=head2 TableCreateComplex()

return an array with the block data

Return

    @BlockData = (
        {

            ObjectName  => 'MELTObjectID',
            ObjectID    => '123',

            Object    => 'MELTObject',
            Blockname => 'MELT Object Computer',
            Headline  => [
                {
                    Content => '',
                    Width   => 20,
                },
                {
                    Content => 'MELTObject#',
                    Width   => 100,
                },
                {
                    Content => 'Name',
                },
                {
                    Content => 'ZTSM Status',
                    Width   => 130,
                },
                {
                    Content => 'Created',
                    Width   => 130,
                },
            ],
            ItemList => [
                [
                    {
                        Type             => 'CurInciSignal',
                        Key              => '123',
                        Content          => 'Incident',
                        ZTSMStatusType => 'incident',
                    },
                    {
                        Type    => 'Link',
                        Content => '123',
                        Link    => 'Action=AgentMELTObjectZoom;MELTObjectID=123',
                    },
                    {
                        Type      => 'Text',
                        Content   => 'The Name of the MELT Object',
                        MaxLength => 50,
                    },
                    {
                        Type      => 'Text',
                        Content   => 'In Repair',
                        Translate => 1,
                    },
                    {
                        Type    => 'TimeLong',
                        Content => '2008-01-01 12:12:00',
                    },
                ],
                [
                    {
                        Type             => 'CurInciSignal',
                        Key              => '234',
                        Content          => 'Incident',
                        ZTSMStatusType => 'incident',
                    },
                    {
                        Type    => 'Link',
                        Content => '234',
                        Link    => 'Action=AgentMELTObjectZoom;MELTObjectID=234',
                    },
                    {
                        Type      => 'Text',
                        Content   => 'The Name of the MELT Object 234',
                        MaxLength => 50,
                    },
                    {
                        Type      => 'Text',
                        Content   => 'Productive',
                        Translate => 1,
                    },
                    {
                        Type    => 'TimeLong',
                        Content => '2007-11-11 12:12:00',
                    },
                ],
            ],
        },
    );

    @BlockData = $LinkObject->TableCreateComplex(
        ObjectLinkListWithData => $ObjectLinkListRef,
    );

=cut

sub TableCreateComplex {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ObjectLinkListWithData} || ref $Param{ObjectLinkListWithData} ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ObjectLinkListWithData!',
        );
        return;
    }

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $MELTObjectObject     = $Kernel::OM->Get('Kernel::System::MELTObject');

    # get and remember the ZTSM Status colors
    my $DeploymentStatesList = $GeneralCatalogObject->ItemList(
        Class => 'ZTSM::MELT::Status',
    );

    ITEMID:
    for my $ItemID ( sort keys %{$DeploymentStatesList} ) {

        # get ZTSM Status preferences
        my %Preferences = $GeneralCatalogObject->GeneralCatalogPreferencesGet(
            ItemID => $ItemID,
        );

        # check if a color is defined in preferences
        next ITEMID unless $Preferences{Color};
        my ($Color) = $Preferences{Color}->@*;
        next ITEMID unless $Color;

        # add color style definition
        my $ZTSMStatus = $DeploymentStatesList->{$ItemID};

        # remove any non ascii word characters
        $ZTSMStatus =~ s{ [^a-zA-Z0-9] }{_}msxg;

        # covert to lower case
        $Self->{ZTSMStatusColors}->{$ZTSMStatus} = lc $Color;
    }

    # Get the columns config.
    my $ColumnsConfig = $Kernel::OM->Get('Kernel::Config')->Get('LinkObject::MELTObject::ShowColumns');

    # Get the columns by class config.
    my $ColumnsByClassConfig = $Kernel::OM->Get('Kernel::Config')->Get('LinkObject::MELTObject::ShowColumnsByClass');

    # Get configured columns and reorganize them by class name.
    my %ColumnByClass;
    my %SignalColumnList;
    if ( $ColumnsByClassConfig && ref $ColumnsByClassConfig eq 'ARRAY' && @{$ColumnsByClassConfig} ) {

        NAME:
        for my $Name ( @{$ColumnsByClassConfig} ) {
            my ( $Class, $Column ) = split /::/, $Name, 2;

            next NAME if !$Column;

            # If signal columns are configured just for certain classes, add them to the beginning of ItemColumns array,
            # not to the array with other columns.
            if ( $Column eq 'CurInciSignal' || $Column eq 'CurDeplSignal' ) {
                $SignalColumnList{$Class}->{$Column} = 1;
                next NAME;
            }

            push @{ $ColumnByClass{$Class} }, $Column;
        }
    }

    # convert the list
    my %LinkList;
    for my $LinkType ( sort keys %{ $Param{ObjectLinkListWithData} } ) {

        # extract link type List
        my $LinkTypeList = $Param{ObjectLinkListWithData}->{$LinkType};

        for my $Direction ( sort keys %{$LinkTypeList} ) {

            # extract direction list
            my $DirectionList = $Param{ObjectLinkListWithData}->{$LinkType}->{$Direction};

            MELTObjectID:
            for my $MELTObjectID ( sort keys %{$DirectionList} ) {

                # extract class
                my $Class = $DirectionList->{$MELTObjectID}->{Class} || '';

                next MELTObjectID if !$Class;

                $LinkList{$Class}->{$MELTObjectID}->{Data} = $DirectionList->{$MELTObjectID};
            }
        }
    }

    my @BlockData;
    for my $Class ( sort { lc $a cmp lc $b } keys %LinkList ) {

        # extract MELT Object data
        my $MELTObjectList = $LinkList{$Class};

        # to store the column headline
        my @ShowColumnsHeadlines;

        # create the item list
        my @ItemList;
        for my $MELTObjectID (
            sort { $MELTObjectList->{$a}->{Data}->{Name} cmp $MELTObjectList->{$b}->{Data}->{Name} }
            keys %{$MELTObjectList}
            )
        {
            my $MELTObject = $MELTObjectObject->MELTObjectGet(
                MELTObjectID  => $MELTObjectID,
                DynamicFields => 1,
            );

            # make sure the column headline array is empty for each loop
            @ShowColumnsHeadlines = ();

            my @ItemColumns = (
                {
                    Type    => 'Link',
                    Content => $MELTObject->{Number},
                    Link    => $Self->{LayoutObject}->{Baselink}
                        . 'Action=AgentMELTObjectZoom;MELTObjectID='
                        . $MELTObjectID,
                    Title => "MELTObject# $MELTObject->{Number} ($MELTObject->{Class}): $MELTObject->{Name}",
                },
            );

            # Add columns from 'LinkObject::MELTObject::ShowColumns' setting to the current CI class
            # if it does not contain them. Signal columns is saved in hash because they will be added later.
            COLUMNCONFIG:
            for my $Column ( @{$ColumnsConfig} ) {

                if ( $Column eq 'CurInciSignal' || $Column eq 'CurDeplSignal' ) {
                    $SignalColumnList{$Class}->{$Column} = 1;
                }
                elsif ( !grep { $_ eq $Column } @{ $ColumnByClass{$Class} } ) {
                    push @{ $ColumnByClass{$Class} }, $Column;
                }
            }

            # Add signal columns to the beginning of the array if needed.
            if ( $SignalColumnList{$Class}->{CurDeplSignal} ) {
                unshift @ItemColumns, {
                    Type    => 'CurDeplSignal',
                    Key     => $MELTObjectID,
                    Content => $MELTObject->{ZTSMStatus},
                };
            }
            if ( $SignalColumnList{$Class}->{CurInciSignal} ) {
                unshift @ItemColumns, {
                    Type             => 'CurInciSignal',
                    Key              => $MELTObjectID,
                    Content          => $MELTObject->{ZTSMStatus},
                    ZTSMStatusType => $MELTObject->{ZTSMStatusType},
                };
            }

            # these columns will be added if no class based column config is defined
            my @AdditionalDefaultItemColumns = (
                {
                    Type      => 'Text',
                    Content   => $MELTObject->{Name},
                    MaxLength => 50,
                },
                {
                    Type      => 'Text',
                    Content   => $MELTObject->{ZTSMStatus},
                    Translate => 1,
                },
                {
                    Type    => 'TimeLong',
                    Content => $MELTObject->{CreateTime},
                },
            );

            # individual column config for this class exists
            # TODO: incorporate dynamic field data
            if (0) { }

            #            if ( $ColumnByClass{$Class} ) {
            #
            #                # convert the XML data into a hash
            #                my $ExtendedVersionData = $Self->{LayoutObject}->XMLData2Hash(
            #                    XMLDefinition => $VersionXMLData->{XMLDefinition},
            #                    XMLData       => $VersionXMLData->{XMLData}->[1]->{Version}->[1],
            #                    Attributes    => $ColumnByClass{$Class},
            #                );
            #
            #                COLUMN:
            #                for my $Column ( @{ $ColumnByClass{$Class} } ) {
            #
            #                    # process some non-xml attributes
            #                    if ( $Version->{$Column} ) {
            #
            #                        # handle the CI name
            #                        if ( $Column eq 'Name' ) {
            #
            #                            # add the column
            #                            push @ItemColumns, {
            #                                Type      => 'Text',
            #                                Content   => $Version->{Name},
            #                                MaxLength => 50,
            #                            };
            #
            #                            # add the headline
            #                            push @ShowColumnsHeadlines, {
            #                                Content => 'Name',
            #                            };
            #                        }
            #
            #                        # special translation handling
            #                        elsif ( $Column eq 'ZTSMStatus' ) {
            #
            #                            # add the column
            #                            push @ItemColumns, {
            #                                Type      => 'Text',
            #                                Content   => $Version->{$Column},
            #                                Translate => 1,
            #                            };
            #
            #                            # add the headline
            #                            push @ShowColumnsHeadlines, {
            #                                Content => 'ZTSM Status',
            #                            };
            #                        }
            #
            #                        # special translation handling
            #                        elsif ( $Column eq 'ZTSMStatus' ) {
            #
            #                            # add the column
            #                            push @ItemColumns, {
            #                                Type      => 'Text',
            #                                Content   => $Version->{$Column},
            #                                Translate => 1,
            #                            };
            #
            #                            # add the headline
            #                            push @ShowColumnsHeadlines, {
            #                                Content => 'ZTSM Status',
            #                            };
            #                        }
            #
            #                        # special translation handling
            #                        elsif ( $Column eq 'Class' ) {
            #
            #                            # add the column
            #                            push @ItemColumns, {
            #                                Type      => 'Text',
            #                                Content   => $Version->{$Column},
            #                                Translate => 1,
            #                            };
            #
            #                            # add the headline
            #                            push @ShowColumnsHeadlines, {
            #                                Content => 'Class',
            #                            };
            #                        }
            #
            #                        # special date/time handling
            #                        elsif ( $Column eq 'CreateTime' ) {
            #
            #                            # add the column
            #                            push @ItemColumns, {
            #                                Type    => 'TimeLong',
            #                                Content => $Version->{CreateTime},
            #                            };
            #
            #                            # add the headline
            #                            push @ShowColumnsHeadlines, {
            #                                Content => 'Created',
            #                            };
            #                        }
            #
            #                        next COLUMN;
            #                    }
            #
            #                    # convert to ascii text in case the value contains html
            #                    my $Value = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(
            #                        String => $ExtendedVersionData->{$Column}->{Value},
            #                    ) || '';
            #
            #                    # convert all whitespace and newlines to single spaces
            #                    $Value =~ s{ \s+ }{ }gxms;
            #
            #                    # add the column
            #                    push @ItemColumns, {
            #                        Type    => 'Text',
            #                        Content => $Value,
            #                    };
            #
            #                    # add the headline
            #                    push @ShowColumnsHeadlines, {
            #                        Content => $ExtendedVersionData->{$Column}->{Name} || '',
            #                    };
            #                }
            #            }

            # individual column config for this class does not exist,
            # so the default columns will be used
            else {

                # add the default columns
                push @ItemColumns, @AdditionalDefaultItemColumns;

                # add the default column headlines
                @ShowColumnsHeadlines = (
                    {
                        Content => 'Name',
                    },
                    {
                        Content => 'ZTSM Status',
                        Width   => 130,
                    },
                    {
                        Content => 'Created',
                        Width   => 130,
                    },
                );
            }

            push @ItemList, \@ItemColumns;
        }

        return if !@ItemList;

        # define the block data
        my %Block = (
            Object    => $Self->{ObjectData}->{Object},
            Blockname => $Self->{ObjectData}->{Realname} . ' (' . $Class . ')',
            Headline  => [
                {
                    Content => 'MELTObject#',
                    Width   => 100,
                },
            ],
            ItemList => \@ItemList,
        );

        # Add 'CurInciSignal' and 'CurDeplSignal' columns to the beginning of headline if needed.
        if ( $SignalColumnList{$Class}->{CurDeplSignal} ) {
            unshift @{ $Block{Headline} }, {
                Content => 'ZTSM Status',
                Width   => 20,
            };
        }
        if ( $SignalColumnList{$Class}->{CurInciSignal} ) {
            unshift @{ $Block{Headline} }, {
                Content => 'ZTSM Status',
                Width   => 20,
            };
        }

        # add the column headlines
        push @{ $Block{Headline} }, @ShowColumnsHeadlines;

        push @BlockData, \%Block;
    }

    return @BlockData;
}

=head2 TableCreateSimple()

return a hash with the link output data

Return

    %LinkOutputData = (
        Normal::Source => {
            MELTObject => [
                {
                    Type    => 'Link',
                    Content => 'CI:55555',
                    Title   => 'MELTObject# 555555: The MELT Object name',
                    Css     => 'style="text-decoration: line-through"',
                },
                {
                    Type    => 'Link',
                    Content => 'CI:22222',
                    Title   => 'MELTObject# 22222: Title of config name 22222',
                },
            ],
        },
        ParentChild::Target => {
            MELTObject => [
                {
                    Type    => 'Link',
                    Content => 'CI:77777',
                    Title   => 'MELTObject# 77777: MELT Object name',
                },
            ],
        },
    );

    %LinkOutputData = $LinkObject->TableCreateSimple(
        ObjectLinkListWithData => $ObjectLinkListRef,
    );

=cut

sub TableCreateSimple {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ObjectLinkListWithData} || ref $Param{ObjectLinkListWithData} ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ObjectLinkListWithData!',
        );
        return;
    }

    my %LinkOutputData;
    for my $LinkType ( sort keys %{ $Param{ObjectLinkListWithData} } ) {

        # extract link type List
        my $LinkTypeList = $Param{ObjectLinkListWithData}->{$LinkType};

        for my $Direction ( sort keys %{$LinkTypeList} ) {

            # extract direction list
            my $DirectionList = $Param{ObjectLinkListWithData}->{$LinkType}->{$Direction};

            my @ItemList;
            for my $MELTObjectID ( sort { $a <=> $b } keys %{$DirectionList} ) {

                # extract MELT Object data
                my $Version = $DirectionList->{$MELTObjectID};

                # define item data
                my %Item = (
                    Type    => 'Link',
                    Content => 'CI:' . $Version->{Number},
                    Title   => "MELTObject# $Version->{Number} ($Version->{Class}): $Version->{Name}",
                    Link    => $Self->{LayoutObject}->{Baselink}
                        . 'Action=AgentMELTObjectZoom;MELTObjectID='
                        . $MELTObjectID,
                );

                push @ItemList, \%Item;
            }

            # add item list to link output data
            $LinkOutputData{ $LinkType . '::' . $Direction }->{MELTObject} = \@ItemList;
        }
    }

    return %LinkOutputData;
}

=head2 ContentStringCreate()

return a output string

    my $String = $LayoutObject->ContentStringCreate(
        ContentData => $HashRef,
    );

=cut

sub ContentStringCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ContentData} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ContentData!',
        );
        return;
    }

    # extract content
    my $Content = $Param{ContentData};

    if ( $Content->{Type} ne 'CurInciSignal' && $Content->{Type} ne 'CurDeplSignal' ) {
        return;
    }

    my $String;
    if ( $Content->{Type} eq 'CurInciSignal' ) {

        # set incident signal
        my %InciSignals = (
            incident    => 'redled',
            operational => 'greenled',
            unknown     => 'grayled',
            warning     => 'yellowled',
        );

        # investigate current incident signal
        $Content->{ZTSMStatusType} ||= 'unknown';
        my $CurInciSignal = $InciSignals{ $Content->{ZTSMStatusType} };
        $CurInciSignal ||= $InciSignals{unknown};

        $String = $Self->{LayoutObject}->Output(
            Template => '<div class="Flag Small" title="[% Translate(Data.ZTSMStatus) | html %]"> '
                . '<span class="[% Data.CurInciSignal | html %]"></span> </div>',
            Data => {
                CurInciSignal => $CurInciSignal,
                ZTSMStatus  => $Content->{Content} || '',
            },
        );
    }
    elsif ( $Content->{Type} eq 'CurDeplSignal' ) {

        # convert ZTSM Status to a web safe CSS class
        my $ZTSMStatus = $Content->{Content} || '';
        $ZTSMStatus =~ s{ [^a-zA-Z0-9] }{_}msxg;

        # get the color of the deplyment state if defined
        my $ZTSMStatusColor = ( $Self->{ZTSMStatusColors}->{$ZTSMStatus} || '' ) =~ s/[^0-9a-f]//msgr;

        my $Template = '<div class="Flag Small" title="[% Translate(Data.ZTSMStatus) | html %]"> ';

        # check if color is defined and set the style class
        if ($ZTSMStatusColor) {
            $Template .= <<"END";
<style>
    .Flag span.$ZTSMStatus {
        background-color: #$ZTSMStatusColor;
    }
</style>
END
        }

        $Template .= "<span class=\"ZTSMStatus $ZTSMStatus\"></span> </div>";

        $String = $Self->{LayoutObject}->Output(
            Template => $Template,
            Data     => {
                ZTSMStatus => $Content->{Content} || '',
            },
        );
    }

    return $String;
}

=head2 SelectableObjectList()

return an array hash with C<selectable> objects

Return

    @SelectableObjectList = (
        {
            Key      => '-',
            Value    => 'MELTObject',
            Disabled => 1,
        },
        {
            Key   => 'MELTObject::25',
            Value => 'MELTObject::Computer',
        },
        {
            Key   => 'MELTObject::26',
            Value => 'MELTObject::Software',
        },
        {
            Key   => 'MELTObject::27',
            Value => 'MELTObject::Network',
        },
    );

    @SelectableObjectList = $LinkObject->SelectableObjectList(
        Selected => $Identifier,  # (optional)
    );

=cut

sub SelectableObjectList {
    my ( $Self, %Param ) = @_;

    # define headline
    my @ObjectSelectList;

    # get class list
    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::MELT::Class',
    );

    return if !$ClassList;
    return if ref $ClassList ne 'HASH';

    # get the config with the default subobjects
    my $DefaultSubobject = $Kernel::OM->Get('Kernel::Config')->Get('LinkObject::DefaultSubObject') || {};

    CLASSID:
    for my $ClassID ( sort { lc $ClassList->{$a} cmp lc $ClassList->{$b} } keys %{$ClassList} ) {

        # show class only if user has access rights
        my $HasAccess = $Kernel::OM->Get('Kernel::System::MELTObject')->Permission(
            Scope   => 'Class',
            ClassID => $ClassID,
            UserID  => $Self->{UserID},
            Type    => 'ro',
        );

        next CLASSID if !$HasAccess;

        my $Class      = $ClassList->{$ClassID} || '';
        my $Identifier = $Self->{ObjectData}->{Object} . '::' . $ClassID;

        # set selected flag
        my $Selected;
        if ( $Param{Selected} ) {

            if ( $Param{Selected} eq $Identifier ) {
                $Selected = 1;
            }
            elsif (
                $Param{Selected} eq $Self->{ObjectData}->{Object}
                && $DefaultSubobject->{ $Self->{ObjectData}->{Object} }
                )
            {

                # extract default class name
                my $DefaultClass = $DefaultSubobject->{ $Self->{ObjectData}->{Object} } || '';

                # check class
                if ( $DefaultClass eq $Class ) {
                    $Selected = 1;
                }
            }
        }

        # create row
        my %Row = (
            Key      => $Identifier,
            Value    => $Self->{ObjectData}->{Realname} . '::' . $Class,
            Selected => $Selected,
        );

        push @ObjectSelectList, \%Row;
    }

    # only add headline if there are MELT Object classes
    # where the user has the permission to use them
    if (@ObjectSelectList) {

        # add headline as first array element
        unshift @ObjectSelectList, {
            Key      => '-',
            Value    => $Self->{ObjectData}->{Realname},
            Disabled => 1,
        };
    }

    return @ObjectSelectList;
}

=head2 SearchOptionList()

return an array hash with search options

Return

    @SearchOptionList = (
        {
            Key       => 'Number',
            Name      => 'MELTObject#',
            InputStrg => $FormString,
            FormData  => '1234',
        },
        {
            Key       => 'Name',
            Name      => 'Name',
            InputStrg => $FormString,
            FormData  => 'BlaBla',
        },
    );

    @SearchOptionList = $LinkObject->SearchOptionList(
        SubObject => '25',  # (optional)
    );

=cut

sub SearchOptionList {
    my ( $Self, %Param ) = @_;

    # search option list
    my @SearchOptionList = (
        {
            Key  => 'Number',
            Name => 'MELTObject#',
            Type => 'Text',
        },
        {
            Key  => 'Name',
            Name => 'Name',
            Type => 'Text',
        },
        {
            Key  => 'ZTSMStatusIDs',
            Name => 'ZTSM Status',
            Type => 'List',
        },
        {
            Key  => 'ZTSMStatusIDs',
            Name => 'ZTSM Status',
            Type => 'List',
        },
    );

    # add object dependence attributes
    #if ( $Param{SubObject} ) {
    #
    #    # get class list
    #    my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
    #        Class => 'ZTSM::MELT::Class',
    #    );
    #
    #    if ( $ClassList && $ClassList eq 'HASH' ) {
    #
    #        # add here the search attributes of the subobject!
    #    }
    #}

    # add formkey
    for my $Row (@SearchOptionList) {
        $Row->{FormKey} = 'SEARCH::' . $Row->{Key};
    }

    # add form data and input string
    ROW:
    for my $Row (@SearchOptionList) {

        # prepare text input fields
        if ( $Row->{Type} eq 'Text' ) {

            # get form data
            $Row->{FormData} = $Kernel::OM->Get('Kernel::System::Web::Request')->GetParam( Param => $Row->{FormKey} );

            # parse the input text block
            $Self->{LayoutObject}->Block(
                Name => 'InputText',
                Data => {
                    Key   => $Row->{FormKey},
                    Value => $Row->{FormData} || '',
                },
            );

            # add the input string
            $Row->{InputStrg} = $Self->{LayoutObject}->Output(
                TemplateFile => 'LinkObject',
            );

            next ROW;
        }

        # prepare list boxes
        if ( $Row->{Type} eq 'List' ) {

            # get form data
            my @FormData = $Kernel::OM->Get('Kernel::System::Web::Request')->GetArray( Param => $Row->{FormKey} );
            $Row->{FormData} = \@FormData;

            # prepare ZTSM Status list
            my %ListData;
            if ( $Row->{Key} eq 'ZTSMStatusIDs' ) {

                # get ZTSM Status list
                my $ZTSMStatusList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                    Class => 'ZTSM::MELT::Status',
                );

                # add list
                if ( $ZTSMStatusList && ref $ZTSMStatusList eq 'HASH' ) {
                    %ListData = %{$ZTSMStatusList};
                }
            }

            # prepare ZTSM Status list
            elsif ( $Row->{Key} eq 'ZTSMStatusIDs' ) {

                # get ZTSM Status list
                my $ZTSMStatusList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                    Class => 'ZTSM::MELT::Status',
                );

                # add list
                if ( $ZTSMStatusList && ref $ZTSMStatusList eq 'HASH' ) {
                    %ListData = %{$ZTSMStatusList};
                }
            }

            # add the input string
            $Row->{InputStrg} = $Self->{LayoutObject}->BuildSelection(
                Data       => \%ListData,
                Name       => $Row->{FormKey},
                SelectedID => $Row->{FormData},
                Size       => 3,
                Multiple   => 1,
                Class      => 'Modernize',
            );

            next ROW;
        }
    }

    return @SearchOptionList;
}

1;

