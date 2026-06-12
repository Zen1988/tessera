# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMArticleHelper.pm
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT_OK = qw(ZTSMArticleBodyConfigItemReferencesExpand ZTSMArticleCreate ZTSMTransitionContextGet);

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

    $Config->{Body} = ZTSMArticleBodyConfigItemReferencesExpand(
        Body => $Config->{Body},
    );

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

sub ZTSMArticleBodyConfigItemReferencesExpand {
    my (%Param) = @_;

    my $Body = $Param{Body};
    return $Body if !defined $Body || $Body eq '';

    my %Cache;
    my $DisplayFor = sub {
        my ($Value) = @_;

        return $Value if !defined $Value || $Value !~ m{\A\d+\z};
        return $Cache{$Value} if exists $Cache{$Value};

        my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
        for my $GetParam (
            { GovernanceObjectID => $Value },
            { VersionID          => $Value },
            )
        {
            my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
                %{$GetParam},
                DynamicFields => 0,
                Silent        => 1,
            );

            next if !$GovernanceObject || ref $GovernanceObject ne 'HASH';
            next if !$GovernanceObject->{Name};

            return $Cache{$Value} = $Value . ' - ' . $GovernanceObject->{Name};
        }

        return $Cache{$Value} = $Value;
    };

    my $ConfigItemLabel = qr{
        (?:BlueBook|StateBook|Book|Profile|Support\s+Profile|Owner\s+Group|Application|Chapter|Config(?:uration)?\s*Item|Governance|Platform|Technology|Environment|Location|Organization)
    }ix;

    $Body =~ s{
        (^ [^\n:]* $ConfigItemLabel [^\n:]* : \s* \n [ \t]*)
        (\d+)
        (?= \s* (?:\n|$) )
    }{$1 . $DisplayFor->($2)}egmx;

    $Body =~ s{
        (\b (?:BlueBook|StateBook|SupportProfile|OwnerGroup|Application|Chapter|ConfigItem|Platform|Technology|Environment|Location|Organization) \s* = \s*)
        (\d+)
        \b
    }{$1 . $DisplayFor->($2)}egmx;

    return $Body;
}

1;
