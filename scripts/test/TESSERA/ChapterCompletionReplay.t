use strict;
use warnings;
use Test::More;
use lib 'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay', 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector;
{
    package CompletionOM;
    sub Get { $_[0] }
    sub Log { push @{$_[0]{Logs}}, $_[2]; return 1 }
    sub TicketGet { return %{$_[0]{Parent}} }
    sub TicketSearch { die "CURRENT_COMPLETION_REACHED\n" }
}
local $Kernel::OM = bless {Parent => {TicketID=>320,State=>'approve',
    'DynamicField_ZTicket-BlueBook'=>1531,'DynamicField_ZTicket-BlueLevel'=>1},Logs=>[]}, 'CompletionOM';
my $director = Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector->new();
my $child = {TicketID=>322,State=>'closed successful',
    'DynamicField_ZTicket-Parent'=>320,'DynamicField_ZTicket-BlueBook'=>1530,
    'DynamicField_ZTicket-BlueLevel'=>1};
ok($director->Run(Ticket=>$child),'assessment closure replay ignored while approval pending');
is($Kernel::OM->{Parent}{State},'approve','pending approval stage preserved');
$Kernel::OM->{Parent}{State}='remediate';
$Kernel::OM->{Parent}{'DynamicField_ZTicket-BlueBook'}=1532;
ok($director->Run(Ticket=>$child),'late assessment closure ignored at remediation');
$Kernel::OM->{Parent}{'DynamicField_ZTicket-BlueBook'}=1530;
$Kernel::OM->{Parent}{'DynamicField_ZTicket-BlueLevel'}=2;
ok($director->Run(Ticket=>$child),'old level cannot advance later level in same Book');
$Kernel::OM->{Parent}{'DynamicField_ZTicket-BlueLevel'}=1;
$Kernel::OM->{Parent}{'DynamicField_ZIN-Iteration'}=2;
ok($director->Run(Ticket=>$child),'previous iteration completion ignored');
$child->{'DynamicField_ZIN-Iteration'}=2;
my $result=eval {$director->Run(Ticket=>$child)};
like($@,qr/CURRENT_COMPLETION_REACHED/,'matching current completion reaches existing orchestration');
$Kernel::OM->{Parent}{'DynamicField_ZTicket-BlueBook'}=[1530];
$child->{'DynamicField_ZTicket-BlueBook'}=[1530];
eval {$director->Run(Ticket=>$child)};
like($@,qr/CURRENT_COMPLETION_REACHED/,'array-shaped reference values remain supported');
$Kernel::OM->{Parent}{State}='follow-up';
$Kernel::OM->{Parent}{'DynamicField_ZTicket-BlueLevel'}=9;
eval {$director->Run(Ticket=>$child)};
like($@,qr/CURRENT_COMPLETION_REACHED/,'follow-up preserves existing independent level semantics');
$Kernel::OM->{Parent}{'DynamicField_ZTicket-BlueBook'}=undef;
ok($director->Run(Ticket=>$child),'cleared Book cannot consume historical completion');
done_testing();
