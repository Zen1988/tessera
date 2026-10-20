use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Template;
open my $SourceFile, '<', 'Kernel/Package/GovernanceDB/Kernel/Modules/CustomerTicketZTSMAction.pm' or die $!;
my $Source = do { local $/; <$SourceFile> };
$Source =~ s{^use Kernel::[^;]+;\r?\n}{}mg;
eval $Source; die $@ if $@;
{
    package PortalRequest;
    sub RequestMethod { $_[0]->{Method} }
    sub RemoteAddr { '192.0.2.10' }
    sub GetParam { my ($Self, %Param)=@_; return $Self->{Params}->{$Param{Param}} }
    package PortalLayout;
    sub CustomerNoPermission { 'DENIED' }
    sub CustomerHeader { 'HEADER' }
    sub CustomerFooter { 'FOOTER' }
    sub CustomerNavigationBar { 'NAVIGATION' }
    sub Output { my ($Self,%Param)=@_; $Self->{Rendered}=$Param{Data}; return 'SECURITYBLOCK' }
    sub ChallengeTokenCheck { my ($Self,%Param)=@_; $Self->{Checks}++; die 'Invalid customer token' if !$Self->{Valid}; die 'Wrong token scope' if $Param{Type} ne 'Customer'; return 1 }
    package PortalConfig;
    sub Get { 1 }
    package PortalMain;
    sub GenerateRandomString { 'PublicEventReference1234' }
    package PortalLog;
    sub Log { my ($Self,%Param)=@_; push @{$Self->{Events}},\%Param; return 1 }
    package PortalArticle;
    sub ArticleCreate { my ($Self,%Param)=@_; push @{$Self->{Articles}},\%Param; return $Self->{Fail} ? undef : 123 }
    package PortalResponse;
    sub Code { $_[0]->{Code}=$_[1] }
    package PortalTicket;
    sub TicketCustomerPermission { 1 }
    sub TicketGet { (TicketID=>1, Type=>'Approval') }
    package PortalDeniedTicket;
    sub TicketCustomerPermission { 0 }
    sub TicketGet { die 'Unauthorized ticket data read' }
    package PortalPermission;
    sub Run { 0 }
    package PortalOM;
    sub Get { my ($Self,$Name)=@_; return $Self->{Objects}->{$Name} || die "Unexpected dependency $Name" }
    package PortalAction;
    our @ISA=('Kernel::Modules::CustomerTicketZTSMAction');
    sub _IsIPCAgent { 0 }
    sub _TicketDynamicFieldSet { die 'MUTATION REACHED' }
}
my $Request=bless {Method=>'GET',Params=>{}},'PortalRequest';
my $Layout=bless {UserChallengeToken=>'session-token',Valid=>1,Checks=>0},'PortalLayout';
my $Action=bless {UserID=>'authenticated-customer'},'PortalAction';
my %Args=(LayoutObject=>$Layout,ParamObject=>$Request,TicketType=>'Approval',RuntimeAction=>'Approve',Subaction=>'');
ok(!$Action->_CustomerRequestSecurityCheck(%Args),'GET cannot mutate');
$Request->{Method}='POST';
ok(!$Action->_CustomerRequestSecurityCheck(%Args),'POST without token denied');
$Request->{Params}->{ChallengeToken}='forged';
ok(!$Action->_CustomerRequestSecurityCheck(%Args),'forged current-session token denied');
is($Layout->{Checks},0,'invalid proofs rejected even if native CSRF configuration is disabled');
$Request->{Params}->{ChallengeToken}='session-token';
ok($Action->_CustomerRequestSecurityCheck(%Args),'valid POST passes customer framework token check');
is($Layout->{Checks},1,'framework customer checker invoked');
$Layout->{Valid}=0;
ok(!$Action->_CustomerRequestSecurityCheck(%Args),'framework denial remains blocked');
is($Action->{CustomerSecurityRejectionReason},'csrf_check_failed','framework failure gets auditable reason without disclosing exception');
$Layout->{Valid}=1;
$Layout->{UserChallengeToken}='';
ok(!$Action->_CustomerRequestSecurityCheck(%Args),'missing session proof denied');
$Layout->{UserChallengeToken}='session-token';
$Request->{Method}='GET';
for my $Case (['Assessment','Assess','RiskAssessmentInline'],['Assessment','Assess',''],['Diagnosis','Diagnose','DiagnosisInline'],['Diagnosis','Diagnose','']) {
    ok($Action->_CustomerRequestSecurityCheck(%Args,TicketType=>$Case->[0],RuntimeAction=>$Case->[1],Subaction=>$Case->[2]),'read-only workspace remains reachable');
}
for my $Subaction (qw(RiskAssessmentInline DiagnosisInline SubmitRiskAssessment SubmitDiagnosis)) {
    ok(!$Action->_CustomerRequestSecurityCheck(%Args,RuntimeAction=>'RequesterHold',Subaction=>$Subaction),'inline/submit parameter cannot exempt a mutation');
}
for my $Subaction (qw(RiskStatementDefaults RiskAssessmentScales RiskScoreLevels ZTSMCustomerUserSearch)) {
    ok($Action->_CustomerRequestSecurityCheck(%Args,Subaction=>$Subaction),'terminal read-only JSON branch remains reachable');
}
# Exercise actual Run: forged GET/POST must return before action configuration or mutation.
our $KernelOM;
local $Kernel::OM=bless {Objects=>{
    'Kernel::Config'=>bless({},'PortalConfig'),
    'Kernel::Output::HTML::Layout'=>$Layout,
    'Kernel::System::Web::Request'=>$Request,
    'Kernel::System::Ticket'=>bless({},'PortalTicket'),
    'Kernel::System::Main'=>bless({},'PortalMain'),
    'Kernel::System::Log'=>bless({Events=>[]},'PortalLog'),
    'Kernel::System::Ticket::Article::Backend::Internal'=>bless({Articles=>[]},'PortalArticle'),
    'Kernel::System::Web::Response'=>bless({},'PortalResponse'),
}},'PortalOM';
for my $Method (qw(GET POST)) {
    $Request->{Method}=$Method;
    $Request->{Params}={TicketID=>1,RuntimeAction=>'Reject',ChallengeToken=>'forged'};
    my $Result=eval {$Action->Run()};
    is($@,'','forged request never reaches mutation/dependencies');
    is($Result,'HEADERSECURITYBLOCKNAVIGATIONFOOTER','actual endpoint rejects forged '.$Method.' within portal shell');
}
is($Layout->{Rendered}{AttemptedAction},'Reject','supplied runtime action reaches rendered page');
my $Objects=$Kernel::OM->{Objects};
is($Objects->{'Kernel::System::Web::Response'}->{Code},403,'real HTTP403 set');
my $Article=$Objects->{'Kernel::System::Ticket::Article::Backend::Internal'}->{Articles}->[-1];
is($Article->{IsVisibleForCustomer},0,'ticket audit is internal only');
is($Article->{SenderType},'system','audit attributed to recording system, not forged customer sender');
is($Article->{UserID},1,'backend recording identity is distinct from customer actor');
like($Article->{Body},qr/authenticated-customer/,'authenticated actor recorded');
like($Article->{Body},qr/csrf_mismatch/,'specific rejection reason recorded');
unlike($Article->{Body},qr/forged|session-token|ChallengeToken/,'no submitted or session tokens in note');
my $Log=$Objects->{'Kernel::System::Log'}->{Events}->[-1]->{Message};
like($Log,qr/^TESSERA_SECURITY /,'structured system security log');
$Log =~ s/^TESSERA_SECURITY //;
my $Event=JSON::PP->new->decode($Log);
is($Event->{PeerAddress},'192.0.2.10','connection peer recorded without trusting forwarded headers');
is($Event->{ActorID},'authenticated-customer','actor from authenticated context');
is($Event->{Outcome},'blocked','outcome is blocked, not a confirmed attack');
like($Event->{TimeUTC},qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/,'UTC event time recorded');
my $Before=@{$Objects->{'Kernel::System::Ticket::Article::Backend::Internal'}->{Articles}};
$Action->_CustomerSecurityRequestAudit(LayoutObject=>$Layout,ParamObject=>$Request,TicketID=>999,RuntimeAction=>'Reject',Reason=>'ticket_access_denied',TicketReadable=>0);
is(scalar @{$Objects->{'Kernel::System::Ticket::Article::Backend::Internal'}->{Articles}},$Before,'inaccessible target receives no audit note');
$Request->{Params}->{Body}='PRIVATE SUBMITTED BODY';
$Action->_CustomerSecurityRequestAudit(LayoutObject=>$Layout,ParamObject=>$Request,TicketID=>1,RuntimeAction=>"Bad\nAction",Subaction=>'test',Reason=>'csrf_missing',TicketReadable=>1);
my $LastLog=$Objects->{'Kernel::System::Log'}->{Events}->[-1]->{Message};
unlike($LastLog,qr/\n|PRIVATE SUBMITTED BODY/,'log is one line and does not capture submitted content');
$Objects->{'Kernel::System::Ticket::Article::Backend::Internal'}->{Fail}=1;
my $Result=$Action->_CustomerSecurityRequestReject(LayoutObject=>$Layout,ParamObject=>$Request,TicketID=>1,RuntimeAction=>'Reject',Reason=>'csrf_missing',TicketReadable=>1);
is($Result,'HEADERSECURITYBLOCKNAVIGATIONFOOTER','audit-note failure does not allow action');
is($Objects->{'Kernel::System::Web::Response'}->{Code},403,'audit-note failure remains403');
like($Objects->{'Kernel::System::Log'}->{Events}->[-1]->{Message},qr/audit_note_failed/,'audit persistence failure is recorded');
# Render the actual new template with hostile display values: never inject identity/action as markup.
my $Template=Template->new({INCLUDE_PATH=>'Kernel/Package/GovernanceDB/Kernel/Output/HTML/Templates/Standard'});
my $HTML='';
ok($Template->process('CustomerSecurityRequestRejected.tt',{
    Data=>{CustomerUserID=>'<img src=x onerror=evil()>',AttemptedAction=>'<script>evil()</script>',EventID=>'PublicEventReference1234',Recorded=>1},
    Env=>sub {'/otobo/customer.pl?'},Translate=>sub {$_[0]},
},\$HTML),'security template renders');
unlike($HTML,qr/<script>|<img /,'actor and action cannot become active HTML');
like($HTML,qr/&lt;script&gt;/,'hostile action displayed as text');
like($HTML,qr/role="alert"/,'warning is accessible');
like($HTML,qr/Return to your tickets/,'safe portal navigation provided');
{
    local $Objects->{'Kernel::System::Ticket'}=bless({},'PortalDeniedTicket');
    local $Objects->{'Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck'}=bless({},'PortalPermission');
    my $BeforeNotes=@{$Objects->{'Kernel::System::Ticket::Article::Backend::Internal'}->{Articles}};
    my $Denied=eval {$Action->Run()};
    is($@,'','inaccessible ticket is not read');
    is($Denied,'HEADERSECURITYBLOCKNAVIGATIONFOOTER','permission rejection uses same themed security response');
    is(scalar @{$Objects->{'Kernel::System::Ticket::Article::Backend::Internal'}->{Articles}},$BeforeNotes,'permission rejection does not write another ticket');
    like($Objects->{'Kernel::System::Log'}->{Events}->[-1]->{Message},qr/ticket_access_denied/,'permission rejection audited in system log');
}
$Action->_CustomerSecurityRequestReject(LayoutObject=>$Layout,ParamObject=>$Request,TicketID=>1,RuntimeAction=>'',Reason=>'method_not_post',TicketReadable=>0);
is($Layout->{Rendered}{AttemptedAction},'No runtime action supplied','missing runtime action has explicit truthful label');
done_testing();
