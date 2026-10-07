use strict;
use warnings;
use Test::More;
require './Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/CustomerEntitlement.pm';

my $Path = 'Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/Modules/CustomerITSMConfigItem.pm';
open my $FH, '<', $Path or die $!;
my $Source = do { local $/; <$FH> };
my ($Helper) = $Source =~ /(sub _ZTSMConfigItemSearchAll \{.*?)(?=sub _ZTSMAssetExport)/s;
die 'Search helper missing' unless $Helper;
eval "package CompleteAssetPage; $Helper; 1" or die $@;
{
    package CompleteAssetBackend;
    sub ConfigItemSearch {
        my ($Self, %Param) = @_;
        push @{$Self->{Calls}}, {%Param};
        return $Self->{Count} if $Param{Result} eq 'COUNT';
        my @IDs = @{$Self->{IDs}};
        splice @IDs, $Param{Limit} if @IDs > $Param{Limit};
        return @IDs;
    }
    package CompleteAssetOM;
    sub Get { $_[0]{Backend} }
    package CompleteAssetEntitlement;
    our @ISA = ('Kernel::System::ITSMConfigItem::CustomerEntitlement');
    sub _ConfigItemAccessCheck {
        my ($Self, %Param) = @_;
        push @{$Self->{Calls}}, {%Param};
        return $Param{CustomerUserID} eq 'test-customer'
            && $Param{RequireCMDBReadRole}
            && $Param{ConfigItemID} == 12050;
    }
}
my $Backend = bless { Count => 12050, IDs => [1..12050], Calls => [] }, 'CompleteAssetBackend';
local $Kernel::OM = bless { Backend => $Backend }, 'CompleteAssetOM';
my $Page = bless {}, 'CompleteAssetPage';
my %Search = (Classes => ['Workload'], SortBy => 'Age', OrderBy => 'Up', Limit => 1000,
    DynamicField_ExistingFilter => {Equals => 'existing-value'}, CacheTTL => 240);
my @IDs = $Page->_ZTSMConfigItemSearchAll(%Search);
is(scalar @IDs, 12050, 'all matching candidates survive both old fixed cutoffs');
is($IDs[-1], 12050, 'late entitled asset reaches permission filtering');
is($Backend->{Calls}[0]{Result}, 'COUNT', 'aggregate count determines complete candidate bound');
is($Backend->{Calls}[1]{Limit}, 12050, 'candidate bound is actual match count');
is($Backend->{Calls}[1]{CacheTTL}, 0, 'count and IDs do not use independently stale search caches');
for my $Call (@{$Backend->{Calls}}) {
    is_deeply($Call->{Classes}, ['Workload'], 'class restriction preserved');
    is_deeply($Call->{DynamicField_ExistingFilter}, {Equals => 'existing-value'}, 'existing field filter preserved');
    is($Call->{OrderBy}, 'Up', 'sort order preserved');
}
my $Permission = bless { Calls => [] }, 'CompleteAssetEntitlement';
my $Allowed = $Permission->ConfigItemIDsFilter(CustomerUserID => 'test-customer', ConfigItemIDs => \@IDs,
    RequireCMDBReadRole => 1);
is_deeply($Allowed, [12050], 'real ID filter includes late authorized asset and excludes all others');
is(scalar @{$Permission->{Calls}}, 12050, 'every candidate passes the backend access boundary');
$Allowed = $Permission->ConfigItemIDsFilter(CustomerUserID => 'other-customer', ConfigItemIDs => \@IDs,
    RequireCMDBReadRole => 1);
is_deeply($Allowed, [], 'another customer cannot receive the entitled asset');
for my $Count (0, undef) {
    $Backend->{Count} = $Count; $Backend->{Calls} = [];
    my @Empty = $Page->_ZTSMConfigItemSearchAll(%Search);
    is_deeply(\@Empty, [], 'empty or failed count returns no assets');
    is(scalar @{$Backend->{Calls}}, 1, 'no fallback broad search on empty or failed count');
}
is(scalar(() = $Source =~ /\$Self->_ZTSMConfigItemSearchAll\(/g), 3, 'overview and both count paths use complete candidate retrieval');
unlike($Source, qr/my \$Limit = 1_000/, 'overview fixed cutoff removed');
like($Source, qr/Limit\s*=> scalar\(\@OriginalViewableConfigItems\) \|\| 1/, 'pagination covers every authorized result');
done_testing();
