# --
# Kernel/Modules/CustomerTicketZTSMAction.pm
# --
# TESSERA customer runtime action endpoint for child execution tickets.
# --

package Kernel::Modules::CustomerTicketZTSMAction;

use strict;
use warnings;

use Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector ();
use Kernel::System::VariableCheck qw(:all);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    return bless {%Param}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $TicketID      = $Self->{TicketID} || $ParamObject->GetParam( Param => 'TicketID' );
    my $RuntimeAction = $ParamObject->GetParam( Param => 'RuntimeAction' ) || '';
    my $Remarks       = $ParamObject->GetParam( Param => 'Remarks' ) || '';
    my $OwnerTarget   = $ParamObject->GetParam( Param => 'OwnerTarget' ) || '';

    if ( !$TicketID ) {
        return $LayoutObject->CustomerErrorScreen(
            Message => 'Need TicketID!',
        );
    }

    my $Access = $TicketObject->TicketCustomerPermission(
        Type     => 'ro',
        TicketID => $TicketID,
        UserID   => $Self->{UserID},
    );

    if ( !$Access ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
    );

    if ( !%Ticket ) {
        return $LayoutObject->CustomerErrorScreen(
            Message => 'Ticket not found.',
        );
    }

    if ( ( $Ticket{StateType} || '' ) eq 'closed' ) {
        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    my $Config              = $ConfigObject->Get('Ticket::Frontend::CustomerTicketZTSMAction') || {};
    my $CustomerPanelUserID = $ConfigObject->Get('CustomerPanelUserID') || 1;

    if ( $RuntimeAction eq 'CancelRequest' ) {
        if (
            !$Self->_RequesterCancelAllowed(
                Ticket => \%Ticket,
                Config => $Config,
            )
            )
        {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        if ( $Remarks !~ m{\S} ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please enter a cancellation reason.',
            );
        }

        my $CancelStateID = $Self->_RequesterCancelStateID(
            Config => $Config,
        );

        if ( !$CancelStateID ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'No valid requester cancellation state is configured.',
            );
        }

        my $StateSet = $TicketObject->TicketStateSet(
            StateID   => $CancelStateID,
            TicketID => $TicketID,
            UserID   => $CustomerPanelUserID,
        );

        if ( !$StateSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not cancel ticket.',
            );
        }

        $TicketObject->TicketLockSet(
            TicketID => $TicketID,
            Lock     => 'unlock',
            UserID   => $CustomerPanelUserID,
        );

        $Self->_RuntimeArticleCreate(
            TicketID            => $TicketID,
            RuntimeAction       => $RuntimeAction,
            Label               => 'Cancel Ticket',
            Remarks             => $Remarks,
            Subject             => 'Ticket cancelled by requester',
            Body                => "** Note: This ticket was cancelled by the requester '$Self->{UserID}'.",
            Config              => $Config,
            CustomerPanelUserID => $CustomerPanelUserID,
        );

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    if ( $RuntimeAction ne 'Unlock' ) {
        my $Permission = $Config->{Permission} || 'ztsm_action';
        $Access = $TicketObject->TicketCustomerPermission(
            Type     => $Permission,
            TicketID => $TicketID,
            UserID   => $Self->{UserID},
        );

        if ( !$Access ) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }
    }

    if ( $RuntimeAction eq 'Unlock' ) {
        $Access = $TicketObject->TicketCustomerPermission(
            Type     => 'ztsm_failback',
            TicketID => $TicketID,
            UserID   => $Self->{UserID},
        );

        if ( !$Access ) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $ActionableTicketType = _ActionableTicketType(
            Config => $Config,
            Type   => $Ticket{Type},
        );

        if ( !$ActionableTicketType ) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        if ($OwnerTarget) {
            my $AllowedOwnerTarget = $Self->_OwnerTargetAllowed(
                Ticket      => \%Ticket,
                OwnerTarget => $OwnerTarget,
            );

            if ( !$AllowedOwnerTarget ) {
                return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
            }
        }

        my $OwnerSet = $Self->_TicketDynamicFieldSet(
            FieldName => 'ZTicket-Owner',
            TicketID  => $TicketID,
            Value     => $OwnerTarget || '',
            UserID    => $CustomerPanelUserID,
        );

        if ( !$OwnerSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update ticket owner.',
            );
        }

        $TicketObject->TicketLockSet(
            TicketID => $TicketID,
            Lock     => $OwnerTarget ? 'lock' : 'unlock',
            UserID   => $CustomerPanelUserID,
        );

        my $Body = "** Note: This is a system-generated orchestration update message.\n\n"
            . "Runtime failback action 'Unlock' was submitted by customer user '$Self->{UserID}'.";

        if ($OwnerTarget) {
            $Body .= "\n\nTicket owner was assigned to '$OwnerTarget'.";
        }
        else {
            $Body .= "\n\nTicket owner was cleared.";
        }

        $Self->_RuntimeArticleCreate(
            TicketID            => $TicketID,
            RuntimeAction       => $RuntimeAction,
            Label               => 'Unlock',
            Remarks             => $Remarks,
            Body                => $Body,
            Config              => $Config,
            CustomerPanelUserID => $CustomerPanelUserID,
        );

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    if ( $RuntimeAction eq 'TakeOwnership' ) {
        my $ActionableTicketType = _ActionableTicketType(
            Config => $Config,
            Type   => $Ticket{Type},
        );

        if ( !$ActionableTicketType ) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $Owner = _NormalizeValue( $Ticket{'DynamicField_ZTicket-Owner'} );

        if ($Owner) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $OwnerSet = $Self->_TicketDynamicFieldSet(
            FieldName => 'ZTicket-Owner',
            TicketID  => $TicketID,
            Value     => $Self->{UserID},
            UserID    => $CustomerPanelUserID,
        );

        if ( !$OwnerSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update ticket owner.',
            );
        }

        my $OwnerWeightage = $Self->_OwnerWeightage(
            Ticket         => \%Ticket,
            CustomerUserID => $Self->{UserID},
        );

        my $OwnerWeightageSet = $Self->_TicketDynamicFieldSet(
            FieldName => 'ZTicket-OwnerWeightage',
            TicketID  => $TicketID,
            Value     => $OwnerWeightage,
            UserID    => $CustomerPanelUserID,
        );

        if ( !$OwnerWeightageSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update ticket owner weightage.',
            );
        }

        $TicketObject->TicketLockSet(
            TicketID => $TicketID,
            Lock     => 'lock',
            UserID   => $CustomerPanelUserID,
        );

        if ( ( $Ticket{State} || '' ) ne 'in-progress' ) {
            my $StateObject = $Kernel::OM->Get('Kernel::System::State');
            my $InProgressStateID = $StateObject->StateLookup(
                State => 'in-progress',
            );

            if ( !$InProgressStateID ) {
                return $LayoutObject->CustomerErrorScreen(
                    Message => 'State in-progress is not configured.',
                );
            }

            my $StateSet = $TicketObject->TicketStateSet(
                StateID  => $InProgressStateID,
                TicketID => $TicketID,
                UserID   => $CustomerPanelUserID,
            );

            if ( !$StateSet ) {
                return $LayoutObject->CustomerErrorScreen(
                    Message => 'Could not move ticket to in-progress.',
                );
            }
        }

        $Self->_RuntimeArticleCreate(
            TicketID             => $TicketID,
            RuntimeAction        => $RuntimeAction,
            Label                => 'Take Ownership',
            Remarks              => $Remarks,
            Config               => $Config,
            CustomerPanelUserID  => $CustomerPanelUserID,
        );

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    my $Owner = _NormalizeValue( $Ticket{'DynamicField_ZTicket-Owner'} );
    if ( !$Owner || lc $Owner ne lc $Self->{UserID} ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    my $ActionConfig = _ActionConfig(
        Config => $Config,
        Action => $RuntimeAction,
        Type   => $Ticket{Type},
    );

    if ( !$ActionConfig ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    if ( $Ticket{Type} eq 'Assessment' ) {
        my $Fields = $Config->{AssessmentFields} || [
            'ZTicket-TechnicalRisk',
            'ZTicket-BusinessRisk',
            'ZTicket-GovernanceRisk',
        ];

        my $RiskFieldsSet = $Self->_AssessmentRiskFieldsSet(
            Fields => $Fields,
            TicketID => $TicketID,
            UserID => $CustomerPanelUserID,
        );

        if ( !$RiskFieldsSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update assessment risk fields.',
            );
        }
    }

    my $StateSet = $TicketObject->TicketStateSet(
        State    => $ActionConfig->{State},
        TicketID => $TicketID,
        UserID   => $CustomerPanelUserID,
    );

    if ( !$StateSet ) {
        return $LayoutObject->CustomerErrorScreen(
            Message => 'Could not update ticket state.',
        );
    }

    $TicketObject->TicketLockSet(
        TicketID => $TicketID,
        Lock     => 'unlock',
        UserID   => $CustomerPanelUserID,
    );

    $Self->_RuntimeArticleCreate(
        TicketID             => $TicketID,
        RuntimeAction        => $RuntimeAction,
        Label                => $ActionConfig->{Label} || $RuntimeAction,
        Remarks              => $Remarks,
        Body                 => $ActionConfig->{Body},
        Subject              => $ActionConfig->{Subject},
        Config               => $Config,
        CustomerPanelUserID  => $CustomerPanelUserID,
    );

    $Self->_ChapterDirectorRun(
        TicketID             => $TicketID,
        TicketObject         => $TicketObject,
        CustomerPanelUserID  => $CustomerPanelUserID,
    );

    return $LayoutObject->Redirect(
        OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
    );
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return $Value->[0];
    }

    return $Value;
}

