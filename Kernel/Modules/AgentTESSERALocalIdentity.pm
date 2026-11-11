package Kernel::Modules::AgentTESSERALocalIdentity;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;return bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $B=$Kernel::OM->Get('Kernel::System::TESSERA::LocalIdentity');
    return $L->NoPermission(WithHeader=>1) if !eval {$B->_admin($S->{UserID});1};
    my $Login=$R->GetParam(Param=>'CustomerUserID')||'';my ($View,$Message);
    if (($S->{Subaction}||'') eq 'Save') {
        return $L->ErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST'
            || !$L->{UserChallengeToken} || ($R->GetParam(Param=>'ChallengeToken')||'') ne $L->{UserChallengeToken};
        return $L->ErrorScreen(Message=>'Invalid request token.') if !$L->ChallengeTokenCheck();
        my @Groups=$R->GetArray(Param=>'GroupIDs');my @Roles=$R->GetArray(Param=>'RoleIDs');
        my $OK=eval {$B->Configure(UserID=>$S->{UserID},CustomerUserID=>$Login,Enabled=>$R->GetParam(Param=>'AgentEnabled'),Groups=>\@Groups,Roles=>\@Roles,
            ConfirmExisting=>$R->GetParam(Param=>'ConfirmExisting'),ExistingAgentID=>$R->GetParam(Param=>'ExistingAgentID'));1};
        $Message=$OK?'Linked agent access saved. The customer record remains the password and profile source.':'Could not save. Check routing readiness, local account validity, explicit grants and existing-agent confirmation.';
    }
    elsif ($S->{Subaction}) {return $L->ErrorScreen(Message=>'Unknown action.')}
    $View=eval {$B->View(UserID=>$S->{UserID},CustomerUserID=>$Login)} if length $Login;
    $Message='Select an existing primary local DB customer. AD/OIDC identities are not supported in this local test flow.' if length($Login) && !$View;
    my $Group=$Kernel::OM->Get('Kernel::System::Group');my %Groups=$Group->GroupList(Valid=>1);my %Roles=$Group->RoleList(Valid=>1);
    my $Managed=$View && $View->{Link} ? $View->{Link}{Managed} : {};
    my %SelectedGroups=map {$_=>1} @{$Managed->{Groups}||[]};my %SelectedRoles=map {$_=>1} @{$Managed->{Roles}||[]};
    return $L->Header(Title=>'People and agent access').$L->NavigationBar().$L->Output(TemplateFile=>'AgentTESSERALocalIdentity',Data=>{
        CustomerUserID=>$Login,SubjectLabel=>$View?$Kernel::OM->Get('Kernel::System::TESSERA::ProviderIdentity')->SubjectLabel(UserID=>$S->{UserID},CustomerUserID=>$Login):'',
        View=>$View,Message=>$Message,Groups=>[map {{ID=>$_,Name=>$Groups{$_},Selected=>$SelectedGroups{$_}}} sort {$Groups{$a} cmp $Groups{$b}} keys %Groups],
        Roles=>[map {{ID=>$_,Name=>$Roles{$_},Selected=>$SelectedRoles{$_}}} sort {$Roles{$a} cmp $Roles{$b}} keys %Roles]}).$L->Footer();
}
1;
