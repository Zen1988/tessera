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
use Kernel::System::ZTSMBlueBookRuntime ();

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::GovernanceObject',
    'Kernel::System::Ticket',
    'Kernel::System::Type',
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

sub _TicketOnHold {
    my ($Ticket) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';
    return 1 if _NormalizeValue( $Ticket->{'DynamicField_ZTicket-HoldState'} );
    return 1 if lc( $Ticket->{State} || '' ) eq 'onhold';

    return;
}

sub _TicketSummary {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};

    if ( !$Ticket && $Param{TicketID} ) {
        my %TicketData = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
            TicketID => $Param{TicketID},
            UserID   => 1,
            Silent   => 1,
        );
        $Ticket = \%TicketData if %TicketData;
    }

    return 'N/A' if !$Ticket || ref $Ticket ne 'HASH';

    my $TicketNumber = $Ticket->{TicketNumber} || '';
    my $TicketID     = $Ticket->{TicketID}     || $Param{TicketID} || '';
    my $Type         = $Ticket->{Type}         || 'Ticket';
    my $Title        = $Ticket->{Title}        || '';

    my $Label = $TicketNumber ? "Ticket#$TicketNumber" : "TicketID#$TicketID";
    $Label .= " (ID $TicketID)" if $TicketNumber && $TicketID;
    $Label .= " - $Type" if $Type;
    $Label .= ": $Title" if $Title;

    return $Label;
}

sub _RecordValueGet {
    my (%Param) = @_;

    my $Record = $Param{Record};

    return if !$Record || ref $Record ne 'HASH';

    FIELD:
    for my $Field ( @{ $Param{Fields} || [] } ) {
        my $StructuredValue = _RecordStructuredFieldValue(
            Record => $Record,
            Field  => $Field,
        );
        return $StructuredValue if defined $StructuredValue && $StructuredValue ne '';

        next FIELD if !exists $Record->{$Field};

        my $Value = $Record->{$Field};

        $Value = _NormalizeValue($Value);

        return $Value if defined $Value && $Value ne '';
    }

    return;
}

sub _RecordStructuredFieldValue {
    my (%Param) = @_;

    my $Record = $Param{Record};
    my $Field  = $Param{Field};
    return if !$Record || ref $Record ne 'HASH';
    return if !$Field;

    if ( ( $Record->{DF} || '' ) eq $Field ) {
        my $Value = exists $Record->{Value} ? $Record->{Value} : $Record->{Content};
        $Value = _NormalizeValue($Value);
        return $Value if defined $Value && $Value ne '';
    }

    for my $ContainerKey (qw(Fields Items Values Content Value)) {
        my $Container = $Record->{$ContainerKey};
        next if ref $Container ne 'ARRAY';

        ITEM:
        for my $Item ( @{$Container} ) {
            next ITEM if ref $Item ne 'HASH';

            my $Value = _RecordStructuredFieldValue(
                Record => $Item,
                Field  => $Field,
            );
            return $Value if defined $Value && $Value ne '';
        }
    }

    return;
}

sub _TicketTypeResolve {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $TypeObject = $Kernel::OM->Get('Kernel::System::Type');

    if ( $Value !~ m{\A\d+\z} ) {
        my $TypeID = $TypeObject->TypeLookup(
            Type => $Value,
        );

        return $Value if $TypeID;
    }

    FIELDNAME:
    for my $FieldName (qw(ZBlue-Type ZBlue-TicketType)) {
        my $DynamicFieldConfig = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
            Name => $FieldName,
        );

        next FIELDNAME if !$DynamicFieldConfig;

        my $DisplayValue;

        my $GeneralCatalogClass = $DynamicFieldConfig->{Config}->{Class}
            || ( $FieldName eq 'ZBlue-TicketType' ? 'ZTSM::Type' : undef );

        if (
            ( $DynamicFieldConfig->{FieldType} || '' ) eq 'GeneralCatalog'
            && $GeneralCatalogClass
            )
        {
            my $PossibleValues = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
                Class => $GeneralCatalogClass,
            );

            $DisplayValue = $PossibleValues->{$Value}
                if $PossibleValues;
        }

        if ( !$DisplayValue && $DynamicFieldConfig->{ID} ) {
            $DisplayValue = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueLookup(
                DynamicFieldConfig => $DynamicFieldConfig,
                Key                => $Value,
            );
        }

        next FIELDNAME if !$DisplayValue;
        next FIELDNAME if $DisplayValue eq $Value;

        my $TypeID = $TypeObject->TypeLookup(
            Type => $DisplayValue,
        );

        return $DisplayValue if $TypeID;
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
    return if !$DynamicFieldConfig->{ID};
    return if $DynamicFieldConfig->{ObjectType} && $DynamicFieldConfig->{ObjectType} ne 'Ticket';

    return $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueSet(
        DynamicFieldConfig => $DynamicFieldConfig,
        ObjectID           => $Param{TicketID},
        Value              => $Param{Value},
        UserID             => $Param{UserID} || 1,
    );
}

