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
    'Kernel::System::ITSMConfigItem',
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
        return $Value->[0];
    }

    return $Value;
}

# ------------------------------------------------------------ #
# GET DYNAMIC FIELD VALUE
# ------------------------------------------------------------ #

sub _GetDynamicFieldValue {
    my ( %Param ) = @_;

    return if !$Param{Object};
    return if !$Param{Field};

    return _NormalizeValue(
        $Param{Object}->{XMLData}
            ->{ $Param{Field} }
            ->{Content}
    );
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

sub _GetConfigItem {
    my ( %Param ) = @_;

    return if !$Param{ConfigItemID};

    my $ConfigItemObject = $Kernel::OM->Get(
        'Kernel::System::ITSMConfigItem'
    );

    return $ConfigItemObject->ConfigItemGet(

        ConfigItemID  => $Param{ConfigItemID},

        DynamicFields => 1,
    );
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

    my $Application = _GetConfigItem(

        ConfigItemID => $Param{ApplicationID},
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

    my $Application = _GetConfigItem(

        ConfigItemID => $Param{ApplicationID},
    );

    return if !$Application;

    my $OrganizationID = _GetDynamicFieldValue(

        Object => $Application,

        Field => 'ZTSMAppSystem-Owner',
    );

    return if !$OrganizationID;

    my $Organization = _GetConfigItem(

        ConfigItemID => $OrganizationID,
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

    my $Application = _GetConfigItem(

        ConfigItemID => $Param{ApplicationID},
    );

    return if !$Application;

    my $PlatformID = _GetDynamicFieldValue(

        Object => $Application,

        Field => 'ZTSMAppSystem-Platform',
    );

    return if !$PlatformID;

    my $Platform = _GetConfigItem(

        ConfigItemID => $PlatformID,
    );

    return if !$Platform;

    my $OrganizationID = _GetDynamicFieldValue(

        Object => $Platform,

        Field => 'ZTSMPlatform-Owner',
    );

    return if !$OrganizationID;

    my $Organization = _GetConfigItem(

        ConfigItemID => $OrganizationID,
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

    my $Application = _GetConfigItem(

        ConfigItemID => $Param{ApplicationID},
    );

    return if !$Application;

    my $OrganizationID = _GetDynamicFieldValue(

        Object => $Application,

        Field => 'ZTSMAppSystem-Owner',
    );

    return if !$OrganizationID;

    LOOP:
    while ($OrganizationID) {

        my $Organization = _GetConfigItem(

            ConfigItemID => $OrganizationID,
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

    my $BlueBook = _GetConfigItem(
        ConfigItemID => $Param{BlueBookID},
    );

    return if !$BlueBook;
	
	my $Chapters = $BlueBook->{XMLData}->{'ZBlue-Record'};

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
	
    # -------------------------------------------------------- #
    # RUNTIME CONTEXT
    # -------------------------------------------------------- #

    my $ExistingOwnerGroup = _NormalizeValue(
		$Ticket{'DynamicField_ZTicket-OwnerGroup'}
	);

	return 1 if $ExistingOwnerGroup;
	
	my $Chapter = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Chapter'}
    );
	
	return if !$Chapter;

    my $BlueBook = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueBook'}
    );
	
	return if !$BlueBook;

    my $Role = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Role'}
    );

    my $ApplicationID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Application'}
    );

    my $CustomerUserID = $Ticket->{CustomerUserID};

	my $Profile = _ReadProfile(
		BlueBookID => $BlueBook,
		Chapter => $Chapter,
		);
	
    return if !$Profile;

    my $ResolvedSupportProfile;

    # -------------------------------------------------------- #
    # REQUESTER DEFAULT
    # -------------------------------------------------------- #

    if (
        $Profile eq 'REQUESTER-SUPPORT-GROUP'
    ) {

        $ResolvedSupportProfile
            = _ResolveRequesterProfile(

                CustomerUserID => $CustomerUserID,
            );
    }

    # -------------------------------------------------------- #
    # APP PROFILE
    # -------------------------------------------------------- #

    elsif (
        $Profile eq 'APP-PROFILE'
    ) {

        $ResolvedSupportProfile
            = _ResolveAppProfile(

                ApplicationID => $ApplicationID,
            );
    }

    # -------------------------------------------------------- #
    # APP OWNER
    # -------------------------------------------------------- #

    elsif (
        $Profile eq 'APP-OWNER'
    ) {

        $ResolvedSupportProfile
            = _ResolveAppOwnerProfile(

                ApplicationID => $ApplicationID,
            );
    }

    # -------------------------------------------------------- #
    # PLATFORM OWNER
    # -------------------------------------------------------- #

    elsif (
        $Profile eq 'PLATFORM-OWNER'
    ) {

        $ResolvedSupportProfile
            = _ResolvePlatformOwnerProfile(

                ApplicationID => $ApplicationID,
            );
    }

    # -------------------------------------------------------- #
    # TOP OWNER
    # -------------------------------------------------------- #

    elsif (
        $Profile eq 'TOP-OWNER'
    ) {

        $ResolvedSupportProfile
            = _ResolveTopOwnerProfile(

                ApplicationID => $ApplicationID,
            );
    }

    # -------------------------------------------------------- #
    # NO MATCH
    # -------------------------------------------------------- #

    else {

        $LogObject->Log(

            Priority => 'error',

            Message =>
                  'ZTSMRoleDirector: '
                . 'Unsupported governance profile: '
                . $Profile,
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
            . ( $Profile || 'N/A' )
            . "\n\n"
            . "Role:\n"
            . ( $Role || 'N/A' )
            . "\n\n"
            . "Application:\n"
            . ( $ApplicationID || 'N/A' );

        ZTSMArticleCreate(
            %Param,
            TicketID => $TicketID,
            Subject  => 'ZTSM Governance Resolution Failed',
            Body     => $Body,
            HistoryComment =>
                'ZTSM: Governance resolution failed '
                . 'Profile='
                . ( $Profile || 'N/A' ),
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
        . ( $Profile || 'N/A' )
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
            . ( $Profile || 'N/A' ),
        UserID => 1,
    );

    $LogObject->Log(

        Priority => 'notice',

        Message =>
              'ZTSMRoleDirector: '
            . 'Governance profile resolved '
            . "TicketID=$TicketID "
            . "Profile=$Profile "
            . "Role=$Role "
            . "SupportProfile=$ResolvedSupportProfile",
    );

    return 1;
}

1;
