# --
# Kernel/System/TESSERA/ControlRuntime.pm
# --

package Kernel::System::TESSERA::ControlRuntime;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::DateTime',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::System::TESSERA::PolicyEngine',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub DispatchDueControls {
    my ( $Self, %Param ) = @_;

    my $UserID = $Param{UserID} || 1;
    my $Now    = defined $Param{Now} ? $Param{Now} : time;
    my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my @IDs = $ConfigItemObject->ConfigItemSearch(
        Result  => 'ARRAY',
        Classes => ['Control'],
        UserID  => $UserID,
    );

    my @Results;
    CONTROL:
    for my $ConfigItemID (@IDs) {
        my $Control = $ConfigItemObject->ConfigItemGet(
            ConfigItemID  => $ConfigItemID,
            DynamicFields => 1,
        );
        next CONTROL if ref $Control ne 'HASH' || !%{$Control};

        my $ObjectiveID = _Scalar( $Control->{'DynamicField_ZRM-ControlObjective'} );
        if (!$ObjectiveID) {
            push @Results, { ConfigItemID => $ConfigItemID, Status => 'UNKNOWN', Reason => 'ControlObjective is missing.' };
            next CONTROL;
        }
        my $Objective = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ObjectiveID,
            DynamicFields      => 1,
            Silent             => 1,
        );
        if ( ref $Objective ne 'HASH' || !%{$Objective} ) {
            push @Results, { ConfigItemID => $ConfigItemID, Status => 'UNKNOWN', Reason => 'ControlObjective cannot be resolved.' };
            next CONTROL;
        }

        my $Cycle = _Scalar( $Objective->{'DynamicField_ZRM-ControlCycle'} );
        my $LastRun = _Scalar( $Control->{'DynamicField_ZRM-LastRun'} );
        my $Due = $Self->ControlDue( Cycle => $Cycle, LastRun => $LastRun, Now => $Now );
        if ( !$Due->{Due} ) {
            push @Results, { ConfigItemID => $ConfigItemID, Status => $Due->{Status}, Reason => $Due->{Reason} };
            next CONTROL;
        }

        my $ControlType = _Scalar( $Objective->{'DynamicField_ZRM-ControlType'} ) || '';
        if ( lc($ControlType) eq 'manual' ) {
            push @Results, {
                ConfigItemID => $ConfigItemID,
                Status       => 'AWAITING_EVIDENCE',
                Reason       => 'Manual control is due; no service or workflow ticket is created automatically.',
            };
            next CONTROL;
        }

        push @Results, $Self->_AutomaticEvaluate(
            Control      => $Control,
            Objective    => $Objective,
            ConfigItemID => $ConfigItemID,
            Now          => $Now,
            UserID       => $UserID,
        );
    }

    return \@Results;
}

sub ControlDue {
    my ( $Self, %Param ) = @_;

    my $Cycle = defined $Param{Cycle} ? $Param{Cycle} : '';
    $Cycle =~ s{\A\s+|\s+\z}{}g;
    return { Due => 0, Status => 'UNKNOWN', Reason => 'Control cycle is empty.' } if $Cycle eq '';

    my ( $Amount, $Unit, $Times );
    if ( $Cycle =~ m{\A(\d+)\s*(DAY|WEEK|MONTH|YEAR)S?(?:\s+(\d+)\s+TIMES?)?\z}i ) {
        ( $Amount, $Unit, $Times ) = ( $1, uc($2), $3 || 1 );
    }
    elsif ( $Cycle =~ m{\A(DAILY|WEEKLY|MONTHLY|QUARTERLY|ANNUALLY|YEARLY)\z}i ) {
        my %Named = (
            DAILY => [ 1, 'DAY' ], WEEKLY => [ 1, 'WEEK' ], MONTHLY => [ 1, 'MONTH' ],
            QUARTERLY => [ 3, 'MONTH' ], ANNUALLY => [ 1, 'YEAR' ], YEARLY => [ 1, 'YEAR' ],
        );
        ( $Amount, $Unit, $Times ) = ( @{ $Named{ uc $Cycle } }, 1 );
    }
    else {
        return { Due => 0, Status => 'UNKNOWN', Reason => "Unsupported control cycle '$Cycle'." };
    }
    return { Due => 0, Status => 'UNKNOWN', Reason => 'Control cycle frequency must be greater than zero.' } if !$Times;

    my %Seconds = ( DAY => 86400, WEEK => 604800, MONTH => 2629746, YEAR => 31556952 );
    my $Interval = int( $Amount * $Seconds{$Unit} / $Times );
    my $LastRunEpoch = _Epoch( $Param{LastRun} );
    return { Due => 1, Status => 'DUE', Reason => 'Control has never run.' } if !defined $LastRunEpoch;

    my $Now = defined $Param{Now} ? $Param{Now} : time;
    return $Now >= $LastRunEpoch + $Interval
        ? { Due => 1, Status => 'DUE', Reason => 'Control cycle has elapsed.' }
        : { Due => 0, Status => 'NOT_DUE', Reason => 'Control instance is still within its cycle.' };
}

