use strict;use warnings;use Test::More;use JSON::PP;use Template;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::SessionGreeting;
{package GreetingOM;sub Get{my($S,$N)=@_;return $S->{Greeting} if $N eq 'Kernel::System::TESSERA::SessionGreeting';return $S;}sub GetSessionIDData{my($S,%P)=@_;return %{$S->{Sessions}{$P{SessionID}}||{}}}sub UpdateSessionID{my($S,%P)=@_;return if $S->{Fail};$S->{Writes}++;$S->{Sessions}{$P{SessionID}}{$P{Key}}=$P{Value};return 1}sub GetCookie{$_[0]{Cookie}}sub SetCookie{my($S,%P)=@_;$S->{Cookie}=$P{Value};$S->{CookieParams}=\%P;return 1}sub Encode{my($S,%P)=@_;JSON::PP::encode_json($P{Data})}sub Decode{my($S,%P)=@_;JSON::PP::decode_json($P{Data})}}
local $Kernel::OM=bless {Sessions=>{a=>{UserLogin=>'zen'},b=>{UserLogin=>'other'},c=>{UserLogin=>'zen'}},Writes=>0},'GreetingOM';
my $G=Kernel::System::TESSERA::SessionGreeting->new();is_deeply($G->Read(SessionID=>'a',UserLogin=>'zen'),{},'fresh login no choice');
my $D=$G->Select(SessionID=>'a',UserLogin=>'zen',Mood=>4);is($D->{Mood},4,'mood saved only to login session');ok($D->{Message},'random message chosen');is_deeply($G->Select(SessionID=>'a',UserLogin=>'zen',Mood=>1),$D,'choice and message stable until session ends');is($Kernel::OM->{Writes},1,'no repeated write');is_deeply($G->Read(SessionID=>'a',UserLogin=>'other'),{},'other customer cannot read choice');ok(!$G->Select(SessionID=>'b',UserLogin=>'zen',Mood=>1),'cannot write foreign session');
for my $Mood (0,6,'bad',undef){ok(!$G->Select(SessionID=>'c',UserLogin=>'zen',Mood=>$Mood),'invalid scale rejected')}
is_deeply($G->Read(SessionID=>'c',UserLogin=>'zen'),{},'new login asks anew');delete $Kernel::OM->{Sessions}{a};is_deeply($G->Read(SessionID=>'a',UserLogin=>'zen'),{},'expired login has no stored greeting');
$Kernel::OM->{Fail}=1;ok(!$G->Select(SessionID=>'c',UserLogin=>'zen',Mood=>3),'failed write not acknowledged');$Kernel::OM->{Fail}=0;
my $Low=$G->Select(SessionID=>'c',UserLogin=>'zen',Mood=>1);like($Low->{Message},qr/support|trust|peer|care|pause|figure|reach|small step/,'low mood gets supportive language');
open my $FH,'<:encoding(UTF-8)','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerDashboard.tt' or die $!;my $Source=do{local $/;<$FH>};my $TT=Template->new();my $Out='';my $V={Data=>{Name=>'<Zen>',Greeting=>{},GreetingToken=>'csrf',TileHTML=>'WORKSPACE'},Translate=>sub{$_[0]},Env=>sub{'/otobo/customer.pl?'}};
ok($TT->process(\$Source,$V,\$Out),'fresh session template renders');is(scalar(()=$Out=~/name="Mood"/g),5,'five labelled emoji choices');like($Out,qr/&lt;Zen&gt;/,'name escaped');like($Out,qr/WORKSPACE/,'nonblocking workspace retained');unlike($Out,qr/>Skip</,'no skip button');like($Out,qr/name="ChallengeToken" value="csrf"/,'native CSRF token in form');
$Out='';$V->{Data}{Greeting}=$D;ok($TT->process(\$Source,$V,\$Out),'selected session renders');unlike($Out,qr/id="TESSERASessionGreeting"/,'selection suppresses repeat prompt');use Kernel::Modules::CustomerDashboardCommon;
{package GreetingOM;sub ChallengeTokenCheck{$_[0]{CSRF}++;die 'CSRF rejected' if $_[0]{RejectCSRF};return 1;}sub RequestMethod{$_[0]{Method}||'POST'}sub GetParam{3}sub Attachment{my($S,%P)=@_;return $P{Content}}}
$Kernel::OM->{Greeting}=$G;my $Controller=Kernel::Modules::CustomerDashboardCommon->new(Subaction=>'SetSessionMood',SessionID=>'b',UserLogin=>'other');my $Reply=JSON::PP::decode_json($Controller->Run());ok($Reply->{Success},'authenticated POST route succeeds');is($Kernel::OM->{CSRF},1,'route enforces customer challenge token');
$Kernel::OM->{RejectCSRF}=1;eval {$Controller->Run()};like($@,qr/CSRF rejected/,'CSRF failure stops route');$Kernel::OM->{RejectCSRF}=0;my $Cookie=$Kernel::OM->{Cookie};
is($Cookie,$G->CompletionToken(SessionID=>'b',UserLogin=>'other'),'response cookie bound to authenticated login');
ok($Kernel::OM->{CookieParams}{HTTPOnly},'dismissal marker HttpOnly');
ok(!exists $Kernel::OM->{CookieParams}{Expires},'session cookie has no persistent expiry');
delete $Kernel::OM->{Sessions}{b}{TESSERASessionGreeting};
is_deeply($G->Read(SessionID=>'b',UserLogin=>'other'),{Completed=>1},'immediate return before backend persistence stays dismissed using response cookie');
is_deeply($G->Read(SessionID=>'c',UserLogin=>'zen'),$Low,'other session retains own stored message');
$Kernel::OM->{Sessions}{d}={UserLogin=>'other'};
is_deeply($G->Read(SessionID=>'d',UserLogin=>'other'),{},'new login ignores prior cookie');
$Out='';$V->{Data}{Greeting}={Completed=>1};ok($TT->process(\$Source,$V,\$Out),'cookie-only completion renders');unlike($Out,qr/id="TESSERASessionGreeting"/,'cookie dismissal suppresses prompt before session data flush');
like($Source,qr/DOMContentLoaded/,'layout binding waits until dashboard exists');like($Source,qr/}, 4000/,'message dismissed after four seconds');
$Kernel::OM->{Method}='GET';$Reply=JSON::PP::decode_json($Controller->Run());ok(!$Reply->{Success},'GET cannot select mood');
done_testing;