sub _ChapterDirectorRun {
    my ( $Self, %Param ) = @_;

    return if !$Param{TicketID};
    return if !$Param{TicketObject};

    my %Ticket = $Param{TicketObject}->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
        UserID        => $Param{CustomerPanelUserID} || 1,
        Silent        => 1,
    );

    return if !IsHashRefWithData( \%Ticket );
    return if !_NormalizeValue( $Ticket{'DynamicField_ZTicket-Parent'} );
    return if !_NormalizeValue( $Ticket{'DynamicField_ZTicket-BlueBook'} );
    return if !_NormalizeValue( $Ticket{'DynamicField_ZTicket-BlueLevel'} );

    my $ChapterDirector = Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector->new();

    return $ChapterDirector->Run(
        Ticket => \%Ticket,
        UserID => $Param{CustomerPanelUserID} || 1,
    );
}

sub _RequesterCancelAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);
    return if !$Ticket->{CustomerUserID};
    return if lc $Ticket->{CustomerUserID} ne lc $Self->{UserID};

    # Orchestration child tickets carry ZTicket-Parent. Only the story root can be requester-cancelled.
    return if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );

    my $ParentTypes = $Config->{RequesterCancelTypes} || [
        'ServiceRequest',
        'Change',
        'Incident',
        'Incident:Major',
        'Problem',
    ];

    my %AllowedType = map { $_ => 1 } @{$ParentTypes};

    return $AllowedType{ $Ticket->{Type} };
}

