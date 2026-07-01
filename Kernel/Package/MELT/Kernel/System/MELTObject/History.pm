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

package Kernel::System::MELTObject::History;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::MELTObject::History - module for MELTObject.pm with history functions

=head1 PUBLIC INTERFACE

=head1 DESCRIPTION

All history functions.

=head2 HistoryGet()

Returns an array reference with all history entries for the given MELT Object.
Each array element is a hash reference representing one history entry.

These hash references contain information about:

    $Info{HistoryEntryID}
    $Info{MELTObjectID}
    $Info{HistoryType}
    $Info{HistoryTypeID}
    $Info{Comment}
    $Info{CreatedBy}
    $Info{CreateTime}
    $Info{UserID}
    $Info{UserLogin}
    $Info{UserLastname}
    $Info{UserFirstname}
    $Info{UserFullname}

    my $Info = $MELTObjectObject->HistoryGet(
        MELTObjectID => 1234,
    );

=cut

sub HistoryGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(MELTObjectID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # if cached result exists, return that result
    return $Self->{Cache}->{CIVersions}->{ $Param{MELTObjectID} }
        if $Self->{Cache}->{CIVersions}->{ $Param{MELTObjectID} };

    # fetch some data from history for given MELT Object
    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => 'SELECT ch.id, ch.melt_object_id, ch.content, ch.type_id, '
            . 'ch.create_by, ch.create_time, cht.name '
            . 'FROM melt_object_item_history ch, melt_object_item_history_type cht '
            . 'WHERE ch.type_id = cht.id AND ch.melt_object_id = ? '
            . 'ORDER BY ch.id',
        Bind => [ \$Param{MELTObjectID} ],
    );

    # save data from history in array
    my @Entries;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        my %Tmp = (
            HistoryEntryID => $Row[0],
            MELTObjectID   => $Row[1],
            Comment        => $Row[2],
            HistoryTypeID  => $Row[3],
            CreateBy       => $Row[4],
            CreateTime     => $Row[5],
            HistoryType    => $Row[6],
        );

        push @Entries, \%Tmp;
    }

    # get more information about user who created history entries
    for my $Entry (@Entries) {

        # get user information
        my %UserInfo = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
            UserID => $Entry->{CreateBy},
            Cached => 1,
        );

        # save additional information for history entry
        $Entry->{UserID}        = $UserInfo{UserID};
        $Entry->{UserLogin}     = $UserInfo{UserLogin};
        $Entry->{UserFirstname} = $UserInfo{UserFirstname};
        $Entry->{UserLastname}  = $UserInfo{UserLastname};
        $Entry->{UserFullname}  = $UserInfo{UserFullname};
    }

    # save result in cache
    $Self->{Cache}->{CIVersions}->{ $Param{MELTObjectID} } = \@Entries;

    return \@Entries;
}

=head2 HistoryEntryGet()

Returns a hash reference with information about a single history entry.
The hash reference contain information about:

    $Info{HistoryEntryID}
    $Info{MELTObjectID}
    $Info{HistoryType}
    $Info{HistoryTypeID}
    $Info{Comment}
    $Info{CreateBy}
    $Info{CreateTime}
    $Info{UserID}
    $Info{UserLogin}
    $Info{UserLastname}
    $Info{UserFirstname}
    $Info{UserFullname}

    my $Info = $MELTObjectObject->HistoryEntryGet(
        HistoryEntryID => 1234,
    );

=cut

sub HistoryEntryGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(HistoryEntryID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # if cached result exists, return that result
    if ( $Self->{Cache}->{Versions}->{ $Param{HistoryEntryID} } ) {
        my ($MELTObjectID) = keys %{ $Self->{Cache}->{Versions}->{ $Param{HistoryEntryID} } };
        return $Self->{Cache}->{Versions}->{ $Param{HistoryEntryID} }->{$MELTObjectID};
    }

    # fetch a single entry from history
    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL => 'SELECT ch.id, ch.melt_object_id, ch.content, ch.type_id, '
            . 'ch.create_by, ch.create_time, cht.name '
            . 'FROM melt_object_item_history ch, melt_object_item_history_type cht '
            . 'WHERE ch.type_id = cht.id AND ch.id = ?',
        Bind  => [ \$Param{HistoryEntryID} ],
        Limit => 1,
    );

    my %Entry;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {

        %Entry = (
            HistoryEntryID => $Row[0],
            MELTObjectID   => $Row[1],
            Comment        => $Row[2],
            HistoryTypeID  => $Row[3],
            CreateBy       => $Row[4],
            CreateTime     => $Row[5],
            HistoryType    => $Row[6],
        );
    }

    # get user data for this entry
    my %UserInfo = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID => $Entry{CreateBy},
        Cached => 1,
    );

    $Entry{UserID}        = $UserInfo{UserID};
    $Entry{UserLogin}     = $UserInfo{UserLogin};
    $Entry{UserFirstname} = $UserInfo{UserFirstname};
    $Entry{UserLastname}  = $UserInfo{UserLastname};
    $Entry{UserFullname}  = $UserInfo{UserFullname};

    $Self->{Cache}->{Versions}->{ $Param{HistoryEntryID} }->{ $Entry{MELTObjectID} } = \%Entry;

    return \%Entry;
}

=head2 HistoryAdd()

