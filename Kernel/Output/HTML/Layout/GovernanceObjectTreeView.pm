# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://ncs.com.sg
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

package Kernel::Output::HTML::Layout::GovernanceObjectTreeView;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::Output::HTML::Layout::GovernanceObjectTreeView - all GovernanceObjectTreeView-related HTML functions

=head1 DESCRIPTION

All GovernanceObjectTreeView-related HTML functions

=head1 PUBLIC INTERFACE

=head2 GenerateHierarchyGraph()

creates HTML containing the information needed for drawing the graph.

    my $CanvasHTML = $LayoutObject->GenerateHierarchyGraph(
        Depth          => 2, # depth level
        GovernanceObjectID   => 1  # source Governance Object ID
        VersionID      => 1  # source Governance Object version ID
    );

=cut

sub GenerateHierarchyGraph {
    my ( $Self, %Param ) = @_;

    my $LayoutObject     = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
        GovernanceObjectID => $Param{GovernanceObjectID},,
        VersionID    => $Param{VersionID},
    );

    if ( !$GovernanceObject ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Could not get GovernanceObject.'
        );

        return;
    }

    $Self->{CITreeMaxDepth} = 1;

    my @LinkOutputDataTargets = ([
        {
            $GovernanceObject->%*,
            ID => $Self->_GenerateID( $GovernanceObject->%* ),
        },
    ]);
    my @LinkOutputDataSources = @LinkOutputDataTargets;

    # Build Levels Down (Targets)
    $Self->GetCISubTreeData(
        LinkOutputData => \@LinkOutputDataTargets,    # will be modified
        Init           => 1,
        Depth          => $Param{Depth},
        Direction      => 'Source'
    );

    # Build Levels Up (Sources)
    $Self->GetCISubTreeData(
        LinkOutputData => \@LinkOutputDataSources,    # will be modified
        Init           => 1,
        Depth          => $Param{Depth},
        Direction      => 'Target'
    );

    # The needed data has been collected.
    # The following just passes the two trees to the web page.

    # for the sources start with the deepest level
    my @LinkDataSource;    # will be used in JavaScript for drawing the arcs
    for my $Level ( reverse ( 1 .. $#LinkOutputDataSources ) ) {
        my $Elements = $LinkOutputDataSources[ $Level ];

        $LayoutObject->Block(
            Name  => 'ChildSourceElementsLevel',
            Level => $Level
        );

        for my $Element ( $Elements->@* ) {
            my $ID = "$Element->{ID}_S$Level";    # only link to the next or previous level, the separator _S indicates Source
            $LayoutObject->Block(
                Name => 'ChildSourceElements',
                Data => {
                    Name         => $Element->{Name},
                    Contents     => $Element->{Contents},
                    GovernanceObjectID => $Element->{GovernanceObjectID},
                    ID           => $ID,
                    SessionID    => $Param{SessionID}
                }
            );

            # need to consider the special case when linking to the origin
            my $NextLevel = $Level - 1;

            for my $Link ( @{ $Element->{Link} // [] } ) {
                my $LinkedToElement = $NextLevel ? $Link->{LinkedTo} . '_S' . $NextLevel : $Link->{LinkedTo};
                push @LinkDataSource, join ',', $LinkedToElement, $ID, $Link->{LinkType};
            }
        }
    }

    # Level 0
    # Give information about the root node to the web page.
    # Dynamic field info is not needed.
    {
        my $Contents = $Self->_GetContents(
            Attributes => [ 'VersionString', $Self->CITreeDefaultAttributes ],    # the root has always a version
            GovernanceObject => $GovernanceObject,
        );

        $LayoutObject->Block(
            Name => 'OriginElement',
            Data => {
                Name         => $GovernanceObject->{Name},
                Contents     => $Contents,
                GovernanceObjectID => $GovernanceObject->{GovernanceObjectID},
                ID           => $LinkOutputDataSources[0][0]{ID},
            }
        );
    }

    # for the targets start with the lowest level
    my @LinkDataTarget;    # will be used in JavaScript for drawing the arcs
    for my $Level ( 1 .. $#LinkOutputDataTargets ) {
        my $Elements = $LinkOutputDataTargets[ $Level ];

        $LayoutObject->Block(
            Name => 'ChildTargetElementsLevel',
            Data => {
                Level => $Level
            }
        );

        for my $Element ( $Elements->@* ) {
            my $ID = "$Element->{ID}_T$Level";    # only link to the next or previous level, the separator _T indicates Target
            $LayoutObject->Block(
                Name => 'ChildTargetElements',
                Data => {
                    Name         => $Element->{Name},
                    Contents     => $Element->{Contents},
                    GovernanceObjectID => $Element->{GovernanceObjectID},
                    ID           => $ID,
                    SessionID    => $Param{SessionID}
                }
            );

            # need to consider the special case when linking to the origin
            my $PreviousLevel = $Level - 1;
            for my $Link ( @{ $Element->{Link} // [] } ) {
                my $LinkedToElement = $PreviousLevel ? $Link->{LinkedTo} . '_T' . $PreviousLevel : $Link->{LinkedTo};
                push @LinkDataTarget, join ',', $ID, $LinkedToElement, $Link->{LinkType};
            }
        }
    }

    return $LayoutObject->Output(
        TemplateFile => 'GovernanceObjectTreeView/GovernanceObjectTreeViewGraph',
        Data         => {
            MaxDepth       => $Self->{CITreeMaxDepth},
            LinkDataSource => join( ';', @LinkDataSource ),
            LinkDataTarget => join( ';', @LinkDataTarget ),
        }
    );
}

=head2 CITreeDefaultAttributes()

Get a list of attributes that are shown in the nodes.

    my @Attributes = $LayoutObject->CITreeDefaultAttributes();

=cut

sub CITreeDefaultAttributes {
    return qw/Class ZTSMStatus ZTSMStatus ZTSMStatusType/;
}

# build Children structure
sub GetCISubTreeData {
    my ( $Self, %Param ) = @_;

    my $LinkOutputData = $Param{LinkOutputData};    # will be modified
    my $Depth          = $Param{Depth};
    my $Init           = $Param{Init};
    my $Direction      = $Param{Direction};

    my $ActualLevel      = 1;
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    # build the items for the new levels
    LOOPDEPTH:
    for my $GoDeep ( $Init .. $Depth ) {
        next LOOPDEPTH if exists $LinkOutputData->[ $GoDeep ];
        last LOOPDEPTH unless $LinkOutputData->[ $GoDeep - 1 ];

        # get linked objects for the next level
        my @ItemsPerLevel;
        my %ItemMap;
        for my $Element ( $LinkOutputData->[ $GoDeep - 1 ]->@* ) {

            my $LinkedGovernanceObjects = $GovernanceObjectObject->LinkedGovernanceObjects(
                GovernanceObjectID => $Element->{GovernanceObjectID},
                VersionID    => $Element->{VersionID},
                Direction    => $Direction,
                UserID       => 1,
            );

            my $DataForItem = $Self->GetLinkOutputData(
                LinkedGovernanceObjects => $LinkedGovernanceObjects,
                LinkedTo          => $Element->{ID},
                Direction         => $Direction,
            );

            ITEM:
            for my $SingleItem ( @{ $DataForItem // [] } ) {

                # if this item already exists on this layer, just add another link to it
                if ( defined $ItemMap{ $SingleItem->{ID} } ) {
                    push @{ $ItemsPerLevel[ $ItemMap{ $SingleItem->{ID} } ]{Link} }, $SingleItem->{Link}[0];

                    next ITEM;
                }

                push @ItemsPerLevel, $SingleItem;
                $ItemMap{ $SingleItem->{ID} } = $#ItemsPerLevel;
            }
        }

        if (@ItemsPerLevel) {
            $ActualLevel++;
            $LinkOutputData->[$GoDeep] = \@ItemsPerLevel;
        }
    }

    if ( $ActualLevel > $Self->{CITreeMaxDepth} && $ActualLevel != 0 ) {
        $Self->{CITreeMaxDepth} = $ActualLevel;
    }

    return;
}

# return contents of the nodes
sub _GetContents {
    my ( $Self, %Param ) = @_;

    my @Attributes = $Param{Attributes}->@*;
    my $GovernanceObject = $Param{GovernanceObject};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # fill data with Governance Object attributes
    my @Lines;
    for my $Column (@Attributes) {

        my $ColumnLabel = $Column;
        if ( index( $Column, '::' ) > 0 ) {
            my @Vals = split /::/, $Column;
            pop @Vals;
            $ColumnLabel = join ' ', @Vals;
        }

        my $Label = $LayoutObject->{LanguageObject}->Translate( $Self->_MapAttributes( Label => $ColumnLabel ) );
        my $Text  = $LayoutObject->{LanguageObject}->Translate( $GovernanceObject->{$Column} // '' );

        # special handling for the current ZTSM Status. Show the green, yellow, red flags.
        if ( $Column eq 'ZTSMStatusType' ) {

            # define incident signals
            my %InciSignals = (
                Translatable('operational') => 'greenled',
                Translatable('warning')     => 'yellowled',
                Translatable('incident')    => 'redled',
            );
            my $CurInciSignal = $InciSignals{ $GovernanceObject->{ZTSMStatusType} };
            push @Lines, qq{<span class="Flag Small"> <span class="$CurInciSignal">"$Text"</span></span>};
        }
        else {
            push @Lines, "$Label: $Text";
        }
    }

    return join "<br>\n", @Lines;
}

# generate an ID that is used for drawing the arcs
sub _GenerateID {
    my ( $Self, %Param ) = @_;

    return join '',
        ( defined $Param{GovernanceObjectID} ? "C$Param{GovernanceObjectID}" : '' ),
        ( defined $Param{VersionID}    ? "V$Param{VersionID}"    : '' );
}

# Get links for related CI.
# This returned output data is not a tree, but an arrayref of items per level.
sub GetLinkOutputData {
    my ( $Self, %Param ) = @_;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $ConfiguredTypes  = $Kernel::OM->Get('Kernel::Config')->Get('LinkObject::Type');

    my @OutputData;
    for my $LinkedGovernanceObject ( grep { $_->{Direction} eq $Param{Direction} } $Param{LinkedGovernanceObjects}->@* ) {

        # basic information about the linked Governance Object
        # There are only two cases:
        #   - GovernanceObjectID is given
        #   - VersionID is given
        my %IncomingIDs = map { $_ => $LinkedGovernanceObject->{$_} } qw(GovernanceObjectID VersionID);

        # GovernanceObjectGet() allows for both cases
        my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
            %IncomingIDs,
            DynamicFields => 1,
        );

        # This will be used for finding the next level of links:
        #   - GovernanceObjectID was given => latest VersionID will be added
        #   - VersionID was given    => GovernanceObjectID for that version will be added
        my %OutgoingIDs = map { $_ => $GovernanceObject->{$_} } qw(GovernanceObjectID VersionID);

        # Find label for the link. In TreeView the label of the arc
        # should be in accordance to the direction of the arc. The are
        # is always directed from Source to Target. Therefore the SourceName is the arc label.
        my $LinkType = $LinkedGovernanceObject->{LinkType};
        my $ArcLabel = $ConfiguredTypes->{$LinkType}->{SourceName} || $LinkType;
        my $Link     = [ { LinkedTo => $Param{LinkedTo},  LinkType => $ArcLabel } ];

        # Was the link to this item version specific ?
        # The VersionString is only shown in the TreeView when an explicit version is linked.
        # TODO: if we want multiple links to the version on the same layer, only partly version specific
        #       we would need separate ids for both. This currently is not implemented.
        my $LinkedAsVersion = $IncomingIDs{VersionID} ? 1 : 0;

        # define item data
        push @OutputData, {
            %OutgoingIDs,
            ID              => $Self->_GenerateID(%OutgoingIDs),    # used for linking in the graph
            Name            => $GovernanceObject->{Name},
            Link            => $Link,
            LinkedAsVersion => $LinkedAsVersion,
            Contents        => $Self->_GetContents(
                Attributes => [
                    ( $LinkedAsVersion ? 'VersionString' : () ),
                    $Self->CITreeDefaultAttributes,
                ],
                GovernanceObject => $GovernanceObject,
            ),
        };
    }

    return \@OutputData;
}

# change labels for translatable values
sub _MapAttributes {
    my ( $Self, %Param ) = @_;

    if ( !$Param{Label} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need Label!'
        );

        return;
    }

    state $MapTranslations = {
        ZTSMStatus        => 'ZTSM Status',
        ZTSMStatus        => 'ZTSM Status',
        ZTSMStatus     => 'Current ZTSM Status',
        ZTSMStatus     => 'Current ZTSM Status',
        ZTSMStatusType => '',
        Number           => 'Governance Object Number',
        VersionString    => 'Version String',
    };

    return $MapTranslations->{ $Param{Label} } // $Param{Label};
}

1;
