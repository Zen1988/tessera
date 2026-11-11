package Kernel::System::TESSERA::IntegrationAuth;
use strict;
use warnings;
use JSON::PP ();
use MIME::Base64 qw(encode_base64);
use Digest::SHA qw(sha256_hex);
use URI ();
use URI::Escape qw(uri_escape_utf8);
use Encode qw(decode FB_CROAK);
our $ObjectManagerDisabled=1;
# Process-local only: credentials and tokens never enter native token repositories.
my %Tokens;
sub new { my ($T,%P)=@_; bless \%P,$T }
sub _form { my $V=uri_escape_utf8($_[0],q{^A-Za-z0-9\-._~}); $V=~s/%20/+/g; return $V }
sub Validate {
    my ($S,$C)=@_;
    die "Invalid authentication profile.\n" if ref $C ne 'HASH';
    if (($C->{Provider} || '') eq 'StaticBearer') {
        die "Invalid bearer secret reference.\n" if grep {!/\A(?:Provider|SecretName)\z/} keys %$C;
        die "Invalid bearer secret reference.\n" if !defined $C->{SecretName} || ref $C->{SecretName}
            || $C->{SecretName}!~/\A[A-Za-z0-9][A-Za-z0-9_-]{0,127}\z/;
        return 1;
    }
    die "Invalid authentication profile.\n" if ($C->{Provider} || '') ne 'ClientCredentialsBasic';
    die "Unsupported authentication property.\n" if grep {!/\A(?:Provider|TokenURL|ClientID|SecretName|Scope)\z/} keys %$C;
    for my $K (qw(TokenURL ClientID SecretName)) {
        die "Incomplete authentication profile.\n" if !defined $C->{$K} || ref $C->{$K} || !length($C->{$K}) || length($C->{$K})>2048 || $C->{$K}=~/[\x00-\x1f\x7f]/;
    }
    $S->URL($C->{TokenURL});
    die "Invalid secret reference.\n" if $C->{SecretName}!~/\A[A-Za-z0-9][A-Za-z0-9_-]{0,127}\z/;
    die "Invalid scope.\n" if defined $C->{Scope} && (ref $C->{Scope} || length($C->{Scope})>3000 || $C->{Scope}!~/\A[\x21\x23-\x5b\x5d-\x7e]+(?: [\x21\x23-\x5b\x5d-\x7e]+)*\z/);
    return 1;
}
sub URL {
    my ($S,$URL)=@_;die "Invalid HTTPS destination.\n" if !defined $URL || ref $URL || length($URL)>4096 || $URL=~/[\x00-\x20\x7f\\]/;
    my $U=URI->new($URL);
    die "Invalid HTTPS destination.\n" if $U->scheme ne 'https' || !$U->host || defined $U->userinfo || defined $U->fragment || defined $U->query;
    return $U;
}
sub HTTP {
    my ($S,%P)=@_;
    return $S->{HTTP}->(%P) if $S->{HTTP};
    require LWP::UserAgent;require HTTP::Request;
    my $UA=LWP::UserAgent->new(timeout=>30,max_size=>4194304,requests_redirectable=>[],protocols_allowed=>['https']);
    $UA->ssl_opts(verify_hostname=>1,SSL_verify_mode=>1);
    my $Q=HTTP::Request->new($P{Method},$P{URL});
    $Q->header(%{$P{Headers}});$Q->content($P{Body}) if defined $P{Body};
    my $R=$UA->request($Q);
    die "Integration transport unavailable.\n" if $R->header('Client-Aborted') || length($R->content)>4194304;
    return {Status=>$R->code,Body=>$R->content};
}
sub _Secret {
    my ($S,$Name)=@_;return $S->{Secret}->($Name) if $S->{Secret};
    require Kernel::System::TESSERA::Secrets;
    return decode('UTF-8',Kernel::System::TESSERA::Secrets::Read($Name),FB_CROAK);
}
sub Token {
    my ($S,%P)=@_;my $C=$P{Profile};$S->Validate($C);
    my $Secret=$S->_Secret($C->{SecretName});
    die "Credential unavailable.\n" if !defined $Secret || ref $Secret || !length($Secret) || length($Secret)>4096 || $Secret=~/[\x00\r\n]/;
    if ($C->{Provider} eq 'StaticBearer') {
        die "Invalid bearer credential.\n" if $Secret!~/\A[A-Za-z0-9\-._~+\/]+=*\z/;
        return $Secret; # Read on every request: mounted token rotation is immediate.
    }
    my $Key=sha256_hex(JSON::PP->new->canonical->utf8->encode([$P{Identity},$C,$Secret]));
    my $Now=$S->{Clock}?$S->{Clock}->():time();
    delete $Tokens{$_} for grep {$Tokens{$_}{Until}<=$Now} keys %Tokens;
    delete $Tokens{$Key} if $P{Invalidate};
    return $Tokens{$Key}{Token} if $Tokens{$Key} && $Tokens{$Key}{Until}>$Now;
    my $Body='grant_type=client_credentials';$Body.='&scope='._form($C->{Scope}) if defined $C->{Scope};
    die "Token request too large.\n" if length($Body)>4096;
    my $R=$S->HTTP(Method=>'POST',URL=>$C->{TokenURL},Headers=>{
        Authorization=>'Basic '.encode_base64(_form($C->{ClientID}).':'._form($Secret),''),
        'Content-Type'=>'application/x-www-form-urlencoded',Accept=>'application/json'},Body=>$Body);
    die "Token exchange failed.\n" if ref $R ne 'HASH' || ($R->{Status} || 0)!=200 || length($R->{Body} || '')>65536;
    my $D=eval {JSON::PP->new->utf8->decode($R->{Body})};
    die "Invalid token response.\n" if ref $D ne 'HASH' || !defined $D->{access_token} || ref $D->{access_token}
        || $D->{access_token}!~/\A[A-Za-z0-9\-._~+\/]+=*\z/ || length($D->{access_token})>16384
        || lc($D->{token_type} || '') ne 'bearer' || ($D->{expires_in} || '')!~/\A[0-9]{1,8}\z/ || $D->{expires_in}<1;
    if (exists $D->{scope}) {
        die "Invalid granted scope.\n" if ref $D->{scope} || !defined $D->{scope} || $D->{scope}!~/\A[\x21\x23-\x5b\x5d-\x7e]+(?: [\x21\x23-\x5b\x5d-\x7e]+)*\z/;
        my %Granted=map {$_=>1} split / /,$D->{scope};
        die "Required scope not granted.\n" if defined $C->{Scope} && grep {!$Granted{$_}} split / /,$C->{Scope};
    }
    my $TTL=$D->{expires_in};my $Skew=$TTL>60?30:($TTL/2);
    # Bound process cache growth and never retain expired entries.
    %Tokens=() if keys(%Tokens)>=128;
    $Tokens{$Key}={Token=>$D->{access_token},Until=>$Now+$TTL-$Skew};
    return $D->{access_token};
}
1;
