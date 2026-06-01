# --
# Kernel/System/ProcessManagement/TransitionValidation/ZTSMBlueBookHasNextLevel.pm
# --

package Kernel::System::ProcessManagement::TransitionValidation::ZTSMBlueBookHasNextLevel;

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
            Message  => 'ZTSMBlueBookHasNextLevel: Data has no values!',
        );
        return;
    }

    my $TicketID = $Param{Data}->{TicketID};

    return if !$TicketID;

    my $BlueBookID = Kernel::System::ZTSMBlueBookRuntime::BlueBookIDGet(
        Data => $Param{Data},
    );

    return if !$BlueBookID;

    my $BlueBook = Kernel::System::ZTSMBlueBookRuntime::BlueBookGet(
        BlueBookID => $BlueBookID,
    );

    return if !$BlueBook;

    my @Records = Kernel::System::ZTSMBlueBookRuntime::RecordsParse(
        BlueBook => $BlueBook,
    );

    return if !@Records;

    my $BlueLevel = Kernel::System::ZTSMBlueBookRuntime::CurrentBlueLevelGet(
        Data           => $Param{Data},
        ParentTicketID => $TicketID,
        BlueBookID     => $BlueBookID,
    );

    return if !defined $BlueLevel;
    return if $BlueLevel eq '';

    my $NextBlueLevel = Kernel::System::ZTSMBlueBookRuntime::NextBlueLevelGet(
        CurrentBlueLevel => $BlueLevel,
        Records          => \@Records,
    );

    return 1 if defined $NextBlueLevel && $NextBlueLevel ne '';

    return;
}

1;
