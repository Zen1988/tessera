# --
# Kernel/System/GenericAgent/ZRMPolicyEvaluator.pm
# --

package Kernel::System::GenericAgent::ZRMPolicyEvaluator;

use strict;
use warnings;
use Kernel::System::TESSERA::ScriptBlocks qw(ObjectSource);

use Digest::SHA qw(sha256_hex);
use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::System::GovernanceObject',
    'Kernel::System::TESSERA::PolicyEngine',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketID = $Param{TicketID};
    my $UserID   = $Param{UserID} || 1;
    return 1 if !$TicketID;

    my %Ticket = $Kernel::OM->Get('Kernel::System::Ticket')->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
        Silent        => 1,
    );
    return 1 if !IsHashRefWithData( \%Ticket );

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @ControlObjectiveIDs = $GovernanceObjectObject->GovernanceObjectSearch(
        Result     => 'ARRAY',
        Classes    => ['ControlObjective'],
        Limit      => 10000,
        SortBy     => 'Name',
        OrderBy    => 'Up',
        Permission => 'ro',
        UserID     => $UserID,
    );

    my $PolicyEngine = $Kernel::OM->Get('Kernel::System::TESSERA::PolicyEngine');
    my @Results;

    CONTROL:
    for my $ControlObjectiveID (@ControlObjectiveIDs) {
        my $Control = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $ControlObjectiveID,
            DynamicFields      => 1,
            Silent             => 1,
        );
        next CONTROL if !IsHashRefWithData($Control);

        my ($Filter, $Policy);
        my $Valid = eval {
            $Filter = ObjectSource(Object => $Control, Field => 'PolicyFilter');
            $Policy = ObjectSource(Object => $Control, Field => 'PolicyEvaluation');
            1;
        };
        if (!$Valid) {
            push @Results, {Control => $Control, Status => 'UNKNOWN', Stage => 'Applicability',
                Result => {Status => 'UNKNOWN', Error => 'Invalid ordered script blocks.'}};
            next CONTROL;
        }
        next CONTROL if !defined $Filter || $Filter eq '';
        next CONTROL if !defined $Policy || $Policy eq '';

        # Collection filters belong to target discovery, not ticket applicability.
        if ( $Filter =~ m{^\s*(?:VERSION|SEARCH|RETURN)\s*:}m ) {
            my $Parsed = $PolicyEngine->ScriptParse( Source => $Filter );
            next CONTROL if $Parsed->{Success}
                && ref $Parsed->{Script}->{RETURN} eq 'HASH'
                && ( $Parsed->{Script}->{RETURN}->{AS} || '' ) =~ m{\ACollection<};
        }

        my %Context = (
            TICKET           => \%Ticket,
            CONTROLOBJECTIVE => $Control,
        );
        my $FilterResult = $PolicyEngine->Evaluate(
            Source  => $Filter,
            Label   => 'ZRM-PolicyFilter',
            Context => \%Context,
        );

        next CONTROL if $FilterResult->{Status} eq 'NOT_SATISFIED';

        if ( $FilterResult->{Status} eq 'UNKNOWN' ) {
            push @Results, {
                Control => $Control,
                Status  => 'UNKNOWN',
                Stage   => 'Applicability',
                Result  => $FilterResult,
            };
            next CONTROL;
        }

        my $PolicyResult = $PolicyEngine->Evaluate(
            Source  => $Policy,
            Label   => 'ZRM-PolicyEvaluation',
            Context => \%Context,
        );
        push @Results, {
            Control => $Control,
            Status  => $PolicyResult->{Status},
            Stage   => 'Evaluation',
            Result  => $PolicyResult,
        };
    }

    return 1 if !@Results;

    my $Body = _ArticleBody(
        Ticket  => \%Ticket,
        Results => \@Results,
    );
    my $Digest = substr( sha256_hex($Body), 0, 16 );
    my $HistoryComment = "TESSERA Control Objective evaluation $Digest";

    return 1 if _HistoryCommentExists(
        TicketID => $TicketID,
        UserID   => $UserID,
        Comment  => $HistoryComment,
    );

    ZTSMArticleCreate(
        Ticket               => \%Ticket,
        UserID               => $UserID,
        Subject              => 'DO-NOT-REPLY: Control Objective policy evaluation.',
        Body                 => $Body,
        HistoryComment       => $HistoryComment,
        IsVisibleForCustomer => 0,
    );

    return 1;
}

sub _HistoryCommentExists {
    my (%Param) = @_;

    my @History = $Kernel::OM->Get('Kernel::System::Ticket')->HistoryGet(
        TicketID => $Param{TicketID},
        UserID   => $Param{UserID},
    );
    for my $Entry (@History) {
        next if ref $Entry ne 'HASH';
        return 1 if ( $Entry->{HistoryComment} || '' ) eq $Param{Comment};
    }
    return;
}

sub _ArticleBody {
    my (%Param) = @_;

    my @Body = (
        '** Note: This is a system-generated policy evaluation record.',
        '',
        'Ticket: ' . ( $Param{Ticket}->{TicketNumber} || $Param{Ticket}->{TicketID} || '' ),
        '',
    );

    for my $Entry ( @{ $Param{Results} } ) {
        my $Control = $Entry->{Control};
        push @Body,
            'Control Objective: ' . ( $Control->{Name} || '' ),
            'Control Class: ' . ( $Control->{Class} || '' ),
            'Evaluation Stage: ' . $Entry->{Stage},
            'Result: ' . $Entry->{Status};
        push @Body, 'Reason: ' . $Entry->{Result}->{Reason} if $Entry->{Result}->{Reason};
        push @Body, 'Trace:';
        push @Body, map { '- ' . $_ } @{ $Entry->{Result}->{Trace} || [] };
        push @Body, '';
    }

    push @Body, 'UNKNOWN is fail-closed and does not establish control satisfaction.';
    return join "\n", @Body;
}

sub _Scalar {
    my ($Value) = @_;
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    return if ref $Value;
    return $Value;
}

1;
