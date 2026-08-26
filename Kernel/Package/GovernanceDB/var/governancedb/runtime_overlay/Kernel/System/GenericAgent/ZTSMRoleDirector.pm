# --
# Kernel/System/GenericAgent/ZTSMRoleDirector.pm
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

package Kernel::System::GenericAgent::ZTSMRoleDirector;

use strict;
use warnings;

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
# RESOLVE BLUEBOOK PROFILE
# ------------------------------------------------------------ #

sub _ReadProfile {
    my ( %Param ) = @_;

    return if !$Param{BlueBookID};
	return if !$Param{Chapter};

    my $BlueBook = _GetGovernanceObject(
        GovernanceObjectID => $Param{BlueBookID},
    );

    return if !$BlueBook;
	
	my $Chapters = $BlueBook->{'DynamicField_ZBlue-Record'}
        || ( ref $BlueBook->{XMLData} eq 'HASH' ? $BlueBook->{XMLData}->{'ZBlue-Record'} : undef );

	return if !$Chapters;
	
	if ( ref $Chapters eq 'HASH' ) {
		$Chapters = [$Chapters];
	}

	return if ref $Chapters ne 'ARRAY';
	
    CHAP:
	for my $Chapter ( @{$Chapters} ) {
		
		next CHAP
            if ref $Chapter ne 'HASH';

        my $BlueChapter = _NormalizeValue(
            $Chapter->{'ZBlue-Chapter'}->{Content}
        );
		
		next CHAP 
			if $BlueChapter ne $Param{Chapter};

        return _NormalizeValue(
            $Chapter->{'ZBlue-Profile'}->{Content}
        );
	}
}

sub _DiagnosisOutcomeLabel {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );
    return if !defined $Value || $Value eq '';

    my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => 'ZIN-Outcome',
    );

    if ( $DynamicFieldConfig && $DynamicFieldConfig->{ID} ) {
        my $DisplayValue = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueLookup(
            DynamicFieldConfig => $DynamicFieldConfig,
            Key                => $Value,
        );

        return _NormalizeValue($DisplayValue)
            if defined $DisplayValue && $DisplayValue ne '';
    }

    return $Value;
}

sub _DiagnosisOwnerGroupsResolve {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return if !$Ticket || ref $Ticket ne 'HASH';

    my $ParentTicketID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    my $Iteration      = _NormalizeValue( $Ticket->{'DynamicField_ZIN-Iteration'} );
    return if !$ParentTicketID;
    return if !defined $Iteration || $Iteration eq '';

    my @Iterations = ($Iteration);
    push @Iterations, $Iteration - 1
        if $Iteration =~ m{\A\d+\z} && $Iteration > 0;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    ITERATION:
    for my $CandidateIteration (@Iterations) {
        my @DiagnosisTicketIDs = sort { $a <=> $b } $TicketObject->TicketSearch(
            Result    => 'ARRAY',
            Types     => ['Diagnosis'],
            StateType => ['closed'],
            'DynamicField_ZTicket-Parent' => {
                Equals => $ParentTicketID,
            },
            'DynamicField_ZIN-Iteration' => {
                Equals => $CandidateIteration,
            },
            UserID => $Param{UserID} || 1,
        );

        next ITERATION if !@DiagnosisTicketIDs;

        my @OwnerGroups;
        my %SeenOwnerGroup;

        DIAGNOSISTICKET:
        for my $DiagnosisTicketID (@DiagnosisTicketIDs) {
            my %DiagnosisTicket = $TicketObject->TicketGet(
                TicketID      => $DiagnosisTicketID,
                DynamicFields => 1,
                UserID        => $Param{UserID} || 1,
                Silent        => 1,
            );
            next DIAGNOSISTICKET if !%DiagnosisTicket;

            my $Outcome = _DiagnosisOutcomeLabel(
                Value => $DiagnosisTicket{'DynamicField_ZIN-Outcome'},
            );
            $Outcome = lc( _NormalizeValue($Outcome) || '' );
            $Outcome =~ s{\A\s+|\s+\z}{}g;
            next DIAGNOSISTICKET
                if $Outcome eq 'not applicable' || $Outcome eq 'recovered';

            my $OwnerGroup = _NormalizeValue(
                $DiagnosisTicket{'DynamicField_ZTicket-OwnerGroup'}
            );
            next DIAGNOSISTICKET if !$OwnerGroup;
            next DIAGNOSISTICKET if $SeenOwnerGroup{$OwnerGroup}++;

            push @OwnerGroups, $OwnerGroup;
        }

        $LogObject->Log(
            Priority => 'notice',
            Message  => 'ZTSMRoleDirector: DIAGNOSE evidence lookup '
                . "ParentTicketID=$ParentTicketID "
                . "RequestedIteration=$Iteration "
                . "MatchedIteration=$CandidateIteration "
                . 'DiagnosisTicketIDs=' . join( ',', @DiagnosisTicketIDs ) . ' '
                . 'OwnerGroups=' . join( ',', @OwnerGroups ),
        );

        return @OwnerGroups;
    }

    $LogObject->Log(
        Priority => 'error',
        Message  => 'ZTSMRoleDirector: DIAGNOSE evidence lookup found no closed Diagnosis tickets '
            . "ParentTicketID=$ParentTicketID Iteration=$Iteration",
    );

    return;
}

