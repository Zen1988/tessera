# --
# Kernel/System/ProcessManagement/TransitionValidation/ZTSMBlueLevelComplete.pm
# --

package Kernel::System::ProcessManagement::TransitionValidation::ZTSMBlueLevelComplete;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::System::ZTSMBlueBookRuntime ();

our @ObjectDependencies = (
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub Validate {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData( $Param{Data} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ZTSMBlueLevelComplete: Data has no values!',
        );
        return;
    }

    my $TicketID = $Param{Data}->{TicketID};

    return if !$TicketID;

    my $BlueBookID = Kernel::System::ZTSMBlueBookRuntime::BlueBookIDGet(
        Data => $Param{Data},
    );

    return if !$BlueBookID;

    my $BlueLevel = Kernel::System::ZTSMBlueBookRuntime::CurrentBlueLevelGet(
        Data           => $Param{Data},
        ParentTicketID => $TicketID,
        BlueBookID     => $BlueBookID,
    );

    return if !defined $BlueLevel;
    return if $BlueLevel eq '';

    return Kernel::System::ZTSMBlueBookRuntime::LevelComplete(
        ParentTicketID => $TicketID,
        BlueBookID     => $BlueBookID,
        BlueLevel      => $BlueLevel,
        UserID         => $Param{Data}->{UserID} || 1,
    );
}

1;
