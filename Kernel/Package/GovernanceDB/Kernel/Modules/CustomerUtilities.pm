package Kernel::Modules::CustomerUtilities;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');my $B=$Kernel::OM->Get('Kernel::System::TESSERA::Utilities');
    my %P=(CustomerUserID=>$S->{UserID},ID=>$R->GetParam(Param=>'ID') || '');
    my $Sub=$R->GetParam(Param=>'Subaction') || '';
    if ($Sub eq 'Icon') {
        my $Icon=eval {$B->Icon(%P)};return $L->CustomerNoPermission(WithHeader=>'yes') if !$Icon;
        return $L->Attachment(Content=>$Icon,ContentType=>'image/png',Filename=>'utility.png',Type=>'inline',NoCache=>1);
    }
    if ($Sub eq 'Launch') {
        my $Dest=eval {$B->Launch(%P,map {$_=>$R->GetParam(Param=>$_) || ''} qw(TicketID ConfigItemID))};
        return $L->CustomerErrorScreen(Message=>'This utility is unavailable or requires authorized ticket or asset context. Contact your administrator if access is expected.') if !$Dest;
        return $L->Redirect(ExtURL=>$Dest->{URL}) if $Dest->{External};
        return $L->Redirect(OP=>$Dest->{OP});
    }
    return $L->CustomerNoPermission(WithHeader=>'yes') if $Sub || !$S->{UserID} || !$B->_customer($S->{UserID});
    my $Rows=eval {$B->List(CustomerUserID=>$S->{UserID})};
    return $L->CustomerErrorScreen(Message=>'Utilities are temporarily unavailable.') if !$Rows;
    return $L->CustomerHeader(Title=>'Utilities').$L->CustomerNavigationBar().$L->Output(TemplateFile=>'CustomerUtilities',Data=>{Tools=>$Rows}).$L->CustomerFooter();
}
1;
