package Kernel::System::TESSERA::LocalIdentity;
use strict;
use warnings;
use JSON::PP ();
our @ObjectDependencies = qw(Kernel::Config Kernel::System::DB Kernel::System::User Kernel::System::CustomerUser Kernel::System::Group Kernel::System::Cache Kernel::System::TESSERA::ProviderIdentity Kernel::System::TESSERA::DirectorySync);
sub new {return bless {},$_[0]}
sub _fail {die "$_[0]\n"}
sub _admin {my ($S,$U)=@_;$Kernel::OM->Get('Kernel::System::TESSERA::ProviderIdentity')->_admin($U)}
sub StorageEnsure {
    my ($S)=@_;my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Do(SQL=>q{CREATE TABLE IF NOT EXISTS tessera_local_identity (
        customer_row_id INTEGER NOT NULL PRIMARY KEY, agent_id INTEGER NOT NULL,
        enabled SMALLINT NOT NULL, managed_grants LONGBLOB NOT NULL,
        create_by INTEGER NOT NULL, change_by INTEGER NOT NULL,
        create_time DATETIME NOT NULL, change_time DATETIME NOT NULL,
        UNIQUE KEY tessera_local_identity_agent (agent_id)
    ) ENGINE=InnoDB});
    return $DB->Do(SQL=>q{CREATE TABLE IF NOT EXISTS tessera_local_identity_audit (
        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_row_id INTEGER NOT NULL,
        agent_id INTEGER NOT NULL, detail LONGBLOB NOT NULL, create_by INTEGER NOT NULL,
        create_time DATETIME NOT NULL
    ) ENGINE=InnoDB});
}
sub RoutingReady {
    my ($S)=@_;my $C=$Kernel::OM->Get('Kernel::Config');
    return if !$C->Get('TESSERA::LocalIdentity::Enabled') || ($C->Get('AuthModule')||'') ne 'Kernel::System::Auth::TESSERALocalIdentity';
    return if !defined $C->Get('AuthModule::UseSyncBackend') || length($C->Get('AuthModule::UseSyncBackend'));
    for my $N (1..10) {return if $C->Get('AuthModule'.$N)}
    return $Kernel::OM->Get('Kernel::System::User')->can('TESSERALocalPasswordRouting') ? 1:0;
}
sub _row {
    my ($S,%P)=@_;my $DB=$Kernel::OM->Get('Kernel::System::DB');
    my ($SQL,$Value);
    if ($P{AgentLogin}) {($SQL,$Value)=('SELECT l.customer_row_id, l.agent_id, l.enabled, l.managed_grants FROM tessera_local_identity l INNER JOIN users u ON u.id = l.agent_id WHERE u.login = ?',$P{AgentLogin})}
    else {($SQL,$Value)=('SELECT customer_row_id, agent_id, enabled, managed_grants FROM tessera_local_identity WHERE customer_row_id = ?',$P{CustomerRowID})}
    _fail('Cannot resolve linked identity') if !$DB->Prepare(SQL=>$SQL,Bind=>[\$Value],Limit=>1);
    my @R=$DB->FetchrowArray();return if !@R;
    return {CustomerRowID=>$R[0],AgentID=>$R[1],Enabled=>$R[2],Managed=>JSON::PP->new->decode($R[3])};
}
sub _subject {
    my ($S,%P)=@_;my $DB=$Kernel::OM->Get('Kernel::System::DB');
    my ($Key,$Value)=$P{CustomerRowID}?('id',$P{CustomerRowID}):('login',$P{CustomerUserID});
    _fail('Cannot resolve local customer identity') if !$DB->Prepare(SQL=>'SELECT id, login FROM customer_user WHERE '.$Key.' = ?',Bind=>[\$Value],Limit=>1);
    my @R=$DB->FetchrowArray();_fail('Customer identity unavailable') if !@R;
    my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$R[1]);
    my $C=$Kernel::OM->Get('Kernel::Config');my $Source=$C->Get('CustomerUser');
    _fail('Custom agent user tables are not supported') if ($C->Get('DatabaseUserTable')||'users') ne 'users' || ($C->Get('DatabaseUserTableUserID')||'id') ne 'id' || ($C->Get('DatabaseUserTableUser')||'login') ne 'login' || ($C->Get('DatabaseUserTableUserPW')||'pw') ne 'pw';
    my $Auth=$C->Get('Customer::AuthModule')||'';
    _fail('A sole local-compatible customer authentication route is required') if $Auth ne 'Kernel::System::CustomerAuth::DB' && $Auth ne 'Kernel::System::CustomerAuth::TESSERAIdentity';
    for my $N (1..10) {_fail('Additional customer authentication routes are not supported') if $C->Get('Customer::AuthModule'.$N)}
    _fail('Custom authentication tables are not supported') if ($C->Get('Customer::AuthModule::DB::Table')||'') ne 'customer_user'
        || ($C->Get('Customer::AuthModule::DB::CustomerKey')||'') ne 'login' || ($C->Get('Customer::AuthModule::DB::CustomerPassword')||'') ne 'pw'
        || $C->Get('Customer::AuthModule::DB::DSN') || $Source->{Params}{DSN};
    if ($Auth eq 'Kernel::System::CustomerAuth::TESSERAIdentity') {
        my $D=$Kernel::OM->Get('Kernel::System::TESSERA::DirectorySync');
        _fail('Local customer authentication is unavailable') if !$D->RoutingReady() || ($D->_Read()->{Config}{Provider}||'') eq 'OpenIDConnect';
    }
    _fail('Only the primary local DB customer source is supported') if !$U{UserLogin} || ($U{Source}||'') ne 'CustomerUser' || ref $Source ne 'HASH'
        || ($Source->{Module}||'') ne 'Kernel::System::CustomerUser::DB' || ($Source->{Params}{Table}||'') ne 'customer_user' || $Source->{ReadOnly};
    # Imported AD/OIDC records may also live in customer_user. They must never
    # acquire an independent local agent password path.
    _fail('External identity cannot use local password linking') if $Kernel::OM->Get('Kernel::System::TESSERA::DirectorySync')->ExternalUser($R[1]);
    return {(map {$_=>$U{$_}} qw(UserLogin UserFirstname UserLastname UserEmail UserTitle ValidID Source)),CustomerRowID=>$R[0]};
}
sub View {
    my ($S,%P)=@_;$S->_admin($P{UserID});my $U=$S->_subject(%P);my $L=$S->_row(CustomerRowID=>$U->{CustomerRowID});
    my %Agent=$L?$Kernel::OM->Get('Kernel::System::User')->GetUserData(UserID=>$L->{AgentID}):();
    return {Subject=>$U,Link=>$L,Agent=>{map {$_=>$Agent{$_}} qw(UserID UserLogin ValidID)},
        EffectiveAgentActive=>$L && $L->{Enabled} && ($U->{ValidID}||0)==1 && ($Agent{ValidID}||0)==1 && $S->RoutingReady()?1:0,RoutingReady=>$S->RoutingReady()?1:0};
}
sub _lists {
    my ($S,$P)=@_;my $G=$Kernel::OM->Get('Kernel::System::Group');
    my %Groups=$G->GroupList(Valid=>1);my %Roles=$G->RoleList(Valid=>1);
    for my $Field (qw(Groups Roles)) {
        my $Values=$P->{$Field};my $Allowed=$Field eq 'Groups'?\%Groups:\%Roles;
        _fail('Select explicit valid agent grants') if ref $Values ne 'ARRAY' || @$Values>100 || grep {ref $_ || !defined $_ || !/\A[1-9][0-9]*\z/ || !$Allowed->{$_}} @$Values;
    }
}
sub Configure {
    my ($S,%P)=@_;$S->_admin($P{UserID});
    _fail('Configure and restart the sole linked-agent authentication router first') if !$S->RoutingReady();
    $S->_lists(\%P);my $U=$S->_subject(%P);
    _fail('Cannot enable an invalid customer') if $P{Enabled} && ($U->{ValidID}||0)!=1;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    for my $Table (qw(users user_preferences group_user role_user tessera_local_identity tessera_local_identity_audit)) {
        _fail('Linked identity changes require InnoDB tables') if !$DB->Prepare(SQL=>'SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',Bind=>[\$Table]) || lc((($DB->FetchrowArray())[0])||'') ne 'innodb';
    }
    my $Lock='tessera_local_identity';
    _fail('Identity management busy') if !$DB->Prepare(SQL=>'SELECT GET_LOCK(?, 2)',Bind=>[\$Lock]) || !(($DB->FetchrowArray())[0]);
    my ($Error,$ID,$Begun);
    eval {
        my $Old=$S->_row(CustomerRowID=>$U->{CustomerRowID});my $Users=$Kernel::OM->Get('Kernel::System::User');
        $ID=$Old?$Old->{AgentID}:$Users->UserLookup(UserLogin=>$U->{UserLogin},Silent=>1);
        _fail('Root and current administrator cannot be linked') if $ID && ($ID==1 || $ID==$P{UserID});
        if ($ID && !$Old) {_fail('Existing agent requires explicit ID confirmation') if !$P{ConfirmExisting} || ($P{ExistingAgentID}||'') ne "$ID"}
        _fail('Choose agent groups or roles before enabling access') if $P{Enabled} && !@{$P{Groups}} && !@{$P{Roles}};
        _fail('Cannot begin identity transaction') if !$DB->BeginWork();$Begun=1;
        if (!$ID) {
            _fail('Select agent access to create its secondary record') if !$P{Enabled};
            $ID=$Users->UserAdd(UserFirstname=>$U->{UserFirstname},UserLastname=>$U->{UserLastname},UserLogin=>$U->{UserLogin},UserEmail=>$U->{UserEmail},ValidID=>2,ChangeUserID=>$P{UserID});
            _fail('Cannot create secondary agent record') if !$ID;
        }
        if (!$Old) {
            # Invalidate any former agent-local password before publishing the link.
            _fail('Cannot retire independent agent password') if !$Users->SetPassword(UserLogin=>$Users->UserLookup(UserID=>$ID),PW=>$Users->GenerateRandomPassword());
        }
        my $Managed={Groups=>$P{Groups},Roles=>$P{Roles}};my $JSON=JSON::PP->new->canonical->encode($Managed);my $Enabled=$P{Enabled}?1:0;
        my $OK=$Old ? $DB->Do(SQL=>'UPDATE tessera_local_identity SET enabled = ?, managed_grants = ?, change_by = ?, change_time = current_timestamp WHERE customer_row_id = ?',Bind=>[\$Enabled,\$JSON,\$P{UserID},\$U->{CustomerRowID}])
            : $DB->Do(SQL=>'INSERT INTO tessera_local_identity (customer_row_id, agent_id, enabled, managed_grants, create_by, change_by, create_time, change_time) VALUES (?, ?, ?, ?, ?, ?, current_timestamp, current_timestamp)',Bind=>[\$U->{CustomerRowID},\$ID,\$Enabled,\$JSON,\$P{UserID},\$P{UserID}]);
        _fail('Cannot save identity link') if !$OK;
        my $G=$Kernel::OM->Get('Kernel::System::Group');
        my %NewGroups=map {$_=>1} @{$P{Groups}};my %NewRoles=map {$_=>1} @{$P{Roles}};
        for my $GID (@{$Old->{Managed}{Groups}||[]}) {next if $NewGroups{$GID};_fail('Cannot retire managed group') if !$G->PermissionGroupUserAdd(UID=>$ID,GID=>$GID,Permission=>{},UserID=>$P{UserID})}
        for my $RID (@{$Old->{Managed}{Roles}||[]}) {next if $NewRoles{$RID};_fail('Cannot retire managed role') if !$G->PermissionRoleUserAdd(UID=>$ID,RID=>$RID,Active=>0,UserID=>$P{UserID})}
        for my $GID (@{$P{Groups}}) {_fail('Cannot grant selected group') if !$G->PermissionGroupUserAdd(UID=>$ID,GID=>$GID,Permission=>{rw=>1},UserID=>$P{UserID})}
        for my $RID (@{$P{Roles}}) {_fail('Cannot grant selected role') if !$G->PermissionRoleUserAdd(UID=>$ID,RID=>$RID,Active=>1,UserID=>$P{UserID})}
        $S->_sync($U,{AgentID=>$ID,Enabled=>$Enabled},$P{UserID});
        my $Audit=JSON::PP->new->canonical->encode({Enabled=>$Enabled,Grants=>$Managed,ConfirmedExisting=>$P{ConfirmExisting}?1:0});
        _fail('Cannot record identity audit') if !$DB->Do(SQL=>'INSERT INTO tessera_local_identity_audit (customer_row_id, agent_id, detail, create_by, create_time) VALUES (?, ?, ?, ?, current_timestamp)',Bind=>[\$U->{CustomerRowID},\$ID,\$Audit,\$P{UserID}]);
        _fail('Cannot commit identity changes') if !$DB->{dbh}->commit();$Begun=0;1;
    } or $Error=$@||'Identity operation failed';
    if ($Begun) {$DB->Rollback();$Kernel::OM->Get('Kernel::System::Cache')->CleanUp()}
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Lock]);$DB->FetchrowArray();
    die $Error if $Error;return $ID;
}
sub _sync {
    my ($S,$U,$L,$Actor,$Automatic)=@_;my $Users=$Kernel::OM->Get('Kernel::System::User');
    my %A=$Users->GetUserData(UserID=>$L->{AgentID});_fail('Linked agent unavailable') if !$A{UserID};
    my $Valid=$L->{Enabled} && ($U->{ValidID}||0)==1?1:2;
    # A profile update must not undo an independent agent-access revocation.
    $Valid=$A{ValidID}||2 if $Automatic && $Valid==1 && ($A{ValidID}||0)!=1;
    _fail('Cannot synchronize secondary agent profile') if !$Users->UserUpdate(UserID=>$A{UserID},UserLogin=>$A{UserLogin},
        UserFirstname=>$U->{UserFirstname},UserLastname=>$U->{UserLastname},UserEmail=>$U->{UserEmail},UserTitle=>$U->{UserTitle},
        ValidID=>$Valid,ChangeUserID=>$Actor);
    return 1;
}
sub SyncCustomer {
    my ($S,%P)=@_;return 1 if !$Kernel::OM->Get('Kernel::Config')->Get('TESSERA::LocalIdentity::Enabled');
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    _fail('Cannot resolve changed customer') if !$DB->Prepare(SQL=>'SELECT id FROM customer_user WHERE login = ?',Bind=>[\$P{CustomerUserID}],Limit=>1);
    my @Row=$DB->FetchrowArray();return 1 if !@Row;
    my $L=$S->_row(CustomerRowID=>$Row[0]);return 1 if !$L;
    my $U=$S->_subject(CustomerRowID=>$Row[0]);
    return $S->_sync($U,$L,$P{UserID},1);
}
sub AgentPasswordTarget {
    my ($S,%P)=@_;my $L=$S->_row(AgentLogin=>$P{AgentLogin});return {Linked=>0} if !$L;
    _fail('Linked password routing is not ready') if !$S->RoutingReady();
    my $U=$S->_subject(CustomerRowID=>$L->{CustomerRowID});
    return {Linked=>1,CustomerUserID=>$U->{UserLogin}};
}
sub AuthenticateAgent {
    my ($S,%P)=@_;my $L=$S->_row(AgentLogin=>$P{User});return {Linked=>0} if !$L;
    return {Linked=>1} if !$S->RoutingReady() || !$L->{Enabled};
    my $U=$S->_subject(CustomerRowID=>$L->{CustomerRowID});return {Linked=>1} if ($U->{ValidID}||0)!=1;
    my %A=$Kernel::OM->Get('Kernel::System::User')->GetUserData(UserID=>$L->{AgentID},Valid=>1);
    return {Linked=>1} if !$A{UserID} || ($A{ValidID}||0)!=1;
    require Kernel::System::CustomerAuth::DB;
    my $OK=Kernel::System::CustomerAuth::DB->new(Count=>'')->Auth(User=>$U->{UserLogin},Pw=>$P{Pw});
    return {Linked=>1,Login=>$OK?$A{UserLogin}:undef};
}
1;
