package Kernel::System::Ticket::Event::TESSERARequestDefaults;
use strict;
use warnings;
our @ObjectDependencies=qw(Kernel::Config Kernel::System::Ticket Kernel::System::DynamicField Kernel::System::DynamicField::Backend Kernel::System::CustomerUser Kernel::System::GovernanceObject);
sub new {bless {},$_[0]}
sub Run {
    my ($S,%P)=@_;return 1 if ($P{Event} || '') ne 'TicketCreate';
    my $ID=$P{Data}{TicketID};return if !$ID;
    my %T=$Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(TicketID=>$ID,DynamicFields=>1,UserID=>1);
    return 1 if !$T{CustomerUserID};
    return 1 if grep {$T{'DynamicField_'.$_}} qw(ZState-CurrentStage ZState-CurrentState ZBlue-CurrentChapter);
    my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');my $B=$Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    for my $Pair (['ZUser-Application','ZTicket-Application','Application'],['ZUser-Location','ZTicket-Location','Location']) {
        next if $T{'DynamicField_'.$Pair->[1]};
        my $From=$DF->DynamicFieldGet(Name=>$Pair->[0]);my $To=$DF->DynamicFieldGet(Name=>$Pair->[1]);next if !$From || !$To;
        my $Value=$B->ValueGet(DynamicFieldConfig=>$From,ObjectName=>$T{CustomerUserID});
        $Value=$Value->[0] if ref $Value eq 'ARRAY' && @$Value==1;
        next if !defined $Value || ref $Value || $Value!~/\A[1-9][0-9]*\z/;
        my $O=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$Value);
        next if !$O || ($O->{Class} || '') ne $Pair->[2] || ($O->{ZTSMStatus} || '') ne 'Active';
        return if !$B->ValueSet(DynamicFieldConfig=>$To,ObjectID=>$ID,Value=>$Value,UserID=>$P{UserID} || 1);
    }
    return 1;
}
1;
