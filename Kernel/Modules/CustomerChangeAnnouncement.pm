package Kernel::Modules::CustomerChangeAnnouncement;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');my $B=$Kernel::OM->Get('Kernel::System::TESSERA::ChangeClassification');
    return $L->CustomerNoPermission(WithHeader=>'yes') if !$B->_activeCustomer($S->{UserID}) || $R->GetParam(Param=>'Subaction');
    my $ID=$R->GetParam(Param=>'TicketID');my $Data;
    if (defined $ID && length $ID) {
        my $Public=eval {$B->PublicView(CustomerUserID=>$S->{UserID},TicketID=>$ID)};
        return $L->CustomerNoPermission(WithHeader=>'yes') if !$Public;$Data={Announcement=>$Public};
    } else {
        my $Rows=eval {$B->PublicList(CustomerUserID=>$S->{UserID})};
        return $L->CustomerErrorScreen(Message=>'Change announcements are temporarily unavailable.') if !$Rows;
        $Data={Announcements=>$Rows};
    }
    $Data->{TimeZone}=$Kernel::OM->Get('Kernel::Config')->Get('OTOBOTimeZone') || 'UTC';
    return $L->CustomerHeader(Title=>'Major change announcements').$L->CustomerNavigationBar().$L->Output(TemplateFile=>'CustomerChangeAnnouncement',Data=>$Data).$L->CustomerFooter();
}
1;
