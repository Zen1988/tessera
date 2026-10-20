use strict;
use warnings;
use Test::More;
use Time::Local qw(timegm);
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::TicketCalendar;

{ package CalendarClock;
    sub new { bless { Value => $_[1] }, $_[0] }
    sub ToEpoch {
        my ($Y,$M,$D,$h,$m,$s) = $_[0]{Value} =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/;
        return Time::Local::timegm($s,$m,$h,$D,$M-1,$Y);
    }
    sub ToString { $_[0]{Value} }
}
{ package CalendarOM;
    sub Get { return $_[0]{Categories} if $_[1] eq 'Ticket::Frontend::CustomerTicketCategories'; return $_[0] }
    sub Create {
        my ($Self,$Name,%P)=@_;
        my $V=$P{ObjectParams}{String};
        if (!defined $V) {
            my @G=gmtime($P{ObjectParams}{Epoch});
            $V=sprintf '%04d-%02d-%02d %02d:%02d:%02d',$G[5]+1900,$G[4]+1,$G[3],$G[2],$G[1],$G[0];
        }
        return CalendarClock->new($V);
    }
    sub TicketSearch { my ($Self,%P)=@_; push @{$Self->{Searches}},\%P; return (1,2,3,4,5) }
    sub TicketPermission { my ($Self,%P)=@_; push @{$Self->{Checks}},\%P; return $P{TicketID} != 4 }
    sub TicketCustomerPermission { my ($Self,%P)=@_; push @{$Self->{CustomerChecks}},\%P; return $P{TicketID} == 1 || $P{TicketID} == 88 }
    sub Run { my ($Self,%P)=@_; push @{$Self->{ZTSMChecks}},\%P; return $P{TicketID} == 2 }
    sub TicketGet { my ($Self,%P)=@_; return %{ $Self->{Tickets}{$P{TicketID}} || {} } }
    sub TicketNumberLookup { my ($Self,%P)=@_; return $Self->{Tickets}{$P{TicketID}}{TicketNumber} }
    sub HistoryGet { return ({StateID=>9,CreateTime=>'2026-10-13 06:00:00'}) }
    sub StateGet { return (TypeName=>'closed') }
}

$Kernel::OM=bless {Categories=>{
    Type=>{Order=>2,ColorDefault=>'#337777',ColorSelection=>{Change=>'#123456',Incident=>'#fed'},Translate=>1},
    State=>{Order=>1,ColorDefault=>'red; background:url(unsafe)'},
},Tickets=>{
    1=>{Type=>'Change',State=>'open',TicketNumber=>'CH1',Title=>'Deploy',
        'DynamicField_ZTicket-Parent'=>88,
        'DynamicField_ZTicket-ScheduleStart'=>'2026-10-13 01:00:00',
        'DynamicField_ZTicket-ScheduleFinish'=>'2026-10-13 03:00:00'},
    2=>{Type=>'Incident',TicketNumber=>'IN2',Title=>'Outage',Created=>'2026-10-12 22:00:00',
        'DynamicField_ZTicket-Parent'=>99,
        'DynamicField_ZTicket-ActualStart'=>'2026-10-12 23:00:00',
        'DynamicField_ZTicket-ActualFinish'=>'2026-10-13 02:00:00'},
    3=>{Type=>'ServiceRequest',TicketNumber=>'SR3',Title=>'Request',
        Created=>'2026-09-01 00:00:00','DynamicField_ZTicket-ActualFinish'=>'2026-09-01 01:00:00'},
    4=>{Type=>'Incident',TicketNumber=>'SECRET',Title=>'Hidden',
        Created=>'2026-10-13 00:00:00','DynamicField_ZTicket-ActualFinish'=>'2026-10-13 01:00:00'},
    5=>{Type=>'ServiceRequest',TicketNumber=>'SR5',Title=>'Completed request',StateType=>'closed',
        Created=>'2026-10-13 04:00:00'},
    88=>{Type=>'Other',TicketNumber=>'MASTER88',Title=>'Readable master'},
    99=>{Type=>'Other',TicketNumber=>'MASTER99',Title=>'Secret master'},
}},'CalendarOM';
my $Events=Kernel::System::TESSERA::TicketCalendar->new()->Events(
    UserID=>7,Start=>'2026-10-13',End=>'2026-10-14');
