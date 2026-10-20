package Kernel::Modules::AgentTESSERANewSetup;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new { my ($Type,%P)=@_; bless \%P,$Type }
sub Run {
    my ($Self)=@_;
    my $Layout=$Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Request=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $Setup=$Kernel::OM->Get('Kernel::System::TESSERA::NewSetup');
    return $Layout->NoPermission(WithHeader=>1) if !$Setup->Authorized(UserID=>$Self->{UserID});
    my ($Message,$State);
    my $Sub=$Self->{Subaction} || '';
    if ($Sub ne '') {
        return $Layout->ErrorScreen(Message=>'Unknown setup action.') if $Sub !~ /\A(?:Save|Complete)\z/;
        return $Layout->ErrorScreen(Message=>'Submit the setup form using POST.') if $Request->RequestMethod() ne 'POST';
        my $Token=$Request->GetParam(Param=>'ChallengeToken') || '';
        return $Layout->ErrorScreen(Message=>'Invalid setup request token.')
            if !$Token || !$Layout->{UserChallengeToken} || $Token ne $Layout->{UserChallengeToken};
        return $Layout->ErrorScreen(Message=>'Invalid setup request token.') if !$Layout->ChallengeTokenCheck();
        my $OK=eval {
            if ($Sub eq 'Save') {
                $Setup->SaveOrganization(UserID=>$Self->{UserID}, map {$_=>$Request->GetParam(Param=>$_)} qw(Name Description RequestKey));
            }
            else { $Setup->Complete(UserID=>$Self->{UserID}); }
            1;
        };
        if ($OK) { return $Layout->Redirect(OP=>'Action=AgentTESSERANewSetup'); }
        $Message='Could not save setup. Check the name and description, or contact your administrator.';
        $Kernel::OM->Get('Kernel::System::Log')->Log(Priority=>'error',Message=>'TESSERA organization setup failed: '.$@);
    }
    $State=eval {$Setup->Progress(UserID=>$Self->{UserID})};
    return $Layout->ErrorScreen(Message=>'Setup storage is unavailable. Complete the package installation first.') if !$State;
    return $Layout->Header(Title=>'TESSERA New setup').$Layout->NavigationBar()
        .$Layout->Output(TemplateFile=>'AgentTESSERANewSetup',Data=>{
            State=>$State, Message=>$Message,
            Name=>$Message ? $Request->GetParam(Param=>'Name') : '',
            Description=>$Message ? $Request->GetParam(Param=>'Description') : '',
            RequestKey=>$Message ? $Request->GetParam(Param=>'RequestKey') : $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>32),
        }).$Layout->Footer();
}
1;
