# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMRoleDirector.pm
# --
# ZTSM Governance Role Resolution Director
#
# Purpose:
# - Resolve governance traversal Profile
# - Resolve operational Support Profile
# - Normalize runtime orchestration ticket
#
# Runtime Normalization:
#
# BEFORE:
#   ZTicket-Profile = APP-OWNER
#   ZTicket-Role    = ESCALATION
#
# AFTER:
#   ZTicket-OwnerGroup = IaaS Approval
#   ZTicket-Role       = ESCALATION
#
# Powered by Zen ☕
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMRoleDirector;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
    'Kernel::System::GovernanceObject',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::CustomerUser',
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
        return _NormalizeValue( $Value->{Content} );
    }

    return $Value;
}

sub _TicketOnHold {
    my ($Ticket) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';
    return 1 if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    return 1 if lc( $Ticket->{State} || '' ) eq 'onhold';

    return;
}

# ------------------------------------------------------------ #
# GET DYNAMIC FIELD VALUE
# ------------------------------------------------------------ #

sub _GetDynamicFieldValue {
    my ( %Param ) = @_;

    return if !$Param{Object};
    return if !$Param{Field};

    my $DynamicFieldValue = _NormalizeValue(
        $Param{Object}->{ 'DynamicField_' . $Param{Field} }
    );

    return $DynamicFieldValue
        if defined $DynamicFieldValue && $DynamicFieldValue ne '';

    return if !$Param{Object}->{XMLData};
    return if !$Param{Object}->{XMLData}->{ $Param{Field} };

    my $XMLValue = $Param{Object}->{XMLData}->{ $Param{Field} };

    if ( ref $XMLValue eq 'ARRAY' ) {
        $XMLValue = $XMLValue->[0];
    }

    if ( ref $XMLValue eq 'HASH' ) {
        return _NormalizeValue( $XMLValue->{Content} );
    }

    return _NormalizeValue(
        $XMLValue
    );
}

# ------------------------------------------------------------ #
# PROFILE KEY
# ------------------------------------------------------------ #

sub _ProfileKey {
    my ($Value) = @_;

    $Value = _NormalizeValue($Value);
    return if !defined $Value;

    $Value = uc $Value;
    $Value =~ s{[^A-Z0-9]+}{-}g;
    $Value =~ s{\A-+}{};
    $Value =~ s{-+\z}{};

    return 'APP-PROFILE' if $Value eq 'APPLICATION-DEFAULT';
    return 'APP-PROFILE' if $Value eq 'APPLICATION-PROFILE';
    return 'APP-PROFILE' if $Value eq 'APP-DEFAULT';
    return 'APP-PROFILE' if $Value eq 'GENERAL-DEFAULT';
    return 'APP-PROFILE' if $Value eq 'GENERIC-DEFAULT';
    return 'APP-OWNER'   if $Value eq 'APPLICATION-OWNER';

    return $Value;
}

# ------------------------------------------------------------ #
# UPDATE TICKET FIELD
# ------------------------------------------------------------ #

