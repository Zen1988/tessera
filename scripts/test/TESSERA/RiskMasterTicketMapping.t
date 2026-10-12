use strict;
use warnings;
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptBlocks qw(SplitSource);
use Test::More;
use File::Spec;
use FindBin;

my $Root = File::Spec->catdir( $FindBin::Bin, '..', '..', '..' );
my $SourceFile = File::Spec->catfile(
    $Root, qw(Kernel Package GovernanceDB Kernel System TESSERA RiskMasterTicket.pm)
);
open my $FH, '<', $SourceFile or die "Cannot read $SourceFile: $!";
local $/;
my $Source = <$FH>;
close $FH;
$Source =~ s{^use Kernel::[^;]+;\r?\n}{}mg;
{ no strict 'refs'; *{'Kernel::System::TESSERA::RiskMasterTicket::ObjectSource'} = \&Kernel::System::TESSERA::ScriptBlocks::ObjectSource; }
my $Loaded = eval $Source;
die $@ if $@;

my $RuntimeOverlayFile = File::Spec->catfile(
    $Root, qw(Kernel Package GovernanceDB var governancedb runtime_overlay Kernel System ZTSMBlueBookRuntime.pm)
);
open my $RuntimeOverlayFH, '<', $RuntimeOverlayFile
    or die "Cannot read $RuntimeOverlayFile: $!";
