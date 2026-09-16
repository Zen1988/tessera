package Kernel::System::GovernanceObject::Activity;
use v5.24; use strict; use warnings; use namespace::autoclean;
our @ObjectDependencies = ('Kernel::System::DB','Kernel::System::GovernanceObject','Kernel::System::JSON');
sub new { my ( $Type, %Param ) = @_; return bless {}, $Type; }
sub ActivityAdd {
    my ( $Self, %Param ) = @_;
    return if !$Param{EventType} || !$Param{Subject} || !$Param{Body} || !$Param{UserID};
    my $Number = $Param{ObjectNumber} // '';
    if (!$Number && $Param{GovernanceObjectID}) { my $O=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$Param{GovernanceObjectID}); $Number=$O->{Number}//'' if $O; }
    my $Payload=ref $Param{Payload}?$Kernel::OM->Get('Kernel::System::JSON')->Encode(Data=>$Param{Payload},SortKeys=>1,Pretty=>1):($Param{Payload}//'');
    return $Kernel::OM->Get('Kernel::System::DB')->Do(SQL=>'INSERT INTO governance_object_activity (governance_object_id, object_number, event_type, source, subject, body, payload, create_time, create_by) VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, ?)',Bind=>[\$Param{GovernanceObjectID},\$Number,\$Param{EventType},\($Param{Source}//'OTOBO Event'),\$Param{Subject},\$Param{Body},\$Payload,\$Param{UserID}]);
}
sub ActivityList {
    my ($Self,%Param)=@_; return [] if !$Param{GovernanceObjectID};
    my $Rows=$Kernel::OM->Get('Kernel::System::DB')->SelectAll(SQL=>'SELECT id, object_number, event_type, source, subject, body, payload, create_time, create_by FROM governance_object_activity WHERE governance_object_id = ? ORDER BY id DESC',Bind=>[\$Param{GovernanceObjectID}],Limit=>$Param{Limit}||500)||[];
    return [map {{ActivityID=>$_->[0],ObjectNumber=>$_->[1],EventType=>$_->[2],Source=>$_->[3],Subject=>$_->[4],Body=>$_->[5],Payload=>$_->[6],CreateTime=>$_->[7],CreateBy=>$_->[8]}} @{$Rows}];
}
1;
