use strict;
use warnings;
use Test::More;
use DateTime;
use YAML::XS ();
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptEngine;
use Kernel::System::TESSERA::ControlRuntime;

sub Slurp { open my $F, '<', $_[0] or die $!; local $/; <$F> }
my $PolicyText = Slurp('Kernel/Package/GovernanceDB/var/governancedb/policy/product_eosl_evaluation.yml');
my $RiskText = Slurp('Kernel/Package/GovernanceDB/var/governancedb/policy/product_eosl_risk_assignment.yml');
my $Script = YAML::XS::Load($PolicyText);
my $Engine = Kernel::System::TESSERA::ScriptEngine->new();
my $Runtime = Kernel::System::TESSERA::ControlRuntime->new();
my $Now = DateTime->new(year=>2026,month=>9,day=>22,time_zone=>'Asia/Singapore')->epoch;
{
    package PolicyAdapters;
    sub Get { $_[1] =~ /::(?:PolicyEngine|ScriptEngine)$/ ? $_[0]{Engine} : $_[0] }
    sub Create { my ( $Self, $Type, %P ) = @_; bless { Epoch => $P{ObjectParams}{Epoch} }, 'PolicyClock' }
    sub Load { my ( $Self, %P ) = @_; YAML::XS::Load($P{Data}) }
    sub PIDCreate { !$_[0]{Busy} }
    sub PIDDelete { 1 }
    sub DynamicFieldGet {
        my ( $Self, %P ) = @_;
        my $Name = $P{Name};
        return if $Name eq 'Unknown';
        return { Name=>$Name, ObjectType=>'ITSMConfigItem', FieldType=>'Date' } if $Name eq 'ZTAM-EoServiceLife';
        return { Name=>$Name, ObjectType=>'ITSMConfigItem', FieldType=>'Set', Config=>{ Include=>[{DF=>'ZTAM-Installed'}] } } if $Name eq 'ZTAM-Runtime';
        return { Name=>$Name, ObjectType=>'ITSMConfigItem', FieldType=>'ConfigItem', Config=>{ReferencedObjectType=>'ITSMConfigItem'} } if $Name =~ /^ZTAM-/;
        return { Name=>$Name, ObjectType=>'MELTObject' } if $Name =~ /^MELT-/;
        return { Name=>$Name, ObjectType=>'ITSMConfigItem' };
    }
    sub ConfigItemSearch {
        my ( $Self, %P ) = @_;
        $Self->{Searches}++;
        my @Objects = grep { $_->{Class} eq $P{Classes}[0] } values %{ $Self->{Objects} };
        for my $Key (grep { /^DynamicField_/ } keys %P) {
            @Objects = grep { ( $_->{$Key} || '' ) eq $P{$Key}{Equals} } @Objects;
        }
        my @IDs = sort { $a <=> $b } map { $_->{ConfigItemID} } @Objects;
        splice @IDs, $P{Limit} if $P{Limit} && @IDs > $P{Limit};
        return @IDs;
    }
    sub ConfigItemGet { my ( $Self, %P ) = @_; $Self->{Objects}{ $P{ConfigItemID} } }
    sub ItemList { my ( $Self, %P ) = @_; return $P{Class} =~ /::Class$/ ? {1=>'Risk'} : {2=>'Active'} }
    sub MELTObjectSearch {
        my ( $Self, %P ) = @_;
        my ($Key) = grep { /^DynamicField_/ } keys %P;
        return grep {
            ($Self->{Risks}{$_}{$Key} || '') eq $P{$Key}{Equals}
                && $Self->{Risks}{$_}{Class} eq $P{Classes}[0]
                && ( !$P{ZTSMStatusIDs} || $Self->{Risks}{$_}{ZTSMStatusID} == $P{ZTSMStatusIDs}[0] )
        } sort keys %{ $Self->{Risks} };
    }
    sub MELTObjectGet { my ( $Self, %P ) = @_; $Self->{Risks}{ $P{MELTObjectID} } }
    sub MELTObjectUpdate { my ( $Self, %P ) = @_; my $ID = delete $P{MELTObjectID}; delete $P{UserID}; @{$Self->{Risks}{$ID}}{keys %P} = values %P; 1 }
    sub GovernanceObjectGet { my ( $Self, %P ) = @_; $Self->{Governance}{ $P{GovernanceObjectID} } }
    sub GovernanceObjectSearch {
        my ( $Self, %P ) = @_;
        return sort { $a <=> $b } map { $_->{GovernanceObjectID} }
            grep { $_->{Class} eq $P{Classes}[0] && $_->{Name} eq $P{Name} }
            values %{ $Self->{Governance} };
    }
    sub MELTObjectAdd {
        my ( $Self, %P ) = @_;
        my $ID = 200 + scalar keys %{ $Self->{Risks} };
        $Self->{Risks}{$ID} = { %P, Class => 'Risk' };
        return $ID;
    }
    sub ActivityAdd { my ( $Self, %P ) = @_; push @{ $Self->{Activities} }, \%P; 1 }
    sub ValueSet { my ( $Self, %P ) = @_; $Self->{Saved}{ $P{DynamicFieldConfig}{Name} } = $P{Value}; 1 }
    sub Log { 1 }
}
{ package PolicyClock; sub ToString { '2026-09-22 00:00:00' } }
sub Setup {
    my %Objects = (
        1 => {Class=>'Product', Name=>'Root', 'DynamicField_ZTAM-EoServiceLife'=>'2027-09-21'},
        2 => {Class=>'Product', Name=>'Child', 'DynamicField_ZTAM-Parent'=>1, 'DynamicField_ZTAM-EoServiceLife'=>'2035-01-01'},
        3 => {Class=>'Product', Name=>'Leaf', 'DynamicField_ZTAM-Parent'=>2},
        4 => {Class=>'Product', Name=>'Unrelated'},
        10 => {Class=>'Workload', Name=>'W', 'DynamicField_ZTAM-Model'=>1, 'DynamicField_ZTAM-Application'=>100},
        11 => {Class=>'NetworkNode', Name=>'N', 'DynamicField_ZTAM-Model'=>3, 'DynamicField_ZTAM-Application'=>100},
        12 => {Class=>'StorageNode', Name=>'S', 'DynamicField_ZTAM-Product'=>2, 'DynamicField_ZTAM-Application'=>100},
        13 => {Class=>'PeripheralNode', Name=>'P', 'DynamicField_ZTAM-Runtime'=>[{'ZTAM-Installed'=>3},{'ZTAM-Installed'=>[2]}], 'DynamicField_ZTAM-Application'=>100},
        14 => {Class=>'Workload', Name=>'Unrelated W', 'DynamicField_ZTAM-Model'=>4},
    );
    $Objects{$_}{ConfigItemID} = $_ for keys %Objects;
    my %Governance = (
        100 => {GovernanceObjectID=>100, Class=>'Application', Name=>'Alpha'},
        101 => {GovernanceObjectID=>101, Class=>'Application', Name=>'Beta'},
        50 => {GovernanceObjectID=>50, Class=>'RiskStatement', Name=>'Unsupported Product', 'DynamicField_ZRM-Annex'=>'A-1', 'DynamicField_ZRM-RMF'=>60},
        51 => {GovernanceObjectID=>51, Class=>'RiskStatement', Name=>'Outdated Support', 'DynamicField_ZRM-Annex'=>'A-2', 'DynamicField_ZRM-RMF'=>60},
        60 => {GovernanceObjectID=>60, Class=>'Framework', Name=>'RMF'},
        70 => {GovernanceObjectID=>70, Class=>'EventSeverity', Name=>'Critical', ZTSMStatus=>'Active'},
        71 => {GovernanceObjectID=>71, Class=>'EventSeverity', Name=>'High', ZTSMStatus=>'Active'},
        72 => {GovernanceObjectID=>72, Class=>'EventSeverity', Name=>'Medium', ZTSMStatus=>'Active'},
    );
    $Kernel::OM = bless {Engine=>$Engine, Objects=>\%Objects, Governance=>\%Governance, Searches=>0, Risks=>{}, Activities=>[], Saved=>{}}, 'PolicyAdapters';
    return $Objects{1};
}
sub Evaluate {
    my ($This, $CustomScript, $Epoch) = @_;
    $Engine->PolicyEvaluate(Script=>$CustomScript || $Script, TargetType=>'ITSMConfigItem.Product', Now=>$Epoch || $Now, UserID=>1, Context=>{THIS=>$This});
}

