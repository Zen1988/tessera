package Kernel::System::TESSERA::ControlDiscovery;

use strict;
use warnings;
use Kernel::System::TESSERA::ScriptBlocks qw(ObjectSource);

our @ObjectDependencies = (
    'Kernel::System::GovernanceObject', 'Kernel::System::ITSMConfigItem',
    'Kernel::System::GeneralCatalog', 'Kernel::System::TESSERA::ScriptEngine',
    'Kernel::System::PID', 'Kernel::System::Log',
);

sub new { bless {}, shift }

# Called after an objective save, and periodically to cover newly added targets.
sub Run {
    my ( $Self, %Param ) = @_;
    my $GO = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $UserID = $Param{UserID} || 1;
    my @IDs;
    if ( $Param{Event} ) {
        return 1 if ref $Param{Data} ne 'HASH';
        my $ID = $Param{Data}->{GovernanceObjectID} || $Param{Data}->{ObjectID};
        return 1 if !$ID;
        @IDs = ($ID);
    }
    else {
        @IDs = $GO->GovernanceObjectSearch( Result => 'ARRAY', Classes => ['ControlObjective'], UserID => $UserID );
    }
    for my $ID (@IDs) {
        my $Result = $Self->Reconcile( GovernanceObjectID => $ID, UserID => $UserID );
        if ( !$Result->{Success} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message => "ControlDiscovery objective $ID: " . ( $Result->{Error} || 'failed' ),
            );
        }
    }
    return 1;
}

sub Reconcile {
    my ( $Self, %Param ) = @_;
    my $ID = $Param{GovernanceObjectID};
    return { Success => 0, Error => 'Need GovernanceObjectID.' } if !$ID;
    my $PID = $Kernel::OM->Get('Kernel::System::PID');
    my $Lock = "TESSERA.ControlDiscovery.$ID";
    return { Success => 1, Status => 'BUSY' } if !$PID->PIDCreate( Name => $Lock );
    my $Result = eval { $Self->_Reconcile( %Param, UserID => $Param{UserID} || 1 ) };
    my $Error = $@;
    $PID->PIDDelete( Name => $Lock );
    return $Result if !$Error && ref $Result eq 'HASH';
    return { Success => 0, Error => $Error || 'Discovery returned no result.' };
}

