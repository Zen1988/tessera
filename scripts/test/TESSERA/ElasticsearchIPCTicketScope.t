use strict;use warnings;use Test::More;use JSON::PP;use Cwd qw(abs_path);use lib '.';
my $Module=abs_path('Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/Elasticsearch.pm');require $Module;
# Exercise the actual existing IPC classification without loading unrelated
# ticket permission dependencies into this isolated Elasticsearch fixture.
open my $RoleFH,'<','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/Ticket/CustomerPermission/ZTSMUserIDCheck.pm' or die;
my $RoleSource=do {local $/;<$RoleFH>};my ($Role)=$RoleSource=~/(sub _IsIPCAgent \{.*?)(?=sub )/s;die 'Missing IPC classifier' if !$Role;
eval "package Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck; $Role;1" or die $@;
{package ESFixture;
 sub Get {my($S,$Key)=@_;if($Key eq 'Kernel::Config'){return bless {fixture=>$S},'ESConfig'}return $S;}
 sub PermissionCheck {my($S,%P)=@_;return $P{GroupName} eq 'IPC' && $P{Type} eq 'rw' && $P{UserID} eq 'ipc' && $S->{IPC};}
 sub UserLookup {return}
 sub GroupMemberList {return (7=>'customers')}
 sub CustomerIDs {return ('ACME')}
 sub GroupContextNameGet {return}
 sub Run {my($S,%P)=@_;$S->{Request}=$P{Data};return {Data=>{Total=>20,Records=>[{TicketID=>100,TicketNumber=>'T100',Title=>'public',Created=>1000,ArticlesInternal=>['private'],AttachmentsInternal=>['private-file']}]}}}
 sub Log {1}
 sub Create {$_[0]}
 sub ToEpoch {2000}
}
{package ESConfig;sub Get {my($S,$Key)=@_;return {Ticket=>['Title'],Article=>['Body'],DynamicField=>[]} if $Key eq 'Elasticsearch::TicketSearchFields';return;}}
local $Kernel::OM=bless {IPC=>1},'ESFixture';my $ES=bless {WebserviceID=>1},'Kernel::System::Elasticsearch';
my $Result=$ES->TicketSearch(CustomerUserID=>'ipc',Fulltext=>'needle',Result=>'FULL',Permission=>'ro',ExtendedSearch=>0,Limit=>10);
is($Result->{Total},20,'IPC response retains full matching total, not preview size');is(scalar @{$Result->{Data}},1,'returned row count remains independent of total');
ok(!exists $Result->{Data}[0]{100}{ArticlesInternal} && !exists $Result->{Data}[0]{100}{AttachmentsInternal},'IPC FULL result omits internal article and attachment source');
my $Query=JSON::PP->new->encode($Kernel::OM->{Request});
unlike($Query,qr/CustomerID|CustomerUserID|GroupID/,'IPC global read has no implicit company/requester/group narrowing');
like($Query,qr/ArticlesExternal/,'customer searches external articles');unlike($Query,qr/ArticlesInternal|AttachmentsInternal/,'IPC ticket read does not reveal internal content');
is($Kernel::OM->{Request}{Limit},10,'configured preview limit preserved');
$ES->TicketSearch(CustomerUserID=>'ipc',CustomerIDRaw=>['NARROW'],Fulltext=>'needle',Result=>'ARRAY',Permission=>'ro',ExtendedSearch=>0,Limit=>10);
$Query=JSON::PP->new->encode($Kernel::OM->{Request});like($Query,qr/NARROW/,'explicit IPC customer filter retained');
$ES->TicketSearch(CustomerUserID=>'ordinary',Fulltext=>'needle',Result=>'ARRAY',Permission=>'ro',ExtendedSearch=>0,Limit=>10);
$Query=JSON::PP->new->encode($Kernel::OM->{Request});like($Query,qr/ACME/,'ordinary customer keeps native company scope');like($Query,qr/GroupID/,'ordinary customer keeps native group boundary');
ok(!$ES->CustomerGlobalTicketRead(CustomerUserID=>'ipc',Permission=>'rw'),'global IPC ticket read never grants write');
$Kernel::OM->{IPC}=0;ok(!$ES->CustomerGlobalTicketRead(CustomerUserID=>'ipc',Permission=>'ro'),'revoked membership evaluated on next request');
$ES->TicketSearch(CustomerUserID=>'ipc',Fulltext=>'needle',Result=>'ARRAY',Permission=>'ro',ExtendedSearch=>0,Limit=>10);
$Query=JSON::PP->new->encode($Kernel::OM->{Request});like($Query,qr/ACME/,'revoked IPC falls back to native restricted customer scope');
ok(!$ES->CustomerGlobalTicketRead(CustomerUserID=>['ipc']),'malformed identity cannot acquire global access');
done_testing;
