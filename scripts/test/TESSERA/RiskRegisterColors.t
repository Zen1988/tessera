use strict;use warnings;use Test::More;
use lib 'Kernel/Package/GovernanceDB','.';
use Kernel::System::TESSERA::RiskRegister;
our %Objects=(
 1=>{Class=>'Framework',Name=>'Application',DynamicField_RiskMatrix=>[
  {'ZRM-StartScore'=>1,'ZRM-EndScore'=>4,'ZRM-RiskSeverity'=>[10]},
  {'ZRM-StartScore'=>5,'ZRM-EndScore'=>9,'ZRM-RiskSeverity'=>[11]}]},
 2=>{Class=>'Framework',Name=>'Asset',DynamicField_RiskMatrix=>[
  {'ZRM-StartScore'=>1,'ZRM-EndScore'=>9,'ZRM-RiskSeverity'=>[10]}]},
 10=>{Class=>'EventSeverity',Name=>'Very Low','DynamicField_ZTSM-ColorHex'=>'#0f0'},
 11=>{Class=>'EventSeverity',Name=>'Low','DynamicField_ZTSM-ColorHex'=>'000080'},
);
{package ColorOM;sub Get{$_[0]}sub GovernanceObjectGet{my($S,%P)=@_;return $main::Objects{$P{GovernanceObjectID}}}}
local $Kernel::OM=bless {},'ColorOM';
my $R=Kernel::System::TESSERA::RiskRegister->new;
sub D {my($F,$S)=@_;return $R->ScoreDecoration(Row=>{'ZRM-Framework'=>[$F]},Score=>$S)}
is(D(1,4)->{Label},'Very Low','inclusive lower band endpoint');
is(D(1,5)->{Label},'Low','inclusive next band start');
is(D(1,9)->{Color},'#000080','score 9 follows authored Low mapping rather than hardcoded Medium');
is(D(2,9)->{Label},'Very Low','same score uses row Framework override');
is(D(2,1)->{Color},'#00ff00','short hex normalized');
is(D(2,1)->{Foreground},'#000000','light background uses readable black');
is(D(1,9)->{Foreground},'#ffffff','dark background uses readable white');
is_deeply(D(1,10),{},'uncovered score stays neutral');
is_deeply(D(999,9),{},'missing Framework stays neutral');
is_deeply(D(1,'<script>'),{},'invalid score is not interpreted');
push @{$Objects{1}{DynamicField_RiskMatrix}},{'ZRM-StartScore'=>9,'ZRM-EndScore'=>10,'ZRM-RiskSeverity'=>[10]};
is_deeply(D(1,9),{},'overlapping bands do not guess');
pop @{$Objects{1}{DynamicField_RiskMatrix}};
$Objects{11}{'DynamicField_ZTSM-ColorHex'}='red;position:fixed';
is_deeply(D(1,9),{},'CSS injection cannot become a colour');
$Objects{11}{'DynamicField_ZTSM-ColorHex'}='#123456';$Objects{11}{Class}='Application';
is_deeply(D(1,9),{},'wrong-class severity stays neutral');
done_testing();
