use strict;
use warnings;
use Test::More;
use DBI;
use JSON::PP ();
use Template;
use lib 'Kernel/Package/GovernanceDB', '.', 'otobo-11.1.0-beta2/Kernel/cpan-lib';
use Kernel::System::TESSERA::NewSetup;
use Kernel::Modules::AgentTESSERANewSetup;
use Kernel::System::GovernanceDB::Bootstrap;
use Kernel::System::HTMLUtils;
{
    package Local::SetupDB;
    sub BeginWork { $_[0]{dbh}->begin_work }
    sub Rollback { $_[0]{dbh}->rollback }
    sub Prepare {
        my ($S,%P)=@_;
        $P{SQL}=~s/ FOR UPDATE\z//;
        $S->{STH}=$S->{dbh}->prepare($P{SQL});
        return $S->{STH}->execute();
    }
    sub FetchrowArray { $_[0]{STH}->fetchrow_array }
    sub Do {
        my ($S,%P)=@_;
        return if $S->{FailWrite};
        $P{SQL}=~s/ ENGINE=InnoDB\z//;
        return $S->{dbh}->do($P{SQL},undef,map {$$_} @{$P{Bind} || []});
    }
    sub ListTables { @{$_[0]{dbh}->selectcol_arrayref("SELECT name FROM sqlite_master WHERE type='table'")} }
}
{
    package Local::SetupDependencies;
    sub PermissionCheck { $_[0]{Admin} }
    sub Decode { my ($S,%P)=@_; JSON::PP::decode_json($P{Data}) }
    sub Encode { my ($S,%P)=@_; JSON::PP::encode_json($P{Data}) }
    sub ToHTML { Kernel::System::HTMLUtils::ToHTML(@_) }
    sub ItemList { my ($S,%P)=@_; return {} if $S->{Missing}; return $P{Class}=~/::Class\z/ ? {7=>'Organization'} : {9=>'Active'} }
    sub GovernanceObjectAdd {
        my ($S,%P)=@_;
        $S->{LastAdd}=\%P;
        $S->{DB}{dbh}->do('INSERT INTO org (name, description) VALUES (?,?)',undef,$P{Name},$P{Description});
        return $S->{DB}{dbh}->sqlite_last_insert_rowid;
    }
    sub GovernanceObjectSearch {
        my ($S,%P)=@_;
        return $S->{DB}{dbh}->selectcol_arrayref('SELECT id FROM org WHERE name = ?',undef,$P{NameExact});
    }
    sub Get { $_[1] eq 'Kernel::System::DB' ? $_[0]{DB} : $_[0] }
}
my $DB=bless {dbh=>DBI->connect('dbi:SQLite:dbname=:memory:','','',{RaiseError=>1,AutoCommit=>1})},'Local::SetupDB';
$DB->{dbh}->do('CREATE TABLE tessera_setup_state(id INTEGER PRIMARY KEY,state_data TEXT NOT NULL)');
$DB->{dbh}->do('INSERT INTO tessera_setup_state VALUES (1,?)',undef,'{"Organizations":[],"Completed":0}');
$DB->{dbh}->do('CREATE TABLE org(id INTEGER PRIMARY KEY,name TEXT,description TEXT)');
local $Kernel::OM=bless {DB=>$DB,Admin=>1},'Local::SetupDependencies';
my $Setup=Kernel::System::TESSERA::NewSetup->new();
is_deeply($Setup->Progress(UserID=>1)->{Organizations},[],'initial progress is empty');
eval {$Setup->Complete(UserID=>1)};
like($@,qr/at least one organization/,'cannot finish without organization');
my %P=(UserID=>1,Name=>' Example ',Description=>'Description',RequestKey=>'a'x32);
$DB->{dbh}->do('INSERT INTO org(name,description) VALUES (?,?)',undef,'Existing','Pre-upgrade record');
eval {$Setup->SaveOrganization(%P,Name=>'Existing')};
like($@,qr/already exists/,'pre-upgrade organization is not recreated');
my $ID=$Setup->SaveOrganization(%P);
ok($ID,'organization created through native API');
is($Kernel::OM->{LastAdd}{ClassID},7,'native Organization class resolved');
is($Kernel::OM->{LastAdd}{ZTSMStatusID},9,'native Active status resolved');
is($Kernel::OM->{LastAdd}{Name},'Example','name trimmed');
is($Setup->SaveOrganization(%P),$ID,'repeated submission returns same organization');
is($DB->{dbh}->selectrow_array('SELECT COUNT(*) FROM org'),2,'retry creates no duplicate');
eval {$Setup->SaveOrganization(%P,Name=>'Different')};
like($@,qr/different details/,'key cannot be reused for different content');
eval {$Setup->SaveOrganization(%P,RequestKey=>'b'x32)};
like($@,qr/already added/,'new token cannot duplicate setup name');
$Kernel::OM->{Admin}=0;
eval {$Setup->SaveOrganization(%P)};
like($@,qr/administrator access/,'backend authorization blocks non-admin');
eval {$Setup->Progress(UserID=>2)};
like($@,qr/administrator access/,'progress is also restricted');
$Kernel::OM->{Admin}=1;
$DB->{FailWrite}=1;
eval {$Setup->SaveOrganization(%P,Name=>'Rolled back',RequestKey=>'c'x32)};
like($@,qr/save setup progress/,'write failure reported');
is($DB->{dbh}->selectrow_array('SELECT COUNT(*) FROM org'),2,'failed progress write rolls back organization insertion');
delete $DB->{FailWrite};
my $Second=$Setup->SaveOrganization(%P,Name=>'Second',Description=>'<script>example</script>',RequestKey=>'d'x32);
ok($Second != $ID,'additional organization created');
is($Kernel::OM->{LastAdd}{Description},'&lt;script&gt;example&lt;/script&gt;','plain text description encoded for native rich-text storage');
is(scalar @{$Setup->Progress(UserID=>1)->{Organizations}},2,'durable progress includes both organizations');
ok($Setup->Complete(UserID=>1),'finish succeeds');
ok($Setup->Complete(UserID=>1),'finish is idempotent');
eval {$Setup->SaveOrganization(%P,Name=>'Too late',RequestKey=>'e'x32)};
like($@,qr/already complete/,'completed setup cannot create further organizations');
is($Setup->SaveOrganization(%P),$ID,'late retry after completion is safe');
eval {$Setup->SaveOrganization(%P,Name=>'')};
like($@,qr/organization name/,'blank name rejected');