Adds a single history entry to the history.

    $MELTObjectObject->HistoryAdd(
        MELTObjectID  => 1234,
        HistoryType   => 'NewMELTObject', # either HistoryType or HistoryTypeID is needed
        HistoryTypeID => 1,
        UserID        => 1,
        Comment       => 'Any useful information',
    );

=cut

sub HistoryAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(MELTObjectID UserID Comment)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    if ( !( $Param{HistoryType} || $Param{HistoryTypeID} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need HistoryType or HistoryTypeID!',
        );
        return;
    }

    # get history type id from history type if history type is given.
    if ( $Param{HistoryType} ) {
        my $Id = $Self->HistoryTypeLookup( HistoryType => $Param{HistoryType} );

        if ( !$Id ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Invalid history type given!',
            );
            return;
        }

        $Param{HistoryTypeID} = $Id;
    }

    # if history type is given
    elsif ( $Param{HistoryTypeID} ) {
        my $Name = $Self->HistoryTypeLookup( HistoryTypeID => $Param{HistoryTypeID} );

        if ( !$Name ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Invalid history type id given!',
            );
            return;
        }
    }

    # check if given MELT Object id points to an existing MELT Object number
    if ( $Param{MELTObjectID} ) {

        my $Number = $Self->MELTObjectLookup(
            MELTObjectID => $Param{MELTObjectID},
        );

        if ( !$Number ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Invalid MELT Object id given!',
            );
            return;
        }
    }

    # delete cached results
    delete $Self->{Cache}->{CIVersions}->{ $Param{MELTObjectID} };

    # shorten the comment if it is bigger than max length
    if ( length( $Param{Comment} ) > 191 ) {

        my ( $Field, $Old, $New ) = split /%%/, $Param{Comment}, 3;

        my $Length = int( ( 191 - length($Field) - 4 ) / 2 );

        if ( length($Old) > $Length ) {
            my $Index = int( $Length / 2 );
            $Old = substr( $Old, 0, $Index - 2 ) . '...' . substr( $Old, length($Old) - $Index + 2 );
        }
        if ( length($New) > $Length ) {
            my $Index = int( $Length / 2 );
            $New = substr( $New, 0, $Index - 2 ) . '...' . substr( $New, length($New) - $Index + 2 );
        }
        my $NewComment = $Field . '%%' . $Old . '%%' . $New;

        $Param{Comment} = $NewComment;
    }

    # insert history entry
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO melt_object_item_history ( melt_object_id, content, create_by, '
            . 'create_time, type_id ) VALUES ( ?, ?, ?, current_timestamp, ? )',
        Bind => [
            \$Param{MELTObjectID},
            \$Param{Comment},
            \$Param{UserID},
            \$Param{HistoryTypeID},
        ],
    );
}

=head2 HistoryDelete()

Deletes complete history for a given MELT Object

    $MELTObjectObject->HistoryDelete(
        MELTObjectID => 123,
    );

=cut

sub HistoryDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(MELTObjectID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # delete cached results
    delete $Self->{Cache}->{CIVersion}->{ $Param{MELTObjectID} };
    for my $VersionNr ( sort keys %{ $Self->{Cache}->{Versions} } ) {
        my ($CacheMELTObject) = keys %{ $Self->{Cache}->{Versions}->{$VersionNr} };
        delete $Self->{Cache}->{Versions}->{$VersionNr} if $CacheMELTObject eq $Param{MELTObjectID};
    }

    # delete history for given MELT Object
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM melt_object_item_history WHERE melt_object_id = ?',
        Bind => [ \$Param{MELTObjectID} ],
    );
}

=head2 HistoryEntryDelete()

Deletes a single history entry.

    $MELTObjectObject->HistoryEntryDelete(
        HistoryEntryID => 123,
    );

=cut

sub HistoryEntryDelete {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(HistoryEntryID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # delete single entry
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM melt_object_item_history WHERE id = ?',
        Bind => [ \$Param{HistoryEntryID} ],
    );
}

=head2 HistoryTypeLookup()

This method does a lookup for a history type. If a history type id is given,
it returns the name of the history type. If a history type is given, the appropriate
id is returned.

    my $Name = $MELTObjectObject->HistoryTypeLookup(
        HistoryTypeID => 1234,
    );

    my $Id = $MELTObjectObject->HistoryTypeLookup(
        HistoryType => 'MELTObjectCreate',
    );

=cut

sub HistoryTypeLookup {
    my ( $Self, %Param ) = @_;

    my ($Key) = grep { $Param{$_} } qw(HistoryTypeID HistoryType);

    # check for needed stuff
    if ( !$Key ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need HistoryTypeID or HistoryType!',
        );
        return;
    }

    # if result is cached return that result
    return $Self->{Cache}->{HistoryTypeLookup}->{ $Param{$Key} }
        if $Self->{Cache}->{HistoryTypeLookup}->{ $Param{$Key} };

    # set the appropriate SQL statement
    my $SQL = 'SELECT name FROM melt_object_item_history_type WHERE id = ?';

    if ( $Key eq 'HistoryType' ) {
        $SQL = 'SELECT id FROM melt_object_item_history_type WHERE name = ?';
    }

    # fetch the requested value
    return if !$Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Param{$Key} ],
        Limit => 1,
    );

    my $Value;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Value = $Row[0];
    }

    # save value in cache
    $Self->{Cache}->{HistoryTypeLookup}->{ $Param{$Key} } = $Value;

    return $Value;
}

1;

