use strict;use warnings;use Test::More;use Cwd qw(abs_path);
my $Path=abs_path('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerElasticsearchQuickResult.pm');require $Path;
{package PagedES;
 sub TicketSearch {my($S,%P)=@_;push @{$S->{Calls}},\%P;return $S->{Count} if $P{Result} eq 'COUNT';my $Total=defined $S->{Actual}?$S->{Actual}:$S->{Count};my $Start=$P{From}+1;my $End=$P{From}+$P{Limit};$End=$Total if $End>$Total;my @Data=$Start<=$End?map {{$_=>{TicketID=>$_}}} ($Start..$End):();return {Total=>$Total,Data=>\@Data};}
}
sub page {my($Page,%Extra)=@_;my $ES=bless {Count=>363,Calls=>[],%Extra},'PagedES';my $P=Kernel::Modules::CustomerElasticsearchQuickResult::_TicketPageSearch(ES=>$ES,Search=>{CustomerUserID=>'ipc',Permission=>'ro',Fulltext=>'needle',ExtendedSearch=>0},PageSize=>10,Page=>$Page);return ($P,$ES)}
my($First,$ES)=page(1);is($First->{TicketPages},37,'363 matches have37 bounded pages');is($First->{TicketPageStart},1,'first range begins1');is($First->{TicketPageEnd},10,'first range ends10');is($First->{TicketNextPage},2,'next page2');is($First->{TicketPreviousPage},0,'no previous first page');is(scalar @{$First->{Data}},10,'first page never renders363 rows');
my($Second,$Next)=page(2);is($Next->{Calls}[1]{From},10,'next request uses actual backend offset');is($Next->{Calls}[1]{Limit},10,'page maximum retained');is($Second->{TicketPageStart},11,'second page starts11');is_deeply([map {keys %$_} @{$Second->{Data}}],[11..20],'second page has distinct rows11..20');
my($Last,$Final)=page(999999);is($Last->{TicketPage},37,'oversized page clamped before fetch');is($Final->{Calls}[1]{From},360,'no huge backend offset');is($Last->{TicketPageEnd},363,'last range ends363');is($Last->{TicketNextPage},0,'no next last page');is(scalar @{$Last->{Data}},3,'last page returns3');
for my $Bad ('<script>',0,-1,'1.5','999999999999999999999999') {my($P)=page($Bad);is($P->{TicketPage},1,'invalid page defaults1');}
for my $Call (@{$Next->{Calls}}) {is($Call->{CustomerUserID},'ipc','authenticated identity preserved on count and page');ok(!exists $Call->{UserID},'no agent impersonation');is($Call->{Fulltext},'needle','same query on count and page');}
is_deeply($Next->{Calls}[1]{SortBy},['Score','Age','TicketID'],'ticketID tie-breaker stabilizes equal-score/date ordering');
my($Empty,$No)=page(4,Count=>0);is($Empty->{TicketPage},1,'empty scope resets page');is($Empty->{TicketShownCount},0,'empty scope no rows');is(scalar @{$No->{Calls}},1,'empty scope never issues unscoped full query');
my($Shrunk,$Changed)=page(37,Actual=>5);is($Shrunk->{TicketPage},1,'shrinking matches reset to valid page');is($Shrunk->{TicketMatchCount},5,'latest total retained');is($Shrunk->{TicketShownCount},5,'last page refilled after shrink');is(scalar @{$Changed->{Calls}},3,'at most one bounded refill');
done_testing;
