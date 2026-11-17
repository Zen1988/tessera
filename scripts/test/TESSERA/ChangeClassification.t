use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use Template;
use lib '.', 'Custom', 'Kernel/cpan-lib';
use Kernel::System::TESSERA::ChangeClassification;
use Kernel::System::DynamicField::Driver::TESSERAChangeDropdown;
use Kernel::Modules::CustomerChangeAnnouncement;
use Kernel::Modules::CustomerChangeClassification;
use Kernel::System::Ticket::Event::ChangeDecisionDefaults;
{
 package CCConfig;sub Get {$_[0]{OM}{Config}{$_[1]}}
 package CCGroup;sub PermissionCheck {my ($S,%P)=@_;$S->{OM}{AgentGroups}{$P{UserID}}{$P{GroupName}}}
 package CCCustomerGroup;sub PermissionCheck {my ($S,%P)=@_;$S->{OM}{CustomerGroups}{$P{UserID}}{$P{GroupName}}}
 package CCDB;
 sub Prepare {
  my ($S,%P)=@_;my $M=$S->{OM};
  if ($P{SQL}=~/GET_LOCK/) {$S->{Rows}=[[1]]}
  elsif ($P{SQL}=~/information_schema/) {$S->{Rows}=[map {[$$_,$M->{BadEngine}?'MyISAM':'InnoDB']} @{$P{Bind}}]}
  elsif ($P{SQL}=~/RELEASE_LOCK/) {$M->{Released}++;$S->{Rows}=[[1]]}
  elsif ($P{SQL}=~/JOIN ticket_type/) {$S->{Rows}=[[$M->{DatabaseType} || $M->{Tickets}{1}{Type},$M->{DatabaseState} || $M->{Tickets}{1}{State},$M->{Tickets}{1}{StateType}]]}
  elsif ($P{SQL}=~/FROM dynamic_field f/) {my $ID=${$P{Bind}[0]};$S->{Rows}=[map {[$_,$M->{Tickets}{$ID}{'DynamicField_'.$_}]} qw(ChangeType ChangeClassification)]}
  elsif ($P{SQL}=~/FROM dynamic_field_value/) {my ($F,$ID)=map {$$_} @{$P{Bind}};$S->{Rows}=exists $M->{Stored}{$ID}{$F}?[[1]]:[]}
  elsif ($P{SQL}=~/ticket_history/) {$M->{ApprovalQuery}++;$S->{Rows}=$M->{LastGate}?[[$M->{LastGate}]]:[]}
  else {my $Key=${$P{Bind}[0]};$S->{Rows}=exists $M->{Records}{$Key}?[[$M->{Records}{$Key}]]:[]}
  return 1;
 }
 sub FetchrowArray {my $R=shift @{$_[0]{Rows}};return $R?@$R:()}
 sub Do {my ($S,%P)=@_;return if $S->{OM}{FailRecord};my ($Key,$Raw)=$P{SQL}=~/INSERT/?map {$$_} @{$P{Bind}}[0,1]:map {$$_} @{$P{Bind}}[2,0];$S->{OM}{Records}{$Key}=$Raw;return 1}
 sub BeginWork {my ($S)=@_;$S->{Saved}=Storable::dclone({map {$_=>$S->{OM}{$_}} qw(Tickets Records Articles Stored)});$S->{Begun}++;return 1}
 sub commit {return if $_[0]{OM}{FailCommit};$_[0]{Committed}++;delete $_[0]{Saved};return 1}
 sub Rollback {my ($S)=@_;$S->{RolledBack}++;for (keys %{$S->{Saved}}) {$S->{OM}{$_}=$S->{Saved}{$_}};delete $S->{Saved};return 1}
 package CCOM;
 sub Get {
  my ($M,$N)=@_;return $M->{Service} if $N eq 'Kernel::System::TESSERA::ChangeClassification';
  return $M->{DB} if $N eq 'Kernel::System::DB';
  return bless({OM=>$M},'CCConfig') if $N eq 'Kernel::Config';
  return bless({OM=>$M},'CCGroup') if $N eq 'Kernel::System::Group';
  return bless({OM=>$M},'CCCustomerGroup') if $N eq 'Kernel::System::CustomerGroup';return $M;
 }
 sub GetUserData {my ($M,%P)=@_;return if !$M->{Users}{$P{UserID}};return (ValidID=>1,UserLogin=>$M->{Users}{$P{UserID}})}
 sub UserLookup {my ($M,%P)=@_;my %R=reverse %{$M->{Users}};return $R{$P{UserLogin}}}
 sub CustomerUserDataGet {my ($M,%P)=@_;return if !$M->{Customers}{$P{User}};return (ValidID=>1,UserFirstname=>'Request',UserLastname=>'User',UserEmail=>'private@example.org')}
 sub TicketGet {my ($M,%P)=@_;return %{$M->{Tickets}{$P{TicketID}} || {}}}
 sub TicketPermission {$_[0]{TicketPermissionCalls}++;$_[0]{TicketWrite}}
 sub TicketCustomerPermission {$_[0]{TicketPermissionCalls}++;$_[0]{TicketWrite}}
 sub TicketSearch {my ($M,%P)=@_;push @{$M->{Searches}},\%P;return @{$M->{Assessments}} if $P{Types}[0] eq 'Assessment';return grep {($M->{Tickets}{$_}{Type} || '') eq 'Change' && ($M->{Tickets}{$_}{DynamicField_ChangeClassification} || '') eq 'Major'} keys %{$M->{Tickets}}}
 sub DynamicFieldGet {my ($M,%P)=@_;return $M->{Fields}{$P{Name}} || {}}
 sub GovernanceObjectGet {my ($M,%P)=@_;$M->{GovernanceReads}++;return $M->{Governance}{$P{GovernanceObjectID}}}
 sub ConfigItemGet {my ($M,%P)=@_;return {Name=>'CI-'.$P{ConfigItemID},Private=>'password'}}
 sub LinkList {{ITSMConfigItem=>{Normal=>{Target=>{202=>1}}}}}
 sub ToAscii {my ($M,%P)=@_;my $S=$P{String};$S=~s/<[^>]*>//g;return $S}
 sub ValueGet {
  my ($M,%P)=@_;if ($P{DynamicFieldConfig}) {my $Name=$P{DynamicFieldConfig}{Name};return $Name=~/\A(?:ChangeType|ChangeClassification)\z/?$M->{Tickets}{$P{ObjectID}}{'DynamicField_'.$Name}:$M->{Runbook}{$Name}}
  my $V=$M->{Stored}{$P{ObjectID}}{$P{FieldID}};return defined $V?[{ValueText=>$V}]:[];
 }
 sub ValueSet {
  my ($M,%P)=@_;
  if ($P{DynamicFieldConfig}) {return $M->{Driver}->ValueSet(%P)}
  return if $M->{FailField};my $Value=$P{Value}[0]{ValueText};$M->{Stored}{$P{ObjectID}}{$P{FieldID}}=$Value;
  for my $Name (qw(ChangeType ChangeClassification)) {$M->{Tickets}{$P{ObjectID}}{'DynamicField_'.$Name}=$Value if $M->{Fields}{$Name}{ID}==$P{FieldID}}
  return 1;
 }
 sub BackendForChannel {$_[0]}
 sub ArticleList {$_[0]{ArticleReads}++;return ({ArticleID=>101,IsVisibleForCustomer=>!$_[0]{PrivateFirstArticle}})}
 sub BackendForArticle {$_[0]}
 sub ArticleGet {(Body=>'Original request description',MimeType=>'text/plain')}
 sub ArticleCreate {my ($M,%P)=@_;return if $M->{FailArticle};push @{$M->{Articles}},\%P;return scalar @{$M->{Articles}}}
 sub StateList {(1=>'approved',2=>'assess',3=>'in-progress',4=>'closed rejected')}
 sub GetParam {my ($M,%P)=@_;$M->{Params}{$P{Param}}}
 sub CustomerNoPermission {'DENIED'}sub NoPermission {'DENIED'}
 sub CustomerErrorScreen {'ERROR'}sub ErrorScreen {'ERROR'}
 sub CustomerHeader {''}sub CustomerNavigationBar {''}sub CustomerFooter {''}
 sub Header {''}sub NavigationBar {''}sub Footer {''}
 sub Output {my ($M,%P)=@_;$M->{Output}=\%P;return 'PAGE'}
 sub RequestMethod {$_[0]{Method} || 'GET'}sub ChallengeTokenCheck {$_[0]{TokenOK}}
 sub TicketIDLookup {my ($M,%P)=@_;return 1 if $P{TicketNumber} eq 'C-1';return}
 sub Redirect {my ($M,%P)=@_;$P{OP}}
}
my $M=bless {Config=>{'TESSERA::ChangeClassification::Groups'=>[],'TESSERA::ChangeClassification::ApprovalStates'=>['approved'],'TESSERA::ChangeClassification::WithdrawalStates'=>['assess','closed rejected'],'CustomerPanelUserID'=>1},
 Users=>{7=>'cab',8=>'ipc',9=>'ordinary'},Customers=>{cab=>1,ipc=>1,ordinary=>1,viewer=>1},AgentGroups=>{7=>{'CAB-Configured'=>1},8=>{IPC=>1}},CustomerGroups=>{},
 Tickets=>{1=>{TicketID=>1,TicketNumber=>'C-1',Title=>'UAT infrastructure patching',Type=>'Change',State=>'assess',StateType=>'open',CustomerUserID=>'ordinary',Service=>'Core infrastructure',
 'DynamicField_ZTicket-Env'=>11,'DynamicField_ZTicket-Application'=>12,'DynamicField_ZTicket-BlueBook'=>13,'DynamicField_ZTicket-ScheduleStart'=>'2026-11-20 21:00:00','DynamicField_ZTicket-ScheduleFinish'=>'2026-11-20 23:00:00','DynamicField_ZRM-RiskTargetCI'=>[201],PrivateHistory=>'secret'},
 10=>{TicketID=>10,Type=>'Assessment',State=>'closed successful','DynamicField_ZTicket-Parent'=>1}},Assessments=>[10],
 Governance=>{11=>{Class=>'Environment',Name=>'UAT'},12=>{Class=>'Application',Name=>'Core system'},13=>{Class=>'BlueBook',Name=>'Patching runbook'}},
 Fields=>{ChangeType=>{ID=>1,Name=>'ChangeType',ObjectType=>'Ticket',FieldType=>'Dropdown',Config=>{MultiValue=>0,PossibleValues=>{Normal=>'Normal',Standard=>'Standard',Emergency=>'Emergency'}}},
 ChangeClassification=>{ID=>2,Name=>'ChangeClassification',ObjectType=>'Ticket',FieldType=>'Dropdown',Config=>{MultiValue=>0,PossibleValues=>{Normal=>'Normal','Not-Assessed'=>'Not-Assessed',Major=>'Major'}}},
 'ZCH-Implementation'=>{ID=>3,Name=>'ZCH-Implementation',ObjectType=>'Ticket',FieldType=>'Set'}},
 Runbook=>{'ZCH-Implementation'=>[{'ZCH-Seq'=>['1'],'ZCH-Activity'=>['Install patch'],'ZCH-Description'=>['<b>Patch UAT only</b>'],'ZCH-Owner'=>'private-owner','ZCH-Profile'=>'private-profile'}]},
 Records=>{},Stored=>{},Articles=>[],Searches=>[],Params=>{},UserChallengeToken=>'real',TokenOK=>1,TicketWrite=>0},'CCOM';
$M->{DB}=bless {OM=>$M},'CCDB';$M->{DB}{dbh}=$M->{DB};$M->{Driver}=bless {},'Kernel::System::DynamicField::Driver::TESSERAChangeDropdown';
local $Kernel::OM=$M;my $B=Kernel::System::TESSERA::ChangeClassification->new();$M->{Service}=$B;
ok(!$B->Actor(UserID=>7),'no fixed CAB group or implicit admin authority');
ok($B->Actor(UserID=>8)->{IPC},'active IPC agent overrides configurable groups');
ok($B->Actor(CustomerUserID=>'ipc')->{IPC},'existing active same-login IPC mapping works in portal');
$M->{Customers}{'portal-ipc'}=1;$M->{CustomerGroups}{'portal-ipc'}{IPC}=1;
ok($B->Actor(CustomerUserID=>'portal-ipc')->{IPC},'native customer IPC write membership also works without provisioning an agent');
ok(!$B->Actor(CustomerUserID=>'viewer'),'ordinary portal viewer cannot classify');
$M->{Config}{'TESSERA::ChangeClassification::Groups'}=['CAB-Configured'];
ok($B->Actor(UserID=>7),'configured group grants classification role');
ok(!$B->CanManage(UserID=>7,TicketID=>1),'non-IPC manager still needs ticket write scope');
ok($B->CanManage(UserID=>8,TicketID=>1),'IPC overrides ticket scope only in dedicated management operation');
$M->{TicketWrite}=1;ok($B->CanManage(UserID=>7,TicketID=>1),'configured manager with ticket rights can manage');$M->{TicketWrite}=0;
my $V=$B->View(CustomerUserID=>'ipc',TicketID=>1);
is($V->{ChangeType},'Normal','missing field has Normal default');is($V->{ChangeClassification},'Not-Assessed','missing classification is Not-Assessed');
is($V->{Description},'Original request description','first customer-visible original description prefills management draft');
is($V->{Summary},'UAT infrastructure patching','ticket title prefills the public summary');
$M->{PrivateFirstArticle}=1;is($B->View(CustomerUserID=>'ipc',TicketID=>1)->{Description},'','private first article is never copied into announcement draft');$M->{PrivateFirstArticle}=0;
ok($V->{AssessmentComplete},'linked completed assessment recognized');
is($V->{Context}{BlueBook},'Patching runbook','bound BlueBook name resolved without evaluating it');
is_deeply($V->{Context}{Assets},['CI-201','CI-202'],'actual target and linked CI names resolved');
is($V->{Context}{Phases}[0]{Steps}[0]{Description},'Patch UAT only','submitted ZCH Set description projected as plain text');
ok(!exists $V->{Context}{Phases}[0]{Steps}[0]{Owner},'private runbook owner/profile excluded');
my $OriginalRunbook=dclone($M->{Runbook});
push @{$M->{Runbook}{'ZCH-Implementation'}},{'ZCH-BlueLevel'=>2,'ZCH-Seq'=>1,'ZCH-Activity'=>'Level two'},{'ZCH-BlueLevel'=>1,'ZCH-Seq'=>2,'ZCH-Activity'=>'Level one later'};
is_deeply([map {[$_->{Level},$_->{Sequence}]} @{$B->View(CustomerUserID=>'ipc',TicketID=>1)->{Context}{Phases}[0]{Steps}}],[[1,1],[1,2],[2,1]],'public runbook preserves executor level then sequence ordering');$M->{Runbook}=$OriginalRunbook;
my %Save=(CustomerUserID=>'ipc',TicketID=>1,Revision=>$V->{Revision},ChangeType=>'Normal',ChangeClassification=>'Major',Reason=>'Assessed UAT scope and business impact',Description=>'UAT maintenance',Summary=>'Patching approved UAT nodes');
ok(!eval {$B->Save(%Save,CustomerUserID=>'ordinary');1},'requester cannot forge management save');
my $F=$M->{Fields}{ChangeClassification};
ok(!$M->{Driver}->ValueSet(DynamicFieldConfig=>$F,ObjectID=>1,Value=>'Major',UserID=>1),'generic customer-panel identity cannot promote Major');
ok(!$M->{Driver}->ValueSet(DynamicFieldConfig=>$M->{Fields}{ChangeType},ObjectID=>1,Value=>'Emergency',UserID=>1),'generic writers cannot declare Emergency');
is_deeply($M->{Driver}->EditFieldRender(DynamicFieldConfig=>$F),{Field=>'',Label=>''},'controlled field not rendered on generic creation/edit screens');
ok(!$M->{Driver}->ValueSet(DynamicFieldConfig=>$F,ObjectID=>1,Value=>'Not-Assessed',UserID=>1),'even the default requires a server-owned initialization scope');
ok(!$M->{Driver}->ValueSet(DynamicFieldConfig=>$F,ObjectID=>1,Value=>'Not-Assessed',UserID=>1),'generic default cannot overwrite an existing decision');
ok(!eval {$B->Save(%Save,Summary=>'');1},'Major requires actual public summary content');
$M->{Tickets}{10}{State}='open';
ok(!eval {$B->Save(%Save);1},'classification waits for assessment completion');
ok(!eval {$B->Save(%Save,CustomerUserID=>'cab',AssessmentOverride=>1);1},'ordinary configured manager cannot use IPC assessment override');
ok($B->Save(%Save,AssessmentOverride=>1),'IPC may explicitly override assessment prerequisite');
like($M->{Articles}[-1]{Body},qr/Assessment override: yes/,'IPC assessment override recorded');
is($M->{Articles}[-1]{IsVisibleForCustomer},0,'decision reason stays in private evidence');
is($M->{Tickets}{1}{Type},'Change','native ticket type unchanged');
is($M->{Tickets}{1}{State},'assess','classification does not advance lifecycle');
is($M->{Tickets}{1}{DynamicField_ChangeClassification},'Major','new dropdown stores Major');
is_deeply($B->PublicList(CustomerUserID=>'viewer'),[],'unapproved Major not announced even after IPC classification');
$M->{Tickets}{10}{State}='closed successful';$M->{Tickets}{1}{State}='approved';
my $PermissionCalls=$M->{TicketPermissionCalls};my $ArticleReads=$M->{ArticleReads};my $Rows=$B->PublicList(CustomerUserID=>'viewer');
is(scalar @$Rows,1,'approved reviewed Major announced to unrelated active portal user');
is($M->{TicketPermissionCalls},$PermissionCalls,'announcement read does not require or broaden native ticket grants');
ok(!$M->TicketCustomerPermission(UserID=>'viewer',TicketID=>1,Type=>'ro'),'viewer still cannot open full ticket');
my $A=$B->PublicView(CustomerUserID=>'viewer',TicketID=>1);
is($M->{ArticleReads},$ArticleReads,'announcement reads never retrieve articles or history bodies');
my $ApprovalPolicy=delete $M->{Config}{'TESSERA::ChangeClassification::ApprovalStates'};
ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'missing approval configuration fails closed');$M->{Config}{'TESSERA::ChangeClassification::ApprovalStates'}=$ApprovalPolicy;
my $WithdrawalPolicy=delete $M->{Config}{'TESSERA::ChangeClassification::WithdrawalStates'};
ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'missing withdrawal configuration fails closed');$M->{Config}{'TESSERA::ChangeClassification::WithdrawalStates'}=$WithdrawalPolicy;
is($A->{Requester},'Request User','only requester display name is public');
ok(!exists $A->{PrivateHistory} && !exists $A->{CustomerUserID} && !exists $A->{UserEmail},'no raw ticket identity/history/contact projection');
ok(!exists $A->{Phases}[0]{Steps}[0]{Profile},'runbook does not disclose operational assignment');
$M->{DatabaseState}='closed rejected';ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'live database withdrawal beats stale cached approved state');delete $M->{DatabaseState};
$M->{DatabaseType}='Incident';ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'live database type beats stale cached Change');delete $M->{DatabaseType};
is_deeply($B->PublicList(CustomerUserID=>'anonymous'),[],'anonymous or inactive accounts denied');
ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>'1;Action=x'),'malformed direct ID denied');
$M->{Tickets}{1}{State}='in-progress';$M->{LastGate}=1;
ok($B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'approved announcement persists during execution using actual approval history');
$M->{LastGate}=2;ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'assessment/reapproval history invalidates earlier approval');
$M->{LastGate}=1;$M->{Tickets}{1}{State}='closed rejected';ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'withdrawn current state hides announcement');
$M->{Tickets}{1}{State}='approved';$M->{Runbook}{'ZCH-Implementation'}[0]{'ZCH-Description'}=['Changed without review'];
ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'changed submitted runbook needs new public review');
$M->{Runbook}{'ZCH-Implementation'}[0]{'ZCH-Description'}=['<b>Patch UAT only</b>'];
$V=$B->View(CustomerUserID=>'ipc',TicketID=>1);$Save{Revision}=$V->{Revision};
my $Before=dclone($M->{Records});$M->{FailArticle}=1;
ok(!eval {$B->Save(%Save,ChangeType=>'Emergency');1},'evidence failure fails the decision');
is_deeply($M->{Records},$Before,'transaction restores prior public snapshot on evidence failure');
is($M->{Tickets}{1}{DynamicField_ChangeType},'Normal','transaction restores prior field value');$M->{FailArticle}=0;
$M->{BadEngine}=1;ok(!eval {$B->Save(%Save);1},'nontransactional evidence storage is rejected before mutation');is_deeply($M->{Records},$Before,'storage preflight failure preserves publication');$M->{BadEngine}=0;
ok($B->Save(%Save,ChangeType=>'Emergency'),'authorized amendment succeeds');
ok(!eval {$B->Save(%Save);1},'stale revision cannot overwrite a newer decision');
$V=$B->View(CustomerUserID=>'ipc',TicketID=>1);$Save{Revision}=$V->{Revision};
ok($B->Save(%Save,ChangeClassification=>'Normal'),'manager can demote Major to Normal');
ok(!$B->PublicView(CustomerUserID=>'viewer',TicketID=>1),'demotion immediately withdraws announcement');
$V=$B->View(CustomerUserID=>'ipc',TicketID=>1);$Save{Revision}=$V->{Revision};ok($B->Save(%Save),'Major can be reviewed again');
ok(!eval {$B->Save(%Save);1},'identical form replay cannot duplicate private decision evidence');
$M->{Params}={TicketID=>1};is(Kernel::Modules::CustomerChangeAnnouncement->new(UserID=>'viewer')->Run(),'PAGE','dedicated announcement route works without full ticket grant');
ok(!exists $M->{Output}{Data}{Announcement}{History},'announcement controller never supplies article history');
$M->{Params}={TicketID=>1,Subaction=>'Save'};is(Kernel::Modules::CustomerChangeAnnouncement->new(UserID=>'viewer')->Run(),'DENIED','public announcement route is read-only');
$M->{Params}={TicketID=>1,Subaction=>'Save'};
is(Kernel::Modules::CustomerChangeClassification->new(UserID=>'ipc')->Run(),'DENIED','GET cannot mutate classifications');
$M->{Method}='POST';$M->{Params}{ChallengeToken}='wrong';is(Kernel::Modules::CustomerChangeClassification->new(UserID=>'ipc')->Run(),'DENIED','CSRF mismatch denied');
is(Kernel::Modules::CustomerChangeClassification->new(UserID=>'viewer')->Run(),'DENIED','ordinary requester cannot open the editor');
my $TT=Template->new(INCLUDE_PATH=>'Kernel/Output/HTML/Templates/Standard',ENCODING=>'utf8');my $HTML='';$A->{Title}='<script>bad</script>';
ok($TT->process('CustomerChangeAnnouncement.tt',{Data=>{Announcement=>$A},Env=>sub {'/customer.pl?'}},\$HTML),'announcement template renders');
unlike($HTML,qr/<script>bad|Action=CustomerTicketZoom|Action=CustomerITSMConfigItem|private-owner|private-profile/,'public page escapes content and has no private ticket/CI links');
like($HTML,qr/Submitted change runbook/,'submitted runbook section is present');
$M->{Tickets}{2}={TicketID=>2,Type=>'Change'};
my $Defaults=Kernel::System::Ticket::Event::ChangeDecisionDefaults->new();
ok($Defaults->Run(Data=>{TicketID=>2},UserID=>1),'creation event initializes hidden dropdown defaults');
is($M->{Tickets}{2}{DynamicField_ChangeType},'Normal','new change stores Normal without a requester input');
is($M->{Tickets}{2}{DynamicField_ChangeClassification},'Not-Assessed','new change stores Not-Assessed without a requester input');
$M->{Tickets}{2}{DynamicField_ChangeClassification}='Major';$M->{Stored}{2}{2}='Major';
ok($Defaults->Run(Data=>{TicketID=>2},UserID=>1),'repeated default event is harmless');
is($M->{Tickets}{2}{DynamicField_ChangeClassification},'Major','default event does not reset an existing decision');
$M->{Tickets}{3}={TicketID=>3,Type=>'ServiceRequest'};
ok($Defaults->Run(Data=>{TicketID=>3},UserID=>1),'unrelated ticket type ignored');ok(!exists $M->{Tickets}{3}{DynamicField_ChangeType},'no change fields written to unrelated type');
ok(!$M->{Driver}->ValueSet(DynamicFieldConfig=>$F,ObjectID=>1,Value=>'Major',Set=>1,UserID=>1),'Set submission cannot bypass protected write context');
my $Other={ID=>99,Name=>'OtherDropdown',ObjectType=>'Ticket',FieldType=>'Dropdown',Config=>{PossibleValues=>{X=>'X'},MultiValue=>0}};
ok($M->{Driver}->ValueSet(DynamicFieldConfig=>$Other,ObjectID=>1,Value=>'X',UserID=>1),'unrelated dropdown delegates to native behavior');
is($M->{Stored}{1}{99},'X','unrelated dropdown stored unchanged');
done_testing();
