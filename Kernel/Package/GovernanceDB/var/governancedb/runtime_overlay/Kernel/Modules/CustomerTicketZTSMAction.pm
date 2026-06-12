# --
# Kernel/Modules/CustomerTicketZTSMAction.pm
# --
# TESSERA customer runtime action endpoint for child execution tickets.
# --

package Kernel::Modules::CustomerTicketZTSMAction;

use strict;
use warnings;

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleBodyConfigItemReferencesExpand);
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
    my $Subaction     = $ParamObject->GetParam( Param => 'Subaction' ) || '';
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

    if ( $RuntimeAction eq 'RequesterHold' || $RuntimeAction eq 'RequesterResume' ) {
        if (
            !$Self->_RequesterExecutionPauseAllowed(
                Ticket => \%Ticket,
                Config => $Config,
            )
            )
        {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $Success = $RuntimeAction eq 'RequesterHold'
            ? $Self->_RequesterHoldApply(
            Ticket              => \%Ticket,
            Config              => $Config,
            CustomerPanelUserID => $CustomerPanelUserID,
            Remarks             => $Remarks,
            )
            : $Self->_RequesterResumeApply(
            Ticket              => \%Ticket,
            Config              => $Config,
            CustomerPanelUserID => $CustomerPanelUserID,
            Remarks             => $Remarks,
            );

        if ( !$Success ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => $RuntimeAction eq 'RequesterHold'
                    ? 'Could not place ticket on hold.'
                    : 'Could not resume ticket.',
            );
        }

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    if ( _NormalizeValue( $Ticket{'DynamicField_ZTicket-HoldState'} ) ) {
        return $LayoutObject->CustomerErrorScreen(
            Message => 'Ticket is on hold. Please resume before continuing execution actions.',
        );
    }

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

    if ( $Ticket{Type} eq 'Assessment' && $RuntimeAction eq 'Assess' ) {
        if ( $Subaction ne 'SubmitRiskAssessment' ) {
            return $Self->_RiskAssessmentWorkspaceShow(
                Ticket   => \%Ticket,
                Config   => $Config,
                TicketID => $TicketID,
            );
        }

        my $Rows = $Self->_RiskAssessmentRowsFromParam();
        if ( !IsArrayRefWithData($Rows) ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please add at least one risk assessment row.',
            );
        }

        my $RiskAssessmentSet = $Self->_TicketDynamicFieldSet(
            FieldName => 'ZRM-RiskAssessment',
            TicketID  => $TicketID,
            Value     => $Rows,
            UserID    => $CustomerPanelUserID,
        );

        if ( !$RiskAssessmentSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update risk assessment.',
            );
        }

        $ActionConfig->{Body} = $Self->_RiskAssessmentArticleBody(
            Rows    => $Rows,
            Remarks => $Remarks,
        );
        $ActionConfig->{Subject} ||= 'Risk assessment submitted';
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

sub _RequesterExecutionPauseAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};

    return if !IsHashRefWithData($Ticket);
    return if !$Ticket->{CustomerUserID};
    return if lc $Ticket->{CustomerUserID} ne lc $Self->{UserID};
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    # Child tickets are execution ledgers; only the requester of the governance/root ticket may pause or resume.
    return if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );

    return 1;
}

sub _RequesterHoldApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $HoldState = $Self->_RequesterHoldState(
        Config => $Param{Config},
    );
    return if !$HoldState;

    my $ParentTicketNumber = $Ticket->{TicketNumber} || $Ticket->{TicketID};

    return if !$Self->_RequesterHoldTicketApply(
        Ticket              => $Ticket,
        HoldState           => $HoldState,
        CustomerPanelUserID => $Param{CustomerPanelUserID},
        Subject             => 'Requester placed ticket on hold',
        Body                => "Requester has placed this ticket On Hold.\n\n"
            . "Execution has been paused pending requester instruction.\n\n"
            . "No lifecycle transition has occurred.",
        Remarks             => $Param{Remarks},
    );

    for my $ChildTicketID ( $Self->_RequesterChildTicketIDs( ParentTicketID => $Ticket->{TicketID} ) ) {
        my %ChildTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $ChildTicketID,
            DynamicFields => 1,
            UserID        => $Param{CustomerPanelUserID},
            Silent        => 1,
        );

        next if !IsHashRefWithData( \%ChildTicket );
        next if ( $ChildTicket{StateType} || '' ) eq 'closed';

        return if !$Self->_RequesterHoldTicketApply(
            Ticket              => \%ChildTicket,
            HoldState           => $HoldState,
            CustomerPanelUserID => $Param{CustomerPanelUserID},
            Subject             => 'Requester placed parent ticket on hold',
            Body                => "Requester has placed the parent ticket On Hold.\n\n"
                . "Execution has been paused pending requester instruction.\n\n"
                . "Parent Ticket: $ParentTicketNumber",
        );
    }

    return 1;
}

