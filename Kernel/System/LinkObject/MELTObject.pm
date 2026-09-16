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

package Kernel::System::LinkObject::MELTObject;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules

# CPAN modules

# OTOBO modules

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::MELTObject',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::LinkObject::MELT Object - LinkObject module for MELTObject

=head2 new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $LinkObjectMELTObjectObject = $Kernel::OM->Get('Kernel::System::LinkObject::MELTObject');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {}, $Type;
}

=head2 LinkListWithData()

fill up the link list with data

    $Success = $LinkObjectBackend->LinkListWithData(
        LinkList => $HashRef,
        UserID   => 1,
    );

=cut

sub LinkListWithData {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(LinkList UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    # check link list
    if ( ref $Param{LinkList} ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'LinkList must be a hash reference!',
        );

        return;
    }

    for my $LinkType ( sort keys %{ $Param{LinkList} } ) {

        for my $Direction ( sort keys %{ $Param{LinkList}->{$LinkType} } ) {

            MELTObjectID:
            for my $MELTObjectID ( sort keys %{ $Param{LinkList}->{$LinkType}->{$Direction} } ) {

                # get last version data
                my $MELTObject = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
                    MELTObjectID => $MELTObjectID,
                );

                # remove id from hash if MELT Object can not get
                if ( !$MELTObject || ref $MELTObject ne 'HASH' || !%{$MELTObject} ) {
                    delete $Param{LinkList}->{$LinkType}->{$Direction}->{$MELTObjectID};
                    next MELTObjectID;
                }

                # add version data
                $Param{LinkList}->{$LinkType}->{$Direction}->{$MELTObjectID} = $MELTObject;
            }
        }
    }

    return 1;
}

=head2 ObjectPermission()

checks read permission for a given object and UserID.

    $Permission = $LinkObject->ObjectPermission(
        Object  => 'MELTObject',
        Key     => 123,
        UserID  => 1,
    );

=cut

sub ObjectPermission {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Object Key UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    # get config of MELT Object zoom frontend module
    $Self->{Config} = $Kernel::OM->Get('Kernel::Config')->Get('MELTObject::Frontend::AgentMELTObjectZoom');

    # check for access rights
    my $Access = $Kernel::OM->Get('Kernel::System::MELTObject')->Permission(
        Scope  => 'Item',
        ItemID => $Param{Key},
        UserID => $Param{UserID},
        Type   => $Self->{Config}->{Permission},
    );

    return $Access;
}

=head2 ObjectDescriptionGet()

return a hash of object descriptions

    %Description = $LinkObject->ObjectDescriptionGet(
        Key     => 123,
        UserID  => 1,
    );

Returns:

    %Description = (
        Normal => "MELTObject# 1234455",
        Long   => "MELTObject# 1234455: The MELT Object Title",
    );

=cut

sub ObjectDescriptionGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Object Key UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    # create description
    my %Description = (
        Normal => 'MELTObject',
        Long   => 'MELTObject',
    );

    return %Description if $Param{Mode} && $Param{Mode} eq 'Temporary';

    # get last version data
    my $MELTObject = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
        MELTObjectID => $Param{Key},
    );

    return if !$MELTObject;
    return if ref $MELTObject ne 'HASH';
    return if !%{$MELTObject};

    # create description
    %Description = (
        Normal => "MELTObject# $MELTObject->{Number}",
        Long   => "MELTObject# $MELTObject->{Number}: $MELTObject->{Name}",
    );

    return %Description;
}

=head2 ObjectSearch()

return a hash list of the search results

    $SearchList = $LinkObjectBackend->ObjectSearch(
        SubObject    => '25',        # (optional)
        SearchParams => $HashRef,    # (optional)
        UserID       => 1,
    );

Returns:

    $SearchList = {
        C<NOTLINKED> => {
            Source => {
                12  => $DataOfItem12,
                212 => $DataOfItem212,
                332 => $DataOfItem332,
            },
        },
    };

=cut

sub ObjectSearch {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );

        return;
    }

    # set default params
    $Param{SearchParams} ||= {};

    # set focus
    my %Search;
    for my $Element (qw(Number Name)) {
        if ( $Param{SearchParams}->{$Element} ) {
            $Search{$Element} = '%' . $Param{SearchParams}->{$Element} . '%';
        }
    }

    if ( !$Param{SubObject} ) {

        # get the config with the default subobjects
        my $DefaultSubobject = $Kernel::OM->Get('Kernel::Config')->Get('LinkObject::DefaultSubObject') || {};

        # extract default class name
        my $DefaultClass = $DefaultSubobject->{MELTObject} || '';

        # get class list
        my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
            Class => 'ZTSM::MELT::Class',
        );

        return if !$ClassList;
        return if ref $ClassList ne 'HASH';

        # lookup the class id
        my %ClassListReverse = reverse %{$ClassList};
        $Param{SubObject} = $ClassListReverse{$DefaultClass} || '';
    }

    return if !$Param{SubObject};

    # search the MELT Objects
    my @MELTObjectIDs = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectSearch(
        %{ $Param{SearchParams} },
        %Search,
        ClassIDs       => [ $Param{SubObject} ],
        UsingWildcards => 1,
        SortBy         => ['Number'],
        OrderBy        => ['Up'],
        Limit          => 50,
        UserID         => $Param{UserID},
        Result         => 'ARRAY',
    );

    my %SearchList;
    MELTObjectID:
    for my $MELTObjectID (@MELTObjectIDs) {

        # get last version data
        my $MELTObject = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
            MELTObjectID => $MELTObjectID,
        );

        next MELTObjectID if !$MELTObject;
        next MELTObjectID if ref $MELTObject ne 'HASH';
        next MELTObjectID if !%{$MELTObject};

        # add version data
        $SearchList{NOTLINKED}->{Source}->{$MELTObjectID} = $MELTObject;
    }

    return \%SearchList;
}

