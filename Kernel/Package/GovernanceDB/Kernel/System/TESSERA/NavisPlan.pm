package Kernel::System::TESSERA::NavisPlan;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Storable qw(dclone);
use Socket qw(AF_INET AF_INET6 inet_pton inet_ntop);
our $ObjectManagerDisabled=1;
sub new {bless {},$_[0]}
sub Digest {sha256_hex(JSON::PP->new->canonical->utf8->encode($_[1]))}
sub _uuid {defined $_[0] && !ref $_[0] && $_[0]=~/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i}
sub _text {defined $_[0] && !ref $_[0] && length($_[0])>0 && length($_[0])<=255 && $_[0]!~/[\x00-\x1f]/}
sub _tuple {JSON::PP->new->canonical->encode([@{$_[0]}{qw(source destination protocol destination_port)}])}
sub Request {
    my ($S,%P)=@_;my $F=$P{Flow};die "Invalid flow.\n" if ref $F ne 'HASH' || !_uuid($P{BuildID}) || ($P{CallerID} || '')!~/\Atessera-[a-f0-9]{40}\z/;
    die "Unsupported flow fields.\n" if grep {!/\A(?:source|destination|protocol|source_port|destination_port|application|action)\z/} keys %$F;
    die "Unsupported requested action.\n" if ($F->{action} || '')!~/\A(?:allow|deny)\z/;
    my $D=dclone($F);delete $D->{action};my $Count=1;
    for my $K (qw(source destination)) {
        die "Literal host addresses required.\n" if !_text($D->{$K});my (%Seen,@IPs);
        for my $IP (split /[;,]/,$D->{$K},-1) {
            $IP=~s/^\s+|\s+$//g;my $Family=index($IP,':')>=0?AF_INET6:AF_INET;
            my $Packed=eval {inet_pton($Family,$IP)};die "Literal host addresses required.\n" if !defined $Packed;
            my $Canonical=inet_ntop($Family,$Packed);push @IPs,$Canonical if !$Seen{$Canonical}++;
        }
        $Count*=scalar @IPs;$D->{$K}=join(';',@IPs);
    }
    die "Too many expanded flows.\n" if !$Count || $Count>1000;
    die "Unsupported protocol.\n" if ($D->{protocol} || '')!~/\A(?:tcp|udp|icmp|icmpv6)\z/;
    for my $K (qw(source_port destination_port)) {
        next if !defined $D->{$K};die "Invalid port.\n" if ref $D->{$K} || $D->{$K}!~/\A[0-9]{1,5}\z/ || $D->{$K}>65535 || $D->{protocol}=~/^icmp/;
        $D->{$K}=0+$D->{$K};
    }
    die "Invalid application.\n" if exists $D->{application} && !_text($D->{application});
    return {%$D,graph_build_id=>$P{BuildID},caller_session_id=>$P{CallerID}};
}
sub Graph {
    my ($S,$G,$Build)=@_;die "Completed matching graph required.\n" if ref $G ne 'HASH' || ($G->{build_id} || '') ne $Build || ($G->{status} || '') ne 'completed'
        || ref $G->{nodes} ne 'ARRAY' || @{$G->{nodes}}>10000;
    my (%Devices,%Identities);
    for my $N (@{$G->{nodes}}) {
        die "Invalid graph identity.\n" if ref $N ne 'HASH' || ($N->{type} || '') ne 'device' || !_uuid($N->{id}) || exists $Devices{$N->{id}} || ref $N->{external_identity} ne 'HASH';
        my $I=$N->{external_identity};my $Key;
        if (($I->{status} || '') eq 'mapped') {
            die "Invalid external identity.\n" if grep {!_text($I->{$_})} qw(namespace object_class id);
            $Key=JSON::PP->new->canonical->encode([@$I{qw(namespace object_class id)}]);
            die "Ambiguous external identity.\n" if $Identities{$Key}++;
        }
        $Devices{$N->{id}}=$Key;
    }
    return \%Devices;
}
sub Prepare {
    my ($S,%P)=@_;my ($Q,$T,$R)=@P{qw(Request Trace Recommendations)};
    die "Mismatched analysis.\n" if ref $Q ne 'HASH' || ref $T ne 'HASH' || ref $R ne 'HASH'
        || ($T->{code} || '') ne 'TRACE_RESULT_READY' || ($T->{caller_session_id} || '') ne $Q->{caller_session_id}
        || ($T->{graph_build_id} || '') ne $Q->{graph_build_id} || !_uuid($T->{trace_session_id})
        || ($R->{caller_session_id} || '') ne $Q->{caller_session_id} || ($R->{trace_session_id} || '') ne $T->{trace_session_id};
    my $Devices=$S->Graph($P{Graph},$Q->{graph_build_id});
    die "Authorized CMDB snapshot required.\n" if ref $P{Snapshot} ne 'ARRAY' || @{$P{Snapshot}}>1000 || !_text($P{Namespace});
    my %Mapped;
    for my $CI (@{$P{Snapshot}}) {
        die "Invalid authorized CMDB identity.\n" if ref $CI ne 'HASH' || exists $CI->{navis_device_id} || ($CI->{namespace} || '') ne $P{Namespace}
            || ($CI->{Class} || '') ne 'NetworkNode' || !_text($CI->{ConfigItemID}) || ($CI->{platform} || '')!~/\A(?:panos|aci|nsx)\z/
            || ref $CI->{context} ne 'HASH' || !keys %{$CI->{context}};
        my $Key=JSON::PP->new->canonical->encode([@$CI{qw(namespace Class ConfigItemID)}]);
        die "Duplicate CMDB identity.\n" if $Mapped{$Key};$Mapped{$Key}=$CI;
    }
    my %Expected;
    for my $Src (split /;/,$Q->{source}) {for my $Dst (split /;/,$Q->{destination}) {$Expected{_tuple({%$Q,source=>$Src,destination=>$Dst})}=1}}
    die "Missing analysis flows.\n" if ref $T->{results} ne 'ARRAY' || @{$T->{results}}!=keys %Expected;
    my (@Summary,%Flows);
    for my $F (@{$T->{results}}) {
        die "Mismatched analysis flows.\n" if ref $F ne 'HASH' || !$Expected{_tuple($F)} || $Flows{_tuple($F)}++;
        my $V=$F->{connection_verdict} || {};my $Status=$V->{status} || 'unknown';$Status='unknown' if $Status!~/\A(?:allowed|blocked|unknown)\z/;
        push @Summary,{Flow=>{map {$_=>$F->{$_}} qw(source destination protocol destination_port)},Status=>$Status,Missing=>$V->{missing} || []};
    }
    my $Out={Status=>'REVIEW_REQUIRED',Simulation=>JSON::PP::true,ApplyReady=>JSON::PP::false,CallerSessionID=>$Q->{caller_session_id},
        TraceSessionID=>$T->{trace_session_id},GraphBuildID=>$Q->{graph_build_id},RequestDigest=>$S->Digest($Q),
        CMDBSnapshotDigest=>$S->Digest($P{Snapshot}),GraphIdentityDigest=>$S->Digest($P{Graph}),RequestedAction=>$P{Action},Summary=>\@Summary,Plans=>[],Issues=>[]};
    my $Code=$R->{code} || '';die "Unknown recommendation status.\n" if $Code!~/\A(?:RECOMMENDATION_PENDING|RECOMMENDATIONS_AVAILABLE|RECOMMENDATIONS_UNAVAILABLE)\z/;
    if ($Code ne 'RECOMMENDATIONS_AVAILABLE') {$Out->{Status}=$Code;return $Out}
    die "Invalid recommendations.\n" if ref $R->{recommendations} ne 'ARRAY' || !@{$R->{recommendations}} || @{$R->{recommendations}}>256;
    my %Seen;
    for my $Row (@{$R->{recommendations}}) {
        my $D=$Row->{result};
        if (($Row->{status} || '') ne 'ready' || ref $D ne 'HASH' || ($D->{status} || '') ne 'draft' || ($P{Action} || '') ne 'allow' || ($D->{action} || '') ne 'allow') {push @{$Out->{Issues}},'Recommendation is incomplete or requested action is unsupported.';next}
        die "Recommendation flow mismatch.\n" if !$Expected{_tuple($D)} || !_uuid($D->{device_id});
        my $CI=$Mapped{$Devices->{$D->{device_id}} || ''};
        if (!$CI) {push @{$Out->{Issues}},'Recommendation lacks authorized caller-scoped CMDB enrichment.';next}
        my $Hash=$S->Digest($D);die "Duplicate recommendation.\n" if $Seen{$Hash}++;
        push @{$Out->{Plans}},{PlanID=>$Hash,Target=>{Application=>'tessera',ObjectType=>'CMDB',Namespace=>$CI->{namespace},Class=>$CI->{Class},ConfigItemID=>$CI->{ConfigItemID}},
            Platform=>$CI->{platform},Context=>dclone($CI->{context}),Draft=>dclone($D)};
    }
    push @{$Out->{Issues}},'No executable vendor intents.' if !@{$Out->{Plans}};
    return $Out;
}
1;
