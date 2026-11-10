package Kernel::GenericInterface::Transport::HTTP::TESSERAIntegration;
use strict;
use warnings;
use JSON::PP ();
use Storable qw(dclone);
use URI::Escape qw(uri_escape_utf8);
use Kernel::System::TESSERA::IntegrationAuth;
use Kernel::System::TESSERA::IntegrationOnboarding;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub RequesterPerformRequest {
    my ($S,%P)=@_;my $Result;
    my $OK=eval {
        my $C=dclone($S->{TransportConfig}{Config});
        Kernel::System::TESSERA::IntegrationOnboarding->new()->Validate($C);
        my $R=$C->{Routes}{$P{Operation}};die if !$R || ref $P{Data} ne 'HASH';
        my $D=dclone($P{Data});my $Path=$R->{Path};
        for my $K (@{$R->{Parameters}}) {
            my $V=delete $D->{$K};die if !defined $V || ref $V || $V!~/\A[A-Za-z0-9_-]{1,200}\z/;
            $Path=~s/:\Q$K\E(?=\/|\z)/uri_escape_utf8($V)/ge;
        }
        die if $Path=~/:/ || ($R->{Method} eq 'GET' && keys %$D);
        my $A=$S->{Auth} || Kernel::System::TESSERA::IntegrationAuth->new();
        my $Identity=$C->{ConnectionUID} || JSON::PP->new->canonical->encode($C);
        my $Body=$R->{Method} eq 'POST'?JSON::PP->new->canonical->utf8->encode($D):undef;
        die if defined $Body && length($Body)>1048576;
        my $Response;
        for my $Attempt (0,1) {
            my $Token=$A->Token(Profile=>$C->{Authentication},Identity=>$Identity,Invalidate=>$Attempt);
            $Response=$A->HTTP(Method=>$R->{Method},URL=>$C->{Origin}.$Path,Headers=>{
                Authorization=>'Bearer '.$Token,Accept=>'application/json','Content-Type'=>'application/json'},Body=>$Body);
            last unless $Attempt==0 && $R->{Method} eq 'GET' && ($Response->{Status} || 0)==401;
        }
        die if ($Response->{Status} || 0)!=($R->{SuccessStatus} || 200) || length($Response->{Body} || '')>4194304;
        my $Data=JSON::PP->new->utf8->decode($Response->{Body});die if ref $Data ne 'HASH' && ref $Data ne 'ARRAY';
        $Result={Success=>1,Data=>$Data};1;
    };
    # Never hand raw HTTP diagnostics, credentials or token bodies to GI debug.
    return $OK?$Result:{Success=>0,ErrorMessage=>'Integration request failed or outcome is uncertain; reconcile mutating requests before retry.'};
}
1;
