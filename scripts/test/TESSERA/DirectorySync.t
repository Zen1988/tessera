use strict;
use warnings;
use Test::More;
use Storable qw(dclone);
use lib '.';
use Kernel::System::TESSERA::DirectorySync;
use Kernel::System::TESSERA::ScriptEngine;
{
    package DirectoryTestOM;
    sub Get {my ($S,$N)=@_;return $S->{Engine} if $N eq 'Kernel::System::TESSERA::ScriptEngine';return $S->{Sync} if $N eq 'Kernel::System::TESSERA::DirectorySync';return $S}
    sub GetUserData {return (ValidID=>1)}
    sub PermissionCheck {my ($S,%P)=@_;return ($P{UserID} || 0)==7}
    sub SystemDataGet {return $_[0]{Raw}}
    sub SystemDataAdd {my ($S,%P)=@_;$S->{Raw}=$P{Value};return 1}
    sub SystemDataUpdate {shift->SystemDataAdd(@_)}
    sub Prepare {$_[0]{SQL}=$_[2];return 1}
    sub FetchrowArray {return (1)}
    sub BeginWork {my ($S)=@_;$S->{Snapshot}=Storable::dclone({map {$_=>$S->{$_}} qw(Raw Objects Customers NextID)});return 1}
    sub Commit {delete $_[0]{Snapshot};return 1}
    sub Rollback {my ($S)=@_;my $B=delete $S->{Snapshot};@$S{keys %$B}=values %$B;return 1}
    sub CleanUp {return 1}
    sub GetConfig {return}
    sub ItemList {my ($S,%P)=@_;return $P{Class}=~/Status/ ? {1=>'Active',2=>'Inactive'}:{10=>'SupportProfile',11=>'SupportAssignment'}}
    sub GovernanceObjectGet {my ($S,%P)=@_;return Storable::dclone($S->{Objects}{$P{GovernanceObjectID}}) if $S->{Objects}{$P{GovernanceObjectID}};return}
    sub GovernanceObjectSearch {
        my ($S,%P)=@_;my @IDs;
        for my $ID (sort {$a<=>$b} keys %{$S->{Objects}}) {
            my $O=$S->{Objects}{$ID};next if $O->{Class} ne $P{Classes}[0];next if defined $P{NameExact} && $O->{Name} ne $P{NameExact};
            next if grep {/^DynamicField_/ && ($O->{$_} // '') ne $P{$_}{Equals}} keys %P;
            push @IDs,$ID;
        }
        return @IDs; # Match the real native API's list return, never arrayref.
    }
    sub GovernanceObjectAdd {
        my ($S,%P)=@_;my $ID=++$S->{NextID};my $Class=$P{ClassID}==10?'SupportProfile':'SupportAssignment';
        $S->{Objects}{$ID}={%P,GovernanceObjectID=>$ID,Class=>$Class,ZTSMStatus=>'Active'};return $ID;
    }
    sub GovernanceObjectUpdate {my ($S,%P)=@_;$S->{Objects}{$P{GovernanceObjectID}}{ZTSMStatus}=$P{ZTSMStatusID}==1?'Active':'Inactive';return 1}
    sub CustomerUserDataGet {my ($S,%P)=@_;return %{$S->{Customers}{$P{User}} || {}}}
    sub CustomerUserAdd {my ($S,%P)=@_;$S->{Customers}{$P{UserLogin}}=\%P;return $P{UserLogin}}
    sub CustomerUserUpdate {shift->CustomerUserAdd(@_)}
    sub SetPreferences {my ($S,%P)=@_;$S->{Customers}{$P{UserID}}{$P{Key}}=$P{Value};return 1}
    sub Log {return}
    package DirectoryTestLDAP;
    sub Groups {return Storable::dclone($_[0]{Groups})}
    sub Members {die "incomplete directory" if $_[0]{Fail};return Storable::dclone($_[0]{Members})}
    sub Authenticate {my ($S,$C,$Bind,$Login,$PW)=@_;$S->{AuthCalls}++;return $PW eq 'external-password'}
    package DirectoryConfig;
    sub Get {my ($S,$K)=@_;return $K eq 'Customer::AuthModule' ? $S->{Router}:undef}
    package DirectoryOM;
    our @ISA=('DirectoryTestOM');
    sub Get {my ($S,$N)=@_;return $S->{Config} if $N eq 'Kernel::Config';return $S->SUPER::Get($N)}
}
my $LDAP=bless {Groups=>[{GUID=>'a'x32,Name=>'Network Support',DN=>'CN=Network Support,OU=Groups,DC=test'}],
    Members=>[{GUID=>'b'x32,Login=>'alice',Firstname=>'Alice',Lastname=>'Smith',Email=>'alice@example.test'}]},'DirectoryTestLDAP';
local $Kernel::OM=bless {Objects=>{20=>{Class=>'SupportProfile',Name=>'Network',ZTSMStatus=>'Active'},30=>{Class=>'GovernanceRole',Name=>'SUPPORT::ENGINEER',ZTSMStatus=>'Active'}},Customers=>{},NextID=>100,
    Engine=>Kernel::System::TESSERA::ScriptEngine->new(),Config=>bless({Router=>'Kernel::System::CustomerAuth::TESSERAIdentity'},'DirectoryConfig')},'DirectoryOM';
my $S=Kernel::System::TESSERA::DirectorySync->new(LDAP=>$LDAP,KeyProvider=>sub {'k'x32});$Kernel::OM->{Sync}=$S;
my $View=$S->View(UserID=>7);my $Script=$View->{Script};
my %C=(Host=>'ad.example.test',BindUser=>'sync@example.test',GroupBase=>'OU=Groups,DC=test',UserBase=>'OU=Users,DC=test',GroupFilter=>'(cn=*)',
    CAFile=>'/trust/ad.pem',CustomerID=>'Example',LoginAttribute=>'sAMAccountName',Provider=>'LDAP',IntervalHours=>24,RoleID=>30,SyncAssignments=>1,ResponsibilityText=>'Approved organization responsibilities');
ok(!eval {$S->View(UserID=>8);1},'nonadmin denied');
ok($S->Save(UserID=>7,Config=>\%C,Password=>'bind-secret',Script=>$Script),'configuration saved');
unlike($Kernel::OM->{Raw},qr/bind-secret/,'password never stored as plaintext');
ok($S->View(UserID=>7)->{PasswordSet},'password presence shown');
ok(!exists $S->View(UserID=>7)->{Password},'encrypted credential not exposed to UI');
is($S->_Password($S->_Read()),'bind-secret','AEAD credential decrypts');
my $Bad=Kernel::System::TESSERA::DirectorySync->new(KeyProvider=>sub {'x'x32});
ok(!eval {$Bad->_Password($S->_Read());1},'wrong key fails authentication');
my $Report=$S->Run(UserID=>7);
is($Report->{Processed},1,'unmapped group members still provisioned as CustomerUsers');
is($Report->{CreatedAssignments},0,'unmapped groups grant no assignments');
is(scalar @{$Report->{Unmapped}},1,'unmapped group returned for administrator selection');
ok($Kernel::OM->{Customers}{alice},'CustomerUser created');
is($S->ExternalUser('ALICE')->{Login},'alice','external identity routing resolves canonical login');
unlike($Kernel::OM->{Customers}{alice}{UserPassword},qr/bind-secret/,'service account password never copied to customer');
ok($S->Map(UserID=>7,GUID=>'a'x32,ProfileID=>20,RoleID=>30,Mode=>'External'),'group mapped to existing SupportProfile');
$Report=$S->Run(UserID=>7);is($Report->{CreatedAssignments},1,'external membership creates assignment');
my ($Assignment)=grep {$_->{Class} eq 'SupportAssignment'} values %{$Kernel::OM->{Objects}};
is($Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'},'alice','assignment uses exported CustomerUser reference');
is($Assignment->{'DynamicField_ZTSMSupportAssignment-SupportProfile'},20,'assignment points to mapped profile');
is($S->Run(UserID=>7)->{CreatedAssignments},0,'same-version/repeated sync creates no duplicates');
$LDAP->{Members}=[];$Report=$S->Run(UserID=>7);is($Report->{RetiredAssignments},1,'complete sync retires only source-owned missing membership');
$LDAP->{Members}=[{GUID=>'b'x32,Login=>'alice',Firstname=>'Alice',Lastname=>'Smith',Email=>'alice@example.test'}];
$S->Run(UserID=>7);is($Kernel::OM->{Objects}{$Assignment->{GovernanceObjectID}}{ZTSMStatus},'Active','returning member reactivates owned assignment');
$LDAP->{Fail}=1;my $Before=$Kernel::OM->{Raw};ok(!eval {$S->Run(UserID=>7);1},'partial directory failure stops synchronization');
is($Kernel::OM->{Raw},$Before,'failed read preserves durable state');delete $LDAP->{Fail};
$S->Map(UserID=>7,GUID=>'a'x32,ProfileID=>20,RoleID=>30,Mode=>'Manual');$LDAP->{Members}=[];
is($S->Run(UserID=>7)->{RetiredAssignments},0,'manual assignment mode never retires previously owned assignment');
$Kernel::OM->{Config}{Router}='Kernel::System::CustomerAuth::DB';ok(!eval {$S->Run(UserID=>7);1},'unsafe local auth fallback blocks import');
$Kernel::OM->{Config}{Router}='Kernel::System::CustomerAuth::TESSERAIdentity';
my $Role=$Kernel::OM->{Objects}{30};$Role->{Name}='TESSERA::CMDB::READ';ok(!eval {$S->Map(UserID=>7,GUID=>'a'x32,ProfileID=>20,RoleID=>30,Mode=>'External');1},'reserved capability never assigned by group sync');$Role->{Name}='SUPPORT::ENGINEER';
my $Saved=$S->_Read();$Saved->{Mappings}={};$Saved->{Config}{AutoCreateProfiles}=1;$S->_Write($Saved,7);
$LDAP->{Groups}[0]{Name}='New Group';$LDAP->{Members}=[];$S->Run(UserID=>7);
ok($S->_Read()->{Mappings}{'a'x32}{ProfileID}>100,'automatic create option creates and persists profile mapping');
my %Unsafe=%C;$Unsafe{Host}='other.example.test';ok(!eval {$S->Save(UserID=>7,Config=>\%Unsafe,Script=>$Script);1},'source identity cannot silently change after importing users');
my $UnsafeScript=$Script;$UnsafeScript=~s/SyncMembership/ArbitraryNetworkCall/;
ok(!eval {$S->Save(UserID=>7,Config=>\%C,Script=>$UnsafeScript);1},'unapproved scripted effect rejected before execution');
require Kernel::System::CustomerAuth::TESSERAIdentity;
my $Auth=Kernel::System::CustomerAuth::TESSERAIdentity->new();
is($Auth->Auth(User=>'alice',Pw=>'external-password'),'alice','directory authentication delegated');
ok(!$Auth->Auth(User=>'alice',Pw=>'wrong-local-password'),'external auth failure never falls through to local DB');
my $State=$S->_Read();$State->{Script}=~s/EXTERNAL.SYNC.Processed/EXTERNAL.SYNC.Missing/;$S->_Write($State,7);
$LDAP->{Members}=[{GUID=>'c'x32,Login=>'bob',Firstname=>'Bob',Lastname=>'Jones',Email=>'bob@example.test'}];
my $StateBefore=$Kernel::OM->{Raw};ok(!eval {$S->Run(UserID=>7);1},'script failure after call rolls back entire sync');
is($Kernel::OM->{Raw},$StateBefore,'script failure rolls back persisted run report and ownership');
ok(!$Kernel::OM->{Customers}{bob},'script failure rolls back CustomerUser creation');
$State=$S->_Read();$State->{Script}=$Script;$State->{Config}{AutoCreateProfiles}=0;$S->_Write($State,7);
$Kernel::OM->{Customers}{bob}={UserLogin=>'bob',ValidID=>1};
ok(!eval {$S->Run(UserID=>7);1},'preexisting local user cannot be silently taken over');
delete $Kernel::OM->{Customers}{bob};
{
    package DirectorySSO;
    sub Auth {return $_[0]{Login}}
    sub PostAuth {return {RequestedURL=>'Action=CustomerTicketOverview'}}
}
{
    no warnings 'redefine';
    my $SSO=bless {Login=>'alice'},'DirectorySSO';
    local *Kernel::System::CustomerAuth::TESSERAIdentity::_SSO=sub {return $SSO};
    my $D=$S->_Read();$D->{Config}{Provider}='OpenIDConnect';$D->{Users}{alice}{Provider}='OpenIDConnect';$S->_Write($D,7);
    is($Auth->GetOption(What=>'PreAuth'),1,'SSO mode requests native external preauthentication');
    is($Auth->Auth(User=>'ignored',Pw=>'not-used'),'alice','only native-verified imported SSO identity accepted');
    $SSO->{Login}='unimported';ok(!$Auth->Auth(),'unimported SSO identity is denied');
    $SSO->{Login}=undef;ok(!$Auth->Auth(),'SSO failure does not fall through to DB authentication');
}
done_testing();
