use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Storable qw(dclone);
use Template;
use lib '.', 'Custom', 'Kernel/Package/GovernanceDB';
use Kernel::System::TESSERA::NetworkSimulationAccess;
use Kernel::Modules::AgentNetworkSimulationAccess;
{
    package AccessOM;
    sub Get {my ($S,$Name)=@_;return $S->{Backend} if $Name eq 'Kernel::System::TESSERA::NetworkSimulationAccess';return $S}
    sub GetUserData {return (ValidID=>1)}
    sub PermissionCheck {my ($S,%P)=@_;return $P{UserID}==7}
    sub SettingGet {my ($S,%P)=@_;my $Key=$P{Name};$Key=~s/^.*:://;return if !exists $S->{Values}{$Key};return (EffectiveValue=>dclone_value($S->{Values}{$Key}))}
    sub GlobalEffectiveValueGet {my ($S,%P)=@_;my $Key=$P{SettingName};$Key=~s/^.*:://;return $S->{Override}? 'override':dclone_value($S->{Values}{$Key})}
    sub dclone_value {ref $_[0]?Storable::dclone($_[0]):$_[0]}
    sub SettingsSet {
        my ($S,%P)=@_;push @{$S->{Deployments}},Storable::dclone(\%P);my $N=@{$S->{Deployments}};
        for my $Setting (@{$P{Settings}}) {my $Key=$Setting->{Name};$Key=~s/^.*:://;next if $S->{PartialAt} && $N==$S->{PartialAt} && $Key eq 'Bindings';$S->{Values}{$Key}=dclone_value($Setting->{EffectiveValue})}
        return 1;
    }
    sub Prepare {return 1}
    sub FetchrowArray {return (1)}
    sub GovernanceObjectSearch {return (10,20)}
    sub GovernanceObjectGet {my ($S,%P)=@_;return {GovernanceObjectID=>$P{GovernanceObjectID},Name=>$P{GovernanceObjectID}==10?'PROD':'UAT',Class=>'Environment',ZTSMStatus=>'Active'}}
    sub WebserviceList {return {12=>'Navis',13=>'Generic'}}
    sub WebserviceGet {my ($S,%P)=@_;return {ID=>$P{ID},Name=>$P{ID}==12?'Navis':'Generic',ValidID=>1,Config=>{Requester=>{Transport=>{Type=>'HTTP::TESSERAIntegration',Config=>{Preset=>$P{ID}==12?'Navis':'Generic'}}}}}}
    sub CustomerUserDataGet {my ($S,%P)=@_;return (ValidID=>1,UserLogin=>$P{User}) if $P{User} eq 'alice' || $P{User} eq 'bob';return}
    sub CustomerHasCMDBReadRole {my ($S,%P)=@_;return $P{CustomerUserID} eq 'alice'}
    sub NoPermission {'DENIED'}
    sub RequestMethod {$_[0]{Method} || 'GET'}
    sub GetParam {my ($S,%P)=@_;return $S->{Params}{$P{Param}}}
    sub ChallengeTokenCheck {$_[0]{ChallengeOK}}
    sub ErrorScreen {my ($S,%P)=@_;return $P{Message}}
}
my $OM=bless {Values=>{Enabled=>0,AllowedCustomerUsers=>[],Bindings=>'{}'},Deployments=>[],Params=>{},UserChallengeToken=>'real',ChallengeOK=>1},'AccessOM';
local $Kernel::OM=$OM;my $B=Kernel::System::TESSERA::NetworkSimulationAccess->new();$OM->{Backend}=$B;
ok(!eval {$B->View(UserID=>8);1},'backend read requires active administrator');
my $V=$B->View(UserID=>7);is(scalar @{$V->{Environments}},2,'administrator sees active environment choices');
is_deeply([map {$_->{ID}} @{$V->{Services}}],[12],'only enabled Navis integrations are selectable');
my $Binding={10=>{WebserviceID=>12,BuildID=>'20000000-0000-4000-8000-000000000001',Namespace=>'CMDB'}};
ok($B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>['alice','alice'],Bindings=>$Binding),'administrator configures access and bindings');
is($OM->{Values}{Enabled},1,'simulation enabled after complete deployment');is_deeply($OM->{Values}{AllowedCustomerUsers},['alice'],'duplicate accounts deduplicated');
is_deeply(JSON::PP->new->decode($OM->{Values}{Bindings}),$Binding,'native SysConfig stores existing binding contract');
is($OM->{Deployments}[0]{Settings}[0]{EffectiveValue},0,'first deployment disables simulation');
is($OM->{Deployments}[-1]{Settings}[0]{EffectiveValue},1,'last deployment enables simulation');
for my $D (@{$OM->{Deployments}}) {ok(!grep({$_->{Name}!~/\ATESSERA::CustomerNetworkSimulation::(?:Enabled|AllowedCustomerUsers|Bindings)\z/} @{$D->{Settings}}),'deployment touches only simulation settings')}
ok(!eval {$B->Save(UserID=>8,Revision=>$V->{Revision},Enabled=>1,Users=>['alice'],Bindings=>$Binding);1},'non-admin cannot grant simulation access');
my $Before=@{$OM->{Deployments}};
ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>['bob'],Bindings=>$Binding);1},'stale edit cannot overwrite grants');is(scalar @{$OM->{Deployments}},$Before,'stale edit makes no changes');
$V=$B->View(UserID=>7);
for my $Users (['missing'],['*'],["alice\nbob"]) {ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>$Users,Bindings=>$Binding);1},'invalid/inactive/wildcard account rejected')}
ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>['alice'],Bindings=>{});1},'cannot enable without an environment binding');
my $Bad=dclone($Binding);$Bad->{10}{WebserviceID}=13;
ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>['alice'],Bindings=>$Bad);1},'generic service cannot masquerade as Navis');
$Bad=dclone($Binding);$Bad->{10}{BuildID}='not-a-uuid';
ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>['alice'],Bindings=>$Bad);1},'invalid completed build reference rejected');
$OM->{Override}=1;ok($B->View(UserID=>7)->{HasOverrides},'configuration override visible to administrator');
ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>['alice'],Bindings=>$Binding);1},'configuration-file override cannot be silently bypassed');$OM->{Override}=0;
$OM->{Deployments}=[];$OM->{PartialAt}=2;
my $Changed=dclone($Binding);$Changed->{10}{Namespace}='NEW-NAMESPACE';
ok(!eval {$B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>1,Users=>['bob'],Bindings=>$Changed);1},'partially successful native deployment detected');
is($OM->{Values}{Enabled},0,'partial deployment remains disabled');
$OM->{PartialAt}=0;$OM->{Deployments}=[];$V=$B->View(UserID=>7);
ok($B->Save(UserID=>7,Revision=>$V->{Revision},Enabled=>0,Users=>[],Bindings=>$Binding),'administrator can revoke all listed accounts');
is_deeply($OM->{Values}{AllowedCustomerUsers},[],'revocation stored without changing CMDB assignments');
my $Page=Kernel::Modules::AgentNetworkSimulationAccess->new(UserID=>7,Subaction=>'Save');
like($Page->Run(),qr/protected POST/,'UI rejects GET mutation');$OM->{Method}='POST';$OM->{Params}{ChallengeToken}='wrong';
like($Page->Run(),qr/protected POST/,'UI rejects CSRF mismatch');$OM->{Params}{ChallengeToken}='real';$OM->{ChallengeOK}=0;
like($Page->Run(),qr/Invalid request token/,'native challenge check required');
is(Kernel::Modules::AgentNetworkSimulationAccess->new(UserID=>8)->Run(),'DENIED','agent screen independently checks authority');
my $HTML='';my $TT=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard');
ok($TT->process('AgentNetworkSimulationAccess.tt',{Data=>{%{$B->View(UserID=>7)},UsersText=>'<script>bad</script>'},Env=>sub {'/index.pl'}},\$HTML),'dedicated access screen renders');
like($HTML,qr/Caller namespace/,'environment binding fields discoverable');unlike($HTML,qr/<script>bad/,'account values escaped');
done_testing();
