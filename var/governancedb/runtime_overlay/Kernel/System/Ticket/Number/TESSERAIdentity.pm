# --
# TESSERA ticket identity number generator.
# --

package Kernel::System::Ticket::Number::TESSERAIdentity;

use strict;
use warnings;

use parent qw(Kernel::System::Ticket::NumberBase);

use Digest::MD5 qw(md5_hex);
use Time::HiRes();

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Ticket',
    'Kernel::System::Type',
);

sub IsDateBased {
    return 0;
}

sub TicketNumberBuild {
    my ( $Self, $Offset, %Param ) = @_;

    $Offset ||= 0;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Config       = $ConfigObject->Get('Ticket::NumberGenerator::TESSERAIdentity') || {};

    my $SystemIdentity = $Self->_SystemIdentityGet($Config);
    my $TypeCode       = $Self->_TypeCodeGet( Config => $Config, %Param );
    my $Year           = $Self->_CurrentYearGet();
    my $ParentTicketNumber = $Self->_ParentTicketNumberGet(%Param);

    if (
        $ParentTicketNumber
        && $Self->_TicketNumberLooksLikeTESSERA(
            TicketNumber => $ParentTicketNumber,
            Config       => $Config,
        )
        )
    {
        my $ChildPadding = $Self->_PositiveIntegerGet(
            Value   => $Config->{ChildSequencePadding},
            Default => 3,
        );
        my $ScopePrefix = $Self->_ChildCounterScopePrefixGet(
            ParentTicketNumber => $ParentTicketNumber,
            TypeCode           => $TypeCode,
        );
        my $Counter = $Self->_ScopedTicketNumberCounterAdd(
            Offset      => 1 + $Offset,
            Year        => $Year,
            ScopePrefix => $ScopePrefix,
        );

        return if !$Counter;

        $Counter = sprintf "%0*u", $ChildPadding, $Counter;

        return join '-', $ParentTicketNumber, $TypeCode, $Counter;
    }

    my $Padding        = $Self->_PositiveIntegerGet(
        Value   => $Config->{SequencePadding},
        Default => 7,
    );

    my $Counter = $Self->_ScopedTicketNumberCounterAdd(
        Offset        => 1 + $Offset,
        SystemIdentity => $SystemIdentity,
        TypeCode      => $TypeCode,
        Year          => $Year,
        Scope         => $Config->{SequenceScope} || 'SystemYear',
        ResetPolicy   => $Config->{ResetPolicy} || 'Yearly',
    );

    return if !$Counter;

    $Counter = sprintf "%0*u", $Padding, $Counter;

    return join '-', $SystemIdentity, $TypeCode, $Year . $Counter;
}

sub GetTNByString {
    my ( $Self, $String ) = @_;

    return if !$String;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $Config       = $ConfigObject->Get('Ticket::NumberGenerator::TESSERAIdentity') || {};

    my $SystemIdentity = $Self->_SystemIdentityGet($Config);
    my $TypeCodeLength = $Self->_PositiveIntegerGet(
        Value   => $Config->{TypeCodeLength},
        Default => 2,
    );
    my $Padding = $Self->_PositiveIntegerGet(
        Value   => $Config->{SequencePadding},
        Default => 7,
    );
    my $ChildPadding = $Self->_PositiveIntegerGet(
        Value   => $Config->{ChildSequencePadding},
        Default => 3,
    );

    my $TicketHook        = $ConfigObject->Get('Ticket::Hook');
    my $TicketHookDivider = $ConfigObject->Get('Ticket::HookDivider');

    my $RootPattern  = qr{\Q$SystemIdentity\E-[A-Z0-9]{$TypeCodeLength}-\d{4}\d{$Padding,40}}xms;
    my $ChildPattern = qr{$RootPattern-[A-Z0-9]{$TypeCodeLength}-\d{$ChildPadding,40}}xms;

    if ( $String =~ /\Q$TicketHook$TicketHookDivider\E($ChildPattern)/i ) {
        return $1;
    }

    if ( $String =~ /\Q$TicketHook\E:\s{0,2}($ChildPattern)/i ) {
        return $1;
    }

    if ( $String =~ /\b($ChildPattern)\b/i ) {
        return $1;
    }

    if ( $String =~ /\Q$TicketHook$TicketHookDivider\E($RootPattern)/i ) {
        return $1;
    }

    if ( $String =~ /\Q$TicketHook\E:\s{0,2}($RootPattern)/i ) {
        return $1;
    }

    if ( $String =~ /\b($RootPattern)\b/i ) {
        return $1;
    }

    return;
}