sub EvaluateCompletedTicket {
    my ( $Self, %Param ) = @_;
    my $TicketID = $Param{TicketID} || return { Success => 0, Status => 'UNKNOWN', Reason => 'TicketID is required.' };
    my $UserID   = $Param{UserID} || 1;
    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID => $TicketID, DynamicFields => 1, UserID => $UserID, Silent => 1,
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => 'Ticket cannot be resolved.' } if !%Ticket;
    my @ControlIDs = $Param{ConfigItemID} ? ( $Param{ConfigItemID} ) : ();
    return { Success => 0, Status => 'UNKNOWN', Reason => 'ConfigItemID for the Control instance is required.' }
        if @ControlIDs != 1;

    my $Control = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID => $ControlIDs[0], DynamicFields => 1,
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => 'Control instance cannot be resolved.' }
        if ref $Control ne 'HASH' || !%{$Control} || ( $Control->{Class} || '' ) ne 'Control';
    my $ObjectiveID = _Scalar( $Control->{'DynamicField_ZRM-ControlObjective'} );
    my $Objective = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $ObjectiveID, DynamicFields => 1, Silent => 1,
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => 'Linked ControlObjective cannot be resolved.' }
        if ref $Objective ne 'HASH' || !%{$Objective};

    my $Source = _Scalar( $Objective->{'DynamicField_ZRM-PolicyEvaluation'} ) || '';
    my $Result = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->ProgramEvaluate(
        Source => $Source, Context => { TICKET => \%Ticket, CONTROLOBJECTIVE => $Objective, CONTROL => $Control },
    );
    return { Success => 0, Status => 'UNKNOWN', Reason => $Result->{Error} } if !$Result->{Success};

    $Self->_ConfigItemFieldSet( ConfigItemID => $ControlIDs[0], FieldName => 'ZRM-Result', Value => $Result->{Result}, UserID => $UserID );
    my $Risk = $Self->ProcessFailedControl(
        Result => $Result->{Result}, Control => $Control, Objective => $Objective,
        ConfigItemID => $ControlIDs[0], Ticket => \%Ticket, UserID => $UserID,
    );
    return { Success => $Risk->{Success}, Status => $Result->{Result}, ConfigItemID => $ControlIDs[0], %{$Risk} };
}

sub ProcessFailedControl {
    my ( $Self, %Param ) = @_;

    my $UserID       = $Param{UserID} || 1;
    my $ConfigItemID = $Param{ConfigItemID};
    my $Control      = $Param{Control};
    if ( ref $Control ne 'HASH' ) {
        return { Success => 0, RiskCreated => 0, Reason => 'ConfigItemID for the Control instance is required.' }
            if !$ConfigItemID;
        $Control = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
            ConfigItemID => $ConfigItemID,
            DynamicFields => 1,
        );
    }
    return { Success => 0, RiskCreated => 0, Reason => 'Control instance cannot be resolved.' }
        if ref $Control ne 'HASH' || !%{$Control} || ( $Control->{Class} || '' ) ne 'Control';
    $ConfigItemID ||= $Control->{ConfigItemID};

    my $Result = defined $Param{Result} ? $Param{Result} : _Scalar( $Control->{'DynamicField_ZRM-Result'} );
    return { Success => 1, RiskCreated => 0 } if lc( $Result || '' ) ne 'fail';

    my $Objective = $Param{Objective};
    my $ObjectiveID = _Scalar( $Control->{'DynamicField_ZRM-ControlObjective'} );
    return { Success => 0, RiskCreated => 0, Reason => 'A Control must reference its ControlObjective.' }
        if !$ObjectiveID;
    if ( ref $Objective ne 'HASH' || !$Objective->{GovernanceObjectID} || "$Objective->{GovernanceObjectID}" ne "$ObjectiveID" ) {
        $Objective = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
            GovernanceObjectID => $ObjectiveID,
            DynamicFields      => 1,
            Silent             => 1,
        );
    }
    return { Success => 0, RiskCreated => 0, Reason => 'The parent ControlObjective cannot be resolved.' }
        if ref $Objective ne 'HASH' || !%{$Objective} || ( $Objective->{Class} || '' ) ne 'ControlObjective';

    return $Self->_RiskCreateOnFailure(
        Result       => $Result,
        Control      => $Control,
        Objective    => $Objective,
        ConfigItemID => $ConfigItemID,
        Ticket       => $Param{Ticket},
        UserID       => $UserID,
    );
}

