package Kernel::System::GenericAgent::ZTSMActivityNotificationCheck;

use strict;
use warnings;
use Kernel::System::ZTSMBlueBookRuntime ();

our @ObjectDependencies = qw(
    Kernel::System::DateTime Kernel::System::GeneralCatalog Kernel::System::GovernanceObject
    Kernel::System::Log Kernel::System::State Kernel::System::TESSERA::ActivityNotification
    Kernel::System::Ticket
);

sub new { return bless {}, shift }

sub Run {
    my ( $Self, %Param ) = @_;
    return 1 if !$Param{TicketID};
    my $Tickets = $Kernel::OM->Get('Kernel::System::Ticket');
    my $UserID = $Param{UserID} || 1;
    my %Ticket = $Tickets->TicketGet(
        TicketID => $Param{TicketID}, UserID => $UserID, DynamicFields => 1, Silent => 1,
    );
    return 1 if !$Ticket{'DynamicField_ZTicket-Parent'} || !$Ticket{'DynamicField_ZTicket-OwnerGroup'}
        || $Ticket{'DynamicField_ZTicket-Owner'} || _Paused( \%Ticket );
    my $Record = Kernel::System::ZTSMBlueBookRuntime::NotificationRecordForTicket( Ticket => \%Ticket );
    my $PolicyID = $Record && $Record->{EscalationPolicy};
    $PolicyID = $PolicyID->[0] if ref $PolicyID eq 'ARRAY' && @{$PolicyID} == 1;
    return 1 if !$PolicyID || ref $PolicyID || $PolicyID !~ /\A[1-9][0-9]*\z/;
    my $Policy = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $PolicyID, DynamicFields => 1,
    );
    return 1 if !$Policy || !$Policy->{ClassID};
    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $Classes = $Catalog->ItemList( Class => 'ZTSM::GovernanceObject::Class', Valid => 1 ) || {};
    return 1 if ($Classes->{ $Policy->{ClassID} } // '') ne 'EscalationPolicy';
    my $Statuses = $Catalog->ItemList( Class => 'ZTSM::GovernanceObject::Status', Valid => 1 ) || {};
    return 1 if !$Policy->{ZTSMStatusID} || ($Statuses->{ $Policy->{ZTSMStatusID} } // '') ne 'Active';
    my $Evaluator = $Kernel::OM->Get('Kernel::System::TESSERA::ActivityNotification');
    my @Timeline;
    my $LatestStateID;
    for my $Line ( $Tickets->HistoryGet( TicketID => $Param{TicketID}, UserID => $UserID ) ) {
        next if $Line->{HistoryType} ne 'NewTicket' && $Line->{HistoryType} ne 'StateUpdate';
        return 1 if !@Timeline && $Line->{HistoryType} ne 'NewTicket';
        return 1 if !$Line->{StateID} || !$Line->{CreateTime};
        my %State = $Kernel::OM->Get('Kernel::System::State')->StateGet( ID => $Line->{StateID} );
        my $At = $Kernel::OM->Create('Kernel::System::DateTime', ObjectParams => { String => $Line->{CreateTime} });
        return 1 if !$State{TypeName} || !$At;
        push @Timeline, [ $At->ToEpoch(), _Paused({ State => $State{Name}, StateType => $State{TypeName} }) ];
        $LatestStateID = $Line->{StateID};
    }
    return 1 if !$LatestStateID || $LatestStateID != $Ticket{StateID};
    my $Seconds = $Evaluator->ActiveSeconds(
        Timeline => \@Timeline, Now => $Kernel::OM->Create('Kernel::System::DateTime')->ToEpoch(),
    );
    return 1 if !defined $Seconds;
    my $Result = $Evaluator->Evaluate(
        Event => 'Timer', Rules => $Policy->{'DynamicField_ZNotify-EscalationRules'},
        AgeDays => sprintf('%.9f', $Seconds / 86400), Owner => '',
        SupportProfile => $Ticket{'DynamicField_ZTicket-OwnerGroup'},
    );
    if ($Result->{Role}) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message => "Activity notification dry run for ticket $Param{TicketID}: $Result->{Role} is due.",
        );
    }
    return 1;
}

sub _Paused {
    my ($Ticket) = @_;
    my $State = lc( $Ticket->{State} // '' );
    $State =~ s/[-_\s]//g;
    return $State eq 'onhold' || ($Ticket->{StateType} // '') =~ /\A(?:closed|merged)\z/;
}

1;
