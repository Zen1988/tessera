use strict;
use warnings;
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
    'DynamicField_ZRM-MasterTicket' => 'mapping YAML',
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
        return { Class => 'Application' } if $Param{GovernanceObjectID} == 1493;
        return;
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
$Tickets{202}{State} = 'closed rejected';
ok( $Runtime->Ensure( RiskID => 21 ), 'a rejected Approval cycle starts another mapped master SR' );
is( $CreateCount, 3, 'a rejected cycle creates one replacement SR' );
$RiskStatus = 'Closed';
ok( $Runtime->Ensure( RiskID => 21 ), 'closed Risk is not restarted' );
is( $CreateCount, 3, 'a successfully treated Risk does not create another SR' );

done_testing();
