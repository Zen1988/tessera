package Kernel::System::TESSERA::TicketCalendar;
use strict;
use warnings;
use Time::Local qw(timegm);

our @ObjectDependencies = ('Kernel::System::Ticket', 'Kernel::System::DateTime', 'Kernel::System::State',
    'Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck', 'Kernel::Config');

sub new { my ($Type) = @_; return bless {}, $Type; }

sub Events {
    my ($Self, %Param) = @_;
    die "Calendar requires an agent user.\n" if !$Param{UserID};
    my ($From, $Until) = map { _DayEpoch($_) } @Param{qw(Start End)};
    die "Calendar range must be 1–62 days.\n" if !$From || !$Until || $Until <= $From || $Until - $From > 62 * 86400;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Base = (Result => 'ARRAY', UserID => $Param{UserID}, Permission => 'ro',
        ArchiveFlags => ['y', 'n'], Limit => 20001);
    my $FromDate = _Date($From - 86400);
    my $UntilDate = _Date($Until + 86400);
    my @Searches = (
        { Types => ['Change', 'Change::Major'],
          'DynamicField_ZTicket-ScheduleStart' => { SmallerThan => $UntilDate },
          'DynamicField_ZTicket-ScheduleFinish' => { GreaterThan => $FromDate } },
        { Types => ['Incident', 'Incident::Major', 'ServiceRequest'], TicketCreateTimeNewerDate => $FromDate,
          TicketCreateTimeOlderDate => $UntilDate },
        { Types => ['Incident', 'Incident::Major', 'ServiceRequest'], TicketCreateTimeOlderDate => $UntilDate,
          StateType => 'Open' },
        { Types => ['Incident', 'Incident::Major', 'ServiceRequest'], TicketCreateTimeOlderDate => $UntilDate,
          TicketCloseTimeNewerDate => $FromDate },
    );
    my %IDs;
    for my $Search (@Searches) {
        my @Found = $TicketObject->TicketSearch(%Base, %{$Search});
        die "Calendar result limit reached; narrow the requested period.\n" if @Found > 20000;
        @IDs{@Found} = (1) x @Found;
    }

    return $Self->_EventsFromIDs(IDs => [keys %IDs], From => $From, Until => $Until,
        AgentUserID => $Param{UserID});
}

sub EventsForCustomer {
    my ($Self, %Param) = @_;
    die "Calendar requires a customer user.\n" if !$Param{CustomerUserID};
    die "Calendar ticket scope is required.\n" if ref $Param{TicketIDs} ne 'ARRAY';
    # The overview already owns and permission-filters this scope. IPC users can
    # legitimately have more than 20,000 tickets; do not turn that into an error.
    my ($From, $Until) = map { _DayEpoch($_) } @Param{qw(Start End)};
    die "Calendar range must be 1–62 days.\n" if !$From || !$Until || $Until <= $From || $Until - $From > 62 * 86400;
    return $Self->_EventsFromIDs(IDs => $Param{TicketIDs}, From => $From,
        Until => $Until, CustomerUserID => $Param{CustomerUserID});
}