sub _AutomaticEvaluate {
    my ( $Self, %Param ) = @_;
    my $Source = _Scalar( $Param{Objective}->{'DynamicField_ZRM-PolicyEvaluation'} ) || '';
    my $Result = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->Evaluate(
        Source => $Source, Label => 'ZRM-PolicyEvaluation',
        Context => { CONTROL => $Param{Control}, CONTROLOBJECTIVE => $Param{Objective} },
    );
    return { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN', Reason => $Result->{Reason} }
        if $Result->{Status} eq 'UNKNOWN';
    my $ControlResult = $Result->{Status} eq 'SATISFIED' ? 'Pass' : 'Fail';
    $Self->_ConfigItemFieldSet( ConfigItemID => $Param{ConfigItemID}, FieldName => 'ZRM-Result', Value => $ControlResult, UserID => $Param{UserID} );
    my $Now = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => { Epoch => $Param{Now} },
    )->ToString();
    $Self->_ConfigItemFieldSet( ConfigItemID => $Param{ConfigItemID}, FieldName => 'ZRM-LastRun', Value => $Now, UserID => $Param{UserID} );
    my $Risk = $Self->ProcessFailedControl(
        Result => $ControlResult, Control => $Param{Control}, Objective => $Param{Objective},
        ConfigItemID => $Param{ConfigItemID}, UserID => $Param{UserID},
    );
    return { ConfigItemID => $Param{ConfigItemID}, Status => $ControlResult, %{$Risk} };
}