is(scalar @{$Events},3,'only overlapping readable ticket events returned');
is_deeply([map {$_->{id}} @{$Events}],[1,2,5],'scheduled change and actual incident/service request included');
is($Events->[1]{start},timegm(0,0,22,12,9,2026)*1000,'incident starts at native ticket creation even with a later ActualStart');
is($Events->[2]{end},timegm(0,0,6,13,9,2026)*1000,'closed request ends at its history close transition');
ok(!grep({$_->{title}=~/SECRET/} @{$Events}),'unreadable ticket title not disclosed');
ok(!grep({$_->{UserID}!=7 || $_->{Type} ne 'ro'} @{$Kernel::OM->{Checks}}),'each candidate uses actor read permission');
ok(!grep({$_->{UserID}!=7 || $_->{Permission} ne 'ro'} @{$Kernel::OM->{Searches}}),'all searches use actor read scope');
my $CustomerEvents=Kernel::System::TESSERA::TicketCalendar->new()->EventsForCustomer(
    CustomerUserID=>'ipc@example.test',TicketIDs=>[1,2,4],Start=>'2026-10-13',End=>'2026-10-14');
is_deeply([map {$_->{id}} @{$CustomerEvents}],[1,2],
    'customer calendar honors native and TESSERA zoom permission while omitting denied ticket');
like($CustomerEvents->[0]{url},qr{\Acustomer\.pl\?Action=CustomerTicketZoom},
    'customer event opens customer ticket view');
is($CustomerEvents->[0]{title},'CH1 > Deploy','ASCII separator prevents encoding corruption');
is_deeply([map {$_->{name}} @{$CustomerEvents->[0]{categories}}],['State','Type'],'front-page category ordering reused');
is($CustomerEvents->[0]{categories}[1]{color},'#123456','front-page configured type color reused');
is($CustomerEvents->[0]{categories}[0]{color},'','unsafe configured CSS color omitted');
is($CustomerEvents->[1]{categories}[0]{color},'#fed','three-digit configured color preserved');
is($CustomerEvents->[0]{master}{number},'MASTER88','readable master groups its visible child');
is($CustomerEvents->[0]{master}{title},'Readable master','readable master title is available');
is($CustomerEvents->[1]{master}{number},'MASTER99','unreadable master number groups its visible child');
ok(!exists $CustomerEvents->[1]{master}{title} && !exists $CustomerEvents->[1]{master}{url},
    'unreadable master does not expose title or zoom link');
my $LargeScope = Kernel::System::TESSERA::TicketCalendar->new()->EventsForCustomer(
    CustomerUserID=>'ipc@example.test', TicketIDs=>[(6..20006)],
    Start=>'2026-10-13', End=>'2026-10-14');
is_deeply($LargeScope, [], 'large authorized IPC overview scope is valid');
ok(!grep({$_->{UserID} ne 'ipc@example.test' || $_->{Type} ne 'ro'} @{$Kernel::OM->{CustomerChecks}}),
    'native customer read permission checked against signed-in customer');
ok(!grep({$_->{CustomerUserID} ne 'ipc@example.test' || $_->{Type} ne 'ro'} @{$Kernel::OM->{ZTSMChecks}}),
    'TESSERA customer permission fallback uses signed-in customer');
my $MissingScope=eval {Kernel::System::TESSERA::TicketCalendar->new()->EventsForCustomer(
    CustomerUserID=>'ipc@example.test',Start=>'2026-10-13',End=>'2026-10-14')};
ok(!$MissingScope,'customer endpoint cannot search arbitrary ticket IDs without overview scope');
my $Bad=eval {Kernel::System::TESSERA::TicketCalendar->new()->Events(UserID=>7,Start=>'2026-01-01',End=>'2026-10-14')};
ok(!$Bad,'oversized range rejected');
done_testing();
