package Kernel::GenericInterface::Invoker::AWX::Inventory;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Invoker::AWX::Base);
use JSON::PP ();
use Storable qw(dclone);
our $ObjectManagerDisabled = 1;
sub _Spec { return ('inventories',0) }
sub _Endpoint {
    my ($Self)=@_;
    return $Self->_Kind() eq 'update' ? ('/api/v2/hosts/:HostID/','PATCH')
        : ('/api/v2/inventories/:InventoryID/hosts/', $Self->_Kind() eq 'create' ? 'POST' : 'GET');
}
sub PrepareRequest {
    my ($Self,%P)=@_;
    my $D=$P{Data};
    return $Self->_Error('Inventory input must be bounded non-secret JSON.') if ref $D ne 'HASH'
        || !Kernel::GenericInterface::Invoker::AWX::Base::_DataOK($D) || Kernel::GenericInterface::Invoker::AWX::Base::_CredentialKey($D);
    my $Error=$Self->_ConfigurationError(); return $Self->_Error($Error) if $Error;
    return $Self->_Error('InventoryID must be a positive ID.') if !Kernel::GenericInterface::Invoker::AWX::Base::_ID($D->{InventoryID});
    my $Kind=$Self->_Kind();
    my %Allowed=map {$_=>1} ($Kind eq 'list' ? qw(InventoryID page page_size) : $Kind eq 'create' ? qw(InventoryID name variables) : qw(InventoryID HostID name variables));
    return $Self->_Error('Unsupported inventory parameter.') if grep {!$Allowed{$_}} keys %{$D};
    my $Out=dclone($D);
    $Self->{InventoryID}=$D->{InventoryID};
    if ($Kind eq 'list') {
        $Out->{page}//=1; $Out->{page_size}//=100;
        return $Self->_Error('Invalid inventory page.') if !Kernel::GenericInterface::Invoker::AWX::Base::_ID($Out->{page})
            || !Kernel::GenericInterface::Invoker::AWX::Base::_ID($Out->{page_size}) || $Out->{page_size}>200;
        $Out->{order_by}='id';
    }
    else {
        return $Self->_Error('Managed inventory names must use the stable CI identifier.') if ($D->{name} || '') !~ /\Atessera-ci-[1-9][0-9]{0,14}\z/;
        return $Self->_Error('Inventory variables must be a JSON object.') if ref $D->{variables} ne 'HASH';
        $Self->{HostName}=$D->{name};
        $Out->{variables}=JSON::PP->new->canonical->encode($D->{variables});
        if ($Kind eq 'update') {
            return $Self->_Error('HostID must be a positive ID.') if !Kernel::GenericInterface::Invoker::AWX::Base::_ID($D->{HostID});
            $Self->{HostID}=$D->{HostID};
            delete $Out->{InventoryID};
        }
    }
    return {Success=>1,Data=>$Out};
}
sub HandleResponse {
    my ($Self,%P)=@_;
    return $Self->_Error('Inventory request failed; reconcile any write before retrying.') if !$P{ResponseSuccess};
    my $D=$P{Data};
    return $Self->_Error('Invalid inventory response.') if ref $D ne 'HASH' || !Kernel::GenericInterface::Invoker::AWX::Base::_DataOK($D);
    if ($Self->_Kind() eq 'list') {
        return $Self->_Error('Invalid inventory host page.') if ref $D->{results} ne 'ARRAY' || !defined $D->{count} || ref $D->{count} || $D->{count}!~/\A[0-9]+\z/;
        for my $Host (@{$D->{results}}) {
            return $Self->_Error('Inventory scope mismatch.') if ref $Host ne 'HASH' || !defined $Host->{inventory} || ref $Host->{inventory} || $Host->{inventory} ne $Self->{InventoryID};
        }
    }
    else {
        return $Self->_Error('Inventory host identity/scope mismatch.') if !Kernel::GenericInterface::Invoker::AWX::Base::_ID($D->{id})
            || !defined $D->{inventory} || ref $D->{inventory} || $D->{inventory} ne $Self->{InventoryID}
            || !defined $D->{name} || ref $D->{name} || $D->{name} ne $Self->{HostName} || !$D->{enabled}
            || ($Self->_Kind() eq 'update' && $D->{id} ne $Self->{HostID});
    }
    return {Success=>1,Data=>{Response=>dclone($D)}};
}
1;