# Render the real template, including hostile input, with ordinary TT filters.
my $TT=Template->new();
my $Out='';
ok($TT->process('Kernel/Package/GovernanceDB/Kernel/Output/HTML/Templates/Standard/AgentTESSERANewSetup.tt',{
    Data=>{State=>{Organizations=>[{ID=>1,Name=>'<script>x</script>'}]},Name=>'" autofocus onfocus="x',Description=>'</textarea><script>x</script>',RequestKey=>'a'x32},
    Translate=>sub {$_[0]}, Env=>sub {''},
},\$Out),'real template renders');
unlike($Out,qr/<script>/,'organization names and form values escaped');
like($Out,qr/ChallengeToken/,'forms include native request token');
like($Out,qr/Would you like to add another organization/,'next page asks for additional organization');
{
    package Local::SetupRoute;
    sub Get { $_[0]{Objects}{$_[1]} || $_[0] }
    sub Authorized { $_[0]{Allow} }
    sub SaveOrganization { $_[0]{Saves}++; 100 }
    sub Complete { $_[0]{Finishes}++; 1 }
    sub Progress { {Organizations=>[]} }
    sub RequestMethod { $_[0]{Method} }
    sub GetParam { my ($S,%P)=@_; $S->{Params}{$P{Param}} }
    sub NoPermission { 'DENIED' }
    sub ErrorScreen { 'ERROR' }
    sub ChallengeTokenCheck { $_[0]{Checks}++; 1 }
    sub Redirect { 'REDIRECT' }
    sub Header { '' }
    sub NavigationBar { '' }
    sub Footer { '' }
    sub Output { 'FORM' }
    sub GenerateRandomString { 'r'x32 }
    sub Log { 1 }
}
my $Route=bless {Allow=>0,Method=>'POST',UserChallengeToken=>'session-token',Params=>{ChallengeToken=>'session-token'}},'Local::SetupRoute';
local $Kernel::OM=$Route;
my $Controller=Kernel::Modules::AgentTESSERANewSetup->new(UserID=>1,Subaction=>'Save');
is($Controller->Run(),'DENIED','agent endpoint rejects non-admin');
$Route->{Allow}=1;
$Route->{Method}='GET';
is($Controller->Run(),'ERROR','GET cannot create organization');
ok(!$Route->{Saves},'denied GET never reaches writer');
$Route->{Method}='POST';
$Route->{Params}{ChallengeToken}='other-session';
is($Controller->Run(),'ERROR','token from another session rejected');
ok(!$Route->{Saves},'bad token never reaches writer');
$Route->{Params}{ChallengeToken}='session-token';
is($Controller->Run(),'REDIRECT','valid POST redirects after save');
is($Route->{Saves},1,'valid POST calls writer once');
is($Route->{Checks},1,'native token validation also invoked');
my $View=Kernel::Modules::AgentTESSERANewSetup->new(UserID=>1);
is($View->Run(),'FORM','GET opens setup form');
is($Route->{Saves},1,'view does not create business data');
{
    local $Kernel::OM=bless {DB=>$DB,Admin=>1},'Local::SetupDependencies';
    my $Bootstrap=bless {},'Kernel::System::GovernanceDB::Bootstrap';
    ok($Bootstrap->_NewSetupStorageEnsure(),'reinstallation initializes storage idempotently');
    ok($Setup->Progress(UserID=>1)->{Completed},'reinstallation preserves completed setup');
    is(scalar @{$Setup->Progress(UserID=>1)->{Organizations}},2,'reinstallation preserves organization links');
    $DB->{dbh}->do('DROP TABLE tessera_setup_state');
    ok($Bootstrap->_NewSetupStorageEnsure(),'upgrade repairs missing setup table');
    is_deeply($Setup->Progress(UserID=>1)->{Organizations},[],'repaired table starts empty without creating business data');
}
done_testing;