sub _DiagnosisFanoutExists {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return if !$Ticket || ref $Ticket ne 'HASH';
    return if !$Param{OwnerGroup};

    my %Search = (
        Result => 'ARRAY',
        Types  => [ $Ticket->{Type} ],
        'DynamicField_ZTicket-OwnerGroup' => {
            Equals => $Param{OwnerGroup},
        },
        UserID => $Param{UserID} || 1,
    );

    for my $FieldName (qw(ZTicket-Parent ZIN-Iteration ZTicket-BlueBook ZTicket-BlueLevel ZTicket-Chapter)) {
        my $Value = _NormalizeValue( $Ticket->{"DynamicField_$FieldName"} );
        next if !defined $Value || $Value eq '';

        $Search{"DynamicField_$FieldName"} = {
            Equals => $Value,
        };
    }

    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(%Search);
    return @TicketIDs ? 1 : 0;
}

sub _DiagnosisFanoutDynamicFieldsCopy {
    my (%Param) = @_;

    return if !$Param{SourceTicketID} || !$Param{TargetTicketID};

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $LogObject                 = $Kernel::OM->Get('Kernel::System::Log');

    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    ) || [];

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicFieldList} ) {
        next DYNAMICFIELD if ref $DynamicFieldConfig ne 'HASH';
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};
        next DYNAMICFIELD if $DynamicFieldConfig->{Name} eq 'ZTicket-OwnerGroup';

        my $Value = $DynamicFieldBackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{SourceTicketID},
        );
        next DYNAMICFIELD if !defined $Value;
        next DYNAMICFIELD if !ref $Value && $Value eq '';

        my $Success = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{TargetTicketID},
            Value              => $Value,
            UserID             => $Param{UserID} || 1,
        );
        next DYNAMICFIELD if $Success;

        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMRoleDirector: DIAGNOSE fan-out could not copy dynamic field "
                . "$DynamicFieldConfig->{Name} SourceTicketID=$Param{SourceTicketID} "
                . "TargetTicketID=$Param{TargetTicketID}",
        );
    }

    return 1;
}

sub _DiagnosisFanoutTicketCreate {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return if !$Ticket || ref $Ticket ne 'HASH';
    my $AssignmentField = $Param{AssignmentField} || 'ZTicket-OwnerGroup';
    my $AssignmentValue = defined $Param{AssignmentValue} ? $Param{AssignmentValue} : $Param{OwnerGroup};
    return if !defined $AssignmentValue || $AssignmentValue eq '';

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    if ( $AssignmentField eq 'ZTicket-OwnerGroup' && _DiagnosisFanoutExists( %Param, OwnerGroup => $AssignmentValue ) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => 'ZTSMRoleDirector: DIAGNOSE fan-out ticket already exists '
                . "SourceTicketID=$Ticket->{TicketID} OwnerGroup=$AssignmentValue",
        );
        return 1;
    }

    my $NewTicketID = $Kernel::OM->Get('Kernel::System::Ticket')->TicketCreate(
        TN            => undef,
        Title         => $Ticket->{Title},
        Queue         => $Ticket->{Queue},
        Lock          => $Ticket->{Lock} || 'unlock',
        Priority      => $Ticket->{Priority},
        State         => $Ticket->{State},
        CustomerID    => $Ticket->{CustomerID},
        CustomerUser  => $Ticket->{CustomerUserID},
        OwnerID       => $Ticket->{OwnerID} || 1,
        UserID        => $Param{UserID} || 1,
        Type          => $Ticket->{Type},
        ServiceID     => $Ticket->{ServiceID},
        SLAID         => $Ticket->{SLAID},
        ResponsibleID => $Ticket->{ResponsibleID} || 1,
        ParentTicketID => _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} ),
    );

    if ( !$NewTicketID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'ZTSMRoleDirector: DIAGNOSE fan-out TicketCreate failed '
                . "SourceTicketID=$Ticket->{TicketID} Assignment=$AssignmentValue",
        );
        return;
    }

    _DiagnosisFanoutDynamicFieldsCopy(
        SourceTicketID => $Ticket->{TicketID},
        TargetTicketID => $NewTicketID,
        UserID         => $Param{UserID} || 1,
    );

    _UpdateTicketField(
        TicketID => $NewTicketID,
        FieldName => $AssignmentField,
        Value     => $AssignmentValue,
    );

    $LogObject->Log(
        Priority => 'notice',
        Message  => 'ZTSMRoleDirector: DIAGNOSE fan-out ticket created '
            . "SourceTicketID=$Ticket->{TicketID} NewTicketID=$NewTicketID "
            . "AssignmentField=$AssignmentField AssignmentValue=$AssignmentValue",
    );

    return $NewTicketID;
}

