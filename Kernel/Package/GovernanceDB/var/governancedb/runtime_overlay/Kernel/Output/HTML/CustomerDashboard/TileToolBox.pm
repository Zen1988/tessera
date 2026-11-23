package Kernel::Output::HTML::CustomerDashboard::TileToolBox;
use strict;
use warnings;
our @ObjectDependencies=qw(Kernel::Output::HTML::Layout Kernel::System::TESSERA::Utilities);
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S,%P)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Rows=eval {$Kernel::OM->Get('Kernel::System::TESSERA::Utilities')->List(CustomerUserID=>$P{UserID},Workplace=>1)};
    return $L->Output(TemplateFile=>'TESSERAUtilitiesShortcuts',Data=>{TileID=>$P{TileID},Tools=>$Rows || [],Unavailable=>$Rows?0:1});
}
1;
