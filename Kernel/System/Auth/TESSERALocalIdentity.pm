package Kernel::System::Auth::TESSERALocalIdentity;
use strict;
use warnings;
our @ObjectDependencies=qw(Kernel::System::TESSERA::LocalIdentity);
sub new {my ($T,%P)=@_;return bless \%P,$T}
sub GetOption {return 0}
sub Auth {
    my ($S,%P)=@_;my $R=eval {$Kernel::OM->Get('Kernel::System::TESSERA::LocalIdentity')->AuthenticateAgent(%P)};
    return if !$R; # Resolution errors never fall back to an agent-local password.
    return $R->{Login} if $R->{Linked};
    require Kernel::System::Auth::DB;
    return Kernel::System::Auth::DB->new(Count=>$S->{Count}||'')->Auth(%P);
}
1;
