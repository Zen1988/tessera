use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
require './Kernel/Package/GovernanceDB/Kernel/Output/HTML/NavBar/ZTSMCustomerAsset.pm';
{package AssetNavOM;sub Get {$_[0]} sub CustomerHasCMDBReadRole {my ($S,%P)=@_;push @{$S->{Users}},$P{CustomerUserID};return $S->{Allowed};}}
my $Original={
 '100'=>{Name=>'Tickets',Link=>'Action=CustomerTicketOverview'},
 '200'=>{Name=>'Assets',Link=>'Action=CustomerITSMConfigItem'},
 '210'=>{Name=>'Company Tickets',Link=>'Action=CustomerTicketOverview;Subaction=CompanyTickets'},
 '250'=>{Name=>'Unrelated',Link=>'Action=CustomerITSMConfigItemOther'},
 Sub=>{Ticket=>{'1'=>{Link=>'Action=CustomerITSMConfigItemSearch'},'2'=>{Link=>'Action=CustomerTicketMessage'},'4'=>{Link=>'Action=CustomerTicketOverview;Subaction=CompanyTickets'}},Other=>{'3'=>{Link=>'customer.pl?Action=CustomerITSMConfigItemZoom;ConfigItemID=1'}}},
};
for my $Allowed (0,1) {
 my $Nav=dclone($Original);local $Kernel::OM=bless {Allowed=>$Allowed},'AssetNavOM';
 my $Module=Kernel::Output::HTML::NavBar::ZTSMCustomerAsset->new(UserID=>'customer-login');
 my %Merged=(%{$Nav},$Module->Run(NavBarModule=>$Nav));
 is_deeply($Nav,$Original,'hook never mutates the navigation map being expanded');
 is_deeply($Kernel::OM->{Users},['customer-login'],'permission resolves the signed-in customer');
 is_deeply($Merged{'210'},{},'Company Tickets main menu is hidden for every customer');
 ok(!exists $Merged{Sub}{Ticket}{'4'},'Company Tickets submenu is hidden for every customer');
 if ($Allowed) {
  my $Expected=dclone($Original);$Expected->{'210'}={};delete $Expected->{Sub}{Ticket}{'4'};
  is_deeply(\%Merged,$Expected,'authorized asset navigation and personal tickets remain');
 }
 else {
  is_deeply($Merged{'200'},{},'Assets main menu is skipped after Layout merge');
  ok(!exists $Merged{Sub}{Ticket}{'1'},'asset search submenu is hidden');
  ok(!exists $Merged{Sub}{Other}{'3'},'asset detail link is hidden');
  is_deeply($Merged{'100'},$Original->{'100'},'ticket main menu remains');
  is_deeply($Merged{Sub}{Ticket}{'2'},$Original->{Sub}{Ticket}{'2'},'ticket submenu remains');
  ok(exists $Merged{'250'},'similarly named unrelated action remains');
 }
}
local $Kernel::OM=bless {Allowed=>0},'AssetNavOM';
my $Module=Kernel::Output::HTML::NavBar::ZTSMCustomerAsset->new(UserID=>'other-login');
my @Result=$Module->Run();is(scalar @Result,0,'missing navigation input is safe');
done_testing();
