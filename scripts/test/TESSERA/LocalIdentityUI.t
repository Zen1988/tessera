use strict;
use warnings;
use Test::More;
use Template;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::Modules::AgentTESSERALocalIdentity;
{
 package LURequest;sub GetParam {return $main::params{$_[2]}}sub GetArray {return ()}sub RequestMethod {return $main::method}
 package LUBackend;
 sub _admin {die 'denied' if !$main::admin}
 sub Configure {$main::writes++;return 10}
 sub View {return {Subject=>{UserLogin=>'person'},Link=>{AgentID=>10,Managed=>{Groups=>[],Roles=>[]}},RoutingReady=>1}}
 sub SubjectLabel {return 'Person (person)'}
 package LUGroup;sub GroupList {return (2=>'agents')}sub RoleList {return (4=>'operators')}
 package LULayout;
 sub NoPermission {return 'denied'}sub ErrorScreen {return 'error'}sub ChallengeTokenCheck {return 1}
 sub Header {return ''}sub NavigationBar {return ''}sub Footer {return ''}
 sub Output {my ($s,%p)=@_;$main::captured=$p{Data};return 'page'}
 package LUOM;sub Get {my ($s,$n)=@_;return $main::layout if $n eq 'Kernel::Output::HTML::Layout';return bless {},'LURequest' if $n eq 'Kernel::System::Web::Request';return bless {},'LUGroup' if $n eq 'Kernel::System::Group';return bless {},'LUBackend'}
 package Kernel;our $OM=bless {},'LUOM';
}
our ($admin,$method,$writes,$captured)=(0,'GET',0,undef);our %params;
our $layout=bless {UserChallengeToken=>'csrf'},'LULayout';
my $s=Kernel::Modules::AgentTESSERALocalIdentity->new(UserID=>99,Subaction=>'Save');
is($s->Run(),'denied','nonadmin cannot pair local identities');is($writes,0,'nonadmin cannot mutate');
$admin=1;is($s->Run(),'error','GET cannot save pairing');$method='POST';$params{ChallengeToken}='bad';is($s->Run(),'error','CSRF prevents pairing');is($writes,0,'invalid token caused no writes');
$params{ChallengeToken}='csrf';$params{CustomerUserID}='person';is($s->Run(),'page','protected POST saves pairing');is($writes,1,'protected action dispatches once');
$s->{Subaction}='';delete $params{CustomerUserID};is($s->Run(),'page','empty page renders');ok(!$captured->{View},'empty page does not manufacture a selected customer');
my $tt=Template->new(INCLUDE_PATH=>'Kernel/Package/GovernanceDB/Kernel/Output/HTML/Templates/Standard');my $html='';
ok($tt->process('AgentTESSERALocalIdentity.tt',{Data=>{SubjectLabel=>'<script>marker</script>',CustomerUserID=>'person',View=>{Subject=>{},RoutingReady=>0},Groups=>[],Roles=>[]},Env=>sub {'/index.pl'}},\$html),'linked identity template renders');
unlike($html,qr/<script>marker/,'identity names escaped');like($html,qr/This customer also has agent access/,'explicit agent checkbox present');like($html,qr/name="ChallengeToken"/,'mutating form protected');like($html,qr/type="submit" disabled/,'save disabled until router ready');
done_testing;