my $Root = Setup();
my $R = Evaluate($Root);
ok($R->{Success}, 'Exact packaged policy executes') or diag explain $R;
is($R->{Status}, 'Fail', 'Less than one year fails');
is_deeply([map {$_->{Asset}{ConfigItemID}} @{$R->{Findings}}], [10,11,12,13], 'Includes direct and last-leaf references across all four classes');
is(scalar @{$R->{Findings}[3]{Matches}}, 2, 'Multiple Runtime Products contribute to one asset finding');
is($Kernel::OM->{Objects}{2}{'DynamicField_ZTAM-EoServiceLife'}, '2035-01-01', 'Descendant own date does not block inherited impact');

for my $Case (['2027-09-22','Pass'], ['2027-09-23','Pass'], ['2025-01-01','Fail'], ['2026-09-22','Fail'], ['', 'N/A'], [undef,'N/A']) {
    $Root=Setup(); $Root->{'DynamicField_ZTAM-EoServiceLife'}=$Case->[0];
    $R=Evaluate($Root);
    is($R->{Status},$Case->[1],'Date boundary '.($Case->[0]//'missing'));
    is($Kernel::OM->{Searches},0,'Pass/missing skips ALL descendant and asset searches') if $Case->[1] ne 'Fail';
}
$Root=Setup();$Root->{'DynamicField_ZTAM-EoServiceLife'}='2026-02-30';
$R=Evaluate($Root);is($R->{Status},'UNKNOWN','Invalid populated date fails closed');
is($Kernel::OM->{Searches},0,'Invalid date does not cascade');
$Root=Setup();$Root->{'DynamicField_ZTAM-EoServiceLife'}='2025-02-28';
$R=Evaluate($Root,undef,DateTime->new(year=>2024,month=>2,day=>29,time_zone=>'Asia/Singapore')->epoch);
is($R->{Status},'Pass','Calendar year cutoff clamps leap day');

$Root=Setup();$Root->{'DynamicField_ZTAM-Parent'}=3;
$R=Evaluate($Root);ok($R->{Success},'Cycle terminates without losing reachable objects');
is(scalar @{$R->{Findings}},4,'Cycle does not duplicate findings');
$Root=Setup();my $Generic=YAML::XS::Load($PolicyText);
$Generic->{CHECK}={EXPECT=>'NUMBER(@THIS.ConfigItemID) IS GREATER THAN NUMBER(0)'};
$R=Evaluate($Root,$Generic);is($R->{Status},'Pass','Authored numeric check replaces date rule without engine changes');
is($Kernel::OM->{Searches},0,'Generic passing check also skips cascade');
$Root=Setup();$Generic=YAML::XS::Load($PolicyText);
$Generic->{CHECK}{EXPECT}='DATE(@THIS.ZTAM-EoServiceLife) IS ON OR AFTER DATE(TODAY + 6 MONTHS)';
$R=Evaluate($Root,$Generic);is($R->{Status},'Pass','Calendar threshold is entirely authored in YAML');
$Root=Setup();my $Limited=YAML::XS::Load($PolicyText);$Limited->{'ON FAIL'}{DESCENDANTS}{'MAX DEPTH'}=1;
$R=Evaluate($Root,$Limited);is($R->{Status},'UNKNOWN','Depth overflow fails rather than claiming full impact');
$Root=Setup();$Limited=YAML::XS::Load($PolicyText);$Limited->{'ON FAIL'}{AFFECTED}[0]{LIMIT}=1;
$R=Evaluate($Root,$Limited);is($R->{Status},'UNKNOWN','Asset scan overflow fails before Risk writes');
$Root=Setup();$Limited=YAML::XS::Load($PolicyText);$Limited->{CHECK}{'ON EMPTY'}{FIELD}='Unknown';
$R=Evaluate($Root,$Limited);is($R->{Status},'UNKNOWN','Unknown field is not treated as unannounced');

$Root=Setup();
my $Objective={GovernanceObjectID=>50,Class=>'ControlObjective',ZTSMStatus=>'Active',
    'DynamicField_ZRM-RiskClass'=>'MELTObject.Risk','DynamicField_ZRM-CreateRisk'=>1,
    'DynamicField_ZRM-RiskStmt'=>[50],
    'DynamicField_ZRM-FieldAssignment'=>$RiskText,'DynamicField_ZRM-PolicyEvaluation'=>$PolicyText};
my $Control={ConfigItemID=>90,Class=>'Control',Name=>'Root Control','DynamicField_ZRM-CIInstance'=>1,'DynamicField_ZRM-ControlObjective'=>50};
my %P=(Script=>$Script,Objective=>$Objective,Control=>$Control,ConfigItemID=>90,UserID=>1,Now=>$Now);
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'Fail','Runtime executes actual finding pipeline');
is(scalar keys %{$Kernel::OM->{Risks}},1,'One Risk per Application and RiskStatement');
my ($Risk) = values %{$Kernel::OM->{Risks}};
is($Risk->{Name},'Alpha: A-1 - Unsupported Product - Root','Risk name identifies Application, statement and Product');
is_deeply($Risk->{'DynamicField_MELT-RelatedCI'},[1,10,11,12,13],'Risk links source Product and affected CIs');
is($Risk->{'DynamicField_MELT-RMF'},60,'Framework follows RiskStatement');
is($Risk->{'DynamicField_MELT-EventSeverity'},72,'Initial distant EOSL is Medium');
is($Kernel::OM->{Saved}{'ZRM-Result'},'Fail','Control result saved');
ok($Kernel::OM->{Saved}{'ZRM-LastRun'},'Successful evaluation stores cycle timestamp');
$Runtime->_TargetEvaluate(%P);
is(scalar keys %{$Kernel::OM->{Risks}},1,'Repeated scan reuses Application Risk');
$Kernel::OM->{Objects}{2}{'DynamicField_ZTAM-EoServiceLife'}='2025-01-01';
$Kernel::OM->{Objects}{15}={ConfigItemID=>15,Class=>'Workload',Name=>'New Workload',
    'DynamicField_ZTAM-Model'=>2,'DynamicField_ZTAM-Application'=>100};
$Control->{'DynamicField_ZRM-CIInstance'}=2;$Control->{ConfigItemID}=91;$P{ConfigItemID}=91;
$Runtime->_TargetEvaluate(%P);
is(scalar keys %{$Kernel::OM->{Risks}},2,'Second failing Product creates its own Risk');
my ($ChildRisk)=grep { $_->{'DynamicField_MELT-Reference'} =~ /:2$/ } values %{$Kernel::OM->{Risks}};
is_deeply($ChildRisk->{'DynamicField_MELT-RelatedCI'},[2,11,12,13,15],'Child Product Risk links source and affected CIs');
is($ChildRisk->{'DynamicField_MELT-EventSeverity'},70,'Child Product EOSL sets Critical severity');
is($Risk->{'DynamicField_MELT-EventSeverity'},72,'Root Product Risk retains its own severity');
ok((grep {($_->{Payload}{ControlID}||0)==91} @{$Kernel::OM->{Activities}}),'Second Product retains its own contribution evidence');
is($Risk->{'DynamicField_MELT-Control'},90,'Root Risk keeps its Control');
is($ChildRisk->{'DynamicField_MELT-Control'},91,'Child Risk records its Control');
$Kernel::OM->{Objects}{2}{'DynamicField_ZTAM-EoServiceLife'}='2035-01-01';
my $Searches=$Kernel::OM->{Searches};
$R=$Runtime->_TargetEvaluate(%P);
is($R->{Status},'Pass','Own recovered Product passes');
is($Kernel::OM->{Searches},$Searches,'Passing Control does not inspect other objects');
is(scalar keys %{$Kernel::OM->{Risks}},2,'Recovery preserves both Product Risks');
my $Watcher=$Runtime->ProcessFailedControl(%P,Result=>'Fail');
ok($Watcher->{Success} && !$Watcher->{RiskCreated},'Result watcher does not duplicate finding-owned Risk creation');

Setup();
$Control->{'DynamicField_ZRM-CIInstance'}=1;
$Control->{ConfigItemID}=90;
$P{ConfigItemID}=90;
$Objective->{'DynamicField_ZRM-RiskStmt'}=[50,51];
$Kernel::OM->{Objects}{13}{'DynamicField_ZTAM-Application'}=101;
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'Fail','Multiple statements and Applications evaluate');
is(scalar keys %{$Kernel::OM->{Risks}},4,'One Risk for each Application and RiskStatement');
my @Alpha = grep { $_->{'DynamicField_MELT-RelatedGO'} == 100 } values %{$Kernel::OM->{Risks}};
my @Beta = grep { $_->{'DynamicField_MELT-RelatedGO'} == 101 } values %{$Kernel::OM->{Risks}};
is(scalar @Alpha,2,'Both statements create Alpha Risks');
is(scalar @Beta,2,'Both statements create Beta Risks');
is_deeply([sort { $a <=> $b } @{$Beta[0]{'DynamicField_MELT-RelatedCI'}}],[1,13],'Beta Risk links Product and Beta CI');

