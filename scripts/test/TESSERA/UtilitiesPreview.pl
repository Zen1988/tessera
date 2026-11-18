use strict;
use warnings;
use utf8;
use Template;
use Encode qw(encode);
use File::Path qw(make_path);
my $T=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard',ENCODING=>'utf8');
make_path('outputs/utilities011-preview');
my @Rows=(
    {ID=>'ticket-search',Name=>'Advanced ticket search',Description=>'Find tickets using detailed search filters.',Enabled=>1},
    {ID=>'network-simulation',Name=>'Network simulation',Description=>'Explore permitted systems and analyze network paths.',Enabled=>1},
    {ID=>'vault',Name=>'CyberArk',Description=>'Access privileged account services.',External=>1,Enabled=>1},
    {ID=>'monitor',Name=>'Monitoring',Description=>'Open operational dashboards.',External=>1,Enabled=>1},
);
for my $Name ('CustomerUtilities','AgentUtilities','TESSERAUtilitiesShortcuts') {
    my $HTML='';my $D={Tools=>\@Rows,Tool=>{ID=>'vault',Name=>'CyberArk',Description=>'Access privileged account services.',Type=>'External',URL=>'https://vault.example.org/',Audience=>'users',Order=>30,Enabled=>1,Workplace=>1},UsersText=>'alice',ParametersText=>'{"username":{"Source":"CustomerUserLogin","Required":1}}',Handlers=>[{ID=>'TicketSearch',Name=>'Advanced ticket search'},{ID=>'NetworkSimulation',Name=>'Network simulation'}],Revision=>'example'};
    $T->process($Name.'.tt',{Data=>$D,Env=>sub {my $N=shift;return $N eq 'ChallengeToken'?'example':'/customer.pl?'}},\$HTML) or die $T->error;
    my $StyleFile=$Name eq 'AgentUtilities'?'var/httpd/htdocs/skins/Agent/default/css/TESSERA.Agent.Utilities.css':'var/httpd/htdocs/skins/Customer/default/css/TESSERA.Customer.Utilities.css';
    open my $SF,'<:raw',$StyleFile or die $!;local $/;my $Style=<$SF>;close $SF;
    open my $F,'>:raw','outputs/utilities011-preview/'.$Name.'.html' or die $!;
    print $F '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'.$Name.'</title><style>body{margin:0;background:#f6f6f9;font-family:Arial,sans-serif}h1,h2{font-weight:600}button{background:#00023c;color:white;border:0;border-radius:5px}a{color:#192569}nav a{text-decoration:none}input,textarea,select,button{font:inherit}.Hidden{position:absolute;width:1px;height:1px;overflow:hidden}'.$Style.'</style>'.encode('UTF-8',$HTML).'</html>';close $F;
}
