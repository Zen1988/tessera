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

package Kernel::Modules::CustomerTicketOverview;
## nofilter(TidyAll::Plugin::OTOBO::Perl::DBObject)

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub _ZTSMNormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _ZTSMNormalizeValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

sub _ZTSMNormalizeReferenceValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _ZTSMNormalizeReferenceValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

sub _ZTSMDebugValue {
    my ($Value) = @_;

    return '<undef>' if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return '[' . join( ', ', map { _ZTSMDebugValue($_) } @{$Value} ) . ']';
    }

    if ( ref $Value eq 'HASH' ) {
        return '{'
            . join(
            ', ',
            map {
                $_ . '=' . _ZTSMDebugValue( $Value->{$_} )
            } sort keys %{$Value}
            )
            . '}';
    }

    return $Value;
}

sub _ZTSMCustomerUserMatches {
    my (%Param) = @_;

    my $AssignmentUser = _ZTSMNormalizeReferenceValue( $Param{AssignmentUser} );
    return if !defined $AssignmentUser || $AssignmentUser eq '';

    my $CustomerUserID = _ZTSMNormalizeValue( $Param{CustomerUserID} ) || '<undef>';
    my %CustomerUserID = map { lc $_ => 1 } _ZTSMCustomerUserReferenceIDs(%Param);

    my $Match = $CustomerUserID{ lc $AssignmentUser };

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM Overview support assignment user match: CustomerUserID='
            . $CustomerUserID
            . ' CandidateIDs='
            . join( '|', sort keys %CustomerUserID )
            . ' AssignmentRaw='
            . _ZTSMDebugValue( $Param{AssignmentUser} )
            . ' AssignmentValue='
            . $AssignmentUser
            . ' Match='
            . ( $Match ? 1 : 0 ),
    );

    return $Match;
}

sub _ZTSMCustomerUserReferenceIDs {
    my (%Param) = @_;

    my $CustomerUserID = _ZTSMNormalizeValue( $Param{CustomerUserID} );

    return if !defined $CustomerUserID || $CustomerUserID eq '';

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my %CustomerUserID = ( $CustomerUserID => 1 );

    for my $CustomerID (
        $CustomerUserObject->CustomerIDs(
            User => $CustomerUserID,
        )
        )
    {
        my $Value = _ZTSMNormalizeValue($CustomerID);
        $CustomerUserID{$Value} = 1 if defined $Value && $Value ne '';
    }

    return sort keys %CustomerUserID;
}

sub _ZTSMSupportProfileVariants {
    my (%Param) = @_;

    my $Value = _ZTSMNormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %Value;

    my @SupportProfiles;
    if ( $Value =~ m{\A\d+\z} ) {
        for my $GetParam (
            { GovernanceObjectID => $Value },
            { VersionID    => $Value },
            )
        {
            my $SupportProfile = $GovernanceObjectObject->GovernanceObjectGet(
                %{$GetParam},
                DynamicFields => 1,
                Silent        => 1,
            );

            push @SupportProfiles, $SupportProfile
                if $SupportProfile
                && ( $SupportProfile->{Class} || '' ) eq 'SupportProfile';
        }
    }
    else {
        my @SupportProfileIDs = $GovernanceObjectObject->GovernanceObjectSearch(
            Result  => 'ARRAY',
            Classes => ['SupportProfile'],
            Name    => $Value,
            Limit   => 10,
        );

        for my $SupportProfileID (@SupportProfileIDs) {
            my $SupportProfile = $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $SupportProfileID,
                DynamicFields => 1,
                Silent        => 1,
            );

            push @SupportProfiles, $SupportProfile
                if $SupportProfile;
        }
    }

    for my $SupportProfile (@SupportProfiles) {
        $Value{ $SupportProfile->{GovernanceObjectID} } = 1 if $SupportProfile->{GovernanceObjectID};
        $Value{ $SupportProfile->{LastVersionID} } = 1 if $SupportProfile->{LastVersionID};
        $Value{ $SupportProfile->{Name} }          = 1 if !$Param{ReferenceOnly} && $SupportProfile->{Name};
    }

    $Value{$Value} = 1
        if !$Param{ReferenceOnly}
        || $Value =~ m{\A\d+\z};

    return sort keys %Value;
}