=head2 LinkAddPre()

link add pre event module

    $True = $LinkObject->LinkAddPre(
        Key          => 123,
        SourceObject => 'MELTObject',
        SourceKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

or

    $True = $LinkObject->LinkAddPre(
        Key          => 123,
        TargetObject => 'MELTObject',
        TargetKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

=cut

sub LinkAddPre {
    return 1;    # nothing to do
}

=head2 LinkAddPost()

link add post event module

    $True = $LinkObject->LinkAddPost(
        Key          => 123,
        SourceObject => 'MELTObject',
        SourceKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

or

    $True = $LinkObject->LinkAddPost(
        Key          => 123,
        TargetObject => 'MELTObject',
        TargetKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

=cut

sub LinkAddPost {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Key Type State UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    # do not update melt_object_item_link table for temporary links
    # do not recalculate the current ZTSM Status for temporary links
    # do not emit the LinkAdd event for temporary links
    return 1 if $Param{State} eq 'Temporary';

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    # Sync the new link to the melt_object_item_link table.
    # This is only needed for links between MELT Objects.
    # When a link is added then LinkAddPost() is called twice. But only
    # one of the calls has to be considered here, as only one entry in 'melt_object_item_link'
    # is needed.
    if ( $Param{TargetKey} && ( $Param{TargetObject} // '' ) eq 'MELTObject' ) {
        $MELTObjectObject->AddMELTObjectLink(
            Type               => $Param{Type},
            SourceMELTObjectID => $Param{Key},
            TargetMELTObjectID => $Param{TargetKey},
        );
    }

    # Recalculate the current ZTSM Status of this CI for links to services
    # This will implicitly update the service ZTSM Status
    # MELTObjectLinks will be handled by the MELTObjectLink object
    elsif ( ( $Param{TargetObject} // $Param{SourceObject} ) eq 'Service' ) {
        $MELTObjectObject->ZTSMStatusRecalc(
            MELTObjectID => $Param{Key},
        );
    }

    # trigger LinkAdd event, the comment is a kind of hidden channel
    my $Comment = join '%%',
        ( $Param{TargetKey}    || $Param{SourceKey} ),
        ( $Param{TargetObject} || $Param{SourceObject} );
    $MELTObjectObject->EventHandler(
        Event => 'LinkAdd',
        Data  => {
            MELTObjectID => $Param{Key},
            Comment      => $Comment,
            Type         => $Param{Type},
        },
        UserID => $Param{UserID},
    );

    return 1;
}

=head2 LinkDeletePre()

link delete pre event module

    $True = $LinkObject->LinkDeletePre(
        Key          => 123,
        SourceObject => 'MELTObject',
        SourceKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

or

    $True = $LinkObject->LinkDeletePre(
        Key          => 123,
        TargetObject => 'MELTObject',
        TargetKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

=cut

sub LinkDeletePre {
    return 1;    # nothing to do
}

=head2 LinkDeletePost()

link delete post event module

    $True = $LinkObject->LinkDeletePost(
        Key          => 123,
        SourceObject => 'MELTObject',
        SourceKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

or

    $True = $LinkObject->LinkDeletePost(
        Key          => 123,
        TargetObject => 'MELTObject',
        TargetKey    => 321,
        Type         => 'Normal',
        State        => 'Valid',
        UserID       => 1,
    );

=cut

sub LinkDeletePost {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Key Type State UserID)) {
        if ( !$Param{$Argument} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );

            return;
        }
    }

    # do not note update melt_object_item_link table for temporary links
    # do not note recalculate the current in ZTSM Status for temporary links
    # do not trigger event for temporary links
    return 1 if $Param{State} eq 'Temporary';

    my $MELTObjectObject = $Kernel::OM->Get('Kernel::System::MELTObject');

    # sync the deletee link to the melt_object_item_link table.
    # This is only needed for one direction.
    if ( $Param{TargetKey} && ( $Param{TargetObject} // '' ) eq 'MELTObject' ) {
        $MELTObjectObject->DeleteMELTObjectLink(
            Type               => $Param{Type},
            SourceMELTObjectID => $Param{Key},
            TargetMELTObjectID => $Param{TargetKey},
        );
    }

    # TODO: Update the current ZTSM Status of unlinked services
    # elsif ( ( $Param{TargetObject} // $Param{SourceObject} ) eq 'Service' ) {
    # }

    # trigger LinkDelete event, the comment is a kind of hidden channel
    my $Comment = join '::',
        ( $Param{TargetKey}    || $Param{SourceKey} ),
        ( $Param{TargetObject} || $Param{SourceObject} );
    $MELTObjectObject->EventHandler(
        Event => 'LinkDelete',
        Data  => {
            MELTObjectID => $Param{Key},
            Comment      => $Comment,
        },
        UserID => $Param{UserID},
    );

    return 1;
}

1;

