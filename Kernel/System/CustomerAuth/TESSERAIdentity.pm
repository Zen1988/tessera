package Kernel::System::CustomerAuth::TESSERAIdentity;
use strict;
use warnings;
our @ObjectDependencies=qw(Kernel::System::TESSERA::DirectorySync Kernel::System::CustomerUser);
sub new {my ($T,%P)=@_;bless \%P,$T}
sub _SSO {
    my ($S)=@_;
    require Kernel::System::CustomerAuth::OpenIDConnect;
    return $S->{SSO} ||= Kernel::System::CustomerAuth::OpenIDConnect->new();
}
sub GetOption {
    my ($S,%P)=@_;return 0 if $P{What} ne 'PreAuth';
    my $D=$Kernel::OM->Get('Kernel::System::TESSERA::DirectorySync')->_Read();
    return ($D->{Config}{Provider} || '') eq 'OpenIDConnect' ? 1:0;
}
sub PreAuth {my ($S,%P)=@_;return $S->_SSO()->PreAuth(%P) if $S->GetOption(What=>'PreAuth');return}
sub PostAuth {my ($S,%P)=@_;return $S->_SSO()->PostAuth(%P) if $S->GetOption(What=>'PreAuth');return}
sub Logout {my ($S,%P)=@_;return $S->_SSO()->Logout(%P) if $S->GetOption(What=>'PreAuth');return}
sub Auth {
    my ($S,%P)=@_;my $Sync=$Kernel::OM->Get('Kernel::System::TESSERA::DirectorySync');
    return if !$Sync->RoutingReady();
    my $D=$Sync->_Read();
    if (($D->{Config}{Provider} || '') eq 'OpenIDConnect') {
        # Native OIDC validates issuer, signed claims, state and nonce. A raw
        # submitted login is never treated as proof of external authentication.
        my $Login=$S->_SSO()->Auth(%P);return if !$Login;
        my $E=$Sync->ExternalUser($Login);return $E ? $E->{Login}:undef;
    }
    my $E=$Sync->ExternalUser($P{User});
    if ($E) {
        return if $E->{Provider} ne 'LDAP';
        my $OK=eval {$Sync->_LDAP()->Authenticate($D->{Config},$Sync->_Password($D),$E->{Login},$P{Pw})};
        return $OK ? $E->{Login}:undef; # Never fall through to local password.
    }
    require Kernel::System::CustomerAuth::DB;
    return Kernel::System::CustomerAuth::DB->new(Count=>'')->Auth(%P);
}
1;
