# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMArticleHelper.pm
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(ZTSMArticleCreate ZTSMTransitionContextGet);

sub ZTSMTransitionContextGet {
    my (%Param) = @_;

    my $Config = ref $Param{Config} eq 'HASH' ? $Param{Config} : {};

    return (
        ProcessEntityID => $Param{ProcessEntityID}
            || $Config->{ProcessEntityID}
            || $Config->{FallbackProcessEntityID},
        ActivityEntityID => $Param{ActivityEntityID}
            || $Config->{ActivityEntityID}
            || $Config->{FallbackActivityEntityID},
        TransitionEntityID => $Param{TransitionEntityID}
            || $Config->{TransitionEntityID}
            || $Config->{FallbackTransitionEntityID},
        TransitionActionEntityID => $Param{TransitionActionEntityID}
            || $Config->{TransitionActionEntityID}
            || $Config->{FallbackTransitionActionEntityID},
    );
}

sub ZTSMArticleCreate {
    my (%Param) = @_;

    my $UserID = $Param{UserID} || 1;
    my $Ticket = $Param{Ticket};

    if ( !$Ticket && $Param{TicketID} ) {
        $Ticket = {
            $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
                TicketID      => $Param{TicketID},
                DynamicFields => 1,
                UserID        => $UserID,
            ),
        };
    }

    return if !$Ticket || !$Ticket->{TicketID};

    my %TransitionContext = ZTSMTransitionContextGet(%Param);
    my $Config            = {
        CommunicationChannel => $Param{CommunicationChannel} || 'Internal',
        SenderType           => $Param{SenderType}           || 'system',
        IsVisibleForCustomer => exists $Param{IsVisibleForCustomer} ? $Param{IsVisibleForCustomer} : 1,
        Subject              => $Param{Subject},
        Body                 => $Param{Body},
        ContentType          => $Param{ContentType} || 'text/plain; charset=utf-8',
        HistoryType          => $Param{HistoryType} || 'AddNote',
        HistoryComment       => $Param{HistoryComment},
    };

    if (
        !$TransitionContext{ProcessEntityID}
        || !$TransitionContext{ActivityEntityID}
        || !$TransitionContext{TransitionEntityID}
        || !$TransitionContext{TransitionActionEntityID}
        )
    {
        my $ArticleBackendObject = $Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(
            ChannelName => $Config->{CommunicationChannel},
        );

        return $ArticleBackendObject->ArticleCreate(
            %{$Config},
            TicketID => $Ticket->{TicketID},
            UserID   => $UserID,
        );
    }

    return $Kernel::OM->Get('Kernel::System::ProcessManagement::TransitionAction::TicketArticleCreate')->Run(
        UserID                   => $UserID,
        Ticket                   => $Ticket,
        ProcessEntityID          => $TransitionContext{ProcessEntityID},
        ActivityEntityID         => $TransitionContext{ActivityEntityID},
        TransitionEntityID       => $TransitionContext{TransitionEntityID},
        TransitionActionEntityID => $TransitionContext{TransitionActionEntityID},
        Config                   => $Config,
    );
}

1;
