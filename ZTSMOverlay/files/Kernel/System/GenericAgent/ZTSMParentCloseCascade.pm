# --
# Kernel/System/GenericAgent/ZTSMParentCloseCascade.pm
# --

package Kernel::System::GenericAgent::ZTSMParentCloseCascade;

use strict;
use warnings;

use Kernel::System::ProcessManagement::TransitionAction::ZTSMArticleHelper qw(ZTSMArticleCreate);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless $Self, $Type;

    $Self->{Debug} = $Param{Debug} || 0;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketID = $Param{TicketID};
    my $UserID   = $Param{UserID} || 1;

    if ( !$TicketID ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'No TicketID passed to ZTSMParentCloseCascade!',
        );
        return 0;
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %ParentTicket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
        Silent        => 1,
    );

    return 1 if !IsHashRefWithData( \%ParentTicket );
    return 1 if ( $ParentTicket{StateType} || '' ) ne 'closed';

    # Child execution tickets carry ZTicket-Parent. Only the governance root cascades.
    return 1 if _NormalizeValue( $ParentTicket{'DynamicField_ZTicket-Parent'} );

    return 1 if !$Self->_RequestTypeCanBeParent(
        Type => $ParentTicket{Type},
        New  => $Param{New} || {},
    );

    my @ChildTicketIDs = $TicketObject->TicketSearch(
        Result => 'ARRAY',
        'DynamicField_ZTicket-Parent' => {
            Equals => $ParentTicket{TicketID},
        },
        UserID => 1,
    );

    return 1 if !@ChildTicketIDs;

    my $CascadeState = $Param{New}->{CascadeState} || 'closed cascading';
    my $ParentLabel  = $ParentTicket{TicketNumber} || $ParentTicket{TicketID};

    CHILD:
    for my $ChildTicketID (@ChildTicketIDs) {
        next CHILD if !$ChildTicketID;
        next CHILD if $ChildTicketID == $ParentTicket{TicketID};

        my %ChildTicket = $TicketObject->TicketGet(
            TicketID      => $ChildTicketID,
            DynamicFields => 1,
            UserID        => 1,
            Silent        => 1,
        );

        next CHILD if !IsHashRefWithData( \%ChildTicket );
        next CHILD if ( $ChildTicket{StateType} || '' ) eq 'closed';

        my $Success = $TicketObject->TicketStateSet(
            TicketID           => $ChildTicketID,
            State              => $CascadeState,
            SendNoNotification => $Param{New}->{SendNoNotification} ? 1 : 0,
            UserID             => 1,
        );

        next CHILD if !$Success;

        next CHILD if defined $Param{New}->{CreateArticle} && !$Param{New}->{CreateArticle};

        ZTSMArticleCreate(
            TicketID             => $ChildTicketID,
            Subject              => $Param{New}->{ArticleSubject} || 'Closed Cascading',
            Body                 => $Param{New}->{ArticleBody}
                || "Parent ticket $ParentLabel was closed. This child execution ticket was closed cascading.",
            HistoryComment       => 'ZTSM: Closed cascading from parent ticket closure',
            IsVisibleForCustomer => 1,
            UserID               => 1,
        );
    }

    return 1;
}

sub _RequestTypeCanBeParent {
    my ( $Self, %Param ) = @_;

    my $Type = $Param{Type} || '';
    return if !$Type;

    my %ItemListParam = (
        Class => 'ZTSM::RequestType',
        Valid => 1,
    );

    my $New = $Param{New} || {};
    if ( $New->{ParentPreferenceKey} ) {
        $ItemListParam{Preferences} = {
            $New->{ParentPreferenceKey} => $New->{ParentPreferenceValue} || 1,
        };
    }

    my $RequestType = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(%ItemListParam);
    return if !IsHashRefWithData($RequestType);

    my %AllowedName = map { $_ => 1 } values %{$RequestType};

    return $AllowedName{$Type};
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _NormalizeValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return _NormalizeValue( $Value->{Content} );
    }

    return $Value;
}

1;
