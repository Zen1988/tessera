# --
# Kernel/System/Ticket/CustomerPermission/ZTSMUserIDCheck.pm
# --
# Tessera Orchestration Permission Engine
#
# Purpose:
#   - Story visibility inheritance
#   - Runtime orchestration participation
#   - Support profile participation
#   - Direct ownership visibility
#
# Powered by Zen ☕
# --

package Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::CustomerGroup',
    'Kernel::System::CustomerUser',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Group',
    'Kernel::System::User',
);

# ------------------------------------------------------------ #
# NEW
# ------------------------------------------------------------ #

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

# ------------------------------------------------------------ #
# NORMALIZE VALUE
# ------------------------------------------------------------ #

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
        Priority => 'debug',
        Message  => 'ZTSM Permission support assignment user match: CustomerUserID='
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

# ------------------------------------------------------------ #
# GET TICKET DYNAMIC FIELD
# ------------------------------------------------------------ #

sub _GetTicketDynamicField {
    my ( %Param ) = @_;

    return if !$Param{Ticket};
    return if !$Param{Field};

    return _NormalizeValue(
        $Param{Ticket}->{ 'DynamicField_' . $Param{Field} }
    );
}

sub _GovernanceObjectReferenceValues {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @GovernanceObjects;

    if ( $Value =~ m{\A\d+\z} ) {
        for my $Lookup (
            { GovernanceObjectID => $Value },
            { VersionID          => $Value },
            )
        {
            my $GovernanceObject = eval {
                $GovernanceObjectObject->GovernanceObjectGet(
                    %{$Lookup},
                    DynamicFields => 0,
                    Silent        => 1,
                );
            };
            push @GovernanceObjects, $GovernanceObject
                if $GovernanceObject && ref $GovernanceObject eq 'HASH';
        }
    }
    else {
        my @GovernanceObjectIDs = $GovernanceObjectObject->GovernanceObjectSearch(
            Result  => 'ARRAY',
            Classes => [ $Param{Class} ],
            Name    => $Value,
            Limit   => 10,
            UserID  => $Param{UserID} || 1,
        );

        for my $GovernanceObjectID (@GovernanceObjectIDs) {
            my $GovernanceObject = eval {
                $GovernanceObjectObject->GovernanceObjectGet(
                    GovernanceObjectID => $GovernanceObjectID,
                    DynamicFields      => 0,
                    Silent             => 1,
                );
            };
            push @GovernanceObjects, $GovernanceObject
                if $GovernanceObject && ref $GovernanceObject eq 'HASH';
        }
    }

    my %Reference;
    for my $GovernanceObject (@GovernanceObjects) {
        next if ( $GovernanceObject->{Class} || '' ) ne $Param{Class};

        $Reference{ $GovernanceObject->{GovernanceObjectID} } = 1 if $GovernanceObject->{GovernanceObjectID};
        $Reference{ $GovernanceObject->{LastVersionID} }      = 1 if $GovernanceObject->{LastVersionID};
        $Reference{ $GovernanceObject->{VersionID} }          = 1 if $GovernanceObject->{VersionID};
    }

    return sort { $a <=> $b } grep { defined $_ && $_ =~ m{\A\d+\z} } keys %Reference;
}

