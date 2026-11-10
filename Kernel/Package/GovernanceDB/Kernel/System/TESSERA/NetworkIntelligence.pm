package Kernel::System::TESSERA::NetworkIntelligence;
use strict;
use warnings;
use Storable qw(dclone);
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Kernel::GenericInterface::Invoker::NetXMS::Base;
our @ObjectDependencies=('Kernel::GenericInterface::Requester','Kernel::System::TESSERA::AsyncExecution','Kernel::System::SystemData');
sub new { my ($T,%P)=@_; bless {%P},$T }
sub _fail { return {Success=>0,Error=>$_[0]} }
sub _id { defined $_[0] && !ref $_[0] && $_[0]=~/\A[1-9][0-9]{0,11}\z/ }
sub _plain { defined $_[0] && !ref $_[0] && length($_[0])<=200 && $_[0]=~/\A[A-Za-z0-9_.:\/-]+\z/ }
sub _ip {
    my ($S)=@_; return if !defined $S || ref $S || $S!~/\A([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\z/;
    my @O=($1,$2,$3,$4); return if grep {$_>255 || (length($_)>1 && /^0/)} @O;
    return ($O[0]*16777216+$O[1]*65536+$O[2]*256+$O[3]);
}
sub _prefix {
    my ($IP,$CIDR)=@_; return if !defined $CIDR || ref $CIDR || $CIDR!~m{\A(.+)/([0-9]|[12][0-9]|3[0-2])\z};
    my ($N,$Bits)=(_ip($1),0+$2); return if !defined $N;
    my $Size=2**(32-$Bits); return if $N % $Size;
    return int($IP/$Size)==int($N/$Size) ? $Bits : undef;
}
# Records are authorized CMDB snapshots supplied by the existing automation.
# Field spellings below are taken from the authoritative exported classes.
sub ResolveNetwork {
    my ($Self,%P)=@_;
    my $IP=_ip($P{Address}); return _fail('IPv4 endpoint required by the current CMDB CIDR model.') if !defined $IP;
    return _fail('Invalid explicit network segment scope.') if defined $P{SegmentID} && !_id($P{SegmentID});
    return _fail('Authorized CMDB records required.') if ref $P{Records} ne 'ARRAY' || @{$P{Records}}>10000;
    my %IDs;
    for my $CI (@{$P{Records}}) {
        return _fail('Invalid or duplicate CMDB snapshot.') if ref $CI ne 'HASH' || !_id($CI->{ConfigItemID})
            || $IDs{$CI->{ConfigItemID}}++ || ref $CI->{Fields} ne 'HASH';
    }
    my @Matches;
    for my $CI (@{$P{Records} || []}) {
        next if ($CI->{Class} || '') ne 'NetworkSegment';
        next if defined $P{SegmentID} && $CI->{ConfigItemID} ne $P{SegmentID};
        my $F=$CI->{Fields} || {};
        next if defined $P{PlatformID} && ($F->{'ZTAM-Platform'} || '') ne $P{PlatformID};
        my $Bits=_prefix($IP,$F->{'ZCI-CIDR'});
        push @Matches,[$Bits,$CI] if defined $Bits;
    }
    return _fail('Endpoint has no authorized CMDB NetworkSegment.') if !@Matches;
    @Matches=sort {$b->[0]<=>$a->[0]} @Matches;
    return _fail('Endpoint matches ambiguous CMDB network scopes.') if @Matches>1 && $Matches[0][0]==$Matches[1][0];
    my $Segment=$Matches[0][1]; my $F=$Segment->{Fields};
    my @Pools;
    for my $CI (@{$P{Records} || []}) {
        next if ($CI->{Class} || '') ne 'NetworkAddressPool';
        my $PF=$CI->{Fields} || {};
        next if ($PF->{'ZCI-Network'} || '') ne $Segment->{ConfigItemID};
        my ($A,$B)=(_ip($PF->{'ZCI-RangeStart'}),_ip($PF->{'ZCI-RangeEnd'}));
        return _fail('Invalid linked address pool range.') if !defined $A || !defined $B || $A>$B;
        push @Pools,$CI->{ConfigItemID} if $IP>=$A && $IP<=$B;
    }
    return _fail('Endpoint belongs to overlapping address pools.') if @Pools>1;
    return {Success=>1,Data=>{SegmentID=>$Segment->{ConfigItemID},CIDR=>$F->{'ZCI-CIDR'},
        NetworkZoneID=>$F->{'ZCI-Zone'},PlatformID=>$F->{'ZTAM-Platform'},AddressPoolID=>$Pools[0]}};
}
sub Discover {
    my ($Self,%P)=@_;
    my $C=$P{Context}; my $D=$P{Data};
    return _fail('Authorized network context required.') if ref $C ne 'HASH' || ref $D ne 'HASH'
        || !Kernel::GenericInterface::Invoker::NetXMS::Base::_Bounded($C)
        || !Kernel::GenericInterface::Invoker::NetXMS::Base::_Bounded($D)
        || !_id($P{ActorID}) || ($C->{ActorID} || 0)!=$P{ActorID} || !_id($C->{NetXMSWebserviceID});
    return _fail('Incomplete backend network mapping.') if ref $C->{ConfigItems} ne 'ARRAY'
        || grep {ref $C->{$_} ne 'HASH'} qw(Endpoints Nodes SegmentDomains DomainBindings);
    return _fail('Only source and destination are accepted from the request.') if grep {$_ ne 'Source' && $_ ne 'Destination'} keys %$D;
    if (defined $C->{Flow}) {
        return _fail('Invalid governed service flow.') if ref $C->{Flow} ne 'HASH'
            || grep {$_ ne 'Protocol' && $_ ne 'DestinationPorts'} keys %{$C->{Flow}};
        return _fail('Unsupported governed service protocol.') if ($C->{Flow}{Protocol} || '')!~/\A(?:tcp|udp|icmp)\z/;
        if ($C->{Flow}{Protocol} ne 'icmp') {
            my $Ports=$C->{Flow}{DestinationPorts};
            return _fail('Explicit governed destination ports required.') if ref $Ports ne 'ARRAY' || !@$Ports || @$Ports>64
                || grep {!defined $_ || ref $_ || !/\A[1-9][0-9]{0,4}\z/ || $_>65535} @$Ports;
        }
        elsif (exists $C->{Flow}{DestinationPorts}) {return _fail('ICMP has no destination ports.')}
    }
    my @Endpoints;
    for my $K (qw(Source Destination)) {
        return _fail('Missing endpoint.') if !_plain($D->{$K});
        my $E=$C->{Endpoints}{$D->{$K}};
        return _fail('Endpoint is not in the authorized CMDB mapping.') if ref $E ne 'HASH' || !_id($E->{NodeID}) || !defined _ip($E->{Address});
        my $N=$Self->ResolveNetwork(Address=>$E->{Address},PlatformID=>$E->{PlatformID},SegmentID=>$E->{SegmentID},Records=>$C->{ConfigItems});
        return $N if !$N->{Success};
        push @Endpoints,{NodeID=>$E->{NodeID},Address=>$E->{Address},PlatformID=>$E->{PlatformID},Network=>$N->{Data}};
    }
    my @Paths;
    for my $Direction ([0,1],[1,0]) {
        my $R=$Self->{Requester} ? $Self->{Requester}->(WebserviceID=>$C->{NetXMSWebserviceID},Invoker=>'PathTrace',Data=>{
            SourceID=>$Endpoints[$Direction->[0]]{NodeID},DestinationID=>$Endpoints[$Direction->[1]]{NodeID}})
            : $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(WebserviceID=>$C->{NetXMSWebserviceID},Invoker=>'PathTrace',Data=>{
            SourceID=>$Endpoints[$Direction->[0]]{NodeID},DestinationID=>$Endpoints[$Direction->[1]]{NodeID}});
        return _fail('NetXMS path collection failed.') if ref $R ne 'HASH' || !$R->{Success} || ref $R->{Data}{Path} ne 'HASH';
        my $Path=$R->{Data}{Path};
        return _fail('NetXMS path identity or structure does not match the query.') if
            !Kernel::GenericInterface::Invoker::NetXMS::Base::_Bounded($Path)
            || !_id($Path->{sourceId}) || !_id($Path->{destinationId})
            || $Path->{sourceId}!=$Endpoints[$Direction->[0]]{NodeID}
            || $Path->{destinationId}!=$Endpoints[$Direction->[1]]{NodeID}
            || ref $Path->{hops} ne 'ARRAY' || @{$Path->{hops}}>256
            || !JSON::PP::is_bool($Path->{isComplete})
            || !defined $Path->{collectedAt} || ref $Path->{collectedAt} || $Path->{collectedAt}!~/\A[0-9]{1,12}\z/;
        return _fail('NetXMS path is incomplete or stale.') if !$Path->{isComplete} || !$Path->{collectedAt}
            || time()-$Path->{collectedAt}>300 || $Path->{collectedAt}>time()+60;
        push @Paths,dclone($Path);
    }
    my (%Selected,%SeenHop);
    for my $Path (@Paths) {
        for my $Hop (@{$Path->{hops}}) {
            return _fail('Invalid path hop.') if ref $Hop ne 'HASH' || !_id($Hop->{nodeId});
            my $ID=$Hop->{nodeId};
            next if $ID==$Endpoints[0]{NodeID} || $ID==$Endpoints[1]{NodeID};
            return _fail('Unresolved path hop identity.') if !$ID;
            my $Map=$C->{Nodes}{$ID};
            return _fail('Path node has no authorized CMDB classification.') if ref $Map ne 'HASH';
            next if ($Map->{Kind} || '') eq 'ExternalTransit' || ($Map->{Kind} || '') eq 'NetworkDevice';
            return _fail('Unknown path node classification.') if ($Map->{Kind} || '') ne 'Firewall';
            return _fail('Invalid path enforcement alias.') if !_plain($Map->{InventoryName});
            my $Old=$Selected{$Map->{InventoryName}};
            return _fail('Conflicting path enforcement context.') if $Old
                && grep {($Old->{$_} || '') ne ($Map->{$_} || '')} qw(ConfigItemID Platform Context);
            $Selected{$Map->{InventoryName}}=$Map;
            $SeenHop{$ID}=1;
        }
    }
    # The exported NetworkSegment has no direct NetworkDomain field. Resolve
    # the relationship through reviewed automation, keyed by the actual CI ID.
    # Never infer an enforcement domain from a zone label or platform name.
    for my $E (@Endpoints) {
        my $DomainID=$C->{SegmentDomains}{$E->{Network}{SegmentID}};
        return _fail('Network segment has no reviewed domain relationship.') if !_id($DomainID);
        my @Domains=grep {($_->{Class} || '') eq 'NetworkDomain' && $_->{ConfigItemID} eq $DomainID} @{$C->{ConfigItems}};
        return _fail('Network domain is not in the authorized CMDB snapshot.') if @Domains!=1;
        my $Binding=$C->{DomainBindings}{$DomainID};
        return _fail('Network domain has no reviewed enforcement binding.') if ref $Binding ne 'HASH';
        return _fail('Network layer must be Overlay or Underlay.') if ($Binding->{Layer} || '')!~/\A(?:Overlay|Underlay)\z/;
        return _fail('Invalid enforcement list.') if exists $Binding->{Enforcement} && ref $Binding->{Enforcement} ne 'ARRAY';
        $E->{Network}{DomainID}=$DomainID;
        $E->{Network}{Layer}=$Binding->{Layer};
        $E->{Network}{DomainTypeID}=$Domains[0]{Fields}{'ZTAM-NetworkDomainType'};
        if ($Binding->{Layer} eq 'Overlay') {
            return _fail('Overlay requires an explicit enforcement mapping.') if ref $Binding->{Enforcement} ne 'ARRAY' || !@{$Binding->{Enforcement}};
        }
        for my $F (@{$Binding->{Enforcement} || []}) {
            return _fail('Invalid domain enforcement mapping.') if ref $F ne 'HASH' || !_plain($F->{InventoryName});
            my $Old=$Selected{$F->{InventoryName}};
            return _fail('Conflicting enforcement contexts for an inventory alias.') if $Old
                && grep {($Old->{$_} || '') ne ($F->{$_} || '')} qw(ConfigItemID Platform Context);
            $Selected{$F->{InventoryName}}=$F;
        }
    }
    my @Candidates;
    for my $Name (sort keys %Selected) {
        my $F=$Selected{$Name};
        return _fail('Invalid managed firewall mapping.') if !_id($F->{ConfigItemID}) || !_plain($Name) || $Name=~/[:\/]/
            || ($F->{Platform} || '')!~/\A(?:panos|checkpoint|fortios|asa|nsx)\z/ || !_plain($F->{Context});
        push @Candidates,{map {$_=>$F->{$_}} qw(ConfigItemID InventoryName Platform Context)};
    }
    return _fail('No managed enforcement point was resolved.') if !@Candidates || @Candidates>32;
    my $Discovery={Source=>$Endpoints[0],Destination=>$Endpoints[1],Paths=>\@Paths,Candidates=>\@Candidates,
        Flow=>$C->{Flow},CollectedAt=>time(),Status=>'FACT_COLLECTION_REQUIRED'};
    my $JSON=JSON::PP->new->canonical->encode($Discovery);
    return _fail('Discovery exceeds saved continuation limit.') if length($JSON)>50000;
    $Discovery->{Digest}=sha256_hex($JSON);
    return {Success=>1,Data=>$Discovery};
}
sub Start {
    my ($Self,%P)=@_;
    my $R=$Self->Discover(%P); return $R if !$R->{Success};
    my $C=$P{Context};
    return _fail('Configure authorized AWX collection template and inventory.') if grep {!_id($C->{$_})} qw(AWXWebserviceID TemplateID InventoryID TargetID);
    my $D=$R->{Data};
    return $Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution')->Start(
        HandlerKey=>'NetworkAssessment',TargetType=>'Ticket',TargetID=>$C->{TargetID},ActorID=>$P{ActorID},
        Continuation=>{Discovery=>$D},WebserviceID=>$C->{AWXWebserviceID},Invoker=>'JobLaunchCallback',
        Payload=>{TemplateID=>$C->{TemplateID},inventory=>$C->{InventoryID},limit=>'localhost',extra_vars=>{tessera_network=>$D}});
}
sub Analyze {
    my ($Self,%P)=@_;
    my ($D,$Evidence)=@P{qw(Discovery Evidence)};
    return _fail('Invalid evidence document.') if ref $D ne 'HASH' || ref $Evidence ne 'HASH'
        || !Kernel::GenericInterface::Invoker::NetXMS::Base::_Bounded($D)
        || !Kernel::GenericInterface::Invoker::NetXMS::Base::_Bounded($Evidence)
        || ($D->{Digest} || '')!~/\A[a-f0-9]{64}\z/
        || ($Evidence->{Digest} || '') ne $D->{Digest} || ref $Evidence->{Devices} ne 'ARRAY'
        || @{$Evidence->{Devices}}>32 || ref $D->{Candidates} ne 'ARRAY';
    my (%ByName,@Issues,@Plans);
    for my $E (@{$Evidence->{Devices}}) {
        return _fail('Duplicate or invalid device evidence.') if ref $E ne 'HASH' || !_plain($E->{InventoryName}) || $ByName{$E->{InventoryName}};
        $ByName{$E->{InventoryName}}=$E;
    }
    for my $F (@{$D->{Candidates}}) {
        my $E=delete $ByName{$F->{InventoryName}};
        if (!$E || ($E->{Platform} || '') ne $F->{Platform} || ($E->{Context} || '') ne $F->{Context}) {push @Issues,{Device=>$F->{InventoryName},Reason=>'Missing or mismatched device/context evidence'};next}
        if (($E->{Status} || '') ne 'COLLECTED' || !defined $E->{CollectedAt} || ref $E->{CollectedAt}
            || $E->{CollectedAt}!~/\A[0-9]{1,12}\z/ || time()-$E->{CollectedAt}>300 || $E->{CollectedAt}>time()+60) {push @Issues,{Device=>$F->{InventoryName},Reason=>'Collection failed or is stale'};next}
        my $P={%$F,Source=>$D->{Source}{Address},Destination=>$D->{Destination}{Address},Flow=>$D->{Flow},
            Enforcement=>$F->{Platform} eq 'nsx' ? 'DistributedFirewall' : $F->{Platform} eq 'checkpoint' ? 'AccessPolicy' : 'InterfacePolicy',
            Findings=>$E->{Findings},EvidenceHash=>$E->{EvidenceHash},Status=>'REVIEW_REQUIRED'};
        if (ref $E->{Findings} ne 'HASH' || ref $E->{Findings}{Unresolved} ne 'ARRAY'
            || ($E->{EvidenceHash} || '')!~/\A[a-f0-9]{64}\z/) {push @Issues,{Device=>$F->{InventoryName},Reason=>'No valid interpreted findings'};next}
        $P->{SourceZone}=$E->{Findings}{SourceZone} if defined $E->{Findings}{SourceZone};
        $P->{DestinationZone}=$E->{Findings}{DestinationZone} if defined $E->{Findings}{DestinationZone};
        # A candidate request is not an apply-ready rule or an approval.
        push @Plans,$P;
        push @Issues,map {{Device=>$F->{InventoryName},Reason=>$_}} @{$E->{Findings}{Unresolved} || []};
    }
    return _fail('Evidence includes an unrequested device.') if keys %ByName;
    push @Issues,{Reason=>'Protocol/ports must resolve from the requested governed service'} if ref $D->{Flow} ne 'HASH';
    return {Success=>1,Data=>{Status=>@Issues ? 'INCOMPLETE' : 'PROPOSAL',ApplyReady=>JSON::PP::false,
        Digest=>$D->{Digest},Plans=>\@Plans,Issues=>\@Issues,SourceNetwork=>$D->{Source}{Network},DestinationNetwork=>$D->{Destination}{Network}}};
}
sub Complete {
    my ($Self,%P)=@_;
    return if ($P{ExecutionUID} || '')!~/\A[A-Za-z0-9]{40}\z/ || !_id($P{ActorID}) || !_id($P{TargetID});
    my $Store=$Kernel::OM->Get('Kernel::System::SystemData'); my $Key='TESSERA::NetworkAssessment::'.$P{ExecutionUID};
    my $ResponseHash=sha256_hex(($P{ExitCode} // '').'\n'.($P{Response} // ''));
    my $Old=$Store->SystemDataGet(Key=>$Key);
    if (defined $Old) {
        my $Saved=eval {JSON::PP->new->decode($Old)};
        return ref $Saved eq 'HASH' && ($Saved->{ResponseHash} || '') eq $ResponseHash
            && ($Saved->{ActorID} || 0)==$P{ActorID} && ($Saved->{TargetID} || 0)==$P{TargetID};
    }
    my $Evidence=eval {JSON::PP->new->decode($P{Response})};
    my $R=$P{ExitCode}==0 ? $Self->Analyze(Discovery=>$P{Context}{Discovery},Evidence=>$Evidence)
        : {Success=>1,Data=>{Status=>'COLLECTION_FAILED',ApplyReady=>JSON::PP::false}};
    return if !$R->{Success};
    my $Value=JSON::PP->new->canonical->encode({ActorID=>$P{ActorID},TargetID=>$P{TargetID},ResponseHash=>$ResponseHash,%{$R->{Data}}});
    return if length($Value)>1048576;
    return $Store->SystemDataAdd(Key=>$Key,Value=>$Value,UserID=>$P{ActorID});
}
sub Get {
    my ($Self,%P)=@_;
    return if ($P{ExecutionUID} || '')!~/\A[A-Za-z0-9]{40}\z/ || !_id($P{ActorID});
    my $Row=$Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution')->_Get($P{ExecutionUID});
    return if !$Row || $Row->{ActorID}!=$P{ActorID} || $Row->{HandlerKey} ne 'NetworkAssessment';
    my $Value=$Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGet(Key=>'TESSERA::NetworkAssessment::'.$P{ExecutionUID});
    return defined $Value ? JSON::PP->new->decode($Value) : {Status=>$Row->{State}};
}
1;
