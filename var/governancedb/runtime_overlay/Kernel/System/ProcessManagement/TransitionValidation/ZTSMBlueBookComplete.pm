# --
# Kernel/System/ProcessManagement/TransitionValidation/ZTSMBlueBookComplete.pm
# --

package Kernel::System::ProcessManagement::TransitionValidation::ZTSMBlueBookComplete;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::System::GenericAgent::ZTSMChangeTaskReader ();
use Kernel::System::ZTSMBlueBookRuntime ();

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;
    return _NormalizeValue( $Value->[0] ) if ref $Value eq 'ARRAY';
    return _NormalizeValue( $Value->{Content} ) if ref $Value eq 'HASH';
    return $Value;
}

sub _TicketOnHold {
    my (%Param) = @_;

    return if !$Param{TicketID};

    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $Param{TicketID},
        DynamicFields => 1,
        UserID        => $Param{UserID} || 1,
        Silent        => 1,
    );

    return if !%Ticket;
    return 1 if _NormalizeValue( $Ticket{'DynamicField_ZTicket-HoldState'} );
    return 1 if lc( $Ticket{State} || '' ) eq 'onhold';

    return;
}

sub Validate {
    my ( $Self, %Param ) = @_;

    if ( !IsHashRefWithData( $Param{Data} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'TESSERA BlueBookComplete: Data has no values!',
        );
        return;
    }

    my $TicketID = $Param{Data}->{TicketID};

    return if !$TicketID;

    return if _TicketOnHold(
        TicketID => $TicketID,
        UserID   => $Param{UserID} || 1,
    );

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

    return if defined $NextBlueLevel && $NextBlueLevel ne '';

    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $Param{UserID} || 1,
        Silent        => 1,
    );

    if ( lc( $Ticket{Type} || '' ) eq 'change' ) {
        my $ChangeTaskReader = Kernel::System::GenericAgent::ZTSMChangeTaskReader->new();
        return if !$ChangeTaskReader->PlanComplete(
            ParentTicketID => $TicketID,
            ParentTicket   => \%Ticket,
            UserID         => $Param{UserID} || 1,
        );
    }

    return 1;
}

1;
