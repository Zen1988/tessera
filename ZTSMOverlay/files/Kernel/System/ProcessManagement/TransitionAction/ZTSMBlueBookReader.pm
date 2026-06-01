# --
# Kernel/System/ProcessManagement/TransitionAction/ZTSMBlueBookReader.pm
# --

package Kernel::System::ProcessManagement::TransitionAction::ZTSMBlueBookReader;

use strict;
use warnings;

use parent qw(
    Kernel::System::ProcessManagement::TransitionAction::Base
);

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Ticket',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;

    return bless {}, $Type;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        $Value = $Value->[0];
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Key}   if defined $Value->{Key};
        return $Value->{Value} if defined $Value->{Value};
        return $Value->{Content} if defined $Value->{Content};
        return;
    }

    return $Value;
}

sub _RecordValueGet {
    my (%Param) = @_;

    my $Record = $Param{Record};

    return if !$Record || ref $Record ne 'HASH';

    FIELD:
    for my $Field ( @{ $Param{Fields} || [] } ) {

        next FIELD if !exists $Record->{$Field};

        my $Value = ref $Record->{$Field} eq 'HASH'
            ? $Record->{$Field}->{Content}
            : $Record->{$Field};

        $Value = _NormalizeValue($Value);

        return $Value if defined $Value && $Value ne '';
    }

    return;
}

sub _TicketFieldSet {
    my (%Param) = @_;

    return if !$Param{TicketID};
    return if !$Param{FieldName};

    my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        Name => $Param{FieldName},
    );

    return if !$DynamicFieldConfig;

    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID} || 1,
    );
}

