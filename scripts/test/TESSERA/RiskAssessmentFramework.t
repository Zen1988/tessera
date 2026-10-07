use strict;
use warnings;
use Test::More;
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptEngine;
open my $FH, '<', 'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerTicketZTSMAction.pm' or die $!;
my $Source = do { local $/; <$FH> };
$Source =~ s{^use Kernel::[^;]+;\r?\n}{}mg;
eval $Source; die $@ if $@;
{ no strict 'refs';
  *{'Kernel::Modules::CustomerTicketZTSMAction::IsHashRefWithData'} = sub { ref $_[0] eq 'HASH' && keys %{$_[0]} };
  *{'Kernel::Modules::CustomerTicketZTSMAction::IsArrayRefWithData'} = sub { ref $_[0] eq 'ARRAY' && @{$_[0]} };
}
our $Default = 'Asset Risk Management';
our %Objects = (
  1 => { GovernanceObjectID=>1, Class=>'Framework', Name=>'Asset Risk Management' },
  2 => { GovernanceObjectID=>2, Class=>'Framework', Name=>'Statement Framework' },
  3 => { GovernanceObjectID=>3, Class=>'Framework', Name=>'Override Framework' },
  4 => { GovernanceObjectID=>4, Class=>'RiskStatement', 'DynamicField_ZRM-RMF'=>[2] },
  5 => { GovernanceObjectID=>5, Class=>'RiskStatement' },
  6 => { GovernanceObjectID=>6, Class=>'RiskStatement', 'DynamicField_ZRM-RMF'=>[2,3] },
);
{ package FrameworkTestOM;
  sub Get {
    return Kernel::System::TESSERA::ScriptEngine->new() if $_[1] eq 'Kernel::System::TESSERA::ScriptEngine';
    return $main::Default if $_[1] eq 'TESSERA::RiskAssessment::DefaultFramework';
    return $_[0];
  }
  sub GovernanceObjectGet { my ($Self,%P)=@_; return $main::Objects{$P{GovernanceObjectID}} }
  sub GovernanceObjectSearch { return keys %main::Objects }
}
$Kernel::OM = bless {}, 'FrameworkTestOM';
my $Action = bless {}, 'Kernel::Modules::CustomerTicketZTSMAction';
is($Action->_RiskAssessmentFrameworkResolve(),1,'empty new row uses organization default by exact name');
is($Action->_RiskAssessmentFrameworkResolve(RiskStatementID=>4),2,'statement Framework overrides organization default');
is($Action->_RiskAssessmentFrameworkResolve(RiskStatementID=>5),1,'statement without Framework uses default');
ok(!defined $Action->_RiskAssessmentFrameworkResolve(RiskStatementID=>6),'ambiguous statement Framework fails closed');
ok(!defined $Action->_RiskAssessmentFrameworkResolve(RiskStatementID=>999),'invalid statement cannot fall through to a default');
$Objects{7} = { Class=>'Framework',Name=>'Asset Risk Management' };
ok(!defined $Action->_RiskAssessmentFrameworkResolve(),'duplicate default name fails closed');
delete $Objects{7};
my $Rows=[{}];
my $Engine={'ASSESSMENT RESULT'=>{'FIELD ASSIGNMENTS'=>{'ZRM-Framework'=>'@FRAMEWORK.GovernanceObjectID'}}};
ok($Action->_RiskAssessmentFrameworkMappingApply(Rows=>$Rows,Engine=>$Engine,Framework=>$Objects{3}),'real ScriptEngine evaluates YAML row mapping');
is_deeply($Rows->[0]->{'ZRM-Framework'},[3],'explicit YAML result overrides automatic Framework');
my $Row={'ZRM-Framework'=>[3]};
$Action->_RiskAssessmentStatementDefaults(Statement=>$Objects{4},Row=>$Row);
is_deeply($Row->{'ZRM-Framework'},[3],'defaults preserve explicit saved override');
$Action->{RiskAssessmentMappedFrameworkID}=3;
$Row={}; $Action->_RiskAssessmentStatementDefaults(Statement=>$Objects{4},Row=>$Row);
is_deeply($Row->{'ZRM-Framework'},[3],'master ticket mapping takes priority on initial row creation');
$Engine->{'ASSESSMENT RESULT'}->{'FIELD ASSIGNMENTS'}->{'ZRM-Framework'}='@STATEMENT.GovernanceObjectID';
eval { $Action->_RiskAssessmentFrameworkMappingApply(Rows=>$Rows,Engine=>$Engine,Statement=>$Objects{4}) };
like($@,qr/does not reference a Framework/,'wrong-class YAML target is rejected');
$Objects{2}{DynamicField_RiskMatrix}=[{'ZRM-StartScore'=>1,'ZRM-EndScore'=>9,'ZRM-RiskSeverity'=>[10]}];
$Objects{10}={Class=>'EventSeverity',Name=>'Low','DynamicField_ZTSM-ColorHex'=>'#00ff00'};
my $Level=Kernel::Modules::CustomerTicketZTSMAction::_RiskAssessmentRiskLevel(9,{'ZRM-Framework'=>[2]});
is($Level->{Label},'Low','assessment classification follows authored Framework for score9');
is($Level->{Color},'#00ff00','assessment colour uses severity object');
is($Level->{Summary},'9 - Low','article summary uses Framework classification');
is(Kernel::Modules::CustomerTicketZTSMAction::_RiskAssessmentRiskLevel(9,{})->{Label},'Unmapped','missing Framework never guesses Medium');
done_testing();