sub _RequesterHoldTicketApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    my $CurrentState = $Ticket->{State} || '';
    return 1 if $CurrentState eq $Param{HoldState};

    my $StoredState = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    $StoredState ||= $CurrentState;

    return if !$Self->_TicketDynamicFieldSet(
        FieldName => 'ZTicket-HoldState',
        TicketID  => $Ticket->{TicketID},
        Value     => $StoredState,
        UserID    => $Param{CustomerPanelUserID},
    );

    return if !$Kernel::OM->Get('Kernel::System::Ticket')->TicketStateSet(
        State    => $Param{HoldState},
        TicketID => $Ticket->{TicketID},
        UserID   => $Param{CustomerPanelUserID},
    );

    return $Self->_RequesterExecutionArticleCreate(
        TicketID            => $Ticket->{TicketID},
        Subject             => $Param{Subject},
        Body                => $Param{Body},
        Remarks             => $Param{Remarks},
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );
}

sub _RequesterResumeApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $ParentTicketNumber = $Ticket->{TicketNumber} || $Ticket->{TicketID};

    return if !$Self->_RequesterResumeTicketApply(
        Ticket              => $Ticket,
        CustomerPanelUserID => $Param{CustomerPanelUserID},
        Subject             => 'Requester resumed ticket execution',
        Body                => "Requester has resumed ticket execution.\n\n"
            . "Execution continues from the existing lifecycle position.\n\n"
            . "No lifecycle transition has occurred.",
        Remarks             => $Param{Remarks},
    );

    for my $ChildTicketID ( $Self->_RequesterChildTicketIDs( ParentTicketID => $Ticket->{TicketID} ) ) {
        my %ChildTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $ChildTicketID,
            DynamicFields => 1,
            UserID        => $Param{CustomerPanelUserID},
            Silent        => 1,
        );

        next if !IsHashRefWithData( \%ChildTicket );
        next if ( $ChildTicket{StateType} || '' ) eq 'closed';

        return if !$Self->_RequesterResumeTicketApply(
            Ticket              => \%ChildTicket,
            CustomerPanelUserID => $Param{CustomerPanelUserID},
            Subject             => 'Requester resumed parent ticket',
            Body                => "Requester has resumed the parent ticket.\n\n"
                . "Execution continues from the existing lifecycle position.\n\n"
                . "Parent Ticket: $ParentTicketNumber",
        );
    }

    return 1;
}

sub _RequesterResumeTicketApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    my $RestoreState = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    return 1 if !$RestoreState;

    return if !$Kernel::OM->Get('Kernel::System::Ticket')->TicketStateSet(
        State    => $RestoreState,
        TicketID => $Ticket->{TicketID},
        UserID   => $Param{CustomerPanelUserID},
    );

    return if !$Self->_TicketDynamicFieldSet(
        FieldName => 'ZTicket-HoldState',
        TicketID  => $Ticket->{TicketID},
        Value     => '',
        UserID    => $Param{CustomerPanelUserID},
    );

    return $Self->_RequesterExecutionArticleCreate(
        TicketID            => $Ticket->{TicketID},
        Subject             => $Param{Subject},
        Body                => $Param{Body},
        Remarks             => $Param{Remarks},
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );
}

sub _RequesterHoldState {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config} || {};
    my @StateCandidates;

    if ( $Config->{RequesterHoldState} ) {
        push @StateCandidates, $Config->{RequesterHoldState};
    }

    if ( IsArrayRefWithData( $Config->{RequesterHoldStates} ) ) {
        push @StateCandidates, @{ $Config->{RequesterHoldStates} };
    }

    push @StateCandidates, ( 'onhold', 'On Hold', 'on hold' );

    my %Seen;
    my $StateObject = $Kernel::OM->Get('Kernel::System::State');

    STATE:
    for my $State (@StateCandidates) {
        next STATE if !$State;
        next STATE if $Seen{$State}++;

        my $StateID = $StateObject->StateLookup(
            State => $State,
        );

        return $State if $StateID;
    }

    return;
}

