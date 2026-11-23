use strict;use warnings;use Test::More;use JSON::PP ();use Storable qw(dclone);
use lib '.';use Kernel::System::TESSERA::ReleaseUpgrade;
require './container/ubuntu2604/image/Navis017Recovery.pm';
{package RecoveryGate;our @ISA=('Kernel::System::TESSERA::ReleaseUpgrade');
 sub _Read {$_[0]{raw}}sub _Version {'0.1.7'}sub _InstalledHash {$TESSERA::Navis017Recovery::Hash}
 sub _Write {my($S,$Old,$New)=@_;die 'CAS' if $S->{conflict} || $S->{raw} ne $Old;$S->{raw}=$New;push @{$S->{phases}},$S->_Decode($New)->{phase};$New}
 package RecoveryOM;sub Get {$_[0]}sub GenerateRandomString {'x'x40}
}
local $Kernel::OM=bless {},'RecoveryOM';
sub fixture {
 my $H=$TESSERA::Navis017Recovery::Hash;my $S={phase=>'UPGRADING',version=>'0.1.7',from=>'0.1.3',hash=>$H,owner=>'old'};
 my $G=bless {raw=>JSON::PP->new->canonical->encode($S)},'RecoveryGate';
 my $J=[['TESSERA::PackageUpgrade::TESSERA-Base',JSON::PP->new->canonical->encode({phase=>'UPGRADING',version=>'0.1.7',hash=>$H})]];
 my $F={Gate=>$G,Meta=>{version=>'0.1.7',package_sha256=>$H},Owner=>'new',J=>$J,hook=>0,configure=>0,drop=>0};
 $F->{Journals}=sub {$F->{J}};$F->{FieldCount}=sub {0};$F->{Verify}=sub {1};$F->{Probe}=sub {1};$F->{VerifyReady}=sub {1};
 $F->{Hook}=sub {$F->{hook}++;1};$F->{Configure}=sub {$F->{configure}++;1};$F->{DropJournal}=sub {my($K,$R)=@_;die 'journal CAS' if $K ne $F->{J}[0][0] || $R ne $F->{J}[0][1];$F->{drop}++;$F->{J}=[];1};return $F;
}
my $F=fixture();ok(TESSERA::Navis017Recovery->Run(%$F),'exact017 failure can complete reviewed hook/config');is($F->{hook},1,'one post hook');is($F->{configure},1,'one config rebuild');is($F->{drop},1,'exact journal removed once');is($F->{Gate}->_Decode($F->{Gate}->_Read())->{phase},'READY','native gate publishes ready');
ok(!eval {TESSERA::Navis017Recovery->Run(%$F);1},'same recovery cannot replay after success');is($F->{hook},1,'no repeated hook');
for my $Case (qw(inventory cache field receipt journal owner afterowner afterjournal hook hookfalse drop configure)) {
 my $X=fixture();
 if($Case eq 'inventory'){$X->{Verify}=sub {die 'inventory'}}
 elsif($Case eq 'cache'){$X->{Probe}=sub {0}}
 elsif($Case eq 'field'){$X->{FieldCount}=sub {1}}
 elsif($Case eq 'receipt'){my $S=$X->{Gate}->_Decode($X->{Gate}{raw});$S->{from}='0.1.2';$X->{Gate}{raw}=$X->{Gate}->_Encode($S)}
 elsif($Case eq 'journal'){$X->{J}[0][1]='{}'}
 elsif($Case eq 'owner'){$X->{Gate}{conflict}=1}
 elsif($Case eq 'afterowner'){$X->{Hook}=sub {$X->{hook}++;$X->{Gate}{raw}=$X->{Gate}->_Encode({phase=>'UPGRADING',owner=>'other'});1}}
 elsif($Case eq 'afterjournal'){$X->{Hook}=sub {$X->{hook}++;$X->{J}[0][1]='changed';1}}
 elsif($Case eq 'hook'){$X->{Hook}=sub {$X->{hook}++;die 'hook failed'}}
 elsif($Case eq 'hookfalse'){$X->{Hook}=sub {$X->{hook}++;0}}
 elsif($Case eq 'drop'){$X->{DropJournal}=sub {die 'CAS'}}
 elsif($Case eq 'configure'){$X->{Configure}=sub {$X->{configure}++;0}}
 ok(!eval {TESSERA::Navis017Recovery->Run(%$X);1},"$Case failure stops recovery");
 isnt($X->{Gate}->_Decode($X->{Gate}{raw})->{phase},'READY',"$Case never marks ready");
 if($Case ne 'configure'){is(scalar @{$X->{J}},1,"$Case retains original journal")}
 if($Case=~/^(inventory|cache|field|receipt|journal|owner)$/){is($X->{hook},0,"$Case executes no hook")}
 if($Case eq 'configure'){is($X->{Gate}->_Decode($X->{Gate}{raw})->{phase},'CONFIGURING','failed config retains completed-hook phase')}
}

# Exercise actual database/native hook adapters with the native API argument contract.
{package RecoveryDB;
 sub Prepare {my ($S,%P)=@_;if($P{SQL}=~/WHERE install_status/){die 'scalar bind required' if ref $P{Bind}[0] ne 'SCALAR';$S->{rows}=[['TESSERA-Base','0.1.7']]}
 elsif($P{SQL}=~/COUNT/){die 'scalar bind required' if ref $P{Bind}[0] ne 'SCALAR';$S->{rows}=[[0]]}
 else {$S->{rows}=[['TESSERA::PackageUpgrade::TESSERA-Base','raw-journal']]}return 1}
 sub FetchrowArray {my $R=shift @{$_[0]{rows}};return $R?@$R:()}
 package RecoveryNative;
 sub _Code {my ($S,%P)=@_;die 'native structure must be hashref' if ref $P{Structure} ne 'HASH' || ref $P{Code} ne 'ARRAY';$S->{hook}++;1}
 sub EventHandler {$_[0]{event}++;1}
 sub Get {$_[0]}sub DynamicFieldGet {{Name=>'Navis',FieldType=>'Text',ObjectType=>'GovernanceObject',ValidID=>1,Config=>{}}}
 sub CleanUp {$_[0]{cleanup}++;1}sub CacheDelete {$_[0]{loader}++;1}
}
my $DB=bless {},'RecoveryDB';is_deeply(TESSERA::Navis017Recovery::Journals($DB),[['TESSERA::PackageUpgrade::TESSERA-Base','raw-journal']],'journal adapter returns an array reference of exact raw values');
is(TESSERA::Navis017Recovery::FieldCount($DB),0,'field count uses native scalar bind references');
my $Inventory={schema=>1,packages=>[{name=>'TESSERA-Base',version=>'0.1.7',package_sha256=>'a'x64}]};
ok(TESSERA::Navis017Recovery::VerifyInventory($Inventory,$DB,sub {'a'x64}),'native inventory adapter verifies registry and actual hashes');
ok(!eval {TESSERA::Navis017Recovery::VerifyInventory($Inventory,$DB,sub {'b'x64});1},'actual artifact mismatch stops inventory verification');
my $Native=bless {},'RecoveryNative';ok(TESSERA::Navis017Recovery::CompleteHook($Native,{CodeUpgrade=>[{Content=>'reviewed'}],Vendor=>{Content=>'vendor'}},$Native),'native hook adapter passes hash and code references');
is($Native->{hook},1,'one native post hook');is($Native->{event},1,'native upgrade event completes');is($Native->{loader},1,'native loader completion runs');
done_testing();
