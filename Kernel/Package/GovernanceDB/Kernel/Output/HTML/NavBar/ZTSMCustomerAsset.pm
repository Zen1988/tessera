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

    my $CanReadAssets = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->CustomerHasCMDBReadRole(
        CustomerUserID => $Self->{UserID},
    );

    my $CanSecOps = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->CustomerHasRole(
        CustomerUserID => $Self->{UserID}, Role => 'TESSERA::CMDB::SECOPS',
    );
    my $Navigation = $Param{NavBarModule};
    return if ref $Navigation ne 'HASH';

    my $HideLink = sub {
        my ($Item) = @_;
        return if ref $Item ne 'HASH';
        my $Link = $Item->{Link} || '';
        return 1 if !$CanSecOps && $Link =~ m{(?:\A|[?;&])Action=CustomerSecurityAdvisory(?:[;&]|\z)};
        return 1 if $Link =~ m{(?:\A|[?;&])Action=CustomerTicketOverview(?:[;&]|\z)}
            && $Link =~ m{(?:\A|[?;&])Subaction=CompanyTickets(?:[;&]|\z)};
        return !$CanReadAssets
            && $Link =~ m{(?:\A|[?;&])Action=CustomerITSMConfigItem(?:Zoom|Search|Attachment)?(?:[;&]|\z)};
    };
    my %Return;
    # Layout has already expanded its map into the merge's argument list.
    # Override denied main entries with empty hashes, which Layout skips.
    # Never mutate the map being expanded by the caller.
    for my $Key ( keys %{$Navigation} ) {
        next if $Key eq 'Sub';
        $Return{$Key} = {} if $HideLink->( $Navigation->{$Key} );
    }
    if ( ref $Navigation->{Sub} eq 'HASH' ) {
        my %Sub;
        for my $NavBarName ( keys %{ $Navigation->{Sub} } ) {
            my $Submenu = $Navigation->{Sub}->{$NavBarName};
            if ( ref $Submenu ne 'HASH' ) {
                $Sub{$NavBarName} = $Submenu;
                next;
            }
            my %Items = %{$Submenu};
            for my $Key ( keys %Items ) {
                delete $Items{$Key} if $HideLink->( $Items{$Key} );
            }
            $Sub{$NavBarName} = \%Items;
        }
        $Return{Sub} = \%Sub;
    }
    return %Return;

}

1;
