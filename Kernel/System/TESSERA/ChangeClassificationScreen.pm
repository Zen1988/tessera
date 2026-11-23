package Kernel::System::TESSERA::ChangeClassificationScreen;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');my $B=$Kernel::OM->Get('Kernel::System::TESSERA::ChangeClassification');
    my %Actor=$S->{Customer}?(CustomerUserID=>$S->{UserID}):(UserID=>$S->{UserID});
    my $Deny=sub {$S->{Customer}?$L->CustomerNoPermission(WithHeader=>'yes'):$L->NoPermission(WithHeader=>1)};
    return $Deny->() if !$B->Actor(%Actor);
    my $ID=$R->GetParam(Param=>'TicketID') || '';
    if (!$ID && $R->GetParam(Param=>'TicketNumber')) {$ID=$Kernel::OM->Get('Kernel::System::Ticket')->TicketIDLookup(TicketNumber=>$R->GetParam(Param=>'TicketNumber')) || ''}
    my ($V,$Error);$V=eval {$B->View(%Actor,TicketID=>$ID)} if $ID;
    return $Deny->() if $ID && !$V;
    my $Action=$S->{Customer}?'CustomerChangeClassification':'AgentTicketChangeClassification';
    if ($R->GetParam(Param=>'Subaction')) {
        return $Deny->() if !$V || $R->GetParam(Param=>'Subaction') ne 'Save' || $R->RequestMethod() ne 'POST'
            || !$L->{UserChallengeToken} || ($R->GetParam(Param=>'ChallengeToken') || '') ne $L->{UserChallengeToken} || !$L->ChallengeTokenCheck();
        my $OK=eval {$B->Save(%Actor,TicketID=>$ID,map {$_=>$R->GetParam(Param=>$_) || ''} qw(ChangeType ChangeClassification Reason Revision Description Summary AssessmentOverride));1};
        return $L->Redirect(OP=>'Action='.$Action.';TicketID='.$ID) if $OK;
        $Error=$@=~/\A(?:Invalid change|A classification|Review the announcement|A public|Change information|Complete all linked)/?$@:'The decision could not be saved. Reload and check configuration or server logs.';
        for my $Name (qw(Description Summary Reason)) {my $Text=$R->GetParam(Param=>$Name);$V->{$Name}=$Text if defined $Text && !ref $Text && length($Text)<=($Name eq 'Reason'?4000:20000)}
        my $Type=$R->GetParam(Param=>'ChangeType') || '';my $Class=$R->GetParam(Param=>'ChangeClassification') || '';
        $V->{ChangeType}=$Type if $Type=~/\A(?:Normal|Standard|Emergency)\z/;
        $V->{ChangeClassification}=$Class if $Class=~/\A(?:Normal|Not-Assessed|Major)\z/;
    }
    my $Content=$L->Output(TemplateFile=>'ChangeClassificationEdit',Data=>{View=>$V,Action=>$Action,TicketID=>$ID,Error=>$Error,Customer=>$S->{Customer}?1:0});
    return $S->{Customer}?$L->CustomerHeader(Title=>'Change classification').$L->CustomerNavigationBar().$Content.$L->CustomerFooter()
        :$L->Header(Title=>'Change classification').$L->NavigationBar().$Content.$L->Footer();
}
1;
