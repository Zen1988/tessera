package Kernel::System::TESSERA::ExternalChange;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::JSON',
    'Kernel::System::Main',
    'Kernel::System::Ticket',
    'Kernel::System::Ticket::Article::Backend::Internal',
);

my %AllowedTransition = (
    Received        => { Invalid => 1, DuplicateReview => 1, ReadyForReview => 1 },
    DuplicateReview => { Invalid => 1, ReadyForReview => 1 },
    ReadyForReview  => { Approved => 1, Rejected => 1, Invalid => 1 },
    Approved        => { Revalidating => 1, Rejected => 1 },
    Revalidating    => { Released => 1, ReleaseFailed => 1, Conflict => 1 },
    Released        => { RevertRequested => 1 },
    RevertRequested => { Reverted => 1, RevertFailed => 1 },
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub StageAdd {
    my ( $Self, %Param ) = @_;
    for my $Needed (qw(Source IdempotencyKey ObjectType ObjectClass Operation Payload CustomerUserID UserID)) {
        return { Success => 0, Error => "Missing $Needed" }
            if !defined $Param{$Needed} || $Param{$Needed} eq '';
    }
    return { Success => 0, Error => 'Payload must be an object.' } if ref $Param{Payload} ne 'HASH';

    my $ObjectType = uc $Param{ObjectType};
    my $Operation  = ucfirst lc $Param{Operation};
    return { Success => 0, Error => 'ObjectType must be CMDB or MELT.' }
        if $ObjectType ne 'CMDB' && $ObjectType ne 'MELT';
    return { Success => 0, Error => 'Only Create and Update are supported.' }
        if $Operation ne 'Create' && $Operation ne 'Update';
    return { Success => 0, Error => 'Update requires TargetID and ExpectedVersionID.' }
        if $Operation eq 'Update' && ( !$Param{TargetID} || !$Param{ExpectedVersionID} );

    my $Existing = $Self->StageGetByIdempotency(
        Source         => $Param{Source},
        IdempotencyKey => $Param{IdempotencyKey},
    );
    return { Success => 1, Duplicate => 1, Change => $Existing } if $Existing;

    my $RequestUID = $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString( Length => 48 );
    my $PayloadJSON = $Self->_Encode( $Param{Payload} );
    my $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO ztsm_external_change '
            . '(request_uid, idempotency_key, source_name, customer_user_id, object_type, object_class, operation, target_id, '
            . 'expected_version_id, ticket_id, status, schema_hash, payload, create_time, create_by, change_time, change_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$RequestUID, \$Param{IdempotencyKey}, \$Param{Source}, \$Param{CustomerUserID}, \$ObjectType, \$Param{ObjectClass},
            \$Operation, \$Param{TargetID}, \$Param{ExpectedVersionID}, \$Param{TicketID}, \'Received',
            \$Param{SchemaHash}, \$PayloadJSON, \$Param{UserID}, \$Param{UserID},
        ],
    );
    return { Success => 0, Error => 'Could not create staging record.' } if !$Success;

    my $Change = $Self->StageGetByIdempotency(
        Source         => $Param{Source},
        IdempotencyKey => $Param{IdempotencyKey},
    );
    return { Success => 0, Error => 'Could not read staging record.' } if !$Change;
    $Self->_HistoryAdd(
        ChangeID => $Change->{ChangeID}, NewStatus => 'Received', EventType => 'ExternalRequestReceived',
        Detail => { CustomerUserID => $Param{CustomerUserID}, RequestUID => $RequestUID }, UserID => $Param{UserID},
    );
    $Self->_TicketArticleAdd(
        TicketID => $Param{TicketID}, UserID => $Param{UserID},
        Subject  => "External $ObjectType $Operation request received",
        Body     => "An external change request was staged for review.\n\nRequest: $RequestUID\nSource: $Param{Source}\nObject: $ObjectType/$Param{ObjectClass}\nOperation: $Operation\nNo production object has been changed.",
    ) if $Param{TicketID};
    return { Success => 1, Change => $Change };
}

