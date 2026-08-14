# --
# Kernel/System/Console/Command/Maint/TESSERA/ControlDispatch.pm
# --

package Kernel::System::Console::Command::Maint::TESSERA::ControlDispatch;

use strict;
use warnings;

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::TESSERA::ControlRuntime',
);

sub Configure {
    my ( $Self, %Param ) = @_;
    $Self->Description('Checks due ConfigItem Control instances; automatic controls evaluate and manual controls expose their service workflow plan.');
    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $Results = $Kernel::OM->Get('Kernel::System::TESSERA::ControlRuntime')->DispatchDueControls(
        UserID => 1,
    );
    my %Count;
    for my $Result ( @{$Results} ) {
        $Count{ $Result->{Status} || 'UNKNOWN' }++;
        my $Line = join ' ',
            'Control=' . ( $Result->{ConfigItemID} || '?' ),
            'Status=' . ( $Result->{Status} || 'UNKNOWN' ),
            ( $Result->{TicketID} ? 'Ticket=' . $Result->{TicketID} : () ),
            ( $Result->{Reason} ? 'Reason=' . $Result->{Reason} : () );
        $Self->Print("$Line\n");
    }
    $Self->Print('Summary: ' . join( ', ', map { $_ . '=' . $Count{$_} } sort keys %Count ) . "\n");
    return $Self->ExitCodeOk();
}

1;