sub _ZTSMSupportProfileList {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM Overview support profile list enter: CustomerUserID='
            . $Param{CustomerUserID},
    );

    my @CustomerUserIDs = _ZTSMCustomerUserReferenceIDs( CustomerUserID => $Param{CustomerUserID} );
    my %AssignmentID;

    my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
        Classes => ['SupportAssignment'],
        Result  => 'ARRAY',
        Limit   => 1000,
    );

    $AssignmentID{$_} = 1 for @FoundAssignmentIDs;

    my @AssignmentIDs = sort { $a <=> $b } keys %AssignmentID;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM Overview support assignment search: CustomerUserID='
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
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment || ref $Assignment ne 'HASH';

        my $AssignmentUser = $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'};

        my $CustomerMatch;
        CUSTOMERUSERID:
        for my $CustomerUserID (@CustomerUserIDs) {
            if (
                _ZTSMCustomerUserMatches(
                    AssignmentUser => $AssignmentUser,
                    CustomerUserID => $CustomerUserID,
                )
                )
            {
                $CustomerMatch = 1;
                last CUSTOMERUSERID;
            }
        }

        next ASSIGNMENT if !$CustomerMatch;

        my $AssignmentSupportProfile = $Assignment->{'DynamicField_ZTSMSupportAssignment-SupportProfile'};
        $AssignmentSupportProfile ||= $Assignment->{XMLData}
            && $Assignment->{XMLData}->{'ZTSMSupportAssignment-SupportProfile'};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'info',
            Message  => 'ZTSM Overview assignment accepted user: AssignmentID='
                . $AssignmentID
                . ' SupportProfileRaw='
                . _ZTSMDebugValue($AssignmentSupportProfile),
        );

        for my $SupportProfile (
            _ZTSMSupportProfileVariants(
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

sub _ZTSMPermissionFilter {
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
            TicketID       => $TicketID,
            CustomerUserID => $Param{CustomerUserID},
            Type           => 'ro',
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

    my %SearchBase = (
        Result  => 'ARRAY',
        SortBy  => $Param{SortBy}  || 'Age',
        OrderBy => $Param{OrderBy} || 'Down',
        UserID  => 1,
    );

    $SearchBase{StateType} = $Param{StateType}
        if $Param{StateType};

    PROFILE:
    for my $SupportProfile ( _ZTSMSupportProfileList( CustomerUserID => $Param{CustomerUserID} ) ) {
        next PROFILE if !$SupportProfile;

        my @ProfileTicketIDs = $TicketObject->TicketSearch(
            %SearchBase,
            'DynamicField_ZTicket-OwnerGroup' => {
                Equals => $SupportProfile,
            },
        );

        for my $TicketID (@ProfileTicketIDs) {
            next if !$TicketID;
            next if $Candidate{$TicketID}++;
            push @Candidate, $TicketID;
        }
    }

    for my $CustomerUserID ( _ZTSMCustomerUserReferenceIDs( CustomerUserID => $Param{CustomerUserID} ) ) {
        next if !$CustomerUserID;

        my @OwnerTicketIDs = $TicketObject->TicketSearch(
            %SearchBase,
            'DynamicField_ZTicket-Owner' => {
                Equals => $CustomerUserID,
            },
        );

        for my $TicketID (@OwnerTicketIDs) {
            next if !$TicketID;
            next if $Candidate{$TicketID}++;
            push @Candidate, $TicketID;
        }
    }

    if ( $Param{CustomerUserLogin} && $Param{CustomerUserLogin} ne $Param{CustomerUserID} ) {
        for my $CustomerUserLogin ( _ZTSMCustomerUserReferenceIDs( CustomerUserID => $Param{CustomerUserLogin} ) ) {
            next if !$CustomerUserLogin;

            my @OwnerTicketIDs = $TicketObject->TicketSearch(
                %SearchBase,
                'DynamicField_ZTicket-Owner' => {
                    Equals => $CustomerUserLogin,
                },
            );

            for my $TicketID (@OwnerTicketIDs) {
                next if !$TicketID;
                next if $Candidate{$TicketID}++;
                push @Candidate, $TicketID;
            }
        }
    }

    return _ZTSMPermissionFilter(
        CustomerUserID => $Param{CustomerUserID},
        TicketIDs      => \@Candidate,
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM CustomerTicketOverview Run enter: UserID='
            . ( $Self->{UserID} // '<undef>' )
            . ' Subaction='
            . ( $Self->{Subaction} // '<undef>' ),
    );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    # disable output of customer company tickets
    my $DisableCompanyTickets = $ConfigObject->Get('Ticket::Frontend::CustomerDisableCompanyTicketAccess');

    # check subaction
    if ( !$Self->{Subaction} ) {
        return $LayoutObject->Redirect(
            OP => 'Action=CustomerTicketOverview;Subaction=MyTickets',
        );
    }
    elsif ( $Self->{Subaction} eq 'CompanyTickets' && $DisableCompanyTickets ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    # check needed CustomerID
    if ( !$Self->{UserCustomerID} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => Translatable('Need CustomerID!'),
        );
        $Output .= $LayoutObject->CustomerFooter();

        return $Output;
    }

    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenOverview',
        Value     => $Self->{RequestedURL},
    );

    my $SortBy         = $ParamObject->GetParam( Param => 'SortBy' )  || 'Age';
    my $OrderByCurrent = $ParamObject->GetParam( Param => 'OrderBy' ) || 'Down';
    my $Fulltext       = $ParamObject->GetParam( Param => 'Fulltext' );

    # filter definition
    my %Filters = (
        MyTickets => {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    CustomerUserLoginRaw => $Self->{UserID},
                    OrderBy              => $OrderByCurrent,
                    SortBy               => $SortBy,
                    CustomerUserID       => $Self->{UserID},
                    Permission           => 'ro',
                },
            },
            Open => {
                Name   => 'Open',
                Prio   => 1100,
                Search => {
                    CustomerUserLoginRaw => $Self->{UserID},
                    StateType            => 'CustomerOpen',
                    OrderBy              => $OrderByCurrent,
                    SortBy               => $SortBy,
                    CustomerUserID       => $Self->{UserID},
                    Permission           => 'ro',
                },
            },
            Closed => {
                Name   => 'Closed',
                Prio   => 1200,
                Search => {
                    CustomerUserLoginRaw => $Self->{UserID},
                    StateType            => 'CustomerClosed',
                    OrderBy              => $OrderByCurrent,
                    SortBy               => $SortBy,
                    CustomerUserID       => $Self->{UserID},
                    Permission           => 'ro',
                },
            },
        },
    );

    my $UserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    my @CustomerIDs;

    # Add filter for customer company if the company tickets are not disabled.
    if ( !$DisableCompanyTickets ) {
        my %AccessibleCustomers = $Kernel::OM->Get('Kernel::System::CustomerGroup')->GroupContextCustomers(
            CustomerUserID => $Self->{UserID},
        );

        # Show customer companies as additional filter selection.
        if ( $Self->{Subaction} eq 'CompanyTickets' && scalar keys %AccessibleCustomers > 1 ) {

            @CustomerIDs = $ParamObject->GetArray( Param => 'CustomerIDs' );

            # Prevent array item duplication.
            my %CustomerIDsHash = map { $_ => 1 } @CustomerIDs;
            @CustomerIDs = sort keys %CustomerIDsHash;

            $Param{CustomerIDStrg} = $LayoutObject->BuildSelection(
                Data       => \%AccessibleCustomers,
                Name       => 'CustomerIDs',
                Multiple   => 1,
                Size       => 1,
                SelectedID => \@CustomerIDs,
                Class      => 'Modernize',
            );

            # Remember the active customer ID filter.
            $Param{CustomerIDs} = '';
            for my $CustomerID (@CustomerIDs) {
                $Param{CustomerIDs} .= ';CustomerIDs=' . $LayoutObject->LinkEncode($CustomerID);
            }
        }
        else {

            # Default behavior - use all available customer IDs.
            @CustomerIDs = sort keys %AccessibleCustomers;
        }

        $Filters{CompanyTickets} = {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    CustomerIDRaw  => \@CustomerIDs,
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $Self->{UserID},
                    Permission     => 'ro',
                },
            },
            Open => {
                Name   => 'Open',
                Prio   => 1100,
                Search => {
                    CustomerIDRaw  => \@CustomerIDs,
                    StateType      => 'CustomerOpen',
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $Self->{UserID},
                    Permission     => 'ro',
                },
            },
            Closed => {
                Name   => 'Closed',
                Prio   => 1200,
                Search => {
                    CustomerIDRaw  => \@CustomerIDs,
                    StateType      => 'CustomerClosed',
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $Self->{UserID},
                    Permission     => 'ro',
                },
            },
        };
    }

    if ( $Self->{Subaction} eq 'Search' ) {

        # check whether company tickets are shown
        my %Selection = @CustomerIDs
            ?
            ( CustomerIDRaw => \@CustomerIDs )
            :
            ( CustomerUserLoginRaw => $Self->{UserID} );

        $Filters{Search} = {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    %Selection,
                    OrderBy             => $OrderByCurrent,
                    SortBy              => $SortBy,
                    CustomerUserID      => $Self->{UserID},
                    Permission          => 'ro',
                    Fulltext            => $Fulltext,
                    FullTextIndex       => 1,
                    ContentSearchPrefix => '*',
                    ContentSearchSuffix => '*',
                },
            },
            Open => {
                Name   => 'Open',
                Prio   => 1100,
                Search => {
                    %Selection,
                    StateType           => 'CustomerOpen',
                    OrderBy             => $OrderByCurrent,
                    SortBy              => $SortBy,
                    CustomerUserID      => $Self->{UserID},
                    Permission          => 'ro',
                    Fulltext            => $Fulltext,
                    FullTextIndex       => 1,
                    ContentSearchPrefix => '*',
                    ContentSearchSuffix => '*',
                },
            },
            Closed => {
                Name   => 'Closed',
                Prio   => 1200,
                Search => {
                    %Selection,
                    StateType           => 'CustomerClosed',
                    OrderBy             => $OrderByCurrent,
                    SortBy              => $SortBy,
                    CustomerUserID      => $Self->{UserID},
                    Permission          => 'ro',
                    Fulltext            => $ParamObject->GetParam( Param => 'Fulltext' ),
                    FullTextIndex       => 1,
                    ContentSearchPrefix => '*',
                    ContentSearchSuffix => '*',
                },
            },
        };
    }

    my $FilterCurrent = $ParamObject->GetParam( Param => 'Filter' );
    if ( !$FilterCurrent ) {
        $FilterCurrent = ( $Self->{Subaction} && $Self->{Subaction} eq 'Search' ) ? 'All' : 'Open';
    }

    # check if filter is valid
    if ( !$Filters{ $Self->{Subaction} }->{$FilterCurrent} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Invalid Filter: %s!', $FilterCurrent ),
        );
        $Output .= $LayoutObject->CustomerFooter();

        return $Output;
    }

    # check if archive search is allowed, otherwise search for all tickets
    my %SearchInArchive;
    if (
        $ConfigObject->Get('Ticket::ArchiveSystem')
        && !$ConfigObject->Get('Ticket::CustomerArchiveSystem')
        )
    {
        $SearchInArchive{ArchiveFlags} = [ 'y', 'n' ];
    }

    my %NavBarFilter;
    my $Counter         = 0;
    my $AllTickets      = 0;
    my $AllTicketsTotal = 0;
    my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
    my %ZTSMFilterTicketIDs;
    my %StandardFilterTicketIDs;

    for my $Filter ( sort keys %{ $Filters{ $Self->{Subaction} } } ) {
        $Counter++;

        my @StandardTicketIDs = $TicketObject->TicketSearch(
            %{ $Filters{ $Self->{Subaction} }->{$Filter}->{Search} },
            %SearchInArchive,
            Result => 'ARRAY',
        );
        $StandardFilterTicketIDs{$Filter} = \@StandardTicketIDs;

        my @ZTSMWorkableTicketIDs = _ZTSMWorkableTicketIDs(
            CustomerUserID    => $Self->{UserID},
            CustomerUserLogin => $Self->{UserLogin},
            StateType         => $Filters{ $Self->{Subaction} }->{$Filter}->{Search}->{StateType},
            SortBy            => $SortBy,
            OrderBy           => $OrderByCurrent,
        );
        $ZTSMFilterTicketIDs{$Filter} = \@ZTSMWorkableTicketIDs;

        my %Counted;
        my $Count = grep { !$Counted{$_}++ } ( @StandardTicketIDs, @ZTSMWorkableTicketIDs );

        my $ClassA = '';
        if ( $Filter eq $FilterCurrent ) {
            $ClassA     = 'Selected';
            $AllTickets = $Count;
        }
        if ( $Filter eq 'All' ) {
            $AllTicketsTotal = $Count;
        }
        $NavBarFilter{ $Filters{ $Self->{Subaction} }->{$Filter}->{Prio} } = {
            %{ $Filters{ $Self->{Subaction} }->{$Filter} },
            Count  => $Count,
            Filter => $Filter,
            ClassA => $ClassA,
        };
    }

    my $StartHit  = int( $ParamObject->GetParam( Param => 'StartHit' ) || 1 );
    my $PageShown = $Self->{UserShowTickets} || 1;
    my $TicketListHTML;
    my %PageNav;

    if ( !$AllTicketsTotal ) {

        my $CustomTexts = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverviewCustomEmptyText');

        # show message if there are no tickets
        my $TicketListObject = $Kernel::OM->Get('Kernel::Output::HTML::TicketOverview::CustomerList');
        $TicketListHTML = $TicketListObject->Run(
            TicketIDs   => [],
            NoAllTotal  => $Self->{Subaction} eq 'Search' ? 0            : 1,
            CustomTexts => ( ref $CustomTexts eq 'HASH' ) ? $CustomTexts : 0,
        );

    }
    else {

        if ( $AllTickets > $PageShown ) {

            # create pagination
            my $Link = 'SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
                . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderByCurrent )
                . ';Filter=' . $LayoutObject->Ascii2Html( Text => $FilterCurrent )
                . ';Subaction=' . $LayoutObject->Ascii2Html( Text => $Self->{Subaction} )
                . ';';

            # remember fulltext query
            if ( defined $Fulltext ) {
                $Link .= 'Fulltext=' . $LayoutObject->Ascii2Html( Text => $Fulltext ) . ';';
            }

            # Add CustomerIDs parameter if needed.
            if ( IsArrayRefWithData( \@CustomerIDs ) ) {
                for my $CustomerID (@CustomerIDs) {
                    $Link .= "CustomerIDs=$CustomerID;";
                }
            }

            %PageNav = $LayoutObject->PageNavBar(
                Limit     => 10000,
                StartHit  => $StartHit,
                PageShown => $PageShown,
                AllHits   => $AllTickets,
                Action    => 'Action=CustomerTicketOverview',
                Link      => $Link,
                IDPrefix  => 'CustomerTicketOverview',
            );
        }

        my $OrderBy = 'Down';
        if ( $OrderByCurrent eq 'Down' ) {
            $OrderBy = 'Up';
        }
        my $Sort       = '';
        my $StateSort  = '';
        my $TicketSort = '';
        my $TitleSort  = '';
        my $AgeSort    = '';
        my $QueueSort  = '';
        my $OwnerSort  = '';

        # this sets the opposite to the $OrderBy
        if ( $OrderBy eq 'Down' ) {
            $Sort = 'SortAscending';
        }
        if ( $OrderBy eq 'Up' ) {
            $Sort = 'SortDescending';
        }

        if ( $SortBy eq 'State' ) {
            $StateSort = $Sort;
        }
        elsif ( $SortBy eq 'Ticket' ) {
            $TicketSort = $Sort;
        }
        elsif ( $SortBy eq 'Title' ) {
            $TitleSort = $Sort;
        }
        elsif ( $SortBy eq 'Age' ) {
            $AgeSort = $Sort;
        }
        elsif ( $SortBy eq 'Queue' ) {
            $QueueSort = $Sort;
        }
        elsif ( $SortBy eq 'Owner' ) {
            $OwnerSort = $Sort;
        }

        my $Owner = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Owner};
        my $Queue = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Queue};

        if ($Owner) {
            $LayoutObject->Block(
                Name => 'OverviewNavBarPageOwner',
                Data => {
                    OrderBy   => $OrderBy,
                    OwnerSort => $OwnerSort,
                    Filter    => $FilterCurrent,
                },
            );
        }

        if ($Queue) {
            $LayoutObject->Block(
                Name => 'OverviewNavBarPageQueue',
                Data => {
                    OrderBy   => $OrderBy,
                    QueueSort => $QueueSort,
                    Filter    => $FilterCurrent,
                },
            );
        }

        # show header filter
        for my $Key ( sort keys %NavBarFilter ) {
            $LayoutObject->Block(
                Name => 'FilterHeader',
                Data => {
                    %Param,
                    %{ $NavBarFilter{$Key} },
                    Fulltext => $ParamObject->GetParam( Param => 'Fulltext' ),
                },
            );
        }

        # get the dynamic fields for this screen
        my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        # get dynamic field config for frontend module
        my $DynamicFieldFilter = $ConfigObject->Get("Ticket::Frontend::CustomerTicketOverview")->{DynamicField};
        my $DynamicField       = $DynamicFieldObject->DynamicFieldListGet(
            Valid       => 1,
            ObjectType  => ['Ticket'],
            FieldFilter => $DynamicFieldFilter || {},
        );

        # reduce the dynamic fields to only the ones that are desinged for customer interface
        my @CustomerDynamicFields;
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsCustomerInterfaceCapable',
            );
            next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

            push @CustomerDynamicFields, $DynamicFieldConfig;
        }
        $DynamicField = \@CustomerDynamicFields;

        # Dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $Label = $DynamicFieldConfig->{Label};

            # get field sortable condition
            my $IsSortable = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsSortable',
            );

            if ($IsSortable) {
                my $CSS = '';
                if (
                    $SortBy
                    && ( $SortBy eq ( 'DynamicField_' . $DynamicFieldConfig->{Name} ) )
                    )
                {
                    if ( $OrderByCurrent && ( $OrderByCurrent eq 'Up' ) ) {
                        $OrderBy = 'Down';
                        $CSS .= ' SortDescending';
                    }
                    else {
                        $OrderBy = 'Up';
                        $CSS .= ' SortAscending';
                    }
                }

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField',
                    Data => {
                        %Param,
                        CSS => $CSS,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicFieldSortable',
                    Data => {
                        %Param,
                        OrderBy          => $OrderBy,
                        Label            => $Label,
                        DynamicFieldName => $DynamicFieldConfig->{Name},
                        Filter           => $FilterCurrent,
                    },
                );

                # example of dynamic fields order customization
                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_' . $DynamicFieldConfig->{Name},
                    Data => {
                        %Param,
                        CSS => $CSS,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_'
                        . $DynamicFieldConfig->{Name}
                        . '_Sortable',
                    Data => {
                        %Param,
                        OrderBy          => $OrderBy,
                        Label            => $Label,
                        DynamicFieldName => $DynamicFieldConfig->{Name},
                        Filter           => $FilterCurrent,
                    },
                );
            }
            else {

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField',
                    Data => {
                        %Param,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicFieldNotSortable',
                    Data => {
                        %Param,
                        Label => $Label,
                    },
                );

                # example of dynamic fields order customization
                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_' . $DynamicFieldConfig->{Name},
                    Data => {
                        %Param,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_'
                        . $DynamicFieldConfig->{Name}
                        . '_NotSortable',
                    Data => {
                        %Param,
                        Label => $Label,
                    },
                );
            }
        }

        my @ViewableTickets = @{ $StandardFilterTicketIDs{$FilterCurrent} || [] };

        my @ZTSMWorkableTicketIDs = _ZTSMWorkableTicketIDs(
            CustomerUserID    => $Self->{UserID},
            CustomerUserLogin => $Self->{UserLogin},
            StateType         => $Filters{ $Self->{Subaction} }->{$FilterCurrent}->{Search}->{StateType},
            SortBy            => $SortBy,
            OrderBy           => $OrderByCurrent,
        );
        @ZTSMWorkableTicketIDs = @{ $ZTSMFilterTicketIDs{$FilterCurrent} || [] }
            if $ZTSMFilterTicketIDs{$FilterCurrent};

        if (@ZTSMWorkableTicketIDs) {
            my %Seen;
            @ViewableTickets = grep { !$Seen{$_}++ } ( @ViewableTickets, @ZTSMWorkableTicketIDs );
        }

        # show tickets
        #       $Counter = 0;
        #       for my $TicketID (@ViewableTickets) {
        #           $Counter++;
        #           if (
        #               $Counter >= $StartHit
        #               && $Counter < ( $PageShown + $StartHit )
        #               )
        #           {
        #               $Self->ShowTicketStatus( TicketID => $TicketID );
        #           }
        #       }

        my $TicketListObject = $Kernel::OM->Get('Kernel::Output::HTML::TicketOverview::CustomerList');
        $TicketListHTML = $TicketListObject->Run(
            StartHit  => $StartHit,
            PageShown => $PageShown,
            TicketIDs => \@ViewableTickets,
        );

    }

    # create & return output
    my $Title = $Self->{Subaction};
    if ( $Title eq 'MyTickets' ) {
        $Title = Translatable('My Tickets');
    }
    elsif ( $Title eq 'CompanyTickets' ) {
        $Title = Translatable('Company Tickets');
    }
    my $Refresh = '';
    if ( $Self->{UserRefreshTime} ) {
        $Refresh = 60 * $Self->{UserRefreshTime};
    }
    my $Output = $LayoutObject->CustomerHeader(
        Title   => $Title,
        Refresh => $Refresh,
    );

    # AddJSData for ES
    my $ESActive = $ConfigObject->Get('Elasticsearch::Active');

    $LayoutObject->AddJSData(
        Key   => 'ESActive',
        Value => $ESActive,
    );

    my $NewTicketAccessKey = $ConfigObject->Get('CustomerFrontend::Navigation')->{'CustomerTicketMessage'}{'002-Ticket'}[0]{'AccessKey'}
        || '';

    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerTicketOverview',
        Data         => {
            %Param,
            %PageNav,
            AccessKey      => $NewTicketAccessKey,
            TicketListHTML => $TicketListHTML,
            Fulltext       => $ParamObject->GetParam( Param => 'Fulltext' ),
        },
    );

    # build NavigationBar
    $Output .= $LayoutObject->CustomerNavigationBar();

    # get page footer
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