Setup();
$Objective->{'DynamicField_ZRM-RiskStmt'}=[50];
$R=$Runtime->_AutomaticEvaluate(%P);
my $FirstEpisode=$Kernel::OM->{Risks}{200};
is($FirstEpisode->{'DynamicField_MELT-EventStatus'},'Active','New Risk episode starts Active');
$FirstEpisode->{'DynamicField_MELT-EventStatus'}='Closed';
$R=$Runtime->_AutomaticEvaluate(%P);
is(scalar keys %{$Kernel::OM->{Risks}},2,'Closed event causes a new Risk episode');
is($FirstEpisode->{'DynamicField_MELT-EventStatus'},'Closed','Prior episode remains closed');
is($Kernel::OM->{Risks}{201}{'DynamicField_MELT-Reference'},
   $FirstEpisode->{'DynamicField_MELT-Reference'},'New episode retains the same Product group identity');
$R=$Runtime->_AutomaticEvaluate(%P);
is(scalar keys %{$Kernel::OM->{Risks}},2,'Subsequent failure reuses the new Active episode');
$Kernel::OM->{Risks}{201}{ZTSMStatusID}=3;
$R=$Runtime->_AutomaticEvaluate(%P);
is(scalar keys %{$Kernel::OM->{Risks}},3,'Closed governance status also starts a new episode');
is($Kernel::OM->{Risks}{202}{'DynamicField_MELT-EventStatus'},'Active','Latest episode starts Active');

