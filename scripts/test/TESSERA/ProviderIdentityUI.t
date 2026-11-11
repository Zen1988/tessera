use strict;
use warnings;
use Test::More;
use Template;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::Modules::AgentTESSERAAPIIdentity;
{
 package URequest;sub GetParam {return $main::params{$_[2]}}sub RequestMethod {return $main::method}
 package UBackend;
 sub _admin {die 'denied' if !$main::admin}
 sub Save {$main::writes++;return 1}
 sub Issue {$main::writes++;return {APIKey=>'once-token'}}
 sub Get {return {ID=>1,Name=>'<script>marker</script>',CustomerUserID=>'subject',Settings=>{Grants=>[]}}}
 sub List {return []}sub Tokens {return []}
 package ULayout;
 sub NoPermission {return 'denied'}sub ErrorScreen {return 'error'}sub ChallengeTokenCheck {return 1}
 sub Header {return ''}sub NavigationBar {return ''}sub Footer {return ''}
 sub Output {my ($s,%p)=@_;return $p{Data}{NewToken}||'page'}
 package UResponse;sub Header {return 1}
 package UOM;sub Get {my ($s,$n)=@_;return $main::layout if $n eq 'Kernel::Output::HTML::Layout';my %m=('Kernel::System::Web::Request'=>'URequest','Kernel::System::TESSERA::ProviderIdentity'=>'UBackend','Kernel::System::Web::Response'=>'UResponse');return bless {},$m{$n}||die $n}
 package Kernel;our $OM=bless {},'UOM';
}
our ($admin,$method,$writes)=(0,'GET',0);our %params;
our $layout=bless {UserChallengeToken=>'csrf'},'ULayout';
my $s=Kernel::Modules::AgentTESSERAAPIIdentity->new(UserID=>2,Subaction=>'Issue');
is($s->Run(),'denied','nonadmin cannot access token issuance');is($writes,0,'denied request cannot issue token');
$admin=1;$params{ID}=1;
is($s->Run(),'error','GET cannot issue token');is($writes,0,'GET caused no mutation');
$method='POST';$params{ChallengeToken}='wrong';is($s->Run(),'error','incorrect CSRF denied');is($writes,0,'CSRF failure caused no mutation');
$params{ChallengeToken}='csrf';$params{TokenName}='grafana';$params{Days}=30;
is($s->Run(),'once-token','protected POST displays issued token');is($writes,1,'protected POST issues once');
$s->{Subaction}='';is($s->Run(),'page','subsequent GET does not redisplay token');
my $tt=Template->new(INCLUDE_PATH=>'Kernel/Package/GovernanceDB/Kernel/Output/HTML/Templates/Standard');my $html='';
ok($tt->process('AgentTESSERAAPIIdentity.tt',{Data=>{Name=>'<script>marker</script>',ID=>1,NewToken=>'test-only',Grants=>[],Tokens=>[],Inputs=>[],Identities=>[]},Env=>sub {'/index.pl'}},\$html),'admin template renders');
unlike($html,qr/<script>marker/,'identity text cannot inject markup');like($html,qr/&lt;script&gt;marker/,'identity name escaped');
like($html,qr/name="ChallengeToken"/,'mutation forms contain CSRF token');
done_testing;
