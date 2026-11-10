package Kernel::GenericInterface::Invoker::NetXMS::Base;
use strict;
use warnings;
use Storable qw(dclone);
use Scalar::Util qw(refaddr blessed);
our $ObjectManagerDisabled = 1;

# Explicit read-only API profile. No remote NXSL, URLs, credentials or mutations
# can be supplied by an automation script.
my %Spec = (
    ServerInfo => ['/v1/server-info', []],
    Status => ['/v1/status', []],
    Objects => ['/v1/objects', []],
    ObjectGet => ['/v1/objects/:ObjectID', ['ObjectID']],
    Alarms => ['/v1/alarms', [], ['rootObject']],
    AlarmGet => ['/v1/alarms/:AlarmID', ['AlarmID']],
    CurrentValues => ['/v1/objects/:ObjectID/data-collection/current-values', ['ObjectID']],
    DataCollection => ['/v1/objects/:ObjectID/data-collection/configuration', ['ObjectID']],
    History => ['/v1/objects/:ObjectID/data-collection/:DCIID/history', ['ObjectID','DCIID','timeFrom','timeTo'], ['maxRows']],
);
sub new {
    my ($Type,%P)=@_;
    return {Success=>0,ErrorMessage=>'Missing debugger.'} if !$P{DebuggerObject};
    return bless {%P},$Type;
}
sub _Error { return {Success=>0,ErrorMessage=>$_[1],Data=>{Outcome=>'UNKNOWN'}} }
sub _Bounded {
    my ($Value)=@_;
    my ($Nodes,$Bytes,%Active)=(0,0);
    my $Walk;
    $Walk=sub {
        my ($V,$Depth)=@_;
        die if ++$Nodes>50000 || $Depth>32;
        if (!ref $V) { $Bytes+=defined $V ? length($V) : 0; die if $Bytes>4194304; return }
        return if blessed($V) && blessed($V)=~/\A(?:JSON::PP::Boolean|JSON::XS::Boolean|Types::Serialiser::Boolean)\z/;
        die if ref $V ne 'HASH' && ref $V ne 'ARRAY';
        my $Address=refaddr($V); die if $Active{$Address};
        local $Active{$Address}=1;
        if (ref $V eq 'HASH') { for my $K (keys %$V) { $Walk->($K,$Depth+1); $Walk->($V->{$K},$Depth+1) } }
        else { $Walk->($_,$Depth+1) for @$V }
    };
    my $OK=eval { $Walk->($Value,0); 1 }; undef $Walk; return $OK;
}
sub PrepareRequest {
    my ($Self,%P)=@_;
    delete $Self->{Prepared};
    my $S=$Self->can('_Spec') ? $Self->_Spec() : $Spec{$Self->_Operation};
    return $Self->_Error('Unsupported NetXMS operation.') if !$S;
    my $D=$P{Data};
    return $Self->_Error('NetXMS input must be a bounded object.') if ref $D ne 'HASH' || !_Bounded($D);
    my %Allowed=map {$_=>1} (@{$S->[1]},@{$S->[2] || []});
    return $Self->_Error('Unsupported NetXMS input.') if grep {!$Allowed{$_}} keys %$D;
    for my $K (@{$S->[1]}) { return $Self->_Error('Missing NetXMS identifier or time range.') if !exists $D->{$K} }
    for my $K (keys %$D) {
        return $Self->_Error('Invalid NetXMS numeric parameter.') if !defined $D->{$K} || ref $D->{$K} || $D->{$K}!~/\A[0-9]{1,12}\z/;
        return $Self->_Error('NetXMS identifiers and limits must be positive.') if $K!~/\Atime/ && !$D->{$K};
    }
    my $Out=dclone($D);
    if ($Self->_Operation eq 'History') {
        $Out->{maxRows}//=1000;
        return $Self->_Error('NetXMS history requires an ordered range and at most 1000 rows.')
            if $D->{timeTo}<=$D->{timeFrom} || $Out->{maxRows}>1000;
    }
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$Self->{WebserviceID});
    return $Self->_Error('NetXMS web service is unavailable.') if ref $WS ne 'HASH' || ($WS->{ValidID} || 0)!=1;
    my $R=$WS->{Config}{Requester}; my $T=$R->{Transport}; my $C=$T->{Config};
    return $Self->_Error('NetXMS requires configured HTTPS REST transport.') if ($T->{Type} || '') ne 'HTTP::REST'
        || ($C->{Host} || '')!~m{\Ahttps://[A-Za-z0-9.-]+(?::[0-9]+)?/?\z};
    return $Self->_Error('NetXMS requires explicit TLS verification and a bounded timeout.')
        if ($C->{SSL}{SSLVerifyHostname} || '') ne 'Yes' || ($C->{SSL}{SSLVerifyMode} || '') ne 'Yes'
        || ($C->{Timeout} || '')!~/\A[0-9]+\z/ || $C->{Timeout}<1 || $C->{Timeout}>60;
    my $Route=$C->{InvokerControllerMapping}{$Self->{Invoker}};
    return $Self->_Error('NetXMS controller must match its read-only API profile.')
        if ($Route->{Command} || '') ne ($Self->can('_Method') ? $Self->_Method() : 'GET') || ($Route->{Controller} || '') ne $S->[0];
    my $I=$R->{Invoker}{$Self->{Invoker}};
    for my $K (qw(MappingInbound MappingOutbound)) {
        return $Self->_Error('NetXMS requires empty mappings.') if ref $I->{$K} eq 'HASH' && keys %{$I->{$K}};
    }
    $Self->{Prepared}=dclone($Out);
    return {Success=>1,Data=>$Self->can('_WireData') ? $Self->_WireData($Out) : $Out};
}
sub HandleResponse {
    my ($Self,%P)=@_;
    return $Self->_Error('NetXMS request failed; observation is unknown.') if !$P{ResponseSuccess};
    return $Self->_Error('NetXMS response has no prepared request.') if !exists $Self->{Prepared};
    my $D=$P{Data};
    return $Self->_Error('Invalid or oversized NetXMS response.') if (ref $D ne 'HASH' && ref $D ne 'ARRAY') || !_Bounded($D);
    return $Self->_Error('NetXMS detail response must be an object.')
        if $Self->_Operation =~ /\A(?:ObjectGet|AlarmGet|ServerInfo|Status)\z/ && ref $D ne 'HASH';
    return $Self->_Error('NetXMS returned an error response.') if ref $D eq 'HASH' && (exists $D->{error} || exists $D->{reason});
    # Preserve version-specific fields; do not manufacture normalized topology,
    # freshness, health or collection completeness from an HTTP success.
    return {Success=>1,Data=>{Source=>'NetXMS',WebserviceID=>$Self->{WebserviceID},
        Operation=>$Self->_Operation,RetrievedAt=>time(),Request=>dclone($Self->{Prepared}),
        Completeness=>'UNVERIFIED',Response=>dclone($D)}};
}
1;