sub _OwnerGroupAssignmentIDs {
    my (%Param) = @_;

    my @SupportProfileReferences = _GovernanceObjectReferenceValues(
        Value  => $Param{OwnerGroup},
        Class  => 'SupportProfile',
        UserID => $Param{UserID},
    );
    my @RoleReferences = @SupportProfileReferences ? () : _GovernanceObjectReferenceValues(
        Value  => $Param{OwnerGroup},
        Class  => 'GovernanceRole',
        UserID => $Param{UserID},
    );

    return if !@SupportProfileReferences && !@RoleReferences;

    my @ApplicationReferences;
    if (@RoleReferences) {
        @ApplicationReferences = _GovernanceObjectReferenceValues(
            Value  => $Param{ApplicationID},
            Class  => 'Application',
            UserID => $Param{UserID},
        );
        return if defined $Param{ApplicationID} && $Param{ApplicationID} ne '' && !@ApplicationReferences;
    }

    my @CustomerUserIDs = _CustomerUserReferenceIDs(
        CustomerUserID => $Param{CustomerUserID},
    );
    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %AssignmentID;

    for my $CustomerUserID (@CustomerUserIDs) {
        for my $SupportProfile (@SupportProfileReferences) {
            my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
                Classes => ['SupportAssignment'],
                'DynamicField_ZTSMSupportAssignment-SupportProfile' => {
                    Equals => $SupportProfile,
                },
                'DynamicField_ZTSMSupportAssignment-UserAccount' => {
                    Equals => $CustomerUserID,
                },
                Result => 'ARRAY',
                Limit  => 100,
                UserID => $Param{UserID} || 1,
            );
            $AssignmentID{$_} = 1 for @FoundAssignmentIDs;
        }

        for my $Role (@RoleReferences) {
            my %BaseSearch = (
                Classes => ['SupportAssignment'],
                'DynamicField_ZTSMSupportAssignment-Role' => {
                    Equals => $Role,
                },
                'DynamicField_ZTSMSupportAssignment-UserAccount' => {
                    Equals => $CustomerUserID,
                },
                Result => 'ARRAY',
                Limit  => 100,
                UserID => $Param{UserID} || 1,
            );

            if (@ApplicationReferences) {
                for my $Application (@ApplicationReferences) {
                    my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
                        %BaseSearch,
                        'DynamicField_ZTSMSupportAssignment-Application' => {
                            Equals => $Application,
                        },
                    );
                    $AssignmentID{$_} = 1 for @FoundAssignmentIDs;
                }
            }
            else {
                my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(%BaseSearch);
                $AssignmentID{$_} = 1 for @FoundAssignmentIDs;
            }
        }
    }

    return sort { $a <=> $b } keys %AssignmentID;
}

# ------------------------------------------------------------ #
# GET SUPPORT ASSIGNMENT
# ------------------------------------------------------------ #

sub _UserParticipateSupportProfile {
    my ( %Param ) = @_;

    return if !$Param{SupportProfile};
    return if !$Param{CustomerUserID};

    my $GovernanceObjectObject = $Kernel::OM->Get(
        'Kernel::System::GovernanceObject'
    );

    my @AssignmentIDs = _OwnerGroupAssignmentIDs(
        OwnerGroup     => $Param{SupportProfile},
        ApplicationID => $Param{ApplicationID},
        CustomerUserID => $Param{CustomerUserID},
        UserID         => $Param{UserID},
    );

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM Permission support assignment search result: CustomerUserID='
            . $Param{CustomerUserID}
            . ' AssignmentIDs='
            . join( '|', @AssignmentIDs )
            . ' OwnerGroup='
            . $Param{SupportProfile}
            . ' Count='
            . scalar @AssignmentIDs,
    );

    return if !@AssignmentIDs;

    ASSIGNMENT:
    for my $AssignmentID (@AssignmentIDs) {

        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(

            GovernanceObjectID => $AssignmentID,

            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment;

        my $AssignmentUser = $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'};

        next ASSIGNMENT if !_CustomerUserMatches(
            AssignmentUser => $AssignmentUser,
            CustomerUserID => $Param{CustomerUserID},
        );

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'info',
            Message  => 'ZTSM Permission assignment accepted user: AssignmentID='
                . $AssignmentID
                . ' OwnerGroup='
                . $Param{SupportProfile},
        );

        return 1;

        my $Type = _NormalizeValue(
            $Assignment->{XMLData}
                ->{'ZTSMSupportAssignment-Type'}
                ->{Content}
        );

        #
        # ALL means universal participation
        #

        return 1
            if $Type eq 'ALL';

        #
        # Ticket Role Match
        #

        return 1
            if (
                defined $Param{Role}
                && $Param{Role} eq $Type
            );
    }

    return;
}

sub _UserHasSupportAssignmentType {
    my (%Param) = @_;

    return if !$Param{SupportProfile};
    return if !$Param{CustomerUserID};
    return if !$Param{AssignmentType};

    my $GovernanceObjectObject = $Kernel::OM->Get(
        'Kernel::System::GovernanceObject'
    );

    my @AssignmentIDs = _OwnerGroupAssignmentIDs(
        OwnerGroup      => $Param{SupportProfile},
        ApplicationID  => $Param{ApplicationID},
        CustomerUserID => $Param{CustomerUserID},
        UserID          => $Param{UserID},
    );

    return if !@AssignmentIDs;

    ASSIGNMENT:
    for my $AssignmentID (@AssignmentIDs) {
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment;

        my $AssignmentUser = $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'};

        next ASSIGNMENT if !_CustomerUserMatches(
            AssignmentUser => $AssignmentUser,
            CustomerUserID => $Param{CustomerUserID},
        );

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'info',
            Message  => 'ZTSM Permission failback assignment accepted user: AssignmentID='
                . $AssignmentID
                . ' OwnerGroup='
                . $Param{SupportProfile},
        );

        my $Type = _NormalizeValue(
            $Assignment->{XMLData}
                ->{'ZTSMSupportAssignment-Type'}
                ->{Content}
        );

        return 1
            if defined $Type
            && $Type eq $Param{AssignmentType};
    }

    return;
}

