use strict;use warnings;use utf8;use Template;use JSON::PP;use Cwd qw(abs_path);use File::Path qw(make_path);
my $Dir='outputs/workplace198-preview';make_path($Dir);
my $Stage='Kernel/Package/GovernanceDB';
sub readfile {open my $F,'<:encoding(UTF-8)',$_[0] or die $!;return do{local $/;<$F>}}
my $Source=readfile("$Stage/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/TESSERAWorkplaceSearch.tt");
my $TT=Template->new();my %Pages;
for my $Scope (qw(All People People2 Asset FAQ)) {
 my $Type=$Scope eq 'People2'?'People':$Scope;my @Rows;
 for my $T ($Scope eq 'All'?qw(Ticket Asset FAQ People):($Type)) {
  for my $N ($Scope eq 'People2'?(11..13):(1..10)) {
   push @Rows,{Type=>$T,ID=>$N,Name=>$T eq 'People'?"Person $N":"$T result $N — workplace search example",Description=>$T eq 'People'?"person$N\@example.test":"REF-$N",Contact=>$T eq 'People'?'1234 5678':'',Action=>$T eq 'People'?'':$T eq 'FAQ'?'CustomerFAQZoom':$T eq 'Asset'?'CustomerITSMConfigItemZoom':'CustomerTicketZoom',Parameter=>$T eq 'FAQ'?'ItemID':$T eq 'Asset'?'ConfigItemID':'TicketID'};
  }
 }
 my $Out='';$TT->process(\$Source,{Data=>{SearchQuery=>'needle',SearchScope=>$Type,All=>$Type eq 'All',PageSize=>10,Rows=>\@Rows,Shown=>scalar @Rows,Total=>13,Types=>[map {{Scope=>$_,Count=>13}} qw(Ticket Asset FAQ People)],Page=>$Scope eq 'People2'?2:1,Pages=>2,PreviousPage=>$Scope eq 'People2'?1:0,NextPage=>$Scope eq 'People2'?0:2},Env=>sub {$_[0] eq 'Baselink'?'customer.pl?':''}},\$Out) or die $TT->error();$Pages{$Scope}=$Out;
}
my $CSS=readfile("$Stage/var/httpd/htdocs/skins/Customer/default/css/TESSERA.Customer.SearchDialog.css");
my $JS=readfile("$Stage/var/httpd/htdocs/js/TESSERA.Customer.SearchPaging.js");
my $Tests=readfile('scripts/test/TESSERA/WorkplaceSearch.browser.js');my $JSON=JSON::PP->new->encode(\%Pages);$JSON=~s{</}{<\/}g;
my $JQuery='file:///' . abs_path('otobo-11.1.0-beta2/var/httpd/htdocs/js/thirdparty/jquery-3.7.1/jquery.min.js');
open my $F,'>:encoding(UTF-8)',"$Dir/preview.html" or die $!;
print $F qq{<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{font:14px Arial;margin:0;background:#edf0f7;color:#33405b}.Dialog{position:fixed}.Header h2{margin:0}button{font:inherit}td{font-size:14px}#testStatus{position:fixed;top:0;left:0;font-size:10px;max-height:60px;overflow:auto} $CSS</style></head><body><input id="oooSearch" value="needle" aria-label="Search Workplace"><div class="Dialog"><div class="Header"><h2>Workplace search</h2><a class="Close" href="#" aria-label="Close"></a></div><div class="Content"><div id="oooESOuter">$Pages{All}</div></div></div><pre id="testStatus">pending</pre><script src="$JQuery"></script><script>var pages=$JSON;var requests=[];var Core={Config:{Get:function(){return '';}},AJAX:{FunctionCall:function(url,data,callback){var d=\$.Deferred();requests.push({data:data,deferred:d});d.done(callback);return d.promise();}}};</script><script>$JS</script><script>$Tests</script></body></html>};
close $F;print "Rendered $Dir/preview.html\n";
