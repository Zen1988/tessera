package Kernel::System::TESSERA::NotificationEmailAdapter;

use strict;
use warnings;

use Digest::SHA qw(sha256_hex);
use Email::Address::XS ();
use Encode qw(encode_utf8);

our @ObjectDependencies = qw(
    Kernel::System::CustomerUser
    Kernel::System::Email
    Kernel::System::Queue
    Kernel::System::SystemAddress
);

sub new {
    my ($Type) = @_;
    return bless {}, $Type;
}

# Call only from a dispatcher that has checked recipient access, preferences,
# and the durable dispatch claim. Message-ID supports correlation, not deduplication.
sub Submit {
    my ( $Self, %Param ) = @_;
    my $QueueID = $Param{QueueID};
    my $Recipient = $Param{CustomerUserID};
    my $Key = $Param{DispatchKey};
    my $Rendered = $Param{Rendered};
    return { Status => 'Rejected', Reason => 'InvalidEnvelope' }
        if !defined $QueueID || ref $QueueID || $QueueID !~ /\A[1-9][0-9]*\z/
        || !defined $Recipient || ref $Recipient || $Recipient !~ /\S/
        || length($Recipient) > 250 || $Recipient =~ /[[:cntrl:]]/
        || !defined $Key || ref $Key || $Key !~ /\S/
        || length($Key) > 512 || $Key =~ /[[:cntrl:]]/;
    return { Status => 'Rejected', Reason => 'InvalidRenderedMessage' }
        if ref $Rendered ne 'HASH'
        || !defined $Rendered->{Subject} || ref $Rendered->{Subject}
        || $Rendered->{Subject} !~ /\S/ || $Rendered->{Subject} =~ /[[:cntrl:]]/
        || length($Rendered->{Subject}) > 780
        || !defined $Rendered->{HTML} || ref $Rendered->{HTML}
        || $Rendered->{HTML} !~ /\S/ || length($Rendered->{HTML}) > 262144;

    my ( $From, $To, $MessageID );
    my $Resolved = eval {
        my %Customer = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(
            User => $Recipient,
        );
        if ( ($Customer{UserLogin} // '') eq $Recipient && ($Customer{ValidID} // 0) == 1 ) {
            $To = _Mailbox( $Customer{UserEmail} );
        }
        my %Queue = $Kernel::OM->Get('Kernel::System::Queue')->QueueGet( ID => $QueueID );
        if ($Queue{SystemAddressID}) {
            my %Address = $Kernel::OM->Get('Kernel::System::SystemAddress')->SystemAddressGet(
                ID => $Queue{SystemAddressID},
            );
            $From = _Mailbox( $Address{Name} ) if ($Address{ValidID} // 0) == 1;
        }
        1;
    };
    return { Status => 'Rejected', Reason => 'AddressResolutionFailed' } if !$Resolved;
    return { Status => 'Rejected', Reason => 'RecipientUnavailable' } if !$To;
    return { Status => 'Rejected', Reason => 'SenderUnavailable' } if !$From;

    my ($Domain) = $From =~ /\@([a-zA-Z0-9.-]+)\z/;
    return { Status => 'Rejected', Reason => 'SenderDomainUnavailable' } if !$Domain;
    my $Digest = sha256_hex(encode_utf8($Key));
    $MessageID = '<tessera-notify.' . $Digest . '@' . lc($Domain) . '>';

    my $Email = eval { $Kernel::OM->Get('Kernel::System::Email') };
    return { Status => 'Rejected', Reason => 'TransportUnavailable' } if !$Email;
    my $Native = eval {
        $Email->Send(
            From          => $From,
            To            => $To,
            Subject       => $Rendered->{Subject},
            Charset       => 'utf-8',
            MimeType      => 'text/html',
            Body          => $Rendered->{HTML},
            'Message-ID'  => $MessageID,
            CustomHeaders => { 'Auto-Submitted' => 'auto-generated' },
        );
    };
    return { Status => 'Unknown', Reason => 'QueueOutcomeUnknown', MessageID => $MessageID }
        if ref $Native ne 'HASH' || !defined $Native->{Success} || $Native->{Success} !~ /\A[01]\z/;
    return { Status => 'Rejected', Reason => 'NativeQueueRejected', MessageID => $MessageID }
        if !$Native->{Success};
    return { Status => 'Queued', MessageID => $MessageID };
}

sub _Mailbox {
    my ($Value) = @_;
    return if !defined $Value || ref $Value || length($Value) > 254
        || $Value =~ /[[:cntrl:]\s,;<>]/;
    my @Parsed = Email::Address::XS->parse($Value);
    return if @Parsed != 1 || !$Parsed[0]->is_valid || ($Parsed[0]->address // '') ne $Value;
    return $Value;
}

1;
