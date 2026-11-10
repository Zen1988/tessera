use strict;use warnings;use Test::More;use lib '.';
use Kernel::System::TESSERA::ReleaseUpgrade;
{package RecoveryGate;our @ISA=('Kernel::System::TESSERA::ReleaseUpgrade');
 sub _Read {$_[0]{raw}} sub _Version {$_[0]{version}} sub _InstalledHash {$_[0]{hash}}
 sub _Write {my($S,$Before,$After)=@_;die 'CAS' if ($S->{raw}//'') ne ($Before//'');$S->{raw}=$After;push @{$S->{phases}},$S->_Decode($After)->{phase};$After}
 package RecoveryOM;sub Get {$_[0]} sub GenerateRandomString {'x'x40}
}
local $Kernel::OM=bless {},'RecoveryOM';
for my $Origin (qw(0.0.179 0.0.178 0.0.180 0.0.185)) {
 my $G=bless {version=>$Origin,hash=>'b'x64},'RecoveryGate';
 my $R=eval {$G->Run(Version=>'0.0.184',Hash=>'a'x64,FromVersions=>['0.0.179'],
 Upgrade=>sub {$G->{calls}++;$G->{version}='0.0.184';$G->{hash}='a'x64;1},Configure=>sub {$G->{configured}++;1})};
 if ($Origin eq '0.0.179') {
  ok($R->{Success},'explicit179 to184 transition succeeds');is($G->{calls},1,'native upgrade once');
  is_deeply($G->{phases},[qw(UPGRADING CONFIGURING READY)],'all durable phases retained');
  ok($G->Check(Version=>'0.0.184',Hash=>'a'x64),'normal184 runtime receipt check passes');
 } else {ok(!$R,"$Origin not admitted by recovery");ok(!$G->{calls},'rejected before native effects')}
}
my $G=bless {version=>'0.0.179',hash=>'b'x64},'RecoveryGate';
eval {$G->Run(Version=>'0.0.184',Hash=>'a'x64,FromVersions=>['0.0.179'],Upgrade=>sub {$G->{version}='0.0.184';die 'failed hook'},Configure=>sub {die 'must not configure'})};
is($G->_Decode($G->_Read())->{phase},'UPGRADING','partial migration remains blocked');
ok(!eval {$G->Check(Version=>'0.0.184',Hash=>'a'x64);1},'partial registry change never grants readiness');
done_testing();
