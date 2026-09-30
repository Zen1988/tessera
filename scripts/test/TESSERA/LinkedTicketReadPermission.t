use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $Root = File::Spec->catdir( $FindBin::Bin, '..', '..', '..' );
my $Module = File::Spec->catfile(
    $Root, qw(Kernel Package GovernanceDB var governancedb runtime_overlay Kernel System Ticket CustomerPermission ZTSMUserIDCheck.pm)
);
open my $FH, '<', $Module or die "Cannot read $Module: $!";
local $/;
my $Source = <$FH>;
close $FH;
eval $Source;
die $@ if $@;

{
    package LinkedTicketTestOM;
    sub new { bless {}, shift }
    sub Get { return $_[0] }
    sub Log { return 1 }
    sub TicketGet {
        my ( $Self, %Param ) = @_;
        my $Ticket = $main::Ticket{ $Param{TicketID} };
        return $Ticket ? %{$Ticket} : ();
    }
    sub TicketSearch {
        my ( $Self, %Param ) = @_;
        my $Parent = $Param{'DynamicField_ZTicket-Parent'}->{Equals};
        return grep { ( $main::Ticket{$_}->{'DynamicField_ZTicket-Parent'} || '' ) eq $Parent }
            sort keys %main::Ticket;
    }
}

our %Ticket = (
    305 => { TicketID => 305 },
    306 => { TicketID => 306, 'DynamicField_ZTicket-Parent' => 305 },
    307 => { TicketID => 307, 'DynamicField_ZTicket-Parent' => 305 },
    400 => { TicketID => 400 },
);
$Kernel::OM = LinkedTicketTestOM->new();

{
    no warnings 'redefine';
    local *Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck::_CanParticipateTicket = sub {
        my (%Param) = @_;
        return $Param{Ticket}->{TicketID} == 306 && $Param{CustomerUserID} eq 'approver';
    };
    local *Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck::_IsIPCAgent = sub { return 0 };
    local *Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck::_UserParticipateSupportProfile = sub { return 0 };
    my $Permission = Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck->new();

    ok( $Permission->Run( TicketID => 305, CustomerUserID => 'approver', Type => 'ro' ),
        'execution participant can read the linked parent ledger' );
    ok( $Permission->Run( TicketID => 307, CustomerUserID => 'approver', Type => 'ro' ),
        'execution participant can read a linked sibling ticket' );
    ok( !$Permission->Run( TicketID => 400, CustomerUserID => 'approver', Type => 'ro' ),
        'unrelated ticket remains private' );
    ok( !$Permission->Run( TicketID => 305, CustomerUserID => 'approver', Type => 'ztsm_action' ),
        'parent task action is not inherited with read access' );
}

done_testing();
