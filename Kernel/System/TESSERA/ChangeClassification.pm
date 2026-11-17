package Kernel::System::TESSERA::ChangeClassification;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
our @ObjectDependencies=qw(Kernel::Config Kernel::System::DB Kernel::System::Ticket Kernel::System::User Kernel::System::Group Kernel::System::CustomerGroup Kernel::System::CustomerUser Kernel::System::DynamicField Kernel::System::DynamicField::Backend Kernel::System::GovernanceObject Kernel::System::ITSMConfigItem Kernel::System::LinkObject Kernel::System::HTMLUtils Kernel::System::State Kernel::System::Ticket::Article);
our $AuthorizedWrite;
sub new {bless {},shift}
sub _json {JSON::PP->new->canonical->utf8}
sub _one {my $V=$_[0];if (ref $V eq 'ARRAY') {return '' if !@$V;die "Ambiguous field value.\n" if @$V!=1;$V=$V->[0]}die "Ambiguous field value.\n" if ref $V;return defined $V?$V:''}
sub _values {my $V=$_[0];return () if !defined $V;return ref $V eq 'ARRAY'?map {_one($_)} @$V:(_one($V))}
sub _config {my ($S,$Name)=@_;$Kernel::OM->Get('Kernel::Config')->Get('TESSERA::ChangeClassification::'.$Name)}
sub Actor {
    my ($S,%P)=@_;my (@Groups,$Agent,$Customer);
    if ($P{CustomerUserID}) {
        my %C=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$P{CustomerUserID});return if ($C{ValidID} || 0)!=1;
        $Customer=$P{CustomerUserID};$Agent=$Kernel::OM->Get('Kernel::System::User')->UserLookup(UserLogin=>$Customer,Silent=>1);
    } else {$Agent=$P{UserID}}
    my %U=$Agent?$Kernel::OM->Get('Kernel::System::User')->GetUserData(UserID=>$Agent):();$Agent=undef if ($U{ValidID} || 0)!=1;
    my $Check=sub {my ($Name)=@_;return ($Customer && $Kernel::OM->Get('Kernel::System::CustomerGroup')->PermissionCheck(UserID=>$Customer,GroupName=>$Name,Type=>'rw'))
        || ($Agent && $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(UserID=>$Agent,GroupName=>$Name,Type=>'rw'))};
    my $IPC=$Check->('IPC')?1:0;my $Allowed=$S->_config('Groups') || [];return if ref $Allowed ne 'ARRAY';
    return if !$IPC && !grep {defined $_ && !ref $_ && length $_ && $Check->($_)} @$Allowed;
    return {UserID=>$Agent || $Kernel::OM->Get('Kernel::Config')->Get('CustomerPanelUserID') || 1,CustomerUserID=>$Customer || '',IPC=>$IPC,Name=>$Customer || $U{UserLogin} || $Agent};
}
sub _ticket {
    my ($S,$ID)=@_;die "Invalid change ticket.\n" if !defined $ID || ref $ID || $ID!~/\A[1-9][0-9]*\z/;
    my %T=$Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(TicketID=>$ID,DynamicFields=>1,UserID=>1,Silent=>1);
    die "A parent Change ticket is required.\n" if !$T{TicketID} || ($T{Type} || '') ne 'Change' || _one($T{'DynamicField_ZTicket-Parent'});
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Cannot read live change state.\n" if !$DB->Prepare(SQL=>'SELECT ty.name,s.name,st.name FROM ticket t JOIN ticket_type ty ON ty.id=t.type_id JOIN ticket_state s ON s.id=t.ticket_state_id JOIN ticket_state_type st ON st.id=s.type_id WHERE t.id=?',Bind=>[\$ID],Limit=>1);
    my @Live=$DB->FetchrowArray();die "A parent Change ticket is required.\n" if @Live!=3 || $Live[0] ne 'Change';@T{qw(Type State StateType)}=@Live;
    die "Cannot read live change decisions.\n" if !$DB->Prepare(SQL=>q{SELECT f.name,v.value_text FROM dynamic_field f LEFT JOIN dynamic_field_value v ON v.field_id=f.id AND v.object_id=? WHERE f.object_type='Ticket' AND f.field_type='Dropdown' AND f.valid_id=1 AND f.name IN ('ChangeType','ChangeClassification')},Bind=>[\$ID]);
    my %Decision;while (my @Row=$DB->FetchrowArray()) {die "Ambiguous change decision field.\n" if exists $Decision{$Row[0]};$Decision{$Row[0]}=$Row[1]}
    die "Change decision fields are unavailable.\n" if !exists $Decision{ChangeType} || !exists $Decision{ChangeClassification};
    @T{qw(DynamicField_ChangeType DynamicField_ChangeClassification)}=@Decision{qw(ChangeType ChangeClassification)};
    return \%T;
}
sub CanManage {
    my ($S,%P)=@_;my $Actor=$S->Actor(%P);return if !$Actor;my $T=eval {$S->_ticket($P{TicketID})};return if !$T;
    return $Actor if $Actor->{IPC};my $Tickets=$Kernel::OM->Get('Kernel::System::Ticket');
    my $OK=$Actor->{CustomerUserID}?$Tickets->TicketCustomerPermission(TicketID=>$P{TicketID},UserID=>$Actor->{CustomerUserID},Type=>'rw')
        :$Tickets->TicketPermission(TicketID=>$P{TicketID},UserID=>$Actor->{UserID},Type=>'rw',LogNo=>1);
    return $OK?$Actor:undef;
}
sub _assessment {
    my ($S,$ID)=@_;my $Ticket=$Kernel::OM->Get('Kernel::System::Ticket');
    my @IDs=$Ticket->TicketSearch(Result=>'ARRAY',Types=>['Assessment'],'DynamicField_ZTicket-Parent'=>{Equals=>$ID},Limit=>1001,UserID=>1,Permission=>'ro');
    return if !@IDs || @IDs>1000;
    for my $Child (@IDs) {my %T=$Ticket->TicketGet(TicketID=>$Child,DynamicFields=>1,UserID=>1,Silent=>1);
        return if _one($T{'DynamicField_ZTicket-Parent'}) ne "$ID" || ($T{State} || '') ne 'closed successful';}
    return 1;
}
sub _names {
    my ($S,$Value,$Class)=@_;my @Names;
    for my $ID (_values($Value)) {next if !length $ID;die "Unresolved governance reference.\n" if $ID!~/\A[1-9][0-9]*\z/;
        my $O=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$ID);
        die "Unresolved governance reference.\n" if !$O || ($O->{Class} || '') ne $Class || !$O->{Name};push @Names,$O->{Name};}
    return join(', ',@Names);
}
sub _plain {
    my ($S,$Text)=@_;$Text=_one($Text);return '' if !length $Text;
    return $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(String=>$Text) if $Text=~/<[^>]+>/;
    return $Text;
}
sub _context {
    my ($S,$T)=@_;my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');my $Backend=$Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my @Phases;for my $Phase (['ZCH-Precheck','Pre-check'],['ZCH-Implementation','Implementation'],['ZCH-PostChange','Post-Change'],['ZCH-Rollback','Rollback']) {
        my $F=$DF->DynamicFieldGet(Name=>$Phase->[0]);next if !$F || !$F->{ID};die "Invalid submitted runbook field.\n" if ($F->{ObjectType} || '') ne 'Ticket' || ($F->{FieldType} || '') ne 'Set';
        my $Rows=$Backend->ValueGet(DynamicFieldConfig=>$F,ObjectID=>$T->{TicketID});next if !defined $Rows;
        die "Invalid submitted runbook.\n" if ref $Rows ne 'ARRAY' || @$Rows>500;
        my (@Public,$Index);for my $R (@$Rows) {die "Invalid submitted runbook row.\n" if ref $R ne 'HASH';$Index++;
            my $Level=_one($R->{'ZCH-BlueLevel'});$Level=1 if $Level!~/\A[0-9]+\z/;
            my $Seq=_one($R->{'ZCH-Seq'});$Seq=$Index if $Seq!~/\A[0-9]+\z/;
            push @Public,{Level=>0+$Level,Sequence=>0+$Seq,Activity=>_one($R->{'ZCH-Activity'}),Description=>$S->_plain($R->{'ZCH-Description'}),
                Mandatory=>_one($R->{'ZCH-Mandatory'})=~/\A(?:1|yes|true|on)\z/i?1:0,Strict=>_one($R->{'ZCH-Strict'})=~/\A(?:1|yes|true|on)\z/i?1:0,
                Start=>_one($R->{'ZCH-ScheduleStart'}),Finish=>_one($R->{'ZCH-ScheduleFinish'})};}
        @Public=sort {$a->{Level}<=>$b->{Level} || $a->{Sequence}<=>$b->{Sequence}} @Public;
        push @Phases,{Name=>$Phase->[1],Steps=>\@Public} if @Public;
    }
    my %CI=map {$_=>1} grep {/\A[1-9][0-9]*\z/} _values($T->{'DynamicField_ZRM-RiskTargetCI'});
    my $Links=$Kernel::OM->Get('Kernel::System::LinkObject')->LinkList(Object=>'Ticket',Key=>$T->{TicketID},Object2=>'ITSMConfigItem',State=>'Valid',UserID=>1) || {};
    for my $Type (values %{$Links->{ITSMConfigItem} || {}}) {for my $Direction (values %$Type) {$CI{$_}=1 for keys %$Direction}}
    die "Too many affected assets.\n" if keys(%CI)>1000;my @Assets;
    for my $ID (sort {$a<=>$b} keys %CI) {my $O=$Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(ConfigItemID=>$ID);die "Unresolved affected asset.\n" if !$O || !$O->{Name};push @Assets,$O->{Name}}
    my %C=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$T->{CustomerUserID});
    my $Requester=join(' ',grep {defined $_ && length $_} @C{qw(UserFirstname UserLastname)});
    return {TicketID=>$T->{TicketID},TicketNumber=>$T->{TicketNumber},Title=>$T->{Title} || '',Service=>$T->{Service} || '',Requester=>$Requester || 'Requester unavailable',
        Assets=>\@Assets,Environment=>$S->_names($T->{'DynamicField_ZTicket-Env'},'Environment'),Application=>$S->_names($T->{'DynamicField_ZTicket-Application'},'Application'),
        BlueBook=>$S->_names($T->{'DynamicField_ZTicket-BlueBook'},'BlueBook'),Template=>$S->_names($T->{'DynamicField_ZCH-Template'},'Template'),Phases=>\@Phases,
        Start=>_one($T->{'DynamicField_ZTicket-ScheduleStart'}),Finish=>_one($T->{'DynamicField_ZTicket-ScheduleFinish'})};
}
sub _key {'TESSERA::ChangeAnnouncement::'.$_[0]}
sub _record {
    my ($S,$ID)=@_;my $Key=_key($ID);my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Announcement storage unavailable.\n" if !$DB->Prepare(SQL=>'SELECT data_value FROM system_data WHERE data_key = ?',Bind=>[\$Key]);
    my @Row=$DB->FetchrowArray();return if !defined $Row[0];my $R=eval {_json()->decode($Row[0])};
    die "Invalid announcement snapshot.\n" if ref $R ne 'HASH' || ($R->{Version} || 0)!=1 || ref $R->{Public} ne 'HASH';return $R;
}
sub _revision {
    my ($S,$T,$Context,$Record)=@_;return sha256_hex(_json()->encode({Context=>$Context,ChangeType=>_one($T->{DynamicField_ChangeType}) || 'Normal',
        ChangeClassification=>_one($T->{DynamicField_ChangeClassification}) || 'Not-Assessed',Record=>$Record}));
}
sub _descriptionDefault {
    my ($S,$ID)=@_;my $Articles=$Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @First=$Articles->ArticleList(TicketID=>$ID,OnlyFirst=>1);
    return '' if !@First || !$First[0]{IsVisibleForCustomer};
    my $Backend=$Articles->BackendForArticle(%{$First[0]});return '' if !$Backend;
    my %A=$Backend->ArticleGet(TicketID=>$ID,ArticleID=>$First[0]{ArticleID},DynamicFields=>0);
    my $Body=$A{Body} || '';return '' if ref $Body || length($Body)>20000;
    return ($A{MimeType} || $A{ContentType} || '')=~/text\/html/i?$S->_plain($Body):$Body;
}
sub View {
    my ($S,%P)=@_;my $Actor=$S->CanManage(%P);die "Change management permission required.\n" if !$Actor;
    my $T=$S->_ticket($P{TicketID});my $C=$S->_context($T);my $R=$S->_record($P{TicketID});
    return {Context=>$C,Actor=>$Actor,AssessmentComplete=>$S->_assessment($P{TicketID})?1:0,Revision=>$S->_revision($T,$C,$R),
        ChangeType=>_one($T->{DynamicField_ChangeType}) || 'Normal',ChangeClassification=>_one($T->{DynamicField_ChangeClassification}) || 'Not-Assessed',
        Description=>$R && length($R->{Public}{Description} || '')?$R->{Public}{Description}:$S->_descriptionDefault($P{TicketID}),
        Summary=>$R && length($R->{Public}{Summary} || '')?$R->{Public}{Summary}:$T->{Title}};
}
sub WriteAllowed {
    my ($Class,%P)=@_;my $Name=$P{DynamicFieldConfig}{Name} || '';
    return 1 if $Name!~/\A(?:ChangeType|ChangeClassification)\z/i;
    return if $Name ne 'ChangeType' && $Name ne 'ChangeClassification';
    return if !$AuthorizedWrite || $P{Set} || ($P{ObjectID} || '') ne $AuthorizedWrite->{TicketID} || ($P{UserID} || '') ne $AuthorizedWrite->{UserID};
    return defined $P{Value} && !ref $P{Value} && $P{Value} eq $AuthorizedWrite->{$Name};
}
sub Save {
    my ($S,%P)=@_;die "Invalid change type.\n" if ($P{ChangeType} || '')!~/\A(?:Normal|Standard|Emergency)\z/;
    die "Invalid change classification.\n" if ($P{ChangeClassification} || '')!~/\A(?:Normal|Not-Assessed|Major)\z/;
    die "A classification reason is required.\n" if !defined $P{Reason} || ref $P{Reason} || $P{Reason}!~/\S/ || length($P{Reason})>4000;
    if ($P{ChangeClassification} eq 'Major') {
        for (qw(Description Summary)) {die "A public description and summary are required.\n" if !defined $P{$_} || ref $P{$_} || $P{$_}!~/\S/ || length($P{$_})>20000}
    }
    my $DB=$Kernel::OM->Get('Kernel::System::DB');my $Lock='tessera_change_'.$P{TicketID};
    die "Invalid ticket.\n" if ($P{TicketID} || '')!~/\A[1-9][0-9]*\z/;
    die "Change classification is busy.\n" if !$DB->Prepare(SQL=>'SELECT GET_LOCK(?,5)',Bind=>[\$Lock]);my @L=$DB->FetchrowArray();die "Change classification is busy.\n" if !$L[0];
    my ($Error,$Began);eval {
        my $V=$S->View(%P);die "Change information changed; reload before saving.\n" if ($P{Revision} || '') ne $V->{Revision};
        die "Complete all linked assessment tickets before classification.\n" if !$V->{AssessmentComplete} && ($P{ChangeClassification} ne 'Not-Assessed' || $P{ChangeType} ne 'Normal') && !($V->{Actor}{IPC} && $P{AssessmentOverride});
        my @Tables=qw(ticket dynamic_field_value system_data ticket_history article article_data_mime article_data_mime_plain);
        die "Cannot verify transactional evidence storage.\n" if !$DB->Prepare(SQL=>'SELECT TABLE_NAME,ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN ('.join(',',map {'?'} @Tables).')',Bind=>[map {\$_} @Tables]);
        my %Engine;while (my @Row=$DB->FetchrowArray()) {$Engine{$Row[0]}=lc($Row[1] || '')}
        die "Change decisions require transactional InnoDB evidence storage.\n" if grep {($Engine{$_} || '') ne 'innodb'} @Tables;
        die "Cannot begin classification transaction.\n" if !$DB->BeginWork();$Began=1;
        local $AuthorizedWrite={TicketID=>"$P{TicketID}",UserID=>$V->{Actor}{UserID},ChangeType=>$P{ChangeType},ChangeClassification=>$P{ChangeClassification}};
        my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');my $B=$Kernel::OM->Get('Kernel::System::DynamicField::Backend');
        for my $Name (qw(ChangeType ChangeClassification)) {
            my $F=$DF->DynamicFieldGet(Name=>$Name);die "Classification field unavailable.\n" if !$F || !$F->{ID} || ($F->{Name} || '') ne $Name || ($F->{ObjectType} || '') ne 'Ticket' || ($F->{FieldType} || '') ne 'Dropdown'
                || ref $F->{Config}{PossibleValues} ne 'HASH' || !exists $F->{Config}{PossibleValues}{$P{$Name}};
            die "Cannot store change classification.\n" if !$B->ValueSet(DynamicFieldConfig=>$F,ObjectID=>$P{TicketID},Value=>$P{$Name},UserID=>$V->{Actor}{UserID});
        }
        my $Fresh=$S->_ticket($P{TicketID});die "Change decisions were not stored consistently.\n" if _one($Fresh->{DynamicField_ChangeType}) ne $P{ChangeType} || _one($Fresh->{DynamicField_ChangeClassification}) ne $P{ChangeClassification};
        my $Old=$S->_record($P{TicketID});my $Counter=$Old?($Old->{Revision} || 0):0;die "Invalid announcement revision.\n" if ref $Counter || $Counter!~/\A[0-9]+\z/;
        my $R={Version=>1,Revision=>$Counter+1,PreparedBy=>$V->{Actor}{Name},SourceDigest=>sha256_hex(_json()->encode($V->{Context})),Public=>{%{$V->{Context}},
            ChangeType=>$P{ChangeType},ChangeClassification=>$P{ChangeClassification},Description=>_one($P{Description}),Summary=>_one($P{Summary})}};
        my $Raw=_json()->encode($R);die "Announcement snapshot is too large.\n" if length($Raw)>4*1024*1024;
        my $Key=_key($P{TicketID});my $UID=$V->{Actor}{UserID};
        my $OK=$Old?$DB->Do(SQL=>'UPDATE system_data SET data_value=?,change_time=current_timestamp,change_by=? WHERE data_key=?',Bind=>[\$Raw,\$UID,\$Key])
            :$DB->Do(SQL=>'INSERT INTO system_data (data_key,data_value,create_time,create_by,change_time,change_by) VALUES (?,?,current_timestamp,?,current_timestamp,?)',Bind=>[\$Key,\$Raw,\$UID,\$UID]);
        die "Cannot store announcement snapshot.\n" if !$OK;
        my $Article=$Kernel::OM->Get('Kernel::System::Ticket::Article')->BackendForChannel(ChannelName=>'Internal');
        die "Cannot record classification evidence.\n" if !$Article->ArticleCreate(TicketID=>$P{TicketID},UserID=>$UID,SenderType=>'system',IsVisibleForCustomer=>0,
            Subject=>'Change classification decision',Body=>"Actor: $V->{Actor}{Name}\nIPC override: ".($V->{Actor}{IPC}?'yes':'no')."\nAssessment override: ".($V->{Actor}{IPC} && $P{AssessmentOverride}?'yes':'no')."\nChange type: $V->{ChangeType} -> $P{ChangeType}\nChange classification: $V->{ChangeClassification} -> $P{ChangeClassification}\nReason: $P{Reason}\nPortal-wide announcement prepared: ".($P{ChangeClassification} eq 'Major'?'yes':'no'),
            ContentType=>'text/plain; charset=utf-8',HistoryType=>'AddNote',HistoryComment=>'Change classification decision');
        die "Cannot commit classification.\n" if !$DB->{dbh}->commit();$Began=0;1;
    } or $Error=$@ || 'Cannot save change classification.';
    $DB->Rollback() if $Began;
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Lock]);$DB->FetchrowArray();die $Error if $Error;return 1;
}
sub _approved {
    my ($S,$T)=@_;my $Approved=$S->_config('ApprovalStates');my $Withdraw=$S->_config('WithdrawalStates');
    return if ref $Approved ne 'ARRAY' || !@$Approved || ref $Withdraw ne 'ARRAY';
    return if grep {ref $_ || !defined $_ || !length $_} (@$Approved,@$Withdraw);
    my %Yes=map {$_=>1} @$Approved;my %No=map {$_=>1} @$Withdraw;
    return if grep {$Yes{$_}} @$Withdraw;
    # Approval/publication decisions must not rely on an externally cached ticket.
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Prepare(SQL=>'SELECT ty.name,s.name,st.name FROM ticket t JOIN ticket_type ty ON ty.id=t.type_id JOIN ticket_state s ON s.id=t.ticket_state_id JOIN ticket_state_type st ON st.id=s.type_id WHERE t.id=?',Bind=>[\$T->{TicketID}],Limit=>1);
    my @Current=$DB->FetchrowArray();return if @Current!=3 || $Current[0] ne 'Change' || $No{$Current[1]} || $Current[2]=~/\A(?:removed|merged)\z/;
    return 1 if $Yes{$Current[1]};
    my %States=$Kernel::OM->Get('Kernel::System::State')->StateList(Valid=>0,UserID=>1);my %IDs=reverse %States;
    my @Gate=grep {defined $_} map {$IDs{$_}} (@$Approved,@$Withdraw);return if !@Gate;
    return if !$DB->Prepare(SQL=>'SELECT h.state_id FROM ticket_history h JOIN ticket_history_type ht ON ht.id=h.history_type_id WHERE h.ticket_id=? AND ht.name IN (\'StateUpdate\',\'NewTicket\') AND h.state_id IN ('.join(',',map {'?'} @Gate).') ORDER BY h.id DESC',Bind=>[\$T->{TicketID},map {\$_} @Gate],Limit=>1);
    my @R=$DB->FetchrowArray();return @R && $Yes{$States{$R[0]} || ''}?1:0;
}
sub _public {
    my ($S,$ID)=@_;my $T=eval {$S->_ticket($ID)};return if !$T || _one($T->{DynamicField_ChangeClassification}) ne 'Major' || !$S->_approved($T);
    my $R=$S->_record($ID);return if !$R || ($R->{Public}{ChangeClassification} || '') ne 'Major';
    return if (_one($T->{DynamicField_ChangeType}) || 'Normal') ne ($R->{Public}{ChangeType} || '');
    my $C=$S->_context($T);return if sha256_hex(_json()->encode($C)) ne ($R->{SourceDigest} || '');
    # Only the reviewed public projection is returned; never articles or native ticket data.
    return {map {$_=>$R->{Public}{$_}} qw(TicketID TicketNumber Title Service Requester Assets Environment Application BlueBook Template Phases Start Finish ChangeType ChangeClassification Description Summary)};
}
sub PublicList {
    my ($S,%P)=@_;return [] if !$S->_activeCustomer($P{CustomerUserID});
    my @IDs=$Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(Result=>'ARRAY',Types=>['Change'],'DynamicField_ChangeClassification'=>{Equals=>'Major'},UserID=>1,Permission=>'ro',ArchiveFlags=>['y','n'],SortBy=>'Changed',OrderBy=>'Down',Limit=>10001);
    die "Announcement scope exceeds limit.\n" if @IDs>10000;my @R;for my $ID (@IDs) {my $R=$S->_public($ID);push @R,$R if $R}return \@R;
}
sub _activeCustomer {my ($S,$Login)=@_;return if !defined $Login || ref $Login || !length $Login;my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$Login);return ($U{ValidID} || 0)==1}
sub PublicView {my ($S,%P)=@_;return if !$S->_activeCustomer($P{CustomerUserID});return $S->_public($P{TicketID})}
1;
