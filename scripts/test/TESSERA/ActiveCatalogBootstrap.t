use strict;
use warnings;
use Test::More;
use YAML::XS ();
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::GovernanceDB::Bootstrap;
{
    package Local::ActiveCatalog;
    sub Get { $_[1] eq 'Home' ? '.' : $_[0] }
    sub FileRead { \$_[0]{Content} }
    sub Load { my ($S,%P)=@_; YAML::XS::Load($P{Data}) }
    sub Dump { my ($S,%P)=@_; YAML::XS::Dump($P{Data}) }
    sub Import {
        my ($S,%P)=@_;
        $S->{Import} = \%P;
        $S->{Calls}++;
        return {Success=>1};
    }
}
my $Input = {classes=>[
    {class=>'Example',items=>[
        {name=>'Active', valid=>'valid',preferences=>{Color=>['blue']}},
        {name=>'Old',valid=>'invalid'},
        {name=>'Paused',valid=>'invalid-temporarily'},
    ]},
    {class=>'Retired',items=>[{name=>'Legacy',valid=>'invalid'}]},
]};
local $Kernel::OM = bless {Content=>YAML::XS::Dump($Input)}, 'Local::ActiveCatalog';
my $B = bless {}, 'Kernel::System::GovernanceDB::Bootstrap';
ok($B->_GeneralCatalogSeedEnsure(), 'active import succeeds');
my $Selected = YAML::XS::Load($Kernel::OM->{Import}{Content});
is_deeply($Selected, {classes=>[{class=>'Example',items=>[$Input->{classes}[0]{items}[0]]}]}, 'only active items and nonempty groups reach importer; preferences preserved');
is($Kernel::OM->{Import}{CreateOnly},1,'existing catalog remains administrator-owned');
my $First = $Kernel::OM->{Import}{Content};
$B->_GeneralCatalogSeedEnsure();
is($Kernel::OM->{Import}{Content},$First,'repeat import selection unchanged');
my $Calls = $Kernel::OM->{Calls};
delete $Input->{classes}[0]{items}[0]{valid};
$Kernel::OM->{Content}=YAML::XS::Dump($Input);
eval {$B->_GeneralCatalogSeedEnsure()};
like($@,qr/validity is missing or unknown/,'unknown validity rejected');
is($Kernel::OM->{Calls},$Calls,'malformed input never reaches write API');
done_testing;
