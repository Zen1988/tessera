package Kernel::Output::HTML::TicketMenu::ChangeClassification;
use strict;
use warnings;
use parent 'Kernel::Output::HTML::Base';
our @ObjectDependencies=qw(Kernel::System::TESSERA::ChangeClassification);
sub Run {
    my ($S,%P)=@_;return if !$P{Ticket} || !$Kernel::OM->Get('Kernel::System::TESSERA::ChangeClassification')->CanManage(UserID=>$S->{UserID},TicketID=>$P{Ticket}{TicketID});
    return {%{$P{Config}},%{$P{Ticket}},%P};
}
1;
