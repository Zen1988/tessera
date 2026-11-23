package Kernel::System::Ticket::Event::ChangeDecisionDefaults;
use strict;
use warnings;
use Kernel::System::TESSERA::ChangeClassification;
our @ObjectDependencies=qw(Kernel::System::DB Kernel::System::Ticket Kernel::System::DynamicField Kernel::System::DynamicField::Backend);
sub new {bless {},shift}
sub Run {
    my ($S,%P)=@_;my $ID=$P{Data}{TicketID};return 1 if !defined $ID || ref $ID || $ID!~/\A[1-9][0-9]*\z/;
    my %T=$Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(TicketID=>$ID,DynamicFields=>0,UserID=>1);
    return 1 if ($T{Type} || '') ne 'Change';
    my $DB=$Kernel::OM->Get('Kernel::System::DB');my $Lock='tessera_change_'.$ID;
    return if !$DB->Prepare(SQL=>'SELECT GET_LOCK(?,5)',Bind=>[\$Lock]);my @L=$DB->FetchrowArray();return if !$L[0];
    my $OK=eval {
        my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');my $B=$Kernel::OM->Get('Kernel::System::DynamicField::Backend');
        local $Kernel::System::TESSERA::ChangeClassification::AuthorizedWrite={TicketID=>"$ID",UserID=>$P{UserID} || 1,ChangeType=>'Normal',ChangeClassification=>'Not-Assessed'};
        for my $Spec (['ChangeType','Normal'],['ChangeClassification','Not-Assessed']) {
            my $F=$DF->DynamicFieldGet(Name=>$Spec->[0]);die if !$F || !$F->{ID} || ($F->{Name} || '') ne $Spec->[0] || ($F->{ObjectType} || '') ne 'Ticket' || ($F->{FieldType} || '') ne 'Dropdown';
            # Read the actual stored row, not an external cache; never reset a decision.
            die if !$DB->Prepare(SQL=>'SELECT id FROM dynamic_field_value WHERE field_id=? AND object_id=?',Bind=>[\$F->{ID},\$ID],Limit=>1);
            my @Old=$DB->FetchrowArray();next if @Old;
            die if !$B->ValueSet(DynamicFieldConfig=>$F,ObjectID=>$ID,Value=>$Spec->[1],UserID=>$P{UserID} || 1);
        }
        1;
    };
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Lock]);$DB->FetchrowArray();return $OK?1:undef;
}
1;
