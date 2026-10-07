use strict;use warnings;use Test::More;use lib 'Kernel/Package/GovernanceDB','.';use Kernel::System::TESSERA::RiskRegister;
{package EntryOM;sub Get{$_[0]}sub ServiceList{return(2=>'Risk::Management',3=>'Other')}sub DynamicFieldGet{return{ID=>1,Config=>{PossibleValues=>{'Risk Accepted'=>'Risk Accepted'}}}}
sub TicketSearch{my($S,%P)=@_;push @{$S->{Search}},\%P;return 4 if $P{Result} eq 'COUNT';return(1,2,3,4)}
sub TicketGet{my($S,%P)=@_;return %{$S->{Data}{$P{TicketID}}||{}}}sub TicketCustomerPermission{1}sub Run{my($S,%P)=@_;return $P{TicketID}==2}
sub Read{$_[0]{DerivedDecision}}sub HistoryGet{my($S,%P)=@_;push @{$S->{HistoryReads}},$P{TicketID};return $S->{Pending} ? () : ({HistoryType=>'Misc',Name=>'ZTSM Risk Governance Decision '.('b'x64)})}}
my $Date='2026-10-07 00:00:00';my $Now=Kernel::System::TESSERA::RiskRegister::Epoch($Date)+100;
local $Kernel::OM=bless{Data=>{
1=>{TicketID=>1,Type=>'ServiceRequest',ServiceID=>2,StateType=>'closed',State=>'closed successful',CustomerUserID=>'requester',TicketNumber=>'T1',Title=>'Accepted','DynamicField_RiskAssessmentOutcome'=>'Risk Accepted','DynamicField_ITSMDecisionDate'=>$Date},
2=>{TicketID=>2,Type=>'ServiceRequest',ServiceID=>2,StateType=>'closed',State=>'closed successful',CustomerUserID=>'other',TicketNumber=>'T2',Title=>'Child','DynamicField_ZTicket-Parent'=>1,'DynamicField_RiskAssessmentOutcome'=>'Risk Accepted','DynamicField_ITSMDecisionDate'=>$Date},
3=>{TicketID=>3,Type=>'ServiceRequest',ServiceID=>2,StateType=>'closed',State=>'closed successful',CustomerUserID=>'other',TicketNumber=>'T3',Title=>'Denied','DynamicField_RiskAssessmentOutcome'=>'Risk Accepted','DynamicField_ITSMDecisionDate'=>$Date},
4=>{TicketID=>4,Type=>'ServiceRequest',ServiceID=>3,StateType=>'closed',State=>'closed successful',CustomerUserID=>'requester',TicketNumber=>'T4',Title=>'Other Service','DynamicField_RiskAssessmentOutcome'=>'Risk Accepted','DynamicField_ITSMDecisionDate'=>$Date}},Search=>[],HistoryReads=>[]},'EntryOM';
my $R=Kernel::System::TESSERA::RiskRegister->new();my $Rows=$R->Entries(CustomerUserID=>'requester',Now=>$Now);
is_deeply([map{$_->{TicketID}}@{$Rows}],[1],'only authorized eligible master returned');is($Rows->[0]{Status},'Current','closed accepted master discovered without active-only search');
is_deeply($Kernel::OM->{Search}[0]{ServiceIDs},[2],'search scoped by exact service');is_deeply($Kernel::OM->{Search}[0]{Types},['ServiceRequest'],'search scoped by authoritative master type');
ok(!exists $Kernel::OM->{Search}[0]{StateType},'closed accepted records are not lost');is($Kernel::OM->{Search}[1]{Limit},4,'complete count determines candidate bound');ok(!(grep{$_==3}@{$Kernel::OM->{HistoryReads}}),'denied viewer never reads decision history');
is_deeply($R->Entries(),[],'anonymous list empty');$Kernel::OM->{Pending}=1;
$Kernel::OM->{Data}{1}{StateType}='open';$Kernel::OM->{Data}{1}{State}='approve';
is_deeply($R->Entries(CustomerUserID=>'requester',Now=>$Now),[],'unapproved master removed from shared list/dashboard/export entry collection');
{no warnings 'redefine';local *Kernel::System::TESSERA::RiskRegister::Columns=sub {[]};
my $Report=$R->Report(CustomerUserID=>'requester',Now=>$Now);
is_deeply($Report->{Rows},[],'completed assessment cannot enter report through pending parent');
my $Dashboard=$R->Dashboard(Rows=>$Report->{Rows},Now=>$Now);
is($Dashboard->{Open},0,'pending parent does not increase dashboard open risks');}
$Kernel::OM->{DerivedDecision}={Outcome=>'Risk Accepted',GovernanceDate=>$Date,Marker=>'ZTSM Risk Governance Decision '.('c'x64)};
my $Recovered=$R->Entries(CustomerUserID=>'requester',Now=>$Now);
is_deeply([map {$_->{TicketID}} @{$Recovered}],[1],'verified completed approval recovers register without master capture');
is($Recovered->[0]{GovernanceDate},$Date,'derived approval supplies actual effective date');
done_testing();
