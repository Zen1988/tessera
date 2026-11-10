package Kernel::Modules::CustomerTESSERAOnboarding;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub PreRun {
    my ($S)=@_;return if ($S->{Action} || '') =~ /\A(?:CustomerTESSERAOnboarding|CustomerAccept)\z/;
    my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $State=eval {$Kernel::OM->Get('Kernel::System::TESSERA::CustomerOnboarding')->State($S->{UserID})};
    return $L->CustomerErrorScreen(Message=>'Identity onboarding is unavailable.') if !$State;
    return if !$State->{Required} || $State->{Step} eq 'Complete';
    return $L->Redirect(OP=>'Action=CustomerTESSERAOnboarding');
}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $Service=$Kernel::OM->Get('Kernel::System::TESSERA::CustomerOnboarding');my $Message='';
    if ($S->{Subaction}) {
        return $L->CustomerErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST';
        $L->ChallengeTokenCheck(Type=>'Customer');
        my $OK=eval {
            if ($S->{Subaction} eq 'Accept') {$Service->Accept(Login=>$S->{UserID},Accepted=>$R->GetParam(Param=>'Accepted'),Version=>$R->GetParam(Param=>'Version'))}
            elsif ($S->{Subaction} eq 'Defaults') {$Service->Defaults(Login=>$S->{UserID},Application=>$R->GetParam(Param=>'Application'),Profile=>$R->GetParam(Param=>'Profile'))}
            else {die 'Unknown action'}1;
        };
        return $L->Redirect(OP=>'Action=CustomerTESSERAOnboarding') if $OK;
        $Message='Could not save. Accept the current responsibilities and select valid request defaults.';
    }
    my $State=eval {$Service->State($S->{UserID})};return $L->CustomerErrorScreen(Message=>'Identity onboarding is unavailable.') if !$State;
    return $L->Redirect(OP=>'Action=CustomerTicketOverview') if !$State->{Required} || ($State->{Step} eq 'Complete' && !$R->GetParam(Param=>'Review'));
    require Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults;
    my $Defaults=Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults->new(UserID=>$S->{UserID},ConfigItem=>{});
    my %Apps=$Defaults->_GovernanceObjectData(Classes=>['Application']);my %Teams=$Defaults->_SupportProfileData(CustomerUserID=>$S->{UserID});
    return $L->CustomerHeader(Title=>'Complete your profile').$L->Output(TemplateFile=>'CustomerTESSERAOnboarding',Data=>{
        State=>$State,Message=>$Message,Applications=>[map {{ID=>$_,Name=>$Apps{$_}}} sort keys %Apps],Teams=>[map {{ID=>$_,Name=>$Teams{$_}}} sort keys %Teams],
    }).$L->CustomerFooter();
}
1;
