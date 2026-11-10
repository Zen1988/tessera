package Kernel::System::TESSERA::DirectorySync;
use strict;
use warnings;
use JSON::PP ();
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(sha256_hex);
use Encode qw(encode decode FB_CROAK);
use Storable qw(dclone);
our @ObjectDependencies=qw(Kernel::Config Kernel::System::DB Kernel::System::SystemData Kernel::System::Group Kernel::System::User Kernel::System::GeneralCatalog Kernel::System::GovernanceObject Kernel::System::CustomerUser Kernel::System::TESSERA::ScriptEngine Kernel::System::Cache Kernel::System::Log Kernel::System::Daemon::SchedulerDB);
my $Key='TESSERA::DirectorySync::State';
my $DefaultScript="VERSION: 1\nCALL WEB SERVICE:\n  - SERVICE: Directory\n    INVOKER: SyncMembership\n    AS: SYNC\n    WITH: {}\nRETURN:\n  VALUE: EXTERNAL.SYNC.Processed\n";
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Authorized {
    my ($S,$U)=@_;
    return if !$U;
    my %User=$Kernel::OM->Get('Kernel::System::User')->GetUserData(UserID=>$U);
    return if ($User{ValidID} || 0)!=1;
    return $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(UserID=>$U,GroupName=>'admin',Type=>'rw');
}
sub _Read {
    my ($S)=@_;
    my $Raw=$Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGet(Key=>$Key);
    return {Config=>{},Groups=>[],Mappings=>{},Users=>{},Owned=>{},Script=>$DefaultScript} if !defined $Raw;
    my $D=JSON::PP->new->decode($Raw);
    die "Directory state invalid.\n" if ref $D ne 'HASH';
    return $D;
}
sub _Write {
    my ($S,$D,$U)=@_;
    my $Store=$Kernel::OM->Get('Kernel::System::SystemData');
    my $Method=defined $Store->SystemDataGet(Key=>$Key) ? 'SystemDataUpdate':'SystemDataAdd';
    die "Directory state save failed.\n" if !$Store->$Method(Key=>$Key,Value=>JSON::PP->new->canonical->encode($D),UserID=>$U);
}
sub _Locked {
    my ($S,$U,$Code)=@_;
    die "Administrator access required.\n" if !$S->Authorized($U);
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Directory sync busy.\n" if !$DB->Prepare(SQL=>q{SELECT GET_LOCK('tessera_directory_sync',5)});
    my @R=$DB->FetchrowArray();die "Directory sync busy.\n" if !$R[0];
    my ($Result,$Failure);
    eval {$Result=$Code->();1} or $Failure=$@ || 'Directory operation failed.';
    $DB->Prepare(SQL=>q{SELECT RELEASE_LOCK('tessera_directory_sync')});$DB->FetchrowArray();
    die $Failure if $Failure;
    return $Result;
}
sub _SecretKey {
    my ($S)=@_;
    return $S->{KeyProvider}->() if $S->{KeyProvider};
    require Kernel::System::TESSERA::Secrets;
    my $K=Kernel::System::TESSERA::Secrets::Read('ad-sync-key');$K=~s/\r?\n\z//;
    die "Directory encryption key unavailable.\n" if $K!~/\A[0-9a-fA-F]{64}\z/;
    return pack('H*',$K);
}
sub _Encrypt {
    my ($S,$PW)=@_;require Crypt::AuthEnc::GCM;require Crypt::PRNG;
    my $IV=Crypt::PRNG::random_bytes(12);
    my ($CT,$Tag)=Crypt::AuthEnc::GCM::gcm_encrypt_authenticate('AES',$S->_SecretKey(),$IV,$Key,encode('UTF-8',$PW));
    return encode_base64($IV.$Tag.$CT,'');
}
sub _Password {
    my ($S,$D)=@_;require Crypt::AuthEnc::GCM;
    my $B=decode_base64($D->{Password} || '');die "Directory credential unavailable.\n" if length($B)<29;
    my ($IV,$Tag,$CT)=(substr($B,0,12),substr($B,12,16),substr($B,28));
    my $PW=Crypt::AuthEnc::GCM::gcm_decrypt_verify('AES',$S->_SecretKey(),$IV,$Key,$CT,$Tag);
    die "Directory credential unavailable.\n" if !defined $PW;
    return decode('UTF-8',$PW,FB_CROAK);
}
sub View {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});
    my $D=$S->_Read();$D->{PasswordSet}=$D->{Password}?1:0;delete $D->{Password};delete $D->{Users};delete $D->{Owned};
    return $D;
}
sub _Object {
    my ($S,$ID,$Class)=@_;
    die "Invalid governance reference.\n" if !defined $ID || ref $ID || $ID!~/\A[1-9][0-9]*\z/;
    my $O=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$ID,DynamicFields=>1);
    die "Invalid active governance reference.\n" if ref $O ne 'HASH' || ($O->{Class} || '') ne $Class || ($O->{ZTSMStatus} || '') ne 'Active';
    return $O;
}
sub _Role {
    my ($S,$ID)=@_;my $O=$S->_Object($ID,'GovernanceRole');
    die "Choose a SUPPORT assignment classification.\n" if ($O->{Name} || '')!~/\ASUPPORT::/;
    return $ID;
}
sub _Catalog {
    my ($S,$Class,$Name)=@_;my $L=$Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(Class=>$Class);
    my @IDs=grep {($L->{$_} || '') eq $Name} keys %{$L || {}};
    die "Required catalog missing or ambiguous.\n" if @IDs!=1;return $IDs[0];
}
sub Save {
    my ($S,%P)=@_;return $S->_Locked($P{UserID},sub {
        my $D=$S->_Read();my $C=$P{Config};die "Configuration required.\n" if ref $C ne 'HASH';
        for my $F (qw(Host BindUser GroupBase UserBase GroupFilter CAFile CustomerID LoginAttribute Provider)) {
            die "Incomplete directory configuration.\n" if !defined $C->{$F} || ref $C->{$F} || !length($C->{$F}) || length($C->{$F})>4000 || $C->{$F}=~/[\x00-\x1f]/;
        }
        die "Invalid directory host.\n" if $C->{Host}!~/\A[A-Za-z0-9][A-Za-z0-9.-]*\z/;
        die "Use an absolute CA file.\n" if $C->{CAFile}!~m{\A/};
        die "Use sAMAccountName or userPrincipalName.\n" if $C->{LoginAttribute}!~/\A(?:sAMAccountName|userPrincipalName)\z/;
        die "Unsupported authentication provider.\n" if $C->{Provider}!~/\A(?:LDAP|OpenIDConnect)\z/;
        die "Invalid group filter.\n" if $C->{GroupFilter}!~/\A\(.+\)\z/;
        die "Invalid sync interval.\n" if ($C->{IntervalHours} || '')!~/\A[0-9]+\z/ || $C->{IntervalHours}<1 || $C->{IntervalHours}>168;
        die "Approved responsibility text required.\n" if !defined $C->{ResponsibilityText} || ref $C->{ResponsibilityText}
            || $C->{ResponsibilityText}!~/\S/ || length($C->{ResponsibilityText})>20000 || $C->{ResponsibilityText}=~/\x00/;
        $S->_Role($C->{RoleID});
        for my $F (qw(Host GroupBase UserBase LoginAttribute CustomerID Provider)) {
            die "Directory identity settings are immutable after import.\n" if keys %{$D->{Users}} && ($D->{Config}{$F} || '') ne $C->{$F};
        }
        for my $F (qw(Enabled AutoCreateProfiles Nested SyncAssignments)) {$C->{$F}=$C->{$F}?1:0}
        my $PW=$P{Password};
        if (defined $PW && length $PW) {die "Invalid password length.\n" if ref $PW || length($PW)>4096 || $PW=~/\x00/;$D->{Password}=$S->_Encrypt($PW)}
        die "Directory credential required.\n" if !$D->{Password};
        my $Script=$P{Script};die "Script required.\n" if !defined $Script || ref $Script || length($Script)>100000;
        my $Parsed=$Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine')->ScriptParse(Source=>$Script);
        die "Invalid sync script.\n" if !$Parsed->{Success};
        my $Calls=$Parsed->{Script}{'CALL WEB SERVICE'};$Calls=[$Calls] if ref $Calls eq 'HASH';
        die "Use exactly one approved Directory SyncMembership call.\n" if ref $Calls ne 'ARRAY' || @$Calls!=1
            || $Calls->[0]{SERVICE} ne 'Directory' || $Calls->[0]{INVOKER} ne 'SyncMembership';
        $D->{Config}=dclone($C);$D->{ActorID}=$P{UserID};$D->{Script}=$Script;
        $S->_Write($D,$P{UserID});return 1;
    });
}
sub _LDAP {my ($S)=@_;return $S->{LDAP} if $S->{LDAP};require Kernel::System::TESSERA::DirectoryLDAP;return Kernel::System::TESSERA::DirectoryLDAP->new()}
sub Discover {
    my ($S,%P)=@_;return $S->_Locked($P{UserID},sub {my $D=$S->_Read();$D->{Groups}=$S->_LDAP()->Groups($D->{Config},$S->_Password($D));$S->_Write($D,$P{UserID});return $D->{Groups}});
}
sub _CreateProfile {
    my ($S,$G,$U)=@_;my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @Existing=$GO->GovernanceObjectSearch(Classes=>['SupportProfile'],NameExact=>$G->{Name},Result=>'ARRAY',Limit=>2);
    die "Profile name already exists; map it explicitly.\n" if @Existing;
    my $ID=$GO->GovernanceObjectAdd(ClassID=>$S->_Catalog('ZTSM::GovernanceObject::Class','SupportProfile'),Name=>$G->{Name},
        ZTSMStatusID=>$S->_Catalog('ZTSM::GovernanceObject::Status','Active'),'DynamicField_ZTSMSupportProfile-Type'=>'Support',UserID=>$U);
    die "Profile creation failed.\n" if !$ID;return $ID;
}
sub Map {
    my ($S,%P)=@_;return $S->_Locked($P{UserID},sub {
        my $D=$S->_Read();my ($G)=grep {$_->{GUID} eq ($P{GUID} || '')} @{$D->{Groups}};die "Discover and select a group first.\n" if !$G;
        my $Role=$S->_Role($P{RoleID});my $ID=$P{ProfileID};
        die "Invalid assignment mode.\n" if ($P{Mode} || '')!~/\A(?:External|Manual)\z/;
        my $DB=$Kernel::OM->Get('Kernel::System::DB');die "Cannot begin mapping.\n" if !$DB->BeginWork();
        eval {
            if ($P{Create}) {$ID=$S->_CreateProfile($G,$P{UserID})}else {$S->_Object($ID,'SupportProfile')}
            $D->{Mappings}{$G->{GUID}}={ProfileID=>$ID,RoleID=>$Role,Mode=>$P{Mode}};
            $S->_Write($D,$P{UserID});die "Mapping commit failed.\n" if !$DB->Commit();1;
        } or do {my $E=$@;$DB->Rollback();$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();die $E};return 1;
    });
}
sub ExternalUser {
    my ($S,$Login)=@_;return if !defined $Login;my $Users=$S->_Read()->{Users};
    my @Keys=grep {lc($_) eq lc($Login)} keys %$Users;
    die "Ambiguous external customer identity.\n" if @Keys>1;
    return if !@Keys;return {%{$Users->{$Keys[0]}},Login=>$Keys[0]};
}
sub RoutingReady {
    my ($S)=@_;my $C=$Kernel::OM->Get('Kernel::Config');
    return if ($C->Get('Customer::AuthModule') || '') ne 'Kernel::System::CustomerAuth::TESSERAIdentity';
    return if grep {$C->Get('Customer::AuthModule'.$_)} 1..10;
    return 1;
}
sub _Provision {
    my ($S,$D,$U,$Actor)=@_;
    for (qw(Login GUID Firstname Lastname Email)) {die "Directory user attributes missing.\n" if !defined $U->{$_} || !length $U->{$_}}
    my $CU=$Kernel::OM->Get('Kernel::System::CustomerUser');my %Current=$CU->CustomerUserDataGet(User=>$U->{Login});
    die "Case-colliding directory customer.\n" if grep {lc($_) eq lc($U->{Login}) && $_ ne $U->{Login}} keys %{$D->{Users}};
    my $Owned=$D->{Users}{$U->{Login}};
    die "Existing customer identity is not owned by this directory.\n" if %Current && (!$Owned || $Owned->{GUID} ne $U->{GUID});
    die "External identity reassignment requires review.\n" if $Owned && $Owned->{GUID} ne $U->{GUID};
    my %Fields=(Source=>'CustomerUser',UserLogin=>$U->{Login},UserFirstname=>$U->{Firstname},UserLastname=>$U->{Lastname},UserEmail=>$U->{Email},
        UserCustomerID=>$D->{Config}{CustomerID},ValidID=>1,UserID=>$Actor);
    if (!%Current) {
        # No imported or recoverable local password. The auth router refuses local
        # authentication for every directory-owned identity even after a reset.
        require Crypt::PRNG;$Fields{UserPassword}=unpack('H*',Crypt::PRNG::random_bytes(64));
        die "Customer creation failed.\n" if !$CU->CustomerUserAdd(%Fields);
    } else {
        # Native DB updates every mapped column, so retain administrator-owned
        # contact data/preferences and never feed a stored hash to SetPassword.
        my %Update=(%Current,%Fields,ID=>$U->{Login},ValidID=>$Current{ValidID} // 1);
        delete $Update{UserPassword};
        die "Customer update failed.\n" if !$CU->CustomerUserUpdate(%Update);
    }
    $D->{Users}{$U->{Login}}={GUID=>$U->{GUID},Provider=>$D->{Config}{Provider}};
}
sub _AssignmentFields {
    my ($S,$Login,$Profile,$Role)=@_;
    return ('DynamicField_ZTSMSupportAssignment-UserAccount'=>$Login,'DynamicField_ZTSMSupportAssignment-SupportProfile'=>$Profile,'DynamicField_ZTSMSupportAssignment-Role'=>$Role);
}
sub _Sync {
    my ($S,$D,$Actor,$Options)=@_;
    die "Configure the sole TESSERA identity authentication router before import.\n" if !$S->RoutingReady();
    die "Invalid sync options.\n" if ref $Options ne 'HASH' || grep {$_ ne 'GroupNameContains' && $_ ne 'AutoCreateProfiles'} keys %$Options;
    my $Filter=$Options->{GroupNameContains} // '';die "Invalid group name filter.\n" if ref $Filter || length($Filter)>200;
    my $Auto=exists $Options->{AutoCreateProfiles} ? $Options->{AutoCreateProfiles}:$D->{Config}{AutoCreateProfiles};
    die "Automatic creation option must be zero or one.\n" if defined $Auto && (ref $Auto || $Auto!~/\A[01]\z/);
    die "Automatic profile creation is not enabled.\n" if $Auto && !$D->{Config}{AutoCreateProfiles};
    my $LDAP=$S->_LDAP();my $PW=$S->_Password($D);my $Groups=$LDAP->Groups($D->{Config},$PW);$D->{Groups}=$Groups;
    die "Narrow the directory group scope.\n" if @$Groups>1000;
    my (%Desired,%Users);my $Memberships=0;my $Report={Processed=>0,CreatedAssignments=>0,RetiredAssignments=>0,Unmapped=>[],Issues=>[]};
    # Complete all directory reads and identity validation before any writes.
    for my $G (@$Groups) {
        next if length($Filter) && index(lc($G->{Name}),lc($Filter))<0;
        my $M=$D->{Mappings}{$G->{GUID}};
        if (!$M && !$Auto) {push @{$Report->{Unmapped}},$G->{GUID}}
        my $Members=$LDAP->Members($D->{Config},$PW,$G);
        $Memberships+=@$Members;die "Narrow the membership scope.\n" if $Memberships>50000;
        for my $U (@$Members) {
            die "Conflicting directory users.\n" if $Users{$U->{Login}} && $Users{$U->{Login}}{GUID} ne $U->{GUID};
            $Users{$U->{Login}}=$U;
            die "Narrow the user scope.\n" if keys(%Users)>10000;
        }
        $G->{Members}=$Members;
    }
    my $DB=$Kernel::OM->Get('Kernel::System::DB');die "Cannot begin directory sync.\n" if !$DB->BeginWork();
    $S->{SyncTransaction}=1;
    eval {
        for my $Login (sort keys %Users) {$S->_Provision($D,$Users{$Login},$Actor);$Report->{Processed}++}
        my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
        for my $G (@$Groups) {
            next if !exists $G->{Members};
            my $M=$D->{Mappings}{$G->{GUID}};
            if (!$M && $Auto) {
                $M={ProfileID=>$S->_CreateProfile($G,$Actor),RoleID=>$S->_Role($D->{Config}{RoleID}),Mode=>'External'};
                $D->{Mappings}{$G->{GUID}}=$M;
            }
            next if !$M;
            $S->_Object($M->{ProfileID},'SupportProfile');$S->_Role($M->{RoleID});
            if ($M->{Mode} ne 'External') {
                for my $K (keys %{$D->{Owned}}) {
                    my $F=$D->{Owned}{$K}{Fields};
                    $Desired{$K}=1 if $F->{'DynamicField_ZTSMSupportAssignment-SupportProfile'} eq $M->{ProfileID}
                        && $F->{'DynamicField_ZTSMSupportAssignment-Role'} eq $M->{RoleID};
                }
                next;
            }
            next if !$D->{Config}{SyncAssignments};
            for my $U (@{$G->{Members}}) {
                my $K=sha256_hex(join("\0",$U->{Login},$M->{ProfileID},$M->{RoleID}));
                $Desired{$K}=1;my %Fields=$S->_AssignmentFields($U->{Login},$M->{ProfileID},$M->{RoleID});
                my %Search=map {$_=>{Equals=>$Fields{$_}}} keys %Fields;
                my @IDs=$GO->GovernanceObjectSearch(Classes=>['SupportAssignment'],%Search,Result=>'ARRAY',Limit=>2);
                die "Assignment identity ambiguous.\n" if @IDs>1;
                if (@IDs) {
                    my $A=$GO->GovernanceObjectGet(GovernanceObjectID=>$IDs[0],DynamicFields=>1);
                    if (($A->{ZTSMStatus} || '') ne 'Active') {
                        die "Inactive manual assignment requires review.\n" if !$D->{Owned}{$K} || $D->{Owned}{$K}{ID}!=$IDs[0];
                        die "Assignment activation failed.\n" if !$GO->GovernanceObjectUpdate(GovernanceObjectID=>$IDs[0],ZTSMStatusID=>$S->_Catalog('ZTSM::GovernanceObject::Status','Active'),UserID=>$Actor);
                    }
                    next;
                }
                my $ID=$GO->GovernanceObjectAdd(ClassID=>$S->_Catalog('ZTSM::GovernanceObject::Class','SupportAssignment'),Name=>'Directory membership '.$K,
                    ZTSMStatusID=>$S->_Catalog('ZTSM::GovernanceObject::Status','Active'),%Fields,UserID=>$Actor);
                die "Assignment creation failed.\n" if !$ID;
                $D->{Owned}{$K}={ID=>$ID,Fields=>\%Fields};$Report->{CreatedAssignments}++;
            }
        }
        # Only a complete unfiltered automatic run can retire this source's own
        # assignments. Manual objects, mappings and governance snapshots survive.
        if (!length($Filter) && $D->{Config}{SyncAssignments}) {
            for my $K (keys %{$D->{Owned}}) {
                next if $Desired{$K};my $Owned=$D->{Owned}{$K};my $A=$GO->GovernanceObjectGet(GovernanceObjectID=>$Owned->{ID},DynamicFields=>1);
                die "Managed assignment changed; review ownership.\n" if !$A || grep {ref($A->{$_}) || ($A->{$_} // '') ne $Owned->{Fields}{$_}} keys %{$Owned->{Fields}};
                next if ($A->{ZTSMStatus} || '') eq 'Inactive';
                die "Assignment retirement failed.\n" if !$GO->GovernanceObjectUpdate(GovernanceObjectID=>$Owned->{ID},ZTSMStatusID=>$S->_Catalog('ZTSM::GovernanceObject::Status','Inactive'),UserID=>$Actor);
                $Report->{RetiredAssignments}++;
            }
        }
        delete $_->{Members} for @$Groups;
        $D->{LastRun}=time();$D->{Report}=$Report;delete $D->{LastFailure};$S->_Write($D,$Actor);
        1;
    } or do {my $E=$@;$DB->Rollback();$S->{SyncTransaction}=0;$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();die $E};
    return $Report;
}
sub Run {
    my ($S,%P)=@_;return $S->_Locked($P{UserID},sub {
        my $D=$S->_Read();my $Calls=0;my $Report;
        local $S->{SyncTransaction}=0;
        require Kernel::System::TESSERA::ScriptEngine;
        my $Engine=Kernel::System::TESSERA::ScriptEngine->new(WebServiceProvider=>sub {
            my %Call=@_;die "Unapproved directory script call.\n" if $Call{Service} ne 'Directory' || $Call{Invoker} ne 'SyncMembership' || $Calls++;
            $Report=$S->_Sync($D,$P{UserID},$Call{Data});return {Success=>1,Data=>$Report};
        });
        my $R=$Engine->ScriptEvaluate(Source=>$D->{Script},UserID=>$P{UserID});
        if (!$R->{Success} || !$Report) {
            $Kernel::OM->Get('Kernel::System::DB')->Rollback() if $S->{SyncTransaction};
            $Kernel::OM->Get('Kernel::System::Cache')->CleanUp() if $S->{SyncTransaction};
            die "Directory script failed; review configuration and sync state.\n";
        }
        if (!$Kernel::OM->Get('Kernel::System::DB')->Commit()) {
            $Kernel::OM->Get('Kernel::System::DB')->Rollback();$Kernel::OM->Get('Kernel::System::Cache')->CleanUp();
            die "Directory sync commit failed.\n";
        }
        return $Report;
    });
}
sub RunScheduled {
    my ($S)=@_;my $D=$S->_Read();return 1 if !$D->{Config}{Enabled};
    return 1 if time()-($D->{LastRun} || 0)<($D->{Config}{IntervalHours} || 24)*3600;
    eval {$S->Run(UserID=>$D->{ActorID});1} or do {$S->_Failure($D->{ActorID});return};return 1;
}
sub _Failure {
    my ($S,$Actor)=@_;
    eval {$S->_Locked($Actor,sub {my $D=$S->_Read();$D->{LastFailure}=time();$S->_Write($D,$Actor);return 1});1};
    $Kernel::OM->Get('Kernel::System::Log')->Log(Priority=>'error',Message=>'Directory sync failed; review the restricted admin configuration.');
    return;
}
sub Queue {
    my ($S,%P)=@_;return $S->_Locked($P{UserID},sub {
        my $ID=$Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB')->TaskAdd(Type=>'AsynchronousExecutor',Name=>'TESSERADirectorySync',MaximumParallelInstances=>1,Attempts=>1,
            Data=>{Object=>'Kernel::System::TESSERA::DirectorySync',Function=>'RunQueued',Params=>{UserID=>$P{UserID}}});
        die "Directory task already queued or unavailable.\n" if !$ID || $ID<1;
        return $ID;
    });
}
sub RunQueued {
    my ($S,%P)=@_;
    eval {$S->Run(%P);1} or do {
        $S->_Failure($P{UserID});
        return;
    };
    return 1;
}
1;
