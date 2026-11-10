package Kernel::GenericInterface::Invoker::TESSERA::Request;
use strict;
use warnings;
use JSON::PP ();
use Storable qw(dclone);
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub PrepareRequest {
    my ($S,%P)=@_;my $Raw=eval {JSON::PP->new->utf8->encode($P{Data})};
    return {Success=>0,ErrorMessage=>'Bounded integration object required.'} if ref $P{Data} ne 'HASH' || !defined $Raw || length($Raw)>1048576;
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$S->{WebserviceID});
    return {Success=>0,ErrorMessage=>'Enabled managed integration required.'} if !$WS || ($WS->{ValidID} || 0)!=1
        || ($WS->{Config}{Requester}{Transport}{Type} || '') ne 'HTTP::TESSERAIntegration'
        || !$WS->{Config}{Requester}{Transport}{Config}{Routes}{$S->{Invoker}};
    return {Success=>1,Data=>dclone($P{Data})};
}
sub HandleResponse {my ($S,%P)=@_;return $P{ResponseSuccess}?{Success=>1,Data=>$P{Data}}:{Success=>0,ErrorMessage=>'Integration failed; reconcile any uncertain mutation.'}}
1;
