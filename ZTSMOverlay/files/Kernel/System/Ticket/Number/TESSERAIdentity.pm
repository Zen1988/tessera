# --
# TESSERA ticket identity number generator.
# --

package Kernel::System::Ticket::Number::TESSERAIdentity;

use strict;
use warnings;

use parent qw(Kernel::System::Ticket::NumberBase);

use Time::HiRes();

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Main',
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

    my $TicketHook        = $ConfigObject->Get('Ticket::Hook');
    my $TicketHookDivider = $ConfigObject->Get('Ticket::HookDivider');

    my $Pattern = qr{\Q$SystemIdentity\E-[A-Z0-9]{$TypeCodeLength}-\d{4}\d{$Padding,40}}xms;

    if ( $String =~ /\Q$TicketHook$TicketHookDivider\E($Pattern)/i ) {
        return $1;
    }

    if ( $String =~ /\Q$TicketHook\E:\s{0,2}($Pattern)/i ) {
        return $1;
    }

    if ( $String =~ /\b($Pattern)\b/i ) {
        return $1;
    }

    return;
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

    my $CounterUID = $Self->_CounterUIDGet();
    return if !$CounterUID;

    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $CurrentTime    = $DateTimeObject->ToString();

    return if !$DBObject->Do(
        SQL => '
            INSERT INTO ticket_number_counter
                (counter, counter_uid, create_time)
            VALUES
                (0, ?, ?)',
        Bind => [ \$CounterUID, \$CurrentTime ],
    );

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

    my @UnsetCounterIDs;
    return if !$DBObject->Prepare(
        SQL => "
            SELECT id
            FROM ticket_number_counter
            WHERE counter = 0
                AND id <= ?
                $ScopeSQL
            ORDER BY id ASC",
        Bind => [ \$CounterID, @ScopeBind ],
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
                    $ScopeSQL
                ORDER BY id DESC",
            Bind  => [ \$UnsetCounterID, @ScopeBind ],
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

    my $NodeID = $Kernel::OM->Get('Kernel::Config')->Get('NodeID') || 1;
    my ( $Seconds, $Microseconds ) = Time::HiRes::gettimeofday();
    my $ProcessID = $$;

    my $CounterUID = $ProcessID . $Seconds . $Microseconds . $NodeID;
    my $Length     = 32 - length $CounterUID;

    if ( $Length > 0 ) {
        $CounterUID .= $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(
            Length     => $Length,
            Dictionary => [ 0 .. 9, 'a' .. 'f' ],
        );
    }

    return substr $CounterUID, 0, 32;
}

1;
