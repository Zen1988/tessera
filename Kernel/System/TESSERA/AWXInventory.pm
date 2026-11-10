package Kernel::System::TESSERA::AWXInventory;
use strict;
use warnings;
use JSON::PP ();
use Storable qw(dclone);
use Kernel::GenericInterface::Invoker::AWX::Base;
our @ObjectDependencies=('Kernel::GenericInterface::Requester');
sub new { my ($Type,%P)=@_; return bless {Requester=>$P{Requester}},$Type }
sub _Call {
    my ($Self,$WS,$Name,$Data)=@_;
    return ($Self->{Requester} || $Kernel::OM->Get('Kernel::GenericInterface::Requester'))->Run(WebserviceID=>$WS,Invoker=>$Name,Data=>$Data);
}
sub Sync {
    my ($Self,%P)=@_;
    my $Hosts=$P{Hosts};
    return {Success=>0,Error=>'Invalid non-secret inventory snapshot.',LaunchAllowed=>0} if ref $Hosts ne 'ARRAY' || !@{$Hosts} || @{$Hosts}>1000
        || !Kernel::GenericInterface::Invoker::AWX::Base::_DataOK($Hosts) || Kernel::GenericInterface::Invoker::AWX::Base::_CredentialKey($Hosts)
        || !Kernel::GenericInterface::Invoker::AWX::Base::_ID($P{InventoryID}) || !Kernel::GenericInterface::Invoker::AWX::Base::_ID($P{WebserviceID});
    my %Desired;
    for my $H (@{$Hosts}) {
        return {Success=>0,LaunchAllowed=>0,Error=>'Snapshot requires unique CI IDs, literal host addresses and JSON Variables.'}
            if ref $H ne 'HASH' || !Kernel::GenericInterface::Invoker::AWX::Base::_ID($H->{ConfigItemID})
                || !defined $H->{Address} || ref $H->{Address} || $H->{Address}!~/\A[A-Za-z0-9_.:%-]{1,253}\z/
                || (exists $H->{Variables} && ref $H->{Variables} ne 'HASH') || $Desired{$H->{ConfigItemID}};
        return {Success=>0,LaunchAllowed=>0,Error=>'Ansible connection/credential overrides are not permitted.'}
            if grep {/\Aansible_/i || /\Atessera_/i} keys %{$H->{Variables} || {}};
        $Desired{$H->{ConfigItemID}}=$H;
    }
    # Read the entire bounded inventory before performing any mutation. Never
    # follow API-returned URLs, delete manual entries or invent CMDB field maps.
    my %Existing;
    for my $Page (1..100) {
        my $R=$Self->_Call($P{WebserviceID},'InventoryHosts',{InventoryID=>$P{InventoryID},page=>$Page,page_size=>100});
        return {Success=>0,LaunchAllowed=>0,Error=>'Could not read the inventory.'} if !$R->{Success};
        my $D=$R->{Data}{Response};
        return {Success=>0,LaunchAllowed=>0,Error=>'Inventory page is invalid or exceeds limits.'} if ref $D ne 'HASH' || ref $D->{results} ne 'ARRAY' || ($D->{count} || 0)>10000;
        for my $H (@{$D->{results}}) {
            return {Success=>0,LaunchAllowed=>0,Error=>'Inventory scope/name ambiguity.'} if ref $H ne 'HASH' || ($H->{inventory} || 0)!=$P{InventoryID} || !defined $H->{name} || ref $H->{name} || $Existing{$H->{name}};
            $Existing{$H->{name}}=$H;
        }
        last if !$D->{next};
        return {Success=>0,LaunchAllowed=>0,Error=>'Inventory pagination exceeded limits.'} if $Page==100;
    }
    my @Plan;
    for my $ID (sort {$a<=>$b} keys %Desired) {
        my $Name='tessera-ci-'.$ID;
        my $Old=$Existing{$Name};
        my $Vars={};
        my $Before;
        if ($Old) {
            $Vars=eval {ref $Old->{variables} eq 'HASH' ? $Old->{variables} : JSON::PP->new->decode($Old->{variables} || '{}')};
            return {Success=>0,LaunchAllowed=>0,Error=>'Existing host is not an unambiguous TESSERA-managed JSON host.'}
                if ref $Vars ne 'HASH' || ($Vars->{tessera_cmdb_configitem_id} || 0)!=$ID || ref $Vars->{tessera_managed_keys} ne 'ARRAY' || !$Old->{enabled};
            return {Success=>0,LaunchAllowed=>0,Error=>'Existing host contains unsupported connection overrides.'} if grep {/\Aansible_/i && $_ ne 'ansible_host'} keys %{$Vars};
            $Vars=dclone($Vars);
            $Before=JSON::PP->new->canonical->encode($Vars);
            return {Success=>0,LaunchAllowed=>0,Error=>'Invalid variable ownership marker.'}
                if grep {!defined $_ || ref $_ || !/\A[A-Za-z_][A-Za-z0-9_]{0,99}\z/} @{$Vars->{tessera_managed_keys}};
            delete @{$Vars}{@{$Vars->{tessera_managed_keys}}};
        }
        my %New=(%{$Desired{$ID}{Variables} || {}},ansible_host=>$Desired{$ID}{Address},tessera_cmdb_configitem_id=>0+$ID);
        $New{tessera_managed_keys}=[sort keys %New];
        my %Merged=(%{$Vars},%New);
        return {Success=>0,LaunchAllowed=>0,Error=>'Managed variables contain credentials.'} if Kernel::GenericInterface::Invoker::AWX::Base::_CredentialKey(\%Merged);
        next if $Old && JSON::PP->new->canonical->encode(\%Merged) eq $Before;
        push @Plan,[$Old?'InventoryHostUpdate':'InventoryHostCreate',{InventoryID=>$P{InventoryID},name=>$Name,variables=>\%Merged, $Old ? (HostID=>$Old->{id}) : ()}];
    }
    my $Written=0;
    for my $Step (@Plan) {
        my $R=$Self->_Call($P{WebserviceID},@{$Step});
        return {Success=>0,LaunchAllowed=>0,Partial=>1,ConfirmedChanges=>$Written,Outcome=>'UNKNOWN',Error=>'Inventory write was not confirmed; reconcile before retrying.'} if !$R->{Success};
        $Written++;
    }
    return {Success=>1,LaunchAllowed=>1,InventoryID=>$P{InventoryID},Changed=>$Written,
        Limit=>join(':',map {'tessera-ci-'.$_} sort {$a<=>$b} keys %Desired)};
}
1;