sub _RequesterChildTicketIDs {
    my ( $Self, %Param ) = @_;

    return if !$Param{ParentTicketID};

    return $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result => 'ARRAY',
        Limit  => 10000,
        UserID => 1,
        'DynamicField_ZTicket-Parent' => {
            Equals => $Param{ParentTicketID},
        },
        StateType => [ 'new', 'open', 'pending reminder', 'pending auto' ],
    );
}

sub _RequesterExecutionArticleCreate {
    my ( $Self, %Param ) = @_;

    my $Body = $Param{Body} || '';
    if ( $Param{Remarks} ) {
        $Body .= "\n\nRemarks:\n$Param{Remarks}";
    }

    return $Self->_RuntimeArticleCreate(
        TicketID            => $Param{TicketID},
        Label               => $Param{Subject},
        Subject             => $Param{Subject},
        Body                => $Body,
        Config              => {
            Article              => 1,
            IsVisibleForCustomer => 1,
            SenderType           => 'customer',
            ContentType          => 'text/plain; charset=utf-8',
            HistoryType          => 'AddNote',
            HistoryComment       => '%%',
        },
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );
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
        $SelectedAssignment->{'DynamicField_ZTSMSupportAssignment-Weightage'}
    );

    return defined $Weightage && $Weightage ne '' ? $Weightage : 1;
}

