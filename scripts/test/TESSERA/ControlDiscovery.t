use strict;
use warnings;
use Test::More;
use YAML::XS ();
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::TESSERA::ScriptEngine;
use Kernel::System::TESSERA::ControlDiscovery;

{
    package DiscoveryAdapters;
    sub Get {
        my ( $Self, $Type ) = @_;
        return $Self->{Engine} if $Type eq 'Kernel::System::TESSERA::ScriptEngine';
        die 'MELT absent' if $Type eq 'Kernel::System::MELTObject' && $Self->{NoMELT};
        return $Self;
    }
    sub Load { my ( $Self, %P ) = @_; YAML::XS::Load($P{Data}) }
    sub PIDCreate { !$_[0]->{Busy} }
    sub PIDDelete { $_[0]->{Unlocked}++; 1 }
    sub Log { my ( $Self, %P ) = @_; push @{ $Self->{Logs} }, $P{Message}; 1 }
    sub ItemList {
        my ( $Self, %P ) = @_;
        return { 1 => 'Control', 4 => 'Product' } if $P{Class} eq 'ITSM::ConfigItem::Class';
        return { 2 => 'Production' } if $P{Class} eq 'ITSM::ConfigItem::DeploymentState';
        return { 3 => 'Operational' };
    }
    sub DefinitionGet { return { DynamicFieldRef => { map { $_ => {} } qw(ZRM-ControlObjective ZRM-CIInstance ZRM-GOInstance ZRM-MOInstance ZRM-TKInstance) } } }
    sub GovernanceObjectGet {
        my ( $Self, %P ) = @_;
        return $Self->{Objective} if $P{GovernanceObjectID} == 50;
        return $Self->{Targets}{ $P{GovernanceObjectID} };
    }
    sub ConfigItemGet {
        my ( $Self, %P ) = @_;
        return $Self->{Controls}{ $P{ConfigItemID} } || $Self->{Targets}{ $P{ConfigItemID} };
    }
    sub MELTObjectGet { my ( $Self, %P ) = @_; $Self->{Targets}{ $P{MELTObjectID} } }
    sub TicketGet { my ( $Self, %P ) = @_; %{ $Self->{Targets}{ $P{TicketID} } || {} } }
    sub ConfigItemSearch {
        my ( $Self, %P ) = @_;
        if ( $P{Classes}[0] eq 'Control' ) { return sort keys %{ $Self->{Controls} }; }
        $Self->{LastSearch} = \%P;
        return sort keys %{ $Self->{Targets} };
    }
    sub GovernanceObjectSearch {
        my ( $Self, %P ) = @_;
        return (50) if $P{Classes}[0] eq 'ControlObjective';
        $Self->{LastSearch} = \%P;
        return sort keys %{ $Self->{Targets} };
    }
    sub MELTObjectSearch { my ( $Self, %P ) = @_; $Self->{LastSearch} = \%P; sort keys %{ $Self->{Targets} } }
    sub TicketSearch { my ( $Self, %P ) = @_; $Self->{LastSearch} = \%P; sort keys %{ $Self->{Targets} } }
    sub ConfigItemAdd {
        my ( $Self, %P ) = @_;
        my $ID = 100 + scalar keys %{ $Self->{Controls} };
        $Self->{Controls}{$ID} = { %P, ConfigItemID => $ID, Class => 'Control' };
        return $ID;
    }
}
my $Engine = Kernel::System::TESSERA::ScriptEngine->new();
my $Discovery = Kernel::System::TESSERA::ControlDiscovery->new();
sub Setup {
    my ( $Kind, $Class, $Key ) = @_;
    my $Typed = $Kind eq 'Ticket' ? 'Ticket' : "$Kind.$Class";
    my $Script = {
        VERSION => 1, SEARCH => { FOR => $Kind, AS => 'Targets', LIMIT => 1000 },
        RETURN => { FROM => 'ALL Targets', AS => "Collection<$Typed>" },
    };
    $Script->{SEARCH}{CLASS} = $Class if $Kind ne 'Ticket';
    $Kernel::OM = bless {
        Engine => $Engine, Controls => {}, Targets => {
            10 => { $Key => 10, Class => $Class, Name => 'parent' },
            11 => { $Key => 11, Class => $Class, Name => 'child', 'DynamicField_ZTAM-EoServiceLife' => '' },
        },
        Objective => { GovernanceObjectID => 50, Class => 'ControlObjective', ZTSMStatus => 'Active', Name => 'Coverage',
            'DynamicField_ZRM-PolicyFilter' => YAML::XS::Dump($Script) },
    }, 'DiscoveryAdapters';
    return $Script;
}
for my $Case (
    [qw(ITSMConfigItem Product ConfigItemID ZRM-CIInstance)],
    [qw(GovernanceObject Application GovernanceObjectID ZRM-GOInstance)],
    [qw(MELTObject Risk MELTObjectID ZRM-MOInstance)],
    [qw(Ticket Ticket TicketID ZRM-TKInstance)],
) {
    my ( $Kind, $Class, $IDKey, $Field ) = @{$Case};
    Setup($Kind, $Class, $IDKey);
    my $Result = $Discovery->Reconcile( GovernanceObjectID => 50, UserID => 1 );
    ok($Result->{Success}, "$Kind discovery succeeds") or diag explain $Result;
    is($Result->{Created}, 2, "$Kind creates one Control per returned target");
    is_deeply([sort map { $_->{"DynamicField_$Field"} } values %{ $Kernel::OM->{Controls} }], [10,11], "$Kind uses its exact exported target field");
    ok(!(grep { exists $_->{'DynamicField_ZRM-Result'} } values %{ $Kernel::OM->{Controls} }), 'Discovery does not invent evaluation results');
    $Result = $Discovery->Reconcile( GovernanceObjectID => 50 );
    is($Result->{Created}, 0, 'Second reconciliation creates no duplicates');
    is($Result->{Reused}, 2, 'Second reconciliation reuses both Controls');
    $Kernel::OM->{Targets}{12} = { $IDKey => 12, Class => $Class, Name => 'new' };
    $Discovery->Run();
    is(scalar keys %{ $Kernel::OM->{Controls} }, 3, 'Periodic scan discovers a new target');
    $Kernel::OM->{Objective}{ZTSMStatus} = 'Inactive';
    $Kernel::OM->{Targets}{13} = { $IDKey => 13, Class => $Class };
    $Discovery->Run(Event => 'GovernanceObjectUpdate', Data => { GovernanceObjectID => 50 });
    is(scalar keys %{ $Kernel::OM->{Controls} }, 3, 'Inactive objective does not create targets');
}

