use strict;use warnings;use Test::More;use Template;use JSON::PP;use Cwd qw(abs_path);
my $File=abs_path('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerElasticsearchQuickResult.pm');require $File;
{package QuickFixture;
 sub Get {my($S,$Key)=@_;return {Ticket=>{Count=>10}} if $Key eq 'Elasticsearch::QuickSearchShow';return $S->{Disable} if $Key eq 'Ticket::Frontend::CustomerDisableCompanyTicketAccess';return}
 sub GetParam {my($S,%P)=@_;return 'needle' if $P{Param} eq 'FulltextES';return 'customer.pl?Action=CustomerDashboard' if $P{Param} eq 'URL';return 'forged-ipc';}
 sub PackageIsInstalled {0}
 sub CustomerGlobalTicketRead {my($S,%P)=@_;$S->{Actor}=\%P;return $P{CustomerUserID} eq 'ipc'}
 sub GroupContextCustomers {return (ACME=>1)}
 sub TicketSearch {my($S,%P)=@_;$S->{Query}=\%P;return 20 if $P{Result} eq 'COUNT';return {Total=>20,Data=>[{1=>{Age=>100,Created=>1000,TicketNumber=>'T1',Title=>'one'}},{2=>{Age=>100,Created=>1000,TicketNumber=>'T2',Title=>'two'}}]};}
 sub Block {1}
 sub CustomerAge {'age'}
 sub Output {my($S,%P)=@_;return JSON::PP->new->encode($P{Data})}
 sub Attachment {my($S,%P)=@_;return $P{Content}}
}
{package QuickOM;sub Get {$_[0]{Fixture}}}
my $F=bless {Disable=>0},'QuickFixture';local $Kernel::OM=bless {Fixture=>$F},'QuickOM';
my $Controller=Kernel::Modules::CustomerElasticsearchQuickResult->new(Subaction=>'SearchUpdate',UserID=>'ipc');
my $Data=JSON::PP->new->decode($Controller->Run());
is($F->{Query}{CustomerUserID},'ipc','authenticated session identity remains customer actor');ok(!exists $F->{Query}{UserID},'IPC customer search never impersonates root agent');ok(!exists $F->{Query}{CustomerIDRaw} && !exists $F->{Query}{CustomerUserLoginRaw},'IPC quick search does not inject company/requester narrowing');is($F->{Query}{Limit},10,'preview count is independent configured limit');is($Data->{TicketMatchCount},20,'summary gets matching total');is($Data->{TicketShownCount},2,'summary gets displayed rows');
$F->{Disable}=1;$Controller->Run();ok(!exists $F->{Query}{CustomerUserLoginRaw},'IPC remains global when ordinary company tickets disabled');
$Controller=Kernel::Modules::CustomerElasticsearchQuickResult->new(Subaction=>'SearchUpdate',UserID=>'ordinary');$F->{Disable}=0;$Controller->Run();is_deeply($F->{Query}{CustomerIDRaw},['ACME'],'ordinary company-ticket selection retained');$F->{Disable}=1;$Controller->Run();is($F->{Query}{CustomerUserLoginRaw},'ordinary','ordinary requester-only selection retained');is($F->{Actor}{CustomerUserID},'ordinary','request parameters cannot replace authenticated permission subject');
open my $FH,'<:encoding(UTF-8)','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/CustomerElasticsearchQuickResult.tt' or die;
my $Source=do {local $/;<$FH>};$Source=~s{\[% RenderBlock(?:Start|End)\("[^"]+"\) %\]}{}g;
my $Out='';my $TT=Template->new();$TT->process(\$Source,{Data=>{TicketSummary=>1,TicketShownCount=>10,TicketMatchCount=>20,TicketPageStart=>1,TicketPageEnd=>10,TicketPage=>1,TicketPages=>2,TicketPreviousPage=>0,TicketNextPage=>2,TicketTitle=>'<script>bad</script>'},Env=>sub{''},Translate=>sub{$_[0]}},\$Out) or die $TT->error();
like($Out,qr/Showing 1 to 10 of 20 matching tickets/,'popup displays preview size and matching total independently');unlike($Out,qr/<script>/,'popup ticket title cannot inject markup');
done_testing;
