# --
# Kernel/System/GenericAgent/ZTSMPurpleBookReader.pm
# --

package Kernel::System::GenericAgent::ZTSMPurpleBookReader;

use strict;
use warnings;

use Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector ();

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Log',
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

    _Log(
        Priority => 'error',
        Message  => 'ZTSMPurpleBookReader: enter TicketID='
            . ( $TicketID || '' )
            . " UserID=$UserID",
    );

    if ( !$TicketID ) {
        _Log(
            Priority => 'error',
            Message  => 'ZTSMPurpleBookReader: skip missing TicketID',
        );
        return 1;
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 1,
        UserID        => $UserID,
        Silent        => 1,
    );

    if ( !%Ticket ) {
        _Log(
            Priority => 'error',
            Message  => "ZTSMPurpleBookReader: skip ticket not found TicketID=$TicketID",
        );
        return 1;
    }

    if ( ( $Ticket{StateType} || '' ) ne 'closed' ) {
        _Log(
            Priority => 'error',
            Message  => "ZTSMPurpleBookReader: skip ticket not closed TicketID=$TicketID State="
                . ( $Ticket{State} || '' )
                . ' StateType='
                . ( $Ticket{StateType} || '' ),
        );
        return 1;
    }

    if ( !$Self->_PurpleBookChildTicket(\%Ticket) ) {
        _Log(
            Priority => 'error',
            Message  => "ZTSMPurpleBookReader: skip not PurpleBook follow-up child TicketID=$TicketID",
        );
        return 1;
    }

    my $ChapterDirector = Kernel::System::ProcessManagement::TransitionAction::ZTSMChapterDirector->new();
    my $Result = $ChapterDirector->Run(
        Ticket => \%Ticket,
        UserID => $UserID,
    );

    _Log(
        Priority => 'error',
        Message  =>
              'ZTSMPurpleBookReader: delegated closed PurpleBook child to ChapterDirector '
            . "TicketID=$TicketID "
            . 'ParentTicketID='
            . ( _NormalizeValue( $Ticket{'DynamicField_ZTicket-Parent'} ) || '' )
            . ' BlueBook='
            . ( _NormalizeValue( $Ticket{'DynamicField_ZTicket-BlueBook'} ) || '' )
            . ' BlueLevel='
            . ( _NormalizeValue( $Ticket{'DynamicField_ZTicket-BlueLevel'} ) || '' )
            . ' Result='
            . ( $Result ? 1 : 0 ),
    );

    return 1;
}

sub _PurpleBookChildTicket {
    my ( $Self, $Ticket ) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';

    my $ParentTicketID = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    my $BlueBookID     = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueBook'} );
    my $BlueLevel      = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-BlueLevel'} );
    my $Chapter        = _NormalizeValue( $Ticket->{'DynamicField_ZTicket-Chapter'} );

    if ( !$ParentTicketID || !$BlueBookID || !defined $BlueLevel || $BlueLevel eq '' || !$Chapter ) {
        _Log(
            Priority => 'error',
            Message  => 'ZTSMPurpleBookReader: missing required child fields TicketID='
                . ( $Ticket->{TicketID} || '' )
                . ' ParentTicketID='
                . ( $ParentTicketID || '' )
                . ' BlueBook='
                . ( $BlueBookID || '' )
                . ' BlueLevel='
                . ( defined $BlueLevel ? $BlueLevel : '' )
                . ' Chapter='
                . ( $Chapter || '' ),
        );
        return;
    }

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %ParentTicket = $TicketObject->TicketGet(
        TicketID      => $ParentTicketID,
        DynamicFields => 1,
        UserID        => 1,
        Silent        => 1,
    );

    if ( !%ParentTicket ) {
        _Log(
            Priority => 'error',
            Message  => 'ZTSMPurpleBookReader: parent ticket not found TicketID='
                . ( $Ticket->{TicketID} || '' )
                . " ParentTicketID=$ParentTicketID",
        );
        return;
    }

    my $ParentState = lc( $ParentTicket{State} || '' );
    if ( $ParentState eq 'follow-up' ) {
        _Log(
            Priority => 'error',
            Message  => 'ZTSMPurpleBookReader: decision parent-follow-up TicketID='
                . ( $Ticket->{TicketID} || '' )
                . " ParentTicketID=$ParentTicketID ParentState="
                . ( $ParentTicket{State} || '' ),
        );
        return 1;
    }

    if ( !$Self->_RequestTypeTicket( \%ParentTicket ) ) {
        _Log(
            Priority => 'error',
            Message  => 'ZTSMPurpleBookReader: decision parent-not-request-type TicketID='
                . ( $Ticket->{TicketID} || '' )
                . " ParentTicketID=$ParentTicketID ParentType="
                . ( $ParentTicket{Type} || '' ),
        );
        return 1;
    }

    if ( $Self->_ProcessContextEmpty($Ticket) ) {
        _Log(
            Priority => 'error',
            Message  => 'ZTSMPurpleBookReader: decision child-process-context-empty TicketID='
                . ( $Ticket->{TicketID} || '' )
                . " ParentTicketID=$ParentTicketID",
        );
        return 1;
    }

    _Log(
        Priority => 'error',
        Message  => 'ZTSMPurpleBookReader: skip parent request type with process context TicketID='
            . ( $Ticket->{TicketID} || '' )
            . " ParentTicketID=$ParentTicketID ParentType="
            . ( $ParentTicket{Type} || '' ),
    );

    return;
}

sub _RequestTypeTicket {
    my ( $Self, $Ticket ) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';

    my $Type = $Ticket->{Type} || '';
    return if !$Type;

    my $RequestTypes = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ZTSM::RequestType',
        Valid => 1,
    );

    return if ref $RequestTypes ne 'HASH';

    my %RequestTypeName = map { $_ => 1 } values %{$RequestTypes};
    return $RequestTypeName{$Type};
}

sub _ProcessContextEmpty {
    my ( $Self, $Ticket ) = @_;

    return if !$Ticket || ref $Ticket ne 'HASH';

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ProcessField = $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID');
    my $ActivityField = $ConfigObject->Get('Process::DynamicFieldProcessManagementActivityID');

    my $ProcessID = $ProcessField ? _NormalizeValue( $Ticket->{ 'DynamicField_' . $ProcessField } ) : undef;
    my $ActivityID = $ActivityField ? _NormalizeValue( $Ticket->{ 'DynamicField_' . $ActivityField } ) : undef;

    return 1 if !$ProcessID && !$ActivityID;
    return;
}

sub _Log {
    my (%Param) = @_;

    eval {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => $Param{Priority} || 'error',
            Message  => $Param{Message}  || '',
        );
    };

    return 1;
}

sub _NormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;
    return _NormalizeValue( $Value->[0] ) if ref $Value eq 'ARRAY';

    if ( ref $Value eq 'HASH' ) {
        for my $Key (qw(Key Value Content GovernanceObjectID ObjectID ID ItemID SelectedID SelectedValue)) {
            return _NormalizeValue( $Value->{$Key} ) if defined $Value->{$Key} && $Value->{$Key} ne '';
        }
        return;
    }

    return $Value;
}

1;