$Objective->{'DynamicField_ZRM-RiskStmt'}=[50];
Setup();
$Kernel::OM->{Objects}{1}{'DynamicField_ZTAM-EoServiceLife'}='2027-03-21';
$R=$Runtime->_AutomaticEvaluate(%P);
my ($HighRisk)=values %{$Kernel::OM->{Risks}};
is($HighRisk->{'DynamicField_MELT-EventSeverity'},71,'Before six calendar months is High');
$Kernel::OM->{Objects}{1}{'DynamicField_ZTAM-EoServiceLife'}='2027-03-22';
$R=$Runtime->_AutomaticEvaluate(%P);
is($HighRisk->{'DynamicField_MELT-EventSeverity'},71,'Six-month boundary cannot downgrade partial Risk');
Setup();
$Kernel::OM->{Objects}{10}{'DynamicField_ZTAM-Application'}=undef;
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'UNKNOWN','Missing Application fails closed');
is(scalar keys %{$Kernel::OM->{Risks}},0,'Missing Application prevents all Risk writes');
Setup();
$Kernel::OM->{Governance}{50}{'DynamicField_ZRM-RMF'}=undef;
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'UNKNOWN','Missing RiskStatement Framework fails closed');
is(scalar keys %{$Kernel::OM->{Risks}},0,'Missing Framework prevents all Risk writes');
Setup();
my $CustomAssignment = YAML::XS::Load($RiskText);
$CustomAssignment->{RETURN}{'GROUP FINDINGS'}{'GROUP BY'}{FIELD}='ZTAM-ApplicationAlternate';
$CustomAssignment->{RETURN}{'GROUP FINDINGS'}{NAME}='{GROUP.Name}: {ITEM.Name} [configured]';
$CustomAssignment->{RETURN}{'GROUP FINDINGS'}{SEVERITY}{RULES}[1]{WHEN}
    ='DATE(@SOURCE.ZTAM-EoServiceLife) IS LESS THAN DATE(TODAY + 3 MONTHS)';
