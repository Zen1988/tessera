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
use Kernel::System::GenericAgent::ZTSMChangeTaskReader ();
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

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;
    return _NormalizeValue( $Value->[0] ) if ref $Value eq 'ARRAY';
    return _NormalizeValue( $Value->{Content} ) if ref $Value eq 'HASH';
    return $Value;
}

sub _TicketOnHold {
    my ($Ticket) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';
    return 1 if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    return 1 if lc( $Ticket->{State} || '' ) eq 'onhold';

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');

    return if !$Param{Ticket};

    my $Ticket   = $Param{Ticket};
    my $TicketID = $Ticket->{TicketID};
    my $UserID   = $Param{UserID} || 1;

    return if !$TicketID;

    if ( _TicketOnHold($Ticket) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMBlueBookDirector: Ticket is onhold, skip BlueBook advance TicketID=$TicketID",
        );
        return 1;
    }

    if ( lc( $Ticket->{Type} || '' ) eq 'change' ) {
        my $ChangeTaskReader = Kernel::System::GenericAgent::ZTSMChangeTaskReader->new();
        if (
            !$ChangeTaskReader->NormalProgressAllowed(
                ParentTicketID => $TicketID,
                ParentTicket   => $Ticket,
                UserID         => $UserID,
            )
            )
        {
            $LogObject->Log(
                Priority => 'notice',
                Message  =>
                    "ZTSMBlueBookDirector: Change execution failure or rollback blocks BlueBook advance TicketID=$TicketID",
            );
            return 1;
        }
    }

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