my $RuntimeOverlay = do { local $/; <$RuntimeOverlayFH> };
close $RuntimeOverlayFH;
like(
    $RuntimeOverlay,
    qr/sub RiskAssessmentAutomationEvidenceEnsure\s*\{/,
    'packaged runtime overlay exports the evidence bridge used by risk reconciliation',
);
like(
    $RuntimeOverlay,
    qr/RiskAssessmentAutomationEvidenceEnsure\(\s*TicketID => \$NewTicketID\s*\).*?\$ChildType eq 'Assessment'/s,
    'new originating-Risk Assessments receive the Framework evidence bridge',
);

{
    no strict 'refs';
    *{'Kernel::System::TESSERA::RiskMasterTicket::ZTSMArticleCreate'} = sub { push @main::Articles, { @_ }; return 1 };
    *{'Kernel::System::ZTSMBlueBookRuntime::RiskAssessmentAutomationEvidenceEnsure'} = sub { return 1 };
}
$INC{'Kernel/System/ZTSMBlueBookRuntime.pm'} = __FILE__;

our $Framework = {
    Class => 'Framework', Name => 'Infrastructure Risk Framework',
    'DynamicField_MasterTicket' => SplitSource(Field=>'MasterTicket',Source=>'mapping YAML'),
};
our $Mapping = {
    Type => 'ServiceRequest', Service => 'Risk',
    CustomerUser => 'tessera@ica.gov.sg', Title => 'EOSL: ICA IaaS Extension',
    'ZRM-OriginatedEvent' => 21, 'ZTicket-Application' => [1493],
    'ZTicket-StateBook' => 165,
};
our %Tickets;
our $CreateCount = 0;
our @FieldSetOrder;
our @Articles;
our $OwnerResult = {Success=>1,Value=>1777,ValueType=>'GovernanceObject.SupportProfile'};
our $OwnerLookups = 0;
our $OwnerMatches = [1776];
our $RiskStatus = 'Active';

{
    package RiskMasterTestOM;
    sub new { return bless {}, shift }
    sub Get { return $_[0] }
    sub PIDCreate { return 1 }
    sub PIDDelete { return 1 }
    sub MELTObjectGet {
        return {
            MELTObjectID => 21, Class => 'Risk', Name => 'EOSL: ICA IaaS Extension',
            Number => 'GO-RISK-00000021', 'DynamicField_MELT-RMF' => [1597],
            'DynamicField_MELT-EventStatus' => $main::RiskStatus,
        };
    }
    sub MELTObjectSearch {
        my ( $Self, %Param ) = @_;
        die 'reconciliation narrowed by dynamic field' if exists $Param{'DynamicField_MELT-RMF'};
        return (21);
    }
    sub GovernanceObjectGet {
        my ( $Self, %Param ) = @_;
        return $main::Framework if $Param{GovernanceObjectID} == 1597;
        return { Class => 'StateBook' } if $Param{GovernanceObjectID} == 165;
        return {Class=>'GovernanceRole',Name=>'APPLICATION::DEFAULT',GovernanceObjectID=>1776} if $Param{GovernanceObjectID} == 1776;
        return {Class=>'SupportProfile',GovernanceObjectID=>1777} if $Param{GovernanceObjectID} == 1777;
        return { Class => 'Application' } if $Param{GovernanceObjectID} == 1493;
        return;
    }
    sub GovernanceObjectSearch { return @{$main::OwnerMatches} }
    sub Resolve {
        my ($Self,%P)=@_;
        $main::OwnerLookups++;
        die 'wrong application context' if $P{Ticket}{'DynamicField_ZTicket-Application'} != 1493;
        die 'wrong master role' if $P{GovernanceRole}{GovernanceObjectID} != 1776;
        return $main::OwnerResult;
    }
    sub FieldAssignmentsEvaluate {
        my ( $Self, %Param ) = @_;
        return { Success => 0, Error => 'wrong target' }
            if $Param{ObjectType} ne 'Ticket' || $Param{Class} ne 'ServiceRequest'
            || $Param{Context}{RISK}{MELTObjectID} != 21
            || $Param{Context}{FRAMEWORK}{Class} ne 'Framework';
        return { Success => 1, Value => $main::Mapping };
    }
    sub ServiceList { return ( 341 => 'Risk' ) }
    sub ServiceGet { return ( DestQueueID => 2 ) }
    sub CustomerUserDataGet {
        return ( UserLogin => 'tessera@ica.gov.sg', UserCustomerID => 'ICA' );
    }
    sub TicketSearch {
        my ( $Self, %Param ) = @_;
        my @IDs = grep {
            ( $main::Tickets{$_}{'DynamicField_ZRM-OriginatedEvent'} || '' ) == 21
        } keys %main::Tickets;
        if ( $Param{Types} ) {
            my %Types = map { $_ => 1 } @{ $Param{Types} };
            @IDs = grep { $Types{ $main::Tickets{$_}{Type} || '' } } @IDs;
        }
        return @IDs;
    }
    sub TicketCreate {
        my ( $Self, %Param ) = @_;
        my $ID = 200 + ++$main::CreateCount;
        $main::Tickets{$ID} = { %Param, TicketID => $ID };
        return $ID;
    }
    sub TicketGet {
        my ( $Self, %Param ) = @_;
        return %{ $main::Tickets{ $Param{TicketID} } || {} };
    }
    sub DynamicFieldGet {
        my ( $Self, %Param ) = @_;
        return { Name => $Param{Name}, ObjectType => 'Ticket' };
    }
    sub ValueSet {
        my ( $Self, %Param ) = @_;
        push @main::FieldSetOrder, $Param{DynamicFieldConfig}{Name};
        $main::Tickets{ $Param{ObjectID} }{
            'DynamicField_' . $Param{DynamicFieldConfig}{Name}
        } = $Param{Value};
        return 1;
    }
    sub Log { return 1 }
}

$Kernel::OM = RiskMasterTestOM->new();
my $Runtime = Kernel::System::TESSERA::RiskMasterTicket->new();
ok( $Runtime->Ensure( RiskID => 21 ), 'empty StateBook leaves Risk unrouted' );
is( $CreateCount, 0, 'no SR is created before StateBook selection' );

$Framework->{'DynamicField_ZRM-RiskMgtStateBook'} = [165];
ok( $Runtime->Ensure( RiskID => 21 ), 'configured Framework creates master SR' );
is( $CreateCount, 1, 'exactly one master SR is created' );
is( $Tickets{201}{Type}, 'ServiceRequest', 'ticket type comes from mapping' );
is( $Tickets{201}{ServiceID}, 341, 'Risk service is resolved by name' );
is( $Tickets{201}{CustomerUser}, 'tessera@ica.gov.sg', 'dedicated requester is used' );
is( $Tickets{201}{'DynamicField_ZRM-OriginatedEvent'}, 21, 'SR links originating MELT Risk' );
is( $Tickets{201}{'DynamicField_ZTicket-Application'}, 1493, 'SR carries the mapped Application' );
is( $Tickets{201}{'DynamicField_ZTicket-StateBook'}, 165, 'SR uses Framework StateBook' );
is_deeply( \@FieldSetOrder,
    [ 'ZRM-OriginatedEvent', 'ZTicket-Application', 'ZTicket-StateBook' ],
    'Application is saved before StateBook starts orchestration' );
delete $Tickets{201}{'DynamicField_ZTicket-Application'};
ok( $Runtime->Ensure( RiskID => 21 ), 'an orchestrated SR is reused without changing its Application snapshot' );
ok( !exists $Tickets{201}{'DynamicField_ZTicket-Application'}, 'the immutable Application snapshot stays untouched' );
$Tickets{201}{'DynamicField_ZTicket-Application'} = 1493;
ok( $Runtime->Ensure( RiskID => 21 ), 'repeated dispatch succeeds' );
is( $CreateCount, 1, 'repeated dispatch does not create another SR' );
ok( $Runtime->Run(), 'scheduled reconciliation scans existing Risks' );
is( $CreateCount, 1, 'scheduled reconciliation reuses the master SR' );
$Tickets{201}{State} = 'closed unsuccessful';
ok( $Runtime->Ensure( RiskID => 21 ), 'an unsuccessful closed cycle starts a new master SR' );
is( $CreateCount, 2, 'a failed cycle creates exactly one replacement SR' );
is( $Tickets{201}{State}, 'closed unsuccessful', 'the failed ServiceRequest remains as history' );
is( $Tickets{202}{'DynamicField_ZRM-OriginatedEvent'}, 21, 'the new ServiceRequest maps to the same Risk' );
like( $Articles[-1]{Body}, qr/Previous ServiceRequest: 201/, 'restart evidence points to the prior cycle' );
ok( $Runtime->Ensure( RiskID => 21 ), 'reconciliation reuses the active replacement cycle' );
is( $CreateCount, 2, 'scheduled retry does not duplicate a replacement SR' );
$Mapping->{'ZRM-Framework'} = [1597];
$Tickets{202}{State} = 'closed rejected';
ok( $Runtime->Ensure( RiskID => 21 ), 'a rejected Approval cycle starts another mapped master SR' );
is( $CreateCount, 3, 'a rejected cycle creates one replacement SR' );
is($Tickets{203}{'DynamicField_ZRM-Framework'},1597,'mapped Framework is persisted on the fresh master');
my @NewOrder = @FieldSetOrder[-4..-1];
is_deeply(\@NewOrder,['ZRM-OriginatedEvent','ZRM-Framework','ZTicket-Application','ZTicket-StateBook'],'mapped Framework is written before orchestration starts');
delete $Tickets{203}{'DynamicField_ZRM-Framework'};
ok($Runtime->Ensure(RiskID=>21),'reconciliation preserves orchestrated master snapshot');
ok(!exists $Tickets{203}{'DynamicField_ZRM-Framework'},'existing orchestrated master is not backfilled');
$Tickets{203}{State} = 'closed cancelled';
ok($Runtime->Run(),'scheduled reconciliation restarts a cancelled active Risk cycle');
is($CreateCount,4,'cancellation creates exactly one fresh master');
is($Tickets{203}{State},'closed cancelled','cancelled ledger remains unchanged');
is($Tickets{204}{'DynamicField_ZRM-OriginatedEvent'},21,'replacement remains linked to originating Risk');
like($Articles[-1]{Body},qr/Previous ServiceRequest: 203/,'replacement evidence references cancelled cycle');
ok($Runtime->Run(),'repeat reconciliation reuses replacement');
is($CreateCount,4,'repeat job does not create duplicate replacement');
$Tickets{204}{State} = 'closed canceled';
ok($Runtime->Ensure(RiskID=>21),'alternate canceled spelling also restarts');
is($CreateCount,5,'alternate cancellation creates one replacement');
$Tickets{205}{State} = 'closed successful';
ok($Runtime->Run(),'successful cycle is retained');
is($CreateCount,5,'success does not restart');
$Tickets{205}{State} = 'closed cancelled';
$RiskStatus = 'Closed';
ok( $Runtime->Ensure( RiskID => 21 ), 'closed Risk is not restarted' );
is( $CreateCount, 5, 'a closed Risk does not create another SR even if its last cycle was cancelled' );

$RiskStatus = 'Active';
$Mapping->{'ZTicket-OwnerGroup'} = 'APPLICATION::DEFAULT';
ok($Runtime->Ensure(RiskID=>21),'Framework role mapping creates fresh owned cycle');
is($Tickets{206}{'DynamicField_ZTicket-OwnerGroup'},1777,'master stores resolved SupportProfile, not role');
is_deeply([@FieldSetOrder[-5..-1]],['ZRM-OriginatedEvent','ZRM-Framework','ZTicket-Application','ZTicket-OwnerGroup','ZTicket-StateBook'],'risk ownership established before orchestration');
is($OwnerLookups,1,'shared role resolver used once for fresh master');
$OwnerResult = {Success=>0,Error=>'RoleMap is ambiguous'};
ok($Runtime->Ensure(RiskID=>21),'active master preserved despite later role change');
is($OwnerLookups,1,'existing cycle does not reevaluate its owner');
is($Tickets{206}{'DynamicField_ZTicket-OwnerGroup'},1777,'original owner retained');
$Tickets{206}{State}='closed unsuccessful';
ok(!$Runtime->Ensure(RiskID=>21),'ambiguous role prevents new cycle');
is($CreateCount,6,'failed ownership does not create orphan ticket');
$OwnerResult = {Success=>1,Value=>[1777,1778],ValueType=>'GovernanceObject.SupportProfile'};
ok(!$Runtime->Ensure(RiskID=>21),'multiple owners rejected');
$OwnerResult = {Success=>1,Value=>1493,ValueType=>'GovernanceObject.Organization'};
ok(!$Runtime->Ensure(RiskID=>21),'wrong typed resolver output rejected');
$OwnerResult = {Success=>1,Value=>1493,ValueType=>'GovernanceObject.SupportProfile'};
ok(!$Runtime->Ensure(RiskID=>21),'wrong actual object class rejected');
$OwnerMatches = [];
ok(!$Runtime->Ensure(RiskID=>21),'missing role rejected before creation');
$OwnerMatches = [1776,1776];
ok(!$Runtime->Ensure(RiskID=>21),'ambiguous role name rejected before creation');
$Mapping->{'ZTicket-OwnerGroup'} = 1777;
ok($Runtime->Ensure(RiskID=>21),'policy may map SupportProfile directly');
is($Tickets{207}{'DynamicField_ZTicket-OwnerGroup'},1777,'direct SupportProfile stored');
is($CreateCount,7,'valid direct mapping creates one replacement');

# Exercise the real application RoleMap -> ScriptEngine -> shared resolver chain.
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::GovernanceRoleResolver;
use Kernel::System::TESSERA::ScriptEngine;
use YAML::XS ();
our $RoleRows = [{GovernanceRole=>1776,SupportProfile=>1777}];
{ package RiskMasterRealRoleOM;
    our @ISA = ('RiskMasterTestOM');
    sub Get {
        my ($Self,$Name)=@_;
        return Kernel::System::TESSERA::GovernanceRoleResolver->new() if $Name eq 'Kernel::System::TESSERA::GovernanceRoleResolver';
        return Kernel::System::TESSERA::ScriptEngine->new() if $Name eq 'Kernel::System::TESSERA::ScriptEngine';
        return $Self;
    }
    sub Load {my ($Self,%P)=@_;return YAML::XS::Load($P{Data})}
    sub GovernanceObjectGet {
        my ($Self,%P)=@_;
        return {Class=>'Application',GovernanceObjectID=>1493,'DynamicField_RoleMap'=>$main::RoleRows} if $P{GovernanceObjectID}==1493;
        return {Class=>'GovernanceRole',Name=>'APPLICATION::DEFAULT',GovernanceObjectID=>1776,'DynamicField_ScriptEngine'=>Kernel::System::TESSERA::ScriptBlocks::SplitSource(Field=>'ScriptEngine',Source=>"VERSION: 1\nLET THIS: TICKET\nRETURN:\n  VALUE: THIS.ZTicket-Application.RoleMap[GovernanceRole=CURRENT OBJECT].SupportProfile\n  AS: GovernanceObject.SupportProfile\n")} if $P{GovernanceObjectID}==1776;
        return $Self->SUPER::GovernanceObjectGet(%P);
    }
}
$OwnerMatches=[1776];
$Kernel::OM=RiskMasterRealRoleOM->new();
my $Owner=$Runtime->_OwnerGroupResolve(Value=>'APPLICATION::DEFAULT',ApplicationID=>1493,CustomerUser=>'tessera@ica.gov.sg');
is($Owner,1777,'real shared resolver uses Application default RoleMap profile');
$RoleRows=[{GovernanceRole=>1776,SupportProfile=>1777},{GovernanceRole=>1776,SupportProfile=>1777}];
my $Ambiguous=eval {$Runtime->_OwnerGroupResolve(Value=>'APPLICATION::DEFAULT',ApplicationID=>1493)};
ok(!$Ambiguous,'real RoleMap ambiguity fails closed');like($@,qr/exactly one row/,'real role error explains ambiguous mapping');
$RoleRows=[];
eval {$Runtime->_OwnerGroupResolve(Value=>'APPLICATION::DEFAULT',ApplicationID=>1493)};
like($@,qr/exactly one row/,'missing Application RoleMap fails closed');

done_testing();