sub _Reconcile {
    my ( $Self, %Param ) = @_;
    my $GO = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $CI = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $ID = $Param{GovernanceObjectID};
    my $Objective = $GO->GovernanceObjectGet( GovernanceObjectID => $ID, DynamicFields => 1 );
    return { Success => 1, Status => 'INACTIVE' }
        if ref $Objective ne 'HASH' || ( $Objective->{Class} || '' ) ne 'ControlObjective'
            || ( $Objective->{ZTSMStatus} || '' ) ne 'Active';
    my $Source = eval { ObjectSource(Object => $Objective, Field => 'PolicyFilter') };
    return { Success => 0, Error => $@ } if $@;
    $Source = $Source->[0] if ref $Source eq 'ARRAY' && @{$Source} == 1;
    return { Success => 0, Error => 'Active ControlObjective needs a scalar PolicyFilter YAML script.' }
        if !defined $Source || ref $Source || $Source !~ /\S/;
    my $Engine = $Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine');
    my $Result = $Engine->ScriptEvaluate(
        Source => $Source, Complete => 1, UserID => $Param{UserID},
        Context => { 'CURRENT OBJECT' => $Objective, CONTROLOBJECTIVE => $Objective },
    );
    return { Success => 0, Error => $Result->{Error} || 'PolicyFilter failed.' } if !$Result->{Success};
    my $Type = $Result->{ValueType} || '';
    return { Success => 0, Error => 'PolicyFilter must return a typed object collection.' }
        if $Type !~ /\ACollection<(ITSMConfigItem|GovernanceObject|MELTObject|Ticket)(?:\.([A-Za-z][A-Za-z0-9_-]*))?>\z/
            || ref $Result->{Value} ne 'ARRAY';
    my ( $ObjectType, $Class ) = ( $1, $2 );
    my %Types = (
        ITSMConfigItem => [ 'ConfigItemID', 'ZRM-CIInstance' ],
        GovernanceObject => [ 'GovernanceObjectID', 'ZRM-GOInstance' ],
        MELTObject => [ 'MELTObjectID', 'ZRM-MOInstance' ],
        Ticket => [ 'TicketID', 'ZRM-TKInstance' ],
    );
    my ( $IDKey, $TargetField ) = @{ $Types{$ObjectType} };
    return { Success => 0, Error => 'Target class is required.' } if !$Class && $ObjectType ne 'Ticket';
    my %Targets;
    for my $Target ( @{ $Result->{Value} } ) {
        return { Success => 0, Error => 'PolicyFilter returned an invalid target.' }
            if ref $Target ne 'HASH' || ( $Class && ( $Target->{Class} || '' ) ne $Class )
                || ( $Target->{$IDKey} || '' ) !~ /\A[1-9][0-9]*\z/;
        $Targets{ $Target->{$IDKey} } = $Target;
    }
    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %Classes = reverse %{ $Catalog->ItemList( Class => 'ITSM::ConfigItem::Class', Valid => 1 ) || {} };
    my %Deploy = reverse %{ $Catalog->ItemList( Class => 'ITSM::ConfigItem::DeploymentState', Valid => 1 ) || {} };
    my %Incident = reverse %{ $Catalog->ItemList( Class => 'ITSM::Core::IncidentState', Valid => 1 ) || {} };
    return { Success => 0, Error => 'Control class, Production deployment state and Operational incident state are required.' }
        if !$Classes{Control} || !$Deploy{Production} || !$Incident{Operational};
    my $Definition = $CI->DefinitionGet( ClassID => $Classes{Control} ) || {};
    for my $Field ( 'ZRM-ControlObjective', $TargetField ) {
        return { Success => 0, Error => "Control definition is missing $Field." }
            if !exists $Definition->{DynamicFieldRef}->{$Field};
    }
    my @ExistingIDs = $CI->ConfigItemSearch(
        Result => 'ARRAY', Classes => ['Control'], UserID => $Param{UserID},
        'DynamicField_ZRM-ControlObjective' => { Equals => $ID },
    );
    my %Existing;
    for my $ControlID (@ExistingIDs) {
        my $Control = $CI->ConfigItemGet( ConfigItemID => $ControlID, DynamicFields => 1 );
        return { Success => 0, Error => "Cannot read existing Control $ControlID." }
            if ref $Control ne 'HASH' || !%{$Control};
        my $TargetID = $Control->{"DynamicField_$TargetField"};
        $TargetID = $TargetID->[0] if ref $TargetID eq 'ARRAY' && @{$TargetID} == 1;
        next if !defined $TargetID || ref $TargetID || !$TargetID;
        return { Success => 0, Error => "Multiple Controls already reference target $TargetID." }
            if $Existing{$TargetID};
        $Existing{$TargetID} = $ControlID;
    }
    my ( $Created, $Reused ) = ( 0, 0 );
    for my $TargetID ( sort { $a <=> $b } keys %Targets ) {
        if ( $Existing{$TargetID} ) { $Reused++; next; }
        my $Target = $Targets{$TargetID};
        my $ControlID = $CI->ConfigItemAdd(
            ClassID => $Classes{Control}, DeplStateID => $Deploy{Production}, InciStateID => $Incident{Operational},
            Name => ( $Objective->{Name} || 'ControlObjective' ) . ' - ' . ( $Target->{Name} || $TargetID ),
            UserID => $Param{UserID},
            'DynamicField_ZRM-ControlObjective' => $ID,
            "DynamicField_$TargetField" => $TargetID,
        );
        return { Success => 0, Created => $Created, Error => "Could not create Control for target $TargetID; retry will reuse completed targets." }
            if !$ControlID;
        $Created++;
    }
    return { Success => 1, Status => 'RECONCILED', Created => $Created, Reused => $Reused, Targets => scalar keys %Targets };
}

1;
