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

    my $Match = $CustomerUserID{ lc $AssignmentUser };

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => 'ZTSM SupportAssignment user match: CustomerUserID='
            . $CustomerUserID
            . ' CandidateIDs='
            . join( '|', sort keys %CustomerUserID )
            . ' AssignmentRaw='
            . _DebugValue( $Param{AssignmentUser} )
            . ' AssignmentValue='
            . $AssignmentUser
            . ' Match='
            . ( $Match ? 1 : 0 ),
    );

    return $Match;
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

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my %Value;

    my @SupportProfiles;
    if ( $Value =~ m{\A\d+\z} ) {
        for my $GetParam (
            { ConfigItemID => $Value },
            { VersionID    => $Value },
            )
        {
            my $SupportProfile = $ConfigItemObject->ConfigItemGet(
                %{$GetParam},
                DynamicFields => 1,
                Silent        => 1,
            );

            push @SupportProfiles, $SupportProfile
                if $SupportProfile
                && ( $SupportProfile->{Class} || '' ) eq 'Support Profile';
        }
    }
    else {
        my @SupportProfileIDs = $ConfigItemObject->ConfigItemSearch(
            Result  => 'ARRAY',
            Classes => ['Support Profile'],
            Name    => $Value,
            Limit   => 10,
        );

        for my $SupportProfileID (@SupportProfileIDs) {
            my $SupportProfile = $ConfigItemObject->ConfigItemGet(
                ConfigItemID  => $SupportProfileID,
                DynamicFields => 1,
                Silent        => 1,
            );

            push @SupportProfiles, $SupportProfile
                if $SupportProfile;
        }
    }

    for my $SupportProfile (@SupportProfiles) {
        $Value{ $SupportProfile->{ConfigItemID} }  = 1 if $SupportProfile->{ConfigItemID};
        $Value{ $SupportProfile->{LastVersionID} } = 1 if $SupportProfile->{LastVersionID};
        $Value{ $SupportProfile->{Name} }          = 1 if $SupportProfile->{Name};
    }

    $Value{$Value} = 1;

    return sort keys %Value;
}

