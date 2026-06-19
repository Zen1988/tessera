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
use Kernel::System::ProcessManagement::TransitionAction::ZTSMServiceLibrarian ();
use Kernel::System::ZTSMBlueBookRuntime ();
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
    my $SupportProfile             = $ParamObject->GetParam( Param => 'SupportProfile' ) || '';
    my $TargetServiceSupportMapID  = $ParamObject->GetParam( Param => 'TargetServiceSupportMapID' ) || '';
    my $TargetServiceID            = $ParamObject->GetParam( Param => 'TargetServiceID' ) || '';
    my $ZTicketOutcome = $ParamObject->GetParam( Param => 'ZTicketOutcome' );
    $ZTicketOutcome = '' if !defined $ZTicketOutcome;
    my $ZTicketResult  = $ParamObject->GetParam( Param => 'ZTicketResult' ) || '';

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

    if ( $Subaction eq 'RiskStatementDefaults' ) {
        return $Self->_RiskStatementDefaultsJSON(
            Ticket => \%Ticket,
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

        if (
            !$Self->_RequesterCancelOrchestrationChildrenClose(
                Ticket              => \%Ticket,
                CancelStateID       => $CancelStateID,
                Remarks             => $Remarks,
                CustomerPanelUserID => $CustomerPanelUserID,
            )
            )
        {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Ticket was cancelled, but one or more orchestration child tickets could not be cancelled.',
            );
        }

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    if ( lc( $Ticket{State} || '' ) eq 'follow-up' ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    if ( $RuntimeAction eq 'CreateExternalPartyRequest' ) {
        if (
            !$Self->_ExternalPartyRequestAllowed(
                Ticket => \%Ticket,
                Config => $Config,
            )
            )
        {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $NewTicketID = $Self->_ExternalPartyRequestApply(
            Ticket                    => \%Ticket,
            TargetServiceSupportMapID => $TargetServiceSupportMapID,
            TargetServiceID           => $TargetServiceID,
            Remarks                   => $Remarks,
            Config                    => $Config,
            CustomerPanelUserID       => $CustomerPanelUserID,
        );

        if ( !$NewTicketID ) {
            $Self->_ZTSMActionLog(
                Message => "Clone failed at top level. TicketID='$TicketID' TargetServiceSupportMapID='$TargetServiceSupportMapID' RuntimeAction='$RuntimeAction'.",
            );
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not create external party request.',
            );
        }

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
        ) || $Self->_TaskLikeTicket( Ticket => \%Ticket );

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

    if ( $RuntimeAction eq 'AddRequiredSupportProfile' ) {
        if (
            !$Self->_AddRequiredSupportProfileAllowed(
                Ticket => \%Ticket,
                Config => $Config,
            )
            )
        {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $NewTicketID = $Self->_AddRequiredSupportProfileApply(
            Ticket              => \%Ticket,
            SupportProfile      => $SupportProfile,
            Remarks             => $Remarks,
            Config              => $Config,
            CustomerPanelUserID => $CustomerPanelUserID,
        );

        if ( !$NewTicketID ) {
            $Self->_ZTSMActionLog(
                Message => "Amend failed at top level. TicketID='$TicketID' SupportProfile='$SupportProfile' RuntimeAction='$RuntimeAction'.",
            );
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not add required support profile.',
            );
        }

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    if ( $RuntimeAction eq 'FollowUp' ) {
        if (
            !$Self->_FollowUpAllowed(
                Ticket => \%Ticket,
                Config => $Config,
            )
            )
        {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $CreatedTicketIDs = $Self->_FollowUpApply(
            Ticket              => \%Ticket,
            Remarks             => $Remarks,
            Config              => $Config,
            CustomerPanelUserID => $CustomerPanelUserID,
        );

        if ( !IsArrayRefWithData($CreatedTicketIDs) ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not start follow-up.',
            );
        }

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    if ( $RuntimeAction eq 'CompleteVerification' ) {
        if ( ( $Ticket{Type} || '' ) ne 'Verification' ) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        if ( $ZTicketOutcome ne '0' && $ZTicketOutcome ne '-1' ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please select a valid verification result.',
            );
        }

        if ( !$ZTicketResult ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please enter verification details.',
            );
        }

        my @Attachments = $Self->_RuntimeUploadAttachments();
        if ( !@Attachments ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please attach the verification artifact.',
            );
        }

        my $StartedFollowUp;
        if ( $ZTicketOutcome eq '-1' && $Self->_FollowUpPurpleBookID( Ticket => \%Ticket ) ) {
            my $CreatedTicketIDs = $Self->_FollowUpApply(
                Ticket              => \%Ticket,
                Remarks             => $ZTicketResult,
                Config              => $Config,
                CustomerPanelUserID => $CustomerPanelUserID,
                Attachments         => \@Attachments,
                VerificationFailed  => 1,
            );
            $StartedFollowUp = IsArrayRefWithData($CreatedTicketIDs);
        }

        if ( !$StartedFollowUp ) {
            my $State = $ZTicketOutcome eq '0' ? 'closed successful' : 'closed unsuccessful';

            for my $Field (
                [ 'ZTicket-Outcome', $ZTicketOutcome ],
                [ 'ZTicket-Result',  $ZTicketResult ],
                )
            {
                if (
                    !$Self->_TicketDynamicFieldSet(
                        FieldName => $Field->[0],
                        TicketID  => $TicketID,
                        Value     => $Field->[1],
                        UserID    => $CustomerPanelUserID,
                    )
                    )
                {
                    return $LayoutObject->CustomerErrorScreen(
                        Message => 'Could not update verification result.',
                    );
                }
            }

            my $StateSet = $TicketObject->TicketStateSet(
                State    => $State,
                TicketID => $TicketID,
                UserID   => $CustomerPanelUserID,
            );

            if ( !$StateSet ) {
                return $LayoutObject->CustomerErrorScreen(
                    Message => 'Could not update verification state.',
                );
            }

            $TicketObject->TicketLockSet(
                TicketID => $TicketID,
                Lock     => 'unlock',
                UserID   => $CustomerPanelUserID,
            );

            my $Label = $ZTicketOutcome eq '0' ? 'Successful' : 'Failed';
            my $Body = "** Note: This is a system-generated verification message.\n\n"
                . "Verification was submitted by customer user '$Self->{UserID}'.\n\n"
                . "Result:\n$Label\n\n"
                . "Details:\n$ZTicketResult";

            $Self->_RuntimeArticleCreate(
                TicketID            => $TicketID,
                RuntimeAction       => $RuntimeAction,
                Label               => 'Complete Verification',
                Subject             => 'Verification submitted',
                Body                => $Body,
                Config              => $Config,
                CustomerPanelUserID => $CustomerPanelUserID,
                Attachments         => \@Attachments,
            );

            $Self->_ChapterDirectorRun(
                TicketID            => $TicketID,
                TicketObject        => $TicketObject,
                CustomerPanelUserID => $CustomerPanelUserID,
            );
        }

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
    }

    if ( $RuntimeAction eq 'CompleteTask' ) {
        if ( ( $Ticket{Type} || '' ) ne 'Task' ) {
            return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
        }

        my $ZTicketOutcomeRaw = $ZTicketOutcome;
        $ZTicketOutcome = $Self->_TaskOutcomeValue( Outcome => $ZTicketOutcome );

        if ( !$ZTicketResult ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please enter task completion details.',
            );
        }

        my $TaskState = $Self->_TaskOutcomeState(
            Outcome => $ZTicketOutcome,
        );

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "ZTSM CompleteTask outcome debug: TicketID=$TicketID; CustomerUser='$Self->{UserID}'; RawZTicketOutcome='"
                . _LogValue($ZTicketOutcomeRaw)
                . "'; NormalizedZTicketOutcome='"
                . _LogValue($ZTicketOutcome)
                . "'; TaskState='"
                . _LogValue($TaskState)
                . "'.",
        );

        if ( !$TaskState ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please select a valid task outcome.',
            );
        }

        if (
            !$Self->_TicketDynamicFieldSet(
                FieldName => 'ZTicket-Outcome',
                TicketID  => $TicketID,
                Value     => $ZTicketOutcome,
                UserID    => $CustomerPanelUserID,
            )
            )
        {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update task outcome.',
            );
        }

        if (
            !$Self->_TicketDynamicFieldSet(
                FieldName => 'ZTicket-Result',
                TicketID  => $TicketID,
                Value     => $ZTicketResult,
                UserID    => $CustomerPanelUserID,
            )
            )
        {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update task result.',
            );
        }

        my $StateSet = $TicketObject->TicketStateSet(
            State    => $TaskState,
            TicketID => $TicketID,
            UserID   => $CustomerPanelUserID,
        );

        if ( !$StateSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update task state.',
            );
        }

        $TicketObject->TicketLockSet(
            TicketID => $TicketID,
            Lock     => 'unlock',
            UserID   => $CustomerPanelUserID,
        );

        my @Attachments = $Self->_RuntimeUploadAttachments();
        my $OutcomeLabel = $Self->_TaskOutcomeLabel(
            Outcome => $ZTicketOutcome,
        );

        my $Body = "** Note: This is a system-generated task completion message.\n\n"
            . "Task outcome was submitted by customer user '$Self->{UserID}'.\n\n"
            . "Outcome:\n"
            . ( $OutcomeLabel || $ZTicketOutcome )
            . "\n\n"
            . "Details:\n"
            . $ZTicketResult;

        $Self->_RuntimeArticleCreate(
            TicketID            => $TicketID,
            RuntimeAction       => $RuntimeAction,
            Label               => 'Complete',
            Subject             => 'Task completion submitted',
            Body                => $Body,
            Config              => $Config,
            CustomerPanelUserID => $CustomerPanelUserID,
            Attachments         => \@Attachments,
        );

        my $ParentTicketID = _NormalizeValue( $Ticket{'DynamicField_ZTicket-Parent'} );
        if ($ParentTicketID) {
            my $ParentBody = "** Note: This is a system-generated task completion message from a child execution ticket.\n\n"
                . "Completed Child Ticket:\n"
                . $Self->_TicketSummary( Ticket => \%Ticket )
                . "\n\n"
                . "Outcome:\n"
                . ( $OutcomeLabel || $ZTicketOutcome )
                . "\n\n"
                . "Details:\n"
                . $ZTicketResult;

            $Self->_RuntimeArticleCreate(
                TicketID            => $ParentTicketID,
                RuntimeAction       => $RuntimeAction,
                Label               => 'Complete',
                Subject             => 'Child task completion submitted',
                Body                => $ParentBody,
                Config              => $Config,
                CustomerPanelUserID => $CustomerPanelUserID,
                Attachments         => \@Attachments,
            );
        }

        $Self->_ChapterDirectorRun(
            TicketID            => $TicketID,
            TicketObject        => $TicketObject,
            CustomerPanelUserID => $CustomerPanelUserID,
        );

        return $LayoutObject->Redirect(
            OP => "Action=CustomerTicketZoom;TicketID=$TicketID",
        );
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
        if ( $Subaction eq 'RiskAssessmentInline' ) {
            my $HTML = $Self->_RiskAssessmentWorkspaceInlineHTML(
                Ticket   => \%Ticket,
                Config   => $Config,
                TicketID => $TicketID,
            );

            return $LayoutObject->Attachment(
                ContentType => 'text/html; charset=utf-8',
                Content     => $HTML,
                Type        => 'inline',
                NoCache     => 1,
            );
        }

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

        if ( !$Self->_RiskAssessmentRowsValidate( Rows => $Rows ) ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Please enter a risk plan when residual risk is lower than inherent risk.',
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

        my $RiskRollupSet = $Self->_RiskAssessmentRollupApply(
            Ticket              => \%Ticket,
            Rows                => $Rows,
            CustomerPanelUserID => $CustomerPanelUserID,
        );

        if ( !$RiskRollupSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update ticket risk summary.',
            );
        }

        my $RemarksSet = $Self->_RiskAssessmentRemarksApply(
            Ticket              => \%Ticket,
            Remarks             => $Remarks,
            CustomerPanelUserID => $CustomerPanelUserID,
        );

        if ( !$RemarksSet ) {
            return $LayoutObject->CustomerErrorScreen(
                Message => 'Could not update risk assessment remarks.',
            );
        }

        $ActionConfig->{RiskAssessmentRows} = $Rows;
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

    if ( IsArrayRefWithData( $ActionConfig->{RiskAssessmentRows} ) ) {
        $Self->_RiskAssessmentArticlesCreate(
            TicketID             => $TicketID,
            Rows                 => $ActionConfig->{RiskAssessmentRows},
            Remarks              => $Remarks,
            Config               => $Config,
            CustomerPanelUserID  => $CustomerPanelUserID,
        );
    }
    else {
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
    }

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