$Objective->{'DynamicField_ZRM-FieldAssignment'}=YAML::XS::Dump($CustomAssignment);
$Kernel::OM->{Objects}{$_}{'DynamicField_ZTAM-ApplicationAlternate'}=101 for (10,11,12,13);
$Kernel::OM->{Objects}{1}{'DynamicField_ZTAM-EoServiceLife'}='2027-01-01';
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'Fail','Changed authored assignment still executes');
my ($ConfiguredRisk)=values %{$Kernel::OM->{Risks}};
is($ConfiguredRisk->{'DynamicField_MELT-RelatedGO'},101,'YAML-selected grouping field controls Application');
is($ConfiguredRisk->{Name},'Beta: Unsupported Product [configured]','YAML template controls Risk name');
is($ConfiguredRisk->{'DynamicField_MELT-EventSeverity'},72,'YAML three-month rule changes severity without Perl edit');
Setup();
my $SimpleGroup = YAML::XS::Load($RiskText);
my $GroupProgram = $SimpleGroup->{RETURN}{'GROUP FINDINGS'};
delete $GroupProgram->{'FOR EACH'};
delete $GroupProgram->{RESOLVE};
delete $GroupProgram->{SEVERITY};
delete $GroupProgram->{'FIELD ASSIGNMENTS'}{$_} for qw(MELT-RiskStmt MELT-RMF MELT-EventSeverity);
delete $GroupProgram->{MERGE}{'MELT-EventSeverity'};
$GroupProgram->{IDENTITY}{TEMPLATE}='{SCENARIO.Value}:{GROUP.GovernanceObjectID}';
$GroupProgram->{NAME}='{GROUP.Name}: generic group';
$Objective->{'DynamicField_ZRM-FieldAssignment'}=YAML::XS::Dump($SimpleGroup);
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'Fail','Grouped program works without severity or item iteration');
is(scalar keys %{$Kernel::OM->{Risks}},1,'Optional iteration does not multiply Risks');
my ($SimpleRisk)=values %{$Kernel::OM->{Risks}};
is($SimpleRisk->{Name},'Alpha: generic group','Generic YAML names the grouped Risk');
$Objective->{'DynamicField_ZRM-FieldAssignment'}=$RiskText;

