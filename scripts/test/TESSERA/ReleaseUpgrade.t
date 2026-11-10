use strict;
use warnings;
use Test::More;
use lib '.';
use Kernel::System::TESSERA::ReleaseUpgrade;
{ package ReleaseFake;
  our @ISA=('Kernel::System::TESSERA::ReleaseUpgrade');
  sub _Version {$_[0]{Store}{version}}
  sub _InstalledHash {$_[0]{Store}{hash}}
  sub _Read {$_[0]{Store}{raw}}
  sub _Write {my($S,$Old,$New)=@_;die 'CAS' if $S->{Conflict} || (($S->{Store}{raw}//'') ne ($Old//''));$S->{Store}{raw}=$New;push @{$S->{Phases}},$S->_Decode($New)->{phase};$New}
  package ReleaseOM; sub Get {$_[0]} sub GenerateRandomString {'A'x40}
}
local $Kernel::OM=bless {},'ReleaseOM';
my $Hash='a'x64;
sub fixture {return bless {Store=>{version=>$_[0] || '0.0.180',hash=>$Hash}},'ReleaseFake'}
sub run_release {
 my($G,%Extra)=@_;
 return $G->Run(Version=>'0.0.182',Hash=>$Hash,FromVersions=>['0.0.180','0.0.181'],
 Upgrade=>sub {$G->{Upgrades}++;$G->{Store}{version}='0.0.182';return1()},Configure=>sub {$G->{Configures}++;1},%Extra);
}
sub return1 {1}
for my $From ('0.0.180','0.0.181') {
 my $G=fixture($From);ok(run_release($G)->{Upgraded},"$From upgrades");
 is_deeply($G->{Phases},[qw(UPGRADING CONFIGURING READY)],'intent precedes native effects/config precedes ready');
 ok($G->Check(Version=>'0.0.182',Hash=>$Hash),'readiness passes after complete');
 ok(!run_release($G)->{Upgraded},'same-version no native reinstall');is($G->{Upgrades},1,'one native upgrade after repeated deployment');
}
for my $Version ('0.0.179','0.0.183','0.1.0') {my $G=fixture($Version);ok(!eval {run_release($G);1},'unsupported/forward target denied');ok(!$G->{Upgrades},'no native effect')}
my $G=fixture();$G->{Conflict}=1;ok(!eval {run_release($G);1},'concurrent CAS loser stops');ok(!$G->{Upgrades},'CAS loser has no effect');
$G=fixture();ok(!eval {run_release($G,Upgrade=>sub {$G->{Store}{version}='0.0.182';die 'interrupted';});1},'interrupted native upgrade stops');
is($G->_Decode($G->_Read())->{phase},'UPGRADING','dirty intent persists even when registry advanced');
ok(!eval {$G->Check(Version=>'0.0.182',Hash=>$Hash);1},'registry version alone cannot unlock readiness');
ok(!eval {run_release($G);1},'uncertain native upgrade is not retried');
ok(!eval {run_release($G,ResumeConfig=>1);1},'config resume cannot hide incomplete native hooks');
$G=fixture();ok(!eval {run_release($G,Configure=>sub {0});1},'failed config stops');
is($G->_Decode($G->_Read())->{phase},'CONFIGURING','config failure durable');
ok(!eval {run_release($G);1},'no implicit stale claim takeover');
ok(run_release($G,ResumeConfig=>1)->{Success},'explicit reviewed config recovery');
is($G->{Upgrades},1,'config recovery never reinstalls schema/package');
$G=fixture();eval {run_release($G,Configure=>sub {0})};$G->{Store}{hash}='b'x64;
ok(!eval {run_release($G,ResumeConfig=>1);1},'config resume rejects changed installed artifact before rebuild');
ok(!$G->{Configures},'wrong-artifact config resume does not invoke configuration');
$G=fixture();ok(!eval {run_release($G,Configure=>sub {$G->{Store}{version}='0.0.183';1});1},'concurrent metadata change during configuration fails');
is($G->_Decode($G->_Read())->{phase},'CONFIGURING','no READY receipt is published for a changed target');
$G=fixture('0.0.182');$G->{Store}{hash}='b'x64;ok(!eval {run_release($G);1},'same-version artifact mismatch fails');
$G=fixture('0.0.182');ok(!eval {$G->Check(Version=>'0.0.182',Hash=>$Hash);1},'matching registry without a successful release receipt cannot start runtime');
ok(run_release($G)->{Success},'controlled current-version job initializes receipt after verification/config');
ok(!$G->{Upgrades},'receipt initialization does not reinstall the package');
$G=fixture();ok(!eval {run_release($G,Upgrade=>sub {$G->{Store}{version}='0.0.182';$G->{Store}{hash}='b'x64;1});1},'native artifact mismatch prevents publication');
is($G->_Decode($G->_Read())->{phase},'UPGRADING','mismatch keeps durable block');
$G=fixture();$G->{Store}{raw}='malformed';ok(!eval {run_release($G);1},'corrupt release state blocks upgrade');
{package HashGate;our @ISA=('Kernel::System::TESSERA::ReleaseUpgrade');sub _DB {$_[0]{DB}}
 package HashDB;
 sub Prepare {$_[0]{Cursor}=0;1}
 sub FetchrowArray {my($S)=@_;return if $S->{Cursor}>=@{$S->{Rows}};return ($S->{Rows}[$S->{Cursor}++])}
 sub GetDatabaseFunction {$_[0]{Direct}}
}
require MIME::Base64;require Digest::SHA;
my $Text='<package>actual installed bytes</package>';
my $DB=bless {Rows=>[$Text],Direct=>1},'HashDB';my $HG=bless {DB=>$DB},'HashGate';
is($HG->_InstalledHash('0.0.182'),Digest::SHA::sha256_hex($Text),'hash reads actual DirectBlob registry bytes');
$DB->{Direct}=0;$DB->{Rows}=[MIME::Base64::encode_base64($Text)];
is($HG->_InstalledHash('0.0.182'),Digest::SHA::sha256_hex($Text),'native Base64 storage hashes original package bytes');
$DB->{Direct}=1;$DB->{Rows}=['new bytes'];
is($HG->_InstalledHash('0.0.182'),Digest::SHA::sha256_hex('new bytes'),'hash reflects changed DB content without repository cache');
$DB->{Rows}=[];ok(!eval {$HG->_InstalledHash('0.0.182');1},'missing artifact fails closed');
done_testing();
