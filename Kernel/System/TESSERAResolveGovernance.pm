# --
# Kernel/System/ProcessManagement/TransitionAction/TESSERAResolveGovernance.pm
# --
# Copyright (C) 2026 Zen
# Author: Yunn Chyuan Chan (yunnchyuanchan@gmail.com)
#
# TESSERA Governance Resolution Engine
#
# Current Scope:
# - Resolve Service Support Map using Ticket Service
# - Load latest ConfigItem snapshot
# - Update governance snapshot back into ticket
#
# Powered by Zen ☕
# --

package Kernel::System::ProcessManagement::TransitionAction::TESSERAResolveGovernance;

use strict;
use warnings;

use Data::Dumper;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get(
        'Kernel::System::Log'
    );

    # ------------------------------------------------------------ #
    # VALIDATE TICKET CONTEXT
    # ------------------------------------------------------------ #

    if (
        !$Param{Ticket}
        ||
        ref $Param{Ticket} ne 'HASH'
    ) {

        $LogObject->Log(
            Priority => 'error',
            Message  => 'TESSERA: Missing Ticket context',
        );

        return;
    }

    my $TicketID  = $Param{Ticket}->{TicketID};
    my $ServiceID = $Param{Ticket}->{ServiceID};

    if (!$TicketID) {

        $LogObject->Log(
            Priority => 'error',
            Message  => 'TESSERA: Missing TicketID',
        );

        return;
    }

    if (!$ServiceID) {

        $LogObject->Log(
            Priority => 'error',
            Message  => "TESSERA: Missing ServiceID for TicketID=$TicketID",
        );

        return;
    }

    $LogObject->Log(
        Priority => 'error',
        Message  => "TESSERA: TicketID=$TicketID ServiceID=$ServiceID",
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
    # FIND SERVICE SUPPORT MAP
    # ------------------------------------------------------------ #

    my @ConfigItemIDs
        = $ConfigItemObject->ConfigItemSearch(

            Result => 'ARRAY',

            Classes => ['Service Support Map'],

            'DynamicField_ZTSMServiceSupportMap-Service' => {
                Equals => $ServiceID,
            },

            UserID => 1,
        );

    if ( !@ConfigItemIDs ) {

        $LogObject->Log(
            Priority => 'error',
            Message  => "TESSERA: No Service Support Map found for ServiceID=$ServiceID",
        );

        return;
    }

    my $ConfigItemID = $ConfigItemIDs[0];

    $LogObject->Log(
        Priority => 'error',
        Message  => "TESSERA: Resolved ServiceSupportMap ConfigItemID=$ConfigItemID",
    );

    # ------------------------------------------------------------ #
    # LOAD CONFIG ITEM
    # ------------------------------------------------------------ #

    my $ConfigItem = $ConfigItemObject->ConfigItemGet(
        ConfigItemID => $ConfigItemID,
    );

    if (
        !$ConfigItem
        ||
        ref $ConfigItem ne 'HASH'
    ) {

        $LogObject->Log(
            Priority => 'error',
            Message  => "TESSERA: Failed ConfigItemGet for ConfigItemID=$ConfigItemID",
        );

        return;
    }

    $LogObject->Log(
        Priority => 'error',
        Message  => 'TESSERA: ConfigItem Snapshot=' . Dumper($ConfigItem),
    );

    #
    # TEMP PLACEHOLDER
    # Will inspect actual runtime structure first
    #

    my $OwnerGroup    = 43;
    my $ApprovalGroup = 44;

    # ------------------------------------------------------------ #
    # UPDATE TICKET SNAPSHOT
    # ------------------------------------------------------------ #

    my %UpdateMap = (

        'ZTicket-ServiceSupportMap'
            => $ConfigItemID,

        'ZTicket-OwnerGroup'
            => $OwnerGroup,

        'ZTicket-ApprovalGroup'
            => $ApprovalGroup,
    );

    FIELD:
    for my $FieldName ( keys %UpdateMap ) {

        next FIELD if !$UpdateMap{$FieldName};

        my $DynamicFieldConfig
            = $DynamicFieldObject->DynamicFieldGet(
                Name => $FieldName,
            );

        if (!$DynamicFieldConfig) {

            $LogObject->Log(
                Priority => 'error',
                Message  => "TESSERA: DynamicField not found: $FieldName",
            );

            next FIELD;
        }

        my $Value = $UpdateMap{$FieldName};

        my $Success
            = $DynamicFieldBackendObject->ValueSet(

                DynamicFieldConfig => $DynamicFieldConfig,

                ObjectID => $TicketID,

                Value => $Value,

                UserID => 1,
            );

        $LogObject->Log(
            Priority => 'error',
            Message  => "TESSERA: Updated $FieldName Value=$Value Result=$Success",
        );
    }

    $LogObject->Log(
        Priority => 'error',
        Message  => "TESSERA: Governance resolution completed for TicketID=$TicketID",
    );

    return 1;
}

1;