sub _IsIPCAgent {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    return 1
        if $Kernel::OM->Get('Kernel::System::CustomerGroup')->PermissionCheck(
        UserID    => $Param{CustomerUserID},
        GroupName => 'IPC',
        Type      => 'rw',
        );

    my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
        UserLogin => $Param{CustomerUserID},
        Silent    => 1,
    );

    return if !$UserID;

    return $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID    => $UserID,
        GroupName => 'IPC',
        Type      => 'rw',
    );
}

# ------------------------------------------------------------ #
# CHECK PARTICIPATION
# ------------------------------------------------------------ #

sub _CanParticipateTicket {
    my ( %Param ) = @_;

    return if !$Param{Ticket};
    return if !$Param{CustomerUserID};

    my $Ticket = $Param{Ticket};

    #
    # Direct Owner
    #

    my $Owner = _GetTicketDynamicField(

        Ticket => $Ticket,

        Field => 'ZTicket-Owner',
    );

    if (
        defined $Owner
        && lc $Owner eq lc $Param{CustomerUserID}
    ) {
        return 1;
    }

    #
    # Support Profile Participation
    #

    my $OwnerGroup = _GetTicketDynamicField(

        Ticket => $Ticket,

        Field => 'ZTicket-OwnerGroup',
    );

    my $Role = _GetTicketDynamicField(

        Ticket => $Ticket,

        Field => 'ZTicket-Role',
    );

    return 1
        if _UserParticipateSupportProfile(

            SupportProfile => $OwnerGroup,

            CustomerUserID => $Param{CustomerUserID},

            ApplicationID => _GetTicketDynamicField(
                Ticket => $Ticket,
                Field  => 'ZTicket-Application',
            ),

            Role => $Role,
        );

    return;
}

# ------------------------------------------------------------ #
# CHECK STORY INHERITANCE
# ------------------------------------------------------------ #

sub _CanViewStory {
    my ( %Param ) = @_;

    return if !$Param{Ticket};
    return if !$Param{CustomerUserID};

    my $Ticket = $Param{Ticket};

    my $ParentID = _GetTicketDynamicField(

        Ticket => $Ticket,

        Field => 'ZTicket-Parent',
    );

    my $TicketObject = $Kernel::OM->Get(
        'Kernel::System::Ticket'
    );

    my @StoryRoots;

    if ($ParentID) {
        push @StoryRoots, $ParentID;
    }

    if ( $Ticket->{TicketID} ) {
        push @StoryRoots, $Ticket->{TicketID};
    }

    #
    # Find sibling/child ChapterPlay tickets.
    #

    ROOT:
    for my $StoryRoot (@StoryRoots) {

        next ROOT if !$StoryRoot;

        my @TicketIDs = $TicketObject->TicketSearch(

            Result => 'ARRAY',

            Limit => 1000,

            'DynamicField_ZTicket-Parent' => {
                Equals => $StoryRoot,
            },

            UserID => 1,
        );

        next ROOT if !@TicketIDs;

        SIBLING:
        for my $TicketID (@TicketIDs) {

            my %PlayTicket = $TicketObject->TicketGet(

                TicketID      => $TicketID,

                DynamicFields => 1,

                UserID        => 1,
            );

            next SIBLING if !%PlayTicket;

            #
            # Local ticket participation check
            #

            return 1
                if _CanParticipateTicket(

                    Ticket => \%PlayTicket,

                    CustomerUserID => $Param{CustomerUserID},
                );
        }
    }

    return;
}