sub _PlainTextValue {
    my ($Value) = @_;

    $Value = _NormalizeValue($Value);
    return if !defined $Value;

    return $Value if $Value !~ m{<[^>]+>}s;

    if ( $Value =~ m{<body[^>]*>(.*?)</body>}is ) {
        $Value = $1;
    }

    $Value =~ s{<script\b[^>]*>.*?</script>}{}gis;
    $Value =~ s{<style\b[^>]*>.*?</style>}{}gis;
    $Value =~ s{<br\s*/?>}{\n}gi;
    $Value =~ s{</(?:p|div|li|tr|h[1-6])>}{\n}gi;
    $Value =~ s{<[^>]+>}{}g;

    my %Entity = (
        amp  => '&',
        lt   => '<',
        gt   => '>',
        quot => '"',
        apos => q{'},
        nbsp => ' ',
    );
    $Value =~ s{&([A-Za-z]+);}{ exists $Entity{lc $1} ? $Entity{lc $1} : ' ' }eg;
    $Value =~ s{&#(\d+);}{ chr($1) }eg;
    $Value =~ s{&#x([0-9A-Fa-f]+);}{ chr(hex($1)) }eg;
    $Value =~ s{\r\n?}{\n}g;
    $Value =~ s{[ \t]+}{ }g;
    $Value =~ s{[ \t]*\n[ \t]*}{\n}g;
    $Value =~ s{\n{3,}}{\n\n}g;
    $Value =~ s{\A\s+|\s+\z}{}g;

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

sub _TaskLikeTicket {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    return 1 if ( $Ticket->{Type} || '' ) eq 'Task';
    return 1 if ( $Ticket->{Title} || '' ) =~ m{\ATask\s+-\s+}i;

    return;
}

sub _RequesterCancelAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);

    # Orchestration child tickets carry ZTicket-Parent. Only the story root can be requester-cancelled.
    return if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $CustomerAccess = $TicketObject->TicketCustomerPermission(
        Type     => 'ro',
        TicketID => $Ticket->{TicketID},
        UserID   => $Self->{UserID},
        LogNo    => 1,
    );

    return if !$CustomerAccess;

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

sub _ExternalPartyRequestAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';

    my $ParentTicketID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );

    if ($ParentTicketID) {
        my $Owner = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Owner'} );
        return 1 if defined $Owner && $Owner ne '' && lc $Owner eq lc $Self->{UserID};
        return;
    }

    return 1
        if $Ticket->{CustomerUserID}
        && lc $Ticket->{CustomerUserID} eq lc $Self->{UserID};

    return;
}

sub _ExternalPartyRequestApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    if ( !IsHashRefWithData($Ticket) ) {
        $Self->_ZTSMActionLog( Message => 'Clone failed: missing ticket context.' );
        return;
    }

    $Self->_ZTSMActionLog(
        Message => "Clone started. SourceTicket='$Ticket->{TicketID}' TargetServiceSupportMapID='" . ( _NormalizeValue( $Param{TargetServiceSupportMapID} ) || '' ) . "'.",
    );

    my $RootTicket = $Self->_ExternalPartyRootTicket(
        Ticket => $Ticket,
        UserID => $Param{CustomerPanelUserID},
    );
    if ( !IsHashRefWithData($RootTicket) ) {
        $Self->_ZTSMActionLog(
            Message => "Clone failed: root ticket could not be resolved from source ticket '$Ticket->{TicketID}'."
        );
        return;
    }

    my $TargetServiceSupportMapID = _NormalizeValue( $Param{TargetServiceSupportMapID} );
    if ( !$TargetServiceSupportMapID ) {
        $Self->_ZTSMActionLog( Message => 'Clone failed: missing TargetServiceSupportMapID.' );
        return;
    }

    my $ServiceSupportMap = $Self->_ServiceSupportMapGet(
        ServiceSupportMapID => $TargetServiceSupportMapID,
        UserID              => $Param{CustomerPanelUserID},
    );
    if ( !IsHashRefWithData($ServiceSupportMap) ) {
        $Self->_ZTSMActionLog( Message => "Clone failed: ServiceSupportMap '$TargetServiceSupportMapID' not found." );
        return;
    }

    my $TargetServiceID = $Self->_ServiceIDResolve(
        Service => _NormalizeValue(
            $ServiceSupportMap->{'DynamicField_ZTSMServiceSupportMap-Service'}
        )
    );
    if ( !$TargetServiceID ) {
        $Self->_ZTSMActionLog(
            Message => 'Clone failed: selected ServiceSupportMap has no resolvable service.'
        );
        return;
    }
    if ( $RootTicket->{ServiceID} && $TargetServiceID ne $RootTicket->{ServiceID} ) {
        $Self->_ZTSMActionLog(
            Message => "Clone failed: ServiceSupportMap service '$TargetServiceID' does not match root ticket service '$RootTicket->{ServiceID}'."
        );
        return;
    }

    my $NewTicketID = $Self->_ExternalPartyRootTicketCreate(
        RootTicket              => $RootTicket,
        TargetServiceID         => $TargetServiceID,
        TargetServiceSupportMap => $ServiceSupportMap,
        CustomerPanelUserID     => $Param{CustomerPanelUserID},
    );
    if ( !$NewTicketID ) {
        $Self->_ZTSMActionLog( Message => 'Clone failed: root ticket creation returned no TicketID.' );
        return;
    }

    if ( !$Self->_TicketDynamicFieldsCopy(
        SourceTicketID => $RootTicket->{TicketID},
        TargetTicketID => $NewTicketID,
        UserID         => $Param{CustomerPanelUserID},
        SkipFields     => $Self->_ExternalPartyCloneSkipFields(),
    ) ) {
        $Self->_ZTSMActionLog(
            Message => "Clone warning: one or more optional dynamic fields could not be copied to ticket $NewTicketID."
        );
    }

    if ( !$Self->_ServiceSupportMapTicketApply(
        TicketID             => $NewTicketID,
        SourceTicketID       => $Ticket->{TicketID},
        ServiceSupportMap    => $ServiceSupportMap,
        TargetServiceID      => $TargetServiceID,
        CustomerPanelUserID  => $Param{CustomerPanelUserID},
    ) ) {
        $Self->_ZTSMActionLog(
            Message => "Clone failed: could not apply ServiceSupportMap fields to new ticket '$NewTicketID'."
        );
        return;
    }

    my %NewTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $NewTicketID,
        DynamicFields => 0,
        UserID        => $Param{CustomerPanelUserID} || 1,
        Silent        => 1,
    );

    my $TargetServiceName = $Self->_ServiceName(
        ServiceID => $TargetServiceID,
    ) || $TargetServiceID;
    my $TargetServiceSupportMapName = $ServiceSupportMap->{Name} || $TargetServiceSupportMapID;
    my $SourceTicketSummary = $Self->_TicketSummary(Ticket => $Ticket);
    my $RootTicketSummary   = $Self->_TicketSummary(Ticket => $RootTicket);
    my $NewTicketSummary    = $Self->_TicketSummary(
        Ticket => %NewTicket ? \%NewTicket : {
            TicketID => $NewTicketID,
            Title    => '',
        },
    );

    my $Body = "** Note: This is a system-generated runtime clone request message.\n\n"
        . "A separate governance request was cloned by customer user '$Self->{UserID}'.\n\n"
        . "Source Ticket:\n"
        . $SourceTicketSummary
        . "\n\n"
        . "Duplicated Parent Ticket:\n"
        . $RootTicketSummary
        . "\n\n"
        . "New Request Ticket:\n$NewTicketSummary\n\n"
        . "Target ServiceSupportMap:\n$TargetServiceSupportMapName\n\n"
        . "Target Service:\n$TargetServiceName\n\n"
        . "Ticket type and request evidence were copied from the parent request.\n\n"
        . "StateBook and approval governance were written from the selected ServiceSupportMap.";

    $Self->_RuntimeArticleCreate(
        TicketID            => $Ticket->{TicketID},
        RuntimeAction       => 'CreateExternalPartyRequest',
        Label               => 'Clone',
        Remarks             => $Param{Remarks},
        Subject             => 'Request cloned',
        Body                => $Body,
        Config              => $Param{Config},
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );

    $Self->_RuntimeArticleCreate(
        TicketID            => $NewTicketID,
        RuntimeAction       => 'CreateExternalPartyRequest',
        Label               => 'Clone',
        Subject             => 'Request cloned',
        Body                => "** Note: This is a system-generated runtime clone request message.\n\n"
            . "This request was cloned from parent ticket:\n"
            . $RootTicketSummary
            . "\n\n"
            . "Created By:\n$Self->{UserID}\n\n"
            . "Target ServiceSupportMap:\n$TargetServiceSupportMapName\n\n"
            . "Target Service:\n$TargetServiceName",
        Config              => $Param{Config},
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );

    return $NewTicketID;
}

sub _TicketSummary {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return 'N/A' if !IsHashRefWithData($Ticket);

    my $TicketNumber = $Ticket->{TicketNumber} || '';
    my $TicketID     = $Ticket->{TicketID}     || '';
    my $Type         = $Ticket->{Type}         || 'Ticket';
    my $Title        = $Ticket->{Title}        || '';

    my $Label = $TicketNumber ? "Ticket#$TicketNumber" : "TicketID#$TicketID";
    $Label .= " (ID $TicketID)" if $TicketNumber && $TicketID;
    $Label .= " - $Type" if $Type;
    $Label .= ": $Title" if $Title;

    return $Label;
}

sub _ServiceSupportMapGet {
    my ( $Self, %Param ) = @_;

    my $ServiceSupportMapID = _NormalizeValue( $Param{ServiceSupportMapID} );
    return if !$ServiceSupportMapID;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @ServiceSupportMapIDs;

    if ( $ServiceSupportMapID =~ m{\A\d+\z} ) {
        @ServiceSupportMapIDs = ($ServiceSupportMapID);
    }
    else {
        $ServiceSupportMapID =~ s{\A [^:]+: \s*}{}xms;
        $ServiceSupportMapID =~ s{\s+\z}{};

        SEARCH:
        for my $Search ( $ServiceSupportMapID, "%$ServiceSupportMapID%" ) {
            @ServiceSupportMapIDs = $GovernanceObjectObject->GovernanceObjectSearch(
                Classes => ['ServiceSupportMap'],
                Name    => $Search,
                Result  => 'ARRAY',
                Limit   => 1,
                UserID  => $Param{UserID} || 1,
            );
            last SEARCH if @ServiceSupportMapIDs;
        }
    }

    SERVICESUPPORTMAPID:
    for my $ResolvedServiceSupportMapID (@ServiceSupportMapIDs) {
        my $ServiceSupportMap = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $ResolvedServiceSupportMapID,
            DynamicFields      => 1,
            UserID             => $Param{UserID} || 1,
            Silent             => 1,
        );
        next SERVICESUPPORTMAPID if !IsHashRefWithData($ServiceSupportMap);
        next SERVICESUPPORTMAPID if ( $ServiceSupportMap->{Class} || '' ) ne 'ServiceSupportMap';

        return $ServiceSupportMap;
    }

    return;
}

