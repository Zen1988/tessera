use strict;
use warnings;
use Test::More;
use Template;
sub Slurp {my($P)=@_;open my $FH,'<',$P or die $!;return do{local $/;<$FH>};}
my $Source=Slurp('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Layout.pm');
my $Methods='';
for my $Name(qw(_CustomerPortalResponse CustomerError CustomerErrorScreen CustomerWarning CustomerNoPermission CustomerFatalError PublicError PublicErrorScreen PublicFatalError)) {
 $Source =~ /(sub \Q$Name\E \{.*?^\})/ms or die "No $Name";$Methods.=$1."\n";
}
eval 'package PortalResponseMethods;'.$Methods;die $@ if $@;
{
 package PortalResponseMethods;
 sub CustomerHeader {my($S,%P)=@_;$S->{Header}++;$S->{BodyClass}=$P{BodyClass};$Kernel::OM->{Response}{Status}=200;return '<header>PORTAL</header>';}
 sub CustomerFooter {$_[0]{Footer}++;'<footer>END</footer>'}
 sub CustomerNavigationBar {$_[0]{Navigation}++;'<nav>SIDEBAR</nav>'}
 sub Output {my($S,%P)=@_;$S->{LastData}=$P{Data};my $Out='';$S->{TT}->process($P{TemplateFile}.'.tt',{Data=>$P{Data},Translate=>sub{$_[0]},Env=>sub{'/otobo/customer.pl?'}},\$Out) or die $S->{TT}->error();return $Out;}
 sub ApplyOutputFilters {my($S,%P)=@_;$S->{Filtered}++;$P{Output}}
 package PortalResponseOM;
 sub Get {my($S,$N)=@_;return $S->{Response} if $N eq 'Kernel::System::Web::Response';return $S->{Log} if $N eq 'Kernel::System::Log';return $S->{Encode} if $N eq 'Kernel::System::Encode';die "Unexpected dependency $N";}
 package PortalResponseHTTP;
 sub Code {$_[0]{Status}=$_[1]}
 sub Headers {[]}
 package PortalResponseLog;
 sub GetLogEntry {die 'Raw backend log must never be rendered'}
 sub Log {my($S,%P)=@_;push @{$S->{Entries}},\%P;1}
 package PortalResponseEncode;
 sub EncodeOutput {$_[0]{Called}++;1}
 package Plack::Response;
 sub new {my($C,$Status,$Headers,$Body)=@_;bless {Status=>$Status,Headers=>$Headers,Body=>$Body},$C}
 package Kernel::System::Web::Exception;
 sub new {my($C,%P)=@_;bless \%P,$C}
}
local $Kernel::OM=bless {Response=>bless({},'PortalResponseHTTP'),Log=>bless({Entries=>[]},'PortalResponseLog'),Encode=>bless({},'PortalResponseEncode')},'PortalResponseOM';
my $TT=Template->new({INCLUDE_PATH=>'Kernel/Package/GovernanceDB/Kernel/Output/HTML/Templates/Standard'});
my $L=bless {TT=>$TT,UserID=>'customer-id',SessionID=>'private-session',Action=>'CustomerTicketMessage'},'PortalResponseMethods';
my $HTML=$L->CustomerErrorScreen(Message=>'Please choose a service.');
like($HTML,qr/SIDEBAR/,'signed-in full error retains portal navigation');
like($HTML,qr/Please choose a service/,'normal error message preserved');
is($Kernel::OM->{Response}{Status},400,'generic request screen is400 after header rendering');
unlike($HTML,qr/security review|attempt has been recorded|Security check failed/i,'ordinary error is not accused or security audited');
like($L->{BodyClass},qr/ZTSMSecurityResponse/,'full page uses shared responsive shell');
is($L->{Header},1,'one header');is($L->{Footer},1,'one footer');is($L->{Navigation},1,'one sidebar');
$HTML=$L->CustomerNoPermission();
is($Kernel::OM->{Response}{Status},403,'standard permission denial is403');like($HTML,qr/Access unavailable/,'permission message uses common card');
for my $Code(404,503) {$HTML=$L->CustomerErrorScreen(StatusCode=>$Code,Message=>'Resource unavailable.');is($Kernel::OM->{Response}{Status},$Code,'explicit supported status preserved');like($HTML,qr/>$Code</,'visible status matches HTTP status');}
my $Before=$L->{Header};my $Nav=$L->{Navigation};
$HTML=$L->CustomerNoPermission(WithHeader=>'no');
is($L->{Header},$Before,'embedded permission does not duplicate header');is($L->{Navigation},$Nav,'embedded permission does not duplicate navigation');unlike($HTML,qr/id="oooContent"|<main/,'embedded response does not nest page containers');
$Kernel::OM->{Response}{Status}=200;
$HTML=$L->CustomerWarning(Message=>'Please complete the required fields.');
is($Kernel::OM->{Response}{Status},200,'ordinary warning does not turn into HTTP failure');unlike($HTML,qr/class="ZTSMSecurityCode"/,'warning does not invent an HTTP error code');
$HTML=$L->CustomerError(Message=>'<script>evil()</script>',Comment=>'<img src=x onerror=evil()>');
unlike($HTML,qr/<script>|<img /,'ordinary messages/comments escaped');like($HTML,qr/&lt;script&gt;/,'escaped message still useful');
$HTML=$L->CustomerError();unlike($HTML,qr/SECRET|backend log/,'missing message does not use backend diagnostic');
my $Anonymous=bless {TT=>$TT,Action=>'CustomerLogin'},'PortalResponseMethods';
$HTML=$Anonymous->CustomerErrorScreen(Message=>'Sign-in unavailable.');unlike($HTML,qr/SIDEBAR|Signed-in customer ID/,'anonymous response has no authenticated sidebar/identity');like($HTML,qr/Return to sign in/,'anonymous recovery is login');like($Anonymous->{BodyClass},qr/Anonymous/,'anonymous shell does not reserve hidden sidebar space');
eval {$L->CustomerFatalError(Message=>'SECRET database failure SQL password=private')};my $Exception=$@;
is(ref $Exception,'Kernel::System::Web::Exception','fatal preserves PSGI exception contract');
is($Exception->{PlackResponse}{Status},500,'fatal exception uses actual500');
unlike($Exception->{PlackResponse}{Body},qr/SECRET|password=private|SQL/,'fatal backend details hidden');
like($Exception->{PlackResponse}{Body},qr/SIDEBAR/,'authenticated fatal retains theme');
is($L->{Filtered},1,'fatal output filters retained');is($Kernel::OM->{Encode}{Called},1,'fatal byte encoding retained');
like($Kernel::OM->{Log}{Entries}[-1]{Message},qr/SECRET database failure/,'fatal diagnostic remains in backend log');
is($L->CustomerFatalError(),undef,'fatal recursion guard retained');
# No article/ticket/CMDB object exists in this OM: accidental security/evidence writes would fail above.
is(scalar @{$Kernel::OM->{Log}{Entries}},1,'ordinary responses create no attack log');
my $Public=bless {TT=>$TT},'PortalResponseMethods';
$HTML=$Public->PublicErrorScreen(Message=>'Resource unavailable.');
like($HTML,qr/ZTSMSecurityCard/,'legacy public error screen shares response card');
unlike($HTML,qr/SIDEBAR/,'public error screen has no authenticated navigation');
$HTML=$Public->PublicError(Message=>'Please retry.');
unlike($HTML,qr/<header>|<main/,'public fragment remains embedded');
eval {$Public->PublicFatalError(Message=>'SECRET public backend failure')};
my $PublicException=$@;
is($PublicException->{PlackResponse}{Status},500,'public fatal uses actual500');
unlike($PublicException->{PlackResponse}{Body},qr/SECRET|SIDEBAR/,'public fatal keeps diagnostics and authenticated navigation hidden');
$HTML=$L->CustomerErrorScreen(StatusCode=>999);
is($Kernel::OM->{Response}{Status},400,'unsupported requested status falls back to400');
done_testing();