Setup();
my $ContractProgram = YAML::XS::Load($RiskText)->{RETURN}{'GROUP FINDINGS'};
$ContractProgram->{SCENARIO}='Contract coverage';
$ContractProgram->{'GROUP BY'}{FROM}='FINDING.Entitlement';
$ContractProgram->{'GROUP BY'}{'MEMBER FROM'}='FINDING.Entitlement.ConfigItemID';
$ContractProgram->{'GROUP BY'}{'MEMBERS AS'}='EntitlementIDs';
delete $ContractProgram->{'GROUP BY'}{'INCLUDE MEMBERS'};
delete $ContractProgram->{'FOR EACH'};
delete $ContractProgram->{RESOLVE};
delete $ContractProgram->{SEVERITY};
delete $ContractProgram->{'FIELD ASSIGNMENTS'}{$_} for qw(MELT-RiskStmt MELT-RMF MELT-EventSeverity);
delete $ContractProgram->{MERGE}{'MELT-EventSeverity'};
$ContractProgram->{'FIELD ASSIGNMENTS'}{'MELT-RelatedCI'}='@GROUP.EntitlementIDs';
$ContractProgram->{IDENTITY}{TEMPLATE}='{SCENARIO.Value}:{GROUP.GovernanceObjectID}:{SOURCE.GovernanceObjectID}';
$ContractProgram->{NAME}='{GROUP.Name}: {SOURCE.Name}';
my $ContractResult=$Runtime->_GroupedFindingRisksCreate(
    Rule=>$ContractProgram, Destination=>'MELTObject.Risk', Objective=>$Objective,
    SourceObject=>{GovernanceObjectID=>500,Name=>'Agreement X'}, Control=>$Control,
    Evaluation=>{Findings=>[{Entitlement=>{ConfigItemID=>777,Name=>'Contract Entitlement',
        'DynamicField_ZTAM-Application'=>100}}]},
    ConfigItemID=>90, Now=>$Now, UserID=>1,
);
is(scalar @{$ContractResult},1,'Contract-shaped finding uses the same grouped operator');
my ($ContractRisk)=values %{$Kernel::OM->{Risks}};
is($ContractRisk->{'DynamicField_MELT-Reference'},'Contract coverage:100:500','Contract YAML controls identity');
is($ContractRisk->{Name},'Alpha: Agreement X','Contract YAML controls Risk name');
is_deeply($ContractRisk->{'DynamicField_MELT-RelatedCI'},[777],'Contract YAML controls member collection');

