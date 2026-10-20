package Kernel::Modules::AgentTESSERATicketCalendar;
use strict;
use warnings;
our $ObjectManagerDisabled = 1;
sub new { my ($Type, %Param) = @_; return bless \%Param, $Type; }
sub Run {
    my ($Self, %Param) = @_;
    my $Layout = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    if (($Self->{Subaction} || '') eq 'Events') {
        my $Request = $Kernel::OM->Get('Kernel::System::Web::Request');
        my $Events = eval {
            $Kernel::OM->Get('Kernel::System::TESSERA::TicketCalendar')->Events(
                UserID => $Self->{UserID},
                Start => $Request->GetParam(Param => 'Start'),
                End => $Request->GetParam(Param => 'End'),
            );
        };
        return $Layout->JSONReply(Data => $Events) if $Events;
        return $Layout->JSONReply(Data => { Error => 'Calendar events could not be loaded.' });
    }
    return $Layout->Header(Title => 'Ticket Calendar')
        . $Layout->Output(TemplateFile => 'AgentTESSERATicketCalendar', Data => {%Param})
        . $Layout->Footer();
}
1;
