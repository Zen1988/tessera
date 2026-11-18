package Kernel::GenericInterface::Operation::TESSERA::Stage;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use parent qw(Kernel::GenericInterface::Operation::TESSERA::Common);

our @ObjectDependencies = (
    'Kernel::System::TESSERA::ExternalChange',
    'Kernel::System::TESSERA::APIPermission',
);

sub Run {
    my ( $Self, %Param ) = @_;
    my $Data = $Param{Data} || {};
    my $ObjectType = uc( $Data->{ObjectType} || '' );
    return $Self->Error( Code => 'TESSERA.InvalidObjectType', Message => 'ObjectType must be CMDB or MELT.' )
        if $ObjectType ne 'CMDB' && $ObjectType ne 'MELT';
    my $Identity = $Self->APIAuthenticate( ObjectType => $ObjectType );
    return $Self->Error( Code => 'TESSERA.AuthFail', Message => 'Invalid API key or insufficient capability.' ) if !$Identity;

    my $Payload = $Data->{Payload};
    return $Self->Error( Code => 'TESSERA.InvalidPayload', Message => 'Payload must be a JSON object.' ) if ref $Payload ne 'HASH';
    my $Permission = $Kernel::OM->Get('Kernel::System::TESSERA::APIPermission');
    my $EntitlementField = $ObjectType eq 'MELT' ? 'MELT-AccessPermission' : 'ZTAM-ContractEntitlement';
    my @EntitlementIDs = $Permission->_ScalarValues( $Payload->{$EntitlementField} );
    return $Self->Error( Code => 'TESSERA.EntitlementRequired', Message => "$EntitlementField is required and must contain entitled ContractEntitlement references." )
        if !$Permission->SubmittedEntitlementsCheck(
            CustomerUserID => $Identity->{CustomerUserID}, ObjectType => $ObjectType, EntitlementIDs => \@EntitlementIDs,
        );

    if ( lc( $Data->{Operation} || '' ) eq 'update' ) {
        my $Allowed = $ObjectType eq 'CMDB'
            ? $Permission->ConfigItemCheck( CustomerUserID => $Identity->{CustomerUserID}, ConfigItemID => $Data->{TargetID} )
            : $Permission->MELTObjectCheck( CustomerUserID => $Identity->{CustomerUserID}, MELTObjectID => $Data->{TargetID} );
        return $Self->Error( Code => 'TESSERA.AccessDenied', Message => 'The target is outside the API identity entitlement.' ) if !$Allowed;
    }

    my $Result = $Kernel::OM->Get('Kernel::System::TESSERA::ExternalChange')->StageAdd(
        Source => $Data->{Source} || 'external', IdempotencyKey => $Data->{IdempotencyKey},
        ObjectType => $ObjectType, ObjectClass => $Data->{ObjectClass}, Operation => $Data->{Operation},
        TargetID => $Data->{TargetID}, ExpectedVersionID => $Data->{ExpectedVersionID}, TicketID => $Data->{TicketID},
        SchemaHash => $Data->{SchemaHash}, Payload => $Payload, CustomerUserID => $Identity->{CustomerUserID},
        UserID => 1,
    );
    return $Self->Error( Code => 'TESSERA.StageFailed', Message => $Result->{Error} ) if !$Result->{Success};
    return { Success => 1, Data => { Duplicate => $Result->{Duplicate} ? 1 : 0, Change => $Result->{Change} } };
}

1;
