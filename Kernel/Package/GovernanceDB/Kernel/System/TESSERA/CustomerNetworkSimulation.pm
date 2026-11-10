package Kernel::System::TESSERA::CustomerNetworkSimulation;
use strict;
use warnings;
use JSON::PP ();
use Storable qw(dclone);
use Digest::SHA qw(sha256_hex);
use Socket qw(AF_INET AF_INET6 inet_pton inet_ntop);
use POSIX qw(strftime);
use Kernel::System::TESSERA::NavisPlan;
our @ObjectDependencies=qw(Kernel::Config Kernel::System::CustomerUser Kernel::System::GovernanceObject Kernel::System::ITSMConfigItem Kernel::System::ITSMConfigItem::CustomerEntitlement Kernel::System::SystemData Kernel::System::DB Kernel::System::GenericInterface::Webservice Kernel::GenericInterface::Requester);
sub new {my ($T,%P)=@_;bless \%P,$T}
sub _config {my ($S,$Name)=@_;return $Kernel::OM->Get('Kernel::Config')->Get('TESSERA::CustomerNetworkSimulation::'.$Name)}
sub _panel {return $Kernel::OM->Get('Kernel::Config')->Get('CustomerPanelUserID') || 1}
sub AccessCheck {
    my ($S,%P)=@_;return if !defined $P{CustomerUserID} || ref $P{CustomerUserID} || !length $P{CustomerUserID};
    my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$P{CustomerUserID});
    return if ($U{ValidID} || 0)!=1;
    return $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->CustomerHasCMDBReadRole(CustomerUserID=>$P{CustomerUserID});
}
sub _simulation {
    my ($S,$Login)=@_;my $Allowed=$S->_config('AllowedCustomerUsers');
    return $S->_config('Enabled') && ref $Allowed eq 'ARRAY' && grep {defined $_ && !ref $_ && $_ eq $Login} @$Allowed;
}
sub _refs {
    my ($S,$Value,$Class)=@_;
    return $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->_ReferenceObjects(Value=>$Value,Class=>$Class);
}
sub _schema {
    my ($S,$CI)=@_;return if $S->{Schema}{$CI->{ClassID}};
    my $Def=$Kernel::OM->Get('Kernel::System::ITSMConfigItem')->DefinitionGet(ClassID=>$CI->{ClassID});
    my $F=$Def->{DynamicFieldRef};
    die "Installed CMDB model is incomplete.\n" if ref $F ne 'HASH' || ($F->{'ZTAM-Application'}{FieldType} || '') ne 'GovernanceObject'
        || ($F->{'ZTAM-Environment'}{FieldType} || '') ne 'GovernanceObject' || ($F->{'ZTAM-NetworkAdapter'}{FieldType} || '') ne 'Set';
    my @IP=grep {($_->{DF} || '') eq 'ZTAM-IpAddress' && ($_->{Definition}{FieldType} || '') eq 'Text'} @{$F->{'ZTAM-NetworkAdapter'}{Config}{Include} || []};
    die "Installed address model is incomplete.\n" if @IP!=1;
    $S->{Schema}{$CI->{ClassID}}=1;
}
sub _ips {
    my ($S,$CI)=@_;my $Rows=$CI->{'DynamicField_ZTAM-NetworkAdapter'};return [] if ref $Rows ne 'ARRAY';
    die "Address collection exceeds budget.\n" if @$Rows>128;my (%Seen,@IPs);
    for my $Row (@$Rows) {
        next if ref $Row ne 'HASH';my $V=$Row->{'ZTAM-IpAddress'};my @Values=ref $V eq 'ARRAY'?@$V:($V);
        for my $IP (@Values) {
            next if !defined $IP || ref $IP || length($IP)>64;
            $IP=~s/^\s+|\s+$//g;my $Family=index($IP,':')>=0?AF_INET6:AF_INET;
            my $Packed=eval {inet_pton($Family,$IP)};next if !defined $Packed;
            my $Canonical=inet_ntop($Family,$Packed);push @IPs,$Canonical if !$Seen{$Canonical}++;
        }
    }
    return \@IPs;
}
sub Model {
    my ($S,%P)=@_;die "Customer CMDB read access required.\n" if !$S->AccessCheck(%P);
    delete $S->{Schema};my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @EnvIDs=$GO->GovernanceObjectSearch(Classes=>['Environment'],ZTSMStatuss=>['Active'],Result=>'ARRAY',Limit=>129,UserID=>$S->_panel());
    die "Environment catalog exceeds budget.\n" if @EnvIDs>128;
    my (%Envs,@Prod);
    for my $ID (@EnvIDs) {my $E=$GO->GovernanceObjectGet(GovernanceObjectID=>$ID);next if !$E || ($E->{Class} || '') ne 'Environment' || ($E->{ZTSMStatus} || '') ne 'Active';
        $Envs{$ID}={ID=>"$ID",Name=>$E->{Name}};push @Prod,$ID if $E->{Name} eq 'PROD';}
    my $EnvironmentID=$P{EnvironmentID};
    die "Invalid environment selection.\n" if defined $EnvironmentID && (ref $EnvironmentID || (length($EnvironmentID) && $EnvironmentID!~/\A[1-9][0-9]*\z/));
    if (!defined $EnvironmentID || $EnvironmentID eq '') {$EnvironmentID=@Prod==1?$Prod[0]:''}
    die "Select an active environment.\n" if $EnvironmentID && (!defined $Envs{$EnvironmentID} || ref $EnvironmentID);
    my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem');my $Ent=$Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement');
    my @IDs=$CI->ConfigItemSearch(Classes=>['Workload','NetworkNode'],Result=>'ARRAY',Limit=>2001,UserID=>$S->_panel());
    die "Asset scope exceeds workspace budget.\n" if @IDs>2000;
    my (@Assets,%Apps);
    if ($EnvironmentID) {for my $ID (@IDs) {
        next if !$Ent->ConfigItemDetailAccessCheck(CustomerUserID=>$P{CustomerUserID},ConfigItemID=>$ID,LogNo=>1);
        my $O=$CI->ConfigItemGet(ConfigItemID=>$ID,DynamicFields=>1);next if !$O || ($O->{Class} || '')!~/\A(?:Workload|NetworkNode)\z/;
        $S->_schema($O);
        my @En=$S->_refs($O->{'DynamicField_ZTAM-Environment'},'Environment');next if @En!=1 || $En[0]{GovernanceObjectID} ne $EnvironmentID;
        my @App=$S->_refs($O->{'DynamicField_ZTAM-Application'},'Application');next if @App>1;
        my $AppID=@App?"$App[0]{GovernanceObjectID}":'';
        $Apps{$AppID}={ID=>$AppID,Name=>$App[0]{Name}} if @App;
        my $IPs=$S->_ips($O);my @Endpoints;my $Index=0;
        for my $IP (@$IPs) {push @Endpoints,{Key=>$ID.'@'.$Index++,Address=>$IP,AssetID=>"$ID",Name=>$O->{Name},Class=>$O->{Class},ApplicationID=>$AppID}}
        push @Assets,{ID=>"$ID",Name=>$O->{Name},Class=>$O->{Class},ApplicationID=>$AppID,Endpoints=>\@Endpoints};
    }}
    return {EnvironmentID=>"$EnvironmentID",Environments=>[sort {$a->{Name} cmp $b->{Name}} values %Envs],
        DefaultMissing=>!@Prod?1:@Prod>1?1:0,Applications=>[sort {$a->{Name} cmp $b->{Name}} values %Apps],Assets=>\@Assets,
        CanSimulate=>$S->_simulation($P{CustomerUserID})?1:0};
}
sub _endpoint {
    my ($S,$M,$Key,$App,$System)=@_;die "Choose an authorized endpoint.\n" if !defined $Key || ref $Key || $Key!~/\A[1-9][0-9]*\@[0-9]{1,3}\z/;
    my @Matches;
    for my $A (@{$M->{Assets}}) {for my $E (@{$A->{Endpoints}}) {push @Matches,$E if $E->{Key} eq $Key}}
    die "Choose an authorized endpoint.\n" if @Matches!=1;
    my $E=$Matches[0];die "Endpoint selection changed.\n" if ($App && $E->{ApplicationID} ne $App) || ($System && $E->{AssetID} ne $System);
    my @Duplicate=map {@{$_->{Endpoints}}} @{$M->{Assets}};
    die "Address is ambiguous in this environment.\n" if (grep {$_->{Address} eq $E->{Address}} @Duplicate)>1;
    return $E;
}
sub _binding {
    my ($S,$Env)=@_;my $Raw=$S->_config('Bindings') || '{}';my $All=eval {JSON::PP->new->decode($Raw)};
    my $B=ref $All eq 'HASH'?$All->{$Env}:undef;
    die "Simulation environment is not configured.\n" if ref $B ne 'HASH' || ($B->{WebserviceID} || '')!~/\A[1-9][0-9]*\z/
        || !Kernel::System::TESSERA::NavisPlan::_uuid($B->{BuildID}) || !Kernel::System::TESSERA::NavisPlan::_text($B->{Namespace});
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$B->{WebserviceID});
    die "Simulation connection unavailable.\n" if !$WS || ($WS->{ValidID} || 0)!=1 || ($WS->{Config}{Requester}{Transport}{Type} || '') ne 'HTTP::TESSERAIntegration'
        || ($WS->{Config}{Requester}{Transport}{Config}{Preset} || '') ne 'Navis';
    return {%$B,ConnectionDigest=>Kernel::System::TESSERA::NavisPlan->new()->Digest($WS->{Config})};
}
sub _key {my ($S,$ID)=@_;die "Invalid analysis reference.\n" if ($ID || '')!~/\A[a-f0-9]{40}\z/;return 'TESSERA::CustomerNetworkSimulation::'.$ID}
sub _store {
    my ($S,$D,$New)=@_;my $Raw=JSON::PP->new->canonical->utf8->encode($D);die "Evidence exceeds budget.\n" if length($Raw)>12582912;
    my $Method=$New?'SystemDataAdd':'SystemDataUpdate';
    die "Evidence storage failed.\n" if !$Kernel::OM->Get('Kernel::System::SystemData')->$Method(Key=>$S->_key($D->{AnalysisID}),Value=>$Raw,UserID=>$S->_panel());
}
sub _read {my ($S,$ID)=@_;my $Raw=$Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGet(Key=>$S->_key($ID));return if !defined $Raw;return JSON::PP->new->utf8->decode($Raw)}
sub _call {
    my ($S,$B,$Op,$Data)=@_;my %Args=(WebserviceID=>$B->{WebserviceID},Invoker=>$Op,Data=>$Data);
    my $R=$S->{Requester}?$S->{Requester}->(%Args):$Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(%Args);
    die "Simulation service failed or outcome is uncertain.\n" if ref $R ne 'HASH' || !$R->{Success} || ref $R->{Data} ne 'HASH';
    return $R->{Data};
}
sub Analyze {
    my ($S,%P)=@_;die "Simulation access required.\n" if !$S->AccessCheck(%P) || !$S->_simulation($P{CustomerUserID});
    die "Invalid submission.\n" if ($P{SubmissionToken} || '')!~/\A[A-Za-z0-9]{40}\z/;
    my $M=$S->Model(%P);my $Source=$S->_endpoint($M,@P{qw(SourceEndpoint SourceApplication SourceSystem)});
    my $Destination=$S->_endpoint($M,@P{qw(DestinationEndpoint DestinationApplication DestinationSystem)});
    my $B=$S->_binding($M->{EnvironmentID});my $ID=substr(sha256_hex($P{CustomerUserID}.':'.$P{SubmissionToken}),0,40);
    my $Flow={source=>$Source->{Address},destination=>$Destination->{Address},protocol=>$P{Protocol},action=>'allow'};
    $Flow->{destination_port}=$P{DestinationPort} if defined $P{DestinationPort} && length $P{DestinationPort};
    die "TCP/UDP destination port required.\n" if ($P{Protocol} || '')=~/\A(?:tcp|udp)\z/ && !defined $Flow->{destination_port};
    my $Request=Kernel::System::TESSERA::NavisPlan->new()->Request(Flow=>$Flow,BuildID=>$B->{BuildID},CallerID=>'tessera-'.$ID);
    my $D={AnalysisID=>$ID,CustomerUserID=>$P{CustomerUserID},EnvironmentID=>$M->{EnvironmentID},Source=>dclone($Source),Destination=>dclone($Destination),
        Binding=>$B,Request=>$Request,Status=>'CREATED',CreatedAt=>time()};
    $D->{SubmissionDigest}=Kernel::System::TESSERA::NavisPlan->new()->Digest([$M->{EnvironmentID},$Source->{AssetID},$Destination->{AssetID},$Request,$B]);
    my $DB=$Kernel::OM->Get('Kernel::System::DB');my $Lock='tessera_customer_sim_'.substr(sha256_hex($P{CustomerUserID}),0,40);
    die "Another simulation is running.\n" if !$DB->Prepare(SQL=>'SELECT GET_LOCK(?,0)',Bind=>[\$Lock]);my @L=$DB->FetchrowArray();die "Another simulation is running.\n" if !$L[0];
    my ($Result,$Error);eval {
        my $Existing=$S->_read($ID);
        if ($Existing) {
            die "Submission content changed.\n" if $Existing->{CustomerUserID} ne $P{CustomerUserID}
                || ($Existing->{SubmissionDigest} || '') ne $D->{SubmissionDigest};
            $Result=$ID;
        } else {
            my $Store=$Kernel::OM->Get('Kernel::System::SystemData');my $RateKey='TESSERA::CustomerNetworkSimulation::Rate::'.sha256_hex($P{CustomerUserID});
            my $Last=$Store->SystemDataGet(Key=>$RateKey);
            die "Please wait before another simulation.\n" if defined $Last && $Last=~/\A[0-9]+\z/ && time()-$Last<30;
            my $Method=defined $Last?'SystemDataUpdate':'SystemDataAdd';die "Rate state unavailable.\n" if !$Store->$Method(Key=>$RateKey,Value=>time(),UserID=>$S->_panel());
            $S->_store($D,1);
            my $OK=eval {
                $D->{Graph}=$S->_call($B,'GraphGet',{BuildID=>$B->{BuildID}});
                Kernel::System::TESSERA::NavisPlan->new()->Graph($D->{Graph},$B->{BuildID});
                $D->{Status}='TRACE_INTENT';$S->_store($D);
                $D->{Trace}=$S->_call($B,'Trace',$Request);$D->{Status}='TRACE_SAVED';$S->_store($D);
                $D->{Recommendations}=$S->_call($B,'RecommendationsGet',{CallerSessionID=>$Request->{caller_session_id}});
                $D->{Status}='ANALYZED';$S->_store($D);1;
            };
            # Preserve TRACE_INTENT on uncertain POST: this ID can never replay it.
            $Result=$ID;
        }
        1;
    } or $Error=$@ || 'Simulation unavailable.';
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Lock]);$DB->FetchrowArray();die $Error if $Error;
    return $Result;
}
sub Result {
    my ($S,%P)=@_;die "Simulation access required.\n" if !$S->AccessCheck(%P) || !$S->_simulation($P{CustomerUserID});
    my $D=$S->_read($P{AnalysisID});die "Analysis unavailable.\n" if !$D || $D->{CustomerUserID} ne $P{CustomerUserID};
    my $M=$S->Model(CustomerUserID=>$P{CustomerUserID},EnvironmentID=>$D->{EnvironmentID});
    for my $K (qw(Source Destination)) {my $E=$S->_endpoint($M,$D->{$K}{Key});die "Endpoint scope changed.\n" if $E->{Address} ne $D->{$K}{Address}}
    my $B=$S->_binding($D->{EnvironmentID});
    die "Analysis connection changed.\n" if Kernel::System::TESSERA::NavisPlan->new()->Digest($B) ne Kernel::System::TESSERA::NavisPlan->new()->Digest($D->{Binding});
    return {Model=>$M,Result=>$S->_project($D,$M)};
}
sub Refresh {
    my ($S,%P)=@_;$S->Result(%P); # Recheck owner, endpoints, current scope and binding.
    my $ID=$P{AnalysisID};my $DB=$Kernel::OM->Get('Kernel::System::DB');my $Lock='tessera_customer_rec_'.$ID;
    die "Recommendation refresh is busy.\n" if !$DB->Prepare(SQL=>'SELECT GET_LOCK(?,0)',Bind=>[\$Lock]);my @L=$DB->FetchrowArray();die "Recommendation refresh is busy.\n" if !$L[0];
    my $Error;eval {
        my $D=$S->_read($ID);die "Saved trace required.\n" if !$D->{Trace};
        die "Wait before refreshing.\n" if $D->{RefreshedAt} && time()-$D->{RefreshedAt}<10;
        $D->{RefreshedAt}=time();$S->_store($D);
        $D->{Recommendations}=$S->_call($D->{Binding},'RecommendationsGet',{CallerSessionID=>$D->{Request}{caller_session_id}});
        $D->{Status}='ANALYZED';$S->_store($D);1;
    } or $Error=$@ || 'Recommendation refresh failed.';
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Lock]);$DB->FetchrowArray();die $Error if $Error;return $ID;
}
sub _project {
    my ($S,$D,$M)=@_;my $Out={AnalysisID=>$D->{AnalysisID},Status=>$D->{Status},CreatedAt=>$D->{CreatedAt},EnvironmentID=>$D->{EnvironmentID},
        Source=>$D->{Source},Destination=>$D->{Destination},Protocol=>$D->{Request}{protocol},DestinationPort=>$D->{Request}{destination_port},
        Nodes=>[],Edges=>[],Hops=>[],Recommendations=>[],Findings=>[],Verdict=>'unknown',Withheld=>0};
    $Out->{CreatedAtUTC}=strftime('%Y-%m-%dT%H:%M:%SZ',gmtime($D->{CreatedAt}));
    my %Labels=(CREATED=>'Analysis could not start',TRACE_INTENT=>'Outcome uncertain',TRACE_SAVED=>'Trace saved; recommendations unavailable',ANALYZED=>'Analysis saved');
    $Out->{StatusLabel}=$Labels{$D->{Status}} || 'Analysis unavailable';
    my (%Assets,%Nodes);
    for my $A (@{$M->{Assets}}) {$Assets{JSON::PP->new->canonical->encode([$D->{Binding}{Namespace},$A->{Class},$A->{ID}])}=$A}
    for my $E (@$D{qw(Source Destination)}) {$Nodes{$E->{AssetID}}={ID=>$E->{AssetID},Name=>$E->{Name},Class=>$E->{Class},Address=>$E->{Address}}}
    return {%$Out,Nodes=>[values %Nodes]} if !$D->{Trace};
    my $T=$D->{Trace};my $Q=$D->{Request};
    die "Analysis response mismatch.\n" if ($T->{code} || '') ne 'TRACE_RESULT_READY' || ($T->{caller_session_id} || '') ne $Q->{caller_session_id}
        || ($T->{graph_build_id} || '') ne $Q->{graph_build_id} || !Kernel::System::TESSERA::NavisPlan::_uuid($T->{trace_session_id})
        || ref $T->{results} ne 'ARRAY' || @{$T->{results}}!=1;
    my $F=$T->{results}[0];die "Analysis flow mismatch.\n" if grep {($F->{$_} // '') ne ($Q->{$_} // '')} qw(source destination protocol destination_port);
    my $Graph=Kernel::System::TESSERA::NavisPlan->new()->Graph($D->{Graph},$Q->{graph_build_id});
    my %Device=map {$_=>$Assets{$Graph->{$_} || ''}} keys %$Graph;
    # Coverage, alternative/reverse paths and endpoint candidates may reference
    # additional devices. They cannot be used to disclose an out-of-scope path.
    my $Visited=0;my $Scan;
    $Scan=sub {
        my ($Value,$Depth)=@_;die "Trace evidence exceeds budget.\n" if ++$Visited>50000 || $Depth>32;
        if (ref $Value eq 'ARRAY') {$Scan->($_,$Depth+1) for @$Value}
        elsif (ref $Value eq 'HASH') {for my $Key (keys %$Value) {
            if ($Key=~/(?:^|_)device_id\z/ && defined $Value->{$Key}) {
                $Out->{Withheld}=1 if ref $Value->{$Key} || !$Device{$Value->{$Key}};
            }
            $Scan->($Value->{$Key},$Depth+1);
        }}
    };
    my $Scanned=eval {$Scan->($F,0);1};undef $Scan;die "Trace evidence exceeds budget.\n" if !$Scanned;
    my $Hops=$F->{hops} || [];die "Trace path exceeds budget.\n" if ref $Hops ne 'ARRAY' || @$Hops>64;
    my @Path;
    for my $Hop (@$Hops) {my $A=ref $Hop eq 'HASH'?$Device{$Hop->{device_id} || ''}:undef;
        if (!$A) {$Out->{Withheld}=1;last}push @Path,$A;}
    if (!$Out->{Withheld}) {
        my $Index=0;my $Previous;
        for my $A (@Path) {
            $Nodes{$A->{ID}}={ID=>$A->{ID},Name=>$A->{Name},Class=>$A->{Class}} if !$Nodes{$A->{ID}};
            push @{$Out->{Hops}},{Number=>++$Index,ID=>$A->{ID},Name=>$A->{Name},Class=>$A->{Class}};
            push @{$Out->{Edges}},{Source=>$Previous,Target=>$A->{ID},Kind=>'candidate'} if defined $Previous && $Previous ne $A->{ID};$Previous=$A->{ID};
        }
        my $Status=$F->{connection_verdict}{status} || 'unknown';$Out->{Verdict}=$Status if @Path && $Status=~/\A(?:allowed|blocked|unknown)\z/;
        die "Findings exceed budget.\n" if ref($F->{findings} || []) ne 'ARRAY' || @{$F->{findings} || []}>500;
        for my $Finding (@{$F->{findings} || []}) {
            next if ref $Finding ne 'HASH' || !$Device{$Finding->{device_id} || ''} || ($Finding->{code} || '')!~/\A[A-Z][A-Z0-9_]{0,79}\z/;
            push @{$Out->{Findings}},{Code=>$Finding->{code},Name=>$Device{$Finding->{device_id}}{Name}};
        }
        my $R=$D->{Recommendations};
        if ($R) {
            die "Recommendation ownership mismatch.\n" if ($R->{caller_session_id} || '') ne $Q->{caller_session_id} || ($R->{trace_session_id} || '') ne $T->{trace_session_id};
            my $Rows=$R->{recommendations} || [];die "Recommendations exceed budget.\n" if ref $Rows ne 'ARRAY' || @$Rows>256;
            $Out->{RecommendationStatus}=($R->{code} || '')=~/\A(?:RECOMMENDATION_PENDING|RECOMMENDATIONS_AVAILABLE|RECOMMENDATIONS_UNAVAILABLE)\z/?$R->{code}:'UNKNOWN';
            for my $Row (@$Rows) {my $Draft=$Row->{result};next if ref $Draft ne 'HASH' || !$Device{$Draft->{device_id} || ''} || ($Row->{status} || '') ne 'ready';
                next if grep {($Draft->{$_} // '') ne ($Q->{$_} // '')} qw(source destination protocol destination_port);
                next if ($Draft->{action} || '') ne 'allow';
                push @{$Out->{Recommendations}},{ID=>$Device{$Draft->{device_id}}{ID},Name=>$Device{$Draft->{device_id}}{Name},Action=>'allow',Status=>($Draft->{status} || '') eq 'draft'?'draft':'incomplete'};
            }
        }
    }
    $Out->{Nodes}=[sort {$a->{ID} cmp $b->{ID}} values %Nodes];
    return $Out;
}
1;
