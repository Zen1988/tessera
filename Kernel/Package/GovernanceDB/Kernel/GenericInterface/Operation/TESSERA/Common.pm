package Kernel::GenericInterface::Operation::TESSERA::Common;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::TESSERA::APIKey',
    'Kernel::System::TESSERA::APIPermission',
    'Kernel::System::Web::Request',
);

sub new {
    my ( $Type, %Param ) = @_;
    my $Self = bless {}, $Type;
    $Self->{$_} = $Param{$_} for qw(DebuggerObject WebserviceID);
    return $Self;
}

sub APIAuthenticate {
    my ( $Self, %Param ) = @_;
    return if !$Kernel::OM->Get('Kernel::Config')->Get('TESSERA::API::Enabled');
    my $Header = $Kernel::OM->Get('Kernel::System::Web::Request')->Header('Authorization') || '';
    return if $Header !~ m{\ABearer\s+(.+)\z}i;
    my $Identity = $Kernel::OM->Get('Kernel::System::TESSERA::APIKey')->KeyAuthenticate( APIKey => $1 );
    return if !$Identity;
    return if $Param{ObjectType} && !$Kernel::OM->Get('Kernel::System::TESSERA::APIPermission')->CapabilityCheck(
        CustomerUserID => $Identity->{CustomerUserID}, ObjectType => $Param{ObjectType},
    );
    return $Identity;
}

sub Error {
    my ( $Self, %Param ) = @_;
    return { Success => 0, ErrorMessage => $Param{Message} || 'Request failed.', Data => { Error => $Param{Code} || 'TESSERA.Error' } };
}

1;
