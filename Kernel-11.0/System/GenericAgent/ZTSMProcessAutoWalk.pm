# --
# Kernel/System/GenericAgent/ZTSMProcessAutoWalk.pm
# --

package Kernel::System::GenericAgent::ZTSMProcessAutoWalk;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::ProcessManagement::Process',
    'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless $Self, $Type;

    $Self->{Debug} = $Param{Debug} || 0;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => 'ZTSMProcessAutoWalk: Constructor called',
    );

    return $Self;
}

sub _ActivityNameGet {
    my (%Param) = @_;

    return if !$Param{ActivityEntityID};

    my $Activities = $Kernel::OM->Get('Kernel::Config')->Get('Process::Activity') || {};

    return if ref $Activities ne 'HASH';
    return if ref $Activities->{ $Param{ActivityEntityID} } ne 'HASH';

    return $Activities->{ $Param{ActivityEntityID} }->{Name};
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;
    return _NormalizeValue( $Value->[0] ) if ref $Value eq 'ARRAY';
    return _NormalizeValue( $Value->{Content} ) if ref $Value eq 'HASH';
    return $Value;
}

sub _TicketOnHold {
    my ($Ticket) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';
    return 1 if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    return 1 if lc( $Ticket->{State} || '' ) eq 'onhold';

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketID = $Param{TicketID};
    my $UserID   = $Param{UserID} || 1;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSMProcessAutoWalk: Enter Run "
            . "TicketID=" . ( $TicketID || '' )
            . " UserID=$UserID",
    );

    return if !$TicketID;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $ProcessObject = $Kernel::OM->Get('Kernel::System::ProcessManagement::Process');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');

    my $ProcessIDField  = $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID');
    my $ActivityIDField = $ConfigObject->Get('Process::DynamicFieldProcessManagementActivityID');

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSMProcessAutoWalk: Process field config "
            . "TicketID=$TicketID "
            . "ProcessIDField=" . ( $ProcessIDField || '' ) . " "
            . "ActivityIDField=" . ( $ActivityIDField || '' ),
    );
    if ( !$ProcessIDField ) {
        return 1;
    }
    if ( !$ActivityIDField ) {
        return 1;
    }

    my $OnlyActivityEntityID = $Param{New}->{ActivityEntityID} || '';
    my $OnlyActivityName     = $Param{New}->{ActivityName}     || '';
    my $MaxWalk              = $Param{New}->{MaxWalk}          || 10;
    my %TransitionData;

    if ( $Param{New}->{StateType} ) {
        $TransitionData{StateType} = $Param{New}->{StateType};
    }

    if ( $Param{New}->{State} ) {
        $TransitionData{State} = $Param{New}->{State};
    }

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
        Silent        => 1,
    );

    if ( !%Ticket ) {
        return 1;
    }

    if ( _TicketOnHold( \%Ticket ) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMProcessAutoWalk: Ticket is onhold, skip process auto-walk TicketID=$TicketID",
        );
        return 1;
    }

    my $ProcessEntityID  = $Ticket{ 'DynamicField_' . $ProcessIDField };
    my $ActivityEntityID = $Ticket{ 'DynamicField_' . $ActivityIDField };

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSMProcessAutoWalk: Process ticket values "
            . "TicketID=$TicketID "
            . "ProcessEntityID=" . ( $ProcessEntityID || '' ) . " "
            . "ActivityEntityID=" . ( $ActivityEntityID || '' ),
    );
    if ( !$ProcessEntityID ) {
        return 1;
    }
    if ( !$ActivityEntityID ) {
        return 1;
    }

    if ( $OnlyActivityEntityID && $OnlyActivityEntityID ne $ActivityEntityID ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  "ZTSMProcessAutoWalk: Skip ticket, activity id does not match "
                . "TicketID=$TicketID "
                . "Expected=$OnlyActivityEntityID "
                . "Actual=$ActivityEntityID",
        );
        return 1;
    }

    if ($OnlyActivityName) {
        my $ActivityName = _ActivityNameGet(
            ActivityEntityID => $ActivityEntityID,
        );

        if ( !$ActivityName || $ActivityName ne $OnlyActivityName ) {
            $LogObject->Log(
                Priority => 'notice',
                Message  =>
                      "ZTSMProcessAutoWalk: Skip ticket, activity name does not match "
                    . "TicketID=$TicketID "
                    . "Expected=$OnlyActivityName "
                    . "Actual=" . ( $ActivityName || '' ) . " "
                    . "Activity=$ActivityEntityID",
            );

            return 1;
        }
    }

    if (
        $OnlyActivityName
        && $OnlyActivityName eq 'StateBook Reader'
    ) {
        my $StateBookResult = $Kernel::OM->Get(
            'Kernel::System::ProcessManagement::TransitionAction::ZTSMStateBookReader'
        )->Run(
            Ticket => \%Ticket,
            UserID => $UserID,
        );

        %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $UserID,
            Silent        => 1,
        );

        if (%Ticket) {
            $ProcessEntityID  = $Ticket{ 'DynamicField_' . $ProcessIDField };
            $ActivityEntityID = $Ticket{ 'DynamicField_' . $ActivityIDField };
        }
    }

    my $WalkCount = 0;

    WALK:
    while ( $WalkCount++ < $MaxWalk ) {

        my $TransitionCheck = $ProcessObject->ProcessTransition(
            ProcessEntityID  => $ProcessEntityID,
            ActivityEntityID => $ActivityEntityID,
            TicketID         => $TicketID,
            UserID           => $UserID,
            CheckOnly        => 1,
            Data             => \%TransitionData,
        );

        if ( !$TransitionCheck || ref $TransitionCheck ne 'HASH' ) {
            $LogObject->Log(
                Priority => 'notice',
                Message  =>
                      "ZTSMProcessAutoWalk: No transition matched "
                    . "TicketID=$TicketID "
                    . "Process=$ProcessEntityID "
                    . "Activity=$ActivityEntityID",
            );

            last WALK;
        }

        my ($TransitionEntityID) = sort keys %{$TransitionCheck};
        my $TargetActivityEntityID = $TransitionCheck->{$TransitionEntityID}->{ActivityEntityID} || '';

        my $TransitionApplied = $ProcessObject->ProcessTransition(
            ProcessEntityID  => $ProcessEntityID,
            ActivityEntityID => $ActivityEntityID,
            TicketID         => $TicketID,
            UserID           => $UserID,
            Data             => \%TransitionData,
        );

        if ( !$TransitionApplied ) {
            $LogObject->Log(
                Priority => 'error',
                Message  =>
                      "ZTSMProcessAutoWalk: Transition matched but did not apply "
                    . "TicketID=$TicketID "
                    . "Process=$ProcessEntityID "
                    . "Activity=$ActivityEntityID "
                    . "Transition=$TransitionEntityID "
                    . "TargetActivity=$TargetActivityEntityID",
            );

            last WALK;
        }

        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  "ZTSMProcessAutoWalk: Transition applied "
                . "TicketID=$TicketID "
                . "Process=$ProcessEntityID "
                . "FromActivity=$ActivityEntityID "
                . "Transition=$TransitionEntityID "
                . "ToActivity=$TargetActivityEntityID",
        );

        %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $UserID,
            Silent        => 1,
        );

        last WALK if !%Ticket;

        my $NextProcessEntityID  = $Ticket{ 'DynamicField_' . $ProcessIDField };
        my $NextActivityEntityID = $Ticket{ 'DynamicField_' . $ActivityIDField };

        last WALK
            if !$NextProcessEntityID
            || !$NextActivityEntityID;

        last WALK
            if $NextProcessEntityID eq $ProcessEntityID
            && $NextActivityEntityID eq $ActivityEntityID;

        $ProcessEntityID  = $NextProcessEntityID;
        $ActivityEntityID = $NextActivityEntityID;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSMProcessAutoWalk: Finished "
            . "TicketID=$TicketID "
            . "WalkCount=$WalkCount",
    );

    return 1;
}

1;