sub _RequesterCancelStateID {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config} || {};

    my @StateCandidates;

    if ( $Config->{RequesterCancelState} ) {
        push @StateCandidates, $Config->{RequesterCancelState};
    }

    if ( IsArrayRefWithData( $Config->{RequesterCancelStates} ) ) {
        push @StateCandidates, @{ $Config->{RequesterCancelStates} };
    }

    push @StateCandidates, (
        'closed cancelled',
        'closed canceled',
        'closed unsuccessful',
        'closed rejected',
    );

    my %Seen;
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    STATE:
    for my $State (@StateCandidates) {
        next STATE if !$State;
        next STATE if $Seen{$State}++;

        my $StateID = $StateObject->StateLookup(
            State => $State,
        );

        return $StateID if $StateID;
    }

    return;
}

sub _TicketDynamicFieldSet {
    my ( $Self, %Param ) = @_;

    return if !$Param{FieldName};
    return if !$Param{TicketID};
    return if !$Param{UserID};

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{FieldName},
    );

    return if !IsHashRefWithData($DynamicFieldConfig);
    return if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

    return $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID},
    );
}

sub _OwnerTargetAllowed {
    my ( $Self, %Param ) = @_;

    return if !$Param{OwnerTarget};
    return if !IsHashRefWithData( $Param{Ticket} );

    my $OwnerGroup = $Param{Ticket}->{'DynamicField_ZTicket-OwnerGroup'};
    if ( ref $OwnerGroup eq 'ARRAY' ) {
        $OwnerGroup = $OwnerGroup->[0];
    }

    return if !$OwnerGroup;

    my $AssignmentUsers = $Self->_SupportAssignmentUsers(
        SupportProfile => $OwnerGroup,
    );

    return if !IsHashRefWithData($AssignmentUsers);
    return $AssignmentUsers->{ $Param{OwnerTarget} };
}

