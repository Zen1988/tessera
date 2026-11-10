package Kernel::Modules::AgentTESSERAIntegration;
use strict;
use warnings;
use JSON::PP ();
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $B=$Kernel::OM->Get('Kernel::System::TESSERA::IntegrationOnboarding');
    return $L->NoPermission(WithHeader=>1) if !$B->Authorized($S->{UserID});
    my $ID=$R->GetParam(Param=>'ID') || '';return $L->ErrorScreen(Message=>'Invalid service identifier.') if $ID && $ID!~/\A[1-9][0-9]*\z/;
    my ($Message,$Name,$Enabled,$C)=('','','',{});
    if ($ID) {my $D=eval {$B->View(UserID=>$S->{UserID},ID=>$ID)};return $L->ErrorScreen(Message=>'Managed connection unavailable.') if !$D;
        ($Name,$Enabled,$C)=($D->{Name},$D->{ValidID}==1,$D->{Config}{Requester}{Transport}{Config});}
    if ($S->{Subaction}) {
        return $L->ErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST'
            || !$L->{UserChallengeToken} || ($R->GetParam(Param=>'ChallengeToken') || '') ne $L->{UserChallengeToken};
        return $L->ErrorScreen(Message=>'Invalid request token.') if !$L->ChallengeTokenCheck();
        my $OK=eval {
            $Name=$R->GetParam(Param=>'Name');$Enabled=$R->GetParam(Param=>'Enabled');
            $C={map {$_=>$R->GetParam(Param=>$_)} qw(Preset Origin InstanceID)};
            $C->{Authentication}={Provider=>'ClientCredentialsBasic',map {$_=>$R->GetParam(Param=>$_)} qw(TokenURL ClientID SecretName)};
            my $Scope=$R->GetParam(Param=>'Scope');$C->{Authentication}{Scope}=$Scope if defined $Scope && length $Scope;
            $C->{Routes}=JSON::PP->new->decode($R->GetParam(Param=>'Routes') || '{}') if $C->{Preset} eq 'Generic';
            if ($S->{Subaction} eq 'Test') {$B->Test(UserID=>$S->{UserID},Connection=>$C);$Message='Authentication succeeded. Application and data readiness still require verification.'}
            elsif ($S->{Subaction} eq 'Save') {$ID=$B->Save(UserID=>$S->{UserID},ID=>$ID,Name=>$Name,Enabled=>$Enabled,Connection=>$C)}
            else {die 'Unknown action'}
            1;
        };
        return $L->Redirect(OP=>'Action=AgentTESSERAIntegration;ID='.$ID) if $OK && $S->{Subaction} eq 'Save';
        $Message='Operation failed. Check the destination, mounted secret, approved scopes and connection name.' if !$OK;
    }
    my @Inputs=map {{Name=>$_,Value=>$C->{$_} || ''}} qw(Origin InstanceID);
    push @Inputs,map {{Name=>$_,Value=>$C->{Authentication}{$_} || ''}} qw(TokenURL ClientID SecretName Scope);
    return $L->Header(Title=>'Integration onboarding').$L->NavigationBar().$L->Output(TemplateFile=>'AgentTESSERAIntegration',Data=>{
        ID=>$ID,Name=>$Name,Enabled=>$Enabled,Preset=>$C->{Preset},Inputs=>\@Inputs,Message=>$Message,
        Routes=>JSON::PP->new->canonical->pretty->encode($C->{Routes} || {}),Connections=>$B->View(UserID=>$S->{UserID}),
    }).$L->Footer();
}
1;
