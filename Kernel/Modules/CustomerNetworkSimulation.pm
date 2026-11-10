package Kernel::Modules::CustomerNetworkSimulation;
use strict;
use warnings;
use JSON::PP ();
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $B=$Kernel::OM->Get('Kernel::System::TESSERA::CustomerNetworkSimulation');
    return $L->CustomerNoPermission(WithHeader=>'yes') if !$B->AccessCheck(CustomerUserID=>$S->{UserID});
    my %Selection=map {$_=>$R->GetParam(Param=>$_) || ''} qw(EnvironmentID SourceApplication SourceSystem SourceEndpoint DestinationApplication DestinationSystem DestinationEndpoint Protocol DestinationPort);
    $Selection{Protocol} ||= 'tcp';$Selection{DestinationPort}='443' if $R->RequestMethod() eq 'GET' && !length $Selection{DestinationPort} && $Selection{Protocol} eq 'tcp';
    my ($M,$Result,$Error);my $Sub=$R->GetParam(Param=>'Subaction') || '';
    if ($Sub eq 'Analyze' || $Sub eq 'Refresh') {
        return $L->CustomerErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST'
            || !$L->{UserChallengeToken} || ($R->GetParam(Param=>'ChallengeToken') || '') ne $L->{UserChallengeToken};
        return $L->CustomerErrorScreen(Message=>'Invalid request token.') if !$L->ChallengeTokenCheck();
        my $ID;my $OK=eval {
            $ID=$Sub eq 'Analyze'?$B->Analyze(CustomerUserID=>$S->{UserID},%Selection,SubmissionToken=>$R->GetParam(Param=>'SubmissionToken'))
                :$B->Refresh(CustomerUserID=>$S->{UserID},AnalysisID=>$R->GetParam(Param=>'AnalysisID'));
            1;
        };
        return $L->Redirect(OP=>'Action=CustomerNetworkSimulation;AnalysisID='.$ID) if $OK;
        $Error='Simulation could not complete. Check your permitted endpoints and environment, or wait before another request. An uncertain analysis is never automatically repeated.';
    } elsif ($Sub && $Sub ne 'Resolve') {
        return $L->CustomerErrorScreen(Message=>'Unknown workspace action.');
    }
    my $AnalysisID=$R->GetParam(Param=>'AnalysisID') || '';
    if ($AnalysisID && !$Error) {
        my $D=eval {$B->Result(CustomerUserID=>$S->{UserID},AnalysisID=>$AnalysisID)};
        return $L->CustomerNoPermission(WithHeader=>'yes') if !$D;
        ($M,$Result)=@$D{qw(Model Result)};
        $Selection{SourceEndpoint}=$Result->{Source}{Key};$Selection{DestinationEndpoint}=$Result->{Destination}{Key};
        $Selection{SourceSystem}=$Result->{Source}{AssetID};$Selection{DestinationSystem}=$Result->{Destination}{AssetID};
        $Selection{SourceApplication}=$Result->{Source}{ApplicationID};$Selection{DestinationApplication}=$Result->{Destination}{ApplicationID};
        $Selection{Protocol}=$Result->{Protocol};$Selection{DestinationPort}=$Result->{DestinationPort} // '';
    }
    $M ||= eval {$B->Model(CustomerUserID=>$S->{UserID},EnvironmentID=>$Selection{EnvironmentID})};
    return $L->CustomerErrorScreen(Message=>'The network workspace model is unavailable. Select a valid environment or contact your administrator.') if !$M;
    my $Payload=JSON::PP->new->canonical->encode({Assets=>$M->{Assets},Result=>$Result,Selection=>\%Selection});
    $Payload=~s/</\\u003c/g;$Payload=~s/>/\\u003e/g;$Payload=~s/&/\\u0026/g;$Payload=~s/\x{2028}/\\u2028/g;$Payload=~s/\x{2029}/\\u2029/g;
    my $Token=$Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>40);
    return $L->CustomerHeader(Title=>'Network simulation').$L->CustomerNavigationBar().$L->Output(TemplateFile=>'CustomerNetworkSimulation',Data=>{
        %$M,Selection=>\%Selection,Result=>$Result,Error=>$Error,Payload=>$Payload,SubmissionToken=>$Token,
    }).$L->CustomerFooter();
}
1;