sub _ServiceSupportMapTicketApply {
    my ( $Self, %Param ) = @_;

    return if !$Param{TicketID};
    return if !$Param{TargetServiceID};
    return if !IsHashRefWithData( $Param{ServiceSupportMap} );

    my $UserID = $Param{CustomerPanelUserID} || 1;

    my $ServiceSet = $Kernel::OM->Get('Kernel::System::Ticket')->TicketServiceSet(
        TicketID  => $Param{TicketID},
        ServiceID => $Param{TargetServiceID},
        UserID    => $UserID,
    );
    return if !$ServiceSet;

    my $Map = $Param{ServiceSupportMap};
    my $StateBookID = $Self->_GovernanceObjectIDResolve(
        Value   => $Map->{'DynamicField_ZTSMServiceSupportMap-StateBook'},
        Classes => ['StateBook'],
    );
    my $ApprovalModelID = $Self->_GovernanceObjectIDResolve(
        Value   => $Map->{'DynamicField_ZTSMServiceSupportMap-ApprovalModel'},
        Classes => ['Approval Model'],
    );

    my %FieldMap = (
        'ZTicket-Parent'        => $Param{SourceTicketID},
        'ZTicket-StateBook'     => $StateBookID,
        'ZTicket-ApprovalModel' => $ApprovalModelID,
    );

    FIELD:
    for my $FieldName ( sort keys %FieldMap ) {
        next FIELD if !defined $FieldMap{$FieldName};
        next FIELD if $FieldMap{$FieldName} eq '';

        if ( !$Self->_TicketDynamicFieldSet(
            FieldName => $FieldName,
            TicketID  => $Param{TicketID},
            Value     => $FieldMap{$FieldName},
            UserID    => $UserID,
        ) ) {
            $Self->_ZTSMActionLog(
                Message => "Clone failed: could not set dynamic field '$FieldName' on ticket '$Param{TicketID}' with value '$FieldMap{$FieldName}'."
            );
            return;
        }
    }

    return 1;
}

sub _ExternalPartyCloneSkipFields {
    my ($Self) = @_;

    return {
        map { $_ => 1 } qw(
            ZTicket-Application
            ZTicket-ApprovalModel
            ZTicket-BlueBook
            ZTicket-BlueLevel
            ZTicket-Chapter
            ZTicket-Duration
            ZTicket-Env
            ZTicket-HoldState
            ZTicket-Location
            ZTicket-Mandatory
            ZTicket-Outcome
            ZTicket-Owner
            ZTicket-OwnerGroup
            ZTicket-OwnerWeightage
            ZTicket-Parent
            ZTicket-Profile
            ZTicket-RequiredWeightage
            ZTicket-Result
            ZTicket-Role
            ZTicket-StateBook
            ZTicket-Strict
        )
    };
}

sub _ExternalPartyRootTicket {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $ParentTicketID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    return $Ticket if !$ParentTicketID;

    my %ParentTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $ParentTicketID,
        DynamicFields => 1,
        UserID        => $Param{UserID} || 1,
        Silent        => 1,
    );

    return \%ParentTicket if %ParentTicket;
    return;
}

sub _ExternalPartyRootTicketCreate {
    my ( $Self, %Param ) = @_;

    my $RootTicket = $Param{RootTicket};
    return if !IsHashRefWithData($RootTicket);

    my $ServiceSupportMap = $Param{TargetServiceSupportMap};
    my $ServiceSupportMapName = IsHashRefWithData($ServiceSupportMap)
        ? $ServiceSupportMap->{Name}
        : '';

    my $ParentType = $RootTicket->{Type} || 'Ticket';
    my $ParentID   = $RootTicket->{TicketNumber} || $RootTicket->{TicketID} || '';
    my $ParentTitle = $RootTicket->{Title} || '';

    my $Title = "$ParentType:$ParentID: $ParentTitle";
    $Title .= " - $ServiceSupportMapName" if $ServiceSupportMapName;

    my $CustomerUserID = $Param{CustomerPanelUserID} || $RootTicket->{CustomerUserID};
    my %CustomerUser = $CustomerUserID
        ? $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $CustomerUserID,
        )
        : ();

    return $Kernel::OM->Get('Kernel::System::Ticket')->TicketCreate(
        TN            => undef,
        Title         => $Title,
        Queue         => $RootTicket->{Queue},
        Lock          => 'unlock',
        Priority      => $RootTicket->{Priority},
        State         => 'new',
        CustomerID    => $CustomerUser{UserCustomerID} || $RootTicket->{CustomerID},
        CustomerUser  => $CustomerUserID || $RootTicket->{CustomerUserID},
        OwnerID       => 1,
        UserID        => $Param{CustomerPanelUserID} || 1,
        Type          => $RootTicket->{Type},
        ServiceID     => $Param{TargetServiceID} || $RootTicket->{ServiceID},
        SLAID         => $RootTicket->{SLAID},
        ResponsibleID => 1,
    );
}

sub _TicketDynamicFieldsCopy {
    my ( $Self, %Param ) = @_;

    return if !$Param{SourceTicketID};
    return if !$Param{TargetTicketID};
    return if !$Param{UserID};

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ConfigObject              = $Kernel::OM->Get('Kernel::Config');

    my %SkipField = map { $_ => 1 } grep { $_ } (
        $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID'),
        $ConfigObject->Get('Process::DynamicFieldProcessManagementActivityID'),
    );
    if ( IsHashRefWithData( $Param{SkipFields} ) ) {
        $SkipField{$_} = 1 for keys %{ $Param{SkipFields} };
    }

    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Ticket'],
    ) || [];

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicFieldList} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);
        next DYNAMICFIELD if !$DynamicFieldConfig->{Name};
        next DYNAMICFIELD if $SkipField{ $DynamicFieldConfig->{Name} };
        next DYNAMICFIELD if $DynamicFieldConfig->{Name} =~ m{\A(?:ZState|ZBlue)-};

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
            UserID             => $Param{UserID},
        );

        if ( !$Success ) {
            $Self->_ZTSMActionLog(
                Message => "Clone warning: could not copy dynamic field '$DynamicFieldConfig->{Name}' from ticket '$Param{SourceTicketID}' to '$Param{TargetTicketID}'."
            );
            next DYNAMICFIELD;
        }
    }

    return 1;
}

sub _ServiceIDResolve {
    my ( $Self, %Param ) = @_;

    my $Service = _NormalizeValue( $Param{Service} );
    return if !defined $Service || $Service eq '';
    return $Service if $Service =~ m{\A\d+\z};

    if ( $Service =~ s{\AService:\s*}{}i ) {
        $Service =~ s{\s+\z}{};
    }

    return if $Service eq '';

    return $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
        Name => $Service,
    );
}

sub _GovernanceObjectIDResolve {
    my ( $Self, %Param ) = @_;

    my $Value = _NormalizeValue( $Param{Value} );
    return if !defined $Value || $Value eq '';
    return $Value if $Value =~ m{\A\d+\z};

    $Value =~ s{\A [^:]+: \s*}{}xms;
    $Value =~ s{\s+\z}{};
    return if $Value eq '';

    my %ClassFilter = ref $Param{Classes} eq 'ARRAY' && @{ $Param{Classes} }
        ? ( Classes => $Param{Classes} )
        : ();

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    SEARCH:
    for my $Search ( $Value, "%$Value%" ) {
        my @IDs = eval {
            $GovernanceObjectObject->GovernanceObjectSearch(
                %ClassFilter,
                Name   => $Search,
                Result => 'ARRAY',
                Limit  => 1,
            );
        };
        next SEARCH if !@IDs;
        return $IDs[0];
    }

    return;
}

sub _ServiceName {
    my ( $Self, %Param ) = @_;

    return if !$Param{ServiceID};

    my %Service = $Kernel::OM->Get('Kernel::System::Service')->ServiceGet(
        ServiceID => $Param{ServiceID},
        UserID    => 1,
    );

    return $Service{Name} if %Service && $Service{Name};
    return;
}

sub _AddRequiredSupportProfileAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';
    return if lc( $Ticket->{State} || '' ) eq 'follow-up';
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} );
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );

    my $AllowedTypes = $Config->{AddRequiredSupportProfileTypes} || [
        'Assessment',
        'Endorsement',
        'Approval',
    ];
    my %AllowedType = map { $_ => 1 } @{$AllowedTypes};

    return $AllowedType{ $Ticket->{Type} };
}

sub _FollowUpAllowed {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    my $Config = $Param{Config} || {};

    return if !IsHashRefWithData($Ticket);
    return if ( $Ticket->{StateType} || '' ) eq 'closed';
    return if lc( $Ticket->{State} || '' ) eq 'follow-up';
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} );
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );

    my $AllowedTypes = $Config->{FollowUpTypes} || [
        'Assessment',
        'Endorsement',
        'Approval',
        'Implementation',
        'Verification',
    ];
    my %AllowedType = map { $_ => 1 } @{$AllowedTypes};
    return if !$AllowedType{ $Ticket->{Type} || '' };

    return $Self->_FollowUpPurpleBookID( Ticket => $Ticket );
}

sub _FollowUpPurpleBookID {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $BlueBookID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
    my $BlueLevel  = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} );
    my $Chapter    = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );

    return if !$BlueBookID || !defined $BlueLevel || $BlueLevel eq '' || !$Chapter;

    my $BlueBook = Kernel::System::ZTSMBlueBookRuntime::BlueBookGet(
        BlueBookID => $BlueBookID,
    );
    my @Records = Kernel::System::ZTSMBlueBookRuntime::RecordsParse(
        BlueBook => $BlueBook,
    );

    RECORD:
    for my $Record (@Records) {
        next RECORD if !$Record || ref $Record ne 'HASH';
        next RECORD if !_BlueLevelMatch(
            BlueLevel => $BlueLevel,
            Record    => $Record,
        );
        next RECORD if !defined $Record->{Chapter} || $Record->{Chapter} ne $Chapter;
        next RECORD if $Record->{Type} && ( $Ticket->{Type} || '' ) && $Record->{Type} ne $Ticket->{Type};

        my $PurpleBookID = _NormalizeValue( $Record->{PurpleBook} );
        return $PurpleBookID if $PurpleBookID;
    }

    return;
}

sub _BlueLevelMatch {
    my (%Param) = @_;

    my $BlueLevel = _NormalizeValue( $Param{BlueLevel} );
    return if !defined $BlueLevel || $BlueLevel eq '';
    return if !$Param{Record} || ref $Param{Record} ne 'HASH';

    for my $RecordBlueLevel ( $Param{Record}->{BlueLevel}, $Param{Record}->{RawBlueLevel} ) {
        $RecordBlueLevel = _NormalizeValue($RecordBlueLevel);
        next if !defined $RecordBlueLevel || $RecordBlueLevel eq '';
        return 1 if $RecordBlueLevel eq $BlueLevel;
    }

    return;
}

