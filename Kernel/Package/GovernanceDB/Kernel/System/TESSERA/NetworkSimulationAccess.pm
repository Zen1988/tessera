package Kernel::System::TESSERA::NetworkSimulationAccess;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Kernel::System::TESSERA::IntegrationOnboarding;
use Kernel::System::TESSERA::NavisPlan;
our @ObjectDependencies=qw(Kernel::System::SysConfig Kernel::System::DB Kernel::System::CustomerUser Kernel::System::ITSMConfigItem::CustomerEntitlement Kernel::System::GovernanceObject Kernel::System::GenericInterface::Webservice Kernel::System::User Kernel::System::Group);
my $Prefix='TESSERA::CustomerNetworkSimulation::';
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Authorized {return Kernel::System::TESSERA::IntegrationOnboarding->new()->Authorized($_[1])}
sub _settings {
    my ($S)=@_;my $Sys=$Kernel::OM->Get('Kernel::System::SysConfig');my (%Values,%Overrides);
    for my $Key (qw(Enabled AllowedCustomerUsers Bindings)) {
        my %Setting=$Sys->SettingGet(Name=>$Prefix.$Key,Deployed=>1);
        die "Simulation settings unavailable.\n" if !%Setting;
        $Values{$Key}=$Setting{EffectiveValue};
        my $Loaded=$Sys->GlobalEffectiveValueGet(SettingName=>$Prefix.$Key);
        my ($Current,$Stored)=($Loaded,$Setting{EffectiveValue});
        ($Current,$Stored)=($Current?1:0,$Stored?1:0) if $Key eq 'Enabled';
        $Overrides{$Key}=JSON::PP->new->canonical->encode($Current) ne JSON::PP->new->canonical->encode($Stored) ? 'override':'';
    }
    return (\%Values,\%Overrides);
}
sub _environments {
    my ($S)=@_;my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @IDs=$GO->GovernanceObjectSearch(Classes=>['Environment'],ZTSMStatuss=>['Active'],Result=>'ARRAY',Limit=>129,UserID=>$S->{ActorID});
    die "Environment catalog exceeds budget.\n" if @IDs>128;my @Envs;
    for my $ID (@IDs) {my $E=$GO->GovernanceObjectGet(GovernanceObjectID=>$ID);push @Envs,{ID=>"$ID",Name=>$E->{Name}} if $E && ($E->{Class} || '') eq 'Environment' && ($E->{ZTSMStatus} || '') eq 'Active'}
    return [sort {$a->{Name} cmp $b->{Name}} @Envs];
}
sub View {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});$S->{ActorID}=$P{UserID};
    my ($Values,$Overrides)=$S->_settings();my $Bindings=eval {JSON::PP->new->decode($Values->{Bindings} || '{}')};
    die "Simulation binding configuration is invalid.\n" if ref $Bindings ne 'HASH' || ref $Values->{AllowedCustomerUsers} ne 'ARRAY';
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');my @Services;
    for my $Service (@{Kernel::System::TESSERA::IntegrationOnboarding->new()->View(UserID=>$P{UserID})}) {
        my $Record=$WS->WebserviceGet(ID=>$Service->{ID});
        push @Services,$Service if ($Record->{ValidID} || 0)==1 && ($Record->{Config}{Requester}{Transport}{Config}{Preset} || '') eq 'Navis';
    }
    my @Rows;
    for my $E (@{$S->_environments()}) {my $Binding=$Bindings->{$E->{ID}} || {};die "Invalid environment binding.\n" if ref $Binding ne 'HASH';
        push @Rows,{%$E,map {$_=>$Binding->{$_} || ''} qw(WebserviceID BuildID Namespace)};}
    my %Active=map {$_->{ID}=>1} @Rows;my @Inactive=sort grep {!$Active{$_}} keys %$Bindings;
    my @Users;
    for my $Login (@{$Values->{AllowedCustomerUsers}}) {
        my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$Login);
        my $Read=$Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->CustomerHasCMDBReadRole(CustomerUserID=>$Login);
        push @Users,{Login=>$Login,Valid=>($U{ValidID} || 0)==1?1:0,CMDBRead=>$Read?1:0};
    }
    return {Enabled=>$Values->{Enabled}?1:0,AllowedCustomerUsers=>$Values->{AllowedCustomerUsers},Users=>\@Users,Environments=>\@Rows,
        Services=>\@Services,InactiveBindings=>\@Inactive,HasOverrides=>(grep {length $_} values %$Overrides)?1:0,
        Revision=>sha256_hex(JSON::PP->new->canonical->utf8->encode($Values))};
}
sub _set {
    my ($S,$Values,$U)=@_;my @Settings=map {{Name=>$Prefix.$_,EffectiveValue=>$Values->{$_},IsValid=>1}} sort keys %$Values;
    my $Sys=$Kernel::OM->Get('Kernel::System::SysConfig');
    die "Could not deploy simulation settings.\n" if !$Sys->SettingsSet(UserID=>$U,Comments=>'Network simulation access configuration',Settings=>\@Settings);
    for my $Key (keys %$Values) {my %Setting=$Sys->SettingGet(Name=>$Prefix.$Key,Deployed=>1);
        my ($Actual,$Expected)=($Setting{EffectiveValue},$Values->{$Key});($Actual,$Expected)=($Actual?1:0,$Expected?1:0) if $Key eq 'Enabled';
        die "Simulation settings were not fully deployed.\n" if JSON::PP->new->canonical->encode($Actual) ne JSON::PP->new->canonical->encode($Expected);
        my $Loaded=$Sys->GlobalEffectiveValueGet(SettingName=>$Prefix.$Key);$Loaded=$Loaded?1:0 if $Key eq 'Enabled';
        die "Active configuration does not match deployment.\n" if JSON::PP->new->canonical->encode($Loaded) ne JSON::PP->new->canonical->encode($Expected);}
}
sub Save {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});$S->{ActorID}=$P{UserID};
    die "Invalid access configuration.\n" if ref $P{Users} ne 'ARRAY' || @{$P{Users}}>500 || ref $P{Bindings} ne 'HASH' || keys(%{$P{Bindings}})>128;
    my (%Seen,@Users);
    for my $Login (@{$P{Users}}) {
        die "Enter valid exact customer account logins.\n" if !defined $Login || ref $Login || $Login!~/\A[^\x00-\x1f\x7f]{1,200}\z/ || $Login=~/^\s|\s$/ || $Login eq '*';
        my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$Login);
        die "An active customer account is required.\n" if ($U{ValidID} || 0)!=1 || (defined $U{UserLogin} && $U{UserLogin} ne $Login);
        push @Users,$Login if !$Seen{$Login}++;
    }
    my %Environment=map {$_->{ID}=>1} @{$S->_environments()};my %Bindings;
    for my $ID (keys %{$P{Bindings}}) {
        my $B=$P{Bindings}{$ID};
        die "Select an active environment and valid Navis binding.\n" if !$Environment{$ID} || ref $B ne 'HASH'
            || grep {!/\A(?:WebserviceID|BuildID|Namespace)\z/} keys %$B;
        die "Complete the environment binding.\n" if ($B->{WebserviceID} || '')!~/\A[1-9][0-9]*\z/
            || !Kernel::System::TESSERA::NavisPlan::_uuid($B->{BuildID}) || !Kernel::System::TESSERA::NavisPlan::_text($B->{Namespace});
        my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$B->{WebserviceID});
        die "Choose an enabled Navis integration.\n" if !$WS || ($WS->{ValidID} || 0)!=1 || ($WS->{Config}{Requester}{Transport}{Type} || '') ne 'HTTP::TESSERAIntegration'
            || ($WS->{Config}{Requester}{Transport}{Config}{Preset} || '') ne 'Navis';
        $Bindings{$ID}={map {$_=>$B->{$_}} qw(WebserviceID BuildID Namespace)};
    }
    die "Configure at least one environment before enabling simulation.\n" if $P{Enabled} && !keys %Bindings;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Simulation access configuration is busy.\n" if !$DB->Prepare(SQL=>q{SELECT GET_LOCK('tessera_simulation_access',5)});my @L=$DB->FetchrowArray();die "Simulation access configuration is busy.\n" if !$L[0];
    my ($Error,$Began);eval {
        my $View=$S->View(UserID=>$P{UserID});
        die "Configuration changed; reload before saving.\n" if ($P{Revision} || '') ne $View->{Revision};
        die "Settings are overridden in a configuration file.\n" if $View->{HasOverrides};
        # Native SettingsSet may deploy only successful updates. Disable first,
        # verify each phase, and enable last so partial failures cannot grant access.
        $Began=1;$S->_set({Enabled=>0},$P{UserID});
        $S->_set({AllowedCustomerUsers=>\@Users,Bindings=>JSON::PP->new->canonical->encode(\%Bindings)},$P{UserID});
        $S->_set({Enabled=>1},$P{UserID}) if $P{Enabled};
        1;
    } or $Error=$@ || 'Could not save simulation access.';
    eval {$S->_set({Enabled=>0},$P{UserID})} if $Error && $Began;
    $DB->Prepare(SQL=>q{SELECT RELEASE_LOCK('tessera_simulation_access')});$DB->FetchrowArray();die $Error if $Error;return 1;
}
1;
