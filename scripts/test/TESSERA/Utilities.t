use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Template;
use lib '.', 'Custom', 'Kernel/Package/GovernanceDB';
use Kernel::System::TESSERA::Utilities;
use Kernel::Modules::CustomerUtilities;
use Kernel::Modules::AgentUtilities;
{
    package UtilityOM;
    sub Get {
        my ($S,$N)=@_;return $S->{Service} if $N eq 'Kernel::System::TESSERA::Utilities';
        return $S->{Config} if $N eq 'Kernel::Config';return $S;
    }
    sub GetUserData {(ValidID=>1)}
    sub PermissionCheck {$_[1] eq 'UserID' && $_[2]==7}
    sub CustomerUserDataGet {my ($S,%P)=@_;return if $P{User} ne 'alice' && $P{User} ne 'bob';return (ValidID=>1,UserLogin=>$P{User},UserEmail=>'a+b@example.org')}
    sub Prepare {
        my ($S,%P)=@_;$S->{Releases}++ if $P{SQL}=~/RELEASE_LOCK/;
        if ($P{SQL}=~/GET_LOCK|RELEASE_LOCK/) {$S->{Rows}=[[1]]}
        else {$S->{Rows}=defined $S->{Raw}?[[$S->{Raw}]]:[]}
        return 1;
    }
    sub FetchrowArray {my $R=shift @{$_[0]{Rows}};return $R?@$R:()}
    sub Do {my ($S,%P)=@_;return if $S->{FailWrite};$S->{Raw}=${$P{Bind}[$P{SQL}=~/INSERT/?1:0]};$S->{Writes}++;return 1}
    sub GenerateRandomString {sprintf '%064d',++$_[0]{RandomCounter}}
    sub AccessCheck {$_[0]{Read}}
    sub ConfigItemDetailAccessCheck {$_[0]{Read}}
    sub TicketCustomerPermission {$_[0]{TicketRead}}
    sub TicketGet {(TicketNumber=>'T-123')}
    sub ConfigItemGet {{Number=>'CI-99'}}
    sub Launch {my ($S,%P)=@_;return {Action=>$S->{AdapterAction} || 'CustomerCustomTool',Parameters=>$S->{AdapterParams} || {scope=>'permitted'}}}
    sub NoPermission {'DENIED'}
    sub CustomerNoPermission {'DENIED'}
    sub ErrorScreen {my ($S,%P)=@_;$P{Message}}
    sub CustomerErrorScreen {my ($S,%P)=@_;$P{Message}}
    sub RequestMethod {$_[0]{Method} || 'GET'}
    sub GetParam {my ($S,%P)=@_;$S->{Params}{$P{Param}}}
    sub ChallengeTokenCheck {$_[0]{ChallengeOK}}
    sub GetUploadAll {()}
    sub Redirect {my ($S,%P)=@_;return $P{OP} || $P{ExtURL}}
    sub Header {''} sub CustomerHeader {''} sub NavigationBar {''} sub CustomerNavigationBar {''} sub Footer {''} sub CustomerFooter {''}
    sub Output {'PAGE'}
    package UtilityConfig;
    sub Get {$_[0]{$_[1]}}
}
my $Config=bless {
    'CustomerFrontend::Module'=>{CustomerTicketSearch=>{},CustomerNetworkSimulation=>{}},
    'CustomerDashboard::Tiles'=>{'ToolBox-01'=>{Module=>'Kernel::Output::HTML::CustomerDashboard::TileToolBox',Config=>{Links=>{'https://vault.example.org/'=>1},Titles=>{Vault=>1},Images=>{'/otobo-web/img/vault.png'=>1}}}},
},'UtilityConfig';
local $Kernel::OM=bless {Config=>$Config,Params=>{},UserChallengeToken=>'real',ChallengeOK=>1,Read=>1},'UtilityOM';
$Config->{'CustomerDashboard::Tiles'}{'ToolBox-Vendor'}={Module=>'Kernel::Output::HTML::CustomerDashboard::TileToolBox',Config=>{Links=>{'https://www.otobo.io'=>1,'https://www.openstreetmap.org'=>2,'https://www.wikipedia.org'=>3},Titles=>{OTOBO=>1,OpenStreetMap=>2,Wikipedia=>3},Images=>{'/img/sample_otobo.png'=>1,'/img/sample_openstreetmap.png'=>2,'/img/sample_wikipedia.png'=>3}}};
my $OM=$Kernel::OM;my $B=Kernel::System::TESSERA::Utilities->new();$OM->{Service}=$B;
ok(!eval {$B->AdminView(UserID=>8);1},'non-admin cannot read catalogue administration');
my $V=$B->AdminView(UserID=>7);
is(scalar @{$V->{Tools}},3,'built-ins and administrator link imported, vendor samples omitted');
is($OM->{Writes} || 0,0,'first view does not persist or duplicate defaults');
is($B->AdminView(UserID=>7)->{Revision},$V->{Revision},'first-save revision stable');
is_deeply($B->List(CustomerUserID=>'missing'),[],'invalid customer denied');
is(scalar @{$B->List(CustomerUserID=>'alice')},3,'active customer sees authorized tools');
is(scalar @{$B->List(CustomerUserID=>'alice',Workplace=>1)},1,'Workplace only returns chosen shortcuts');
my ($Legacy)=grep {$_->{ID}=~/legacy/} @{$V->{Tools}};
is($Legacy->{LegacyIcon},'/otobo-web/img/vault.png','administrator icon reference preserved');
$OM->{Read}=0;
is(scalar @{$B->List(CustomerUserID=>'alice')},2,'network tool hidden without existing CMDB read');
ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>'network-simulation');1},'direct launch cannot bypass native CMDB permission');
$OM->{Read}=1;
is($B->Launch(CustomerUserID=>'alice',ID=>'ticket-search')->{OP},'Action=CustomerTicketSearch','built-in launches existing search');
my $R={Name=>'CyberArk',Description=>'Vault',Type=>'External',URL=>'https://vault.example.org/login?region=sg',Audience=>'users',Users=>['alice'],Enabled=>1,Workplace=>1,Order=>30,Parameters=>{username=>{Source=>'CustomerUserEmail',Required=>1}}};
ok(!eval {$B->Save(UserID=>8,Revision=>$V->{Revision},Tool=>$R);1},'non-admin cannot save');
my $ID=$B->Save(UserID=>7,Revision=>$V->{Revision},Tool=>$R);
like($ID,qr/^tool-[a-f0-9]{32}$/,'new stable server-generated ID');
is($OM->{Writes},1,'first save persists one record');
my $Dest=$B->Launch(CustomerUserID=>'alice',ID=>$ID);
like($Dest->{URL},qr/username=a%2Bb%40example.org/,'customer email is URL encoded');
like($Dest->{URL},qr/region=sg/,'static query retained');
ok(!eval {$B->Launch(CustomerUserID=>'bob',ID=>$ID);1},'cross-customer direct launch denied');
ok(!grep({$_->{ID} eq $ID} @{$B->List(CustomerUserID=>'bob')}),'catalogue and launch share audience checks');
ok(!eval {$B->Icon(CustomerUserID=>'bob',ID=>$ID);1},'icon lookup does not disclose hidden tools');
ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Tool=>$R);1},'concurrent stale edit denied');
is($OM->{Writes},1,'stale edit does not write');
for my $URL ('javascript:alert(1)','http://vault.example.org','https://a:b@vault.example.org','https://vault.example.org/?access_token=abc','https://vault.example.org/#script',"https://vault.example.org/\n") {
    my %Bad=(%$R,URL=>$URL);ok(!eval {$B->_validate(\%Bad);1},'unsafe destination rejected');
}
for my $Users (['*'],['missing']) {my %Bad=(%$R,Users=>$Users);ok(!eval {$B->_validate(\%Bad);1},'wildcard or inactive audience denied')}
my %Bad=(%$R,Parameters=>{password=>{Source=>'CustomerUserLogin'}});ok(!eval {$B->_validate(\%Bad);1},'credential-named parameter denied');
%Bad=(%$R,Parameters=>{x=>{Source=>'ArbitraryRequestParameter'}});ok(!eval {$B->_validate(\%Bad);1},'arbitrary request substitution denied');
ok(!eval {$B->_icon('<svg onload="alert(1)"/>');1},'active SVG upload rejected');
ok(!eval {$B->_icon('x'x262145);1},'oversized upload rejected before decoding');
require GD;my $Image=GD::Image->newTrueColor(24,16);my $Icon=$B->_icon($Image->png);
like($Icon,qr/\AiVBOR/,'real PNG decoded and normalized');
my $Now=$B->AdminView(UserID=>7);$R->{ID}=$ID;$R->{Parameters}={ticket=>{Source=>'TicketNumber',Required=>1}};
$B->Save(UserID=>7,Revision=>$Now->{Revision},Tool=>$R,IconContent=>$Image->png);
ok($B->Icon(CustomerUserID=>'alice',ID=>$ID),'saved icon can be read by authorized customer');
ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$ID);1},'missing required ticket context denied');
ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$ID,TicketID=>123);1},'knowing ticket ID does not grant context');
$OM->{TicketRead}=1;
like($B->Launch(CustomerUserID=>'alice',ID=>$ID,TicketID=>123)->{URL},qr/ticket=T-123/,'live readable ticket supplies ticket number');
ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$ID,TicketID=>'123;Action=x');1},'malformed object selector denied');
$Now=$B->AdminView(UserID=>7);$R->{Parameters}={asset=>{Source=>'ConfigItemNumber',Required=>1}};$B->Save(UserID=>7,Revision=>$Now->{Revision},Tool=>$R);
$OM->{Read}=0;ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$ID,ConfigItemID=>99);1},'asset context requires full detail entitlement');
$OM->{Read}=1;like($B->Launch(CustomerUserID=>'alice',ID=>$ID,ConfigItemID=>99)->{URL},qr/asset=CI-99/,'entitled asset supplies native number');
$Now=$B->AdminView(UserID=>7);$R->{Enabled}=0;$B->Save(UserID=>7,Revision=>$Now->{Revision},Tool=>$R);
ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$ID);1},'revocation takes effect on next request without worker cache');
ok(!eval {$B->Icon(CustomerUserID=>'alice',ID=>$ID);1},'revoked tool icon denied');
is(scalar @{$B->AdminView(UserID=>7)->{Tools}},4,'edits and retries do not duplicate built-ins or tools');
$Now=$B->AdminView(UserID=>7);my %Builtin=(%{$Now->{Tools}[0]},Type=>'External',URL=>'https://vault.example.org/');
ok(!eval {$B->Save(UserID=>7,Revision=>$Now->{Revision},Tool=>\%Builtin);1},'built-in handler cannot be replaced with external destination');
$OM->{Params}={Subaction=>'Save'};
like(Kernel::Modules::AgentUtilities->new(UserID=>7)->Run(),qr/protected POST/,'GET administration mutation rejected');
$OM->{Method}='POST';$OM->{Params}{ChallengeToken}='wrong';
like(Kernel::Modules::AgentUtilities->new(UserID=>7)->Run(),qr/protected POST/,'CSRF mismatch rejected');
is(Kernel::Modules::AgentUtilities->new(UserID=>8)->Run(),'DENIED','admin controller independently enforces authority');
$OM->{Params}={Subaction=>'Launch',ID=>$ID};
like(Kernel::Modules::CustomerUtilities->new(UserID=>'bob')->Run(),qr/unavailable/,'customer controller denies forged direct launch');
$OM->{Method}='POST';$OM->{Params}={Subaction=>'Preview',ID=>'ticket-search',CustomerLogin=>'alice',ChallengeToken=>'real'};
is(Kernel::Modules::AgentUtilities->new(UserID=>7)->Run(),'PAGE','protected admin access and launch preview renders without external request');
$OM->{Params}={Subaction=>'Launch',ID=>'ticket-search'};
is(Kernel::Modules::CustomerUtilities->new(UserID=>'alice')->Run(),'Action=CustomerTicketSearch','customer controller launches registered native search');
my $BeforeRaw=$OM->{Raw};$OM->{Raw}='not-json';
ok(!eval {$B->List(CustomerUserID=>'alice');1},'corrupt persisted catalogue denies instead of broad defaults');$OM->{Raw}=$BeforeRaw;
$Now=$B->AdminView(UserID=>7);my $Releases=$OM->{Releases};$OM->{FailWrite}=1;
ok(!eval {$B->Save(UserID=>7,Revision=>$Now->{Revision},Tool=>$R);1},'database write failure is reported');
is($OM->{Raw},$BeforeRaw,'failed single-record write preserves catalogue');
is($OM->{Releases},$Releases+1,'failed write releases advisory lock');$OM->{FailWrite}=0;
$Config->{'TESSERA::Utilities::Handlers'}={CustomTool=>{Name=>'Installed tool',Module=>'Kernel::System::Example::UtilityAdapter'},Invalid=>{Module=>'shell;bad'},TicketSearch=>{Module=>'Kernel::System::Evil'}};
ok(!exists $B->Handlers()->{Invalid},'unregistered executable expressions rejected');
ok(!exists $B->Handlers()->{TicketSearch}{Module},'extension cannot override built-in registration');
my $Custom={Name=>'Installed extension',Description=>'Custom internal page',Type=>'Internal',Handler=>'CustomTool',Audience=>'users',Users=>['alice'],Enabled=>1,Workplace=>1,Order=>40,Parameters=>{}};
$Now=$B->AdminView(UserID=>7);my $CustomID=$B->Save(UserID=>7,Revision=>$Now->{Revision},Tool=>$Custom);
$Config->{'CustomerFrontend::Module'}{CustomerCustomTool}={Title=>'Custom tool'};
like($B->Launch(CustomerUserID=>'alice',ID=>$CustomID)->{OP},qr/Action=CustomerCustomTool/,'registered installed extension supplies a customer entry screen');
$OM->{Read}=0;ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$CustomID);1},'adapter access check is required on direct launch');$OM->{Read}=1;
$OM->{AdapterParams}={UserID=>1};ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$CustomID);1},'adapter cannot substitute reserved identity');delete $OM->{AdapterParams};
$OM->{AdapterAction}='AgentTicketZoom';ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$CustomID);1},'adapter cannot route into agent module');delete $OM->{AdapterAction};
delete $Config->{'TESSERA::Utilities::Handlers'}{CustomTool};
ok(!eval {$B->Launch(CustomerUserID=>'alice',ID=>$CustomID);1},'removed extension registration denies saved tool');
my $TT=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard');
for my $Name ('CustomerUtilities','AgentUtilities','TESSERAUtilitiesShortcuts') {
    my $HTML='';ok($TT->process($Name.'.tt',{Data=>{Tools=>[{ID=>'safe',Name=>'<script>bad</script>',Description=>'<img onerror=x>',External=>1}],Tool=>$R,ParametersText=>'{}',Handlers=>[]},Env=>sub {'/customer.pl?'}},\$HTML),$Name.' template renders') or diag $TT->error;
    unlike($HTML,qr/<script>bad|<img onerror/,$Name.' escapes labels');
}
for my $Link ('Action=CustomerTicketSearch','Action=CustomerNetworkSimulation','Action=CustomerUtilities') {
 my $HTML='';ok($TT->process('CustomerNavigationBar.tt',{Config=>sub {{CustomerUtilities=>{Title=>'Utilities'}}},Env=>sub {''},Translate=>sub {$_[0]},RenderBlockStart=>sub {''},RenderBlockEnd=>sub {''},Data=>{Link=>$Link}},\$HTML),'navigation template compiles');
 if ($Link eq 'Action=CustomerUtilities') {like($HTML,qr/Action=CustomerUtilities/,'Utilities navigation retained')}
 else {unlike($HTML,qr/\Q$Link\E/,'individual tool removed from sidebar')}
}
done_testing();
