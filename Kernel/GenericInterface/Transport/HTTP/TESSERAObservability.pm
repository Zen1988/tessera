package Kernel::GenericInterface::Transport::HTTP::TESSERAObservability;
use strict;
use warnings;
use parent 'Kernel::GenericInterface::Transport::HTTP::REST';
our $ObjectManagerDisabled=1;
# Inherit native routing, maximum body length and JSON parsing. This provider
# has explicit HTTP statuses so Alertmanager retries transient failures.
sub ProviderGenerateResponse {
    my ($S,%P)=@_;
    my $D=$P{Data};
    if (($S->{HTTPError}||'') eq '413') {$P{Success}=1;$D={HTTPStatus=>413,Body=>{Error=>'Request exceeds provider body limit'}}}
    elsif ($S->{HTTPError}) {$P{Success}=1;$D={HTTPStatus=>400,Body=>{Error=>'Invalid provider route or JSON request'}}}
    my ($Code,$Body)=(503,{Error=>'Provider request failed'});
    if ($P{Success} && ref $D eq 'HASH' && ($D->{HTTPStatus}||'')=~/\A(?:200|400|403|404|405|413|429|503)\z/ && ref $D->{Body} eq 'HASH') {
        ($Code,$Body)=@{$D}{qw(HTTPStatus Body)};
    }
    my $JSON=$Kernel::OM->Get('Kernel::System::JSON')->Encode(Data=>$Body);
    $Kernel::OM->Get('Kernel::System::Encode')->EncodeOutput(\$JSON);
    my $Response=Plack::Response->new($Code,[
        'Content-Type'=>'application/json; charset=UTF-8','Cache-Control'=>'no-store',
        'X-Content-Type-Options'=>'nosniff','Connection'=>'close'], $JSON);
    die Kernel::System::Web::Exception->new(PlackResponse=>$Response);
}
1;
