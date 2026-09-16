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

package Kernel::System::MELTObject::Event::DoHistory;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules

# CPAN modules

# OTOBO modules

our @ObjectDependencies = (
    'Kernel::System::MELTObject',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::MELTObject::Event::DoHistory - Event handler that records the history

=head1 PUBLIC INTERFACE

=head2 new()

create an object

    use Kernel::System::ObjectManager;

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $DoHistoryObject = $Kernel::OM->Get('Kernel::System::MELTObject::Event::DoHistory');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    return bless {}, $Type;
}

=head2 Run()

This method handles the event.

    $DoHistoryObject->Run(
        Event => 'MELTObjectCreate',
        Data  => {
            Comment      => 'new value: 1',
            MELTObjectID => 123,
        },
        UserID => 1,
    );

=cut

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Data Event UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # check for dynamic fields first, most events will be this,
    # ReadableValue and ReadableOldValue are expected to be strings
    if ( $Param{Event} =~ m/^MELTObjectDynamicFieldUpdate_/ ) {
        return $Self->_HistoryAdd(
            MELTObjectID => $Param{Data}{MELTObjectID},
            HistoryType  => 'ValueUpdate',
            Comment      => "$Param{Data}{FieldName}%%$Param{Data}{ReadableOldValue}%%$Param{Data}{ReadableValue}",
            UserID       => $Param{UserID},
        );
    }

    # due to consistency with ticket history, we need HistoryType
    $Param{HistoryType} = $Param{Event};

    # dispatch table for all events
    my %Dispatcher = (
        MELTObjectCreate      => \&_HistoryAdd,
        MELTObjectUpdate      => \&_Return,
        MELTObjectDelete      => \&_MELTObjectDelete,
        LinkAdd               => \&_HistoryAdd,
        LinkDelete            => \&_HistoryAdd,
        NameUpdate            => \&_HistoryAdd,
        IncidentStateUpdate   => \&_HistoryAdd,
        DeploymentStateUpdate => \&_HistoryAdd,
        DefinitionUpdate      => \&_HistoryAdd,
        VersionCreate         => \&_HistoryAdd,
        VersionUpdate         => \&_Return,
        DefinitionCreate      => \&_Return,
        VersionDelete         => \&_HistoryAdd,
        AttachmentAddPost     => \&_HistoryAdd,
        AttachmentDeletePost  => \&_HistoryAdd,
    );

    # error handling
    if ( !exists $Dispatcher{ $Param{Event} } ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'non existent history type: ' . $Param{Event},
        );

        return;
    }

    # call callback
    my $Sub = $Dispatcher{ $Param{Event} };
    $Self->$Sub(
        %Param,
        %{ $Param{Data} },
    );

    return 1;
}

=head1 INTERNAL INTERFACE

=head2 _Return()

do nothing

=cut

sub _Return { return 1 }

=head2 _MELTObjectDelete()

history's event handler for MELTObjectDelete

=cut

sub _MELTObjectDelete {
    my ( $Self, %Param ) = @_;

    # delete history
    $Kernel::OM->Get('Kernel::System::MELTObject')->HistoryDelete(
        MELTObjectID => $Param{MELTObjectID},
    );

    return 1;
}

=head2 _HistoryAdd()

history's default event handler.

=cut

sub _HistoryAdd {
    my ( $Self, %Param ) = @_;

    # add history entry
    return $Kernel::OM->Get('Kernel::System::MELTObject')->HistoryAdd(
        %Param,
    );
}

1;

