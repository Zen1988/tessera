package Kernel::System::TESSERA::ProviderIdentity;
use strict;
use warnings;
use JSON::PP ();
our @ObjectDependencies = qw(Kernel::System::DB Kernel::System::TESSERA::APIKey Kernel::System::CustomerUser Kernel::System::TESSERA::IntegrationOnboarding);
my %Grants=map {$_=>1} qw(report:tickets report:alerts report:risks ingest:alertmanager);
sub new { return bless {}, $_[0] }
sub _admin {
    my ($S,$U)=@_;
    die "Administrator access required.\n" if !$Kernel::OM->Get('Kernel::System::TESSERA::IntegrationOnboarding')->Authorized($U);
}
sub SubjectSearch {
    my ($S,%P)=@_;$S->_admin($P{UserID});
    my $Term=$P{Term}//'';
    return [] if ref $Term || length($Term)<2 || length($Term)>100 || $Term=~/[\x00-\x1f\x7f]/ || $Term!~/[\pL\pN]/;
    my $Users=$Kernel::OM->Get('Kernel::System::CustomerUser');
    my %Matches=$Users->CustomerSearch(Search=>'*'.$Term.'*',Valid=>1,Limit=>20);
    my %EmailMatches=$Users->CustomerSearch(PostMasterSearch=>'*'.$Term.'*',Valid=>1,Limit=>20);
    @Matches{keys %EmailMatches}=values %EmailMatches;
    my @Results;
    for my $Login (sort keys %Matches) {
        my %U=$Users->CustomerUserDataGet(User=>$Login);
        next if !$U{UserLogin} || ($U{ValidID}||$U{UserValidID}||0)!=1;
        push @Results,{Value=>$U{UserLogin},Label=>$S->_SubjectLabel(\%U)};
        last if @Results>=20;
    }
    return \@Results;
}
sub _SubjectLabel {
    my ($S,$U)=@_;
    my $Name=join(' ',grep {defined $_ && length $_} @{$U}{qw(UserFirstname UserLastname)});
    my $Email=$U->{UserEmail}||'';
    return ($Name?"$Name ":'').($Email?"<$Email> ":'').'('.$U->{UserLogin}.')';
}
sub SubjectLabel {
    my ($S,%P)=@_;$S->_admin($P{UserID});
    return '' if !$P{CustomerUserID};
    my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$P{CustomerUserID});
    return $P{CustomerUserID}.' (unavailable)' if !$U{UserLogin};
    return $S->_SubjectLabel(\%U).(($U{ValidID}||$U{UserValidID}||0)==1?'':' (inactive)');
}
sub StorageEnsure {
    my ($S)=@_; my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Do(SQL=>q{CREATE TABLE IF NOT EXISTS tessera_api_identity (
        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, identity_name VARCHAR(100) NOT NULL,
        customer_user_id VARCHAR(200) NOT NULL, enabled SMALLINT NOT NULL, source_name VARCHAR(100) NULL,
        settings LONGBLOB NOT NULL, create_by INTEGER NOT NULL, change_by INTEGER NOT NULL,
        create_time DATETIME NOT NULL, change_time DATETIME NOT NULL,
        UNIQUE KEY tessera_api_identity_name (identity_name), UNIQUE KEY tessera_api_identity_source (source_name)
    ) ENGINE=InnoDB});
    return $DB->Do(SQL=>q{CREATE TABLE IF NOT EXISTS tessera_api_identity_token (
        key_id BIGINT NOT NULL PRIMARY KEY, identity_id BIGINT NOT NULL,
        INDEX tessera_api_identity_tokens (identity_id)
    ) ENGINE=InnoDB});
}
sub _settings {
    my ($S,$C)=@_;
    die "Invalid API identity settings.\n" if ref $C ne 'HASH' || grep {!/\A(?:Grants|TicketQueueIDs|MELTObjectIDs|SourceName|TargetMELTObjectID|ActorID)\z/} keys %$C;
    die "Select explicit API capabilities.\n" if ref $C->{Grants} ne 'ARRAY' || !@{$C->{Grants}} || @{$C->{Grants}}>4 || grep {ref $_ || !$Grants{$_}} @{$C->{Grants}};
    for my $F (qw(TicketQueueIDs MELTObjectIDs)) {
        $C->{$F}||=[];
        die "Invalid API data scope.\n" if ref $C->{$F} ne 'ARRAY' || @{$C->{$F}}>200 || grep {ref $_ || !defined $_ || !/\A[1-9][0-9]{0,9}\z/} @{$C->{$F}};
    }
    die "Ticket reporting requires a queue scope.\n" if grep($_ eq 'report:tickets',@{$C->{Grants}}) && !@{$C->{TicketQueueIDs}};
    die "Alert reporting requires MELT object scope.\n" if grep($_ eq 'report:alerts',@{$C->{Grants}}) && !@{$C->{MELTObjectIDs}};
    if (grep {$_ eq 'ingest:alertmanager'} @{$C->{Grants}}) {
        die "Alert ingestion requires source, MELT target and evidence actor.\n" if ($C->{SourceName}||'')!~/\A[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\z/
            || ($C->{TargetMELTObjectID}||'')!~/\A[1-9][0-9]{0,9}\z/ || ($C->{ActorID}||'')!~/\A[1-9][0-9]{0,9}\z/;
    }
    return JSON::PP->new->canonical->encode($C);
}
sub Save {
    my ($S,%P)=@_;$S->_admin($P{UserID});
    die "Invalid identity name.\n" if ($P{Name}||'')!~/\A[A-Za-z0-9][A-Za-z0-9_. -]{0,99}\z/;
    die "Invalid identity identifier.\n" if $P{ID} && $P{ID}!~/\A[1-9][0-9]*\z/;
    my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$P{CustomerUserID});
    die "Choose a valid permission subject.\n" if !$U{UserLogin} || ($U{ValidID}||$U{UserValidID}||0)!=1;
    my $Settings=$S->_settings($P{Settings});my $Enabled=$P{Enabled}?1:0;
    my $Source=grep($_ eq 'ingest:alertmanager',@{$P{Settings}{Grants}})?$P{Settings}{SourceName}:undef;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Cannot read identity name.\n" if !$DB->Prepare(SQL=>'SELECT id FROM tessera_api_identity WHERE identity_name = ?',Bind=>[\$P{Name}],Limit=>1);
    my @Taken=$DB->FetchrowArray();
    die "Identity name already exists.\n" if @Taken && (!$P{ID} || $Taken[0]!=$P{ID});
    if ($P{ID}) {
        my $Old=$S->Get(UserID=>$P{UserID},ID=>$P{ID});
        die "Identity unavailable.\n" if !$Old;
        # A new subject requires a new identity; old tokens must never change owner.
        die "Permission subject is immutable; create another identity.\n" if $Old->{CustomerUserID} ne $P{CustomerUserID};
        die "Cannot save identity.\n" if !$DB->Do(SQL=>'UPDATE tessera_api_identity SET identity_name = ?, enabled = ?, settings = ?, source_name = ?, change_by = ?, change_time = current_timestamp WHERE id = ?',Bind=>[\$P{Name},\$Enabled,\$Settings,\$Source,\$P{UserID},\$P{ID}]);
        return $P{ID};
    }
    die "Cannot create identity.\n" if !$DB->Do(SQL=>'INSERT INTO tessera_api_identity (identity_name, customer_user_id, enabled, settings, source_name, create_by, change_by, create_time, change_time) VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, current_timestamp)',Bind=>[\$P{Name},\$P{CustomerUserID},\$Enabled,\$Settings,\$Source,\$P{UserID},\$P{UserID}]);
    die "Cannot read new identity.\n" if !$DB->Prepare(SQL=>'SELECT id FROM tessera_api_identity WHERE identity_name = ?',Bind=>[\$P{Name}],Limit=>1);
    return ($DB->FetchrowArray())[0];
}
sub Get {
    my ($S,%P)=@_;$S->_admin($P{UserID});
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Prepare(SQL=>'SELECT id, identity_name, customer_user_id, enabled, settings FROM tessera_api_identity WHERE id = ?',Bind=>[\$P{ID}],Limit=>1);
    my @R=$DB->FetchrowArray();return if !@R;
    return {ID=>$R[0],Name=>$R[1],CustomerUserID=>$R[2],Enabled=>$R[3],Settings=>JSON::PP->new->decode($R[4])};
}
sub List {
    my ($S,%P)=@_;$S->_admin($P{UserID});my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Cannot list identities.\n" if !$DB->Prepare(SQL=>'SELECT id, identity_name, customer_user_id, enabled FROM tessera_api_identity ORDER BY identity_name',Limit=>500);
    my @Rows;while(my @R=$DB->FetchrowArray()){push @Rows,{ID=>$R[0],Name=>$R[1],CustomerUserID=>$R[2],Enabled=>$R[3]}}
    return \@Rows;
}
sub Tokens {
    my ($S,%P)=@_;$S->_admin($P{UserID});my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Cannot list tokens.\n" if !$DB->Prepare(SQL=>'SELECT k.id, k.key_name, k.key_prefix, k.expires_time, k.last_used_time, k.revoke_time FROM ztsm_api_key k INNER JOIN tessera_api_identity_token t ON t.key_id = k.id WHERE t.identity_id = ? ORDER BY k.id DESC',Bind=>[\$P{ID}],Limit=>100);
    my @Rows;while(my @R=$DB->FetchrowArray()){push @Rows,{KeyID=>$R[0],Name=>$R[1],Prefix=>$R[2],ExpiresTime=>$R[3],LastUsedTime=>$R[4],RevokeTime=>$R[5]}}
    return \@Rows;
}
sub Issue {
    my ($S,%P)=@_;$S->_admin($P{UserID});my $I=$S->Get(%P);
    die "Enable the API identity before issuing a token.\n" if !$I || !$I->{Enabled};
    die "Token lifetime must be 1 to 365 days.\n" if ($P{Days}||'')!~/\A[1-9][0-9]{0,2}\z/ || $P{Days}>365;
    die "Invalid token name.\n" if ($P{Name}||'')!~/\A[A-Za-z0-9][A-Za-z0-9_. -]{0,99}\z/;
    my $Keys=$Kernel::OM->Get('Kernel::System::TESSERA::APIKey');
    my $New=$Keys->KeyCreate(CustomerUserID=>$I->{CustomerUserID},Name=>$P{Name},ExpiresIn=>$P{Days}*86400,CreateBy=>$P{UserID});
    die "Cannot issue token.\n" if !$New;
    if (!$Kernel::OM->Get('Kernel::System::DB')->Do(SQL=>'INSERT INTO tessera_api_identity_token (key_id, identity_id) VALUES (?, ?)',Bind=>[\$New->{KeyID},\$P{ID}])) {
        $Keys->KeyRevoke(KeyID=>$New->{KeyID},UserID=>$P{UserID});die "Cannot bind token to API identity.\n";
    }
    return $New;
}
sub Revoke {
    my ($S,%P)=@_;$S->_admin($P{UserID});
    my $Tokens=$S->Tokens(%P);
    die "Token does not belong to this identity.\n" if !grep {$_->{KeyID} eq ($P{KeyID}||'')} @$Tokens;
    return $Kernel::OM->Get('Kernel::System::TESSERA::APIKey')->KeyRevoke(KeyID=>$P{KeyID},UserID=>$P{UserID});
}
# A scoped provider token must never bypass its grants through the older
# staged-change API, even when the permission subject has broader roles.
sub LegacyKeyAllowed {
    my ($S,%P)=@_;my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Prepare(SQL=>'SELECT identity_id FROM tessera_api_identity_token WHERE key_id = ?',Bind=>[\$P{KeyID}],Limit=>1);
    my @R=$DB->FetchrowArray();return @R ? 0 : 1;
}
sub Authenticate {
    my ($S,%P)=@_;
    my $I=$Kernel::OM->Get('Kernel::System::TESSERA::APIKey')->KeyAuthenticate(APIKey=>$P{Token});return if !$I;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Prepare(SQL=>'SELECT p.id, p.customer_user_id, p.settings FROM tessera_api_identity p INNER JOIN tessera_api_identity_token t ON t.identity_id = p.id WHERE t.key_id = ? AND p.enabled = 1',Bind=>[\$I->{KeyID}],Limit=>1);
    my @R=$DB->FetchrowArray();return if !@R || $R[1] ne $I->{CustomerUserID};
    my $C=eval {JSON::PP->new->decode($R[2])};return if ref $C ne 'HASH' || !eval {$S->_settings($C);1};
    return if !grep {$_ eq $P{Grant}} @{$C->{Grants}};
    return {%$C,Identity=>$I,ProviderIdentityID=>$R[0]};
}
1;
