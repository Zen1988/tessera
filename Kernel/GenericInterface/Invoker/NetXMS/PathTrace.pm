package Kernel::GenericInterface::Invoker::NetXMS::PathTrace;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::NetXMS::Base);
use JSON::PP ();
use Scalar::Util qw(blessed);
our $ObjectManagerDisabled=1;
sub _Operation { 'PathTrace' }
sub _Method { 'POST' }
sub _TraceMethod { 'traceRoute' }
sub _Spec { ['/v1/objects/:SourceID/execute-script', ['SourceID','DestinationID']] }
sub PrepareRequest {
    my ($Self,%P)=@_;
    my $R=$Self->SUPER::PrepareRequest(%P);
    return $R if !$R->{Success};
    if (grep {$Self->{Prepared}{$_}>4294967295} qw(SourceID DestinationID)) {
        delete $Self->{Prepared};
        return $Self->_Error('NetXMS object identifiers exceed uint32 range.');
    }
    return $R;
}
sub _WireData {
    my ($Self,$D)=@_;
    my $Method=$Self->_TraceMethod;
    my $Destination=0+$D->{DestinationID};
    # Numeric identifiers and the fixed method are the only interpolated data.
    # The source is the API's authorized object context, never a global script.
    my $Script=qq{destination = FindObject($Destination);\npath = \$node.$Method(destination);\n};
    $Script .= <<'NXSL';
if (path == null) return null;
result = new JsonObject();
result.set("sourceId", $node.id);
result.set("destinationId", destination.id);
result.set("collectedAt", time());
result.setBoolean("isComplete", path.isComplete);
result.set("sourceAddress", path.sourceAddress);
result.set("hopCount", path.hopCount);
hops = new JsonArray();
if (path.hopCount > 256) return null;
for (hop : path.hops) {
  item = new JsonObject();
  item.set("nodeId", hop.nodeId);
  item.set("type", hop.type);
  item.set("ifIndex", hop.ifIndex);
  item.set("name", hop.name);
  item.set("nextHop", hop.nextHop);
  item.set("route", hop.route);
  hops.append(item);
}
result.set("hops", hops);
return result.serialize();
NXSL
    return {SourceID=>$D->{SourceID},script=>$Script,stream=>JSON::PP::false,resultAsMap=>JSON::PP::false};
}
sub HandleResponse {
    my ($Self,%P)=@_;
    my $R=$Self->SUPER::HandleResponse(%P);
    return $R if !$R->{Success};
    my $Raw=$P{Data};
    return $Self->_Error('NetXMS did not return a synchronous path result.') if ref $Raw ne 'HASH' || ref $Raw->{result} || !defined $Raw->{result};
    my $Path=eval {JSON::PP->new->decode($Raw->{result})};
    return $Self->_Error('Invalid NetXMS path identity or structure.') if ref $Path ne 'HASH'
        || !Kernel::GenericInterface::Invoker::NetXMS::Base::_Bounded($Path)
        || !defined $Path->{sourceId} || ref $Path->{sourceId} || $Path->{sourceId} ne $Self->{Prepared}{SourceID}
        || !defined $Path->{destinationId} || ref $Path->{destinationId} || $Path->{destinationId} ne $Self->{Prepared}{DestinationID}
        || ref $Path->{hops} ne 'ARRAY' || @{$Path->{hops}}>256
        || !defined $Path->{hopCount} || ref $Path->{hopCount} || $Path->{hopCount}!~/\A[0-9]+\z/ || $Path->{hopCount}!=@{$Path->{hops}}
        || !JSON::PP::is_bool($Path->{isComplete})
        || !defined $Path->{collectedAt} || ref $Path->{collectedAt} || $Path->{collectedAt}!~/\A[0-9]+\z/;
    for my $H (@{$Path->{hops}}) {
        return $Self->_Error('Invalid NetXMS hop.') if ref $H ne 'HASH'
            || !defined $H->{nodeId} || ref $H->{nodeId} || $H->{nodeId}!~/\A[0-9]+\z/
            || !defined $H->{ifIndex} || ref $H->{ifIndex} || $H->{ifIndex}!~/\A[0-9]+\z/
            || !defined $H->{type} || ref $H->{type} || $H->{type}!~/\A(?:ROUTE|L2_LINK|VPN|PROXY|DESTINATION)\z/;
    }
    $R->{Data}{Path}=$Path;
    $R->{Data}{Completeness}=$Path->{isComplete} ? 'COMPLETE' : 'INCOMPLETE';
    return $R;
}
1;