sub ChildTicketNumberCounterCleanup {
    my ( $Self, %Param ) = @_;

    my $ParentTicketNumber = $Param{ParentTicketNumber} || '';
    return 1 if !$ParentTicketNumber;

    my $ParentPrefix = $Self->_ChildCounterParentPrefixGet(
        ParentTicketNumber => $ParentTicketNumber,
    );
    return 1 if !$ParentPrefix;

    my $LikePrefix = $ParentPrefix . '%';

    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL  => 'DELETE FROM ticket_number_counter WHERE counter_uid LIKE ?',
        Bind => [ \$LikePrefix ],
    );
}

sub _SystemIdentityGet {
    my ( $Self, $Config ) = @_;

    my $SystemIdentity = $Config->{SystemIdentity}
        || $Kernel::OM->Get('Kernel::Config')->Get('SystemID')
        || 'SYS';

    $SystemIdentity = uc $SystemIdentity;
    $SystemIdentity =~ s{[^A-Z0-9]}{}xmsg;

    return $SystemIdentity || 'SYS';
}

sub _TypeCodeGet {
    my ( $Self, %Param ) = @_;

    my $Config = $Param{Config} || {};
    my $Type   = $Param{Type}   || '';

    if ( !$Type && $Param{TypeID} ) {
        $Type = $Kernel::OM->Get('Kernel::System::Type')->TypeLookup(
            TypeID => $Param{TypeID},
        ) || '';
    }

    my $TypeCodes = $Config->{TypeCodes} || {};
    my $Code      = $TypeCodes->{$Type};

    if ( !$Code && $Type ) {
        my $NormalizedType = $Type;
        $NormalizedType =~ s{[^A-Za-z0-9]}{}xmsg;

        TYPECODE:
        for my $ConfiguredType ( sort keys %{$TypeCodes} ) {
            my $NormalizedConfiguredType = $ConfiguredType;
            $NormalizedConfiguredType =~ s{[^A-Za-z0-9]}{}xmsg;

            next TYPECODE if lc $NormalizedConfiguredType ne lc $NormalizedType;

            $Code = $TypeCodes->{$ConfiguredType};
            last TYPECODE;
        }
    }

    my $Length = $Self->_PositiveIntegerGet(
        Value   => $Config->{TypeCodeLength},
        Default => 2,
    );

    if ( !$Code ) {
        $Code = $Type || 'Ticket';
        $Code =~ s{[^A-Za-z0-9]}{}xmsg;
        $Code = substr $Code, 0, $Length;
    }

    $Code = uc $Code;
    $Code =~ s{[^A-Z0-9]}{}xmsg;
    $Code = substr $Code, 0, $Length;
    $Code = sprintf "%-*s", $Length, $Code;
    $Code =~ tr/ /X/;

    return $Code;
}

sub _ParentTicketNumberGet {
    my ( $Self, %Param ) = @_;

    return $Param{ParentTicketNumber} if $Param{ParentTicketNumber};

    return if !$Param{ParentTicketID};

    my %ParentTicket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $Param{ParentTicketID},
        DynamicFields => 0,
        UserID        => $Param{UserID} || 1,
        Silent        => 1,
    );

    return $ParentTicket{TicketNumber};
}

sub _TicketNumberLooksLikeTESSERA {
    my ( $Self, %Param ) = @_;

    my $TicketNumber = $Param{TicketNumber} || '';
    return if !$TicketNumber;

    my $Config         = $Param{Config} || {};
    my $SystemIdentity = $Self->_SystemIdentityGet($Config);
    my $TypeCodeLength = $Self->_PositiveIntegerGet(
        Value   => $Config->{TypeCodeLength},
        Default => 2,
    );
    my $Padding = $Self->_PositiveIntegerGet(
        Value   => $Config->{SequencePadding},
        Default => 7,
    );

    return $TicketNumber =~ m{\A\Q$SystemIdentity\E-[A-Z0-9]{$TypeCodeLength}-\d{4}\d{$Padding,40}\z}xms;
}

sub _ChildCounterParentPrefixGet {
    my ( $Self, %Param ) = @_;

    my $ParentTicketNumber = $Param{ParentTicketNumber} || '';
    return if !$ParentTicketNumber;

    return 'ZT' . substr( md5_hex("ChildParent:$ParentTicketNumber"), 0, 10 );
}

sub _ChildCounterScopePrefixGet {
    my ( $Self, %Param ) = @_;

    my $ParentPrefix = $Self->_ChildCounterParentPrefixGet(%Param);
    return if !$ParentPrefix;

    my $TypeCode = $Param{TypeCode} || 'XX';

    return $ParentPrefix . substr( md5_hex("ChildType:$TypeCode"), 0, 6 );
}

sub _CurrentYearGet {
    my ( $Self, %Param ) = @_;

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $DateTime       = $DateTimeObject->Get();

    return $DateTime->{Year};
}

sub _PositiveIntegerGet {
    my ( $Self, %Param ) = @_;

    return $Param{Default} if !$Param{Value};
    return $Param{Default} if $Param{Value} !~ m{\A[1-9][0-9]*\z}xms;

    return $Param{Value};
}

