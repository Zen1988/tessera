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
    delete $S->{Schema};
    my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem');my $Ent=$Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement');
    my @IDs=$CI->ConfigItemSearch(Classes=>['Workload','NetworkNode'],Result=>'ARRAY',Limit=>2001,UserID=>$S->_panel());
    die "Asset scope exceeds workspace budget.\n" if @IDs>2000;
    my (@Assets,%Apps);
    for my $ID (@IDs) {
        next if !$Ent->ConfigItemDetailAccessCheck(CustomerUserID=>$P{CustomerUserID},ConfigItemID=>$ID,LogNo=>1);
        my $O=$CI->ConfigItemGet(ConfigItemID=>$ID,DynamicFields=>1);next if !$O || ($O->{Class} || '')!~/\A(?:Workload|NetworkNode)\z/;
        $S->_schema($O);
        my @App=$S->_refs($O->{'DynamicField_ZTAM-Application'},'Application');next if @App>1;
        my $AppID=@App?"$App[0]{GovernanceObjectID}":'';
        $Apps{$AppID}={ID=>$AppID,Name=>$App[0]{Name}} if @App;
        my $IPs=$S->_ips($O);my @Endpoints;my $Index=0;
        for my $IP (@$IPs) {push @Endpoints,{Key=>$ID.'@'.$Index++,Address=>$IP,AssetID=>"$ID",Name=>$O->{Name},Class=>$O->{Class},ApplicationID=>$AppID}}
        push @Assets,{ID=>"$ID",Name=>$O->{Name},Class=>$O->{Class},ApplicationID=>$AppID,Endpoints=>\@Endpoints};
    }
    for my $App (values %Apps) {
        my $Object=eval {$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$App->{ID},DynamicFields=>1)};
        my $Name=ref $Object eq 'HASH'?$Object->{DynamicField_Navis}:undef;$Name=$Name->[0] if ref $Name eq 'ARRAY' && @$Name==1;
        $App->{HasTopology}=ref $Object eq 'HASH' && ($Object->{Class} || '') eq 'Application' && ($Object->{ZTSMStatus} || '') eq 'Active'
            && Kernel::System::TESSERA::NavisPlan::_text($Name) && $Name!~/^\s|\s$/?1:0;
    }
    return {Applications=>[sort {$a->{Name} cmp $b->{Name}} values %Apps],Assets=>\@Assets,
        CanSimulate=>$S->_simulation($P{CustomerUserID})?1:0};
}
sub _endpoint {
    my ($S,$M,$Key,$App,$System)=@_;die "Choose an authorized endpoint.\n" if !defined $Key || ref $Key || $Key!~/\A[1-9][0-9]*\@[0-9]{1,3}\z/;
    my @Matches;
    for my $A (@{$M->{Assets}}) {for my $E (@{$A->{Endpoints}}) {push @Matches,$E if $E->{Key} eq $Key}}
    die "Choose an authorized endpoint.\n" if @Matches!=1;
    my $E=$Matches[0];die "Endpoint selection changed.\n" if ($App && $E->{ApplicationID} ne $App) || ($System && $E->{AssetID} ne $System);
    my @Duplicate=map {@{$_->{Endpoints}}} @{$M->{Assets}};
    die "Address is ambiguous in the authorized asset scope.\n" if (grep {$_->{Address} eq $E->{Address}} @Duplicate)>1;
    return $E;
}
sub _binding {
    my ($S)=@_;
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    my $List=$WS->WebserviceList(Valid=>1) || {};my @Bindings;
    die "Integration catalog exceeds budget.\n" if keys(%$List)>1000;
    for my $ID (sort {$a<=>$b} keys %$List) {
        my $W=$WS->WebserviceGet(ID=>$ID);next if !$W || ($W->{ValidID} || 0)!=1;
        my $T=$W->{Config}{Requester}{Transport};next if ref $T ne 'HASH' || ($T->{Type} || '') ne 'HTTP::TESSERAIntegration';
        my $C=$T->{Config};next if ref $C ne 'HASH' || ($C->{Preset} || '') ne 'Navis';
        my $P=$C->{CustomerSimulation};next if ref $P ne 'HASH' || !$P->{Enabled};
        die "Invalid simulation identity configuration.\n" if !Kernel::System::TESSERA::NavisPlan::_text($P->{IdentityNamespace})
            || (defined $P->{SourceNamespace} && length($P->{SourceNamespace}) && !Kernel::System::TESSERA::NavisPlan::_text($P->{SourceNamespace}));
        push @Bindings,{Mode=>'OnDemand',WebserviceID=>0+$ID,Namespace=>$P->{IdentityNamespace},SourceNamespace=>$P->{SourceNamespace} || '',GraphName=>'',
            ConnectionDigest=>Kernel::System::TESSERA::NavisPlan->new()->Digest($W->{Config})};
    }
    die "Configure exactly one enabled Navis customer simulation connection in Integration onboarding.\n" if @Bindings!=1;
    return $Bindings[0];
}
sub _applicationBinding {
    my ($S,$B,$M,$ID)=@_;return $B if !defined $ID || $ID eq '';
    die "Choose a permitted Application topology.\n" if ref $ID || $ID!~/\A[1-9][0-9]*\z/
        || !grep {$_->{ID} eq $ID} @{$M->{Applications}};
    my $App=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$ID,DynamicFields=>1);
    die "Application topology unavailable.\n" if ref $App ne 'HASH' || ($App->{Class} || '') ne 'Application' || ($App->{ZTSMStatus} || '') ne 'Active';
    my $Name=$App->{DynamicField_Navis};$Name=$Name->[0] if ref $Name eq 'ARRAY' && @$Name==1;
    die "Configure the Application Navis topology name first.\n" if !Kernel::System::TESSERA::NavisPlan::_text($Name) || $Name=~/^\s|\s$/;
    return {%$B,ApplicationID=>"$ID",GraphName=>$Name};
}
sub _savedBinding {
    my ($S,$D,$M)=@_;
    return $S->_applicationBinding($S->_binding(),$M,$D->{Binding}{ApplicationID}) if ($D->{Binding}{Mode} || '') eq 'OnDemand';
    # Historical records retain their original scope and pinned build. Never use
    # this compatibility path to initiate a new trace.
    my $All=eval {JSON::PP->new->decode($S->_config('Bindings') || '{}')};
    my $B=ref $All eq 'HASH'?$All->{$D->{EnvironmentID} || ''}:undef;
    die "Historical analysis binding unavailable.\n" if ref $B ne 'HASH';
    my $W=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$B->{WebserviceID});
    die "Historical connection unavailable.\n" if !$W || ($W->{ValidID} || 0)!=1;
    return {%$B,ConnectionDigest=>Kernel::System::TESSERA::NavisPlan->new()->Digest($W->{Config})};
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
    my $B=$S->_applicationBinding($S->_binding(),$M,$P{TopologyApplicationID});my $ID=substr(sha256_hex($P{CustomerUserID}.':'.$P{SubmissionToken}),0,40);
    my $Flow={source=>$Source->{Address},destination=>$Destination->{Address},protocol=>$P{Protocol},action=>'allow'};
    $Flow->{destination_port}=$P{DestinationPort} if defined $P{DestinationPort} && length $P{DestinationPort};
    die "TCP/UDP destination port required.\n" if ($P{Protocol} || '')=~/\A(?:tcp|udp)\z/ && !defined $Flow->{destination_port};
    my $Request=Kernel::System::TESSERA::NavisPlan->new()->Request(Flow=>$Flow,OnDemand=>1,Namespace=>$B->{SourceNamespace},TopologyName=>$B->{GraphName},CallerID=>'tessera-'.$ID);
    my $D={AnalysisID=>$ID,CustomerUserID=>$P{CustomerUserID},Source=>dclone($Source),Destination=>dclone($Destination),
        Binding=>$B,SubmittedRequest=>dclone($Request),Request=>dclone($Request),Status=>'CREATED',CreatedAt=>time()};
    $D->{SubmissionDigest}=Kernel::System::TESSERA::NavisPlan->new()->Digest([$Source->{AssetID},$Destination->{AssetID},$Request,$B]);
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
                my $TraceRequest=dclone($Request);
                $D->{Request}=dclone($TraceRequest);$D->{Status}='TRACE_INTENT';$S->_store($D);
                my $Trace=$S->_call($B,'Trace',$TraceRequest);
                die "Invalid trace identity.\n" if ($Trace->{code} || '') ne 'TRACE_RESULT_READY'
                    || ($Trace->{caller_session_id} || '') ne $Request->{caller_session_id}
                    || !Kernel::System::TESSERA::NavisPlan::_uuid($Trace->{graph_build_id})
                    || !Kernel::System::TESSERA::NavisPlan::_uuid($Trace->{trace_session_id})
                    || (defined $TraceRequest->{graph_build_id} && $Trace->{graph_build_id} ne $TraceRequest->{graph_build_id});
                $D->{Trace}=$Trace;$D->{Request}{graph_build_id}=$Trace->{graph_build_id};
                delete @{$D->{Request}}{qw(topology_name topology_version_id)};
                $D->{Status}='TRACE_SAVED';$S->_store($D);
                $D->{Graph}=$S->_call($B,'GraphGet',{BuildID=>$Trace->{graph_build_id}});
                Kernel::System::TESSERA::NavisPlan->new()->Graph($D->{Graph},$Trace->{graph_build_id});
                $S->_store($D);
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
    my $B=$S->_savedBinding($D,$M);
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
        if (!$D->{Graph}) {
            $D->{Graph}=$S->_call($D->{Binding},'GraphGet',{BuildID=>$D->{Request}{graph_build_id}});
            Kernel::System::TESSERA::NavisPlan->new()->Graph($D->{Graph},$D->{Request}{graph_build_id});$S->_store($D);
        }
        $D->{Recommendations}=$S->_call($D->{Binding},'RecommendationsGet',{CallerSessionID=>$D->{Request}{caller_session_id}});
        $D->{Status}='ANALYZED';$S->_store($D);1;
    } or $Error=$@ || 'Recommendation refresh failed.';
    $DB->Prepare(SQL=>'SELECT RELEASE_LOCK(?)',Bind=>[\$Lock]);$DB->FetchrowArray();die $Error if $Error;return $ID;
}
# Owner-approved graph-only affiliation projection. Never return hidden device
# data or grant direct object access from this lookup.
sub _restrictedApplication {
    my ($S,$D,$Node)=@_;my $I=$Node->{external_identity};
    return '' if ref $I ne 'HASH' || ($I->{status} || '') ne 'mapped' || ($I->{namespace} || '') ne $D->{Binding}{Namespace}
        || ($I->{object_class} || '')!~/\A(?:Workload|NetworkNode)\z/ || ($I->{id} || '')!~/\A[1-9][0-9]*\z/;
    my $Name=eval {
        my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(ConfigItemID=>$I->{id},DynamicFields=>1);
        die if ref $CI ne 'HASH' || ($CI->{Class} || '') ne $I->{object_class};
        my @Apps=$S->_refs($CI->{'DynamicField_ZTAM-Application'},'Application');
        die if @Apps!=1 || !defined $Apps[0]{Name} || ref $Apps[0]{Name};
        $Apps[0]{Name};
    };
    return defined $Name && !ref $Name && length($Name)<=255?$Name:'';
}
# Narrow presentation exception: graph shape may contain anonymous restricted
# vertices. No hidden CI lookup, stable identity or remote metadata is exposed.
sub _graphProjection {
    my ($S,$D,$F,$Devices)=@_;
    my $V=$F->{visibility_graph};
    if (!defined $V) {
        my (%Seen,@Nodes,@Edges,$Previous);
        for my $H (@{$F->{hops} || []}) {
            die "Invalid trace hop.\n" if ref $H ne 'HASH';
            my $ID=$H->{device_id};
            push @Nodes,{id=>$ID,device_id=>$ID,type=>'device',trace_status=>'visited'} if !$Seen{$ID}++;
            push @Edges,{source=>$Previous,target=>$ID,kind=>'trace_candidate'} if defined $Previous && $Previous ne $ID;
            $Previous=$ID;
        }
        $V={nodes=>\@Nodes,connections=>\@Edges};
    }
    die "Invalid visibility graph.\n" if ref $V ne 'HASH' || ref $V->{nodes} ne 'ARRAY' || @{$V->{nodes}}>256
        || ref $V->{connections} ne 'ARRAY' || @{$V->{connections}}>512;
    my (%Map,%GraphNodes,@Nodes,@Edges,$Restricted,$Gap);my $Index=0;
    for my $G (@{$D->{Graph}{nodes}}) {$GraphNodes{$G->{id}}=$G if ($G->{type} || '') eq 'device'}
    for my $N (@{$V->{nodes}}) {
        die "Invalid visibility node.\n" if ref $N ne 'HASH' || !defined $N->{id} || ref $N->{id} || exists $Map{$N->{id}};
        my $ID=$N->{id};my $Out;
        if (($N->{type} || '') eq 'unmanaged') {
            die "Invalid visibility gap.\n" if !$N->{placeholder} || defined $N->{device_id};
            $Out={ID=>'gap-'.++$Index,Name=>'Unmanaged / missing network',Class=>'Unknown segment',Placeholder=>1,Evidence=>'Unverified',TraceStatus=>'not_traced'};$Gap=1;
        } elsif (($N->{type} || '') eq 'device' && $GraphNodes{$ID} && (!defined $N->{device_id} || $N->{device_id} eq $ID)) {
            my $A=$Devices->{$ID};
            if ($A) {
                $Out={ID=>$A->{ID},Name=>$A->{Name},Class=>$A->{Class},Evidence=>'Inventory evidence',TraceStatus=>($N->{trace_status} || '') eq 'visited'?'visited':'not_traced'};
            } else {
                $Out={ID=>'restricted-'.++$Index,Name=>'Restricted device',Class=>'Details unavailable',Restricted=>1,Evidence=>'Not disclosed',TraceStatus=>'unknown'};$Restricted=1;
                my $Application=$S->_restrictedApplication($D,$GraphNodes{$ID});$Out->{ApplicationName}=$Application if length $Application;
            }
        } else {die "Unknown visibility node.\n"}
        $Map{$ID}=$Out->{ID};push @Nodes,$Out;
    }
    for my $E (@{$V->{connections}}) {
        die "Invalid visibility connection.\n" if ref $E ne 'HASH' || !exists $Map{$E->{source} || ''} || !exists $Map{$E->{target} || ''};
        my $Kind=($E->{kind} || '') eq 'trace_candidate'?'candidate':'unknown';
        push @Edges,{Source=>$Map{$E->{source}},Target=>$Map{$E->{target}},Kind=>$Kind};
    }
    return {DisplayNodes=>\@Nodes,DisplayEdges=>\@Edges,HasRestricted=>$Restricted?1:0,HasVisibilityGap=>$Gap?1:0};
}
sub _project {
    my ($S,$D,$M)=@_;my $Out={AnalysisID=>$D->{AnalysisID},Status=>$D->{Status},CreatedAt=>$D->{CreatedAt},EnvironmentID=>$D->{EnvironmentID},
        Source=>$D->{Source},Destination=>$D->{Destination},Protocol=>$D->{Request}{protocol},DestinationPort=>$D->{Request}{destination_port},
        TopologyApplicationID=>$D->{Binding}{ApplicationID} || '',Nodes=>[],Edges=>[],Hops=>[],Recommendations=>[],Findings=>[],Verdict=>'unknown',Withheld=>0};
    $Out->{CreatedAtUTC}=strftime('%Y-%m-%dT%H:%M:%SZ',gmtime($D->{CreatedAt}));
    my %Labels=(CREATED=>'Analysis could not start',TRACE_INTENT=>'Outcome uncertain',TRACE_SAVED=>'Trace saved; recommendations unavailable',ANALYZED=>'Analysis saved');
    $Out->{StatusLabel}=$Labels{$D->{Status}} || 'Analysis unavailable';
    my (%Assets,%Nodes);
    for my $A (@{$M->{Assets}}) {$Assets{JSON::PP->new->canonical->encode([$D->{Binding}{Namespace},$A->{Class},$A->{ID}])}=$A}
    for my $E (@$D{qw(Source Destination)}) {$Nodes{$E->{AssetID}}={ID=>$E->{AssetID},Name=>$E->{Name},Class=>$E->{Class},Address=>$E->{Address}}}
    return {%$Out,Nodes=>[values %Nodes]} if !$D->{Trace} || !$D->{Graph};
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
            if ($Key=~/(?:^|_)device_ids\z/ && defined $Value->{$Key}) {
                $Out->{Withheld}=1 if ref $Value->{$Key} ne 'ARRAY' || grep {ref $_ || !$Device{$_ || ''}} @{$Value->{$Key}};
            }
            if ($Key=~/(?:^|_)device_id\z/ && defined $Value->{$Key}) {
                $Out->{Withheld}=1 if ref $Value->{$Key} || !$Device{$Value->{$Key}};
            }
            $Scan->($Value->{$Key},$Depth+1);
        }}
    };
    my $Scanned=eval {$Scan->($F,0);1};undef $Scan;die "Trace evidence exceeds budget.\n" if !$Scanned;
    my $Presentation=eval {$S->_graphProjection($D,$F,\%Device)};
    if ($Presentation) {@$Out{keys %$Presentation}=values %$Presentation}
    else {$Out->{DisplayGraphUnavailable}=1}
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
        my $Status=$F->{connection_verdict}{status} || 'unknown';$Out->{Verdict}=$Status if !$Out->{HasVisibilityGap} && @Path && $Status=~/\A(?:allowed|blocked|unknown)\z/;
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