sub _SupportAssignments {
    my ( $Self, %Param ) = @_;

    return if !$Param{SupportProfile};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %AssignmentID;

    SUPPORTPROFILE:
    for my $SupportProfile ( $Self->_SupportProfileReferences( SupportProfile => $Param{SupportProfile} ) ) {
        next SUPPORTPROFILE if !$SupportProfile;

        my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
            Classes => ['SupportAssignment'],
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
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !IsHashRefWithData($Assignment);

        if ( $Param{CustomerUserID} ) {
            my $UserAccount = _NormalizeValue(
                $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'}
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
            && $Assignment->{XMLData}->{'ZTSMSupportAssignment-UserAccount'}
            && $Assignment->{XMLData}->{'ZTSMSupportAssignment-UserAccount'}->{Content};
        $UserAccount ||= $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'};

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

    $Body = ZTSMArticleBodyConfigItemReferencesExpand(
        Body => $Body,
    );

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

sub _RiskAssessmentColumns {
    return (
        { Field => 'ZRM-ImpactCategory',          Label => 'Category',                             Type => 'GeneralCatalog' },
        { Field => 'ZRM-RiskCategory',            Label => 'Risk Category',                        Type => 'GeneralCatalog' },
        { Field => 'ZRM-RiskStatement',           Label => 'Risk Statement',                       Type => 'GovernanceObject' },
        { Field => 'ZRM-RiskDetail',              Label => 'Risk Detail',                          Type => 'TextArea' },
        { Field => 'ZRM-InherentLikelihood',      Label => 'Inherent Likelihood',                  Type => 'GeneralCatalog' },
        { Field => 'ZRM-InherentImpact',          Label => 'Inherent Impact',                      Type => 'GeneralCatalog' },
        { Field => 'ZRM-InherentCalculatedRisk',  Label => 'Inherent - Calculated Risk Score',     Type => 'Text' },
        { Field => 'ZRM-RiskAction',              Label => 'Risk Action',                          Type => 'Dropdown' },
        { Field => 'ZRM-RiskPlan',                Label => 'Risk Plan',                            Type => 'TextArea' },
        { Field => 'ZRM-ResidualLikelihood',      Label => 'Residual Likelihood',                  Type => 'GeneralCatalog' },
        { Field => 'ZRM-ResidualImpact',          Label => 'Residual Impact',                      Type => 'GeneralCatalog' },
        { Field => 'ZRM-ResidualCalculatedRisk',  Label => 'Residual - Calculated Risk Score',     Type => 'Text' },
    );
}

sub _RiskAssessmentTargetColumns {
    return (
        { Field => 'ZRM-RiskTargetCI', Label => 'Target CI',                Type => 'ConfigItem' },
        { Field => 'ZRM-RiskTargetGO', Label => 'Target Governance Object', Type => 'GovernanceObject' },
    );
}

sub _RiskAssessmentWorkspaceShow {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $HTML = $Self->_RiskAssessmentWorkspaceHTML(
        Ticket => $Param{Ticket},
    );

    my $Output = $LayoutObject->CustomerHeader( Value => $Param{Ticket}->{TicketNumber} );
    $Output .= $LayoutObject->CustomerNavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerTicketZTSMRiskAssessment',
        Data         => {
            TicketID       => $Param{TicketID},
            TicketNumber   => $Param{Ticket}->{TicketNumber},
            TicketTitle    => $Param{Ticket}->{Title},
            WorkspaceHTML  => $HTML,
        },
    );
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

sub _RiskAssessmentWorkspaceHTML {
    my ( $Self, %Param ) = @_;

    my $Rows = $Self->_RiskAssessmentRowsGet(
        TicketID => $Param{Ticket}->{TicketID},
    );

    $Rows = [ {} ] if !IsArrayRefWithData($Rows);

    my @Columns = _RiskAssessmentColumns();
    my @Targets = _RiskAssessmentTargetColumns();
    my $Configs = $Self->_RiskAssessmentFieldConfigs(
        Fields => [ map { $_->{Field} } ( @Columns, @Targets ) ],
    );

    my $HTML = '<div id="ZTSMRiskAssessmentRows" class="ZTSMRiskAssessmentRows">';

    my $Index = 0;
    for my $Row ( @{$Rows} ) {
        $HTML .= $Self->_RiskAssessmentRowHTML(
            Row     => $Row,
            Index   => $Index++,
            Columns => \@Columns,
            Targets => \@Targets,
            Configs => $Configs,
        );
    }

    $HTML .= '</div>';
    $HTML .= '<template id="ZTSMRiskAssessmentTemplate">'
        . $Self->_RiskAssessmentRowHTML(
        Row      => {},
        Index    => '__INDEX__',
        Columns  => \@Columns,
        Targets  => \@Targets,
        Configs   => $Configs,
        Template => 1,
        )
        . '</template>';

    return $HTML;
}

sub _RiskAssessmentRowHTML {
    my ( $Self, %Param ) = @_;

    my $Index = $Param{Index};
    my $Row   = $Param{Row} || {};
    my %Column = map { $_->{Field} => $_ } @{ $Param{Columns} || [] };
    my %Target = map { $_->{Field} => $_ } @{ $Param{Targets} || [] };

    my $FieldHTML = sub {
        my ($Field) = @_;
        my $Definition = $Column{$Field} || $Target{$Field} || {};

        return '<div class="ZTSMRiskAssessmentField ZTSMRiskAssessmentField_' . _HTML($Field) . '">'
            . '<label>' . _HTML( $Definition->{Label} || $Field ) . '</label>'
            . $Self->_RiskAssessmentInputHTML(
            Field  => $Field,
            Type   => $Definition->{Type},
            Index  => $Index,
            Value  => $Row->{$Field},
            Config => $Param{Configs}->{$Field},
            )
            . '</div>';
    };

    my $HTML = '<section class="ZTSMRiskAssessmentRow" data-row-index="' . _HTML($Index) . '">';
    $HTML .= '<div class="ZTSMRiskAssessmentRowHead">'
        . '<input type="hidden" name="RA_RowIndex" value="' . _HTML($Index) . '"/>'
        . '<strong>Risk Row <span class="ZTSMRiskAssessmentRowNumber"></span></strong>'
        . '<button type="button" class="ZTSMRiskAssessmentRemove" title="Remove row">-</button>'
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentGrid ZTSMRiskAssessmentGrid2">'
        . $FieldHTML->('ZRM-ImpactCategory')
        . $FieldHTML->('ZRM-RiskCategory')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentGrid ZTSMRiskAssessmentGrid2">'
        . $FieldHTML->('ZRM-RiskStatement')
        . $FieldHTML->('ZRM-RiskDetail')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentGrid ZTSMRiskAssessmentGrid3">'
        . $FieldHTML->('ZRM-InherentLikelihood')
        . $FieldHTML->('ZRM-InherentImpact')
        . $FieldHTML->('ZRM-InherentCalculatedRisk')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentGrid ZTSMRiskAssessmentGrid2">'
        . $FieldHTML->('ZRM-RiskAction')
        . $FieldHTML->('ZRM-RiskPlan')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentGrid ZTSMRiskAssessmentGrid3">'
        . $FieldHTML->('ZRM-ResidualLikelihood')
        . $FieldHTML->('ZRM-ResidualImpact')
        . $FieldHTML->('ZRM-ResidualCalculatedRisk')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentGrid ZTSMRiskAssessmentGrid2">'
        . $FieldHTML->('ZRM-RiskTargetCI')
        . $FieldHTML->('ZRM-RiskTargetGO')
        . '</div>';
    $HTML .= '</section>';

    return $HTML;
}

sub _RiskAssessmentInputHTML {
    my ( $Self, %Param ) = @_;

    my $Field = $Param{Field};
    my $Index = $Param{Index};
    my $Value = $Param{Value};

    if ( IsHashRefWithData( $Param{Config} ) && ( $Param{Config}->{FieldType} || '' ) =~ m{\A(?:ConfigItem|ConfigItemVersion|GovernanceObject|Reference)\z} ) {
        return $Self->_RiskAssessmentReferenceInputHTML(%Param);
    }

    if ( IsHashRefWithData( $Param{Config} ) ) {
        my $DynamicFieldHTML = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->EditFieldRender(
            DynamicFieldConfig => $Param{Config},
            Value              => $Value,
            LayoutObject       => $Kernel::OM->Get('Kernel::Output::HTML::Layout'),
            ParamObject        => $Kernel::OM->Get('Kernel::System::Web::Request'),
            Mandatory          => 0,
            CustomerInterface  => 1,
            Object             => {},
        );

        if ( IsHashRefWithData($DynamicFieldHTML) ) {
            my $FieldHTML = $DynamicFieldHTML->{Field} || '';
            if ( !$FieldHTML && IsArrayRefWithData( $DynamicFieldHTML->{MultiValue} ) ) {
                $FieldHTML = join "\n", @{ $DynamicFieldHTML->{MultiValue} };
                $FieldHTML .= "\n" . ( $DynamicFieldHTML->{MultiValueTemplate} || '' );
            }

            if ($FieldHTML) {
                return $Self->_RiskAssessmentFieldNameRewrite(
                    HTML  => $FieldHTML,
                    Field => $Field,
                    Index => $Index,
                );
            }
        }
    }

    my $Name       = 'RA_' . $Index . '_' . $Field;
    my $EditValue  = $Self->_RiskAssessmentEditValue(%Param);
    my $FieldClass = $Param{Type} eq 'TextArea' ? 'ZTSMRiskAssessmentTextarea' : 'ZTSMRiskAssessmentInput';

    if ( $Param{Type} eq 'TextArea' ) {
        return '<textarea class="' . $FieldClass . '" name="' . _HTML($Name) . '" rows="3">' . _HTML($EditValue) . '</textarea>';
    }

    return '<input type="text" class="' . $FieldClass . '" name="' . _HTML($Name) . '" value="' . _HTML($EditValue) . '"/>';
}

sub _RiskAssessmentReferenceInputHTML {
    my ( $Self, %Param ) = @_;

    my $Field = $Param{Field};
    my $Index = $Param{Index};
    my $Name  = 'RA_' . $Index . '_' . $Field;
    my $ID    = 'DynamicField_' . $Field . '_' . $Index;
    my $Value = _NormalizeValue( $Param{Value} );
    my $Label = $Param{Config}->{Label} || $Field;
    my $VisibleValue = $Self->_RiskAssessmentDisplayValue(
        Field => $Field,
        Type  => $Param{Type},
        Value => $Value,
    );

    return '<input type="hidden" id="' . _HTML($ID) . '" name="' . _HTML($Name) . '" value="' . _HTML( $Value // '' ) . '" />'
        . '<input type="text" class="DynamicFieldReference DynamicFieldText W100pc" id="Autocomplete_' . _HTML($ID) . '" name="Autocomplete_' . _HTML($ID)
        . '" title="' . _HTML($Label) . '" value="' . _HTML($VisibleValue) . '" data-dynamic-field="' . _HTML($Field) . '" />';
}

sub _RiskAssessmentFieldConfigs {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my %Config;

    FIELD:
    for my $Field ( @{ $Param{Fields} || [] } ) {
        next FIELD if !$Field;
        next FIELD if $Config{$Field};

        my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
            Name => $Field,
        );

        next FIELD if !IsHashRefWithData($DynamicFieldConfig);
        next FIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

        $Config{$Field} = $DynamicFieldConfig;
    }

    return \%Config;
}

sub _RiskAssessmentFieldNameRewrite {
    my ( $Self, %Param ) = @_;

    my $HTML = $Param{HTML} || '';
    my $From = 'DynamicField_' . $Param{Field};
    my $To   = 'RA_' . $Param{Index} . '_' . $Param{Field};

    $HTML =~ s{\Q$From\E}{$To}g;
    $HTML =~ s{class="([^"]*?)\bModernize\b([^"]*?)"}{'class="' . _RiskAssessmentNormalizeClass( "$1 $2" ) . '"'}eg;

    return $HTML;
}

sub _RiskAssessmentNormalizeClass {
    my ($Class) = @_;

    $Class //= '';
    $Class =~ s{\s+}{ }g;
    $Class =~ s{\A\s+|\s+\z}{}g;

    return $Class;
}

sub _RiskAssessmentOptions {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => $Param{Field},
    );

    return {} if !IsHashRefWithData($DynamicFieldConfig);

    if ( $Param{Type} eq 'Dropdown' ) {
        return $DynamicFieldConfig->{Config}->{PossibleValues} || {};
    }

    my $Class = $DynamicFieldConfig->{Config}->{Class};
    return {} if !$Class;

    return $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => $Class,
        Valid => 1,
    ) || {};
}

sub _RiskAssessmentRowsGet {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my $DynamicFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZRM-RiskAssessment',
    );

    return if !IsHashRefWithData($DynamicFieldConfig);

    return $DynamicFieldBackendObject->ValueGet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
    );
}