my $Script = Setup(qw(ITSMConfigItem Product ConfigItemID));
$Script->{SEARCH}{LIMIT} = 1;
$Kernel::OM->{Objective}{'DynamicField_ZRM-PolicyFilter'} = YAML::XS::Dump($Script);
my $Result = $Discovery->Reconcile(GovernanceObjectID => 50);
ok(!$Result->{Success}, 'Truncated discovery rejected');
is(scalar keys %{ $Kernel::OM->{Controls} }, 0, 'Overflow writes no Controls');
is($Kernel::OM->{LastSearch}{Limit}, 2, 'Native adapter probes one beyond the authored limit');

Setup(qw(ITSMConfigItem Product ConfigItemID));
$Kernel::OM->{Targets} = {};
$Result = $Discovery->Reconcile(GovernanceObjectID => 50);
ok($Result->{Success}, 'Empty collection is a successful empty selection');
is($Result->{Created}, 0, 'Empty filter creates nothing');

Setup(qw(MELTObject Risk MELTObjectID));
$Kernel::OM->{NoMELT} = 1;
$Result = $Discovery->Reconcile(GovernanceObjectID => 50);
ok(!$Result->{Success}, 'Unavailable MELT fails closed');
is(scalar keys %{ $Kernel::OM->{Controls} }, 0, 'Unavailable MELT creates no Controls');

Setup(qw(ITSMConfigItem Product ConfigItemID));
$Kernel::OM->{Busy} = 1;
$Result = $Discovery->Reconcile(GovernanceObjectID => 50);
is($Result->{Status}, 'BUSY', 'Existing objective lock prevents concurrent reconciliation');
is(scalar keys %{ $Kernel::OM->{Controls} }, 0, 'Busy scan writes nothing');

Setup(qw(ITSMConfigItem Product ConfigItemID));
open my $Example, '<', 'Kernel/Package/GovernanceDB/var/governancedb/policy/control_discovery_products.yml' or die $!;
$Kernel::OM->{Objective}{'DynamicField_ZRM-PolicyFilter'} = do { local $/; <$Example> };
$Discovery->Run(Event => 'GovernanceObjectDynamicFieldUpdate_ZRM-PolicyFilter', Data => { GovernanceObjectID => 50 });
is(scalar keys %{ $Kernel::OM->{Controls} }, 2, 'Packaged paste-ready Product YAML creates both Controls through save handler');

Setup(qw(Ticket Ticket TicketID));
my $Native = $Engine->_ScriptNativeSearch(For => 'Ticket', Class => 'Ticket', Limit => 100, UserID => 1,
    Where => { Type => { EQUALS => 'Incident' }, State => { EQUALS => 'open' } });
ok($Native->{Success}, 'Ticket filters execute');
is_deeply($Kernel::OM->{LastSearch}{Types}, ['Incident'], 'Ticket Type maps to native Types');
is_deeply($Kernel::OM->{LastSearch}{States}, ['open'], 'Ticket State maps to native States');
done_testing();
