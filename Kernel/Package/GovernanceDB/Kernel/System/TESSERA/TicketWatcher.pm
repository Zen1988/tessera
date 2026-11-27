package Kernel::System::TESSERA::TicketWatcher;

use strict;
use warnings;

our @ObjectDependencies = qw(Kernel::System::CustomerUser Kernel::System::DB Kernel::System::Ticket);

sub new { return bless {}, shift }

sub Validate {
    my ( $Self, %Param ) = @_;
    my $Actor = $Param{Actor} // '';
    return if !$Actor || $Actor ne ($Param{Requester} // '');
    my @Logins = grep { length } split /[\s,]+/, ($Param{Logins} // '');
    return if @Logins > 10;
    my $Users = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my %Owner = $Users->CustomerUserDataGet( User => $Actor );
    return if ($Owner{ValidID} // 0) != 1 || !$Owner{UserCustomerID};
    my %Seen;
    my @Eligible;
    for my $Login (@Logins) {
        return if length($Login) > 200;
        my %User = $Users->CustomerUserDataGet( User => $Login );
        my $Canonical = $User{UserLogin} // '';
        return if !$Canonical || ($User{ValidID} // 0) != 1
            || ($User{UserCustomerID} // '') ne $Owner{UserCustomerID};
        next if $Canonical eq $Actor || $Seen{$Canonical}++;
        push @Eligible, $Canonical;
    }
    return { Company => $Owner{UserCustomerID}, Logins => \@Eligible };
}

sub Add {
    my ( $Self, %Param ) = @_;
    my $Ticket = $Param{Ticket};
    my $Validated = $Param{Validated};
    return if ref $Ticket ne 'HASH' || !$Ticket->{TicketID} || !$Ticket->{TicketNumber} || $Ticket->{'DynamicField_ZTicket-Parent'}
        || ($Ticket->{CustomerUserID} // '') ne $Param{Actor}
        || ($Ticket->{CustomerID} // '') ne $Validated->{Company};
    my @Logins = @{ $Validated->{Logins} };
    return 1 if !@Logins;
    my @Values = map { ($Ticket->{TicketID}, $Ticket->{TicketNumber}, $_, $Param{Actor}, $Validated->{Company}) } @Logins;
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO tessera_ticket_watcher (ticket_id, ticket_number, watcher_login, granted_by, customer_id, create_time) VALUES '
            . join(', ', ('(?, ?, ?, ?, ?, CURRENT_TIMESTAMP)') x @Logins),
        Bind => [map { \$_ } @Values],
    );
}

sub List {
    my ( $Self, %Param ) = @_;
    my $Login = $Param{CustomerUserID} // '';
    return [] if !$Login;
    my %User = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet( User => $Login );
    return [] if ($User{ValidID} // 0) != 1 || ($User{UserLogin} // '') ne $Login || !$User{UserCustomerID};
    my @Bind = (\$Login, \$User{UserCustomerID});
    my $Filter = '';
    if ( defined $Param{TicketID} ) {
        return [] if $Param{TicketID} !~ /\A[1-9][0-9]*\z/;
        $Filter = ' AND ticket_id = ?';
        push @Bind, \$Param{TicketID};
    }
    my $DB = $Kernel::OM->Get('Kernel::System::DB');
    return [] if !$DB->Prepare(
        SQL => 'SELECT ticket_id, ticket_number FROM tessera_ticket_watcher WHERE watcher_login = ? AND customer_id = ?'
            . $Filter . ' ORDER BY create_time DESC, ticket_id DESC',
        Bind => \@Bind,
    );
    my @Shares;
    while (my @Row = $DB->FetchrowArray()) { push @Shares, \@Row }
    my $Tickets = $Kernel::OM->Get('Kernel::System::Ticket');
    my @Rows;
    for my $Share (@Shares) {
        my ($ID, $Number) = @{$Share};
        my %Ticket = $Tickets->TicketGet( TicketID => $ID, DynamicFields => 1, UserID => 1, Silent => 1 );
        next if !$Ticket{TicketID} || ($Ticket{TicketNumber} // '') ne $Number || $Ticket{'DynamicField_ZTicket-Parent'}
            || ($Ticket{CustomerID} // '') ne $User{UserCustomerID}
            || ($Ticket{StateType} // '') eq 'merged';
        push @Rows, { map { $_ => $Ticket{$_} } qw(TicketID TicketNumber Title State Created) };
    }
    return \@Rows;
}

1;