sub _FollowUpApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $TicketID     = $Ticket->{TicketID};
    my $PurpleBookID = $Self->_FollowUpPurpleBookID( Ticket => $Ticket );
    return if !$TicketID || !$PurpleBookID;

    my $UserID       = $Param{CustomerPanelUserID} || 1;
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $BlueBook     = Kernel::System::ZTSMBlueBookRuntime::BlueBookGet(
        BlueBookID => $PurpleBookID,
    );
    my @Records = Kernel::System::ZTSMBlueBookRuntime::RecordsParse(
        BlueBook => $BlueBook,
    );
    return if !@Records;

    my $FirstBlueLevel = $Records[0]->{BlueLevel};
    return if !defined $FirstBlueLevel || $FirstBlueLevel eq '';

    my $StateSet = $TicketObject->TicketStateSet(
        State    => 'follow-up',
        TicketID => $TicketID,
        UserID   => $UserID,
    );
    return if !$StateSet;

    if ( $Param{VerificationFailed} && defined $Param{Remarks} && $Param{Remarks} ne '' ) {
        $Self->_TicketDynamicFieldSet(
            FieldName => 'ZTicket-Result',
            TicketID  => $TicketID,
            Value     => $Param{Remarks},
            UserID    => $UserID,
        );
    }

    my @CreatedTicketIDs = Kernel::System::ZTSMBlueBookRuntime::LevelSpawn(
        ParentTicket   => $Ticket,
        ParentTicketID => $TicketID,
        BlueBookID     => $PurpleBookID,
        BlueLevel      => $FirstBlueLevel,
        Records        => \@Records,
        ArticleParam   => {
            UserID => $UserID,
        },
        PreserveParentBlueLevel => 1,
        AllowRepeatClosed       => 1,
        UserID                  => $UserID,
    );

    return if !@CreatedTicketIDs;

    my @CreatedTicketSummaries;
    for my $CreatedTicketID (@CreatedTicketIDs) {
        my %CreatedTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $CreatedTicketID,
            DynamicFields => 0,
            UserID        => $UserID,
            Silent        => 1,
        );

        push @CreatedTicketSummaries, $Self->_TicketSummary(
            Ticket => %CreatedTicket ? \%CreatedTicket : {
                TicketID => $CreatedTicketID,
            },
        );
    }

    my $Body = "** Note: This is a system-generated follow-up orchestration message.\n\n"
        . "Follow-up was started by customer user '$Self->{UserID}'.\n\n"
        . "Original Child Ticket:\n"
        . $Self->_TicketSummary( Ticket => $Ticket )
        . "\n\n"
        . "PurpleBook:\n$PurpleBookID\n\n"
        . "Follow-up Tickets Created:\n"
        . join( "\n", @CreatedTicketSummaries );

    if ( $Param{VerificationFailed} ) {
        $Body .= "\n\nVerification Result:\nFailed";
    }

    $Self->_RuntimeArticleCreate(
        TicketID            => $TicketID,
        RuntimeAction       => 'FollowUp',
        Label               => 'Follow-up',
        Remarks             => $Param{Remarks},
        Subject             => 'Follow-up started',
        Body                => $Body,
        Config              => $Param{Config} || {},
        CustomerPanelUserID => $UserID,
        Attachments         => $Param{Attachments},
    );

    return \@CreatedTicketIDs;
}

sub _AddRequiredSupportProfileApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    if ( !IsHashRefWithData($Ticket) ) {
        $Self->_ZTSMActionLog( Message => 'Amend failed: missing ticket context.' );
        return;
    }

    my $SupportProfile = _NormalizeValue( $Param{SupportProfile} );
    $Self->_ZTSMActionLog(
        Message => "Amend started. SourceTicket='" . ( $Ticket->{TicketID} || '' ) . "' SupportProfile='" . ( defined $SupportProfile ? $SupportProfile : '' ) . "'.",
    ) if IsHashRefWithData($Ticket);
    if ( !defined $SupportProfile || $SupportProfile eq '' ) {
        $Self->_ZTSMActionLog(
            Message => "Amend failed: no SupportProfile submitted for ticket '$Ticket->{TicketID}'."
        );
        return;
    }

    my $SupportProfileObject = $Self->_SupportProfileGet(
        SupportProfile => $SupportProfile,
        UserID         => $Param{CustomerPanelUserID},
    );
    if ( !IsHashRefWithData($SupportProfileObject) ) {
        $Self->_ZTSMActionLog(
            Message => "Amend failed: submitted SupportProfile '$SupportProfile' could not be resolved."
        );
        return;
    }

    my $SupportProfileID = $SupportProfileObject->{GovernanceObjectID};
    if ( !$SupportProfileID ) {
        $Self->_ZTSMActionLog(
            Message => "Amend failed: resolved SupportProfile '$SupportProfile' has no GovernanceObjectID."
        );
        return;
    }

    my $ParentTicketID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    my $BlueBookID     = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
    my $BlueLevel      = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} );
    my $Chapter        = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );

    if ( !$ParentTicketID || !$BlueBookID || !defined $BlueLevel || $BlueLevel eq '' || !$Chapter ) {
        $Self->_ZTSMActionLog(
            Message => "Amend failed: missing execution context on ticket '$Ticket->{TicketID}' Parent='$ParentTicketID' BlueBook='$BlueBookID' BlueLevel='$BlueLevel' Chapter='$Chapter'."
        );
        return;
    }

    my $DuplicateTicketID = $Self->_AdditionalSupportProfileTicketID(
        ParentTicketID   => $ParentTicketID,
        BlueBookID       => $BlueBookID,
        BlueLevel        => $BlueLevel,
        Chapter          => $Chapter,
        Type             => $Ticket->{Type},
        SupportProfile   => $SupportProfileObject,
        UserID           => $Param{CustomerPanelUserID},
    );
    return $DuplicateTicketID if $DuplicateTicketID;

    my %ParentTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $ParentTicketID,
        DynamicFields => 1,
        UserID        => $Param{CustomerPanelUserID},
        Silent        => 1,
    );
    if ( !%ParentTicket ) {
        $Self->_ZTSMActionLog(
            Message => "Amend failed: parent ticket '$ParentTicketID' could not be loaded."
        );
        return;
    }

    my $NewTicketID = $Self->_RequiredSupportProfileTicketCreate(
        SourceTicket        => $Ticket,
        ParentTicket        => \%ParentTicket,
        ParentTicketID      => $ParentTicketID,
        SupportProfile      => $SupportProfileObject,
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );
    if ( !$NewTicketID ) {
        $Self->_ZTSMActionLog(
            Message => "Amend failed: child ticket create failed for SourceTicket='$Ticket->{TicketID}' Parent='$ParentTicketID' SupportProfileID='$SupportProfileID' SupportProfileName='" . ( $SupportProfileObject->{Name} || '' ) . "'."
        );
        return;
    }

    my $ProfileName = $SupportProfileObject->{Name} || $SupportProfileID;
    my %NewTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $NewTicketID,
        DynamicFields => 0,
        UserID        => $Param{CustomerPanelUserID},
        Silent        => 1,
    );
    my $ParentTicketSummary = $Self->_TicketSummary( Ticket => \%ParentTicket );
    my $NewTicketSummary    = $Self->_TicketSummary(
        Ticket => %NewTicket ? \%NewTicket : {
            TicketID => $NewTicketID,
        },
    );

    my $Body = "** Note: This is a system-generated runtime stakeholder update message.\n\n"
        . "A mandatory support profile was added by customer user '$Self->{UserID}'.\n\n"
        . "Support Profile:\n$ProfileName\n\n"
        . "Parent Ticket:\n$ParentTicketSummary\n\n"
        . "BlueBook:\n$BlueBookID\n\n"
        . "BlueLevel:\n$BlueLevel\n\n"
        . "Chapter:\n$Chapter\n\n"
        . "Created Child Ticket:\n$NewTicketSummary\n\n"
        . "No lifecycle transition has occurred.";

    $Self->_RuntimeArticleCreate(
        TicketID            => $Ticket->{TicketID},
        RuntimeAction       => 'AddRequiredSupportProfile',
        Label               => 'Amend',
        Remarks             => $Param{Remarks},
        Subject             => 'Required support profile added',
        Body                => $Body,
        Config              => $Param{Config},
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );

    $Self->_RuntimeArticleCreate(
        TicketID            => $NewTicketID,
        RuntimeAction       => 'AddRequiredSupportProfile',
        Label               => 'Amend',
        Subject             => 'Mandatory execution task created',
        Body                => "** Note: This is a system-generated runtime stakeholder update message.\n\n"
            . "This mandatory execution task was added during the active gate.\n\n"
            . "Added By:\n$Self->{UserID}\n\n"
            . "Support Profile:\n$ProfileName\n\n"
            . "Parent Ticket:\n$ParentTicketSummary\n\n"
            . "No lifecycle transition has occurred.",
        Config              => $Param{Config},
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );

    return $NewTicketID;
}

sub _SupportProfileGet {
    my ( $Self, %Param ) = @_;

    my $SupportProfile = _NormalizeValue( $Param{SupportProfile} );
    return if !defined $SupportProfile || $SupportProfile eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @SupportProfileIDs;

    if ( $SupportProfile =~ m{\A\d+\z} ) {
        @SupportProfileIDs = ($SupportProfile);
    }
    else {
        $SupportProfile =~ s{\A [^:]+: \s*}{}xms;
        $SupportProfile =~ s{\s+\z}{};

        SEARCH:
        for my $Search ( $SupportProfile, "%$SupportProfile%" ) {
            @SupportProfileIDs = $GovernanceObjectObject->GovernanceObjectSearch(
                Classes => ['SupportProfile'],
                Name    => $Search,
                Result  => 'ARRAY',
                Limit   => 1,
                UserID  => $Param{UserID} || 1,
            );
            last SEARCH if @SupportProfileIDs;
        }
    }

    for my $SupportProfileID (@SupportProfileIDs) {
        my $SupportProfileObject = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $SupportProfileID,
            DynamicFields      => 1,
            UserID             => $Param{UserID} || 1,
            Silent             => 1,
        );
        next if !IsHashRefWithData($SupportProfileObject);
        next if ( $SupportProfileObject->{Class} || '' ) ne 'SupportProfile';

        return $SupportProfileObject;
    }

    return;
}

sub _AdditionalSupportProfileTicketID {
    my ( $Self, %Param ) = @_;

    return if !$Param{ParentTicketID};
    return if !$Param{BlueBookID};
    return if !defined $Param{BlueLevel};
    return if $Param{BlueLevel} eq '';
    return if !$Param{Chapter};
    return if !$Param{Type};
    return if !$Param{SupportProfile};

    my @SupportProfileReferences = $Self->_SupportProfileReferences(
        SupportProfile => $Param{SupportProfile},
    );
    return if !@SupportProfileReferences;

    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result => 'ARRAY',
        Limit  => 1000,
        UserID => $Param{UserID} || 1,
        'DynamicField_ZTicket-Parent' => {
            Equals => $Param{ParentTicketID},
        },
        'DynamicField_ZTicket-BlueBook' => {
            Equals => $Param{BlueBookID},
        },
        'DynamicField_ZTicket-BlueLevel' => {
            Equals => $Param{BlueLevel},
        },
        'DynamicField_ZTicket-Chapter' => {
            Equals => $Param{Chapter},
        },
        Type => $Param{Type},
    );

    my %SupportProfileReference = map { $_ => 1 } @SupportProfileReferences;
    for my $TicketID (@TicketIDs) {
        my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $Param{UserID} || 1,
            Silent        => 1,
        );
        next if !%Ticket;

        my $OwnerGroup = _NormalizeValue( $Ticket{'DynamicField_ZTicket-OwnerGroup'} );
        next if !defined $OwnerGroup || $OwnerGroup eq '';
        return $TicketID if $SupportProfileReference{$OwnerGroup};
    }

    return;
}