sub _RiskAssessmentRowsFromParam {
    my ($Self) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
    my @Index       = $ParamObject->GetArray( Param => 'RA_RowIndex' );

    my @Columns = ( _RiskAssessmentColumns(), _RiskAssessmentTargetColumns() );
    my $Configs = $Self->_RiskAssessmentFieldConfigs(
        Fields => [ map { $_->{Field} } @Columns ],
    );
    my @Rows;

    INDEX:
    for my $Index (@Index) {
        next INDEX if !defined $Index || $Index eq '' || $Index !~ m{\A(?:\d+|__INDEX__)\z};

        my %Row;
        my $HasValue;
        for my $Column (@Columns) {
            my $Field = $Column->{Field};
            my $Param = "RA_${Index}_$Field";
            my @Value = $ParamObject->GetArray( Param => $Param );
            if ( !@Value ) {
                my $SingleValue = $ParamObject->GetParam( Param => $Param );
                @Value = defined $SingleValue ? ($SingleValue) : ();
            }
            @Value = grep { defined $_ } @Value;
            for my $Value (@Value) {
                $Value =~ s{\A\s+|\s+\z}{}g;
            }
            @Value = grep { $_ ne '' } @Value;
            my $Value = @Value > 1 ? \@Value : ( $Value[0] // '' );
            $HasValue ||= ref $Value eq 'ARRAY' ? @{$Value} : $Value ne '';

            if ( $Field eq 'ZRM-RiskTargetGO' || $Field eq 'ZRM-RiskTargetCI' ) {
                my @Values;
                my @RawValues = ref $Value eq 'ARRAY' ? @{$Value} : split m{\s*,\s*}, $Value;
                for my $Entry (@RawValues) {
                    $Entry =~ s{\A\s+|\s+\z}{}g;
                    push @Values, $Entry if $Entry ne '';
                }
                $Row{$Field} = $Self->_RiskAssessmentSetFieldValue(
                    Field  => $Field,
                    Config => $Configs->{$Field},
                    Value  => \@Values,
                );
            }
            else {
                $Row{$Field} = $Self->_RiskAssessmentSetFieldValue(
                    Field  => $Field,
                    Config => $Configs->{$Field},
                    Value  => $Value,
                );
            }
        }

        push @Rows, \%Row if $HasValue;
    }

    return \@Rows;
}

sub _RiskAssessmentSetFieldValue {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    my @Value = _RiskAssessmentFlattenValues($Value);

    @Value = grep { defined $_ && $_ ne '' } @Value;
    return if !@Value;

    my $FieldType = IsHashRefWithData( $Param{Config} ) ? ( $Param{Config}->{FieldType} || '' ) : '';
    if ( $FieldType =~ m{\A(?:GeneralCatalog|Queue|SLA|Type|WebService|ConfigItem|ConfigItemVersion|GovernanceObject|GovernanceObjectVersion|Reference)\z} ) {
        return ( $Param{Config}->{Config}->{MultiValue} || $Param{Config}->{Config}->{Multiselect} )
            ? \@Value
            : [ $Value[0] ];
    }

    return @Value > 1 ? \@Value : $Value[0];
}

sub _RiskAssessmentFlattenValues {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        my @Values;
        for my $Item ( @{$Value} ) {
            push @Values, _RiskAssessmentFlattenValues($Item);
        }
        return @Values;
    }

    return $Value;
}

