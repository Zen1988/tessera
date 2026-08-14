# --
# Kernel/System/ProcessManagement/TransitionAction/ZRMControlEvaluate.pm
# --

package Kernel::System::ProcessManagement::TransitionAction::ZRMControlEvaluate;

use strict;
use warnings;

use parent qw(Kernel::System::ProcessManagement::TransitionAction::Base);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::TESSERA::ControlRuntime',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Params {
    return (
        {
            Key      => 'ControlConfigItemID',
            Value    => 'ConfigItemID of the Control instance whose result will be updated',
            Optional => 0,
        },
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketID = ref $Param{Ticket} eq 'HASH' ? $Param{Ticket}{TicketID} : undef;
    my $ControlID = ref $Param{Config} eq 'HASH' ? $Param{Config}{ControlConfigItemID} : undef;
    my $UserID = ref $Param{Config} eq 'HASH' && $Param{Config}{UserID}
        ? $Param{Config}{UserID}
        : $Param{UserID} || 1;

    if ( !$TicketID || !$ControlID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ZRMControlEvaluate requires the current TicketID and ControlConfigItemID.',
        );
        return;
    }

    my $Result = $Kernel::OM->Get('Kernel::System::TESSERA::ControlRuntime')->EvaluateCompletedTicket(
        TicketID     => $TicketID,
        ConfigItemID => $ControlID,
        UserID       => $UserID,
    );
    if ( !$Result->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ZRMControlEvaluate did not update the Control instance: ' . ( $Result->{Reason} || 'UNKNOWN' ),
        );
        return;
    }

    return 1;
}

1;
