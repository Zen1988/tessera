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
    'Kernel::System::CustomerUser',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::ITSMConfigItem',
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
        return $Value->[0];
    }

    return $Value;
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

# ------------------------------------------------------------ #
# GET SUPPORT ASSIGNMENT
# ------------------------------------------------------------ #

sub _UserParticipateSupportProfile {
    my ( %Param ) = @_;

    return if !$Param{SupportProfile};
    return if !$Param{CustomerUserID};

    my $ConfigItemObject = $Kernel::OM->Get(
        'Kernel::System::ITSMConfigItem'
    );

    #
    # Search Support Assignment
    #

    my $AssignmentList = $ConfigItemObject->ConfigItemSearch(

        ClassIDs => ['ZTSMSupportAssignment'],

        What => [

            {
                Field => 'ZTSMSupportAssignment-SupportProfile',
                Type  => 'Equals',
                Value => $Param{SupportProfile},
            },

            {
                Field => 'ZTSMSupportAssignment-UserAccount',
                Type  => 'Equals',
                Value => $Param{CustomerUserID},
            },
        ],

        Limit => 100,
    );

    return if !$AssignmentList;
    return if ref $AssignmentList ne 'ARRAY';

    ASSIGNMENT:
    for my $AssignmentID ( @{$AssignmentList} ) {

        my $Assignment = $ConfigItemObject->ConfigItemGet(

            ConfigItemID  => $AssignmentID,

            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment;

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

    my $ConfigItemObject = $Kernel::OM->Get(
        'Kernel::System::ITSMConfigItem'
    );

    my $AssignmentList = $ConfigItemObject->ConfigItemSearch(
        ClassIDs => ['ZTSMSupportAssignment'],
        What     => [
            {
                Field => 'ZTSMSupportAssignment-SupportProfile',
                Type  => 'Equals',
                Value => $Param{SupportProfile},
            },
            {
                Field => 'ZTSMSupportAssignment-UserAccount',
                Type  => 'Equals',
                Value => $Param{CustomerUserID},
            },
        ],
        Limit => 100,
    );

    return if !$AssignmentList;
    return if ref $AssignmentList ne 'ARRAY';

    ASSIGNMENT:
    for my $AssignmentID ( @{$AssignmentList} ) {
        my $Assignment = $ConfigItemObject->ConfigItemGet(
            ConfigItemID  => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment;

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

            DynamicField_ZTicket_Parent => {
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

    my $TicketObject = $Kernel::OM->Get(
        'Kernel::System::Ticket'
    );

    my %Ticket = $TicketObject->TicketGet(

        TicketID      => $Param{TicketID},

        DynamicFields => 1,

        UserID        => 1,
    );

    return if !%Ticket;

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

            Priority => 'notice',

            Message =>
                  'ZTSMUserIDCheck: '
                . 'Direct participation access granted '
                . "TicketID=$Param{TicketID} "
                . "CustomerUserID=$CustomerUserID",
        );

        return 1;
    }

    # -------------------------------------------------------- #
    # STORY VISIBILITY INHERITANCE
    # -------------------------------------------------------- #

    if (
        _CanViewStory(

            Ticket => \%Ticket,

            CustomerUserID => $CustomerUserID,
        )
    ) {

        $LogObject->Log(

            Priority => 'notice',

            Message =>
                  'ZTSMUserIDCheck: '
                . 'Story inheritance access granted '
                . "TicketID=$Param{TicketID} "
                . "CustomerUserID=$CustomerUserID",
        );

        return 1;
    }

    # -------------------------------------------------------- #
    # DENY
    # -------------------------------------------------------- #

    $LogObject->Log(

        Priority => 'notice',

        Message =>
              'ZTSMUserIDCheck: '
            . 'Access denied '
            . "TicketID=$Param{TicketID} "
            . "CustomerUserID=$CustomerUserID",
    );

    return;
}

1;