sub _RequiredSupportProfileTicketCreate {
    my ( $Self, %Param ) = @_;

    my $SourceTicket   = $Param{SourceTicket};
    my $ParentTicket   = $Param{ParentTicket};
    my $SupportProfile = $Param{SupportProfile};
    return if !IsHashRefWithData($SourceTicket);
    return if !IsHashRefWithData($ParentTicket);
    return if !IsHashRefWithData($SupportProfile);

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my $ParentRef   = $ParentTicket->{TicketNumber} || $Param{ParentTicketID};
    my $ProfileName = $SupportProfile->{Name} || $SupportProfile->{GovernanceObjectID};
    my $ChildTitle  = join ' - ', grep { defined $_ && $_ ne '' } (
        $SourceTicket->{Type},
        ( $ParentTicket->{Type} || 'ParentTicket' ) . "#$ParentRef",
        _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-Chapter'} ),
        $ProfileName,
    );

    my $NewTicketID = $TicketObject->TicketCreate(
        TN            => undef,
        Title         => $ChildTitle,
        Queue         => $SourceTicket->{Queue} || $ParentTicket->{Queue},
        Lock          => 'unlock',
        Priority      => $SourceTicket->{Priority} || $ParentTicket->{Priority},
        State         => 'new',
        CustomerUser  => $ParentTicket->{CustomerUserID} || $SourceTicket->{CustomerUserID},
        OwnerID       => 1,
        UserID        => $Param{CustomerPanelUserID} || 1,
        Type          => $SourceTicket->{Type},
        ServiceID     => $ParentTicket->{ServiceID} || $SourceTicket->{ServiceID},
        SLAID         => $ParentTicket->{SLAID} || $SourceTicket->{SLAID},
        ResponsibleID => 1,
    );

    return if !$NewTicketID;

    Kernel::System::ZTSMBlueBookRuntime::ChildProcessSet(
        TicketID => $NewTicketID,
        UserID   => $Param{CustomerPanelUserID} || 1,
    );

    my %FieldMap = (
        'ZTicket-Parent'            => $Param{ParentTicketID},
        'ZTicket-BlueBook'          => _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-BlueBook'} ),
        'ZTicket-BlueLevel'         => _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-BlueLevel'} ),
        'ZTicket-Chapter'           => _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-Chapter'} ),
        'ZTicket-Application'       => _NormalizeValue( $ParentTicket->{'DynamicField_ZTicket-Application'} )
            || _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-Application'} ),
        'ZTicket-Profile'           => $SupportProfile->{GovernanceObjectID},
        'ZTicket-OwnerGroup'        => $SupportProfile->{GovernanceObjectID},
        'ZTicket-Role'              => _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-Role'} ),
        'ZTicket-Mandatory'         => 1,
        'ZTicket-Strict'            => _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-Strict'} ),
        'ZTicket-Duration'          => _NormalizeValue( $SourceTicket->{'DynamicField_ZTicket-Duration'} ),
        'ZTicket-RequiredWeightage' => 1,
    );

    FIELD:
    for my $FieldName ( sort keys %FieldMap ) {
        next FIELD if !defined $FieldMap{$FieldName};
        next FIELD if $FieldMap{$FieldName} eq '';

        my $Success = $Self->_TicketDynamicFieldSet(
            FieldName => $FieldName,
            TicketID  => $NewTicketID,
            Value     => $FieldMap{$FieldName},
            UserID    => $Param{CustomerPanelUserID} || 1,
        );
        if ( !$Success ) {
            $Self->_ZTSMActionLog(
                Message => "Amend failed: could not set dynamic field '$FieldName' on ticket '$NewTicketID' with value '$FieldMap{$FieldName}'."
            );
            return;
        }
    }

    my $TemplateID = Kernel::System::ZTSMBlueBookRuntime::TemplateIDForTicket(
        Ticket => $SourceTicket,
    );
    if ($TemplateID) {
        Kernel::System::ZTSMBlueBookRuntime::ChildTemplateApply(
            TicketID     => $NewTicketID,
            TemplateID   => $TemplateID,
            ArticleParam => {
                UserID => $Param{CustomerPanelUserID} || 1,
            },
            UserID => $Param{CustomerPanelUserID} || 1,
        );
    }

    return $NewTicketID;
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

sub _RequesterOrchestrationChildTicketIDs {
    my ( $Self, %Param ) = @_;

    return if !$Param{ParentTicketID};

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Seen;
    my @Queue  = ( $Param{ParentTicketID} );
    my @Result;

    PARENT:
    while (@Queue) {
        my $ParentTicketID = shift @Queue;

        CHILD:
        for my $ChildTicketID ( $Self->_RequesterChildTicketIDs( ParentTicketID => $ParentTicketID ) ) {
            next CHILD if !$ChildTicketID;
            next CHILD if $Seen{$ChildTicketID}++;

            my %ChildTicket = $TicketObject->TicketGet(
                TicketID      => $ChildTicketID,
                DynamicFields => 1,
                UserID        => 1,
                Silent        => 1,
            );

            next CHILD if !IsHashRefWithData( \%ChildTicket );
            next CHILD if !$Self->_RequesterOrchestrationTicket( Ticket => \%ChildTicket );

            push @Result, $ChildTicketID;
            push @Queue,  $ChildTicketID;
        }
    }

    return @Result;
}

sub _RequesterOrchestrationTicket {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if !_NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );

    return 1
        if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} )
        || _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} )
        || _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );

    return;
}

sub _RequesterCancelOrchestrationChildrenClose {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if !$Param{CancelStateID};

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ParentSummary = $Self->_TicketSummary( Ticket => $Ticket );

    CHILD:
    for my $ChildTicketID (
        $Self->_RequesterOrchestrationChildTicketIDs(
            ParentTicketID => $Ticket->{TicketID},
        )
        )
    {
        my %ChildTicket = $TicketObject->TicketGet(
            TicketID      => $ChildTicketID,
            DynamicFields => 1,
            UserID        => $Param{CustomerPanelUserID} || 1,
            Silent        => 1,
        );

        next CHILD if !IsHashRefWithData( \%ChildTicket );
        next CHILD if ( $ChildTicket{StateType} || '' ) eq 'closed';

        return if !$TicketObject->TicketStateSet(
            StateID  => $Param{CancelStateID},
            TicketID => $ChildTicketID,
            UserID   => $Param{CustomerPanelUserID} || 1,
        );

        $TicketObject->TicketLockSet(
            TicketID => $ChildTicketID,
            Lock     => 'unlock',
            UserID   => $Param{CustomerPanelUserID} || 1,
        );

        return if !$Self->_RequesterExecutionArticleCreate(
            TicketID            => $ChildTicketID,
            Subject             => 'Requester cancelled parent ticket',
            Body                => "Requester has cancelled the parent ticket.\n\n"
                . "This orchestration ticket has been closed because execution is no longer required.\n\n"
                . "Parent Ticket: $ParentSummary",
            Remarks             => $Param{Remarks},
            CustomerPanelUserID => $Param{CustomerPanelUserID},
        );
    }

    return 1;
}

sub _RequesterExecutionArticleCreate {
    my ( $Self, %Param ) = @_;

    my $Body = $Param{Body} || '';
    if ( $Param{Remarks} ) {
        $Body .= "\n\nRemarks:\n" . ( _PlainTextValue( $Param{Remarks} ) || '' );
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

    if ( !IsHashRefWithData($DynamicFieldConfig) ) {
        $Self->_ZTSMActionLog( Message => "Dynamic field set failed: '$Param{FieldName}' does not exist." );
        return;
    }
    if ( $DynamicFieldConfig->{ObjectType} ne 'Ticket' ) {
        $Self->_ZTSMActionLog( Message => "Dynamic field set failed: '$Param{FieldName}' is not a Ticket field." );
        return;
    }

    my $Success = $DynamicFieldBackendObject->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID},
    );

    if ( !$Success ) {
        my $Value = defined $Param{Value} ? $Param{Value} : '';
        $Self->_ZTSMActionLog(
            Message => "Dynamic field set failed: '$Param{FieldName}' TicketID='$Param{TicketID}' Value='$Value'."
        );
    }

    return $Success;
}

sub _ZTSMActionLog {
    my ( $Self, %Param ) = @_;

    return if !$Param{Message};

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => $Param{Priority} || 'error',
        Message  => 'CustomerTicketZTSMAction: ' . $Param{Message},
    );

    return 1;
}

sub _RuntimeUploadAttachments {
    my ( $Self, %Param ) = @_;

    my %UploadStuff = $Kernel::OM->Get('Kernel::System::Web::Request')->GetUploadAll(
        Param => 'file_upload',
    );

    return if !%UploadStuff;
    return \%UploadStuff;
}

sub _TaskOutcomeState {
    my ( $Self, %Param ) = @_;

    my $Outcome = _NormalizeValue( $Param{Outcome} );
    return if !defined $Outcome || $Outcome eq '';

    return 'closed successful'   if $Outcome eq '0';
    return 'closed no action'    if $Outcome eq '1';
    return 'closed successful'   if $Outcome eq '2';
    return 'closed unsuccessful' if $Outcome eq '-1';
    return 'closed rollback'     if $Outcome eq '-2';

    return;
}

sub _TaskOutcomeLabel {
    my ( $Self, %Param ) = @_;

    my $Outcome = _NormalizeValue( $Param{Outcome} );
    return if !defined $Outcome || $Outcome eq '';

    my %Fallback = (
        0    => 'Successful',
        1    => 'No Action',
        2    => 'Partial Success',
        '-1' => 'Failed',
        '-2' => 'Rollback',
    );

    return $Fallback{$Outcome} || $Outcome;
}

sub _TaskOutcomeValue {
    my ( $Self, %Param ) = @_;

    my $Outcome = _NormalizeValue( $Param{Outcome} );
    return if !defined $Outcome || $Outcome eq '';

    my %ValueForLabel = (
        Successful        => '0',
        'No Action'       => '1',
        'Partial Success' => '2',
        Failed            => '-1',
        Rollback          => '-2',
    );

    return $ValueForLabel{$Outcome} if defined $ValueForLabel{$Outcome};
    return $Outcome;
}

sub _LogValue {
    my ($Value) = @_;

    return '<undef>' if !defined $Value;
    return '<empty>' if $Value eq '';

    $Value =~ s{\r}{\\r}g;
    $Value =~ s{\n}{\\n}g;

    return $Value;
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
        next SUPPORTPROFILE if $SupportProfile !~ m{\A\d+\z};

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

    my $SupportProfile = $Param{SupportProfile};
    if ( IsHashRefWithData($SupportProfile) ) {
        my %Reference;
        $Reference{ $SupportProfile->{GovernanceObjectID} } = 1 if $SupportProfile->{GovernanceObjectID};
        $Reference{ $SupportProfile->{LastVersionID} }      = 1 if $SupportProfile->{LastVersionID};
        $Reference{ $SupportProfile->{Name} }               = 1 if $SupportProfile->{Name};

        return sort keys %Reference;
    }

    $SupportProfile = _NormalizeValue($SupportProfile);

    return if !defined $SupportProfile;
    return if $SupportProfile eq '';

    my %Reference;

    if ( $SupportProfile =~ m{\A\d+\z} ) {
        $Reference{$SupportProfile} = 1;

        my $SupportProfileObject = eval {
            $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
                GovernanceObjectID => $SupportProfile,
                DynamicFields      => 0,
                Silent             => 1,
            );
        };

        if ( IsHashRefWithData($SupportProfileObject) ) {
            $Reference{ $SupportProfileObject->{LastVersionID} } = 1 if $SupportProfileObject->{LastVersionID};
            $Reference{ $SupportProfileObject->{Name} }          = 1 if $SupportProfileObject->{Name};
        }
    }
    else {
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
        $Body .= "\n\nRemarks:\n" . ( _PlainTextValue( $Param{Remarks} ) || '' );
    }

    $Body = ZTSMArticleBodyConfigItemReferencesExpand(
        Body => $Body,
    );

    my $ArticleID = $ArticleBackendObject->ArticleCreate(
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

    return if !$ArticleID;

    if ( IsArrayRefWithData( $Param{Attachments} ) ) {
        ATTACHMENT:
        for my $Attachment ( @{ $Param{Attachments} } ) {
            next ATTACHMENT if !IsHashRefWithData($Attachment);
            next ATTACHMENT if !$Attachment->{Filename};

            $ArticleBackendObject->ArticleWriteAttachment(
                %{$Attachment},
                ArticleID => $ArticleID,
                UserID    => $Param{CustomerPanelUserID},
            );
        }
    }

    return $ArticleID;
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
        { Field => 'ZRM-RiskOwner',               Label => 'Risk Owner',                           Type => 'Text' },
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

    my %Data = $Self->_RiskAssessmentWorkspaceData(
        Ticket   => $Param{Ticket},
        TicketID => $Param{TicketID},
    );

    my $Output = $LayoutObject->CustomerHeader( Value => $Param{Ticket}->{TicketNumber} );
    $Output .= $LayoutObject->CustomerNavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerTicketZTSMRiskAssessment',
        Data         => \%Data,
    );
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

