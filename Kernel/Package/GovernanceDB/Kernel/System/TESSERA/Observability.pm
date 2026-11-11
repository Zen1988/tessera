package Kernel::System::TESSERA::Observability;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Time::Local qw(timegm);
use POSIX qw(strftime);
our @ObjectDependencies = qw(Kernel::Config Kernel::System::DB Kernel::System::JSON Kernel::System::User Kernel::System::TESSERA::ProviderIdentity Kernel::System::TESSERA::APIPermission Kernel::System::TESSERA::RiskRegister Kernel::System::Ticket Kernel::System::MELTObject::Activity Kernel::System::GenericInterface::Webservice);
sub new { return bless {}, $_[0] }
sub _fail { die "$_[0]\n" }
sub _ids {
    my ($V)=@_;
    _fail('Invalid configured scope') if ref $V ne 'ARRAY' || @$V>200 || grep {ref $_ || !defined $_ || !/\A[1-9][0-9]{0,9}\z/} @$V;
    return $V;
}
# Registry grants are separate from identity authentication and object permissions.
sub Authorize {
    my ($S,%P)=@_;
    my $C=$Kernel::OM->Get('Kernel::Config');
    return if !$C->Get('TESSERA::API::Enabled') || !$C->Get('TESSERA::Observability::Enabled');
    return if ($P{Header}||'') !~ /\ABearer (ztsm_[A-Za-z0-9]{12}\.[A-Za-z0-9]{64})\z/;
    return $Kernel::OM->Get('Kernel::System::TESSERA::ProviderIdentity')->Authenticate(Token=>$1,Grant=>$P{Grant});
}
sub StorageEnsure {
    my ($S)=@_;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return $DB->Do(SQL=>q{CREATE TABLE IF NOT EXISTS tessera_monitor_alert (
        id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        source_name VARCHAR(100) NOT NULL,
        fingerprint VARCHAR(64) NOT NULL,
        cycle_key VARCHAR(40) NOT NULL,
        alert_status VARCHAR(10) NOT NULL,
        melt_object_id BIGINT NOT NULL,
        payload LONGBLOB NOT NULL,
        create_time DATETIME NOT NULL,
        change_time DATETIME NOT NULL,
        UNIQUE KEY tessera_monitor_source (source_name, fingerprint),
        INDEX tessera_monitor_target (melt_object_id, id)
    ) ENGINE=InnoDB});
}
sub ProviderEnsure {
    my ($S)=@_;
    my $W=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    my $Old=$W->WebserviceGet(Name=>'TESSERAObservability');
    return 1 if $Old && $Old->{ID}; # Existing administrator configuration is never overwritten.
    return $W->WebserviceAdd(Name=>'TESSERAObservability',ValidID=>1,UserID=>1,Config=>{
        Debugger=>{DebugThreshold=>'error',TestMode=>'0'},
        Provider=>{Operation=>{Observability=>{Type=>'TESSERA::Observability',Description=>'Scoped reporting and Alertmanager ingestion',MappingInbound=>{},MappingOutbound=>{}}},
            Transport=>{Type=>'HTTP::TESSERAObservability',Config=>{MaxLength=>'1048576',KeepAlive=>'0',
                RouteOperationMapping=>{Observability=>{RequestMethod=>['GET','POST'],Route=>'/v1/:Resource'}}}}}
    }) ? 1 : 0;
}
sub _time {
    my ($T)=@_;
    _fail('Invalid alert time') if !defined $T || ref $T || $T !~ /\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.(\d{1,9}))?(Z|[+-]\d\d:\d\d)\z/;
    my ($y,$m,$d,$h,$mi,$se,$frac,$zone)=($1,$2,$3,$4,$5,$6,$7||'',$8);
    _fail('Invalid alert time') if $y<1970 || $y>2200 || $m<1 || $m>12 || $d<1 || $d>31 || $h>23 || $mi>59 || $se>59;
    my $epoch=eval {timegm($se,$mi,$h,$d,$m-1,$y)};
    _fail('Invalid alert time') if !defined $epoch || strftime('%Y-%m-%dT%H:%M:%S',gmtime($epoch)) ne substr($T,0,19);
    if ($zone ne 'Z') {
        my ($sign,$zh,$zm)=$zone=~/([+-])(\d\d):(\d\d)/;
        _fail('Invalid alert time') if $zh>23 || $zm>59;
        $epoch-=($sign eq '+'?1:-1)*($zh*3600+$zm*60);
    }
    return sprintf('%020d.%s',$epoch,$frac.('0' x (9-length($frac))));
}
sub _strings {
    my ($V,$Max)=@_;
    _fail('Invalid alert labels or annotations') if ref $V ne 'HASH' || keys(%$V)>$Max;
    for my $K (keys %$V) {
        _fail('Invalid alert labels or annotations') if length($K)>128 || $K!~/\A[a-zA-Z_][a-zA-Z0-9_]*\z/
            || !defined $V->{$K} || ref $V->{$K} || length($V->{$K})>8192;
    }
    return {%$V};
}
sub Normalize {
    my ($S,$D)=@_;
    _fail('Invalid Alertmanager v4 notification') if ref $D ne 'HASH' || ($D->{version}||'') ne '4'
        || ($D->{status}||'')!~/\A(?:firing|resolved)\z/ || ref $D->{alerts} ne 'ARRAY'
        || !@{$D->{alerts}} || @{$D->{alerts}}>100;
    _fail('Truncated alert notifications are not accepted; narrow Alertmanager groups') if ($D->{truncatedAlerts}||0) ne '0';
    my @Alerts;
    for my $A (@{$D->{alerts}}) {
        _fail('Invalid alert') if ref $A ne 'HASH' || ($A->{status}||'')!~/\A(?:firing|resolved)\z/
            || ($A->{fingerprint}||'')!~/\A[a-fA-F0-9]{16,64}\z/;
        my $Labels=_strings($A->{labels},64); my $Annotations=_strings($A->{annotations}||{},32);
        _fail('Missing alertname') if !length($Labels->{alertname}||'');
        my $Cycle=_time($A->{startsAt});
        my $End=$A->{status} eq 'resolved' ? _time($A->{endsAt}) : undef;
        _fail('Resolution precedes firing') if defined $End && $End lt $Cycle;
        push @Alerts,{Fingerprint=>lc($A->{fingerprint}),Cycle=>$Cycle,Status=>$A->{status},
            StartsAt=>$A->{startsAt},EndsAt=>$A->{status} eq 'resolved'?$A->{endsAt}:undef,Labels=>$Labels,Annotations=>$Annotations};
    }
    return \@Alerts;
}
sub Ingest {
    my ($S,%P)=@_;
    my $C=$P{Client}; my $Alerts=$S->Normalize($P{Data});
    _fail('Invalid source configuration') if ($C->{SourceName}||'')!~/\A[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\z/
        || ($C->{TargetMELTObjectID}||'')!~/\A[1-9][0-9]{0,9}\z/ || ($C->{ActorID}||'')!~/\A[1-9][0-9]{0,9}\z/;
    my %Actor=$Kernel::OM->Get('Kernel::System::User')->GetUserData(UserID=>$C->{ActorID},Valid=>1);
    _fail('Invalid evidence actor') if !$Actor{UserID} || ($Actor{ValidID}||0)!=1;
    _fail('MELT target not authorized') if !$Kernel::OM->Get('Kernel::System::TESSERA::APIPermission')->MELTObjectCheck(
        CustomerUserID=>$C->{Identity}{CustomerUserID},MELTObjectID=>$C->{TargetMELTObjectID});
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    # Activity evidence and correlation state must share transactional storage.
    my $EvidenceTable='melt_object_activity_article';
    _fail('MELT evidence requires InnoDB storage') if !$DB->Prepare(SQL=>'SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',Bind=>[\$EvidenceTable])
        || lc((($DB->FetchrowArray())[0])||'') ne 'innodb';
    my $Lock='tessera_alert_'.substr(sha256_hex($C->{SourceName}),0,40);
    _fail('Alert source busy') if !$DB->Prepare(SQL=>'SELECT GET_LOCK(?, 2)',Bind=>[\$Lock]) || !(($DB->FetchrowArray())[0]);
    my ($Error,$Result); my $Begun;
    eval {
        _fail('Cannot begin alert transaction') if !$DB->BeginWork(); $Begun=1;
        _fail('Cannot count alert source') if !$DB->Prepare(SQL=>'SELECT COUNT(*) FROM tessera_monitor_alert WHERE source_name = ?',Bind=>[\$C->{SourceName}]);
        my $Count=($DB->FetchrowArray())[0];
        _fail('Cannot count alert source') if !defined $Count || $Count!~/\A[0-9]+\z/;
        my ($Changed,$Duplicate)=(0,0);
        for my $A (@$Alerts) {
            _fail('Cannot read alert state') if !$DB->Prepare(SQL=>'SELECT id, cycle_key, alert_status, melt_object_id FROM tessera_monitor_alert WHERE source_name = ? AND fingerprint = ? FOR UPDATE',Bind=>[\$C->{SourceName},\$A->{Fingerprint}]);
            my @Old=$DB->FetchrowArray();
            _fail('Source target changed; use a new SourceName') if @Old && $Old[3]!=$C->{TargetMELTObjectID};
            _fail('Alert source capacity reached') if !@Old && $Count>=10000;
            # A terminal cycle cannot be reopened by delayed firing deliveries.
            if (@Old && ($A->{Cycle} lt $Old[1] || ($A->{Cycle} eq $Old[1] && ($Old[2] eq 'resolved' || $Old[2] eq $A->{Status})))) {$Duplicate++; next}
            $Count++ if !@Old;
            my $Payload=JSON::PP->new->canonical->encode($A);
            my $OK=@Old ? $DB->Do(SQL=>'UPDATE tessera_monitor_alert SET cycle_key = ?, alert_status = ?, payload = ?, change_time = current_timestamp WHERE id = ?',Bind=>[\$A->{Cycle},\$A->{Status},\$Payload,\$Old[0]])
                : $DB->Do(SQL=>'INSERT INTO tessera_monitor_alert (source_name, fingerprint, cycle_key, alert_status, melt_object_id, payload, create_time, change_time) VALUES (?, ?, ?, ?, ?, ?, current_timestamp, current_timestamp)',Bind=>[\$C->{SourceName},\$A->{Fingerprint},\$A->{Cycle},\$A->{Status},\$C->{TargetMELTObjectID},\$Payload]);
            _fail('Cannot save alert state') if !$OK;
            _fail('Cannot save MELT alert evidence') if !$Kernel::OM->Get('Kernel::System::MELTObject::Activity')->ActivityAdd(
                MELTObjectID=>$C->{TargetMELTObjectID},EventType=>'AlertmanagerNotification',Source=>'Alertmanager:'.$C->{SourceName},
                Subject=>'Alertmanager '.$A->{Status}.': '.substr($A->{Labels}{alertname},0,100),
                Body=>'External alert evidence recorded. No ticket or governance transition was performed.',Payload=>$A,UserID=>$C->{ActorID});
            $Changed++;
        }
        _fail('Cannot commit alert evidence') if !$DB->{dbh}->commit(); $Begun=0;
        $Result={Accepted=>scalar(@$Alerts),Changed=>$Changed,Duplicates=>$Duplicate}; 1;
    } or $Error=$@||'Alert ingestion failed';
    $DB->Rollback() if $Begun;
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Lock]);$DB->FetchrowArray();
    die $Error if $Error;
    return $Result;
}
sub Report {
    my ($S,%P)=@_;
    my $C=$P{Client}; my $D=$P{Data};
    _fail('Invalid report query') if ref $D ne 'HASH' || grep {!/\A(?:Resource|Limit|Cursor)\z/} keys %$D;
    my $Limit=$D->{Limit}//100; my $Cursor=$D->{Cursor}//0;
    _fail('Invalid report pagination') if ref $Limit || ref $Cursor || $Limit!~/\A[1-9][0-9]{0,2}\z/ || $Limit>200 || $Cursor!~/\A[0-9]{1,12}\z/;
    my (@Rows,$Next); my $Resource=$D->{Resource};
    if ($Resource eq 'tickets') {
        my $Queues=_ids($C->{TicketQueueIDs});
        if (@$Queues) {
            my $DB=$Kernel::OM->Get('Kernel::System::DB');
            my $SQL='SELECT id FROM ticket WHERE id > ? AND queue_id IN ('.join(',',('?') x @$Queues).') ORDER BY id';
            _fail('Cannot read tickets') if !$DB->Prepare(SQL=>$SQL,Bind=>[\$Cursor,map {\$_} @$Queues],Limit=>$Limit+1);
            my @IDs; while (my @R=$DB->FetchrowArray()) {push @IDs,$R[0]}
            my $More=@IDs>$Limit; pop @IDs if $More;
            my $Ticket=$Kernel::OM->Get('Kernel::System::Ticket');
            my $Permission=$Kernel::OM->Get('Kernel::System::TESSERA::RiskRegister');
            for my $ID (@IDs) {
                next if !$Permission->Visible(TicketID=>$ID,CustomerUserID=>$C->{Identity}{CustomerUserID});
                my %T=$Ticket->TicketGet(TicketID=>$ID,DynamicFields=>0,UserID=>1);
                next if !$T{TicketID};
                push @Rows,{map {$_=>$T{$_}} qw(TicketID TicketNumber Title State StateType Type Queue Service Priority CreateTime ChangeTime)};
            }
            $Next=$IDs[-1] if $More;
        }
    }
    elsif ($Resource eq 'risks') {
        # Reuse the governed register: final decision evidence, current iteration,
        # per-master/assessment permission checks and resolved catalog names.
        my $R=$Kernel::OM->Get('Kernel::System::TESSERA::RiskRegister')->Report(CustomerUserID=>$C->{Identity}{CustomerUserID});
        _fail('Risk register unavailable') if ref $R ne 'HASH' || ref $R->{Rows} ne 'ARRAY';
        my $End=$Cursor+$Limit; $End=@{$R->{Rows}} if $End>@{$R->{Rows}};
        for my $I ($Cursor..$End-1) {
            my $Row=$R->{Rows}[$I];
            my %Out=map {$_=>$Row->{$_}} qw(TicketID TicketNumber Title State Status Outcome GovernanceDate ReviewDue RowNumber);
            for my $J (0..$#{$R->{Columns}}) {$Out{'Column'.($J+1)}=$Row->{Cells}[$J]}
            push @Rows,\%Out;
        }
        $Next=$End if $End<@{$R->{Rows}};
        return {Rows=>\@Rows,NextCursor=>$Next,Columns=>[map {{Name=>'Column'.($_+1),Label=>$R->{Columns}[$_]{Label}}} 0..$#{$R->{Columns}}]};
    }
    elsif ($Resource eq 'alerts') {
        my $Targets=_ids($C->{MELTObjectIDs});
        my $Permission=$Kernel::OM->Get('Kernel::System::TESSERA::APIPermission');
        my @Allowed=grep {$Permission->MELTObjectCheck(CustomerUserID=>$C->{Identity}{CustomerUserID},MELTObjectID=>$_)} @$Targets;
        if (@Allowed) {
            my $DB=$Kernel::OM->Get('Kernel::System::DB');
            _fail('Cannot read alerts') if !$DB->Prepare(SQL=>'SELECT id, source_name, fingerprint, alert_status, melt_object_id, payload, change_time FROM tessera_monitor_alert WHERE id > ? AND melt_object_id IN ('.join(',',('?') x @Allowed).') ORDER BY id',Bind=>[\$Cursor,map {\$_} @Allowed],Limit=>$Limit+1);
            while (my @R=$DB->FetchrowArray()) {
                my $A=JSON::PP->new->decode($R[5]);
                push @Rows,{AlertID=>$R[0],Source=>$R[1],Fingerprint=>$R[2],Status=>$R[3],MELTObjectID=>$R[4],ChangeTime=>$R[6],
                    AlertName=>$A->{Labels}{alertname},Severity=>$A->{Labels}{severity}//'',Instance=>$A->{Labels}{instance}//'',StartsAt=>$A->{StartsAt},EndsAt=>$A->{EndsAt}};
            }
            if (@Rows>$Limit) {pop @Rows;$Next=$Rows[-1]{AlertID}}
        }
    }
    else {_fail('Unknown report')}
    return {Rows=>\@Rows,NextCursor=>$Next};
}
1;
