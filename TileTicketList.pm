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

package Kernel::Output::HTML::CustomerDashboard::TileTicketList;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::Output::HTML::TicketOverview::CustomerList',
    'Kernel::System::CustomerUser',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::CustomerGroup',
    'Kernel::System::Log',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _NormalizeValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

sub _NormalizeReferenceValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _NormalizeReferenceValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

sub _DebugValue {
    my ($Value) = @_;

    return '<undef>' if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return '[' . join( ', ', map { _DebugValue($_) } @{$Value} ) . ']';
    }

    if ( ref $Value eq 'HASH' ) {
        return '{'
            . join(
            ', ',
            map {
                $_ . '=' . _DebugValue( $Value->{$_} )
            } sort keys %{$Value}
            )
            . '}';
    }

    return $Value;
}

sub _CustomerUserMatches {
    my (%Param) = @_;

    my $AssignmentUser = _NormalizeReferenceValue( $Param{AssignmentUser} );
    return if !defined $AssignmentUser || $AssignmentUser eq '';

    my $CustomerUserID = _NormalizeValue( $Param{CustomerUserID} ) || '<undef>';
    my %CustomerUserID = map { lc $_ => 1 } _CustomerUserReferenceIDs(%Param);

    return $CustomerUserID{ lc $AssignmentUser };
}

sub _CustomerUserReferenceIDs {
    my (%Param) = @_;

    my $CustomerUserID = _NormalizeValue( $Param{CustomerUserID} );

    return if !defined $CustomerUserID || $CustomerUserID eq '';

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my %CustomerUserID = ( $CustomerUserID => 1 );

    for my $CustomerID (
        $CustomerUserObject->CustomerIDs(
            User => $CustomerUserID,
        )
        )
    {
        my $Value = _NormalizeValue($CustomerID);
        $CustomerUserID{$Value} = 1 if defined $Value && $Value ne '';
    }

    return sort keys %CustomerUserID;
}

sub _SupportProfileVariants {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my %Value;

    if ( $Value =~ m{\A\d+\z} ) {
        $Value{$Value} = 1;
    }

    return sort keys %Value;
}

sub _SupportProfileList {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    my @CustomerUserIDs = _CustomerUserReferenceIDs( CustomerUserID => $Param{CustomerUserID} );
    my %AssignmentID;

    for my $CustomerUserID (@CustomerUserIDs) {
        my @FoundAssignmentIDs = $ConfigItemObject->ConfigItemSearch(
            Classes => ['Support Assignment'],
            'DynamicField_ZTSMSupportAssignment-UserAccount' => {
                Equals => $CustomerUserID,
            },
            Result => 'ARRAY',
            Limit  => 1000,
        );

        $AssignmentID{$_} = 1 for @FoundAssignmentIDs;
    }

    my @AssignmentIDs = sort { $a <=> $b } keys %AssignmentID;

    return if !@AssignmentIDs;

    my %SupportProfile;

    ASSIGNMENT:
    for my $AssignmentID (@AssignmentIDs) {

        my $Assignment = $ConfigItemObject->ConfigItemGet(
            ConfigItemID  => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment || ref $Assignment ne 'HASH';

        my $AssignmentUser = $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'};
        $AssignmentUser ||= $Assignment->{XMLData}
            && $Assignment->{XMLData}->{'ZTSMSupportAssignment-UserAccount'};

        next ASSIGNMENT if !_CustomerUserMatches(
            AssignmentUser => $AssignmentUser,
            CustomerUserID => $Param{CustomerUserID},
        );

        my $AssignmentSupportProfile = $Assignment->{'DynamicField_ZTSMSupportAssignment-SupportProfile'};
        $AssignmentSupportProfile ||= $Assignment->{XMLData}
            && $Assignment->{XMLData}->{'ZTSMSupportAssignment-SupportProfile'};

        for my $SupportProfile (
            _SupportProfileVariants(
                Value => $AssignmentSupportProfile,
                ReferenceOnly => 1,
            )
            )
        {
            next ASSIGNMENT if !defined $SupportProfile;
            next ASSIGNMENT if $SupportProfile eq '';

            $SupportProfile{$SupportProfile} = 1;
        }
    }

    return sort keys %SupportProfile;
}

sub _PermissionFilter {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $PermissionObject = $Kernel::OM->Get(
        'Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck'
    );

    my @TicketIDs;
    my %Seen;

    TICKETID:
    for my $TicketID ( @{ $Param{TicketIDs} || [] } ) {

        next TICKETID if !$TicketID;
        next TICKETID if $Seen{$TicketID}++;

        next TICKETID if !$PermissionObject->Run(
            TicketID        => $TicketID,
            CustomerUserID  => $Param{CustomerUserID},
            Type            => 'ro',
        );

        push @TicketIDs, $TicketID;
    }

    return @TicketIDs;
}

sub _ZTSMWorkableTicketIDs {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Candidate;
    my @Candidate;
    my @StateTypes = $Param{StateType} ? ( $Param{StateType} ) : ( 'new', 'open', 'pending' );

    PROFILE:
    for my $SupportProfile ( _SupportProfileList( CustomerUserID => $Param{CustomerUserID} ) ) {

        next PROFILE if !$SupportProfile;

        my @ProfileTicketIDs = $TicketObject->TicketSearch(
            Result => 'ARRAY',
            'DynamicField_ZTicket-OwnerGroup' => {
                Equals => $SupportProfile,
            },
            StateType => \@StateTypes,
            SortBy    => $Param{SortBy}  || 'Changed',
            OrderBy   => $Param{OrderBy} || 'Down',
            UserID    => 1,
        );

        for my $TicketID (@ProfileTicketIDs) {
            next if !$TicketID;
            next if $Candidate{$TicketID}++;
            push @Candidate, $TicketID;
        }
    }

    return _PermissionFilter(
        CustomerUserID => $Param{CustomerUserID},
        TicketIDs      => \@Candidate,
    );
}

sub _TypeColor {
    my ($Type) = @_;

    my %Color = (
        'ServiceRequest' => '#2563EB',
        'Assessment'     => '#F59E0B',
        'Approval'       => '#8B5CF6',
        'Endorsement'    => '#6366F1',
        'Change'         => '#06B6D4',
        'Change::Major'  => '#0284C7',
        'Task'           => '#22C55E',
        'Verification'   => '#14B8A6',
        'Incident'       => '#EF4444',
        'Incident::Major' => '#B91C1C',
        'Problem'        => '#EA580C',
        'Unclassified'   => '#6B7280',
    );

    return $Color{ $Type || '' } || $Color{Unclassified};
}

sub _ConfigItemNameGet {
    my (%Param) = @_;

    my $ConfigItemID = _NormalizeValue( $Param{ConfigItemID} );
    return '-' if !defined $ConfigItemID || $ConfigItemID eq '';

    my $ConfigItem = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID => $ConfigItemID,
    );

    return $ConfigItem->{Name} if $ConfigItem && $ConfigItem->{Name};
    return $ConfigItemID;
}

