use strict;use warnings;use JSON::PP ();use Digest::SHA qw(sha256_hex);$|=1;
require '/usr/local/lib/tessera/package-inventory.pl';
require '/opt/tessera-navis017-recovery/Navis017Recovery.pm';
sub bytes {my ($P)=@_;open my $F,'<:raw',$P or die "Recovery input unreadable.\n";local $/;return <$F>}
sub json {JSON::PP->new->utf8->decode(bytes($_[0]))}
my $Stage='preflight';
my $OK=eval {
 die "Quiescence required.\n" if ($ENV{TESSERA_UPGRADE_QUIESCED} || '') ne '1' || !-w '/opt/otobo/Kernel/System';
 my $Meta=json('/opt/tessera/dependencies/release.json');my $Inventory=json('/opt/tessera/dependencies/package-modules.json');
 my $Dir='/opt/tessera/upgrade-bundle';
 system('/usr/bin/python3','/usr/local/lib/tessera/check-package-bundle.py',$Dir,'/opt/tessera/dependencies')==0 or die "Bundle verification failed.\n";
 die "Original installer differs.\n" if sha256_hex(bytes('/opt/otobo/Kernel/System/TESSERA/ApplicationNavisInstaller.pm')) ne '3385a3166ccdc655dceda4df32157260b9d8772cb1ad1f8b7e12473938276316';
 die "Bootstrap differs.\n" if sha256_hex(bytes('/opt/otobo/Kernel/System/GovernanceDB/Bootstrap.pm')) ne '20f3224d684d9661625655f2423a45a191861be25bba04698e29302f6afa1455';
 my $Fixed='/opt/tessera-navis017-recovery/Kernel/System/TESSERA/ApplicationNavisInstaller.pm';
 die "Recovery installer differs.\n" if sha256_hex(bytes($Fixed)) ne '3bfd9d55f374643e6b2d2ca9a01fba72622ddb3805710f84ec4faae520087d61';
 unshift @INC,'/opt/tessera-navis017-recovery';
 require Kernel::System::ObjectManager;local $Kernel::OM=Kernel::System::ObjectManager->new();
 my $DB=$Kernel::OM->Get('Kernel::System::DB');my $Gate=$Kernel::OM->Get('Kernel::System::TESSERA::ReleaseUpgrade');
 my $Package=$Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
 my $Journals=sub {TESSERA::Navis017Recovery::Journals($DB)};
 my $Verify=sub {TESSERA::Navis017Recovery::VerifyInventory($Inventory,$DB,sub {InstalledArtifactHash(@_)})};
 my %Structure=$Package->PackageParse(String=>Encode::decode('UTF-8',bytes("$Dir/packages/$TESSERA::Navis017Recovery::Hash.opm")));
 die "Reviewed post hook differs.\n" if ref $Structure{CodeUpgrade} ne 'ARRAY' || @{$Structure{CodeUpgrade}}!=1 || ($Structure{CodeUpgrade}[0]{Type} || '') ne 'post'
  || sha256_hex(Encode::encode('UTF-8',$Structure{CodeUpgrade}[0]{Content})) ne '350f00cc8d67490afd760c38762778c81ef5e4aeaad895c49002ff68bf61cbaf';
 my $Probe=sub {
   my ($Clear)=@_;$Clear=1 if !defined $Clear;$Stage=$Clear?'cache-preflight':'cache-verification';my $C=$Kernel::OM->Get('Kernel::System::Cache');my $B=$C->{CacheObject};my $Key='navis017-'.$Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>40);
   die "Cache write failed.\n" if !$B->Set(Type=>'TESSERARecoveryProbe',Key=>$Key,Value=>$Key,TTL=>60);
   die "Cache read failed.\n" if ($B->Get(Type=>'TESSERARecoveryProbe',Key=>$Key) || '') ne $Key;
   die "Cache delete failed.\n" if !$B->Delete(Type=>'TESSERARecoveryProbe',Key=>$Key);
   die "Cache invalidation failed.\n" if $Clear && !$B->CleanUp();
   $C->Configure(CacheInMemory=>0,CacheInBackend=>0);return 1;
 };
 TESSERA::Navis017Recovery->Run(Meta=>$Meta,Gate=>$Gate,Owner=>$Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length=>40),Journals=>$Journals,Verify=>$Verify,
  FieldCount=>sub {TESSERA::Navis017Recovery::FieldCount($DB)},
  Probe=>$Probe,
  Hook=>sub {
   $Stage='native-post-hook';print "recovery=reviewed-post-hook-only,no-native-package-replay
";
   TESSERA::Navis017Recovery::CompleteHook($Package,\%Structure,$Kernel::OM);
   return 1;
  },
  DropJournal=>sub {my ($Key,$Raw)=@_;$Stage='journal-completion';my $N=$DB->Connect()->do('DELETE FROM system_data WHERE data_key = ? AND data_value = ?',undef,$Key,$Raw);die "Journal CAS failed.\n" if !defined $N || $N!=1;return 1},
  VerifyReady=>sub {CheckInventory($Inventory,$DB,$Package);die if !$DB->Prepare(SQL=>'SELECT request_data,dispatch_data FROM ztsm_async_execution WHERE 1 = 0');$DB->FetchrowArray();return 1},
  Configure=>sub {$Stage='configuration';return 0 if system('/usr/bin/python3','/opt/tessera-navis017-recovery/configure.py')!=0;$Probe->(0);return 1});
 print "recovery=READY017-verified\n";1;
};
if (!$OK){print STDERR "Navis017 recovery stopped at $Stage; preserve state, Job and bundle.\n";exit 1}

1;