sub _OwnerWeightage {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return 1 if !IsHashRefWithData($Ticket);

    my $OwnerGroup = $Ticket->{'DynamicField_ZTicket-OwnerGroup'};
    if ( ref $OwnerGroup eq 'ARRAY' ) {
        $OwnerGroup = $OwnerGroup->[0];
    }

    return 1 if !$OwnerGroup;

    my @Assignments = $Self->_SupportAssignments(
        SupportProfile => $OwnerGroup,
        CustomerUserID  => $Param{CustomerUserID},
    );

    my $TicketRole = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Role'}
    );

    my $SelectedAssignment;
    ASSIGNMENT:
    for my $Assignment (@Assignments) {
        next ASSIGNMENT if !IsHashRefWithData($Assignment);

        my $AssignmentRole = _NormalizeValue(
            $Assignment->{XMLData}
                && $Assignment->{XMLData}->{'ZTSMSupportAssignment-Role'}
                && $Assignment->{XMLData}->{'ZTSMSupportAssignment-Role'}->{Content}
        );

        my $Type = _NormalizeValue(
            $Assignment->{XMLData}
                && $Assignment->{XMLData}->{'ZTSMSupportAssignment-Type'}
                && $Assignment->{XMLData}->{'ZTSMSupportAssignment-Type'}->{Content}
        );

        if (
            defined $TicketRole
            && $TicketRole ne ''
            && defined $AssignmentRole
            && lc $AssignmentRole eq lc $TicketRole
            )
        {
            $SelectedAssignment = $Assignment;
            last ASSIGNMENT;
        }

        next ASSIGNMENT if defined $TicketRole && $TicketRole ne '';

        $SelectedAssignment ||= $Assignment;

        if ( defined $Type && $Type eq 'Primary' ) {
            $SelectedAssignment = $Assignment;
        }
    }

    return 1 if !IsHashRefWithData($SelectedAssignment);

    my $Weightage = _NormalizeValue(
        $SelectedAssignment->{XMLData}
            && $SelectedAssignment->{XMLData}->{'ZTSMSupportAssignment-Weightage'}
            && $SelectedAssignment->{XMLData}->{'ZTSMSupportAssignment-Weightage'}->{Content}
    );

    return defined $Weightage && $Weightage ne '' ? $Weightage : 1;
}

sub _SupportAssignments {
    my ( $Self, %Param ) = @_;

    return if !$Param{SupportProfile};

    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my %AssignmentID;

    SUPPORTPROFILE:
    for my $SupportProfile ( $Self->_SupportProfileReferences( SupportProfile => $Param{SupportProfile} ) ) {
        next SUPPORTPROFILE if !$SupportProfile;

        my @FoundAssignmentIDs = $ConfigItemObject->ConfigItemSearch(
            Classes => ['Support Assignment'],
            'DynamicField_ZTSMSupportAssignment-SupportProfile' => {
                Equals => $SupportProfile,
            },
            Result => 'ARRAY',
            Limit  => 1000,
        );

        $AssignmentID{$_} = 1 for @FoundAssignmentIDs;
    }

    my @Assignments;
    ASSIGNMENT:
    for my $AssignmentID ( sort { $a <=> $b } keys %AssignmentID ) {
        my $Assignment = $ConfigItemObject->ConfigItemGet(
            ConfigItemID  => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !IsHashRefWithData($Assignment);

        if ( $Param{CustomerUserID} ) {
            my $UserAccount = _NormalizeValue(
                $Assignment->{XMLData}
                    && $Assignment->{XMLData}->{'ZTSMSupportAssignment-UserAccount'}
                    && $Assignment->{XMLData}->{'ZTSMSupportAssignment-UserAccount'}->{Content}
            );

            next ASSIGNMENT if !$UserAccount;
            next ASSIGNMENT if lc $UserAccount ne lc $Param{CustomerUserID};
        }

        push @Assignments, $Assignment;
    }

    return @Assignments;
}

sub _SupportProfileReferences {
    my ( $Self, %Param ) = @_;

    my $SupportProfile = _NormalizeValue( $Param{SupportProfile} );

    return if !defined $SupportProfile;
    return if $SupportProfile eq '';

    my %Reference;

    if ( $SupportProfile =~ m{\A\d+\z} ) {
        $Reference{$SupportProfile} = 1;
    }

    return sort keys %Reference;
}

sub _SupportAssignmentUsers {
    my ( $Self, %Param ) = @_;

    return if !$Param{SupportProfile};

    my %Users;
    ASSIGNMENT:
    for my $Assignment ( $Self->_SupportAssignments( SupportProfile => $Param{SupportProfile} ) ) {
        my $UserAccount = $Assignment->{XMLData}
            ->{'ZTSMSupportAssignment-UserAccount'}
            ->{Content};

        if ( ref $UserAccount eq 'ARRAY' ) {
            $UserAccount = $UserAccount->[0];
        }

        next ASSIGNMENT if !$UserAccount;

        $Users{$UserAccount} = 1;
    }

    return \%Users;
}

sub _RuntimeArticleCreate {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config} || {};
    return 1 if !( $Config->{Article} // 1 );

    my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal');

    my $Label = $Param{Label} || $Param{RuntimeAction};
    my $From  = "\"$Self->{UserFullname}\" <$Self->{UserEmail}>";
    my $Body  = $Param{Body}
        || "** Note: This is a system-generated orchestration update message.\n\n"
        . "Runtime action '$Label' was submitted by customer user '$Self->{UserID}'.";

    if ( $Param{Remarks} ) {
        $Body .= "\n\nRemarks:\n$Param{Remarks}";
    }

    return $ArticleBackendObject->ArticleCreate(
        TicketID             => $Param{TicketID},
        IsVisibleForCustomer => $Config->{IsVisibleForCustomer} // 1,
        SenderType           => $Config->{SenderType} || 'customer',
        From                 => $From,
        Subject              => $Param{Subject} || "Runtime action: $Label",
        Body                 => $Body,
        ContentType          => $Config->{ContentType} || 'text/plain; charset=utf-8',
        HistoryType          => $Config->{HistoryType} || 'AddNote',
        HistoryComment       => $Config->{HistoryComment} || '%%',
        UserID               => $Param{CustomerPanelUserID},
    );
}

sub _AssessmentRiskFieldsSet {
    my ( $Self, %Param ) = @_;

    return if !IsArrayRefWithData( $Param{Fields} );
    return if !$Param{TicketID};
    return if !$Param{UserID};

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $LayoutObject              = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject               = $Kernel::OM->Get('Kernel::System::Web::Request');

    FIELD:
    for my $FieldName ( @{ $Param{Fields} } ) {
        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $FieldName,
        );

        return if !IsHashRefWithData($DynamicFieldConfig);
        return if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

        my $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            Mandatory          => 1,
        );

        return if !IsHashRefWithData($ValidationResult);
        return if $ValidationResult->{ServerError};

        my $Value = $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );

        my $Success = $DynamicFieldBackendObject->ValueSet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{TicketID},
            Value              => $Value,
            UserID             => $Param{UserID},
        );

        return if !$Success;
    }

    return 1;
}