sub _RiskAssessmentWorkspaceInlineHTML {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my %Data = $Self->_RiskAssessmentWorkspaceData(
        Ticket   => $Param{Ticket},
        TicketID => $Param{TicketID},
        Inline   => 1,
    );

    return $LayoutObject->Output(
        TemplateFile => 'CustomerTicketZTSMRiskAssessment',
        Data         => \%Data,
    );
}

sub _RiskAssessmentWorkspaceData {
    my ( $Self, %Param ) = @_;

    my $HTML = $Self->_RiskAssessmentWorkspaceHTML(
        Ticket => $Param{Ticket},
    );

    return (
        TicketID      => $Param{TicketID},
        TicketNumber  => $Param{Ticket}->{TicketNumber},
        TicketTitle   => $Param{Ticket}->{Title},
        WorkspaceHTML => $HTML,
        Inline        => $Param{Inline} ? 1 : 0,
    );
}

sub _RiskAssessmentWorkspaceHTML {
    my ( $Self, %Param ) = @_;

    $Self->_RiskAssessmentTemplateHydrateIfEmpty(
        Ticket => $Param{Ticket},
    );

    my $Rows = $Self->_RiskAssessmentRowsGet(
        TicketID => $Param{Ticket}->{TicketID},
    );

    $Rows = [ {} ] if !IsArrayRefWithData($Rows);
    if ( @{$Rows} > 50 ) {
        $Rows = [ @{$Rows}[ 0 .. 49 ] ];
    }

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

sub _RiskAssessmentTemplateHydrateIfEmpty {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if !$Ticket->{TicketID};

    my $Rows = $Self->_RiskAssessmentRowsGet(
        TicketID => $Ticket->{TicketID},
    );
    return 1 if IsArrayRefWithData($Rows);

    my $TemplateID = Kernel::System::ZTSMBlueBookRuntime::TemplateIDForTicket(
        Ticket => $Ticket,
    );
    if ( !$TemplateID ) {
        $Self->_ZTSMActionLog(
            Message  => "Assessment template hydration skipped: no template found for ticket '$Ticket->{TicketID}'.",
        );
        return;
    }

    my $Applied = Kernel::System::ZTSMBlueBookRuntime::ChildTemplateApply(
        TicketID     => $Ticket->{TicketID},
        TemplateID   => $TemplateID,
        ArticleParam => {
            UserID => 1,
        },
        UserID => 1,
    );

    if ( !$Applied ) {
        $Self->_ZTSMActionLog(
            Message => "Assessment template hydration failed for ticket '$Ticket->{TicketID}' using template '$TemplateID'.",
        );
        return;
    }

    return 1;
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
        return '' if !$Definition->{Field};
        return '' if $Field eq 'ZRM-RiskOwner' && !IsHashRefWithData( $Param{Configs}->{$Field} );
        return '' if $Definition->{Type} ne 'Text' && $Definition->{Type} ne 'TextArea' && !IsHashRefWithData( $Param{Configs}->{$Field} );

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
    $HTML .= '<div class="ZTSMRiskAssessmentRowBody ZTSMRiskAssessmentRowLayout">';
    $HTML .= '<div class="ZTSMRiskAssessmentBand ZTSMRiskAssessmentBandStatement">'
        . $FieldHTML->('ZRM-RiskStatement')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentStack ZTSMRiskAssessmentStackMeta">'
        . $FieldHTML->('ZRM-ImpactCategory')
        . $FieldHTML->('ZRM-RiskCategory')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentBand ZTSMRiskAssessmentBandDetail">'
        . $FieldHTML->('ZRM-RiskDetail')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentEquation ZTSMRiskAssessmentEquationInherent">'
        . $FieldHTML->('ZRM-InherentLikelihood')
        . '<span class="ZTSMRiskAssessmentOperator">x</span>'
        . $FieldHTML->('ZRM-InherentImpact')
        . '<span class="ZTSMRiskAssessmentOperator">=</span>'
        . $FieldHTML->('ZRM-InherentCalculatedRisk')
        . '<div class="ZTSMRiskAssessmentLevel ZTSMRiskAssessmentLevelInherent" data-score-field="ZRM-InherentCalculatedRisk">N/A</div>'
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentStack ZTSMRiskAssessmentStackAction">'
        . $FieldHTML->('ZRM-RiskAction')
        . $FieldHTML->('ZRM-RiskOwner')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentBand ZTSMRiskAssessmentBandPlan">'
        . $FieldHTML->('ZRM-RiskPlan')
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentEquation ZTSMRiskAssessmentEquationResidual">'
        . $FieldHTML->('ZRM-ResidualLikelihood')
        . '<span class="ZTSMRiskAssessmentOperator">x</span>'
        . $FieldHTML->('ZRM-ResidualImpact')
        . '<span class="ZTSMRiskAssessmentOperator">=</span>'
        . $FieldHTML->('ZRM-ResidualCalculatedRisk')
        . '<div class="ZTSMRiskAssessmentLevel ZTSMRiskAssessmentLevelResidual" data-score-field="ZRM-ResidualCalculatedRisk">N/A</div>'
        . '</div>';
    $HTML .= '<div class="ZTSMRiskAssessmentTargets">'
        . $FieldHTML->('ZRM-RiskTargetCI')
        . $FieldHTML->('ZRM-RiskTargetGO')
        . '</div>';
    $HTML .= '</div>';
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

    if ( IsHashRefWithData( $Param{Config} ) && $Param{Type} =~ m{\A(?:GeneralCatalog|Dropdown)\z} ) {
        return $Self->_RiskAssessmentSelectInputHTML(%Param);
    }

    if ( IsHashRefWithData( $Param{Config} ) && $Param{Type} ne 'TextArea' ) {
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

sub _RiskAssessmentSelectInputHTML {
    my ( $Self, %Param ) = @_;

    my $Field = $Param{Field};
    my $Index = $Param{Index};
    my $Name  = 'RA_' . $Index . '_' . $Field;
    my $Value = $Param{Value};

    my %Selected = map { $_ => 1 } _RiskAssessmentFlattenValues($Value);
    my $Options  = $Self->_RiskAssessmentOptionsFromConfig(%Param);
    my $Multiple = $Param{Config}->{Config}->{Multiselect} || $Param{Config}->{Config}->{MultiValue};

    my $HTML = '<select class="ZTSMRiskAssessmentSelect" name="' . _HTML($Name) . '"';
    $HTML .= ' multiple="multiple" size="3"' if $Multiple;
    $HTML .= '>';
    $HTML .= '<option value=""></option>' if !$Multiple;

    for my $Key ( $Self->_RiskAssessmentOptionKeysSorted( Field => $Field, Options => $Options ) ) {
        my $Label = $Options->{$Key};
        my $IsSelected = $Selected{$Key} || $Selected{$Label};
        $HTML .= '<option value="' . _HTML($Key) . '"';
        $HTML .= ' selected="selected"' if $IsSelected;
        $HTML .= '>' . _HTML($Label) . '</option>';
    }

    $HTML .= '</select>';

    return $HTML;
}

sub _RiskAssessmentOptionKeysSorted {
    my ( $Self, %Param ) = @_;

    my $Field   = $Param{Field} || '';
    my $Options = $Param{Options} || {};

    my %NumericScoreField = map { $_ => 1 } qw(
        ZRM-InherentLikelihood
        ZRM-InherentImpact
        ZRM-ResidualLikelihood
        ZRM-ResidualImpact
    );

    if ( $NumericScoreField{$Field} ) {
        return sort {
            _RiskAssessmentScoreSortValue( $Options->{$a}, $a ) <=> _RiskAssessmentScoreSortValue( $Options->{$b}, $b )
                || ( $Options->{$a} || $a ) cmp ( $Options->{$b} || $b )
                || $a cmp $b
        } keys %{$Options};
    }

    return sort { ( $Options->{$a} || $a ) cmp ( $Options->{$b} || $b ) || $a cmp $b } keys %{$Options};
}

sub _RiskAssessmentScoreSortValue {
    my ( $Label, $Key ) = @_;

    for my $Candidate ( $Label, $Key ) {
        next if !defined $Candidate;

        if ( $Candidate =~ m{\A\s*(-?\d+(?:\.\d+)?)\s*\z} ) {
            return 0 + $1;
        }
    }

    return 999_999;
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

    return $Self->_RiskAssessmentOptionsFromConfig(
        %Param,
        Config => $DynamicFieldConfig,
    );
}

sub _RiskAssessmentOptionsFromConfig {
    my ( $Self, %Param ) = @_;

    my $DynamicFieldConfig = $Param{Config};
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

            if ( $Field eq 'ZRM-RiskTargetCI' || $Field eq 'ZRM-RiskTargetGO' ) {
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
        return \@Value if $Param{Config}->{Config}->{Multiselect};
        return $Param{Config}->{Config}->{MultiValue} ? \@Value : [ $Value[0] ];
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

sub _RiskAssessmentArticlesCreate {
    my ( $Self, %Param ) = @_;

    return 1 if !IsArrayRefWithData( $Param{Rows} );

    my $Config = $Param{Config} || {};
    return 1 if !( $Config->{Article} // 1 );

    ROW:
    for my $Index ( 0 .. $#{ $Param{Rows} } ) {
        my $Row = $Param{Rows}->[$Index];
        next ROW if !IsHashRefWithData($Row);

        $Self->_RuntimeArticleCreate(
            TicketID            => $Param{TicketID},
            Body                => $Self->_RiskAssessmentArticleBody(
                Row   => $Row,
                Index => $Index + 1,
            ),
            Subject             => 'Risk assessment result ' . ( $Index + 1 ),
            Config              => {
                %{$Config},
                ContentType => 'text/html; charset=utf-8',
            },
            CustomerPanelUserID => $Param{CustomerPanelUserID},
        );
    }

    $Self->_RuntimeArticleCreate(
        TicketID            => $Param{TicketID},
        Body                => $Self->_RiskAssessmentSummaryArticleBody(%Param),
        Subject             => 'Risk assessment summary',
        Config              => {
            %{$Config},
            ContentType => 'text/html; charset=utf-8',
        },
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );

    return 1;
}

sub _RiskAssessmentArticleBody {
    my ( $Self, %Param ) = @_;

    my $Row = $Param{Row};
    return '' if !IsHashRefWithData($Row);

    my %Value;
    for my $Column ( _RiskAssessmentColumns(), _RiskAssessmentTargetColumns() ) {
        $Value{ $Column->{Field} } = _PlainTextValue(
            $Self->_RiskAssessmentDisplayValue(
            Field => $Column->{Field},
            Type  => $Column->{Type},
            Value => $Row->{ $Column->{Field} },
            )
        );
    }

    my $InherentLevel = _RiskAssessmentRiskLevel( $Value{'ZRM-InherentCalculatedRisk'} );
    my $ResidualLevel = _RiskAssessmentRiskLevel( $Value{'ZRM-ResidualCalculatedRisk'} );

    return ''
        . '<div style="font-family:Arial,Helvetica,sans-serif;color:#0b1340;">'
        . '<p><strong>Note:</strong> This is a system-generated risk assessment evidence snapshot.</p>'
        . '<p>Risk assessment result ' . _HTML( $Param{Index} || 1 ) . ' was submitted by customer user <strong>' . _HTML( $Self->{UserID} ) . '</strong>.</p>'
        . '<table style="width:100%;border-collapse:collapse;table-layout:fixed;">'
        . '<colgroup>'
        . '<col style="width:8.333%;" /><col style="width:8.333%;" /><col style="width:8.333%;" /><col style="width:8.333%;" />'
        . '<col style="width:8.333%;" /><col style="width:8.333%;" /><col style="width:8.333%;" /><col style="width:8.333%;" />'
        . '<col style="width:8.333%;" /><col style="width:8.333%;" /><col style="width:8.333%;" /><col style="width:8.333%;" />'
        . '</colgroup>'
        . '<tr>'
        . _RiskAssessmentArticleCell( 'Risk Statement', $Value{'ZRM-RiskStatement'}, 12, 'text-align:center;font-size:18px;' )
        . '</tr>'
        . _RiskAssessmentArticleGap()
        . '<tr>'
        . _RiskAssessmentArticleCell( 'Impact Category', $Value{'ZRM-ImpactCategory'}, 4 )
        . _RiskAssessmentArticleCell( 'Risk Detail', $Value{'ZRM-RiskDetail'}, 8 )
        . '</tr>'
        . _RiskAssessmentArticleGap()
        . '<tr>'
        . _RiskAssessmentArticleCell( 'Risk Category', $Value{'ZRM-RiskCategory'}, 4 )
        . _RiskAssessmentArticleEmpty(8)
        . '</tr>'
        . _RiskAssessmentArticleGap()
        . '<tr>'
        . _RiskAssessmentArticleScoreCell( 'Inherent - Likelihood', $Value{'ZRM-InherentLikelihood'}, 3 )
        . _RiskAssessmentArticleOperatorCell('x')
        . _RiskAssessmentArticleScoreCell( 'Inherent - Impact', $Value{'ZRM-InherentImpact'}, 3 )
        . _RiskAssessmentArticleOperatorCell('=')
        . _RiskAssessmentArticleScoreCell( 'Inherent - Risk Score', $Value{'ZRM-InherentCalculatedRisk'}, 2 )
        . _RiskAssessmentArticleLevelCell( $InherentLevel, 2 )
        . '</tr>'
        . _RiskAssessmentArticleGap()
        . '<tr>'
        . _RiskAssessmentArticleCell( 'Risk Action', $Value{'ZRM-RiskAction'}, 4 )
        . _RiskAssessmentArticleCell( 'Risk Plan', $Value{'ZRM-RiskPlan'}, 8 )
        . '</tr>'
        . _RiskAssessmentArticleGap()
        . '<tr>'
        . _RiskAssessmentArticleCell( 'Risk Owner', $Value{'ZRM-RiskOwner'}, 4 )
        . _RiskAssessmentArticleEmpty(8)
        . '</tr>'
        . _RiskAssessmentArticleGap()
        . '<tr>'
        . _RiskAssessmentArticleScoreCell( 'Residual - Likelihood', $Value{'ZRM-ResidualLikelihood'}, 3 )
        . _RiskAssessmentArticleOperatorCell('x')
        . _RiskAssessmentArticleScoreCell( 'Residual - Impact', $Value{'ZRM-ResidualImpact'}, 3 )
        . _RiskAssessmentArticleOperatorCell('=')
        . _RiskAssessmentArticleScoreCell( 'Residual - Risk Score', $Value{'ZRM-ResidualCalculatedRisk'}, 2 )
        . _RiskAssessmentArticleLevelCell( $ResidualLevel, 2 )
        . '</tr>'
        . _RiskAssessmentArticleGap()
        . '<tr>'
        . _RiskAssessmentArticleCell( 'RiskTarget - CI', $Value{'ZRM-RiskTargetCI'}, 6 )
        . _RiskAssessmentArticleCell( 'RiskTarget - GO', $Value{'ZRM-RiskTargetGO'}, 6 )
        . '</tr>'
        . '</table>'
        . '</div>';
}

sub _RiskAssessmentSummaryArticleBody {
    my ( $Self, %Param ) = @_;

    my @Summary = $Self->_RiskAssessmentCategorySummary(
        Rows => $Param{Rows},
    );

    my $Body = ''
        . '<div style="font-family:Arial,Helvetica,sans-serif;color:#0b1340;">'
        . '<p><strong>Note:</strong> This is a system-generated risk assessment decision summary.</p>'
        . '<p>Use this summary as guidance for endorsement and approval decision making.</p>'
        . '<table style="width:100%;border-collapse:collapse;">'
        . '<tr>'
        . '<th style="text-align:left;border:1px solid #d9deea;padding:8px;background:#eef2f7;">Category</th>'
        . '<th style="text-align:left;border:1px solid #d9deea;padding:8px;background:#eef2f7;">Maximum Residual Risk</th>'
        . '</tr>';

    for my $Item (@Summary) {
        my $Level = _RiskAssessmentRiskLevel( $Item->{Risk} );
        $Body .= '<tr>'
            . '<td style="border:1px solid #d9deea;padding:8px;">' . _HTML( $Item->{Label} ) . '</td>'
            . '<td style="border:1px solid #d9deea;padding:8px;">'
            . '<span style="display:inline-block;border-radius:999px;padding:5px 12px;font-weight:bold;background:' . $Level->{Color}
            . ';color:' . $Level->{TextColor} . ';">' . _HTML( $Level->{Summary} ) . '</span>'
            . '</td>'
            . '</tr>';
    }

    $Body .= '</table>';

    if ( defined $Param{Remarks} && $Param{Remarks} ne '' ) {
        my $RemarksHTML = _HTML( _PlainTextValue( $Param{Remarks} ) || '' );
        $RemarksHTML =~ s{\r?\n}{<br />}g;

        $Body .= '<div style="margin-top:16px;"><strong>Remarks:</strong><br />'
            . $RemarksHTML
            . '</div>';
    }

    $Body .= '</div>';

    return $Body;
}

sub _RiskAssessmentArticleCell {
    my ( $Label, $Value, $Colspan, $HeaderStyle ) = @_;

    return '<td colspan="' . _HTML( $Colspan || 1 ) . '" style="vertical-align:top;padding:0;">'
        . '<div style="border:2px solid #063247;background:#176a85;color:#fff;padding:8px;text-align:center;font-size:15px;font-weight:bold;' . _HTML( $HeaderStyle || '' ) . '">' . _HTML($Label) . '</div>'
        . '<div style="border:1px solid #d9deea;border-top:0;min-height:34px;padding:8px;background:#fff;word-wrap:break-word;">' . _HTML( $Value || '' ) . '</div>'
        . '</td>';
}

sub _RiskAssessmentArticleScoreCell {
    my ( $Label, $Value, $Colspan ) = @_;

    return _RiskAssessmentArticleCell( $Label, $Value, $Colspan || 2 );
}

sub _RiskAssessmentArticleOperatorCell {
    my ($Operator) = @_;

    return '<td style="text-align:center;font-size:22px;font-weight:bold;vertical-align:middle;padding:0 6px;">' . _HTML($Operator) . '</td>';
}

sub _RiskAssessmentArticleLevelCell {
    my ( $Level, $Colspan ) = @_;

    return '<td colspan="' . _HTML( $Colspan || 2 ) . '" style="vertical-align:middle;padding:0 0 0 10px;">'
        . '<div style="border-radius:999px;padding:8px 10px;text-align:center;font-weight:bold;background:' . $Level->{Color}
        . ';color:' . $Level->{TextColor} . ';">' . _HTML( $Level->{Summary} ) . '</div>'
        . '</td>';
}

sub _RiskAssessmentArticleEmpty {
    my ($Colspan) = @_;

    return '<td colspan="' . _HTML( $Colspan || 1 ) . '" style="padding:0;"></td>';
}

sub _RiskAssessmentArticleGap {

    return '<tr><td colspan="12" style="height:10px;font-size:1px;line-height:1px;">&nbsp;</td></tr>';
}

sub _RiskAssessmentRowsValidate {
    my ( $Self, %Param ) = @_;

    ROW:
    for my $Row ( @{ $Param{Rows} || [] } ) {
        next ROW if !IsHashRefWithData($Row);

        my $InherentRisk = _NormalizeValue( $Row->{'ZRM-InherentCalculatedRisk'} );
        my $ResidualRisk = _NormalizeValue( $Row->{'ZRM-ResidualCalculatedRisk'} );
        next ROW if !defined $InherentRisk || $InherentRisk eq '';
        next ROW if !defined $ResidualRisk || $ResidualRisk eq '';

        next ROW if _RiskAssessmentRiskRank($ResidualRisk) >= _RiskAssessmentRiskRank($InherentRisk);

        my $RiskPlan = _NormalizeValue( $Row->{'ZRM-RiskPlan'} );
        return if !defined $RiskPlan || $RiskPlan eq '';
    }

    return 1;
}

sub _RiskStatementDefaultsJSON {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $RiskStatementID = $ParamObject->GetParam( Param => 'RiskStatementID' ) || '';
    my $RiskStatementLabel = $ParamObject->GetParam( Param => 'RiskStatementLabel' ) || '';
    my %Data = (
        Success => 0,
        Fields  => {},
    );

    if ( !$RiskStatementID && $RiskStatementLabel ) {
        $RiskStatementID = $Self->_RiskStatementIDByLabel(
            Label => $RiskStatementLabel,
        ) || '';
    }

    if ( $RiskStatementID =~ m{\A\d+\z} ) {
        my $GovernanceObject = eval {
            $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
                GovernanceObjectID => $RiskStatementID,
                DynamicFields      => 1,
                Silent             => 1,
            );
        };

        if ( IsHashRefWithData($GovernanceObject) ) {
            $Data{RiskStatementID} = $RiskStatementID;

            my @DefaultFields = (
                { Source => 'ZRM-ImpactCategoryGO', Target => 'ZRM-ImpactCategory',     Type => 'GeneralCatalog' },
                { Source => 'ZRM-RiskCategoryGO',   Target => 'ZRM-RiskCategory',       Type => 'GeneralCatalog' },
                { Source => 'ZRM-BaseLikelihood',   Target => 'ZRM-InherentLikelihood', Type => 'GeneralCatalog' },
                { Source => 'ZRM-BaseImpact',       Target => 'ZRM-InherentImpact',     Type => 'GeneralCatalog' },
                { Source => 'ZRM-RiskDetail',       Target => 'ZRM-RiskDetail' },
            );

            FIELD:
            for my $Field (@DefaultFields) {
                my $Value = _RiskStatementObjectValue(
                    Object => $GovernanceObject,
                    Field  => $Field->{Source},
                );
                next FIELD if !defined $Value || $Value eq '';

                if ( ( $Field->{Type} || '' ) eq 'GeneralCatalog' ) {
                    $Value = _RiskStatementGeneralCatalogValueWithName($Value);
                }

                $Data{Fields}->{ $Field->{Target} } = $Value;
            }

            $Data{Success} = 1;
        }
    }

    my $JSON = $LayoutObject->JSONEncode( Data => \%Data );

    return $LayoutObject->Attachment(
        ContentType => 'application/json',
        Content     => $JSON,
        Type        => 'inline',
        NoCache     => 1,
    );
}

sub _RiskStatementIDByLabel {
    my ( $Self, %Param ) = @_;

    my $Label = $Param{Label} || '';
    $Label =~ s{\A\s+|\s+\z}{}g;
    return if !$Label;

    my @Candidates = ($Label);
    if ( $Label =~ m{\A.+?\s+-\s+(.+)\z} ) {
        push @Candidates, $1;
    }
    push @Candidates, map { "*$_*" } @Candidates;

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @ObjectIDs;
    CANDIDATE:
    for my $Candidate (@Candidates) {
        my @Found = eval {
            $GovernanceObjectObject->GovernanceObjectSearch(
                Name   => $Candidate,
                Limit  => 10,
                Silent => 1,
            );
        };
        next CANDIDATE if !@Found;
        @ObjectIDs = @Found;
        last CANDIDATE;
    }

    for my $ObjectID (@ObjectIDs) {
        my $Object = eval {
            $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $ObjectID,
                Silent             => 1,
            );
        };
        next if !IsHashRefWithData($Object);
        return $ObjectID if ( $Object->{Name} || '' ) eq $Label;
        return $ObjectID if ( $Object->{Number} || '' ) eq $Label;
        return $ObjectID if $Object->{Name} && $Label =~ m{\Q$Object->{Name}\E};
    }

    return $ObjectIDs[0] if @ObjectIDs;
    return;
}

sub _RiskStatementObjectValue {
    my (%Param) = @_;

    my $Object = $Param{Object};
    my $Field  = $Param{Field};

    return if !IsHashRefWithData($Object);
    return if !$Field;

    for my $Key ( 'DynamicField_' . $Field, $Field ) {
        return $Object->{$Key} if defined $Object->{$Key};
    }

    my $XMLData = $Object->{XMLData};
    return if ref $XMLData ne 'HASH';

    my $Value = $XMLData->{$Field};
    if ( ref $Value eq 'HASH' ) {
        return $Value->{Content} if defined $Value->{Content};
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Key}     if defined $Value->{Key};
    }

    if ( ref $Value eq 'ARRAY' ) {
        my @Values;
        for my $Item ( @{$Value} ) {
            if ( ref $Item eq 'HASH' ) {
                push @Values, $Item->{Content} if defined $Item->{Content};
                push @Values, $Item->{Value}   if defined $Item->{Value};
                push @Values, $Item->{Key}     if defined $Item->{Key};
                next;
            }
            push @Values, $Item if defined $Item;
        }
        return \@Values if @Values > 1;
        return $Values[0] if @Values;
    }

    return $Value if defined $Value;
    return;
}

sub _RiskStatementGeneralCatalogValueWithName {
    my ($Value) = @_;

    my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
    my @Expanded;
    my %Seen;

    VALUE:
    for my $ItemID (@Values) {
        next VALUE if !defined $ItemID || $ItemID eq '';

        for my $Candidate ($ItemID) {
            next if !defined $Candidate || $Candidate eq '' || $Seen{$Candidate}++;
            push @Expanded, $Candidate;
        }

        next VALUE if $ItemID !~ m{\A\d+\z};

        my $Item = eval {
            $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemGet(
                ItemID => $ItemID,
            );
        };
        next VALUE if !IsHashRefWithData($Item) || !defined $Item->{Name} || $Item->{Name} eq '';
        next VALUE if $Seen{ $Item->{Name} }++;

        push @Expanded, $Item->{Name};
    }

    return $Expanded[0] if @Expanded == 1;
    return \@Expanded if @Expanded;
    return;
}

sub _RiskAssessmentRollupApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if !IsArrayRefWithData( $Param{Rows} );
    return if !$Param{CustomerPanelUserID};

    my $RiskByField = $Self->_RiskAssessmentCategoryRiskMax(
        Rows => $Param{Rows},
    );

    return 1 if !IsHashRefWithData($RiskByField);

    return if !$Self->_RiskAssessmentTicketRiskMaxSet(
        Ticket              => $Ticket,
        RiskByField         => $RiskByField,
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );

    my $ParentTicketID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    return 1 if !$ParentTicketID;

    my %ParentTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $ParentTicketID,
        DynamicFields => 1,
        UserID        => $Param{CustomerPanelUserID},
        Silent        => 1,
    );

    return 1 if !IsHashRefWithData( \%ParentTicket );

    return $Self->_RiskAssessmentTicketRiskMaxSet(
        Ticket              => \%ParentTicket,
        RiskByField         => $RiskByField,
        CustomerPanelUserID => $Param{CustomerPanelUserID},
    );
}

sub _RiskAssessmentRemarksApply {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if !$Param{CustomerPanelUserID};

    my $Remarks = defined $Param{Remarks} ? ( _PlainTextValue( $Param{Remarks} ) || '' ) : '';

    return if !$Self->_TicketDynamicFieldSet(
        FieldName => 'ZTicket-Remarks',
        TicketID  => $Ticket->{TicketID},
        Value     => $Remarks,
        UserID    => $Param{CustomerPanelUserID},
    );

    my $ParentTicketID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    return 1 if !$ParentTicketID;

    return $Self->_TicketDynamicFieldSet(
        FieldName => 'ZTicket-Remarks',
        TicketID  => $ParentTicketID,
        Value     => $Remarks,
        UserID    => $Param{CustomerPanelUserID},
    );
}

sub _RiskAssessmentCategorySummary {
    my ( $Self, %Param ) = @_;

    my $RiskByField = $Self->_RiskAssessmentCategoryRiskMax(
        Rows => $Param{Rows},
    );

    my @Category = (
        {
            Field => 'ZTicket-BusinessRisk',
            Label => 'Business',
        },
        {
            Field => 'ZTicket-GovernanceRisk',
            Label => 'Governance',
        },
        {
            Field => 'ZTicket-TechnicalRisk',
            Label => 'Technical',
        },
    );

    for my $Category (@Category) {
        $Category->{Risk} = $RiskByField->{ $Category->{Field} };
    }

    return @Category;
}

sub _RiskAssessmentCategoryRiskMax {
    my ( $Self, %Param ) = @_;

    my %RiskByField;

    ROW:
    for my $Row ( @{ $Param{Rows} || [] } ) {
        next ROW if !IsHashRefWithData($Row);

        my $ResidualRisk = _NormalizeValue( $Row->{'ZRM-ResidualCalculatedRisk'} );
        next ROW if !defined $ResidualRisk || $ResidualRisk eq '';

        CATEGORY:
        for my $CategoryID ( _RiskAssessmentFlattenValues( $Row->{'ZRM-ImpactCategory'} ) ) {
            next CATEGORY if !defined $CategoryID || $CategoryID eq '';

            my $FieldName = $Self->_RiskAssessmentCategoryFieldName(
                CategoryID => $CategoryID,
            );
            next CATEGORY if !$FieldName;

            next CATEGORY if defined $RiskByField{$FieldName}
                && !_RiskAssessmentRiskHigher( $ResidualRisk, $RiskByField{$FieldName} );

            $RiskByField{$FieldName} = $ResidualRisk;
        }
    }

    return \%RiskByField;
}

sub _RiskAssessmentCategoryFieldName {
    my ( $Self, %Param ) = @_;

    return if !defined $Param{CategoryID} || $Param{CategoryID} eq '';

    my $Category = $Self->_RiskAssessmentDisplayValue(
        Field => 'ZRM-ImpactCategory',
        Type  => 'GeneralCatalog',
        Value => $Param{CategoryID},
    );

    return if !defined $Category || $Category eq '';

    my $Normalized = lc $Category;
    $Normalized =~ s{[^a-z0-9]+}{}g;

    return 'ZTicket-TechnicalRisk'  if $Normalized =~ m{technical};
    return 'ZTicket-BusinessRisk'   if $Normalized =~ m{business};
    return 'ZTicket-GovernanceRisk' if $Normalized =~ m{governance};

    return;
}

sub _RiskAssessmentTicketRiskMaxSet {
    my ( $Self, %Param ) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);
    return if !IsHashRefWithData( $Param{RiskByField} );
    return if !$Param{CustomerPanelUserID};

    FIELD:
    for my $FieldName ( sort keys %{ $Param{RiskByField} } ) {
        my $IncomingRisk = $Param{RiskByField}->{$FieldName};
        next FIELD if !defined $IncomingRisk || $IncomingRisk eq '';

        my $CurrentRisk = _NormalizeValue( $Ticket->{ 'DynamicField_' . $FieldName } );
        next FIELD if defined $CurrentRisk
            && $CurrentRisk ne ''
            && !_RiskAssessmentRiskHigher( $IncomingRisk, $CurrentRisk );

        return if !$Self->_TicketDynamicFieldSet(
            FieldName => $FieldName,
            TicketID  => $Ticket->{TicketID},
            Value     => $IncomingRisk,
            UserID    => $Param{CustomerPanelUserID},
        );
    }

    return 1;
}

