package Kernel::GenericInterface::Operation::TESSERA::Status;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use parent qw(Kernel::GenericInterface::Operation::TESSERA::Common);

our @ObjectDependencies = ('Kernel::System::TESSERA::ExternalChange');

sub Run {
    my ( $Self, %Param ) = @_;
    my $Identity = $Self->APIAuthenticate();
    return $Self->Error( Code => 'TESSERA.AuthFail', Message => 'Invalid API key.' ) if !$Identity;
    my $Change = $Kernel::OM->Get('Kernel::System::TESSERA::ExternalChange')->StageGet(
        ChangeID => $Param{Data}->{ChangeID},
    );
    return $Self->Error( Code => 'TESSERA.NotFound', Message => 'Staging request not found.' )
        if !$Change || $Change->{CustomerUserID} ne $Identity->{CustomerUserID};
    return { Success => 1, Data => { Change => $Change } };
}

1;