sub _AssignmentCollectionTicketsGet {
    my (%Param) = @_;
    my $Ticket = $Param{Ticket};
    return () if ref $Ticket ne 'HASH';
    my $Parent  = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    my $Chapter = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );
    return ($Ticket) if !defined $Parent || $Parent eq '' || !defined $Chapter || $Chapter eq '';

    my %Search = ( Result => 'ARRAY', Types => [ $Ticket->{Type} ], UserID => $Param{UserID} || 1 );
    for my $FieldName (qw(ZTicket-Parent ZTicket-BlueBook ZTicket-BlueLevel ZTicket-Chapter)) {
        my $Value = _NormalizeValue( $Ticket->{"DynamicField_$FieldName"} );
        $Search{"DynamicField_$FieldName"} = { Equals => $Value } if defined $Value && $Value ne '';
    }
    my @IDs = sort { $a <=> $b } $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(%Search);
    my $Iteration = _NormalizeValue( $Ticket->{'DynamicField_ZIN-Iteration'} );
    my @Tickets;
    for my $ID (@IDs) {
        my %Found = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID => $ID, DynamicFields => 1, UserID => $Param{UserID} || 1, Silent => 1,
        );
        next if !%Found;
        my $FoundIteration = _NormalizeValue( $Found{'DynamicField_ZIN-Iteration'} );
        next if ( defined $Iteration && $Iteration ne '' )
            ? !defined $FoundIteration || $FoundIteration ne $Iteration
            : defined $FoundIteration && $FoundIteration ne '';
        push @Tickets, \%Found;
    }
    return @Tickets;
}

sub _AssignmentCollectionNeutralClose {
    my (%Param) = @_;
    my $Ticket = $Param{Ticket};
    return 1 if ref $Ticket ne 'HASH' || ( $Ticket->{StateType} || '' ) eq 'closed';
    my $Success = $Kernel::OM->Get('Kernel::System::Ticket')->TicketStateSet(
        TicketID => $Ticket->{TicketID}, State => 'closed no action', UserID => $Param{UserID} || 1,
    );
    return if !$Success;
    ZTSMArticleCreate(
        TicketID => $Ticket->{TicketID}, Subject => 'Dynamic assignment completed with no action',
        Body => "** Note: This is a system-generated orchestration update message.\n\n"
            . ( $Param{Reason} || 'No remaining assignment target was found for this execution ticket.' )
            . "\n\nGovernance Role:\n" . ( $Param{Role} || 'N/A' )
            . "\n\nNo lifecycle transition was initiated by assignment reconciliation.",
        HistoryComment => 'ZTSM: dynamic assignment closed surplus execution ticket with no action',
        UserID => $Param{UserID} || 1,
    );
    return 1;
}

