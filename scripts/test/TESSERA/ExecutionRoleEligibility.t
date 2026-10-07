use strict;use warnings;use Test::More;use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::GovernanceRoleResolver;
our $Masters={1=>'ServiceRequest',2=>'Incident',3=>'Problem',4=>'Change'};
{package EligibleOM;sub Get{$_[0]}sub ItemList{my($S,%P)=@_;die 'wrong catalog' if $P{Class} ne 'ZTSM::RequestType';$main::Masters}sub Log{1}}
local $Kernel::OM=bless{},'EligibleOM';my $R=Kernel::System::TESSERA::GovernanceRoleResolver->new;
for my $Type(qw(ServiceRequest Incident Problem Change)){ok(!$R->ExecutionTicketEligible(Ticket=>{Type=>$Type,StateType=>'open'}),"catalog master $Type skipped");}
for my $Type(qw(RiskTreatment Assessment NewExecutionType)){ok($R->ExecutionTicketEligible(Ticket=>{Type=>$Type,StateType=>'open'}),"execution $Type eligible without allowlist");}
ok(!$R->ExecutionTicketEligible(Ticket=>{Type=>'RiskTreatment',StateType=>'closed'}),'closed execution evidence untouched');
$Masters->{5}='NewMaster';ok(!$R->ExecutionTicketEligible(Ticket=>{Type=>'NewMaster',StateType=>'open'}),'new catalog master automatically excluded');
$Masters={};ok(!$R->ExecutionTicketEligible(Ticket=>{Type=>'RiskTreatment',StateType=>'open'}),'missing classification catalog fails closed');
done_testing();