sub _RiskCreateOnFailure {
    my ( $Self, %Param ) = @_;
    return { Success => 1, RiskCreated => 0 } if lc( $Param{Result} || '' ) ne 'fail';
    return { Success => 1, RiskCreated => 0 } if !_Truthy( _Scalar( $Param{Objective}{'DynamicField_ZRM-CreateRisk'} ) );

    my $Target = _Scalar( $Param{Objective}{'DynamicField_ZRM-RiskClass'} ) || '';
    $Target =~ s{\A\s*\@?}{};
    $Target =~ s{\s+\z}{};
    return { Success => 0, RiskCreated => 0, RiskError => 'ZRM-RiskClass is required when ZRM-CreateRisk is selected.' }
        if $Target !~ m{\A(MELTObject|GovernanceObject)\.([A-Za-z][A-Za-z0-9_-]*)\z};
    my ( $ObjectType, $Class ) = ( $1, $2 );
    my $Source = _Scalar( $Param{Objective}{'DynamicField_ZRM-FieldAssignment'} ) || '';
    my $Assignments = $Self->_RiskAssignmentsParse(
        Source => $Source, ObjectType => $ObjectType, Class => $Class,
        Context => { CONTROL => $Param{Control}, CONTROLOBJECTIVE => $Param{Objective}, TICKET => $Param{Ticket} || {} },
        ConfigItemID => $Param{ConfigItemID},
    );
    return { Success => 0, RiskCreated => 0, RiskError => $Assignments->{Error} } if !$Assignments->{Success};

    my $CatalogClass = $ObjectType eq 'MELTObject' ? 'ZTSM::MELT::Class' : 'ZTSM::GovernanceObject::Class';
    my $StatusClass  = $ObjectType eq 'MELTObject' ? 'ZTSM::MELT::Status' : 'ZTSM::GovernanceObject::Status';
    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %ClassID = reverse %{ $Catalog->ItemList( Class => $CatalogClass, Valid => 1 ) || {} };
    my %StatusID = reverse %{ $Catalog->ItemList( Class => $StatusClass, Valid => 1 ) || {} };
    return { Success => 0, RiskCreated => 0, RiskError => "Risk class '$Target' is unavailable or inactive." } if !$ClassID{$Class};
    my $ActiveID = $StatusID{Active} || $StatusID{Production} || ( sort { $a <=> $b } values %StatusID )[0];
    return { Success => 0, RiskCreated => 0, RiskError => "No active status is available for '$ObjectType'." } if !$ActiveID;

    my $Object = eval { $Kernel::OM->Get("Kernel::System::$ObjectType") };
    return { Success => 0, RiskCreated => 0, RiskError => "$ObjectType is not installed." } if !$Object;
    my ($IdentityField) = grep {
        defined $Assignments->{Values}{$_} && "$Assignments->{Values}{$_}" eq "$Param{ConfigItemID}"
    } keys %{ $Assignments->{Values} };
    if ($IdentityField) {
        my $SearchMethod = $ObjectType . 'Search';
        my @Existing = $Object->$SearchMethod(
            Result => 'ARRAY', Limit => 1, Classes => [$Class],
            "DynamicField_$IdentityField" => { Equals => $Param{ConfigItemID} },
        );
        return {
            Success => 1, RiskCreated => 0, RiskObjectType => $ObjectType,
            RiskObjectID => $Existing[0], RiskClass => $Class,
        } if @Existing;
    }
    my $Name = 'Control failure: ' . ( $Param{Control}{Name} || $Param{Control}{Number} || $Param{ConfigItemID} );
    my %Create = ( ClassID => $ClassID{$Class}, ZTSMStatusID => $ActiveID, Name => $Name, UserID => $Param{UserID} );
    $Create{"DynamicField_$_"} = $Assignments->{Values}{$_} for keys %{ $Assignments->{Values} };
    my $Method = $ObjectType . 'Add';
    my $RiskID = $Object->$Method(%Create);
    return { Success => 0, RiskCreated => 0, RiskError => "Failed to create '$Target'." } if !$RiskID;
    return { Success => 1, RiskCreated => 1, RiskObjectType => $ObjectType, RiskObjectID => $RiskID, RiskClass => $Class };
}

sub _RiskAssignmentsParse {
    my ( $Self, %Param ) = @_;
    my $Evaluated = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->FieldAssignmentsEvaluate(
        Source     => $Param{Source},
        ObjectType => $Param{ObjectType},
        Class      => $Param{Class},
        Context    => $Param{Context},
        ThisValue  => $Param{ConfigItemID},
    );
    return { Success => 0, Error => $Evaluated->{Error} } if !$Evaluated->{Success};

    for my $FieldName ( keys %{ $Evaluated->{Value} } ) {
        my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $FieldName );
        return { Success => 0, Error => "Dynamic Field '$FieldName' does not belong to $Param{ObjectType}." }
            if !$Field || ( $Field->{ObjectType} || '' ) ne $Param{ObjectType};
    }
    return { Success => 1, Values => $Evaluated->{Value} };
}

sub _ConfigItemFieldSet {
    my ( $Self, %Param ) = @_;
    my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Param{FieldName} );
    return if !$Field || ( $Field->{ObjectType} || '' ) ne 'ITSMConfigItem';
    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $Field, ObjectID => $Param{ConfigItemID}, Value => $Param{Value}, UserID => $Param{UserID},
    );
}

sub _Scalar {
    my ($Value) = @_;
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    return if ref $Value;
    return $Value;
}

sub _Truthy {
    my ($Value) = @_;
    return 0 if !defined $Value || $Value eq '' || $Value =~ m{\A(?:0|no|false|off)\z}i;
    return 1;
}

sub _Epoch {
    my ($Value) = @_;
    return if !defined $Value || $Value eq '';
    return 0 + $Value if $Value =~ m{\A\d+\z};
    return if $Value !~ m{\A(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})\z};
    require Time::Local;
    return eval { Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 ) };
}

1;