sub _SupportProfileList {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => 'ZTSM Dashboard support profile list enter: CustomerUserID='
            . $Param{CustomerUserID},
    );

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

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => 'ZTSM Dashboard support assignment search: CustomerUserID='
            . $Param{CustomerUserID}
            . ' CandidateIDs='
            . join( '|', @CustomerUserIDs )
            . ' Count='
            . scalar @AssignmentIDs,
    );

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

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ZTSM Dashboard assignment accepted user: AssignmentID='
                . $AssignmentID
                . ' SupportProfileRaw='
                . _DebugValue($AssignmentSupportProfile),
        );

        for my $SupportProfile (
            _SupportProfileVariants(
                Value => $AssignmentSupportProfile,
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

    my @DirectOwnerTicketIDs = $TicketObject->TicketSearch(
        Result => 'ARRAY',
        'DynamicField_ZTicket-Owner' => {
            Equals => $Param{CustomerUserID},
        },
        StateType => $Param{StateType} || '',
        SortBy    => $Param{SortBy}    || 'Age',
        OrderBy   => $Param{OrderBy}   || 'Down',
        UserID    => 1,
    );

    $Candidate{$_} = 1 for @DirectOwnerTicketIDs;

    PROFILE:
    for my $SupportProfile ( _SupportProfileList( CustomerUserID => $Param{CustomerUserID} ) ) {

        next PROFILE if !$SupportProfile;

        my @ProfileTicketIDs = $TicketObject->TicketSearch(
            Result => 'ARRAY',
            'DynamicField_ZTicket-OwnerGroup' => {
                Equals => $SupportProfile,
            },
            StateType => $Param{StateType} || '',
            SortBy    => $Param{SortBy}    || 'Age',
            OrderBy   => $Param{OrderBy}   || 'Down',
            UserID    => 1,
        );

        $Candidate{$_} = 1 for @ProfileTicketIDs;
    }

    return _PermissionFilter(
        CustomerUserID => $Param{CustomerUserID},
        TicketIDs      => [ sort { $a <=> $b } keys %Candidate ],
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => 'ZTSM TileTicketList Run enter: UserID='
            . ( $Param{UserID} // '<undef>' ),
    );

    # check needed CustomerUserID
    if ( !$Param{UserID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return '';
    }

    my $ConfigObject     = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject     = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TicketListObject = $Kernel::OM->Get('Kernel::Output::HTML::TicketOverview::CustomerList');

    my %Filter = (
        CustomerUserID => $Param{UserID},
        StateType      => $Param{Config}{StateType} || '',
        SortBy         => $Param{Config}{SortBy}    || 'Age',
        OrderBy        => $Param{Config}{OrderBy}   || 'Down',
        Permission     => 'ro',
    );

    if ( $Param{Config}{CompanyTickets} ) {

        # check if output of customer company tickets is disabled
        if ( $ConfigObject->Get('Ticket::Frontend::CustomerDisableCompanyTicketAccess') ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  =>
                    'Company Tickets can not be shown with Ticket::Frontend::CustomerDisableCompanyTicketAccess set!',
            );
            return '';
        }

        my %AccessibleCustomers = $Kernel::OM->Get('Kernel::System::CustomerGroup')->GroupContextCustomers(
            CustomerUserID => $Param{UserID},
        );

        $Filter{CustomerIDRaw} = [ sort keys %AccessibleCustomers ];

    }
    else {
        $Filter{CustomerUserLoginRaw} = $Param{UserID};
    }

    # get the viewable tickets
    my @ViewableTickets = $TicketObject->TicketSearch(
        %Filter,
        Result => 'ARRAY',
    );

    if ( $Param{Config}{ZTSMWorkableTickets} // 1 ) {

        my @WorkableTicketIDs = _ZTSMWorkableTicketIDs(
            CustomerUserID => $Param{UserID},
            StateType      => $Param{Config}{StateType} || '',
            SortBy         => $Param{Config}{SortBy}    || 'Age',
            OrderBy        => $Param{Config}{OrderBy}   || 'Down',
        );

        my %Seen;
        @ViewableTickets = grep { !$Seen{$_}++ } ( @ViewableTickets, @WorkableTicketIDs );
    }

    my $TicketListHTML;
    if ( scalar @ViewableTickets == 0 ) {

        # check if the CustomerUser has tickets at all
        my @AllTickets = $TicketObject->TicketSearch(
            Result               => 'ARRAY',
            CustomerUserID       => $Param{UserID},
            CustomerUserLoginRaw => $Param{UserID},
            Permission           => 'ro',
            Limit                => 1,
        );

        # generate appropriate message
        if ( !@AllTickets ) {
            my $CustomTexts = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverviewCustomEmptyText');
            $TicketListHTML = $TicketListObject->Run(
                TicketIDs   => [],
                NoAllTotal  => 1,
                CustomTexts => ( ref $CustomTexts eq 'HASH' ) ? $CustomTexts : 0,
            );
        }
        else {
            $TicketListHTML = $TicketListObject->Run(
                TicketIDs => [],
            );
        }

    }
    else {

        if ( $Param{Config}{MaxTickets} && $Param{Config}{MaxTickets} - 1 < $#ViewableTickets ) {
            @ViewableTickets = @ViewableTickets[ 0 .. $Param{Config}{MaxTickets} - 1 ];
        }

        $TicketListHTML = $TicketListObject->Run(
            TicketIDs => \@ViewableTickets,
        );

    }

    my $Content = $Kernel::OM->Get('Kernel::Output::HTML::Layout')->Output(
        TemplateFile => 'Dashboard/TileTicketList',
        Data         => {
            TileID         => $Param{TileID},
            TicketListHTML => $TicketListHTML,
            %{ $Param{Config} },
        },
    );

    return '<!-- ZTSM-TILETICKETLIST-PROBE active -->' . $Content;
}

1;