sub _RiskAssessmentRiskHigher {
    my ( $Candidate, $Current ) = @_;

    return 1 if !defined $Current || $Current eq '';
    return if !defined $Candidate || $Candidate eq '';

    return _RiskAssessmentRiskRank($Candidate) > _RiskAssessmentRiskRank($Current);
}

sub _RiskAssessmentRiskRank {
    my ($Risk) = @_;

    return 0 if !defined $Risk;

    my $Text = lc $Risk;
    $Text =~ s{\A\s+|\s+\z}{}g;

    if ( $Text =~ m{(-?\d+(?:\.\d+)?) }xms ) {
        return $1 + 0;
    }

    $Text =~ s{[^a-z]+}{ }g;
    $Text =~ s{\A\s+|\s+\z}{}g;

    return 6 if $Text =~ m{\b(?:extreme|critical)\b};
    return 5 if $Text =~ m{\bvery\s+high\b};
    return 1 if $Text =~ m{\b(?:very\s+low|informational|info)\b};
    return 4 if $Text =~ m{\bhigh\b};
    return 3 if $Text =~ m{\b(?:medium|moderate)\b};
    return 2 if $Text =~ m{\blow\b};

    return 0;
}

sub _RiskAssessmentRiskLevel {
    my ($Risk) = @_;

    my $Score = _RiskAssessmentRiskRank($Risk);
    return {
        Score     => '',
        Label     => 'N/A',
        Summary   => 'N/A',
        Color     => '#8a8ea8',
        TextColor => '#ffffff',
    } if !$Score;

    return {
        Score     => $Score,
        Label     => 'Low',
        Summary   => "$Score - Low",
        Color     => '#2f855a',
        TextColor => '#ffffff',
    } if $Score <= 5;

    return {
        Score     => $Score,
        Label     => 'Medium',
        Summary   => "$Score - Medium",
        Color     => '#d6b500',
        TextColor => '#161616',
    } if $Score <= 9;

    return {
        Score     => $Score,
        Label     => 'High',
        Summary   => "$Score - High",
        Color     => '#f59e0b',
        TextColor => '#161616',
    } if $Score <= 16;

    return {
        Score     => $Score,
        Label     => 'Critical',
        Summary   => "$Score - Critical",
        Color     => '#991b1b',
        TextColor => '#ffffff',
    };
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
            Label => 'Submit Assessment',
            State => 'closed successful',
            Types => ['Assessment'],
        },
        CloseDuplicate => {
            Label => 'Duplicate',
            State => 'closed duplicate',
            Types => ['Assessment'],
        },
        CloseNoAction => {
            Label => 'No Action',
            State => 'closed no action',
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
            Label => 'Submit Assessment',
            State => 'closed successful',
            Types => ['Assessment'],
        },
        CloseDuplicate => {
            Label => 'Duplicate',
            State => 'closed duplicate',
            Types => ['Assessment'],
        },
        CloseNoAction => {
            Label => 'No Action',
            State => 'closed no action',
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