sub _ActionConfig {
    my (%Param) = @_;

    return if !$Param{Action};
    return if !$Param{Type};

    my $Actions = $Param{Config}->{Actions} || {
        Approve => {
            Label => 'Approve',
            State => 'closed successful',
            Types => ['Approval'],
        },
        Endorse => {
            Label => 'Endorse',
            State => 'closed successful',
            Types => ['Endorsement'],
        },
        Assess => {
            Label => 'Assess',
            State => 'closed successful',
            Types => ['Assessment'],
        },
        Reject => {
            Label => 'Reject',
            State => 'closed rejected',
            Types => [ 'Approval', 'Assessment', 'Endorsement' ],
        },
    };

    my $ActionConfig = $Actions->{ $Param{Action} };
    return if !$ActionConfig;

    my %AllowedTypes = map { $_ => 1 } @{ $ActionConfig->{Types} || [] };
    return if !$AllowedTypes{ $Param{Type} };
    return if !$ActionConfig->{State};

    return $ActionConfig;
}

sub _ActionableTicketType {
    my (%Param) = @_;

    return if !$Param{Type};

    my $Actions = $Param{Config}->{Actions} || {
        Approve => {
            Label => 'Approve',
            State => 'closed successful',
            Types => ['Approval'],
        },
        Endorse => {
            Label => 'Endorse',
            State => 'closed successful',
            Types => ['Endorsement'],
        },
        Assess => {
            Label => 'Assess',
            State => 'closed successful',
            Types => ['Assessment'],
        },
        Reject => {
            Label => 'Reject',
            State => 'closed rejected',
            Types => [ 'Approval', 'Assessment', 'Endorsement' ],
        },
    };

    ACTION:
    for my $Action ( keys %{$Actions} ) {
        my $ActionConfig = $Actions->{$Action};
        next ACTION if !$ActionConfig->{State};

        my %AllowedTypes = map { $_ => 1 } @{ $ActionConfig->{Types} || [] };
        return 1 if $AllowedTypes{ $Param{Type} };
    }

    return;
}

1;