sub _UpdateTicketField {
    my ( %Param ) = @_;

    return if !$Param{TicketID};
    return if !$Param{FieldName};

    my $DynamicFieldObject = $Kernel::OM->Get(
        'Kernel::System::DynamicField'
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get(
        'Kernel::System::DynamicField::Backend'
    );

    my $DynamicFieldConfig
        = $DynamicFieldObject->DynamicFieldGet(
            Name => $Param{FieldName},
        );

    return if !$DynamicFieldConfig;

    return $DynamicFieldBackendObject->ValueSet(

        DynamicFieldConfig => $DynamicFieldConfig,

        ObjectID => $Param{TicketID},

        Value => $Param{Value},

        UserID => 1,
    );
}

# ------------------------------------------------------------ #
# GET CONFIG ITEM
# ------------------------------------------------------------ #

sub _GetGovernanceObject {
    my ( %Param ) = @_;

    return if !$Param{GovernanceObjectID};

    my $GovernanceObjectObject = $Kernel::OM->Get(
        'Kernel::System::GovernanceObject'
    );

    return $GovernanceObjectObject->GovernanceObjectGet(

        GovernanceObjectID => $Param{GovernanceObjectID},

        DynamicFields => 1,
    );
}

# ------------------------------------------------------------ #
# IS SUPPORT PROFILE
# ------------------------------------------------------------ #

sub _IsSupportProfile {
    my (%Param) = @_;

    return if !$Param{GovernanceObjectID};

    my @SupportProfileIDs = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectSearch(
        Result             => 'ARRAY',
        Classes            => ['SupportProfile'],
        GovernanceObjectID => [ $Param{GovernanceObjectID} ],
        Limit              => 1,
        UserID             => $Param{UserID} || 1,
    );

    return @SupportProfileIDs ? 1 : 0;
}

# ------------------------------------------------------------ #
# RESOLVE PROFILE DIRECTIVE
# ------------------------------------------------------------ #

sub _ResolveProfileDirective {
    my (%Param) = @_;

    my $Profile = _NormalizeValue( $Param{Profile} );

    return if !defined $Profile;
    return if $Profile eq '';

    my %Result = (
        Display => $Profile,
    );

    my $GovernanceObject;
    if ( $Profile =~ m{\A\d+\z} ) {
        $GovernanceObject = _GetGovernanceObject(
            GovernanceObjectID => $Profile,
        );
    }

    if ($GovernanceObject) {
        $Result{Display} = $GovernanceObject->{Name} || $Profile;

        if (
            ( $GovernanceObject->{Class} || '' ) eq 'SupportProfile'
            || _IsSupportProfile( GovernanceObjectID => $Profile, UserID => $Param{UserID} )
            )
        {
            $Result{SupportProfile} = $Profile;
            return %Result;
        }

        my $Code = _GetDynamicFieldValue(
            Object => $GovernanceObject,
            Field  => 'ZTSM-Code',
        );

        $Result{ProfileKey} = _ProfileKey( $Code || $GovernanceObject->{Name} || $Profile );
        return %Result;
    }

    $Result{ProfileKey} = _ProfileKey($Profile);
    return %Result;
}

# ------------------------------------------------------------ #
# RESOLVE REQUESTER DEFAULT PROFILE
# ------------------------------------------------------------ #

sub _ResolveRequesterProfile {
    my ( %Param ) = @_;

    return if !$Param{CustomerUserID};

    my $CustomerUserObject = $Kernel::OM->Get(
        'Kernel::System::CustomerUser'
    );

    my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(

        User => $Param{CustomerUserID},
    );

    return if !%CustomerUser;

    return _NormalizeValue(
        $CustomerUser{
            'DynamicField_ZTSMUser-DefaultSupportProfile'
        }
    );
}

# ------------------------------------------------------------ #
# RESOLVE APP DEFAULT PROFILE
# ------------------------------------------------------------ #

sub _ResolveAppProfile {
    my ( %Param ) = @_;

    return if !$Param{ApplicationID};

    my $Application = _GetGovernanceObject(

        GovernanceObjectID => $Param{ApplicationID},
    );

    return if !$Application;

    return _GetDynamicFieldValue(

        Object => $Application,

        Field => 'ZTSMAppSystem-DefaultApprovalProfile',
    );
}

# ------------------------------------------------------------ #
# RESOLVE APP OWNER PROFILE
# ------------------------------------------------------------ #

sub _ResolveAppOwnerProfile {
    my ( %Param ) = @_;

    return if !$Param{ApplicationID};

    my $Application = _GetGovernanceObject(

        GovernanceObjectID => $Param{ApplicationID},
    );

    return if !$Application;

    my $OrganizationID = _GetDynamicFieldValue(

        Object => $Application,

        Field => 'ZTSMAppSystem-Owner',
    );

    return if !$OrganizationID;

    my $Organization = _GetGovernanceObject(

        GovernanceObjectID => $OrganizationID,
    );

    return if !$Organization;

    return _GetDynamicFieldValue(

        Object => $Organization,

        Field => 'ZTSMOrganization-DefaultApprovalProfile',
    );
}

# ------------------------------------------------------------ #
# RESOLVE PLATFORM OWNER PROFILE
# ------------------------------------------------------------ #

sub _ResolvePlatformOwnerProfile {
    my ( %Param ) = @_;

    return if !$Param{ApplicationID};

    my $Application = _GetGovernanceObject(

        GovernanceObjectID => $Param{ApplicationID},
    );

    return if !$Application;

    my $PlatformID = _GetDynamicFieldValue(

        Object => $Application,

        Field => 'ZTSMAppSystem-Platform',
    );

    return if !$PlatformID;

    my $Platform = _GetGovernanceObject(

        GovernanceObjectID => $PlatformID,
    );

    return if !$Platform;

    my $OrganizationID = _GetDynamicFieldValue(

        Object => $Platform,

        Field => 'ZTSMPlatform-Owner',
    );

    return if !$OrganizationID;

    my $Organization = _GetGovernanceObject(

        GovernanceObjectID => $OrganizationID,
    );

    return if !$Organization;

    return _GetDynamicFieldValue(

        Object => $Organization,

        Field => 'ZTSMOrganization-DefaultApprovalProfile',
    );
}

# ------------------------------------------------------------ #
# RESOLVE TOP OWNER PROFILE
# ------------------------------------------------------------ #

sub _ResolveTopOwnerProfile {
    my ( %Param ) = @_;

    return if !$Param{ApplicationID};

    my $Application = _GetGovernanceObject(

        GovernanceObjectID => $Param{ApplicationID},
    );

    return if !$Application;

    my $OrganizationID = _GetDynamicFieldValue(

        Object => $Application,

        Field => 'ZTSMAppSystem-Owner',
    );

    return if !$OrganizationID;

    LOOP:
    while ($OrganizationID) {

        my $Organization = _GetGovernanceObject(

            GovernanceObjectID => $OrganizationID,
        );

        last LOOP if !$Organization;

        my $ParentID = _GetDynamicFieldValue(

            Object => $Organization,

            Field => 'ZTSMOrganization-Parent',
        );

        #
        # Highest organization reached
        #

        if ( !$ParentID ) {

            return _GetDynamicFieldValue(

                Object => $Organization,

                Field => 'ZTSMOrganization-DefaultApprovalProfile',
            );
        }

        $OrganizationID = $ParentID;
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

    my $TicketObject = $Kernel::OM->Get(
        'Kernel::System::Ticket'
    );

    return if !$Param{Ticket};

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};

    return if !$TicketID;

    if ( _TicketOnHold($Ticket) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMRoleDirector: Ticket is onhold, skip role resolution TicketID=$TicketID",
        );
        return 1;
    }

    # -------------------------------------------------------- #
    # RUNTIME CONTEXT
    # -------------------------------------------------------- #

    my $Profile = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Profile'}
    );

    my $Role = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Role'}
    );

    my $ApplicationID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Application'}
    );

    if ( !$ApplicationID ) {
        my $ParentTicketID = _NormalizeValue(
            $Ticket->{'DynamicField_ZTicket-Parent'}
        );

        if ($ParentTicketID) {
            my %ParentTicket = $TicketObject->TicketGet(
                TicketID       => $ParentTicketID,
                DynamicFields  => 1,
                UserID         => 1,
                Silent         => 1,
            );

            $ApplicationID = _NormalizeValue(
                $ParentTicket{'DynamicField_ZTicket-Application'}
            );
        }
    }

    my $CustomerUserID = $Ticket->{CustomerUserID};

    return if !$Profile;

    my $ResolvedSupportProfile;
    my %ProfileDirective = _ResolveProfileDirective(
        Profile => $Profile,
    );

    my $ProfileDisplay = $ProfileDirective{Display} || $Profile;

    if ( $ProfileDirective{SupportProfile} ) {
        $ResolvedSupportProfile = $ProfileDirective{SupportProfile};
    }
    else {
        $Profile = $ProfileDirective{ProfileKey} || $Profile;
    }

    # -------------------------------------------------------- #
    # REQUESTER DEFAULT
    # -------------------------------------------------------- #

    my $ResolutionCandidate;

    if (
        !$ResolvedSupportProfile
        &&
        $Profile eq 'REQUESTER-SUPPORT-GROUP'
    ) {

        $ResolutionCandidate = _ResolveRequesterProfile(

            CustomerUserID => $CustomerUserID,
        );

        $ResolvedSupportProfile = $ResolutionCandidate;
    }

    # -------------------------------------------------------- #
    # APP PROFILE
    # -------------------------------------------------------- #

    elsif (
        !$ResolvedSupportProfile
        &&
        $Profile eq 'APP-PROFILE'
    ) {

        $ResolutionCandidate = _ResolveAppProfile(

            ApplicationID => $ApplicationID,
        );

        $ResolvedSupportProfile = $ResolutionCandidate;
    }

    # -------------------------------------------------------- #
    # APP OWNER
    # -------------------------------------------------------- #

    elsif (
        !$ResolvedSupportProfile
        &&
        $Profile eq 'APP-OWNER'
    ) {

        $ResolutionCandidate = _ResolveAppOwnerProfile(

            ApplicationID => $ApplicationID,
        );

        $ResolvedSupportProfile = $ResolutionCandidate;
    }

    # -------------------------------------------------------- #
    # PLATFORM OWNER
    # -------------------------------------------------------- #

    elsif (
        !$ResolvedSupportProfile
        &&
        $Profile eq 'PLATFORM-OWNER'
    ) {

        $ResolutionCandidate = _ResolvePlatformOwnerProfile(

            ApplicationID => $ApplicationID,
        );

        $ResolvedSupportProfile = $ResolutionCandidate;
    }

    # -------------------------------------------------------- #
    # TOP OWNER
    # -------------------------------------------------------- #

    elsif (
        !$ResolvedSupportProfile
        &&
        $Profile eq 'TOP-OWNER'
    ) {

        $ResolutionCandidate = _ResolveTopOwnerProfile(

            ApplicationID => $ApplicationID,
        );

        $ResolvedSupportProfile = $ResolutionCandidate;
    }

    # -------------------------------------------------------- #
    # NO MATCH
    # -------------------------------------------------------- #

    elsif (!$ResolvedSupportProfile) {

        $LogObject->Log(

            Priority => 'error',

            Message =>
                  'ZTSMRoleDirector: '
                . 'Unsupported governance profile: '
                . $ProfileDisplay,
        );

        return 1;
    }

    # -------------------------------------------------------- #
    # RESOLUTION FAILED
    # -------------------------------------------------------- #

    if ( !$ResolvedSupportProfile ) {

        my $Body
            = "** Note: This is a system-generated orchestration update message.\n\n"
            . "Governance profile resolution failed.\n\n"
            . "Profile:\n"
            . ( $ProfileDisplay || 'N/A' )
            . "\n\n"
            . "Role:\n"
            . ( $Role || 'N/A' )
            . "\n\n"
            . "Application:\n"
            . ( $ApplicationID || 'N/A' )
            . "\n\n"
            . "Resolved Candidate:\n"
            . ( $ResolutionCandidate || 'N/A' );

        ZTSMArticleCreate(
            %Param,
            TicketID => $TicketID,
            Subject  => 'ZTSM Governance Resolution Failed',
            Body     => $Body,
            HistoryComment =>
                'ZTSM: Governance resolution failed '
                . 'Profile='
                . ( $ProfileDisplay || 'N/A' ),
            UserID => 1,
        );

        return 1;
    }

    # -------------------------------------------------------- #
    # NORMALIZE RUNTIME TICKET
    # -------------------------------------------------------- #

    _UpdateTicketField(

        TicketID => $TicketID,

        FieldName => 'ZTicket-OwnerGroup',

        Value => $ResolvedSupportProfile,
    );

    #
    # Role remains unchanged intentionally.
    #

    my $Body
        = "** Note: This is a system-generated orchestration update message.\n\n"
        . "Governance profile resolved successfully.\n\n"
        . "Profile:\n"
        . ( $ProfileDisplay || 'N/A' )
        . "\n\n"
        . "Resolved Support Profile:\n"
        . $ResolvedSupportProfile
        . "\n\n"
        . "Runtime Role:\n"
        . ( $Role || 'N/A' );

    ZTSMArticleCreate(
        %Param,
        TicketID => $TicketID,
        Subject  => 'ZTSM Governance Profile Resolved',
        Body     => $Body,
        HistoryComment =>
            'ZTSM: Governance resolved '
            . 'Profile='
            . ( $ProfileDisplay || 'N/A' ),
        UserID => 1,
    );

    $LogObject->Log(

        Priority => 'notice',

        Message =>
              'ZTSMRoleDirector: '
            . 'Governance profile resolved '
            . "TicketID=$TicketID "
            . "Profile=$Profile "
            . "ProfileDisplay=$ProfileDisplay "
            . "Role=$Role "
            . "SupportProfile=$ResolvedSupportProfile",
    );

    return 1;
}

1;
