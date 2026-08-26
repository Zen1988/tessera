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
    'Kernel::System::TESSERA::GovernanceRoleResolver',
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

sub _IsRequesterDefaultProfile {
    my ($Profile) = @_;

    $Profile = _ProfileKey($Profile);
    return if !defined $Profile;

    return 1 if $Profile eq 'REQUESTER-DEFAULT';
    return 1 if $Profile eq 'REQUESTER-SUPPORT-GROUP';

    return;
}

sub _IsAffectedUserSupportRole {
    my ($Profile) = @_;

    $Profile = _ProfileKey($Profile);
    return if !defined $Profile;

    return 1 if $Profile eq 'ESCALATION';
    return 1 if $Profile eq 'PRIMARY';
    return 1 if $Profile eq 'SECONDARY';

    return;
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

sub _GovernanceObjectReferenceValues {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );
    return if !defined $Value || $Value eq '';

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

sub _ResolveGovernanceRoleSupportProfile {
    my (%Param) = @_;

    my @RoleReferences = _GovernanceObjectReferenceValues(
        Value  => $Param{GovernanceRole},
        Class  => 'GovernanceRole',
        UserID => $Param{UserID},
    );
    return if !@RoleReferences;

    my @ApplicationReferences = _GovernanceObjectReferenceValues(
        Value  => $Param{ApplicationID},
        Class  => 'Application',
        UserID => $Param{UserID},
    );
    return if defined $Param{ApplicationID} && $Param{ApplicationID} ne '' && !@ApplicationReferences;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %AssignmentID;

    for my $RoleReference (@RoleReferences) {
        my %BaseSearch = (
            Classes => ['SupportAssignment'],
            'DynamicField_ZTSMSupportAssignment-Role' => {
                Equals => $RoleReference,
            },
            Result => 'ARRAY',
            Limit  => 1000,
            UserID => $Param{UserID} || 1,
        );

        if (@ApplicationReferences) {
            for my $ApplicationReference (@ApplicationReferences) {
                my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
                    %BaseSearch,
                    'DynamicField_ZTSMSupportAssignment-Application' => {
                        Equals => $ApplicationReference,
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

    for my $AssignmentID ( sort { $a <=> $b } keys %AssignmentID ) {
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields      => 1,
            Silent             => 1,
        );
        next if !$Assignment || ref $Assignment ne 'HASH';

        my $SupportProfile = _GetDynamicFieldValue(
            Object => $Assignment,
            Field  => 'ZTSMSupportAssignment-SupportProfile',
        );
        next if !$SupportProfile;

        my @SupportProfileReferences = _GovernanceObjectReferenceValues(
            Value  => $SupportProfile,
            Class  => 'SupportProfile',
            UserID => $Param{UserID},
        );
        for my $SupportProfileReference (@SupportProfileReferences) {
            my @SupportProfileIDs = $GovernanceObjectObject->GovernanceObjectSearch(
                Result             => 'ARRAY',
                Classes            => ['SupportProfile'],
                GovernanceObjectID => [$SupportProfileReference],
                Limit              => 1,
                UserID             => $Param{UserID} || 1,
            );
            return $SupportProfileIDs[0] if @SupportProfileIDs;
        }
    }

    return;
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

        if ( ( $GovernanceObject->{Class} || '' ) eq 'GovernanceRole' ) {
            $Result{GovernanceRole} = $Profile;
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

    my $Profile = _NormalizeValue( $CustomerUser{'DynamicField_ZUser-SupportProfile'} );
    return $Profile if $Profile;

    $Profile = _NormalizeValue( $CustomerUser{'DynamicField_ZTSMUser-DefaultSupportProfile'} );
    return $Profile if $Profile;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZUser-SupportProfile',
    );
    if ($DynamicFieldConfig) {
        $Profile = _NormalizeValue(
            $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectName         => $Param{CustomerUserID},
            )
        );
        return $Profile if $Profile;
    }

    $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZTSMUser-DefaultSupportProfile',
    );
    if ($DynamicFieldConfig) {
        $Profile = _NormalizeValue(
            $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectName         => $Param{CustomerUserID},
            )
        );
        return $Profile if $Profile;
    }

    return;
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

    my $DynamicGovernanceRole;
    if ( $ProfileDirective{SupportProfile} ) {
        $ResolvedSupportProfile = $ProfileDirective{SupportProfile};
    }
    elsif ( $ProfileDirective{GovernanceRole} ) {
        $DynamicGovernanceRole = $ProfileDirective{GovernanceRole};
    }
    else {
        $Profile = $ProfileDirective{ProfileKey} || $Profile;
    }

    # -------------------------------------------------------- #
    # REQUESTER DEFAULT
    # -------------------------------------------------------- #

    my $ResolutionCandidate;
    my $RequesterOwnerUserID;
    my $AffectedUserOwnerUserID;

    my $ScriptResolutionHandled;
    if ($DynamicGovernanceRole) {
        my $ScriptResult = $Kernel::OM->Get('Kernel::System::TESSERA::GovernanceRoleResolver')->Resolve(
            GovernanceRole => $DynamicGovernanceRole,
            Ticket         => $Ticket,
            UserID         => 1,
        );
        if ( ( $ScriptResult->{Status} || '' ) eq 'RETURNED' ) {
            $ResolutionCandidate = $ScriptResult->{Value};
            if ( ( $ScriptResult->{ValueType} || '' ) eq 'GovernanceObject.SupportProfile' ) {
                $ResolvedSupportProfile = $ScriptResult->{Value};
            }
            elsif ( ( $ScriptResult->{ValueType} || '' ) eq 'CustomerUser' ) {
                $RequesterOwnerUserID = $ScriptResult->{Value};
            }
            elsif ( ( $ScriptResult->{ValueType} || '' ) eq 'Collection<SupportAssignment>' ) {
                my $Assignments = $ScriptResult->{Value};
                my @Targets = ref $Assignments eq 'ARRAY'
                    ? grep { ref $_ eq 'HASH' && $_->{Type} && defined $_->{Value} } @{$Assignments}
                    : ();
                if ( @Targets != 1 ) {
                    $LogObject->Log( Priority => 'error', Message => "ZTSMRoleDirector: TransitionAction requires one SupportAssignment target; found " . scalar(@Targets) . " TicketID=$TicketID" );
                    return 1;
                }
                if ( $Targets[0]->{Type} eq 'GovernanceObject.SupportProfile' ) {
                    $ResolvedSupportProfile = $Targets[0]->{Value};
                }
                elsif ( $Targets[0]->{Type} eq 'CustomerUser' ) {
                    $RequesterOwnerUserID = $Targets[0]->{Value};
                }
                else {
                    $LogObject->Log( Priority => 'error', Message => "ZTSMRoleDirector: unsupported SupportAssignment target type $Targets[0]->{Type} TicketID=$TicketID" );
                    return 1;
                }
            }
            elsif (
                ( $ScriptResult->{ValueType} || '' ) eq 'Collection<GovernanceObject.SupportProfile>'
                || ( $ScriptResult->{ValueType} || '' ) eq 'Collection<CustomerUser>'
                )
            {
                my $Targets = $ScriptResult->{Value};
                if ( ref $Targets ne 'ARRAY' ) {
                    $LogObject->Log( Priority => 'error', Message => "ZTSMRoleDirector: typed assignment collection is not an array TicketID=$TicketID" );
                    return 1;
                }
                if ( !@{$Targets} ) {
                    $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateSet(
                        TicketID => $TicketID, State => 'closed no action', UserID => 1,
                    );
                    ZTSMArticleCreate(
                        TicketID => $TicketID,
                        Subject  => 'Dynamic assignment completed with no action',
                        Body     => "The GovernanceRole resolver returned no eligible assignment targets.\n\nNo lifecycle transition was initiated by assignment resolution.",
                        HistoryComment => 'ZTSM: dynamic assignment returned no targets',
                        UserID => 1,
                    );
                    return 1;
                }
                if ( @{$Targets} != 1 ) {
                    $LogObject->Log(
                        Priority => 'notice',
                        Message  => 'ZTSMRoleDirector: multiple typed targets require GenericAgent reconciliation; found '
                            . scalar(@{$Targets}) . " TicketID=$TicketID",
                    );
                    return 1;
                }
                if ( $ScriptResult->{ValueType} eq 'Collection<CustomerUser>' ) {
                    $RequesterOwnerUserID = $Targets->[0];
                }
                else {
                    $ResolvedSupportProfile = $Targets->[0];
                }
            }
            else {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => 'ZTSMRoleDirector: GovernanceRole script returned unsupported type '
                        . ( $ScriptResult->{ValueType} || 'N/A' ) . " TicketID=$TicketID",
                );
                return 1;
            }
            $ScriptResolutionHandled = 1;
        }
        elsif ( ( $ScriptResult->{Status} || '' ) ne 'NO_SCRIPT' ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => 'ZTSMRoleDirector: GovernanceRole script resolution failed '
                    . ( $ScriptResult->{Error} || 'UNKNOWN' ) . " TicketID=$TicketID",
            );
            return 1;
        }
    }

    if ( $DynamicGovernanceRole && !$ScriptResolutionHandled ) {
        if ( _IsRequesterDefaultProfile($ProfileDisplay) ) {
            $ResolutionCandidate = _ResolveRequesterProfile(

                CustomerUserID => $CustomerUserID,
            );

            if ( !$ResolutionCandidate ) {
                $ResolutionCandidate = _ResolveAppProfile(

                    ApplicationID => $ApplicationID,
                );
            }

            $ResolvedSupportProfile = $ResolutionCandidate;
            $RequesterOwnerUserID   = $CustomerUserID;
        }
        elsif ( _IsAffectedUserSupportRole($ProfileDisplay) ) {
            $ResolutionCandidate = _ResolveRequesterProfile(

                CustomerUserID => $CustomerUserID,
            );

            if ( !$ResolutionCandidate ) {
                $ResolutionCandidate = _ResolveAppProfile(

                    ApplicationID => $ApplicationID,
                );
            }

            $AffectedUserOwnerUserID = $CustomerUserID;
        }
        else {
            $ResolutionCandidate = _ResolveGovernanceRoleSupportProfile(
                GovernanceRole => $DynamicGovernanceRole,
                ApplicationID  => $ApplicationID,
                UserID          => 1,
            );
        }
        $ResolvedSupportProfile = $ResolutionCandidate;
    }

    elsif (
        !$ResolvedSupportProfile
        &&
        _IsRequesterDefaultProfile($Profile)
    ) {

        $ResolutionCandidate = _ResolveRequesterProfile(

            CustomerUserID => $CustomerUserID,
        );

        $ResolvedSupportProfile = $ResolutionCandidate;
        if ( !$ResolvedSupportProfile ) {
            $ResolutionCandidate = _ResolveAppProfile(

                ApplicationID => $ApplicationID,
            );

            $ResolvedSupportProfile = $ResolutionCandidate;
        }

        if ( !$ResolvedSupportProfile ) {
            $RequesterOwnerUserID = $CustomerUserID;
        }
        else {
            $RequesterOwnerUserID = $CustomerUserID;
        }
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

    if ( $RequesterOwnerUserID && !$ResolvedSupportProfile ) {

        _UpdateTicketField(

            TicketID => $TicketID,

            FieldName => 'ZTicket-OwnerGroup',

            Value => '',
        );

        _UpdateTicketField(

            TicketID => $TicketID,

            FieldName => 'ZTicket-Owner',

            Value => $RequesterOwnerUserID,
        );

        my $Body
            = "** Note: This is a system-generated orchestration update message.\n\n"
            . "Requester default resolved successfully.\n\n"
            . "Profile:\n"
            . ( $ProfileDisplay || 'N/A' )
            . "\n\n"
            . "Requester Support Profile:\nN/A\n\n"
            . "Assigned Owner:\n"
            . $RequesterOwnerUserID
            . "\n\n"
            . "Runtime Role:\n"
            . ( $Role || 'N/A' );

        ZTSMArticleCreate(
            %Param,
            TicketID => $TicketID,
            Subject  => 'ZTSM Requester Default Resolved',
            Body     => $Body,
            HistoryComment => 'ZTSM: Requester default resolved to owner',
            UserID   => 1,
        );

        return 1;
    }

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

    if ( _IsRequesterDefaultProfile($Profile) || $AffectedUserOwnerUserID ) {
        _UpdateTicketField(

            TicketID => $TicketID,

            FieldName => 'ZTicket-Owner',

            Value => $RequesterOwnerUserID || $AffectedUserOwnerUserID || $CustomerUserID || '',
        );
    }

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