sub _AssignmentCollectionReconcile {
    my (%Param) = @_;
    my $Ticket = $Param{Ticket};
    return if ref $Ticket ne 'HASH' || !$Param{FieldName};
    my @Targets;
    my %TargetSeen;
    for my $Target ( @{ $Param{Targets} || [] } ) {
        $Target = _NormalizeValue($Target);
        next if !defined $Target || $Target eq '' || $TargetSeen{$Target}++;
        push @Targets, $Target;
    }
    my $Parent  = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    my $Chapter = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );
    if ( @Targets > 1 && ( !defined $Parent || $Parent eq '' || !defined $Chapter || $Chapter eq '' ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "ZTSMRoleDirector: collection fan-out requires ZTicket-Parent and ZTicket-Chapter TicketID=$Ticket->{TicketID}",
        );
        return;
    }
    my %Wanted = map { $_ => 1 } @Targets;
    my %Satisfied;
    my @Available;
    my @Tickets = _AssignmentCollectionTicketsGet(%Param);
    for my $Candidate (@Tickets) {
        my $Assigned = _NormalizeValue( $Candidate->{ 'DynamicField_' . $Param{FieldName} } );
        if ( defined $Assigned && $Assigned ne '' && $Wanted{$Assigned} && !$Satisfied{$Assigned} ) {
            $Satisfied{$Assigned} = 1;
            next;
        }
        next if ( $Candidate->{StateType} || '' ) eq 'closed';
        push @Available, $Candidate;
    }
    TARGET:
    for my $Target (@Targets) {
        next TARGET if $Satisfied{$Target};
        if (@Available) {
            my $Candidate = shift @Available;
            _UpdateTicketField( TicketID => $Candidate->{TicketID}, FieldName => $Param{FieldName}, Value => $Target );
            $Satisfied{$Target} = 1;
            next TARGET;
        }
        my $NewTicketID = _DiagnosisFanoutTicketCreate(
            Ticket => $Ticket, AssignmentField => $Param{FieldName}, AssignmentValue => $Target, UserID => $Param{UserID} || 1,
        );
        $Satisfied{$Target} = 1 if $NewTicketID;
    }
    my $Reason = @Targets
        ? 'No remaining assignment target was found for this surplus execution ticket.'
        : 'The GovernanceRole resolver returned no eligible assignment targets.';
    for my $Candidate (@Available) {
        _AssignmentCollectionNeutralClose( Ticket => $Candidate, Reason => $Reason, Role => $Param{Role}, UserID => $Param{UserID} || 1 );
    }
    return 1;
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

    # The Generic Agent automatically injects TicketID here
    my $TicketID = $Param{TicketID};

    # Verify you have a valid TicketID
    if ( !$TicketID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No TicketID passed to ZTSMRoleDirector!',
        );
        return 0;
    }

    # Now use the TicketID with core OTOBO objects
    my %Ticket = $TicketObject->TicketGet(
        TicketID => $TicketID,
        UserID   => 1, # Admin UserID
		DynamicFields => 1,
    );
	
	return 0 if !%Ticket;

    if ( _TicketOnHold( \%Ticket ) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMRoleDirector: Ticket is onhold, skip GenericAgent role resolution TicketID=$TicketID",
        );
        return 1;
    }
	
    # -------------------------------------------------------- #
    # RUNTIME CONTEXT
    # -------------------------------------------------------- #

    my $ExistingOwnerGroup = _NormalizeValue(
		$Ticket{'DynamicField_ZTicket-OwnerGroup'}
	);

	my $Profile = _NormalizeValue(
        $Ticket{'DynamicField_ZTicket-Profile'}
    );

	my $Chapter = _NormalizeValue(
        $Ticket{'DynamicField_ZTicket-Chapter'}
    );
	
	return if !$Chapter && !$Profile;

    my $BlueBook = _NormalizeValue(
        $Ticket{'DynamicField_ZTicket-BlueBook'}
    );
	
	return if !$BlueBook && !$Profile;

    my $Role = _NormalizeValue(
        $Ticket{'DynamicField_ZTicket-Role'}
    );

    my $ApplicationID = _NormalizeValue(
        $Ticket{'DynamicField_ZTicket-Application'}
    );

    if ( !$ApplicationID ) {
        my $ParentTicketID = _NormalizeValue(
            $Ticket{'DynamicField_ZTicket-Parent'}
        );

        if ($ParentTicketID) {
            my %ParentTicket = $TicketObject->TicketGet(
                TicketID      => $ParentTicketID,
                DynamicFields => 1,
                UserID        => 1,
                Silent        => 1,
            );

            $ApplicationID = _NormalizeValue(
                $ParentTicket{'DynamicField_ZTicket-Application'}
            );
        }
    }

    my $CustomerUserID = $Ticket{CustomerUserID};

    if ( !$Profile ) {
        $Profile = _ReadProfile(
            BlueBookID => $BlueBook,
            Chapter    => $Chapter,
        );
    }
	
    return if !$Profile;

    my $ResolvedSupportProfile;
    my @DiagnosisFanoutOwnerGroups;
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

    return 1
        if $ExistingOwnerGroup
        && _IsSupportProfile( GovernanceObjectID => $ExistingOwnerGroup, UserID => 1 )
        && !_IsRequesterDefaultProfile($Profile)
        && !$DynamicGovernanceRole;

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
            Ticket         => \%Ticket,
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
                if ( ref $Assignments ne 'ARRAY' || !@{$Assignments} ) {
                    $LogObject->Log( Priority => 'error', Message => "ZTSMRoleDirector: empty SupportAssignment collection TicketID=$TicketID" );
                    return 1;
                }
                my @SupportProfiles;
                my @CustomerUsers;
                my %Seen;
                for my $Assignment ( @{$Assignments} ) {
                    next if ref $Assignment ne 'HASH' || !$Assignment->{Type} || !defined $Assignment->{Value};
                    next if $Seen{"$Assignment->{Type}\0$Assignment->{Value}"}++;
                    push @SupportProfiles, $Assignment->{Value} if $Assignment->{Type} eq 'GovernanceObject.SupportProfile';
                    push @CustomerUsers,   $Assignment->{Value} if $Assignment->{Type} eq 'CustomerUser';
                }
                if (@SupportProfiles) {
                    $ResolvedSupportProfile = shift @SupportProfiles;
                    push @DiagnosisFanoutOwnerGroups, @SupportProfiles;
                }
                elsif ( @CustomerUsers == 1 ) {
                    $RequesterOwnerUserID = $CustomerUsers[0];
                }
                else {
                    $LogObject->Log( Priority => 'error', Message => "ZTSMRoleDirector: SupportAssignment collection has no unambiguous target TicketID=$TicketID" );
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
                my $FieldName = $ScriptResult->{ValueType} eq 'Collection<CustomerUser>' ? 'ZTicket-Owner' : 'ZTicket-OwnerGroup';
                _AssignmentCollectionReconcile(
                    Ticket => \%Ticket, Targets => $Targets, FieldName => $FieldName,
                    Role => $ProfileDisplay, UserID => 1,
                );
                return 1;
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
        if ( _ProfileKey($ProfileDisplay) eq 'DIAGNOSE' ) {
            my @OwnerGroups = _DiagnosisOwnerGroupsResolve(
                Ticket => \%Ticket,
                UserID => 1,
            );

            if (@OwnerGroups) {
                my %DiagnosisOwnerGroup = map { $_ => 1 } @OwnerGroups;

                if (
                    $ExistingOwnerGroup
                    && $DiagnosisOwnerGroup{$ExistingOwnerGroup}
                    && _IsSupportProfile(
                        GovernanceObjectID => $ExistingOwnerGroup,
                        UserID             => 1,
                    )
                    )
                {
                    $ResolutionCandidate     = $ExistingOwnerGroup;
                    $ResolvedSupportProfile = $ExistingOwnerGroup;
                    @DiagnosisFanoutOwnerGroups = grep { $_ ne $ExistingOwnerGroup } @OwnerGroups;
                }
                else {
                    $ResolutionCandidate = shift @OwnerGroups;
                    $ResolvedSupportProfile = $ResolutionCandidate;
                    @DiagnosisFanoutOwnerGroups = @OwnerGroups;
                }
            }
        }
        elsif ( _IsRequesterDefaultProfile($ProfileDisplay) ) {
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

            $ResolvedSupportProfile = $ResolutionCandidate;
            $AffectedUserOwnerUserID = $CustomerUserID;
        }
        else {
            $ResolutionCandidate = _ResolveGovernanceRoleSupportProfile(
                GovernanceRole => $DynamicGovernanceRole,
                ApplicationID  => $ApplicationID,
                UserID          => 1,
            );
            $ResolvedSupportProfile = $ResolutionCandidate;
        }
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

        $RequesterOwnerUserID = $CustomerUserID;
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

    elsif (!$ResolvedSupportProfile && !$DynamicGovernanceRole) {

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

    for my $OwnerGroup (@DiagnosisFanoutOwnerGroups) {
        _DiagnosisFanoutTicketCreate(
            Ticket     => \%Ticket,
            OwnerGroup => $OwnerGroup,
            UserID     => 1,
        );
    }

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
        . (
        _IsRequesterDefaultProfile($Profile)
        ? "Assigned Owner:\n"
            . ( $RequesterOwnerUserID || $CustomerUserID || 'N/A' )
            . "\n\n"
        : ''
        )
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
            . "SupportProfile=$ResolvedSupportProfile "
            . "Owner="
            . (
            _IsRequesterDefaultProfile($Profile)
            ? ( $RequesterOwnerUserID || $CustomerUserID || '' )
            : ''
            ),
    );

    return 1;
}

1;