sub _RiskAssessmentArticleBody {
    my ( $Self, %Param ) = @_;

    my @Columns = _RiskAssessmentColumns();
    my @Targets = _RiskAssessmentTargetColumns();

    my $Body = "** Note: This is a system-generated risk assessment evidence snapshot.\n\n";
    $Body .= "Risk assessment was submitted by customer user '$Self->{UserID}'.\n\n";

    my @Headers = map { $_->{Label} } @Columns;
    $Body .= join( ' | ', @Headers ) . "\n";
    $Body .= join( ' | ', map {'---'} @Headers ) . "\n";

    for my $Row ( @{ $Param{Rows} || [] } ) {
        $Body .= join(
            ' | ',
            map {
                my $Column = $_;
                _ArticleCell( $Self->_RiskAssessmentDisplayValue( Field => $Column->{Field}, Type => $Column->{Type}, Value => $Row->{ $Column->{Field} } ) )
            } @Columns
        ) . "\n";

        my @TargetText;
        for my $Target (@Targets) {
            my $Display = $Self->_RiskAssessmentDisplayValue(
                Field => $Target->{Field},
                Type  => $Target->{Type},
                Value => $Row->{ $Target->{Field} },
            );
            push @TargetText, "$Target->{Label}: $Display" if defined $Display && $Display ne '';
        }
        $Body .= 'Targets: ' . join( '; ', @TargetText ) . "\n" if @TargetText;
    }

    if ( $Param{Remarks} ) {
        $Body .= "\nRemarks:\n$Param{Remarks}";
    }

    return $Body;
}

