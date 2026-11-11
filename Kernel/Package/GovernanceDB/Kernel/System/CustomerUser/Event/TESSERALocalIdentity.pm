package Kernel::System::CustomerUser::Event::TESSERALocalIdentity;
use strict;
use warnings;
our @ObjectDependencies=qw(Kernel::System::TESSERA::LocalIdentity Kernel::System::Log);
sub new {return bless {},$_[0]}
sub Run {
    my ($S,%P)=@_;return 1 if ($P{Event}||'') ne 'CustomerUserUpdate';
    my $Login=$P{Data}{NewData}{UserLogin}||$P{Data}{UserLogin};return 1 if !$Login;
    my $OK=eval {$Kernel::OM->Get('Kernel::System::TESSERA::LocalIdentity')->SyncCustomer(CustomerUserID=>$Login,UserID=>$P{UserID});1};
    $Kernel::OM->Get('Kernel::System::Log')->Log(Priority=>'error',Message=>'Linked local agent profile could not be synchronized; check People and agent access.') if !$OK;
    return $OK?1:0;
}
1;
