# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookDirector.pm
# --
# ZTSM whole-BlueBook runtime director.
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookDirector;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);
use Kernel::System::ZTSMBlueBookRuntime ();

our @ObjectDependencies = (
    'Kernel::System::GovernanceObject',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    return if !$Param{Ticket};

    my $Ticket   = $Param{Ticket};
    my $TicketID = $Ticket->{TicketID};
    my $UserID   = $Param{UserID} || 1;

    return if !$TicketID;

    my $BlueBookID = Kernel::System::ZTSMBlueBookRuntime::BlueBookIDGet(
        Ticket => $Ticket,
    );

    return if !$BlueBookID;

    my $CurrentBlueLevel = Kernel::System::ZTSMBlueBookRuntime::CurrentBlueLevelGet(
        Ticket         => $Ticket,
        ParentTicketID => $TicketID,
        BlueBookID     => $BlueBookID,
        UserID         => $UserID,
    );

    return if !defined $CurrentBlueLevel;
    return if $CurrentBlueLevel eq '';

    my $BlueBook = Kernel::System::ZTSMBlueBookRuntime::BlueBookGet(
        BlueBookID => $BlueBookID,
    );

    if ( !$BlueBook || ref $BlueBook ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookDirector: Failed loading BlueBook=$BlueBookID TicketID=$TicketID",
        );
        return;
    }

    my @Records = Kernel::System::ZTSMBlueBookRuntime::RecordsParse(
        BlueBook => $BlueBook,
    );

    return if !@Records;

    my $NextBlueLevel = Kernel::System::ZTSMBlueBookRuntime::NextBlueLevelGet(
        CurrentBlueLevel => $CurrentBlueLevel,
        Records          => \@Records,
    );

    if ( !defined $NextBlueLevel || $NextBlueLevel eq '' ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  "ZTSMBlueBookDirector: No next BlueLevel "
                . "TicketID=$TicketID "
                . "BlueBook=$BlueBookID "
                . "CurrentBlueLevel=$CurrentBlueLevel",
        );
        return 1;
    }

    my @CreatedTicketIDs = Kernel::System::ZTSMBlueBookRuntime::LevelSpawn(
        ParentTicket   => $Ticket,
        ParentTicketID => $TicketID,
        BlueBookID     => $BlueBookID,
        BlueLevel      => $NextBlueLevel,
        Records        => \@Records,
        UserID         => $UserID,
        ArticleParam   => \%Param,
    );

    ZTSMArticleCreate(
        %Param,
        TicketID => $TicketID,
        Subject  => 'DO-NOT-REPLY: BlueBook advanced.',
        Body     =>
              "** Note: This is a system-generated orchestration update message.\n\n"
            . "BlueBook Director:\n"
            . "Advanced\n\n"
            . "BlueBook:\n"
            . $BlueBookID
            . "\n\n"
            . "From BlueLevel:\n"
            . $CurrentBlueLevel
            . "\n\n"
            . "To BlueLevel:\n"
            . $NextBlueLevel
            . "\n\n"
            . "ChapterPlay Tickets Created:\n"
            . ( join( ', ', @CreatedTicketIDs ) || 'None' ),
        HistoryComment => 'ZTSM: BlueBook advanced',
        UserID         => $UserID,
    );

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSMBlueBookDirector: BlueBook advanced "
            . "TicketID=$TicketID "
            . "BlueBook=$BlueBookID "
            . "FromBlueLevel=$CurrentBlueLevel "
            . "ToBlueLevel=$NextBlueLevel "
            . "Created="
            . scalar @CreatedTicketIDs,
    );

    return 1;
}

1;