# ShowTicket
sub ShowTicketStatus {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject              = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $CommunicationChannelObject = $Kernel::OM->Get('Kernel::System::CommunicationChannel');
    my $TicketID                   = $Param{TicketID} || return;

    # Get last customer article.
    my @ArticleList = $ArticleObject->ArticleList(
        TicketID             => $Param{TicketID},
        IsVisibleForCustomer => 1,
        OnlyLast             => 1,
    );

    my %Article;
    if ( $ArticleList[0] && IsHashRefWithData( $ArticleList[0] ) ) {
        my $ArticleBackendObject = $ArticleObject->BackendForArticle( %{ $ArticleList[0] } );
        %Article = $ArticleBackendObject->ArticleGet(
            TicketID  => $Param{TicketID},
            ArticleID => $ArticleList[0]->{ArticleID},
        );
    }

    # get ticket info
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 0,
    );

    my $Subject;
    my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
    my $SmallViewColumnHeader = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{ColumnHeader};

    # Check if the last customer subject or ticket title should be shown.
    if ( $SmallViewColumnHeader eq 'LastCustomerSubject' ) {
        $Subject = $Article{Subject} || '';
    }
    else {
        $Subject = $Ticket{Title};
    }

    # Condense down the subject.
    $Subject = $TicketObject->TicketSubjectClean(
        TicketNumber => $Ticket{TicketNumber},
        Subject      => $Subject,
    );

    # Age design.
    $Ticket{CustomerAge} = $LayoutObject->CustomerAge(
        Age   => $Ticket{Age},
        Space => ' '
    ) || 0;

    # return ticket information if there is no article
    if ( !IsHashRefWithData( \%Article ) ) {
        $Article{State}        = $Ticket{State};
        $Article{TicketNumber} = $Ticket{TicketNumber};
        $Article{Body}         = $LayoutObject->{LanguageObject}->Translate('This item has no articles yet.');
    }

    # customer info (customer name)
    if ( $Article{CustomerUserID} ) {
        $Param{CustomerName} = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
            UserLogin => $Article{CustomerUserID},
        );
        $Param{CustomerName} = '(' . $Param{CustomerName} . ')' if ( $Param{CustomerName} );
    }

    # add block
    $LayoutObject->Block(
        Name => 'Record',
        Data => {
            %Article,
            %Ticket,
            Subject => $Subject,
            %Param,
        },
    );

    my $Owner = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Owner};
    my $Queue = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Queue};

    if ($Owner) {
        my $OwnerName = $Kernel::OM->Get('Kernel::System::User')->UserName( UserID => $Ticket{OwnerID} );
        $LayoutObject->Block(
            Name => 'RecordOwner',
            Data => {
                OwnerName => $OwnerName,
            },
        );
    }
    if ($Queue) {
        $LayoutObject->Block(
            Name => 'RecordQueue',
            Data => {
                %Ticket,
            },
        );
    }

    # get the dynamic fields for this screen
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # get dynamic field config for frontend module
    my $DynamicFieldFilter = $ConfigObject->Get("Ticket::Frontend::CustomerTicketOverview")->{DynamicField};
    my $DynamicField       = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => ['Ticket'],
        FieldFilter => $DynamicFieldFilter || {},
    );

    # reduce the dynamic fields to only the ones that are desinged for customer interface
    my @CustomerDynamicFields;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsCustomerInterfaceCapable',
        );
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        push @CustomerDynamicFields, $DynamicFieldConfig;
    }
    $DynamicField = \@CustomerDynamicFields;

    # Dynamic fields
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # get field value
        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Ticket{TicketID},
        );

        my $ValueStrg = $BackendObject->DisplayValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            ValueMaxChars      => 20,
            LayoutObject       => $LayoutObject,
        );

        $LayoutObject->Block(
            Name => 'RecordDynamicField',
            Data => {
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );

        if ( $ValueStrg->{Link} ) {
            $LayoutObject->Block(
                Name => 'RecordDynamicFieldLink',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $ValueStrg->{Link},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'RecordDynamicFieldPlain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }

        # example of dynamic fields order customization
        $LayoutObject->Block(
            Name => 'RecordDynamicField' . $DynamicFieldConfig->{Name},
            Data => {
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );

        if ( $ValueStrg->{Link} ) {
            $LayoutObject->Block(
                Name => 'RecordDynamicField' . $DynamicFieldConfig->{Name} . 'Link',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $ValueStrg->{Link},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'RecordDynamicField' . $DynamicFieldConfig->{Name} . 'Plain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }
    }

    return;
}

1;
