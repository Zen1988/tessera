use strict;use warnings;use Test::More;use Template;use Cwd qw(abs_path);
my $Module=abs_path('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/CustomerDashboard/TileTicketList.pm');require $Module;
{package WorkspaceFixture;
 sub Get {$_[0]}
 sub PermissionCheck {my($S,%P)=@_;return ($P{UserID}||'') eq 'ipc'}
 sub UserLookup {return}
 sub TicketSearch {my($S,%P)=@_;push @{$S->{Search}},\%P;return 40 if $P{Result} eq 'COUNT';return (1..($P{Limit}||9));}
 sub Run {my($S,%P)=@_;push @{$S->{Permissions}},\%P;return ($P{CustomerUserID}||'') eq 'ipc' && $P{TicketID}!=40;}
 sub TicketGet {my($S,%P)=@_;my $ID=$P{TicketID};return (TicketID=>$ID,TicketNumber=>'T'.$ID,Title=>'<unsafe>',Type=>'ServiceRequest',State=>$ID<=20?'open':'closed successful',StateType=>$ID<=20?'open':'closed',Changed=>sprintf('2026-11-13 00:00:%02d',$ID),Created=>'2026-10-01 00:00:00');}
}
local $Kernel::OM=bless {Search=>[],Permissions=>[]},'WorkspaceFixture';
my @IDs=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_ZTSMWorkableTicketIDs(CustomerUserID=>'ipc');
is(scalar @IDs,39,'IPC gets all existing permitted candidates, not default search page');
is($Kernel::OM->{Search}[1]{Limit},40,'complete search uses total before permission checks');
ok(!grep({exists $_->{CustomerUserID} || exists $_->{CustomerID} || exists $_->{StateType}} @{$Kernel::OM->{Search}}),'IPC candidate query has no requester/company/state restriction');
is(scalar @{$Kernel::OM->{Permissions}},40,'every candidate checked by existing permission service');
ok(!grep({$_->{CustomerUserID} ne 'ipc' || $_->{Type} ne 'ro'} @{$Kernel::OM->{Permissions}}),'IPC uses same read capability as overview');
ok(!grep({$_==40} @IDs),'denied candidate never appears');
my @Open=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_TicketRowsBuild(TicketIDs=>\@IDs,IncludeClosed=>0);
my @All=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_TicketRowsBuild(TicketIDs=>\@IDs,IncludeClosed=>1);
is(scalar @Open,20,'outstanding workspace matches twenty permitted nonclosed tickets');
is(scalar @All,39,'including closed retains all permitted historical tickets');
my %Page=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_WorkspacePage(Rows=>\@Open,PageSize=>9,Page=>1);
is($Page{WorkspaceCount},20,'header total is before pagination');is(scalar @{$Page{WorkspaceRows}},9,'page contains configured nine rows');is($Page{WorkspaceNextPage},2,'next page exists');
my @Paged;
for my $N (1..3) {my %P=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_WorkspacePage(Rows=>\@Open,PageSize=>9,Page=>$N);push @Paged,map {$_->{TicketID}} @{$P{WorkspaceRows}};}
is_deeply(\@Paged,[map {$_->{TicketID}} @Open],'all twenty records reachable exactly once across pages');
my %Last=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_WorkspacePage(Rows=>\@Open,PageSize=>9,Page=>999);
is($Last{WorkspacePage},3,'stale page clamps to last page');is($Last{WorkspacePageStart},19,'last page begins nineteen');is($Last{WorkspacePageEnd},20,'last page ends twenty');
my %Empty=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_WorkspacePage(Rows=>[],PageSize=>9,Page=>2);is($Empty{WorkspaceCount},0,'empty view has zero total');is_deeply($Empty{WorkspaceRows},[],'empty view has no slice artifacts');
my %Invalid=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_WorkspacePage(Rows=>\@Open,PageSize=>9,Page=>'<bad>');is($Invalid{WorkspacePage},1,'invalid page defaults safely');
my %Unlimited=Kernel::Output::HTML::CustomerDashboard::TileTicketList::_WorkspacePage(Rows=>\@Open,PageSize=>0,Page=>1);is(scalar @{$Unlimited{WorkspaceRows}},9,'zero size falls back to bounded default instead of rendering all');
open my $FH,'<:encoding(UTF-8)','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/Dashboard/TileTicketList.tt' or die;
my $Template=do {local $/;<$FH>};my $TT=Template->new();my $Out='';my %Data=(%Page,TileID=>1,ShowAllWorkspace=>1);
ok($TT->process(\$Template,{Data=>\%Data,Env=>sub{'/otobo/customer.pl?'}},\$Out),'workspace template renders');
like($Out,qr/20 item\(s\)/,'rendered header reports total twenty');like($Out,qr/Showing 1.*9 of 20/,'rendered page range is explicit');like($Out,qr/ShowAllWorkspace=1;WorkspacePage=2/,'paging retains closed filter');like($Out,qr/aria-label="Workspace ticket pages"/,'pagination navigation named');like($Out,qr/&lt;unsafe&gt;/,'ticket title remains escaped');unlike($Out,qr/>Previous<\/a>/,'first page has no previous action');
done_testing;