sub _ScopedTicketNumberCounterAdd {
    my ( $Self, %Param ) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $CurrentTime    = $DateTimeObject->ToString();

    my $ScopePrefix = $Param{ScopePrefix} || '';
    my $CounterUID;

    COUNTERUID:
    for my $Attempt ( 1 .. 5 ) {
        $CounterUID = $Self->_CounterUIDGet( ScopePrefix => $ScopePrefix );
        return if !$CounterUID;

        last COUNTERUID if $DBObject->Do(
            SQL => '
                INSERT INTO ticket_number_counter
                    (counter, counter_uid, create_time)
                VALUES
                    (0, ?, ?)',
            Bind => [ \$CounterUID, \$CurrentTime ],
        );

        $CounterUID = undef;
        Time::HiRes::sleep(0.01);
    }

    return if !$CounterUID;

    Time::HiRes::sleep(0.05);

    return if !$DBObject->Prepare(
        SQL => '
            SELECT id
            FROM ticket_number_counter
            WHERE counter_uid = ?',
        Bind  => [ \$CounterUID ],
        Limit => 1,
    );

    my $CounterID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $CounterID = $Row[0];
    }

    return if !$CounterID;

    my $YearStart = $Param{Year} . '-01-01 00:00:00';
    my $ScopeSQL  = 'AND create_time >= ?';
    my @ScopeBind = ( \$YearStart );
    my $CounterScopeSQL = '';
    my @CounterScopeBind;

    if ($ScopePrefix) {
        my $LikePrefix = $ScopePrefix . '%';
        $CounterScopeSQL = 'AND counter_uid LIKE ?';
        @CounterScopeBind = ( \$LikePrefix );
    }

    my @UnsetCounterIDs;
    return if !$DBObject->Prepare(
        SQL => "
            SELECT id
            FROM ticket_number_counter
            WHERE counter = 0
                $CounterScopeSQL
                AND id <= ?
                $ScopeSQL
            ORDER BY id ASC",
        Bind => [ @CounterScopeBind, \$CounterID, @ScopeBind ],
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @UnsetCounterIDs, $Row[0];
    }

    my $SetOffset;
    for my $UnsetCounterID (@UnsetCounterIDs) {
        my $PreviousCounter = 0;

        return if !$DBObject->Prepare(
            SQL => "
                SELECT counter
                FROM ticket_number_counter
                WHERE id < ?
                    $CounterScopeSQL
                    $ScopeSQL
                ORDER BY id DESC",
            Bind  => [ \$UnsetCounterID, @CounterScopeBind, @ScopeBind ],
            Limit => 1,
        );

        while ( my @Row = $DBObject->FetchrowArray() ) {
            $PreviousCounter = $Row[0] || 0;
        }

        my $NewCounter = $PreviousCounter + 1;
        if ( !$SetOffset ) {
            $NewCounter = $PreviousCounter + $Param{Offset};
            $SetOffset  = 1;
        }

        return if !$DBObject->Do(
            SQL => '
                UPDATE ticket_number_counter
                SET counter = ?
                WHERE id = ?
                    AND counter = 0',
            Bind => [ \$NewCounter, \$UnsetCounterID ],
        );
    }

    return if !$DBObject->Prepare(
        SQL => '
            SELECT counter
            FROM ticket_number_counter
            WHERE counter_uid = ?',
        Bind  => [ \$CounterUID ],
        Limit => 1,
    );

    my $Counter;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Counter = $Row[0];
    }

    return $Counter;
}

sub _CounterUIDGet {
    my ( $Self, %Param ) = @_;

    my $ScopePrefix = $Param{ScopePrefix} || '';
    $ScopePrefix =~ s{[^A-Za-z0-9]}{}xmsg;
    $ScopePrefix = substr $ScopePrefix, 0, 24;

    my $NodeID = $Kernel::OM->Get('Kernel::Config')->Get('NodeID') || 1;
    my ( $Seconds, $Microseconds ) = Time::HiRes::gettimeofday();
    my $ProcessID = $$;

    my $CounterUID = $ProcessID . $Seconds . $Microseconds . $NodeID;
    my $RandomLength = 32;

    if ($ScopePrefix) {
        my $SuffixLength = 32 - length $ScopePrefix;
        return if $SuffixLength < 8;

        $RandomLength = $SuffixLength;
    }

    my $Length = $RandomLength - length $CounterUID;

    if ( $Length > 0 ) {
        $CounterUID .= $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(
            Length     => $Length,
            Dictionary => [ 0 .. 9, 'a' .. 'f' ],
        );
    }

    if ($ScopePrefix) {
        my $RandomSuffix = $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(
            Length     => $RandomLength,
            Dictionary => [ 0 .. 9, 'a' .. 'f' ],
        );

        return $ScopePrefix . $RandomSuffix;
    }

    return substr $CounterUID, 0, 32;
}

1;
