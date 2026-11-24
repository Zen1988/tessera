#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Encode ();
use Kernel::System::ObjectManager;
require '/opt/tessera-release012-recovery/upgrade-cache.pl';
require '/usr/local/lib/tessera/package-inventory.pl';
require '/usr/local/lib/tessera/package-reconcile.pl';
$|=1;
my $Root='/opt/tessera-release012-recovery';
my $Bundle='/opt/tessera/upgrade-bundle';
my $RecoveryKey='TESSERA::Recovery::release-1795491815';
my ($Stage,$Attempt,$Gate,$Owned,$JournalRaw,$DB,$Inventory,$Meta,$Package);
sub Bytes {
    open my $FH,'<:raw',$_[0] or die "Recovery input unavailable.\n";
    local $/;return <$FH>;
}
sub JSONFile {JSON::PP->new->utf8->decode(Bytes($_[0]))}
sub DirectRows {
    my ($SQL,@Values)=@_;
    my @Bind=map {\$_} @Values;
    die "Recovery metadata query failed.\n" if !$DB->Prepare(SQL=>$SQL,Bind=>\@Bind);
    my @Rows;while(my @Row=$DB->FetchrowArray()){push @Rows,[@Row]}
    return @Rows;
}
sub Record {
    my ($Phase)=@_;
    $Attempt->{stage}=$Phase;
    my $Text=JSON::PP->new->canonical->encode($Attempt);
    my $Handle=$Kernel::OM->Get('Kernel::System::DB')->Connect();
    my $N=$Handle->do('UPDATE system_data SET data_value=?,change_time=current_timestamp,change_by=1 WHERE data_key=?',
        undef,$Text,$RecoveryKey);
    die "Recovery record unavailable.\n" if !defined $N || $N!=1;
    print "recovery_stage=$Phase\n";
}
sub CheckOwned {
    die "Release ownership changed.\n" if $Gate->_Read() ne $Owned;
}
sub PreflightInventory {
    my %Wanted=map {$_->{name}=>$_} @{$Inventory->{packages} || []};
    die "Invalid target inventory.\n" if !%Wanted || keys(%Wanted)!=@{$Inventory->{packages}};
    my %Seen;
    for my $Row (DirectRows(q{SELECT name,version FROM package_repository WHERE install_status='installed'})) {
        my ($Name,$Version)=@$Row;
        die "Extra or ambiguous installed package.\n" if !$Wanted{$Name} || $Seen{$Name}++;
        my $Expected=$Wanted{$Name};
        die "Unsupported installed version.\n" if $Version!~/\A[0-9]+(?:\.[0-9]+)*\z/;
        my @A=split /\./,$Version;my @B=split /\./,$Expected->{version};
        for my $I (0..(@A>@B?$#A:$#B)) {
            die "Package downgrade is not allowed.\n" if ($A[$I]||0)>($B[$I]||0);
            last if ($A[$I]||0)<($B[$I]||0);
        }
        die "Existing package artifact differs; review required.\n"
            if $Version eq $Expected->{version}
            && InstalledArtifactHash($DB,$Name,$Version) ne $Expected->{package_sha256};
    }
    die "Expected installed package is missing.\n" if keys(%Seen)!=keys(%Wanted);
}
sub ValidateLabel {
    my ($Entry,$String)=@_;
    die "Unexpected LabelPrint artifact.\n" if $Entry->{version} ne '11.1.1'
        || $Entry->{package_sha256} ne '8546fd85ffd059aadd48afaf8a2c5a0987017c6da6558685eb5ec6d17ae328f9';
    my %Structure=$Package->PackageParse(String=>$String);
    die "Invalid LabelPrint structure.\n" if ($Structure{Name}{Content} || '') ne 'ITSMConfigItemLabelPrint'
        || ($Structure{Version}{Content} || '') ne '11.1.1'
        || ref $Structure{Filelist} ne 'ARRAY' || !@{$Structure{Filelist}};
    die "LabelPrint repair cannot replay hooks/schema.\n"
        if grep {(/^Code|^Database/) && (ref $Structure{$_} eq 'ARRAY'
            ? scalar @{$Structure{$_}} : $Structure{$_})} keys %Structure;
    return \%Structure;
}
sub VerifyLabelFiles {
    my ($Structure)=@_;
    require MIME::Base64;
    for my $F (@{$Structure->{Filelist} || []}) {
        my $Path=$F->{Location};
        die "Unsafe LabelPrint file.\n" if !$Path || $Path=~m{(?:\A/|(?:\A|/)\.\.(?:/|\z)|\\)};
        my $Expected=$F->{Content};
        $Expected=MIME::Base64::decode_base64($Expected) if ($F->{Encode} || '') eq 'Base64';
        die "LabelPrint file mismatch.\n" if sha256_hex(Bytes("/opt/otobo/$Path")) ne sha256_hex($Expected);
    }
}
my $OK=eval {
    $Stage='preflight';
    die "Wrong recovery environment.\n" if ($ENV{TESSERA_UPGRADE_QUIESCED} || '') ne '1'
        || ($ENV{TESSERA_TEST_NO_BACKUP} || '') ne '1' || !-w '/opt/otobo/Kernel/System';
    local $Kernel::OM=Kernel::System::ObjectManager->new();
    UpgradeCacheConfigure($Kernel::OM->Get('Kernel::System::Cache'));
    $DB=$Kernel::OM->Get('Kernel::System::DB');
    $Gate=$Kernel::OM->Get('Kernel::System::TESSERA::ReleaseUpgrade');
    $Meta=JSONFile('/opt/tessera/dependencies/release.json');
    die "Unexpected image release.\n" if ($Meta->{version} || '') ne '0.1.12'
        || ($Meta->{package_sha256} || '') ne '7911eff6b39b594f95d036386caab604356120945413a0fe2650c3ec35352aff';
    my %AllowedOrigins=map {$_=>1} @{$Meta->{upgrade_from} || []};
    die "Image does not allow original upgrade path.\n" if !$AllowedOrigins{'0.1.8'};
    die "Bundle metadata differs from image.\n" if JSON::PP->new->canonical->encode($Meta)
        ne JSON::PP->new->canonical->encode(JSONFile("$Bundle/release.json"));
    system('/usr/bin/python3','/usr/local/lib/tessera/check-package-bundle.py',$Bundle)==0
        or die "Invalid original bundle.\n";
    $Inventory=JSONFile('/opt/tessera/dependencies/package-modules.json');
    die "Inventory differs from bundle.\n" if JSON::PP->new->canonical->encode($Inventory)
        ne JSON::PP->new->canonical->encode(JSONFile("$Bundle/package-modules.json"));
    PreflightInventory();
    my $Before=$Gate->_Read();
    my $State=$Gate->_Decode($Before);
    die "Unexpected interrupted release.\n" if !$State || $State->{phase} ne 'UPGRADING'
        || $State->{version} ne '0.1.12' || $State->{hash} ne $Meta->{package_sha256}
        || $State->{from} ne '0.1.8' || $Gate->_Version() ne '0.1.8';
    die "Original Base artifact differs.\n" if $Gate->_InstalledHash('0.1.8')
        ne '9c9a4554d098204190ebc3b22d51348756b342e9021655e089e9b3ee4093ea55';
    my @J=DirectRows(q{SELECT data_key,data_value FROM system_data WHERE data_key LIKE 'TESSERA::PackageUpgrade::%'});
    die "Unexpected package journals.\n" if @J!=1 || $J[0][0] ne 'TESSERA::PackageUpgrade::ITSMConfigItemLabelPrint';
    $JournalRaw=$J[0][1];
    my $Journal=JSON::PP->new->decode($JournalRaw);
    my ($Entry)=grep {$_->{name} eq 'ITSMConfigItemLabelPrint'} @{$Inventory->{packages}};
    die "Journal differs from intended artifact.\n" if !$Entry || $Journal->{phase} ne 'UPGRADING'
        || $Journal->{version} ne $Entry->{version} || $Journal->{hash} ne $Entry->{package_sha256};
    die "Installed LabelPrint differs from bundle.\n"
        if InstalledArtifactHash($DB,'ITSMConfigItemLabelPrint','11.1.1') ne $Entry->{package_sha256};
    $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
    my $LabelBytes=Bytes("$Bundle/packages/$Entry->{package_sha256}.opm");
    die "LabelPrint payload hash mismatch.\n" if sha256_hex($LabelBytes) ne $Entry->{package_sha256};
    my $LabelString=Encode::decode('UTF-8',$LabelBytes,Encode::FB_CROAK());
    my $Label=ValidateLabel($Entry,$LabelString);
    my $Framework=JSONFile("$Root/framework-11.1.1.json");
    for my $Path (keys %{$Framework->{files}}) {
        die "Native framework source differs.\n" if sha256_hex(Bytes("/opt/otobo/$Path")) ne $Framework->{files}{$Path};
    }
    my @Packet=DirectRows('SELECT @@max_allowed_packet');
    print "db_packet_bytes=$Packet[0][0]\n";
    die "Application DB packet limit below64MiB.\n" if $Packet[0][0]<67108864;
    my @Setting=DirectRows('SELECT id FROM sysconfig_default WHERE name=?',
        'DynamicFieldScreens::ObjectTypes###ITSMChangeManagement');
    die "Existing setting is missing or ambiguous.\n" if @Setting!=1;
    my $SettingID=$Setting[0][0];
    die "Recovery already attempted; inspect before retry.\n" if DirectRows('SELECT data_key FROM system_data WHERE data_key=?',$RecoveryKey);
    my $Bootstrap=$Kernel::OM->Get('Kernel::System::GovernanceDB::Bootstrap');
    $Bootstrap->_OTOBO111CompatibilityPreflight();
    $Bootstrap->_OTOBO111AddonPreflight();
    system('/usr/bin/perl','/usr/local/lib/tessera/runtime-check.pl','smoke')==0
        or die "Target dependency check failed.\n";
    my $ConfigHash=sha256_hex(Bytes('/opt/otobo/Kernel/Config.pm'));
    if (($ENV{TESSERA_RECOVERY_CHECK_ONLY} || '') eq '1') {
        print "preflight=ok;no-migration-no-package-journal-change\n";
        exit 0;
    }
    # A unique recovery receipt and release CAS retain all evidence. Neither is
    # cleared on error. The original package journal remains until repair verifies.
    $Attempt={stage=>'CLAIMED',original_release=>$Before,original_package_journal=>$JournalRaw,
        backup=>'owner-waived-test-server',setting_id=>$SettingID};
    my $Handle=$DB->Connect();
    my $N=$Handle->do('INSERT INTO system_data (data_key,data_value,create_time,create_by,change_time,change_by) VALUES (?,?,current_timestamp,1,current_timestamp,1)',
        undef,$RecoveryKey,JSON::PP->new->canonical->encode($Attempt));
    die "Recovery claim conflicted.\n" if !defined $N || $N!=1;
    $State->{owner}=$Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>40);
    $State->{recovery}='release-1795491815';
    $Owned=$Gate->_Write($Before,$Gate->_Encode($State));
    die "Base changed during recovery claim.\n" if $Gate->_Version() ne '0.1.8'
        || $Gate->_InstalledHash('0.1.8') ne '9c9a4554d098204190ebc3b22d51348756b342e9021655e089e9b3ee4093ea55';
    Record('FRAMEWORK');
    # Use pinned official native task implementations/order. The Docker cache
    # override-removal task must not edit an externally mounted Config.pm.
    for my $Task (@{$Framework->{tasks}}) {
        CheckOwned();
        if ($Task eq 'RemoveRedisOverride') {
            print "framework_task=RemoveRedisOverride;external-config-preserved\n";next;
        }
        UpgradeCacheConfigure($Kernel::OM->Get('Kernel::System::Cache'));
        Record('FRAMEWORK_'.$Task);
        my $Class='scripts::DBUpdateTo11_1::'.$Task;
        die "Native migration task unavailable.\n" if !$Kernel::OM->Get('Kernel::System::Main')->Require($Class);
        die "Native framework migration failed.\n" if !$Kernel::OM->Create($Class)->Run();
    }
    die "Mounted Config.pm changed.\n" if sha256_hex(Bytes('/opt/otobo/Kernel/Config.pm')) ne $ConfigHash;
    UpgradeCacheConfigure($Kernel::OM->Get('Kernel::System::Cache'));
    $DB=$Kernel::OM->Get('Kernel::System::DB');
    $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
    die "Base changed during framework migration.\n" if $Gate->_Version() ne '0.1.8';
    CheckOwned();Record('LABELPRINT_REPAIR');
    die "Native LabelPrint reinstall failed.\n" if !$Package->PackageReinstall(String=>$LabelString);
    VerifyLabelFiles($Label);
    die "LabelPrint registry changed.\n" if InstalledArtifactHash($DB,'ITSMConfigItemLabelPrint','11.1.1') ne $Entry->{package_sha256};
    @Setting=DirectRows('SELECT id FROM sysconfig_default WHERE name=?','DynamicFieldScreens::ObjectTypes###ITSMChangeManagement');
    die "Existing setting identity changed.\n" if @Setting!=1 || $Setting[0][0]!=$SettingID;
    CheckOwned();Record('LABELPRINT_VERIFIED');
    $N=$DB->Connect()->do('DELETE FROM system_data WHERE data_key=? AND data_value=?',undef,
        'TESSERA::PackageUpgrade::ITSMConfigItemLabelPrint',$JournalRaw);
    die "Package journal changed; not completed.\n" if !defined $N || $N!=1;
    CheckOwned();Record('RECONCILING');
    die "Pending package reconciliation failed.\n" if !ReconcilePackages($Inventory,$DB,$Package,"$Bundle/packages");
    $Package->EventHandlerTransaction() if $Package->can('EventHandlerTransaction');
    CheckInventory($Inventory,$DB,$Package);
    die "Final package mismatch.\n" if $Gate->_Version() ne '0.1.12' || $Gate->_InstalledHash('0.1.12') ne $Meta->{package_sha256};
    $State->{phase}='CONFIGURING';
    $Owned=$Gate->_Write($Owned,$Gate->_Encode($State));
    Record('CONFIGURING');
    system('/usr/bin/python3',"$Root/configure.py")==0 or die "Configuration rebuild failed.\n";
    for my $Command (qw(Maint::Cache::Delete Maint::Loader::CacheCleanup Maint::Loader::CacheGenerate Maint::Translations::Deploy)) {
        die "Final cache/assets deployment failed.\n" if $Kernel::OM->Get(
            'Kernel::System::Console::InterfaceConsole')->Run($Command,'--no-ansi')!=0;
    }
    CheckOwned();CheckInventory($Inventory,$DB,$Package);
    die "Mounted Config.pm changed.\n" if sha256_hex(Bytes('/opt/otobo/Kernel/Config.pm')) ne $ConfigHash;
    die "Execution history schema incomplete.\n" if !$DB->Prepare(SQL=>'SELECT request_data,dispatch_data FROM ztsm_async_execution WHERE 1=0');
    $DB->FetchrowArray();
    system('/usr/bin/perl','/usr/local/lib/tessera/runtime-check.pl','smoke')==0 or die "Final dependencies failed.\n";
    $State->{phase}='READY';
    $Owned=$Gate->_Write($Owned,$Gate->_Encode($State));
    $Gate->Check(Version=>'0.1.12',Hash=>$Meta->{package_sha256});
    Record('READY');
    print "recovery=READY-0.1.12;original-setting-id-preserved\n";
    1;
};
if (!$OK) {
    # No automatic replay, raw credential-bearing exceptions or phase resets.
    print "recovery=stopped;stage=",($Attempt?$Attempt->{stage}:'PREFLIGHT'),"\n";
    my $Error=$@ || '';
    if ($Error=~/\A([A-Za-z0-9 .;_-]{1,140})\n/) {print "reason=$1\n"}
    else {print "reason=unclassified;exception-withheld\n"}
    exit 1;
}
1;
