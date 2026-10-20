package Kernel::Modules::AgentControlObjectiveRun;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my($Type,%P)=@_;bless \%P,$Type}
sub Run {
    my ($Self)=@_;
    my $Request=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $Layout=$Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ID=$Request->GetParam(Param=>'GovernanceObjectID');
    my $Runtime=$Kernel::OM->Get('Kernel::System::TESSERA::ControlRuntime');
    my $Objective=eval {$Runtime->_RunObjectiveGet(GovernanceObjectID=>$ID,UserID=>$Self->{UserID})};
    return $Layout->ErrorScreen(Message=>'Run now requires write access to an Active automatic ControlObjective.') if !$Objective;
    my $Result;
    if (($Self->{Subaction}||'') eq 'Queue') {
        return $Layout->ErrorScreen(Message=>'Use the Run now form to submit a POST request.') if $Request->RequestMethod() ne 'POST';
        $Layout->ChallengeTokenCheck();
        $Result=eval {$Runtime->QueueControlObjective(GovernanceObjectID=>$ID,UserID=>$Self->{UserID})};
        $Result||={Status=>'ERROR',Reason=>substr($@||'Could not queue this run.',0,2000)};
    }
    return $Layout->Header(Type=>'Small',Title=>'Run ControlObjective now')
        .$Layout->Output(TemplateFile=>'AgentControlObjectiveRun',Data=>{
            GovernanceObjectID=>$ID,Name=>$Objective->{Name},Result=>$Result})
        .$Layout->Footer(Type=>'Small');
}
1;
