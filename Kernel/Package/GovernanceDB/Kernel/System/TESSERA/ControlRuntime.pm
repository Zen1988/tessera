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
            my $Source = _Scalar( $Objective->{'DynamicField_ZRM-PolicyEvaluation'} ) || '';
            my $Parsed = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine')->ProgramParse( Source => $Source );
            my $ServiceID = _Scalar( $Objective->{'DynamicField_ZRM-Service'} );
            push @Results, !$Parsed->{Success}
                ? { ConfigItemID => $ConfigItemID, Status => 'UNKNOWN', Reason => $Parsed->{Error} }
                : !$ServiceID
                    ? { ConfigItemID => $ConfigItemID, Status => 'UNKNOWN', Reason => 'ControlObjective ZRM-Service is missing.' }
                    : $Self->_ManualRequestSubmit(
                        ConfigItemID => $ConfigItemID,
                        ObjectiveID  => $ObjectiveID,
                        ServiceID    => $ServiceID,
                        Program      => $Parsed->{Program},
                        UserID       => $UserID,
                    );
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
    return { Success => 1, Status => $Result->{Result}, ConfigItemID => $ControlIDs[0] };
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
    return { ConfigItemID => $Param{ConfigItemID}, Status => $ControlResult };
}

sub _ManualRequestSubmit {
    my ( $Self, %Param ) = @_;

    my $Program = $Param{Program};
    return { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN', Reason => 'NEW @TICKET is required.' }
        if !$Program->{TicketRequested};
    return { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN', Reason => 'SUBMIT is required.' }
        if !$Program->{SubmitRequested};

    my %Assignment = ( %{ $Program->{Assignments} || {} }, %{ $Program->{Ticket} || {} } );
    my %AllowedNative = map { $_ => 1 } qw(Title Queue QueueID Lock Priority PriorityID State StateID
        CustomerUser CustomerID Owner OwnerID Responsible ResponsibleID Type TypeID SLA SLAID);
    my %Create = (
        TN        => undef,
        ServiceID => $Param{ServiceID},
        UserID    => $Param{UserID},
    );
    for my $Field ( keys %Assignment ) {
        $Create{$Field} = $Assignment{$Field} if $AllowedNative{$Field};
    }
    for my $Required (qw(Title)) {
        return { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN', Reason => "NEW \@TICKET assignment '$Required' is required." }
            if !defined $Create{$Required} || $Create{$Required} eq '';
    }

    my $TicketID = $Kernel::OM->Get('Kernel::System::Ticket')->TicketCreate(%Create);
    return { ConfigItemID => $Param{ConfigItemID}, Status => 'UNKNOWN', Reason => 'Service Request submission failed.' }
        if !$TicketID;

    for my $Field ( keys %Assignment ) {
        next if $AllowedNative{$Field};
        my $Set = $Self->_TicketFieldSet(
            TicketID => $TicketID, FieldName => $Field, Value => $Assignment{$Field}, UserID => $Param{UserID},
        );
        return { ConfigItemID => $Param{ConfigItemID}, TicketID => $TicketID, Status => 'UNKNOWN', Reason => "Ticket field '$Field' could not be assigned." }
            if !$Set;
    }
    if ( @{ $Program->{Attestation} || [] } ) {
        my $Set = $Self->_TicketFieldSet(
            TicketID => $TicketID, FieldName => 'Attestation', Value => $Program->{Attestation}, UserID => $Param{UserID},
        );
        return { ConfigItemID => $Param{ConfigItemID}, TicketID => $TicketID, Status => 'UNKNOWN', Reason => 'Attestation rows could not be assigned.' }
            if !$Set;
    }

    my $Now = $Kernel::OM->Create('Kernel::System::DateTime')->ToString();
    my $RunRecorded = $Self->_ConfigItemFieldSet(
        ConfigItemID => $Param{ConfigItemID}, FieldName => 'ZRM-LastRun', Value => $Now, UserID => $Param{UserID},
    );
    return { ConfigItemID => $Param{ConfigItemID}, TicketID => $TicketID, Status => 'UNKNOWN', Reason => 'Ticket submitted but ZRM-LastRun could not be recorded.' }
        if !$RunRecorded;

    return {
        ConfigItemID => $Param{ConfigItemID}, ObjectiveID => $Param{ObjectiveID},
        TicketID => $TicketID, ServiceID => $Param{ServiceID}, Status => 'SUBMITTED',
    };
}

sub _TicketFieldSet {
    my ( $Self, %Param ) = @_;
    my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Param{FieldName} );
    return if !$Field || ( $Field->{ObjectType} || '' ) ne 'Ticket';
    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $Field, ObjectID => $Param{TicketID}, Value => $Param{Value}, UserID => $Param{UserID},
    );
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

sub _Epoch {
    my ($Value) = @_;
    return if !defined $Value || $Value eq '';
    return 0 + $Value if $Value =~ m{\A\d+\z};
    return if $Value !~ m{\A(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})\z};
    require Time::Local;
    return eval { Time::Local::timegm( $6, $5, $4, $3, $2 - 1, $1 ) };
}

1;