sub StageTransition {
    my ( $Self, %Param ) = @_;
    return { Success => 0, Error => 'Missing ChangeID, Status, or UserID.' }
        if !$Param{ChangeID} || !$Param{Status} || !$Param{UserID};
    my $Current = $Self->StageGet( ChangeID => $Param{ChangeID} );
    return { Success => 0, Error => 'Staging record not found.' } if !$Current;
    return { Success => 0, Error => "Transition $Current->{Status} -> $Param{Status} is not allowed." }
        if !$AllowedTransition{ $Current->{Status} } || !$AllowedTransition{ $Current->{Status} }->{ $Param{Status} };

    my $DetailJSON = $Self->_Encode( $Param{Detail} || {} );
    my $Success = $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'UPDATE ztsm_external_change SET status = ?, validation_result = ?, change_time = current_timestamp, change_by = ? WHERE id = ? AND status = ?',
        Bind => [ \$Param{Status}, \$DetailJSON, \$Param{UserID}, \$Param{ChangeID}, \$Current->{Status} ],
    );
    return { Success => 0, Error => 'Concurrent staging update detected.' } if !$Success;
    $Self->_HistoryAdd(
        ChangeID => $Param{ChangeID}, OldStatus => $Current->{Status}, NewStatus => $Param{Status},
        EventType => $Param{EventType} || 'ExternalRequestStatusChanged', Detail => $Param{Detail}, UserID => $Param{UserID},
    );
    $Self->_TicketArticleAdd(
        TicketID => $Current->{TicketID}, UserID => $Param{UserID},
        Subject => "External request status: $Param{Status}",
        Body => "External request $Current->{RequestUID} changed from $Current->{Status} to $Param{Status}.\n\nEvery production release or revert requires a separate approved ticket action.",
    ) if $Current->{TicketID};
    return { Success => 1, Change => $Self->StageGet( ChangeID => $Param{ChangeID} ) };
}

sub StageGetByIdempotency {
    my ( $Self, %Param ) = @_;
    return if !defined $Param{Source} || !defined $Param{IdempotencyKey};
    return $Self->_StageSelect(
        Where => 'source_name = ? AND idempotency_key = ?',
        Bind  => [ \$Param{Source}, \$Param{IdempotencyKey} ],
    );
}

sub StageGet {
    my ( $Self, %Param ) = @_;
    return if !$Param{ChangeID};
    return $Self->_StageSelect( Where => 'id = ?', Bind => [ \$Param{ChangeID} ] );
}

sub _StageSelect {
    my ( $Self, %Param ) = @_;
    my $DB = $Kernel::OM->Get('Kernel::System::DB');
    return if !$DB->Prepare(
        SQL => 'SELECT id, request_uid, idempotency_key, source_name, customer_user_id, object_type, object_class, operation, target_id, '
            . 'expected_version_id, ticket_id, status, schema_hash, payload, normalized_payload, validation_result, '
            . 'before_snapshot, after_snapshot, released_object_id, released_version_id, entitlement_snapshot, parent_change_id, '
            . 'create_time, create_by, change_time, change_by FROM ztsm_external_change WHERE ' . $Param{Where},
        Bind => $Param{Bind}, Limit => 1,
    );
    my @R = $DB->FetchrowArray();
    return if !@R;
    my @Keys = qw(ChangeID RequestUID IdempotencyKey Source CustomerUserID ObjectType ObjectClass Operation TargetID ExpectedVersionID TicketID Status SchemaHash Payload NormalizedPayload ValidationResult BeforeSnapshot AfterSnapshot ReleasedObjectID ReleasedVersionID EntitlementSnapshot ParentChangeID CreateTime CreateBy ChangeTime ChangeBy);
    my %Data; @Data{@Keys} = @R;
    for my $Key (qw(Payload NormalizedPayload ValidationResult BeforeSnapshot AfterSnapshot EntitlementSnapshot)) {
        $Data{$Key} = $Self->_Decode( $Data{$Key} ) if defined $Data{$Key} && $Data{$Key} ne '';
    }
    return \%Data;
}

sub _HistoryAdd {
    my ( $Self, %Param ) = @_;
    my $Detail = $Self->_Encode( $Param{Detail} || {} );
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO ztsm_external_change_history (change_id, old_status, new_status, event_type, detail, create_time, create_by) VALUES (?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [ \$Param{ChangeID}, \$Param{OldStatus}, \$Param{NewStatus}, \$Param{EventType}, \$Detail, \$Param{UserID} ],
    );
}

sub _TicketArticleAdd {
    my ( $Self, %Param ) = @_;
    return if !$Param{TicketID};
    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet( TicketID => $Param{TicketID}, UserID => $Param{UserID} );
    return if !$Ticket{TicketID};
    return $Kernel::OM->Get('Kernel::System::Ticket::Article::Backend::Internal')->ArticleCreate(
        TicketID => $Param{TicketID}, SenderType => 'system', IsVisibleForCustomer => 0,
        Subject => $Param{Subject}, Body => $Param{Body}, ContentType => 'text/plain; charset=utf-8',
        HistoryType => 'AddNote', HistoryComment => $Param{Subject}, UserID => $Param{UserID},
    );
}

sub _Encode {
    my ( $Self, $Data ) = @_;
    return $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => $Data, SortKeys => 1 );
}

sub _Decode {
    my ( $Self, $Data ) = @_;
    return $Kernel::OM->Get('Kernel::System::JSON')->Decode( Data => $Data );
}

1;