sub _RiskAssessmentDisplayValue {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    if ( ref $Value eq 'ARRAY' ) {
        return join ', ', map { $Self->_RiskAssessmentDisplayValue( %Param, Value => $_ ) } @{$Value};
    }

    return '' if !defined $Value || $Value eq '';

    if ( $Param{Type} eq 'GeneralCatalog' ) {
        my $Item = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
            ItemID => $Value,
        );
        return $Item->{Name} if IsHashRefWithData($Item) && defined $Item->{Name};
    }

    if ( $Param{Type} eq 'Dropdown' ) {
        my $Options = $Self->_RiskAssessmentOptions(%Param);
        return $Options->{$Value} if defined $Options->{$Value};
    }

    if ( $Param{Type} eq 'GovernanceObject' ) {
        my $Object = eval { $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet( GovernanceObjectID => $Value, Silent => 1 ) };
        return $Object->{Name} if IsHashRefWithData($Object) && defined $Object->{Name};
        return $Object->{Number} if IsHashRefWithData($Object) && defined $Object->{Number};
    }

    if ( $Param{Type} eq 'ConfigItem' ) {
        my $Object = eval { $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet( ConfigItemID => $Value, Silent => 1 ) };
        return $Object->{Name} if IsHashRefWithData($Object) && defined $Object->{Name};
        return $Object->{Number} if IsHashRefWithData($Object) && defined $Object->{Number};
    }

    return $Value;
}

sub _RiskAssessmentEditValue {
    my ( $Self, %Param ) = @_;

    my $Value = $Param{Value};
    return '' if !defined $Value;
    return join ', ', @{$Value} if ref $Value eq 'ARRAY';
    return $Value;
}

sub _HTML {
    my ($Text) = @_;

    return '' if !defined $Text;
    $Text =~ s/&/&amp;/g;
    $Text =~ s/</&lt;/g;
    $Text =~ s/>/&gt;/g;
    $Text =~ s/"/&quot;/g;
    $Text =~ s/'/&#39;/g;
    return $Text;
}

sub _ArticleCell {
    my ($Text) = @_;

    return '' if !defined $Text;
    $Text =~ s/\r?\n/ /g;
    $Text =~ s/\|/\\|/g;
    $Text =~ s/\s+/ /g;
    $Text =~ s{\A\s+|\s+\z}{}g;
    return $Text;
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
