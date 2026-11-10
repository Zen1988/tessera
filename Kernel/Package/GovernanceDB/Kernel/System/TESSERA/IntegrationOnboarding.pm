package Kernel::System::TESSERA::IntegrationOnboarding;
use strict;
use warnings;
use JSON::PP ();
use Storable qw(dclone);
use Kernel::System::TESSERA::IntegrationAuth;
our @ObjectDependencies=qw(Kernel::System::User Kernel::System::Group Kernel::System::DB Kernel::System::GenericInterface::Webservice);
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Authorized {
    my ($S,$U)=@_;return if !$U;
    my %D=$Kernel::OM->Get('Kernel::System::User')->GetUserData(UserID=>$U);
    return ($D{ValidID} || 0)==1 && $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(UserID=>$U,GroupName=>'admin',Type=>'rw');
}
sub NavisRoutes {return {
    GraphGet=>{Method=>'GET',Path=>'/v1/graph-builds/:BuildID/graph',Parameters=>['BuildID']},
    Trace=>{Method=>'POST',Path=>'/v1/traces',Parameters=>[]},
    RecommendationsGet=>{Method=>'GET',Path=>'/v1/trace-sessions/:CallerSessionID/recommendations',Parameters=>['CallerSessionID']},
    Ingest=>{Method=>'POST',Path=>'/v1/ingestions',Parameters=>[],SuccessStatus=>202},
}}
sub Validate {
    my ($S,$C)=@_;die "Invalid connection.\n" if ref $C ne 'HASH';
    die "Unsupported connection property.\n" if grep {!/\A(?:Preset|Origin|InstanceID|Authentication|Routes|Timeout|ConnectionUID)\z/} keys %$C;
    die "Invalid connection identity.\n" if defined $C->{ConnectionUID} && $C->{ConnectionUID}!~/\A[a-f0-9]{40}\z/;
    die "Invalid preset.\n" if ($C->{Preset} || '')!~/\A(?:Navis|Generic)\z/;
    my $A=Kernel::System::TESSERA::IntegrationAuth->new();my $U=$A->URL($C->{Origin});
    die "HTTPS origin required.\n" if $U->path ne '' && $U->path ne '/';
    $C->{Origin}=~s{/$}{};
    $C->{Timeout}=30; # Prevent native legacy-config migration from rewriting auth.
    $A->Validate($C->{Authentication});
    die "Navis token endpoint must belong to this installation.\n" if $C->{Preset} eq 'Navis' && $C->{Authentication}{TokenURL} ne $C->{Origin}.'/nauth/token';
    die "Invalid instance reference.\n" if defined $C->{InstanceID} && (ref $C->{InstanceID} || length($C->{InstanceID})>255 || $C->{InstanceID}=~/[\x00-\x1f]/);
    $C->{Routes}=NavisRoutes() if $C->{Preset} eq 'Navis';
    my $Routes=$C->{Routes};die "Operation routes required.\n" if ref $Routes ne 'HASH' || !keys %$Routes || keys(%$Routes)>32;
    for my $Name (keys %$Routes) {
        my $R=$Routes->{$Name};
        die "Invalid operation route.\n" if $Name!~/\A[A-Za-z][A-Za-z0-9]{0,63}\z/ || ref $R ne 'HASH'
            || ($R->{Method} || '')!~/\A(?:GET|POST)\z/ || ($R->{Path} || '')!~m{\A/(?!/)[A-Za-z0-9_/:.~-]+\z}
            || $R->{Path}=~m{(?:\A|/)\.\.?(/|\z)} || ref $R->{Parameters} ne 'ARRAY';
        die "Unsupported route property.\n" if grep {!/\A(?:Method|Path|Parameters|SuccessStatus)\z/} keys %$R;
        die "Invalid expected response status.\n" if defined $R->{SuccessStatus} && $R->{SuccessStatus}!~/\A20[0-9]\z/;
        my @Names=$R->{Path}=~/:([A-Za-z][A-Za-z0-9]*)/g;
        die "Invalid path parameters.\n" if join(',',sort @Names) ne join(',',sort @{$R->{Parameters}}) || grep {ref $_ || !/\A[A-Za-z][A-Za-z0-9]*\z/} @{$R->{Parameters}};
    }
    return $C;
}
sub View {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});
    my $W=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
    if ($P{ID}) {
        my $D=$W->WebserviceGet(ID=>$P{ID});
        die "Managed connection required.\n" if !$D || ($D->{Config}{Requester}{Transport}{Type} || '') ne 'HTTP::TESSERAIntegration';
        return $D;
    }
    my $List=$W->WebserviceList(Valid=>0) || {};my @Out;
    for my $ID (sort {$a<=>$b} keys %$List) {my $D=$W->WebserviceGet(ID=>$ID);push @Out,{ID=>$ID,Name=>$D->{Name},ValidID=>$D->{ValidID}} if ($D->{Config}{Requester}{Transport}{Type} || '') eq 'HTTP::TESSERAIntegration'}
    return \@Out;
}
sub Test {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});
    my $C=$S->Validate(dclone($P{Connection}));
    my $A=$S->{Auth} || Kernel::System::TESSERA::IntegrationAuth->new();
    $A->Token(Profile=>$C->{Authentication},Identity=>'onboarding-test',Invalidate=>1);
    return {Success=>1};
}
sub Save {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});
    my $C=$S->Validate(dclone($P{Connection}));
    die "Invalid connection name.\n" if !defined $P{Name} || ref $P{Name} || $P{Name}!~/\A[^\x00-\x1f]{1,100}\z/;
    $S->Test(%P) if $P{Enabled};
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Onboarding busy.\n" if !$DB->Prepare(SQL=>q{SELECT GET_LOCK('tessera_integration_onboarding',5)});
    my @Lock=$DB->FetchrowArray();die "Onboarding busy.\n" if !$Lock[0];
    my ($ID,$Error);eval {
        my $W=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice');
        my $Existing=$P{ID}?$S->View(UserID=>$P{UserID},ID=>$P{ID}):undef;
        require Crypt::PRNG;
        $C->{ConnectionUID}=$Existing?$Existing->{Config}{Requester}{Transport}{Config}{ConnectionUID}:unpack('H*',Crypt::PRNG::random_bytes(20));
        my $List=$W->WebserviceList(Valid=>0) || {};
        die "Name already exists; select its managed connection.\n" if grep {$List->{$_} eq $P{Name} && (!$Existing || $_!=$P{ID})} keys %$List;
        my %I=map {$_=>{Type=>'TESSERA::Request'}} keys %{$C->{Routes}};
        my $Config={Debugger=>{DebugThreshold=>'error',TestMode=>0},Requester=>{Invoker=>\%I,Transport=>{Type=>'HTTP::TESSERAIntegration',Config=>$C}}};
        my %Args=(Name=>$P{Name},Config=>$Config,ValidID=>$P{Enabled}?1:2,UserID=>$P{UserID});
        if ($Existing) {$ID=$P{ID};die "Service update failed.\n" if !$W->WebserviceUpdate(ID=>$ID,%Args)}
        else {$ID=$W->WebserviceAdd(%Args);die "Service creation failed.\n" if !$ID}
        1;
    } or $Error=$@ || 'Service save failed.';
    $DB->Prepare(SQL=>q{SELECT RELEASE_LOCK('tessera_integration_onboarding')});$DB->FetchrowArray();
    die $Error if $Error;return $ID;
}
1;
