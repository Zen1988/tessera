package Kernel::Output::HTML::NavBar::ZTSMCustomerAsset;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::ITSMConfigItem::CustomerEntitlement',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless { %Param }, $Type;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->CustomerHasAssetRole(
        CustomerUserID => $Self->{UserID},
    );

    my %Return = %{ $Param{NavBar}->{Sub} || {} };

    for my $NavBarName ( keys %Return ) {
        next if ref $Return{$NavBarName} ne 'HASH';

        for my $Priority ( keys %{ $Return{$NavBarName} } ) {
            my $Navigation = $Return{$NavBarName}->{$Priority};
            next if ref $Navigation ne 'HASH';
            next if ( $Navigation->{Link} || '' ) !~ m{(?:\A|;)Action=CustomerITSMConfigItem(?:;|\z)};
            delete $Return{$NavBarName}->{$Priority};
        }
    }

    return ( Sub => \%Return );
}

1;
