package Kernel::System::TESSERA::NavisControl;
use strict;
use warnings;
use JSON::PP ();
use Storable qw(dclone);
use Time::Local qw(timegm);
use Kernel::System::TESSERA::NavisPlan;
our @ObjectDependencies=qw(Kernel::System::SystemData Kernel::System::DB Kernel::GenericInterface::Requester Kernel::System::TESSERA::AsyncExecution Kernel::System::GenericInterface::Webservice);
sub new {my ($T,%P)=@_;bless \%P,$T}
sub _key {die "Invalid analysis reference.\n" if ($_[1] || '')!~/\A[a-f0-9]{40}\z/;return 'TESSERA::Navis::Analysis::'.$_[1]}
sub _read {
    my ($S,$ID)=@_;my $Raw=$Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGet(Key=>$S->_key($ID));
    die "Analysis unavailable.\n" if !defined $Raw;return JSON::PP->new->utf8->decode($Raw);
}
sub _save {
    my ($S,$D,$New)=@_;my $Store=$Kernel::OM->Get('Kernel::System::SystemData');my $Method=$New?'SystemDataAdd':'SystemDataUpdate';
    my $Raw=JSON::PP->new->canonical->utf8->encode($D);die "Analysis evidence exceeds budget.\n" if length($Raw)>12582912;
    die "Analysis evidence save failed.\n" if !$Store->$Method(Key=>$S->_key($D->{AnalysisID}),Value=>$Raw,UserID=>$D->{ActorID});
}
sub _lock {
    my ($S,$ID,$Code)=@_;$S->_key($ID);my $DB=$Kernel::OM->Get('Kernel::System::DB');my $Name='tessera_navis_'.$ID;
    die "Analysis busy.\n" if !$DB->Prepare(SQL=>'SELECT GET_LOCK(?,5)',Bind=>[\$Name]);
    my @L=$DB->FetchrowArray();die "Analysis busy.\n" if !$L[0];my ($R,$Error);
    eval {$R=$Code->();1} or $Error=$@ || 'Analysis operation failed.';
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Name]);$DB->FetchrowArray();die $Error if $Error;return $R;
}
# Context is supplied only by an independently authorized trusted workflow binding,
# never copied from portal inputs or stored YAML. Same boundary as NetworkContext.
sub _context {
    my ($S,$C,$Actor)=@_;die "Authorized Navis context required.\n" if ref $C ne 'HASH' || ($Actor || '')!~/\A[1-9][0-9]*\z/
        || ($C->{ActorID} || 0)!=$Actor || ($C->{NavisWebserviceID} || '')!~/\A[1-9][0-9]*\z/
        || ($C->{TargetID} || '')!~/\A[1-9][0-9]*\z/ || ($C->{TargetType} || '')!~/\A[A-Za-z][A-Za-z0-9_]{0,49}\z/;
    die "Authorized CMDB context required.\n" if ref $C->{Snapshot} ne 'ARRAY' || @{$C->{Snapshot}}>1000
        || !Kernel::System::TESSERA::NavisPlan::_text($C->{Namespace}) || !Kernel::System::TESSERA::NavisPlan::_uuid($C->{BuildID});
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$C->{NavisWebserviceID});
    die "Enabled Navis connection required.\n" if !$WS || ($WS->{ValidID} || 0)!=1
        || ($WS->{Config}{Requester}{Transport}{Type} || '') ne 'HTTP::TESSERAIntegration'
        || ($WS->{Config}{Requester}{Transport}{Config}{Preset} || '') ne 'Navis';
    return $C;
}
sub _bound {
    my ($S,$D,$C,$Actor)=@_;$S->_context($C,$Actor);
    die "Analysis scope mismatch.\n" if grep {($D->{$_} // '') ne ($C->{$_} // '')} qw(ActorID NavisWebserviceID TargetType TargetID);
    my $Planner=Kernel::System::TESSERA::NavisPlan->new();
    die "Authorized CMDB context changed.\n" if $D->{Namespace} ne $C->{Namespace} || $Planner->Digest($D->{Snapshot}) ne $Planner->Digest($C->{Snapshot});
    $S->_connection($D);
}
sub _connection {
    my ($S,$D)=@_;my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$D->{NavisWebserviceID});
    die "Analysis connection changed or disabled.\n" if !$WS || ($WS->{ValidID} || 0)!=1
        || Kernel::System::TESSERA::NavisPlan->new()->Digest($WS->{Config}) ne $D->{ConnectionDigest};
}
sub _call {
    my ($S,$ID,$Op,$Data)=@_;my %P=(WebserviceID=>$ID,Invoker=>$Op,Data=>$Data);
    my $R=$S->{Requester}?$S->{Requester}->(%P):$Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(%P);
    die "Navis request failed or outcome is uncertain.\n" if ref $R ne 'HASH' || !$R->{Success} || ref $R->{Data} ne 'HASH';
    return $R->{Data};
}
sub Analyze {
    my ($S,%P)=@_;my $C=$S->_context($P{Context},$P{ActorID});my $Planner=Kernel::System::TESSERA::NavisPlan->new();
    require Crypt::PRNG;my $ID=unpack('H*',Crypt::PRNG::random_bytes(20));
    my $Q=$Planner->Request(Flow=>$P{Data},BuildID=>$C->{BuildID},CallerID=>'tessera-'.$ID);
    my $D={AnalysisID=>$ID,ActorID=>$P{ActorID},map {$_=>$C->{$_}} qw(NavisWebserviceID TargetType TargetID)};
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$C->{NavisWebserviceID});
    $D->{ConnectionDigest}=$Planner->Digest($WS->{Config});
    @$D{qw(Request Snapshot Namespace Action Status)}=($Q,dclone($C->{Snapshot}),$C->{Namespace},$P{Data}{action},'CREATED');
    $S->_save($D,1);
    my $OK=eval {
        $D->{Graph}=$S->_call($C->{NavisWebserviceID},'GraphGet',{BuildID=>$C->{BuildID}});$Planner->Graph($D->{Graph},$C->{BuildID});
        $D->{Status}='TRACE_INTENT';$S->_save($D);
        $D->{Trace}=$S->_call($C->{NavisWebserviceID},'Trace',$Q);
        $D->{Status}='TRACE_SAVED';$S->_save($D);
        $S->_recommend($D);1;
    };
    return {Success=>$OK?1:0,Data=>{AnalysisID=>$ID,Status=>$OK?$D->{Status}:'FAILED_OR_UNCERTAIN'}};
}
sub _recommend {
    my ($S,$D)=@_;$D->{Recommendations}=$S->_call($D->{NavisWebserviceID},'RecommendationsGet',{CallerSessionID=>$D->{Request}{caller_session_id}});
    $D->{Plan}=Kernel::System::TESSERA::NavisPlan->new()->Prepare(Request=>$D->{Request},Trace=>$D->{Trace},Graph=>$D->{Graph},Recommendations=>$D->{Recommendations},Snapshot=>$D->{Snapshot},Namespace=>$D->{Namespace},Action=>$D->{Action});
    $D->{PlanDigest}=Kernel::System::TESSERA::NavisPlan->new()->Digest($D->{Plan});$D->{Status}=$D->{Plan}{Status};$S->_save($D);
}
sub Get {
    my ($S,%P)=@_;my $D=$S->_read($P{AnalysisID});$S->_bound($D,$P{Context},$P{ActorID});
    return {Success=>1,Data=>dclone($D)};
}
sub Recommendations {
    my ($S,%P)=@_;return $S->_lock($P{AnalysisID},sub {
        my $D=$S->_read($P{AnalysisID});$S->_bound($D,$P{Context},$P{ActorID});
        die "Saved trace required; never replay an uncertain POST.\n" if !$D->{Trace} || $D->{Status}!~/\A(?:TRACE_SAVED|RECOMMENDATION_PENDING|RECOMMENDATIONS_UNAVAILABLE)\z/;
        $S->_recommend($D);return {Success=>1,Data=>{AnalysisID=>$D->{AnalysisID},Status=>$D->{Status},PlanDigest=>$D->{PlanDigest}}};
    });
}
sub _launch {
    my ($S,$D,$Phase,$Binding)=@_;
    die "Reviewed AWX binding required.\n" if ref $Binding ne 'HASH';
    for my $K (qw(AWXWebserviceID TemplateID InventoryID)) {die "Reviewed AWX binding required.\n" if ($Binding->{$K} || '')!~/\A[1-9][0-9]*\z/}
    die "Reviewed execution limit required.\n" if !defined $Binding->{Limit} || ref $Binding->{Limit} || $Binding->{Limit}!~/\A[A-Za-z0-9_.:,\-]{1,1000}\z/;
    $D->{Status}=$Phase.'_INTENT';$S->_save($D);
    my $Async=$S->{Async} || $Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution');
    my $R=$Async->Start(ActorID=>$D->{ActorID},TargetType=>$D->{TargetType},TargetID=>$D->{TargetID},HandlerKey=>'NavisControl',
        Continuation=>{AnalysisID=>$D->{AnalysisID},Phase=>$Phase},WebserviceID=>$Binding->{AWXWebserviceID},Invoker=>'JobLaunchCallback',
        Payload=>{TemplateID=>$Binding->{TemplateID},inventory=>$Binding->{InventoryID},limit=>$Binding->{Limit},extra_vars=>{
            tessera_work=>{AnalysisID=>$D->{AnalysisID},PlanDigest=>$D->{PlanDigest},Phase=>$Phase,Plans=>$D->{Plan}{Plans}}}});
    die "AWX dispatch uncertain; reconcile before retry.\n" if !$R->{Success};
    $D->{$Phase.'ExecutionUID'}=$R->{ExecutionUID};$D->{Status}=$Phase.'_WAITING';$S->_save($D);return $R;
}
sub Execute {
    my ($S,%P)=@_;return $S->_lock($P{AnalysisID},sub {
        my $D=$S->_read($P{AnalysisID});my $C=$P{Context};$S->_bound($D,$C,$P{ActorID});
        die "Independent authorization of the exact plan required.\n" if $D->{Status} ne 'REVIEW_REQUIRED' || !@{$D->{Plan}{Plans}}
            || @{$D->{Plan}{Issues}} || ($C->{ApprovedPlanDigest} || '') ne $D->{PlanDigest};
        # Only reviewed backend bindings choose apply/readback jobs. No URLs,
        # tokens, trace/graph or recommendation logic are sent to AWX.
        die "Readback binding required.\n" if ref $C->{Readback} ne 'HASH';
        for my $Plan (@{$D->{Plan}{Plans}}) {
            my %Fields=(panos=>[qw(vsys source_zone destination_zone)],aci=>[qw(tenant source_epg destination_epg contract)],nsx=>[qw(domain source_group destination_group applied_to policy)]);
            die "Complete vendor context required.\n" if grep {!Kernel::System::TESSERA::NavisPlan::_text($Plan->{Context}{$_})} @{$Fields{$Plan->{Platform}}};
            if ($Plan->{Platform} eq 'panos') {for my $Zone (qw(source_zone destination_zone)) {
                die "Resolved matching firewall zones required.\n" if ($Plan->{Draft}{$Zone.'_status'} || '') ne 'resolved' || ($Plan->{Draft}{$Zone} || '') ne $Plan->{Context}{$Zone};
            }}
            die "Explicit destination port required.\n" if $Plan->{Draft}{protocol}=~/\A(?:tcp|udp)\z/ && !defined $Plan->{Draft}{destination_port};
        }
        $D->{ReadbackBinding}=dclone($C->{Readback});
        return $S->_launch($D,'APPLY',$C->{Apply});
    });
}
# Called by the existing authenticated AsyncExecution dispatcher only. Re-read its
# RUNNING ledger; a caller-supplied exit code is never sufficient completion proof.
sub Completed {
    my ($S,%P)=@_;my $Async=$Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution');
    my $Row=$Async->_Get($P{ExecutionUID});
    die "Authenticated completion required.\n" if !$Row || $Row->{State} ne 'RUNNING' || $Row->{HandlerKey} ne 'NavisControl';
    my $C=JSON::PP->new->decode($Row->{Continuation});my $ID=$C->{AnalysisID};
    return $S->_lock($ID,sub {
        my $D=$S->_read($ID);my $Phase=$C->{Phase};
        die "Completion scope mismatch.\n" if ($Phase || '')!~/\A(?:APPLY|READBACK)\z/ || ($D->{$Phase.'ExecutionUID'} || '') ne $P{ExecutionUID}
            || $Row->{ActorID}!=$D->{ActorID} || $Row->{TargetID}!=$D->{TargetID} || $Row->{TargetType} ne $D->{TargetType};
        return 1 if $D->{Status} ne $Phase.'_WAITING';
        $S->_connection($D);
        if ($Row->{ExitCode}!=0) {$D->{Status}=$Phase.'_FAILED';$S->_save($D);return 1}
        my $Evidence=JSON::PP->new->decode($Row->{Response});
        if ($Phase eq 'APPLY') {
            die "Real apply evidence required.\n" if ref $Evidence ne 'HASH' || ($Evidence->{AnalysisID} || '') ne $D->{AnalysisID}
                || ($Evidence->{PlanDigest} || '') ne $D->{PlanDigest} || !JSON::PP::is_bool($Evidence->{Simulation}) || $Evidence->{Simulation}
                || ($Evidence->{Status} || '') ne 'APPLIED';
            $D->{ApplyEvidence}=dclone($Evidence);$D->{AppliedAt}=time();$S->_launch($D,'READBACK',$D->{ReadbackBinding});return 1;
        }
        $S->_publish($D,$Evidence);return 1;
    });
}
sub _publish {
    my ($S,$D,$Evidence)=@_;
    $S->_connection($D);
    # A collector supplies observed normalized envelopes, never the planned rule
    # echoed back. Preserve partial/unknown evidence; no claim of graph readiness.
    die "Observed firewall readback required.\n" if ref $Evidence ne 'HASH' || ($Evidence->{AnalysisID} || '') ne $D->{AnalysisID}
        || ($Evidence->{PlanDigest} || '') ne $D->{PlanDigest} || ref $Evidence->{Envelopes} ne 'ARRAY' || !@{$Evidence->{Envelopes}} || @{$Evidence->{Envelopes}}>256;
    my %Targets=map {JSON::PP->new->canonical->encode([@{$_->{Target}}{qw(Namespace Class ConfigItemID)}])=>1} @{$D->{Plan}{Plans}};
    my %Observed;my %Complete;
    for my $E (@{$Evidence->{Envelopes}}) {
        die "Readback source is outside authorized targets.\n" if ref $E ne 'HASH' || ref $E->{source} ne 'HASH'
            || !$Targets{JSON::PP->new->canonical->encode([@{$E->{source}}{qw(namespace object_class external_device_id)}])}
            || ($E->{data_type} || '') ne 'policy' || ($E->{completeness} || '')!~/\A(?:complete|partial|unknown)\z/
            || ($E->{collected_at} || '')!~/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)\z/
            || ref $E->{payload}{entries} ne 'ARRAY' || @{$E->{payload}{entries}}>10000;
        die "Unexpected readback metadata.\n" if grep {!/\A(?:source|adapter|data_type|collected_at|completeness|payload)\z/} keys %$E;
        die "Normalized adapter required.\n" if ref $E->{adapter} ne 'HASH' || ($E->{adapter}{name} || '') ne 'navis'
            || ($E->{adapter}{input_format} || '') ne 'normalized-json' || ($E->{adapter}{format_version} || '') ne '1';
        my ($Year,$Month,$Day,$Hour,$Minute,$Second,$Zone,$Sign,$ZH,$ZM)=$E->{collected_at}=~/\A(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d+)?(Z|([+-])(\d\d):(\d\d))\z/;
        my $Stamp=eval {timegm($Second,$Minute,$Hour,$Day,$Month-1,$Year)};
        die "Invalid readback collection time.\n" if !defined $Stamp || ($Zone ne 'Z' && ($ZH>23 || $ZM>59));
        $Stamp-=($Sign eq '+'?1:-1)*($ZH*3600+$ZM*60) if $Zone ne 'Z';
        die "Readback predates apply or is in the future.\n" if $Stamp<($D->{AppliedAt} || 0)-60 || $Stamp>time()+60;
        my $Key=JSON::PP->new->canonical->encode([@{$E->{source}}{qw(namespace object_class external_device_id)}]);
        die "Duplicate policy snapshots for one target.\n" if $Observed{$Key};
        $Observed{$Key}=$E;$Complete{$Key}=($E->{completeness} eq 'complete');
    }
    # Evaluate observed rules in TESSERA. An AWX success/Verified flag or echoed
    # planned draft cannot replace this comparison. Partial coverage stays unknown.
    my @Verification;
    for my $Plan (@{$D->{Plan}{Plans}}) {
        my $Key=JSON::PP->new->canonical->encode([@{$Plan->{Target}}{qw(Namespace Class ConfigItemID)}]);
        my $E=$Observed{$Key};my $Found=0;my $Draft=$Plan->{Draft};
        for my $Rule (@{$E ? $E->{payload}{entries}:[]}) {
            next if ref $Rule ne 'HASH' || !JSON::PP::is_bool($Rule->{enabled}) || !$Rule->{enabled}
                || ($Rule->{action} || '') ne $Draft->{action} || ref $Rule->{selectors} ne 'ARRAY';
            next if !$Plan->{Context}{normalized_enforcement_point} || !$Plan->{Context}{normalized_rule_set}
                || ($Rule->{enforcement_point} || '') ne $Plan->{Context}{normalized_enforcement_point}
                || ($Rule->{rule_set} || '') ne $Plan->{Context}{normalized_rule_set} || @{$Rule->{selectors}}!=3;
            my %Match;
            for my $Selector (@{$Rule->{selectors}}) {
                next if ref $Selector ne 'HASH' || !JSON::PP::is_bool($Selector->{negated}) || $Selector->{negated};
                my ($Role,$Kind,$Value)=@$Selector{qw(role kind value)};
                if (($Kind || '') eq 'address' && ($Role || '')=~/\A(?:source|destination)\z/ && !ref $Value) {
                    $Match{$Role}=1 if defined $Value && $Value eq $Draft->{$Role};
                }
                if (($Kind || '') eq 'service' && ($Role || '') eq 'service' && ref $Value eq 'HASH') {
                    $Match{service}=1 if ($Value->{protocol} || '') eq $Draft->{protocol}
                        && (!defined $Draft->{destination_port} || (defined $Value->{destination_port_start} && defined $Value->{destination_port_end}
                            && $Value->{destination_port_start}==$Draft->{destination_port} && $Value->{destination_port_end}==$Draft->{destination_port}));
                }
            }
            $Found=1 if $Match{source} && $Match{destination} && $Match{service};
        }
        push @Verification,{PlanID=>$Plan->{PlanID},Status=>$Complete{$Key} && $Found?'OBSERVED_MATCH':'UNKNOWN',ConnectivityVerified=>JSON::PP::false};
    }
    $D->{ReadbackVerification}=\@Verification;
    $D->{ObservedReadback}=dclone($Evidence);$D->{Ingestions}=[];$D->{Status}='INGEST_INTENT';$S->_save($D);
    for my $E (@{$Evidence->{Envelopes}}) {
        my $Receipt=$S->_call($D->{NavisWebserviceID},'Ingest',$E);
        die "Invalid staging receipt.\n" if !Kernel::System::TESSERA::NavisPlan::_uuid($Receipt->{ingestion_id}) || ($Receipt->{status} || '') ne 'pending_identity';
        push @{$D->{Ingestions}},{Receipt=>$Receipt,EnvelopeDigest=>Kernel::System::TESSERA::NavisPlan->new()->Digest($E)};$S->_save($D);
    }
    $D->{Status}='NAVIS_STAGED_OPERATOR_PROCESSING_REQUIRED';$S->_save($D);
}
1;
