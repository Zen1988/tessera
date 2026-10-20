use strict;
use warnings;
use Test::More;
use JSON::PP ();
use YAML::XS ();
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::GovernanceDB::Bootstrap;
{
    package Local::CMDBSeed;
    sub Get { $_[1] eq 'Home' ? '.' : $_[0] }
    sub FileRead { \$_[0]{Content} }
    sub Decode { my ($S,%P)=@_; JSON::PP::decode_json($P{Data}) }
    sub ItemList {
        my ($S,%P)=@_;
        die 'Disabled records must be included' if $P{Valid} != 0;
        return $S->{Existing}{$P{Class}} || {};
    }
    sub ClassImport {
        my ($S,%P)=@_;
        $S->{Import}=\%P;
        return {Success=>1};
    }
}
local $Kernel::OM = bless {
    Content=>JSON::PP::encode_json([
        {Class=>{Name=>'Disabled'},Definition=>'{}'},
        {Class=>{Name=>'New'},Definition=>'{}'},
        {RoleName=>'DisabledRole',Definition=>'{}'},
        {RoleName=>'NewRole',Definition=>'{}'},
    ]),
    Existing=>{
        'ITSM::ConfigItem::Class'=>{1=>'Disabled'},
        'ITSM::ConfigItem::Role'=>{2=>'DisabledRole'},
    },
}, 'Local::CMDBSeed';
my $B=bless {},'Kernel::System::GovernanceDB::Bootstrap';
ok($B->_ITSMConfigItemDefaultsEnsure(),'model importer succeeds');
is_deeply([map {$_->{Class} ? $_->{Class}{Name} : $_->{RoleName}} @{$Kernel::OM->{Import}{Content}}],['New','NewRole'],'existing disabled class/role excluded before native importer');
is($Kernel::OM->{Import}{ClassExists},'IGNORE','native import preserves existing records');

my $Catalog=YAML::XS::LoadFile('Export/GeneralCatalog_2026-10-19.yml');
my %Validity;
for my $Group(@{$Catalog->{classes}}) {
    $Validity{$Group->{class}}{$_->{name}}=$_->{valid} for @{$Group->{items}};
}
open my $F,'<:raw','Kernel/Package/GovernanceDB/var/governancedb/default_configitem.json' or die $!;
local $/; my $Seed=JSON::PP::decode_json(<$F>); close $F;
my @Bad=grep {
    my $Kind=$_->{Class} ? 'Class' : 'Role';
    my $Name=$_->{Class} ? $_->{Class}{Name} : $_->{RoleName};
    ($Validity{"ITSM::ConfigItem::$Kind"}{$Name} || '') ne 'valid';
} @$Seed;
is(scalar @Bad,0,'every packaged CMDB definition is active in current export');
is(scalar @$Seed,64,'complete implemented active CMDB model packaged');
my $General=YAML::XS::LoadFile('Kernel/Package/GovernanceDB/var/governancedb/default_general_catalog.yml');
my @Inactive=map {grep {$_->{valid} ne 'valid'} @{$_->{items}}} @{$General->{classes}};
is(scalar @Inactive,0,'inactive catalog entries removed from fresh seeds');
ok(!grep({$_->{class} =~ /\AITSM::ConfigItem::(?:Class|Role)\z/} @{$General->{classes}}),'CMDB class/role labels created by model importer, not preseeded into IGNORE skip');
done_testing;
