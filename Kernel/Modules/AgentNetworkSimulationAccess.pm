package Kernel::Modules::AgentNetworkSimulationAccess;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $B=$Kernel::OM->Get('Kernel::System::TESSERA::NetworkSimulationAccess');
    return $L->NoPermission(WithHeader=>1) if !$B->Authorized($S->{UserID});
    my $View=eval {$B->View(UserID=>$S->{UserID})};return $L->ErrorScreen(Message=>'Simulation settings are unavailable. Verify package configuration deployment.') if !$View;
    my $Message='';
    if ($S->{Subaction}) {
        return $L->ErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST' || !$L->{UserChallengeToken}
            || ($R->GetParam(Param=>'ChallengeToken') || '') ne $L->{UserChallengeToken};
        return $L->ErrorScreen(Message=>'Invalid request token.') if !$L->ChallengeTokenCheck();
        my $OK=eval {
            die if $S->{Subaction} ne 'Save';my $Text=$R->GetParam(Param=>'Users') || '';die if length($Text)>100000;
            my @Users=grep {length} map {my $V=$_;$V=~s/^\s+|\s+$//g;$V} split /\r?\n/,$Text;
            my %Bindings;
            for my $E (@{$View->{Environments}}) {my $ID=$E->{ID};my $WS=$R->GetParam(Param=>'Webservice_'.$ID) || '';my $Build=$R->GetParam(Param=>'Build_'.$ID) || '';my $NS=$R->GetParam(Param=>'Namespace_'.$ID) || '';
                $Bindings{$ID}={WebserviceID=>$WS,BuildID=>$Build,Namespace=>$NS} if length($WS) || length($Build) || length($NS);}
            $B->Save(UserID=>$S->{UserID},Revision=>$R->GetParam(Param=>'Revision'),Enabled=>$R->GetParam(Param=>'Enabled'),Users=>\@Users,Bindings=>\%Bindings);1;
        };
        return $L->Redirect(OP=>'Action=AgentNetworkSimulationAccess') if $OK;
        $Message='Configuration could not be saved. Check exact active customer logins, complete environment bindings, configuration overrides and concurrent changes. A failed deployment may leave simulation disabled; reload before retrying.';
    }
    return $L->Header(Title=>'Network simulation access').$L->NavigationBar().$L->Output(TemplateFile=>'AgentNetworkSimulationAccess',Data=>{%$View,UsersText=>join("\n",@{$View->{AllowedCustomerUsers}}),Message=>$Message}).$L->Footer();
}
1;
