package Kernel::System::TESSERA::APIPermission;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

our @ObjectDependencies = (
    'Kernel::System::CustomerGroup',
    'Kernel::System::ITSMConfigItem::CustomerEntitlement',
    'Kernel::System::MELTObject',
);

my %Capability = (
    CMDB       => { Group => 'tessera-cmdb-api',       Role => 'CMDBAPI' },
    MELT       => { Group => 'tessera-melt-api',       Role => 'MELTAPI' },
    GOVERNANCE => { Group => 'tessera-governance-api', Role => 'GovernanceAPI' },
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub CapabilityCheck {
    my ( $Self, %Param ) = @_;
    return if !$Param{CustomerUserID} || !$Param{ObjectType};
    my $Rule = $Capability{ uc $Param{ObjectType} } || return;
    my @Groups = $Kernel::OM->Get('Kernel::System::CustomerGroup')->GroupMemberList(
        UserID => $Param{CustomerUserID}, Type => 'rw', Result => 'Name', RawPermissions => 0,
    );
    return if !grep { $_ eq 'tessera-api' } @Groups;
    return if !grep { $_ eq $Rule->{Group} } @Groups;
    return $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->CustomerHasRole(
        CustomerUserID => $Param{CustomerUserID}, Role => $Rule->{Role},
    );
}

sub ConfigItemCheck {
    my ( $Self, %Param ) = @_;
    return if !$Self->CapabilityCheck( CustomerUserID => $Param{CustomerUserID}, ObjectType => 'CMDB' );
    return $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->_ConfigItemAccessCheck(
        CustomerUserID => $Param{CustomerUserID}, ConfigItemID => $Param{ConfigItemID}, RequireRole => 'CMDBAPI',
    );
}

sub MELTObjectCheck {
    my ( $Self, %Param ) = @_;
    return if !$Self->CapabilityCheck( CustomerUserID => $Param{CustomerUserID}, ObjectType => 'MELT' );
    my $Object = $Kernel::OM->Get('Kernel::System::MELTObject')->MELTObjectGet(
        MELTObjectID => $Param{MELTObjectID}, DynamicFields => 1,
    );
    return if !$Object;
    my @Entitlements = $Self->_ScalarValues( $Object->{'DynamicField_MELT-AccessPermission'} );
    return if !@Entitlements;
    for my $EntitlementID (@Entitlements) {
        return 1 if $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->ContractEntitlementAccessCheck(
            CustomerUserID => $Param{CustomerUserID}, ContractEntitlementID => $EntitlementID,
            RequireRole => 'MELTAPI', LogNo => 1,
        );
    }
    return;
}

sub SubmittedEntitlementsCheck {
    my ( $Self, %Param ) = @_;
    return if !$Param{CustomerUserID} || !$Param{ObjectType} || ref $Param{EntitlementIDs} ne 'ARRAY';
    return if !@{ $Param{EntitlementIDs} };
    my $Role = uc($Param{ObjectType}) eq 'MELT' ? 'MELTAPI' : 'CMDBAPI';
    for my $ID ( @{ $Param{EntitlementIDs} } ) {
        return if !$Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->ContractEntitlementAccessCheck(
            CustomerUserID => $Param{CustomerUserID}, ContractEntitlementID => $ID,
            RequireRole => $Role, LogNo => 1,
        );
    }
    return 1;
}

sub _ScalarValues {
    my ( $Self, $Value ) = @_;
    return if !defined $Value;
    return map { $Self->_ScalarValues($_) } @{$Value} if ref $Value eq 'ARRAY';
    if ( ref $Value eq 'HASH' ) {
        for my $Key (qw(Value Key Content ID)) {
            return $Self->_ScalarValues( $Value->{$Key} ) if defined $Value->{$Key};
        }
        return;
    }
    return $Value eq '' ? () : ($Value);
}

1;
