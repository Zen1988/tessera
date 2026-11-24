use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
require(abs_path('var/governancedb/runtime_overlay/Kernel/System/ITSMConfigItem/Permission.pm'));
{
    package AddonFixture;
    sub Get {
        my ($Self, $Key) = @_;
        return $Self if $Key =~ /^Kernel::/;
        return 'managers' if $Key eq 'ITSMConfigItemManagementGroup';
        return {grant => {Module => 'AddonGrant', Granted => 1}} if $Key =~ /^ITSMConfigItem::Permission::/;
        return;
    }
    sub ConfigItemGet { $_[0]->{Reads}++; return $_[0]->{Item}; }
    sub GroupMemberList { return %{$_[0]->{Groups} || {}}; }
    sub Require { 1 }
    sub Log { 1 }
    sub ConfigItemDetailAccessCheck {
        my ($Self, %Param) = @_;
        $Self->{Detail} = \%Param;
        return $Self->{Entitled};
    }
    package AddonGrant;
    sub new { bless {}, shift }
    sub Run { $Kernel::OM->{Grants}++; return 1; }
}
local $Kernel::OM = bless {Item => {ConfigItemID => 10, GroupID => 4}, Groups => {}}, 'AddonFixture';
my $Permission = bless {}, 'Kernel::System::ITSMConfigItem::Permission';
my %Args = (Type => 'ro', Scope => 'Item', ItemID => 10, UserID => 2, LogNo => 1);
ok(!$Permission->Permission(%Args), 'class grant cannot bypass tenant item group');
ok(!$Kernel::OM->{Grants}, 'grant modules not reached for wrong tenant');
$Kernel::OM->{Groups} = {4 => 'tenant'};
ok($Permission->Permission(%Args), 'matching tenant and grant module permit agent read');
$Kernel::OM->{Groups} = {8 => 'managers'};
ok($Permission->Permission(%Args), 'configured native manager group retains item access');
$Kernel::OM->{Item} = {};
ok(!$Permission->Permission(%Args), 'missing CI fails closed');
$Kernel::OM->{Item} = {ConfigItemID => 10};
$Kernel::OM->{Groups} = {};
ok($Permission->Permission(%Args), 'ungrouped native item still requires normal grant module');
$Kernel::OM->{Entitled} = 0;
ok(!$Permission->CustomerPermission(ConfigItemID => 10, UserID => 'customer'), 'customer access delegates denial');
$Kernel::OM->{Entitled} = 1;
ok($Permission->CustomerPermission(ConfigItemID => 10, UserID => 'customer'), 'central entitlement may grant customer read');
is_deeply($Kernel::OM->{Detail}, {ConfigItemID => 10, CustomerUserID => 'customer', LogNo => undef}, 'trusted customer identity sent to central service');
my $Reads = $Kernel::OM->{Reads};
ok(!$Permission->PublicPermission(ConfigItemID => 10), 'anonymous CI detail denied');
is($Kernel::OM->{Reads}, $Reads, 'public denial does not fetch CI');
done_testing;
