package Kernel::System::GovernanceObject::Event::ActivityRecorder;
use v5.24; use strict; use warnings; use namespace::autoclean;
our @ObjectDependencies=('Kernel::System::GovernanceObject::Activity');
sub new { my($Type,%Param)=@_; bless {},$Type }
sub Run { my($Self,%Param)=@_; return if !$Param{Event}||ref $Param{Data} ne 'HASH'||!$Param{UserID}; my $D=$Param{Data}; my $F=$D->{FieldName}//''; my $B=$D->{Comment}//''; $B=(($D->{ReadableOldValue}//'').' -> '.($D->{ReadableValue}//'')) if !$B&&exists $D->{ReadableOldValue}; $B||="GovernanceObject activity event: $Param{Event}"; return $Kernel::OM->Get('Kernel::System::GovernanceObject::Activity')->ActivityAdd(GovernanceObjectID=>$D->{GovernanceObjectID}||$D->{ObjectID},ObjectNumber=>$D->{Number}//'',EventType=>$Param{Event},Source=>'OTOBO Event',Subject=>$Param{Event}.($F?": $F":''),Body=>$B,Payload=>$D,UserID=>$Param{UserID}); }
1;