Setup();$Control->{'DynamicField_ZRM-CIInstance'}=1;
$Objective->{'DynamicField_ZRM-CreateRisk'}=0;
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'Fail','Unchecked Risk gate still records failure');
is(scalar keys %{$Kernel::OM->{Risks}},0,'Unchecked gate creates no Risk');
$Objective->{'DynamicField_ZRM-CreateRisk'}=1;
Setup();$Kernel::OM->{Busy}=1;
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'UNKNOWN','Busy Risk identity retries safely');
ok(!exists $Kernel::OM->{Saved}{'ZRM-LastRun'},'Failed Risk execution does not advance cycle');
Setup();$Kernel::OM->{Objects}{1}{'DynamicField_ZTAM-EoServiceLife'}='invalid';
$R=$Runtime->_AutomaticEvaluate(%P);
is($R->{Status},'UNKNOWN','Automatic entry point rejects invalid dates');
is(scalar keys %{$Kernel::OM->{Risks}},0,'Invalid evaluation creates no Risk');
ok(!exists $Kernel::OM->{Saved}{'ZRM-Result'},'Invalid evaluation does not overwrite result with Pass');

# The same authored check can emit its bound target directly. No Product graph,
# asset field, or class-based descendant traversal is required.
for my $TargetType (qw(ITSMConfigItem.Workload GovernanceObject.Application MELTObject.Risk Ticket)) {
    Setup();
    my $IDField = $TargetType =~ /^ITSMConfigItem/ ? 'ConfigItemID'
        : $TargetType =~ /^GovernanceObject/ ? 'GovernanceObjectID'
        : $TargetType =~ /^MELTObject/ ? 'MELTObjectID' : 'TicketID';
    my $Target = { $IDField => 55, Name => $TargetType };
    my $Direct = {
        VERSION => 1, TARGET => $TargetType,
        CHECK => { EXPECT => "NUMBER(\@THIS.$IDField) IS GREATER THAN NUMBER(100)" },
        'ON FAIL' => { 'EMIT FINDING' => 'THIS' },
    };
    my $Result = $Engine->PolicyEvaluate(
        Script => $Direct, TargetType => $TargetType, Now => $Now,
        UserID => 1, Context => { THIS => $Target },
    );
    is($Result->{Status}, 'Fail', "$TargetType can fail its own policy") or diag explain $Result;
    is($Result->{Findings}[0]{Target}{$IDField}, 55, "$TargetType finding is its bound target");
    is($Kernel::OM->{Searches}, 0, "$TargetType direct finding does not search assets");
    $Target->{$IDField} = 150;
    $Result = $Engine->PolicyEvaluate(
        Script => $Direct, TargetType => $TargetType, Now => $Now,
        UserID => 1, Context => { THIS => $Target },
    );
    is($Result->{Status}, 'Pass', "$TargetType can pass its own policy");
    is(scalar @{$Result->{Findings}}, 0, "$TargetType pass emits no finding");
}
done_testing();
