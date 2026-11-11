package Kernel::Modules::AgentTESSERAAPIIdentity;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;return bless \%P,$T}
sub Run {
    my ($S)=@_;
    my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $B=$Kernel::OM->Get('Kernel::System::TESSERA::ProviderIdentity');
    return $L->NoPermission(WithHeader=>1) if !eval {$B->_admin($S->{UserID});1};
    if (($S->{Subaction}||'') eq 'SearchSubjects') {
        my $Results=$B->SubjectSearch(UserID=>$S->{UserID},Term=>$R->GetParam(Param=>'Term'));
        return $L->Attachment(ContentType=>'application/json',Content=>$L->JSONEncode(Data=>$Results),Type=>'inline',NoCache=>1);
    }
    my $ID=$R->GetParam(Param=>'ID')||'';
    return $L->ErrorScreen(Message=>'Invalid API identity.') if $ID && $ID!~/\A[1-9][0-9]{0,11}\z/;
    my ($Message,$NewToken)=('','');
    if ($S->{Subaction}) {
        return $L->ErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST'
            || !$L->{UserChallengeToken} || ($R->GetParam(Param=>'ChallengeToken')||'') ne $L->{UserChallengeToken};
        return $L->ErrorScreen(Message=>'Invalid request token.') if !$L->ChallengeTokenCheck();
        my $OK=eval {
            if ($S->{Subaction} eq 'Save') {
                my @Grants=grep {$R->GetParam(Param=>'Grant_'.$_)} qw(report:tickets report:risks report:alerts ingest:alertmanager);
                my %Settings=(Grants=>\@Grants,map {$_=>$R->GetParam(Param=>$_)||''} qw(SourceName TargetMELTObjectID ActorID));
                for my $F (qw(TicketQueueIDs MELTObjectIDs)) {
                    my $Raw=$R->GetParam(Param=>$F)||'';
                    $Settings{$F}=[grep {length} split /[\s,]+/,$Raw];
                }
                $ID=$B->Save(UserID=>$S->{UserID},ID=>$ID,Name=>$R->GetParam(Param=>'Name'),
                    CustomerUserID=>$R->GetParam(Param=>'CustomerUserID'),Enabled=>$R->GetParam(Param=>'Enabled'),Settings=>\%Settings);
                $Message='API identity saved. Capabilities and scope apply immediately to all its tokens.';
            }
            elsif ($S->{Subaction} eq 'Issue') {
                my $T=$B->Issue(UserID=>$S->{UserID},ID=>$ID,Name=>$R->GetParam(Param=>'TokenName'),Days=>$R->GetParam(Param=>'Days'));
                $NewToken=$T->{APIKey};$Message='Copy this token now. It is displayed once. Refreshing this POST may issue another token.';
            }
            elsif ($S->{Subaction} eq 'Revoke') {
                die 'Revoke failed' if !$B->Revoke(UserID=>$S->{UserID},ID=>$ID,KeyID=>$R->GetParam(Param=>'KeyID'));
                $Message='Token revoked immediately.';
            }
            else {die 'Unknown action'}
            1;
        };
        $Message='Operation failed. Check identity name, existing permission subject, explicit scopes, target and token lifetime.' if !$OK;
    }
    my $I=$ID?eval {$B->Get(UserID=>$S->{UserID},ID=>$ID)}:{};
    return $L->ErrorScreen(Message=>'API identity unavailable.') if !$I;
    my %C=%{$I->{Settings}||{}};my %Grants=map {$_=>1} @{$C{Grants}||[]};
    my @Inputs=map {{Name=>$_,Value=>$C{$_}||''}} qw(SourceName TargetMELTObjectID ActorID);
    push @Inputs,map {{Name=>$_,Value=>join(',',@{$C{$_}||[]})}} qw(TicketQueueIDs MELTObjectIDs);
    my $Output=$L->Header(Title=>'API identities and tokens').$L->NavigationBar().$L->Output(TemplateFile=>'AgentTESSERAAPIIdentity',Data=>{
        %$I,ID=>$ID,SubjectLabel=>$ID?$B->SubjectLabel(UserID=>$S->{UserID},CustomerUserID=>$I->{CustomerUserID}):'',Message=>$Message,NewToken=>$NewToken,Inputs=>\@Inputs,
        Grants=>[map {{Name=>$_,Selected=>$Grants{$_}}} qw(report:tickets report:risks report:alerts ingest:alertmanager)],
        Identities=>$B->List(UserID=>$S->{UserID}),Tokens=>$ID?$B->Tokens(UserID=>$S->{UserID},ID=>$ID):[]}).$L->Footer();
    $Kernel::OM->Get('Kernel::System::Web::Response')->Header('Cache-Control'=>'no-store');
    return $Output;
}
1;
