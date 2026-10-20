package Kernel::Output::HTML::GovernanceObject::MenuControlRun;
use strict;
use warnings;
use parent 'Kernel::Output::HTML::GovernanceObject::MenuGeneric';
sub Run {
    my ($Self,%P)=@_;
    my $Object=$P{GovernanceObject};
    return $P{Counter} if ref $Object ne 'HASH' || ($Object->{Class}||'') ne 'ControlObjective';
    return $P{Counter} if !$Kernel::OM->Get('Kernel::System::GovernanceObject')->Permission(
        Scope=>'Item',ItemID=>$Object->{GovernanceObjectID},Type=>'rw',UserID=>$Self->{UserID});
    return $Self->SUPER::Run(%P);
}
1;