sub _EventsFromIDs {
    my ($Self, %Param) = @_;
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my ($From, $Until) = @Param{qw(From Until)};
    my @Events;
    my %Seen;
    my %MasterCache;
    my $CategoryConfig = $Param{CustomerUserID}
        ? $Kernel::OM->Get('Kernel::Config')->Get('Ticket::Frontend::CustomerTicketCategories') : {};
    $CategoryConfig = {} if ref $CategoryConfig ne 'HASH';
    for my $ID (sort { $a <=> $b } @{$Param{IDs}}) {
        next if !$ID || $Seen{$ID}++;
        if ($Param{CustomerUserID}) {
            next if !$TicketObject->TicketCustomerPermission(Type => 'ro', TicketID => $ID,
                UserID => $Param{CustomerUserID})
                && !$Kernel::OM->Get('Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck')->Run(
                    TicketID => $ID, CustomerUserID => $Param{CustomerUserID}, Type => 'ro');
        }
        else {
            next if !$TicketObject->TicketPermission(Type => 'ro', TicketID => $ID,
                UserID => $Param{AgentUserID}, LogNo => 1);
        }
        my %Ticket = $TicketObject->TicketGet(TicketID => $ID, DynamicFields => 1,
            UserID => $Param{CustomerUserID} ? 1 : $Param{AgentUserID});
        next if !%Ticket;
        my $Type = $Ticket{Type} || '';
        next if $Type !~ /\A(?:Change(?:::Major)?|Incident(?:::Major)?|ServiceRequest)\z/;
        my ($Start, $End);
        if ($Type =~ /\AChange/) {
            $Start = _Moment($Ticket{'DynamicField_ZTicket-ScheduleStart'});
            $End = _Moment($Ticket{'DynamicField_ZTicket-ScheduleFinish'});
        }
        elsif ($Type =~ /\AIncident/) {
            # Native TicketCreate writes create_time for every creation path.
            $Start = _Moment($Ticket{Created});
            $End = _Moment($Ticket{'DynamicField_ZTicket-ActualFinish'});
            $End //= $Self->_ClosedAt(TicketObject => $TicketObject, TicketID => $ID,
                UserID => $Param{CustomerUserID} ? 1 : $Param{AgentUserID}) if ($Ticket{StateType} || '') eq 'closed';
            $End //= time() if ($Ticket{StateType} || '') ne 'closed';
        }
        else {
            $Start = _Moment($Ticket{'DynamicField_ZTicket-ActualStart'})
                // _Moment($Ticket{Created});
            $End = _Moment($Ticket{'DynamicField_ZTicket-ActualFinish'});
            $End //= $Self->_ClosedAt(TicketObject => $TicketObject, TicketID => $ID,
                UserID => $Param{CustomerUserID} ? 1 : $Param{AgentUserID}) if ($Ticket{StateType} || '') eq 'closed';
            $End //= time() if ($Ticket{StateType} || '') ne 'closed';
        }
        next if !defined $Start || !defined $End || $End <= $Start;
        next if $Start >= $Until || $End <= $From;
        my $Event = {
            id => $ID, title => ($Ticket{TicketNumber} || $ID) . ' > ' . ($Ticket{Title} || ''),
            start => $Start * 1000, end => $End * 1000,
            url => ($Param{CustomerUserID} ? 'customer.pl?Action=CustomerTicketZoom' : 'index.pl?Action=AgentTicketZoom')
                . ';TicketID=' . $ID,
            className => 'TESSERA-' . ($Type =~ /\AChange/ ? 'Change'
                : $Type =~ /\AIncident/ ? 'Incident' : 'ServiceRequest'),
        };
        if ($Param{CustomerUserID}) {
            my @Categories;
            for my $Name (qw(Priority Type Queue Service State Owner)) {
                my $Conf = $CategoryConfig->{$Name};
                next if ref $Conf ne 'HASH' || !$Ticket{$Name};
                my $Selection = ref $Conf->{ColorSelection} eq 'HASH' ? $Conf->{ColorSelection} : {};
                my $Color = $Selection->{$Ticket{$Name}} // $Conf->{ColorDefault};
                $Color = '' if !defined $Color || $Color !~ /\A#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?\z/;
                push @Categories, { name => $Name, text => $Conf->{Text} // $Ticket{$Name},
                    prefix => $Conf->{Prefix} // '', translate => $Conf->{Translate} ? 1 : 0,
                    color => $Color, order => $Conf->{Order} || 0 };
            }
            $Event->{categories} = [sort { $a->{order} <=> $b->{order} } @Categories];
        }
        my $MasterID = $Ticket{'DynamicField_ZTicket-Parent'};
        $MasterID = $MasterID->[0] if ref $MasterID eq 'ARRAY' && @{$MasterID} == 1;
        if (!ref $MasterID && defined $MasterID && $MasterID =~ /\A[1-9]\d*\z/ && $MasterID != $ID) {
            if (!exists $MasterCache{$MasterID}) {
                my $Number = $TicketObject->TicketNumberLookup(TicketID => $MasterID);
                my $Master;
                if ($Number) {
                    $Master = { id => 0 + $MasterID, number => $Number };
                    my $CanRead = $Param{CustomerUserID}
                        ? $TicketObject->TicketCustomerPermission(Type => 'ro', TicketID => $MasterID,
                            UserID => $Param{CustomerUserID})
                            || $Kernel::OM->Get('Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck')->Run(
                                TicketID => $MasterID, CustomerUserID => $Param{CustomerUserID}, Type => 'ro')
                        : $TicketObject->TicketPermission(Type => 'ro', TicketID => $MasterID,
                            UserID => $Param{AgentUserID}, LogNo => 1);
                    if ($CanRead) {
                        my %MasterTicket = $TicketObject->TicketGet(TicketID => $MasterID,
                            UserID => $Param{CustomerUserID} ? 1 : $Param{AgentUserID});
                        if (%MasterTicket) {
                            $Master->{title} = $MasterTicket{Title} || '';
                            $Master->{url} = ($Param{CustomerUserID}
                                ? 'customer.pl?Action=CustomerTicketZoom'
                                : 'index.pl?Action=AgentTicketZoom') . ';TicketID=' . $MasterID;
                        }
                    }
                }
                $MasterCache{$MasterID} = $Master;
            }
            $Event->{master} = $MasterCache{$MasterID} if $MasterCache{$MasterID};
        }
        push @Events, $Event;
    }
    return \@Events;
}

sub _ClosedAt {
    my ($Self, %Param) = @_;
    my @History = $Param{TicketObject}->HistoryGet(
        TicketID => $Param{TicketID}, UserID => $Param{UserID});
    for my $Entry (reverse @History) {
        next if !$Entry->{StateID};
        my %State = $Kernel::OM->Get('Kernel::System::State')->StateGet(ID => $Entry->{StateID});
        return _Moment($Entry->{CreateTime}) if ($State{TypeName} || '') eq 'closed';
    }
    return;
}

sub _DayEpoch {
    my ($Value) = @_;
    return if !defined $Value || $Value !~ /\A(\d{4})-(\d\d)-(\d\d)\z/;
    my ($Y, $M, $D) = ($1, $2, $3);
    return eval { timegm(0, 0, 0, $D, $M - 1, $Y) };
}

sub _Date {
    my ($Epoch) = @_;
    my $Date = $Kernel::OM->Create('Kernel::System::DateTime', ObjectParams => { Epoch => $Epoch });
    return $Date->ToString();
}

sub _Moment {
    my ($Value) = @_;
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    return if ref $Value || !$Value || $Value !~ /\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\z/;
    my $Date = $Kernel::OM->Create('Kernel::System::DateTime', ObjectParams => { String => $Value });
    return $Date->ToEpoch();
}

1;
