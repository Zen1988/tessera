use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Storable qw(dclone);

sub SourceMethod {
    my ($Path, $Name) = @_;
    open my $FH, '<', $Path or die $!;
    my $Source = do {local $/; <$FH>};
    my ($Method) = $Source =~ /(^sub \Q$Name\E \{.*?)(?=^=head2|^sub |\z)/ms;
    die "Missing native $Name" if !$Method;
    return $Method;
}
# Execute the native reconciliation and native cache read/write logic with
# a small DB fixture. These methods match the reviewed OTOBO11.1.1 source.
for my $Name (qw(Configure Get Set Delete)) {
    my $Method = SourceMethod('Kernel/System/Cache.pm', $Name);
    eval "package UpgradeNativeCache; $Method;1" or die $@;
}
for my $Name (qw(ConfigurationXML2DB ConfigurationList _DefaultSettingAddBulk)) {
    my $Method = SourceMethod('Kernel/System/SysConfig.pm', $Name);
    eval "package UpgradeNativeSysConfig; use File::Basename qw(basename fileparse); $Method;1" or die $@;
}
my $List = SourceMethod('Kernel/System/SysConfig/DB.pm','DefaultSettingList');
eval "package UpgradeDB; $List;1" or die $@;
require './container/ubuntu2604/image/upgrade-cache.pl';
{
    package UpgradeNativeSysConfig;
    sub IsHashRefWithData {ref $_[0] eq 'HASH' && scalar keys %{$_[0]}}
    sub SettingEffectiveValueGet {my ($S,%P)=@_;$P{Value}}
    sub SettingEffectiveValueCheck {return (Success=>1)}
    package UpgradeOM;
    sub Get {
        my ($Self,$Name)=@_;
        return $Self->{Cache} if $Name eq 'Kernel::System::Cache';
        return $Self->{DB} if $Name eq 'Kernel::System::SysConfig::DB' || $Name eq 'Kernel::System::DB';
        return $Self;
    }
    sub DirectoryRead {('Fixture.xml')}
    sub MD5sum {'fixture-md5'}
    sub FileRead {my $XML='<otobo_config init="Application"></otobo_config>';return \$XML}
    sub Clone {my ($S,%P)=@_;Storable::dclone($P{Data})}
    sub Dump {'serialized-fixture'}
    sub SettingListParse {
        return map {{XMLContentRaw=>'new-xml',XMLFilename=>'Fixture.xml',XMLContentParsed=>{
            Name=>$_,Value=>[{Content=>'default'}]}}} @{$_[0]{Wanted}};
    }
    sub Log {my ($S,%P)=@_;push @{$S->{Logs}},$P{Message};1}
    package UpgradeBackend;
    sub Get {my ($S,%P)=@_;return $S->{Stale} if $P{Type} eq 'SysConfigDefaultList';return}
    sub Set {$_[0]{Writes}++;1}
    sub Delete {1}
    package UpgradeDB;
    sub Prepare {
        my ($S,%P)=@_;
        die 'Unexpected SQL' if $P{SQL}!~/FROM sysconfig_default/;
        $S->{Cursor}=[map {my $R=$S->{Rows}{$_};[$R->{ID},$_,0,'lock',$R->{XML},'Fixture.xml',0]} sort keys %{$S->{Rows}}];
        $S->{Reads}++;
        return 1;
    }
    sub FetchrowArray {my $R=shift @{$_[0]{Cursor}};return $R?@$R:()}
    sub DefaultSettingLock {return if $_[0]{LockFailure};'lock'}
    sub DefaultSettingUnlock {1}
    sub DefaultSettingUpdate {
        my ($S,%P)=@_;
        die 'Wrong row ID' if $S->{Rows}{$P{Name}}{ID}!=$P{DefaultID};
        $S->{Rows}{$P{Name}}{XML}=$P{XMLContentRaw};
        $S->{Updates}++;
        $S->{Versions}++;
        return 1;
    }
    sub ModifiedSettingListGet {return ({ModifiedID=>99,EffectiveValue=>'administrator-value'})}
    sub ModifiedSettingDelete {die 'Administrator value unexpectedly deleted'}
    sub DefaultSettingBulkAdd {
        my ($S,%P)=@_;
        for my $Name (keys %{$P{Settings}}) {
            if (exists $S->{Rows}{$Name}) {$S->{DuplicateAttempts}++;return}
        }
        for my $Name (keys %{$P{Settings}}) {
            $S->{Rows}{$Name}={ID=>++$S->{Sequence},XML=>$P{Settings}{$Name}{XMLContentRaw}};
            $S->{Inserts}++;
        }
        return 1;
    }
    sub DefaultSettingVersionBulkAdd {$_[0]{Versions}++;1}
}
my $Directory=tempdir(CLEANUP=>1);
sub Fixture {
    my ($Existing)=@_;
    my $Backend=bless {Stale=>[{Name=>'Unrelated',DefaultID=>8,XMLContentRaw=>'unchanged',XMLFilename=>'Fixture.xml'}]},'UpgradeBackend';
    my $Cache=bless {CacheInBackend=>1,CacheInMemory=>1,CacheObject=>$Backend,Debug=>0,
        Cache=>{SysConfigDefaultList=>{DefaultSettingList=>$Backend->{Stale}}}},'UpgradeNativeCache';
    my $DB=bless {Rows=>$Existing?{Existing=>{ID=>7,XML=>'old-xml'},Unrelated=>{ID=>8,XML=>'unchanged'}}:{},
                  Sequence=>100,AdminValue=>'administrator-value',CacheTTL=>3600},'UpgradeDB';
    my $OM=bless {DB=>$DB,Cache=>$Cache,Wanted=>['Existing']},'UpgradeOM';
    return ($OM,$DB,$Backend);
}
my $SysConfig=bless {},'UpgradeNativeSysConfig';
{
    my ($OM,$DB)=Fixture(1);
    local $Kernel::OM=$OM;
    ok(!$SysConfig->ConfigurationXML2DB(UserID=>1,Directory=>$Directory),'native rebuild reproduces duplicate insert with stale nonempty list');
    is($DB->{DuplicateAttempts},1,'existing row was incorrectly sent to insert path');
}
{
    my ($OM,$DB,$Backend)=Fixture(1);
    local $Kernel::OM=$OM;
    ok(UpgradeCacheConfigure($OM->{Cache}),'apply upgrade-only cache policy');
    ok($SysConfig->ConfigurationXML2DB(UserID=>1,Directory=>$Directory),'existing setting reconciles through native update');
    is($DB->{Rows}{Existing}{ID},7,'original setting identity preserved');
    is($DB->{Rows}{Existing}{XML},'new-xml','new XML definition applied');
    is($DB->{AdminValue},'administrator-value','compatible administrator value preserved');
    is($DB->{Updates},1,'one native update');
    ok(!$DB->{DuplicateAttempts},'no duplicate insert attempted');
    ok(!$Backend->{Writes},'upgrade does not publish stale list back to Redis');
    ok($SysConfig->ConfigurationXML2DB(UserID=>1,Directory=>$Directory),'repeat rebuild remains successful');
    is($DB->{Updates},1,'same-definition rebuild is a no-op');
}
{
    my ($OM,$DB)=Fixture(0);
    local $Kernel::OM=$OM;
    UpgradeCacheConfigure($OM->{Cache});
    ok($SysConfig->ConfigurationXML2DB(UserID=>1,Directory=>$Directory),'fresh setting installation works');
    is($DB->{Inserts},1,'fresh definition inserted once');
    ok($SysConfig->ConfigurationXML2DB(UserID=>1,Directory=>$Directory),'fresh installation may be repeated');
    is($DB->{Inserts},1,'repeat creates no duplicate');
}
{
    my ($OM,$DB)=Fixture(1);
    local $Kernel::OM=$OM;
    $DB->{LockFailure}=1;
    UpgradeCacheConfigure($OM->{Cache});
    ok(!$SysConfig->ConfigurationXML2DB(UserID=>1,Directory=>$Directory),'genuine setting lock conflict still fails');
    ok(!$DB->{Updates} && !$DB->{Inserts},'lock conflict performs no setting writes');
    is($DB->{AdminValue},'administrator-value','lock conflict preserves administrator value');
}
open my $FH,'<','container/ubuntu2604/image/release-control.pl' or die $!;
my $Control=do {local $/;<$FH>};
ok(index($Control,'UpgradeCacheConfigure($Kernel::OM')<index($Control,"my \$Gate ="),'cache policy precedes release service/package hooks');
ok(index($Control,"runtime-check.pl','smoke")<index($Control,'$Gate->Run('),'dependency roundtrip precedes release mutation');
done_testing;
