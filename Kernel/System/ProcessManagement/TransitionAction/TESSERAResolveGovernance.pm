# --
# Kernel/System/ProcessManagement/TransitionAction/TESSERAResolveGovernance.pm
# --
# Copyright (C) 2026 Zen
# Author: Yunn Chyuan Chan
#
# TESSERA Governance Resolution Engine
#
# Purpose:
# - Resolve Service Support Map
# - Resolve StateBook
# - Resolve ApprovalModel
# - Update Ticket Orchestration Snapshot
#
# Powered by Zen ☕
# --

package Kernel::System::ProcessManagement::TransitionAction::TESSERAResolveGovernance;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !$Value;

    if ( ref $Value eq 'ARRAY' ) {
        return $Value->[0];
    }

    return $Value;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get(
        'Kernel::System::Log'
    );

    my $DynamicFieldObject = $Kernel::OM->Get(
        'Kernel::System::DynamicField'
    );

    my $DynamicFieldBackendObject = $Kernel::OM->Get(
        'Kernel::System::DynamicField::Backend'
    );

    my $ConfigItemObject = $Kernel::OM->Get(
        'Kernel::System::ITSMConfigItem'
    );

    # ------------------------------------------------------------ #
    # VALIDATE TICKET
    # ------------------------------------------------------------ #

    return if !$Param{Ticket};

    my $Ticket = $Param{Ticket};

    my $TicketID  = $Ticket->{TicketID};
    my $ServiceID = $Ticket->{ServiceID};

    return if !$TicketID;
    return if !$ServiceID;

    # ------------------------------------------------------------ #
    # TICKET CONTEXT
    # ------------------------------------------------------------ #

    my $TicketApplication = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Application'}
    );

    my $TicketEnvironment = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Env'}
    );

    my $TicketLocation = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-Location'}
    );

    # ------------------------------------------------------------ #
    # FIND SERVICE SUPPORT MAP
    # ------------------------------------------------------------ #

    my @CandidateIDs = $ConfigItemObject->ConfigItemSearch(

        Result => 'ARRAY',

        Classes => ['Service Support Map'],

        'DynamicField_ZTSMServiceSupportMap-Service' => {
            Equals => $ServiceID,
        },

        UserID => 1,
    );

    if ( !@CandidateIDs ) {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                "TESSERA: No Service Support Map found "
                . "for ServiceID=$ServiceID",
        );

        return;
    }

    #
    # Current Strategy
    # First match only
    #
    # Future:
    # scoring engine
    #

    my $WinnerID = $CandidateIDs[0];

    # ------------------------------------------------------------ #
    # LOAD SERVICE SUPPORT MAP
    # ------------------------------------------------------------ #

    my $Winner = $ConfigItemObject->ConfigItemGet(

        ConfigItemID  => $WinnerID,

        DynamicFields => 1,
    );

    if (
        !$Winner
        ||
        ref $Winner ne 'HASH'
    ) {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                "TESSERA: Failed loading "
                . "ServiceSupportMap=$WinnerID",
        );

        return;
    }

    # ------------------------------------------------------------ #
    # ORCHESTRATION VALUES
    # ------------------------------------------------------------ #

    my $StateBook = _NormalizeValue(
        $Winner->{'DynamicField_ZTSMServiceSupportMap-StateBook'}
    );

    my $ApprovalModel = _NormalizeValue(
        $Winner->{'DynamicField_ZTSMServiceSupportMap-ApprovalModel'}
    );

    # ------------------------------------------------------------ #
    # VALIDATE REQUIRED VALUES
    # ------------------------------------------------------------ #

    if ( !$StateBook ) {

        $LogObject->Log(
            Priority => 'error',
            Message  =>
                "TESSERA: Missing StateBook "
                . "ServiceSupportMap=$WinnerID",
        );

        return;
    }

    # ------------------------------------------------------------ #
    # UPDATE ORCHESTRATION SNAPSHOT
    # ------------------------------------------------------------ #

    my %UpdateMap = (

        'ZTicket-StateBook'
            => $StateBook,

        'ZTicket-ApprovalModel'
            => $ApprovalModel,
    );

    FIELD:
    for my $FieldName ( keys %UpdateMap ) {

        next FIELD if !$UpdateMap{$FieldName};

        my $DynamicFieldConfig
            = $DynamicFieldObject->DynamicFieldGet(
                Name => $FieldName,
            );

        next FIELD if !$DynamicFieldConfig;
        next FIELD if ref $DynamicFieldConfig ne 'HASH';

        my $Success
            = $DynamicFieldBackendObject->ValueSet(

                DynamicFieldConfig => $DynamicFieldConfig,

                ObjectID => $TicketID,

                Value => $UpdateMap{$FieldName},

                UserID => 1,
            );

        if ( !$Success ) {

            $LogObject->Log(
                Priority => 'error',
                Message  =>
                    "TESSERA: Failed updating "
                    . "$FieldName "
                    . "TicketID=$TicketID",
            );
        }
    }

    # ------------------------------------------------------------ #
    # LOG SUCCESS
    # ------------------------------------------------------------ #

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "TESSERA: Governance resolved "
            . "TicketID=$TicketID "
            . "ServiceSupportMap=$WinnerID "
            . "StateBook=$StateBook",
    );

    return 1;
}

1;