sub _TicketRowsBuild {
    my (%Param) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my @Rows;
    my %Seen;

    TICKETID:
    for my $TicketID ( @{ $Param{TicketIDs} || [] } ) {

        next TICKETID if !$TicketID;
        next TICKETID if $Seen{$TicketID}++;

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => 1,
        );

        next TICKETID if !%Ticket;
        next TICKETID if !$Param{IncludeClosed} && ( $Ticket{StateType} || '' ) eq 'closed';

        my $Type       = $Ticket{Type} || 'Unclassified';
        my $OwnerGroup = _NormalizeValue( $Ticket{'DynamicField_ZTicket-OwnerGroup'} );
        my $Changed    = $Ticket{Changed} || $Ticket{Created} || '';
        my $Created    = $Ticket{Created} || '';

        push @Rows, {
            TicketID       => $TicketID,
            TicketNumber   => $Ticket{TicketNumber} || $TicketID,
            Title          => $Ticket{Title} || '-',
            Type           => $Type,
            TypeColor      => _TypeColor($Type),
            State          => $Ticket{State} || '-',
            OwnerGroup     => _ConfigItemNameGet( ConfigItemID => $OwnerGroup ),
            Changed        => $Changed,
            Created        => $Created,
            SortTime       => $Changed || $Created,
        };
    }

    return sort {
             ( $b->{SortTime} || '' ) cmp ( $a->{SortTime} || '' )
          || ( $b->{TicketID}  || 0 )  <=> ( $a->{TicketID}  || 0 )
    } @Rows;
}

sub _MajorChangeTicketIDs {
    my (%Param) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Candidate;
    my @Candidate;
    my %StateList = $Kernel::OM->Get('Kernel::System::State')->StateList(
        Valid  => 0,
        UserID => 1,
    );
    my %StateLookup = reverse %StateList;

    return if !$StateLookup{approved};

    my @TicketIDs = $TicketObject->TicketSearch(
        Result    => 'ARRAY',
        Types     => ['Change::Major'],
        States    => ['approved'],
        StateType => [ 'new', 'open', 'pending' ],
        SortBy    => 'Changed',
        OrderBy   => 'Down',
        UserID    => 1,
    );

    for my $TicketID (@TicketIDs) {
        next if !$TicketID;
        next if $Candidate{$TicketID}++;
        push @Candidate, $TicketID;
    }

    return _PermissionFilter(
        CustomerUserID => $Param{CustomerUserID},
        TicketIDs      => \@Candidate,
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    # check needed CustomerUserID
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return '';
    }

    my @WorkableTicketIDs = _ZTSMWorkableTicketIDs(
        CustomerUserID => $Param{UserID},
        SortBy         => $Param{Config}{SortBy}  || 'Changed',
        OrderBy        => $Param{Config}{OrderBy} || 'Down',
    );

    my @WorkspaceRows = _TicketRowsBuild(
        TicketIDs => \@WorkableTicketIDs,
    );

    if ( $Param{Config}{MaxTickets} && $Param{Config}{MaxTickets} - 1 < $#WorkspaceRows ) {
        @WorkspaceRows = @WorkspaceRows[ 0 .. $Param{Config}{MaxTickets} - 1 ];
    }

    my @MajorChangeRows = _TicketRowsBuild(
        TicketIDs => [
            _MajorChangeTicketIDs(
                CustomerUserID => $Param{UserID},
            )
        ],
    );

    my $Content = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Output(
        TemplateFile => 'Dashboard/TileTicketList',
        Data         => {
            TileID           => $Param{TileID},
            Text             => 'My workspace',
            WorkspaceRows    => \@WorkspaceRows,
            WorkspaceCount   => scalar @WorkspaceRows,
            MajorChangeRows  => \@MajorChangeRows,
            MajorChangeCount => scalar @MajorChangeRows,
            %{ $Param{Config} },
        },
    );

    return $Content;
}

1;