# ------------------------------------------------------------ #
# RUN
# ------------------------------------------------------------ #

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get(
        'Kernel::System::Log'
    );

    return if !$Param{TicketID};

    my $CustomerUserID = $Param{CustomerUserID} || $Param{UserID};

    return if !$CustomerUserID;

    my $PermissionType = $Param{Type} || '';
    return if $PermissionType ne 'ro' && $PermissionType ne 'ztsm_action' && $PermissionType ne 'ztsm_failback';

    $LogObject->Log(
        Priority => 'debug',
        Message  => 'ZTSMUserIDCheck Run enter: TicketID='
            . $Param{TicketID}
            . ' CustomerUserID='
            . $CustomerUserID
            . ' Type='
            . $PermissionType,
    );

    my $TicketObject = $Kernel::OM->Get(
        'Kernel::System::Ticket'
    );

    my %Ticket = $TicketObject->TicketGet(

        TicketID      => $Param{TicketID},

        DynamicFields => 1,

        UserID        => 1,
    );

    return if !%Ticket;

    if (
        $PermissionType eq 'ro'
        && _IsIPCAgent(
            CustomerUserID => $CustomerUserID,
        )
        )
    {
        $LogObject->Log(
            Priority => 'info',
            Message  =>
                  'TESSERA UserIDCheck: '
                . 'IPC global read access granted '
                . "TicketID=$Param{TicketID} "
                . "CustomerUserID=$CustomerUserID",
        );

        return 1;
    }

    if ( $PermissionType eq 'ztsm_action' ) {
        my $Owner = _GetTicketDynamicField(
            Ticket => \%Ticket,
            Field  => 'ZTicket-Owner',
        );

        return 1
            if defined $Owner
            && $Owner ne ''
            && lc $Owner eq lc $CustomerUserID;

        return
            if defined $Owner
            && $Owner ne '';

        my $OwnerGroup = _GetTicketDynamicField(
            Ticket => \%Ticket,
            Field  => 'ZTicket-OwnerGroup',
        );

        my $Role = _GetTicketDynamicField(
            Ticket => \%Ticket,
            Field  => 'ZTicket-Role',
        );

        return 1
            if _UserParticipateSupportProfile(
            SupportProfile => $OwnerGroup,
            CustomerUserID => $CustomerUserID,
            ApplicationID  => _GetTicketDynamicField(
                Ticket => \%Ticket,
                Field  => 'ZTicket-Application',
            ),
            Role           => $Role,
            );

        return;
    }

    if ( $PermissionType eq 'ztsm_failback' ) {
        my $OwnerGroup = _GetTicketDynamicField(
            Ticket => \%Ticket,
            Field  => 'ZTicket-OwnerGroup',
        );

        return 1
            if _UserHasSupportAssignmentType(
            SupportProfile => $OwnerGroup,
            CustomerUserID => $CustomerUserID,
            ApplicationID  => _GetTicketDynamicField(
                Ticket => \%Ticket,
                Field  => 'ZTicket-Application',
            ),
            AssignmentType => 'Escalation',
            );

        return 1
            if _IsIPCAgent(
            CustomerUserID => $CustomerUserID,
            );

        return;
    }

    # -------------------------------------------------------- #
    # DIRECT PARTICIPATION
    # -------------------------------------------------------- #

    if (
        _CanParticipateTicket(

            Ticket => \%Ticket,

            CustomerUserID => $CustomerUserID,
        )
    ) {

        $LogObject->Log(

            Priority => 'info',

            Message =>
                  'TESSERA UserIDCheck: '
                . 'Direct participation access granted '
                . "TicketID=$Param{TicketID} "
                . "CustomerUserID=$CustomerUserID",
        );

        return 1;
    }

    if (
        _CanViewStory(
            Ticket         => \%Ticket,
            CustomerUserID => $CustomerUserID,
        )
        )
    {
        $LogObject->Log(
            Priority => 'info',
            Message =>
                  'TESSERA UserIDCheck: '
                . 'Linked ticket read access granted '
                . "TicketID=$Param{TicketID} "
                . "CustomerUserID=$CustomerUserID",
        );

        return 1;
    }

    # -------------------------------------------------------- #
    # DENY
    # -------------------------------------------------------- #

    $LogObject->Log(

        Priority => 'debug',

        Message =>
              'TESSERA UserIDCheck: '
            . 'Access denied '
            . "TicketID=$Param{TicketID} "
            . "CustomerUserID=$CustomerUserID",
    );

    return;
}

1;