sub _ExistingChapterPlayCount {
    my (%Param) = @_;

    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result => 'ARRAY',
        DynamicField_ZTicket_Parent => {
            Equals => $Param{ParentTicketID},
        },
        DynamicField_ZTicket_BlueBook => {
            Equals => $Param{BlueBookID},
        },
        DynamicField_ZTicket_BlueLevel => {
            Equals => $Param{BlueLevel},
        },
        UserID => $Param{UserID} || 1,
    );

    return scalar @TicketIDs;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    return if !$Param{Ticket};

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};
    my $UserID   = $Param{UserID} || 1;

    return if !$TicketID;

    my $BlueBookID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueBook'}
    );

    return if !$BlueBookID;

    my $BlueBook = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID  => $BlueBookID,
        DynamicFields => 1,
    );

    if ( !$BlueBook || ref $BlueBook ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Failed loading BlueBook=$BlueBookID TicketID=$TicketID",
        );

        return;
    }

    my $Records = $BlueBook->{XMLData}->{'ZBlue-Record'};

    return if !$Records;

    if ( ref $Records eq 'HASH' ) {
        $Records = [$Records];
    }

    return if ref $Records ne 'ARRAY';

    my @ParsedRecords;

    RECORD:
    for my $Record ( @{$Records} ) {

        next RECORD if ref $Record ne 'HASH';

        my $BlueLevel = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-BlueLevel', 'ZBlue-Level', 'ZBlue-Seq' ],
        ) || 1;

        my $Chapter = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-Chapter' ],
        );

        next RECORD if !$Chapter;

        push @ParsedRecords, {
            BlueLevel        => $BlueLevel,
            Chapter          => $Chapter,
            Type             => _RecordValueGet(
                Record => $Record,
                Fields => [ 'ZBlue-Type', 'ZBlue-TicketType' ],
            ),
            Profile          => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Profile'] ),
            Role             => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Role'] ),
            Mandatory        => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Mandatory'] ),
            Strict           => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Strict'] ),
            Duration         => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Duration'] ),
            RequiredWeightage => _RecordValueGet(
                Record => $Record,
                Fields => [ 'ZBlue-RequiredWeightage', 'ZBlue-Weightage' ],
            ),
        };
    }

    return if !@ParsedRecords;

    @ParsedRecords = sort {
        $a->{BlueLevel} <=> $b->{BlueLevel}
            ||
        $a->{Chapter} cmp $b->{Chapter}
    } @ParsedRecords;

    my $CurrentBlueLevel = $ParsedRecords[0]->{BlueLevel};

    _TicketFieldSet(
        TicketID  => $TicketID,
        FieldName => 'ZTicket-BlueLevel',
        Value     => $CurrentBlueLevel,
        UserID    => $UserID,
    );

    return 1
        if _ExistingChapterPlayCount(
            ParentTicketID => $TicketID,
            BlueBookID     => $BlueBookID,
            BlueLevel      => $CurrentBlueLevel,
            UserID         => $UserID,
        );

    my @CreatedTicketIDs;

    RECORD:
    for my $Record (@ParsedRecords) {

        next RECORD if $Record->{BlueLevel} ne $CurrentBlueLevel;

        my $NewTicketID = $TicketObject->TicketCreate(
            TN           => undef,
            Title        => $Ticket->{Title},
            Queue        => $Ticket->{Queue},
            Lock         => 'unlock',
            Priority     => $Ticket->{Priority},
            State        => 'new',
            CustomerUser => $Ticket->{CustomerUserID},
            OwnerID      => 1,
            UserID       => $UserID,
            Type         => $Record->{Type} || $Ticket->{Type},
            ServiceID    => $Ticket->{ServiceID},
            SLAID        => $Ticket->{SLAID},
            ResponsibleID => 1,
        );

        next RECORD if !$NewTicketID;

        push @CreatedTicketIDs, $NewTicketID;

        my %FieldMap = (
            'ZTicket-Parent'           => $TicketID,
            'ZTicket-BlueBook'         => $BlueBookID,
            'ZTicket-BlueLevel'        => $Record->{BlueLevel},
            'ZTicket-Chapter'          => $Record->{Chapter},
            'ZTicket-Profile'          => $Record->{Profile},
            'ZTicket-Role'             => $Record->{Role},
            'ZTicket-Mandatory'        => $Record->{Mandatory},
            'ZTicket-Strict'           => $Record->{Strict},
            'ZTicket-Duration'         => $Record->{Duration},
            'ZTicket-RequiredWeightage' => $Record->{RequiredWeightage},
        );

        FIELD:
        for my $FieldName ( sort keys %FieldMap ) {

            next FIELD if !defined $FieldMap{$FieldName};
            next FIELD if $FieldMap{$FieldName} eq '';

            _TicketFieldSet(
                TicketID  => $NewTicketID,
                FieldName => $FieldName,
                Value     => $FieldMap{$FieldName},
                UserID    => $UserID,
            );
        }

        ZTSMArticleCreate(
            %Param,
            TicketID => $NewTicketID,
            Subject  => 'DO-NOT-REPLY: ChapterPlay initiated.',
            Body     =>
                  "** Note: This is a system-generated orchestration update message.\n\n"
                . "ChapterPlay:\n"
                . "Initiated\n\n"
                . "Parent Ticket:\n"
                . $TicketID
                . "\n\n"
                . "BlueBook:\n"
                . $BlueBookID
                . "\n\n"
                . "BlueLevel:\n"
                . $Record->{BlueLevel}
                . "\n\n"
                . "Chapter:\n"
                . $Record->{Chapter},
            HistoryComment => 'ZTSM: ChapterPlay initiated',
            UserID         => $UserID,
        );
    }

    ZTSMArticleCreate(
        %Param,
        TicketID => $TicketID,
        Subject  => 'DO-NOT-REPLY: BlueBook orchestration started.',
        Body     =>
              "** Note: This is a system-generated orchestration update message.\n\n"
            . "BlueBook Reader:\n"
            . "Started\n\n"
            . "BlueBook:\n"
            . $BlueBookID
            . "\n\n"
            . "BlueLevel:\n"
            . $CurrentBlueLevel
            . "\n\n"
            . "ChapterPlay Tickets Created:\n"
            . ( join( ', ', @CreatedTicketIDs ) || 'None' ),
        HistoryComment => 'ZTSM: BlueBook orchestration started',
        UserID         => $UserID,
    );

    $LogObject->Log(
        Priority => 'notice',
        Message  =>
              "ZTSMBlueBookReader: BlueBook orchestration started "
            . "TicketID=$TicketID "
            . "BlueBook=$BlueBookID "
            . "BlueLevel=$CurrentBlueLevel "
            . "Created="
            . scalar @CreatedTicketIDs,
    );

    return 1;
}

1;
