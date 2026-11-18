package Kernel::System::TESSERA::Utilities;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use MIME::Base64 qw(encode_base64 decode_base64);
use URI;
use Kernel::System::TESSERA::IntegrationOnboarding;
our @ObjectDependencies = qw(Kernel::Config Kernel::System::DB Kernel::System::CustomerUser Kernel::System::Main Kernel::System::Ticket Kernel::System::ITSMConfigItem Kernel::System::ITSMConfigItem::CustomerEntitlement Kernel::System::TESSERA::CustomerNetworkSimulation);
my $Key = 'TESSERA::Utilities::Catalogue';
sub new { bless {}, shift }
sub _json { JSON::PP->new->canonical->utf8 }
sub Authorized { Kernel::System::TESSERA::IntegrationOnboarding->new()->Authorized($_[1]) }
sub _customer {
    my ($S,$Login)=@_; return if !defined $Login || ref $Login || !length $Login;
    my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$Login);
    return if ($U{ValidID} || 0)!=1; return \%U;
}
sub _defaults {
    my ($S)=@_;
    my @Rows=(
        {ID=>'ticket-search',Name=>'Advanced ticket search',Description=>'Find tickets using detailed search filters.',Type=>'Internal',Handler=>'TicketSearch',Audience=>'all',Users=>[],Enabled=>1,Workplace=>0,Order=>10,Parameters=>{}},
        {ID=>'network-simulation',Name=>'Network simulation',Description=>'Explore permitted CMDB endpoints and analyze network paths.',Type=>'Internal',Handler=>'NetworkSimulation',Audience=>'all',Users=>[],Enabled=>1,Workplace=>0,Order=>20,Parameters=>{}},
    );
    # Preserve administrator-configured native toolbox links on first save.
    my $Tiles=$Kernel::OM->Get('Kernel::Config')->Get('CustomerDashboard::Tiles') || {};
    for my $Tile (sort keys %$Tiles) {
        next if ($Tiles->{$Tile}{Module} || '') ne 'Kernel::Output::HTML::CustomerDashboard::TileToolBox';
        my $C=$Tiles->{$Tile}{Config} || {}; my %Titles=reverse %{$C->{Titles} || {}};my %Images=reverse %{$C->{Images} || {}};
        my $Links=$C->{Links} || {};
        my $VendorDefaults=keys(%$Links)==3 && ($Links->{'https://www.otobo.io'} || 0)==1
            && ($Links->{'https://www.openstreetmap.org'} || 0)==2 && ($Links->{'https://www.wikipedia.org'} || 0)==3
            && ($Titles{1} || '') eq 'OTOBO' && ($Titles{2} || '') eq 'OpenStreetMap' && ($Titles{3} || '') eq 'Wikipedia'
            && ($Images{1} || '')=~/sample_otobo\.png\z/ && ($Images{2} || '')=~/sample_openstreetmap\.png\z/ && ($Images{3} || '')=~/sample_wikipedia\.png\z/;
        next if $VendorDefaults;
        for my $URL (sort keys %{$C->{Links} || {}}) {
            next if !eval {$S->_url($URL);1};
            my $ID='legacy-'.substr(sha256_hex($Tile.'|'.$URL),0,24);
            my $Image=$Images{$C->{Links}{$URL}} || '';
            $Image='' if $Image!~m{\A/(?!/)[A-Za-z0-9_./-]+\.(?:png|jpe?g|gif|svg)\z}i || $Image=~m{(?:\A|/)\.\.(?:/|\z)};
            push @Rows,{ID=>$ID,Name=>$Titles{$C->{Links}{$URL}} || URI->new($URL)->host,Description=>'Imported Workplace tool',Type=>'External',URL=>$URL,LegacyIcon=>$Image,Audience=>'all',Users=>[],Enabled=>1,Workplace=>1,Order=>100,Parameters=>{}};
        }
    }
    return {Version=>1,Tools=>\@Rows};
}
sub _read {
    my ($S)=@_;my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Utilities storage is unavailable.\n" if !$DB->Prepare(SQL=>'SELECT data_value FROM system_data WHERE data_key = ?',Bind=>[\$Key]);
    my @Row=$DB->FetchrowArray();my $Raw=$Row[0];my $Doc=defined $Raw?eval {_json()->decode($Raw)}:$S->_defaults();
    die "Utilities catalogue is invalid.\n" if ref $Doc ne 'HASH' || ($Doc->{Version} || 0)!=1 || ref $Doc->{Tools} ne 'ARRAY' || @{$Doc->{Tools}}>100;
    return ($Doc,sha256_hex(_json()->encode($Doc)),defined $Raw);
}
sub AdminView {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});
    my ($D,$Revision)=$S->_read();return {Tools=>$D->{Tools},Revision=>$Revision,Handlers=>$S->Handlers()};
}
sub Handlers {
    my ($S)=@_;my %H=(TicketSearch=>{Name=>'Advanced ticket search'},NetworkSimulation=>{Name=>'Network simulation'});
    my $Registered=$Kernel::OM->Get('Kernel::Config')->Get('TESSERA::Utilities::Handlers') || {};
    for my $ID (keys %$Registered) {
        next if exists $H{$ID} || $ID!~/\A[A-Za-z][A-Za-z0-9]{0,63}\z/;
        my $R=$Registered->{$ID};next if ref $R ne 'HASH' || ($R->{Module} || '')!~/\AKernel::System::[A-Za-z0-9_:]+\z/;
        $H{$ID}={Name=>$R->{Name} || $ID,Module=>$R->{Module}};
    }
    return \%H;
}
sub _url {
    my ($S,$Text)=@_;die "Enter an HTTPS destination without credentials or fragments.\n" if !defined $Text || ref $Text || length($Text)>2048 || $Text=~/[\x00-\x20\x7f\\]/;
    my $U=URI->new($Text);die "Enter an HTTPS destination without credentials or fragments.\n" if lc($U->scheme || '') ne 'https' || !$U->host || defined $U->userinfo || defined $U->fragment;
    my @Q=$U->query_form;while (@Q) {my ($N,$V)=splice @Q,0,2;die "Credentials must not be stored in launch URLs.\n" if $N=~/(?:password|passwd|token|secret|session|authorization)/i}
    return $U;
}
sub _validate {
    my ($S,$R)=@_;die "Invalid utility.\n" if ref $R ne 'HASH';
    die "Enter a name and description within the length limits.\n" if !defined $R->{Name} || ref $R->{Name} || $R->{Name}!~/\S/ || length($R->{Name})>100 || ref $R->{Description} || length($R->{Description} || '')>500;
    die "Invalid tool type.\n" if ($R->{Type} || '')!~/\A(?:External|Internal)\z/;
    $S->_url($R->{URL}) if $R->{Type} eq 'External';
    die "Select a registered internal tool.\n" if $R->{Type} eq 'Internal' && !exists $S->Handlers()->{$R->{Handler} || ''};
    die "Choose an explicit audience.\n" if ($R->{Audience} || '')!~/\A(?:none|all|users)\z/;
    die "Invalid customer audience.\n" if ref $R->{Users} ne 'ARRAY' || @{$R->{Users}}>500;
    my %Seen;for my $Login (@{$R->{Users}}) {die "Choose exact active customer logins.\n" if !defined $Login || ref $Login || $Login eq '*' || $Login=~/[\x00-\x20\x7f]/ || !$S->_customer($Login)}
    $R->{Users}=[grep {!$Seen{$_}++} @{$R->{Users}}];
    die "Invalid display order.\n" if !defined $R->{Order} || $R->{Order}!~/\A[0-9]{1,5}\z/;
    die "Invalid parameter mapping.\n" if ref $R->{Parameters} ne 'HASH' || keys(%{$R->{Parameters}})>20;
    for my $Name (keys %{$R->{Parameters}}) {
        my $M=$R->{Parameters}{$Name};
        die "Invalid parameter mapping.\n" if $Name!~/\A[A-Za-z][A-Za-z0-9_.-]{0,63}\z/ || $Name=~/(?:password|passwd|token|secret|session|authorization)/i || ref $M ne 'HASH'
            || grep {!/\A(?:Source|Value|Required)\z/} keys %$M;
        die "Choose a supported parameter source.\n" if ($M->{Source} || '')!~/\A(?:Literal|CustomerUserLogin|CustomerUserEmail|TicketNumber|ConfigItemNumber)\z/;
        die "Invalid literal parameter.\n" if ref $M->{Value} || length($M->{Value} || '')>500;
        $M->{Required}=$M->{Required}?1:0;
    }
    for (qw(Enabled Workplace)) {$R->{$_}=$R->{$_}?1:0}
    return $R;
}
sub _icon {
    my ($S,$Bytes)=@_;die "Choose a PNG or JPEG image up to 256 KB.\n" if !length($Bytes) || length($Bytes)>262144;
    require Kernel::System::TESSERA::CustomerProfilePhoto;
    my ($W,$H,$Type)=Kernel::System::TESSERA::CustomerProfilePhoto->new()->_Dimensions($Bytes);
    die "Choose a PNG or JPEG up to 1024 by 1024 pixels.\n" if !$W || !$H || $W>1024 || $H>1024;
    require GD;my $In=eval {$Type eq 'PNG'?GD::Image->newFromPngData($Bytes,1):GD::Image->newFromJpegData($Bytes,1)};
    die "The image could not be decoded.\n" if !$In;
    my $Out=GD::Image->newTrueColor(96,96);$Out->alphaBlending(0);$Out->saveAlpha(1);my $Clear=$Out->colorAllocateAlpha(255,255,255,127);$Out->filledRectangle(0,0,95,95,$Clear);
    my $Scale=96/($W>$H?$W:$H);my ($NW,$NH)=(int($W*$Scale)||1,int($H*$Scale)||1);
    $Out->copyResampled($In,int((96-$NW)/2),int((96-$NH)/2),0,0,$NW,$NH,$W,$H);
    return encode_base64($Out->png,'');
}
sub Save {
    my ($S,%P)=@_;die "Administrator access required.\n" if !$S->Authorized($P{UserID});
    my $R=$S->_validate($P{Tool});my $Icon=defined $P{IconContent}?$S->_icon($P{IconContent}):undef;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Utilities are busy.\n" if !$DB->Prepare(SQL=>q{SELECT GET_LOCK('tessera_utilities',5)});my @Lock=$DB->FetchrowArray();die "Utilities are busy.\n" if !$Lock[0];
    my ($ID,$Error);eval {
        my ($D,$Rev,$Exists)=$S->_read();die "Catalogue changed; reload before saving.\n" if ($P{Revision} || '') ne $Rev;
        $ID=$R->{ID} || '';my ($Old)=grep {$_->{ID} eq $ID} @{$D->{Tools}};
        die "Utility no longer exists.\n" if length($ID) && !$Old;
        die "Catalogue is full.\n" if !$Old && @{$D->{Tools}}>=100;
        $ID ||= 'tool-'.substr(sha256_hex($Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>64)),0,32);
        die "Built-in handler cannot be replaced.\n" if $Old && ($ID eq 'ticket-search' || $ID eq 'network-simulation') && ($R->{Type} ne 'Internal' || $R->{Handler} ne $Old->{Handler});
        my %New=map {$_=>$R->{$_}} qw(Name Description Type URL Handler Audience Users Enabled Workplace Order Parameters);
        $New{ID}=$ID;$New{Icon}=defined $Icon?$Icon:$P{RemoveIcon}?'':$Old?($Old->{Icon} || ''):'';
        $New{LegacyIcon}=defined $Icon || $P{RemoveIcon}?'':$Old?($Old->{LegacyIcon} || ''):'';
        $D->{Tools}=[map {$_->{ID} eq $ID?\%New:$_} @{$D->{Tools}}];push @{$D->{Tools}},\%New if !$Old;
        my $Raw=_json()->encode($D);die "Catalogue is too large.\n" if length($Raw)>8*1024*1024;
        my $OK=$Exists?$DB->Do(SQL=>'UPDATE system_data SET data_value = ?, change_time = current_timestamp, change_by = ? WHERE data_key = ?',Bind=>[\$Raw,\$P{UserID},\$Key])
            :$DB->Do(SQL=>'INSERT INTO system_data (data_key,data_value,create_time,create_by,change_time,change_by) VALUES (?,?,current_timestamp,?,current_timestamp,?)',Bind=>[\$Key,\$Raw,\$P{UserID},\$P{UserID}]);
        die "Utility could not be saved.\n" if !$OK;1;
    } or $Error=$@ || 'Utility could not be saved.';
    $DB->Prepare(SQL=>q{SELECT RELEASE_LOCK('tessera_utilities')});$DB->FetchrowArray();die $Error if $Error;return $ID;
}
sub _allowed {
    my ($S,$R,$Login)=@_;return if !$R->{Enabled};
    return if ($R->{Audience} || '') ne 'all' && !(($R->{Audience} || '') eq 'users' && grep {$_ eq $Login} @{$R->{Users} || []});
    if ($R->{Type} eq 'Internal') {
        my $H=$R->{Handler} || '';my $Reg=$S->Handlers()->{$H};return if !$Reg;
        my $Modules=$Kernel::OM->Get('Kernel::Config')->Get('CustomerFrontend::Module') || {};
        if ($H eq 'NetworkSimulation') {return if !$Modules->{CustomerNetworkSimulation};return $Kernel::OM->Get('Kernel::System::TESSERA::CustomerNetworkSimulation')->AccessCheck(CustomerUserID=>$Login)}
        return $Modules->{CustomerTicketSearch}?1:0 if $H eq 'TicketSearch';
        my $Allowed=eval {$Kernel::OM->Get($Reg->{Module})->AccessCheck(CustomerUserID=>$Login)};return $Allowed?1:0;
    }
    return eval {$S->_url($R->{URL});1};
}
sub List {
    my ($S,%P)=@_;return [] if !$S->_customer($P{CustomerUserID});my ($D)=$S->_read();
    return [map {{ID=>$_->{ID},Name=>$_->{Name},Description=>$_->{Description},External=>$_->{Type} eq 'External'?1:0,HasIcon=>length($_->{Icon} || '')?1:0,LegacyIcon=>$_->{LegacyIcon} || '',Workplace=>$_->{Workplace}}}
        sort {($a->{Order} || 0)<=>($b->{Order} || 0) || $a->{Name} cmp $b->{Name}}
        grep {(!$P{Workplace} || $_->{Workplace}) && $S->_allowed($_,$P{CustomerUserID})} @{$D->{Tools}}];
}
sub _find {
    my ($S,%P)=@_;die "Utility unavailable.\n" if !$S->_customer($P{CustomerUserID});my ($D)=$S->_read();
    my @R=grep {$_->{ID} eq ($P{ID} || '')} @{$D->{Tools}};die "Utility unavailable.\n" if @R!=1 || !$S->_allowed($R[0],$P{CustomerUserID});return $R[0];
}
sub Icon {
    my ($S,%P)=@_;my $R=$S->_find(%P);return decode_base64($R->{Icon}) if $R->{Icon};return;
}
sub Launch {
    my ($S,%P)=@_;my $R=$S->_find(%P);my $U=$S->_customer($P{CustomerUserID});my %Context=(CustomerUserLogin=>$P{CustomerUserID},CustomerUserEmail=>$U->{UserEmail});
    # Object IDs are selectors only; live permissions resolve context before use.
    for my $ID (qw(TicketID ConfigItemID)) {die "Invalid context.\n" if defined $P{$ID} && length($P{$ID}) && $P{$ID}!~/\A[1-9][0-9]*\z/}
    if ($P{TicketID}) {
        my $T=$Kernel::OM->Get('Kernel::System::Ticket');die "Context unavailable.\n" if !$T->TicketCustomerPermission(Type=>'ro',TicketID=>$P{TicketID},UserID=>$P{CustomerUserID});
        my %T=$T->TicketGet(TicketID=>$P{TicketID});$Context{TicketNumber}=$T{TicketNumber};
    }
    if ($P{ConfigItemID}) {
        die "Context unavailable.\n" if !$Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->ConfigItemDetailAccessCheck(CustomerUserID=>$P{CustomerUserID},ConfigItemID=>$P{ConfigItemID},LogNo=>1);
        my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(ConfigItemID=>$P{ConfigItemID});$Context{ConfigItemNumber}=$CI->{Number};
    }
    my %Params;for my $Name (keys %{$R->{Parameters} || {}}) {
        my $M=$R->{Parameters}{$Name};my $V=$M->{Source} eq 'Literal'?$M->{Value}:$Context{$M->{Source}};
        die "This tool needs additional context. Open it from an authorized ticket or asset.\n" if (!defined $V || !length $V) && $M->{Required};
        $Params{$Name}=$V if defined $V && length $V;
    }
    if ($R->{Type} eq 'External') {
        my $URL=$S->_url($R->{URL});my (@Existing,@Query);@Existing=$URL->query_form;
        while (@Existing) {my ($Name,$Value)=splice @Existing,0,2;push @Query,$Name,$Value if !exists $Params{$Name}}
        $URL->query_form(@Query,map {($_,$Params{$_})} sort keys %Params) if keys %Params;
        return {External=>1,URL=>$URL->as_string};
    }
    my $Handler=$R->{Handler};my $Action;
    if ($Handler eq 'TicketSearch') {$Action='CustomerTicketSearch'}
    elsif ($Handler eq 'NetworkSimulation') {$Action='CustomerNetworkSimulation'}
    else {
        my $Reg=$S->Handlers()->{$Handler};my $Dest=$Kernel::OM->Get($Reg->{Module})->Launch(CustomerUserID=>$P{CustomerUserID},Parameters=>\%Params);
        die "Internal tool returned an invalid destination.\n" if ref $Dest ne 'HASH' || ($Dest->{Action} || '')!~/\ACustomer[A-Za-z0-9]+\z/;
        $Action=$Dest->{Action};%Params=%{$Dest->{Parameters} || {}};
    }
    die "Internal tool is not installed.\n" if !$Kernel::OM->Get('Kernel::Config')->Get('CustomerFrontend::Module')->{$Action};
    die "Reserved internal parameter.\n" if grep {$_!~/\A[A-Za-z][A-Za-z0-9_]*\z/ || /\A(?:Action|Subaction|ChallengeToken|SessionID|CustomerUserID|UserID)\z/i || ref $Params{$_}} keys %Params;
    my $Query=URI->new('');$Query->query_form(Action=>$Action,%Params);my $OP=$Query->query;$OP=~s/&/;/g;return {External=>0,OP=>$OP};
}
1;
