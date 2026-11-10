use strict;
use warnings;
use Test::More;
use Template;
use lib '.';
use Kernel::System::TESSERA::CustomerOnboarding;
use Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults;
use Kernel::System::Ticket::Event::TESSERARequestDefaults;
{
    package OnboardTest;
    sub Get {return $_[0]}
    sub ExternalUser {my ($S,$Login)=@_;return $Login eq 'alice'?{Provider=>'LDAP'}:undef}
    sub _Read {return {Config=>{ResponsibilityText=>$_[0]{Text}}}}
    sub CustomerUserDataGet {my ($S,%P)=@_;return (UserLogin=>$P{User},ValidID=>1,%{$S->{Prefs}})}
    sub SetPreferences {my ($S,%P)=@_;$S->{Prefs}{$P{Key}}=$P{Value};return 1}
    sub DynamicFieldGet {my ($S,%P)=@_;return {Name=>$P{Name}}}
    sub ValueGet {my ($S,%P)=@_;return $S->{Values}{$P{DynamicFieldConfig}{Name}}}
    sub ValueSet {my ($S,%P)=@_;push @{$S->{Writes}},\%P;return 1}
    sub GovernanceObjectGet {my ($S,%P)=@_;return {Class=>'Application',ZTSMStatus=>'Active'} if $P{GovernanceObjectID}==40;return}
    sub TicketGet {return %{$_[0]{Ticket}}}
}
local $Kernel::OM=bless {Text=>'Approved responsibilities',Prefs=>{},Values=>{},Writes=>[],Ticket=>{CustomerUserID=>'alice'}},'OnboardTest';
my $S=Kernel::System::TESSERA::CustomerOnboarding->new();
is($S->State('alice')->{Step},'Consent','first external login requires consent');
ok(!$S->State('local')->{Required},'existing local users not silently enrolled');
ok(!eval {$S->Accept(Login=>'alice',Accepted=>1,Version=>'old');1},'stale responsibility version rejected');
my $V=$S->State('alice')->{Version};ok($S->Accept(Login=>'alice',Accepted=>1,Version=>$V),'current acceptance saved');
is($S->State('alice')->{Step},'Defaults','preferences required after consent');
{
    no warnings 'redefine';
    local *Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults::_GovernanceObjectData=sub {return (40=>'App')};
    local *Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults::_SupportProfileData=sub {return (20=>'Assigned team')};
    local *Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults::_DynamicFieldConfigGet=sub {return};
    local *Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults::Run=sub {my ($M,%P)=@_;$Kernel::OM->{SavedDefaults}=$P{GetParam};return 1};
    ok(!eval {$S->Defaults(Login=>'alice',Application=>40,Profile=>999);1},'unassigned team rejected');
    ok(!eval {$S->Defaults(Login=>'alice',Application=>999,Profile=>20);1},'invalid application rejected');
    ok($S->Defaults(Login=>'alice',Application=>40,Profile=>20),'valid defaults saved without assignment API');
    is_deeply($Kernel::OM->{SavedDefaults}{'ZUser-SupportProfile'},[20],'team stored as preference only');
    $Kernel::OM->{Values}={'ZUser-Application'=>40,'ZUser-SupportProfile'=>20};
    is($S->State('alice')->{Step},'Complete','first-login sequence complete');
    delete $Kernel::OM->{Values}{'ZUser-Application'};
    is($S->State('alice')->{Step},'Defaults','cleared required preferences cannot bypass onboarding');
    $Kernel::OM->{Text}='Updated responsibilities';
    is($S->State('alice')->{Step},'Consent','new responsibility version requires new acceptance');
}
my $Event=Kernel::System::Ticket::Event::TESSERARequestDefaults->new();
$Kernel::OM->{Values}={'ZUser-Application'=>40};
ok($Event->Run(Event=>'TicketCreate',Data=>{TicketID=>12},UserID=>7),'new request defaults applied');
is(scalar @{$Kernel::OM->{Writes}},1,'only exported matching ticket field written');
is($Kernel::OM->{Writes}[0]{DynamicFieldConfig}{Name},'ZTicket-Application','application maps to exported ticket field');
$Kernel::OM->{Ticket}{'DynamicField_ZTicket-Application'}=55;$Kernel::OM->{Writes}=[];
$Event->Run(Event=>'TicketCreate',Data=>{TicketID=>12},UserID=>7);
is(scalar @{$Kernel::OM->{Writes}},0,'explicit request context preserved');
delete $Kernel::OM->{Ticket}{'DynamicField_ZTicket-Application'};$Kernel::OM->{Ticket}{'DynamicField_ZState-CurrentState'}='active';
$Event->Run(Event=>'TicketCreate',Data=>{TicketID=>12},UserID=>7);
is(scalar @{$Kernel::OM->{Writes}},0,'started governance snapshot preserved');
my $TT=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard');
for my $Step (qw(Consent Defaults Unavailable)) {
    my $Output='';ok($TT->process('CustomerTESSERAOnboarding.tt',{Data=>{State=>{Step=>$Step,Text=>'<script>bad</script>',Version=>'v'},Applications=>[{ID=>40,Name=>'App'}],Teams=>[{ID=>20,Name=>'Team'}]},Env=>sub {return '/customer.pl'}},\$Output),"customer $Step template renders");
    unlike($Output,qr/<script>bad/,'responsibility HTML escaped');
}
my $Output='';ok($TT->process('AgentTESSERADirectorySync.tt',{Data=>{State=>{Config=>{},Mappings=>{},Groups=>[{GUID=>'a'x32,Name=>'<script>bad</script>',DN=>'CN=Group'}]},Inputs=>[],Profiles=>[{ID=>20,Name=>'Team'}],Roles=>[{ID=>30,Name=>'SUPPORT::ENGINEER'}]},Env=>sub {'/index.pl'}},\$Output),'admin configuration/group mapping template renders');
unlike($Output,qr/<script>bad/,'external group name escaped');
done_testing();
