use strict;use warnings;use Test::More;use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::RiskGovernanceDecision;
{package DecisionOM;sub Get{$_[0]}sub ServiceGet{return(Name=>$_[0]{Service}||'Risk::Management')}sub TicketSearch{my($S,%P)=@_;my @IDs=sort keys %{$S->{Children}};for my $Key (grep {/^DynamicField_/} keys %P){@IDs=grep {($S->{Children}{$_}{$Key}//'') eq $P{$Key}{Equals}} @IDs;}return scalar @IDs if $P{Result} eq 'COUNT';return @IDs;}
sub TicketGet{my($S,%P)=@_;return %{$S->{Children}{$P{TicketID}}||{}}}sub HistoryGet{my($S,%P)=@_;return @{$S->{History}{$P{TicketID}}||[]}}
sub DynamicFieldGet{my($S,%P)=@_;return if $S->{MissingDate} && $P{Name} eq 'ITSMDecisionDate';return {Name=>$P{Name},ObjectType=>'Ticket',FieldType=>$P{Name} eq 'ITSMDecisionDate'?'DateTime':'Dropdown',Config=>{PossibleValues=>{'Risk Accepted'=>'Risk Accepted'}}}}
sub GovernanceObjectGet{return $_[0]{StateBook}}sub StateLookup{1}sub StateGet{return(Name=>'approve')}sub ValueLookup{return undef}
sub PIDCreate{1}sub PIDDelete{1}sub Log{1}sub ValueSet{my($S,%P)=@_;return if $S->{FailWrite};push @{$S->{Writes}},\%P;return 1}
sub HistoryAdd{my($S,%P)=@_;push @{$S->{History}{$P{TicketID}}},{Name=>$P{Name}};return 1}}
my $Books={5=>[{Type=>'Approval',BlueLevel=>1}],6=>[{Type=>'Implementation',BlueLevel=>1}],7=>[{Type=>'Approval',BlueLevel=>2}]};
my $NativeLevelComplete=\&Kernel::System::ZTSMBlueBookRuntime::LevelComplete;
my $Complete=1;
{no warnings 'redefine';*Kernel::System::ZTSMBlueBookRuntime::BlueBookGet=sub{return {ID=>$_[1]}};
*Kernel::System::ZTSMBlueBookRuntime::RecordsParse=sub{my(%P)=@_;return @{$Books->{$P{BlueBook}{ID}}||[]}};
*Kernel::System::ZTSMBlueBookRuntime::LevelComplete=sub{return $Complete};}
local $Kernel::OM=bless {Children=>{10=>{Type=>'Assessment',State=>'closed successful',StateType=>'closed','DynamicField_ZTicket-Parent'=>1,'DynamicField_ZTicket-BlueBook'=>4,'DynamicField_ZTicket-BlueLevel'=>1,'DynamicField_ZTicket-Chapter'=>'AS-001','DynamicField_ZTicket-Outcome'=>'0','DynamicField_RiskAssessmentOutcome'=>'Risk Accepted'},11=>{Type=>'Approval',State=>'closed successful',StateType=>'closed','DynamicField_ZTicket-Parent'=>1,'DynamicField_ZTicket-BlueLevel'=>1,'DynamicField_ZTicket-Chapter'=>'BR-001','DynamicField_ZTicket-Outcome'=>'0','DynamicField_ZTicket-BlueBook'=>5}},History=>{11=>[{HistoryType=>'StateUpdate',Name=>'%%approve%%closed successful%%',CreateTime=>'2026-10-07 01:00:00'}]},Writes=>[]},'DecisionOM';
my $D=Kernel::System::TESSERA::RiskGovernanceDecision->new();my $T={TicketID=>1,Type=>'ServiceRequest',ServiceID=>2};
my %P=(Ticket=>$T,Records=>[{BlueBook=>5},{BlueBook=>6}],CurrentIndex=>0);
ok($D->Run(%P),'final governed approval recorded before treatment');
is(scalar @{$Kernel::OM->{Writes}},2,'existing outcome and decision date written on master only');
is($Kernel::OM->{Writes}[0]{ObjectID},1,'master is authoritative decision record');
is($Kernel::OM->{Writes}[0]{Value},'Risk Accepted','existing outcome retained');
is($Kernel::OM->{Writes}[1]{Value},'2026-10-07 01:00:00','effective date from completed approval evidence');
ok($D->Run(%P),'approval replay succeeds');is(scalar @{$Kernel::OM->{Writes}},2,'replay does not renew decision or write again');
$Kernel::OM->{History}{11}[0]{CreateTime}='2027-10-01 02:00:00';ok($D->Run(%P),'new completed approval evidence establishes renewed decision');
is(scalar @{$Kernel::OM->{Writes}},4,'renewal persists new date and existing outcome');is($Kernel::OM->{Writes}[3]{Value},'2027-10-01 02:00:00','renewal uses new decision timestamp');
my $Before=scalar @{$Kernel::OM->{Writes}};
ok($D->Run(%P,Records=>[{BlueBook=>5},{BlueBook=>7}]),'later governed Approval defers capture');is(scalar @{$Kernel::OM->{Writes}},$Before,'not captured before final approval');
$Complete=0;ok($D->Run(%P),'incomplete governed weights defer capture');is(scalar @{$Kernel::OM->{Writes}},$Before,'incomplete approval cannot accept');$Complete=1;
$Kernel::OM->{Children}{10}{'DynamicField_ZIN-Iteration'}=2;ok($D->Run(%P),'other iteration recommendation excluded');is(scalar @{$Kernel::OM->{Writes}},$Before,'no historic assessment outcome carried into decision');delete $Kernel::OM->{Children}{10}{'DynamicField_ZIN-Iteration'};
$Kernel::OM->{Children}{11}{'DynamicField_ZTicket-Outcome'}=-1;ok($D->Run(%P),'rejected approval excluded');is(scalar @{$Kernel::OM->{Writes}},$Before,'negative approval cannot establish acceptance');$Kernel::OM->{Children}{11}{'DynamicField_ZTicket-Outcome'}=0;
$Kernel::OM->{MissingDate}=1;ok(!$D->Run(%P),'missing authoritative timestamp field blocks capture');$Kernel::OM->{MissingDate}=0;
$Kernel::OM->{History}{11}[0]{CreateTime}='2027-10-02 02:00:00';$Kernel::OM->{FailWrite}=1;ok(!$D->Run(%P),'failed governance write stops transition handoff');$Kernel::OM->{FailWrite}=0;
$Kernel::OM->{Service}='Other';ok($D->Run(%P),'unrelated service unchanged');is(scalar @{$Kernel::OM->{Writes}},$Before,'unrelated workflow has no field writes');
$Kernel::OM->{Service}='Risk::Management';
$Kernel::OM->{StateBook}={'DynamicField_ZState-Record'=>[{'ZState-Seq'=>1,'ZState-State'=>'approve','ZState-Book'=>5},{'ZState-Seq'=>2,'ZState-State'=>'approve','ZState-Book'=>6}]};
$T->{State}='approve';$T->{'DynamicField_ZTicket-StateBook'}=8;
$Kernel::OM->{History}{11}[0]{CreateTime}='2027-10-03 02:00:00';
ok($D->FromCompletedLevel(Ticket=>$T,BlueBookID=>5),'actual StateBook parser resolves governed completed approval stage');
is($Kernel::OM->{Writes}[-1]{Value},'2027-10-03 02:00:00','chapter completion handoff captures effective decision');
$T->{State}='unmatched';my $After=scalar @{$Kernel::OM->{Writes}};
ok($D->FromCompletedLevel(Ticket=>$T,BlueBookID=>5),'unmatched governance stage does not infer approval');
is(scalar @{$Kernel::OM->{Writes}},$After,'unmatched stage has no decision writes');
# Reproduce live0052/0053/0054: successful children omit ZTicket-Outcome.
delete $Kernel::OM->{Children}{10}{'DynamicField_ZTicket-Outcome'};
delete $Kernel::OM->{Children}{11}{'DynamicField_ZTicket-Outcome'};
$Kernel::OM->{History}{11}[0]{CreateTime}='2026-10-07 08:06:52';
$Kernel::OM->{Children}{10}{DynamicField_RiskAssessmentOutcome}='At Risk - Mitigation Planned';
{no warnings 'redefine';local *DecisionOM::DynamicFieldGet=sub {my($S,%Q)=@_;return {Name=>$Q{Name},ObjectType=>'Ticket',FieldType=>$Q{Name} eq 'ITSMDecisionDate'?'DateTime':'Dropdown',Config=>{PossibleValues=>{'At Risk - Mitigation Planned'=>'At Risk - Mitigation Planned'}}}};
local *Kernel::System::ZTSMBlueBookRuntime::LevelComplete=$NativeLevelComplete;
my $WriteCount=scalar @{$Kernel::OM->{Writes}};
$T->{State}='remediate';$T->{StateType}='open';$T->{Service}='Risk::Management';
my $Read=$D->Read(Ticket=>$T);
ok($Read,'real native level completion recognizes success without optional outcome');
is($Read->{GovernanceDate},'2026-10-07 08:06:52','existing approval closure is effective date');
is(scalar @{$Kernel::OM->{Writes}},$WriteCount,'read recovery neither modifies ticket nor captures new decision');
my $Register=Kernel::System::TESSERA::RiskRegister->new();
my $Evaluation=$Register->Evaluate(Ticket=>$T,Decision=>$Read,History=>[],Now=>Kernel::System::TESSERA::RiskRegister::Epoch('2026-10-07 08:10:00'));
is($Evaluation->{Status},'Current','live-shaped completed approval becomes current risk without new approval');
$Kernel::OM->{Children}{11}{StateType}='open';$Kernel::OM->{Children}{11}{State}='pending';
ok(!$D->Read(Ticket=>$T),'pending required approval remains excluded using actual native level check');
$Kernel::OM->{Children}{11}{StateType}='closed';$Kernel::OM->{Children}{11}{State}='closed unsuccessful';
ok(!$D->Read(Ticket=>$T),'failed closure does not establish approval');
$Kernel::OM->{Children}{11}{State}='closed successful';$Kernel::OM->{Children}{11}{'DynamicField_ZTicket-Outcome'}=-1;
ok(!$D->Read(Ticket=>$T),'explicit negative execution evidence cannot be overridden by successful state');
delete $Kernel::OM->{Children}{11}{'DynamicField_ZTicket-Outcome'};
$T->{'DynamicField_ZIN-Iteration'}=2;
ok(!$D->Read(Ticket=>$T),'previous iteration approvals cannot recover current decision');delete $T->{'DynamicField_ZIN-Iteration'};
$Kernel::OM->{StateBook}{'DynamicField_ZState-Record'}[1]{'ZState-Book'}=7;
ok(!$D->Read(Ticket=>$T),'later governed approval remains required');
$Kernel::OM->{StateBook}{'DynamicField_ZState-Record'}[1]{'ZState-Book'}=6;
ok($D->FromCompletedLevel(Ticket=>{%{$T},State=>'approve'},BlueBookID=>5),'future approval capture handles native successful closures with absent outcome');
is(scalar @{$Kernel::OM->{Writes}},$WriteCount+2,'future capture persists master fields once');}
done_testing();