sub _SupportProfileResolve {
    my (%Param) = @_;

    my $Value = _NormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    my %Search = (
        Result  => 'ARRAY',
        Classes => ['SupportProfile'],
        Limit   => 1,
        UserID  => $Param{UserID} || 1,
    );

    if ( $Value =~ m{\A\d+\z} ) {
        $Search{GovernanceObjectID} = [$Value];
    }
    else {
        $Search{Name} = $Value;
    }

    my @SupportProfileIDs = $GovernanceObjectObject->GovernanceObjectSearch(%Search);

    return if !@SupportProfileIDs;

    return $SupportProfileIDs[0];
}

sub _ExistingChapterPlayCount {
    my (%Param) = @_;

    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result => 'ARRAY',
        'DynamicField_ZTicket-Parent' => {
            Equals => $Param{ParentTicketID},
        },
        'DynamicField_ZTicket-BlueBook' => {
            Equals => $Param{BlueBookID},
        },
        'DynamicField_ZTicket-BlueLevel' => {
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

    if ( !$Param{Ticket} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'ZTSMBlueBookReader: Stop, missing Ticket param',
        );
        return;
    }

    my $Ticket = $Param{Ticket};

    my $TicketID = $Ticket->{TicketID};
    my $UserID   = $Param{UserID} || 1;

    if ( !$TicketID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => 'ZTSMBlueBookReader: Stop, missing TicketID',
        );
        return;
    }

    if ( _TicketOnHold($Ticket) ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMBlueBookReader: Ticket is onhold, skip BlueBook orchestration TicketID=$TicketID",
        );
        return 1;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "ZTSMBlueBookReader: Enter Run TicketID=$TicketID",
    );

    my $BlueBookID = _NormalizeValue(
        $Ticket->{'DynamicField_ZTicket-BlueBook'}
    );

    if ( !$BlueBookID ) {
        my %FreshTicket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => $UserID,
            Silent        => 1,
        );

        $BlueBookID = _NormalizeValue(
            $FreshTicket{'DynamicField_ZTicket-BlueBook'}
        );

        if ($BlueBookID) {
            $Ticket = \%FreshTicket;
            $LogObject->Log(
                Priority => 'notice',
                Message  => "ZTSMBlueBookReader: BlueBook resolved after ticket reload TicketID=$TicketID BlueBook=$BlueBookID",
            );
        }
    }

    if ( !$BlueBookID ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, missing ZTicket-BlueBook TicketID=$TicketID",
        );
        return;
    }

    my $BlueBook = $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(
        GovernanceObjectID => $BlueBookID,
        DynamicFields => 1,
    );

    if ( !$BlueBook || ref $BlueBook ne 'HASH' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Failed loading BlueBook=$BlueBookID TicketID=$TicketID",
        );

        return;
    }

    my $XMLData = ref $BlueBook->{XMLData} eq 'HASH' ? $BlueBook->{XMLData} : {};

    my $Records
        = $XMLData->{'ZBlue-Record'}
        || $BlueBook->{'DynamicField_ZBlue-Record'};

    if ( !$Records ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, missing ZBlue-Record TicketID=$TicketID BlueBook=$BlueBookID",
        );
        return;
    }

    if ( ref $Records eq 'HASH' ) {
        $Records = [$Records];
    }

    if ( ref $Records ne 'ARRAY' ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, invalid ZBlue-Record structure TicketID=$TicketID BlueBook=$BlueBookID Ref=" . ref $Records,
        );
        return;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "ZTSMBlueBookReader: Raw records TicketID=$TicketID BlueBook=$BlueBookID Count=" . scalar @{$Records},
    );

    my @ParsedRecords;

    RECORD:
    for my $Record ( @{$Records} ) {

        if ( ref $Record ne 'HASH' ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "ZTSMBlueBookReader: Skip record, invalid structure TicketID=$TicketID BlueBook=$BlueBookID Ref=" . ref $Record,
            );
            next RECORD;
        }

        my $BlueLevel = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-BlueLevel', 'ZBlue-Level', 'ZBlue-Seq' ],
        ) || 1;

        my $Chapter = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-Chapter' ],
        );

        if ( !$Chapter ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "ZTSMBlueBookReader: Skip record, missing ZBlue-Chapter TicketID=$TicketID BlueBook=$BlueBookID BlueLevel=$BlueLevel",
            );
            next RECORD;
        }

        my $RawType = _RecordValueGet(
            Record => $Record,
            Fields => [ 'ZBlue-Type', 'ZBlue-TicketType' ],
        );

        my $Type = _TicketTypeResolve(
            Value => $RawType,
        );

        push @ParsedRecords, {
            BlueLevel        => $BlueLevel,
            Chapter          => $Chapter,
            Type             => $Type,
            RawType          => $RawType,
            Activity         => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Activity'] ),
            Profile          => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Profile'] ),
            Role             => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Role'] ),
            Template         => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Template'] ),
            PurpleBook       => _RecordValueGet( Record => $Record, Fields => ['ZBlue-PurpleBook'] ),
            Mandatory        => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Mandatory'] ),
            Strict           => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Strict'] ),
            Duration         => _RecordValueGet( Record => $Record, Fields => ['ZBlue-Duration'] ),
            RequiredWeightage => _RecordValueGet(
                Record => $Record,
                Fields => [ 'ZBlue-RequiredWeightage', 'ZBlue-Weightage' ],
            ),
        };
    }

    if ( !@ParsedRecords ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "ZTSMBlueBookReader: Stop, no parsed BlueBook records TicketID=$TicketID BlueBook=$BlueBookID",
        );
        return;
    }

    @ParsedRecords = sort {
        $a->{BlueLevel} <=> $b->{BlueLevel}
            ||
        $a->{Chapter} cmp $b->{Chapter}
    } @ParsedRecords;

    my $CurrentBlueLevel = $ParsedRecords[0]->{BlueLevel};

    $LogObject->Log(
        Priority => 'notice',
        Message  => "ZTSMBlueBookReader: Parsed records TicketID=$TicketID BlueBook=$BlueBookID Count="
            . scalar @ParsedRecords
            . " FirstBlueLevel=$CurrentBlueLevel",
    );

    _TicketFieldSet(
        TicketID  => $TicketID,
        FieldName => 'ZTicket-BlueLevel',
        Value     => $CurrentBlueLevel,
        UserID    => $UserID,
    );

    my $ExistingChapterPlayCount = _ExistingChapterPlayCount(
        ParentTicketID => $TicketID,
        BlueBookID     => $BlueBookID,
        BlueLevel      => $CurrentBlueLevel,
        UserID         => $UserID,
    );

    if ($ExistingChapterPlayCount) {
        $LogObject->Log(
            Priority => 'notice',
            Message  =>
                  "ZTSMBlueBookReader: Existing ChapterPlay tickets found, skip spawn "
                . "TicketID=$TicketID "
                . "BlueBook=$BlueBookID "
                . "BlueLevel=$CurrentBlueLevel "
                . "Existing=$ExistingChapterPlayCount",
        );
        return 1;
    }

    my @CreatedTicketIDs;

    RECORD:
    for my $Record (@ParsedRecords) {

        next RECORD if $Record->{BlueLevel} ne $CurrentBlueLevel;

        my $ChildType  = $Record->{Type} || $Ticket->{Type} || '';
        my $ParentType = $Ticket->{Type} || 'ParentTicket';
        my $ParentRef  = $Ticket->{TicketNumber} || $TicketID;
        my $Activity   = $Record->{Activity} || $Ticket->{Title};
        my $ChildTitle = join ' - ', grep { defined $_ && $_ ne '' } (
            $ChildType,
            "$ParentType#$ParentRef",
            $Activity,
        );

        my $NewTicketID = $TicketObject->TicketCreate(
            TN           => undef,
            Title        => $ChildTitle,
            Queue        => $Ticket->{Queue},
            Lock         => 'unlock',
            Priority     => $Ticket->{Priority},
            State        => 'new',
            CustomerUser => $Ticket->{CustomerUserID},
            OwnerID      => 1,
            UserID       => $UserID,
            Type         => $ChildType,
            ServiceID    => $Ticket->{ServiceID},
            SLAID        => $Ticket->{SLAID},
            ResponsibleID => 1,
        );

        if ( !$NewTicketID ) {
            $LogObject->Log(
                Priority => 'error',
                Message  =>
                      "ZTSMBlueBookReader: TicketCreate failed "
                    . "ParentTicketID=$TicketID "
                    . "BlueBook=$BlueBookID "
                    . "BlueLevel=$Record->{BlueLevel} "
                    . "Chapter=$Record->{Chapter} "
                    . "Type="
                    . ( $Record->{Type} || $Ticket->{Type} || '' )
                    . " RawType="
                    . ( $Record->{RawType} || '' )
                    . " Queue="
                    . ( $Ticket->{Queue} || '' ),
            );
            next RECORD;
        }

        push @CreatedTicketIDs, $NewTicketID;

        my %ChildProcessContext = Kernel::System::ZTSMBlueBookRuntime::ChildProcessSet(
            TicketID => $NewTicketID,
            UserID   => $UserID,
        );

        my $OwnerGroup = _SupportProfileResolve(
            Value  => $Record->{Profile},
            UserID => $UserID,
        );

        $LogObject->Log(
            Priority => 'notice',
            Message  => "ZTSMBlueBookReader: Support profile owner group resolution "
                . "TicketID=$TicketID "
                . "ChildTicketID=$NewTicketID "
                . "Profile="
                . ( $Record->{Profile} || '' )
                . " OwnerGroup="
                . ( $OwnerGroup || '' ),
        );

        my %FieldMap = (
            'ZTicket-Parent'           => $TicketID,
            'ZTicket-BlueBook'         => $BlueBookID,
            'ZTicket-BlueLevel'        => $Record->{BlueLevel},
            'ZTicket-Chapter'          => $Record->{Chapter},
            'ZTicket-Application'      => $Ticket->{'DynamicField_ZTicket-Application'},
            'ZTicket-Profile'          => $Record->{Profile},
            'ZTicket-OwnerGroup'       => $OwnerGroup,
            'ZTicket-Role'             => $Record->{Role},
            'ZTicket-Mandatory'        => $Record->{Mandatory},
            'ZTicket-Strict'           => $Record->{Strict},
            'ZTicket-Duration'         => $Record->{Duration},
            'ZTicket-RequiredWeightage' => $Record->{RequiredWeightage} || 1,
        );

        FIELD:
        for my $FieldName ( sort keys %FieldMap ) {

            next FIELD if !defined $FieldMap{$FieldName};
            next FIELD if $FieldMap{$FieldName} eq '';

            my $FieldSet = _TicketFieldSet(
                TicketID  => $NewTicketID,
                FieldName => $FieldName,
                Value     => $FieldMap{$FieldName},
                UserID    => $UserID,
            );

            if ( !$FieldSet ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  =>
                          'ZTSMBlueBookReader: Child field set failed '
                        . "TicketID=$NewTicketID "
                        . "Field=$FieldName "
                        . 'Value='
                        . ( defined $FieldMap{$FieldName} ? $FieldMap{$FieldName} : '' ),
                );
            }
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
                . _TicketSummary(
                    Ticket   => $Ticket,
                    TicketID => $TicketID,
                )
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

        Kernel::System::ZTSMBlueBookRuntime::ChildTemplateApply(
            TicketID     => $NewTicketID,
            TemplateID   => $Record->{Template},
            ArticleParam => \%Param,
            UserID       => $UserID,
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
            . (
                @CreatedTicketIDs
                ? join(
                    "\n",
                    map { _TicketSummary( TicketID => $_ ) } @CreatedTicketIDs
                )
                : 'None'
            ),
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
