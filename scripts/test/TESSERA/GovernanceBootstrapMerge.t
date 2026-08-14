use strict;
use warnings;
use Test::More;

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::GovernanceDB::Bootstrap;

my $Bootstrap = bless {}, 'Kernel::System::GovernanceDB::Bootstrap';

my $Current = {
    Pages => [
        { Name => 'Summary', Layout => { Columns => 3 }, Content => [ { Section => 'Customer::Custom' } ] },
        { Name => 'Customer Page', Content => [ { DF => 'Customer-Field' } ] },
    ],
    Roles => { 'General Fields' => { Name => 'Customer Role' } },
};
my $Wanted = {
    Pages => [
        { Name => 'Summary', Layout => { Columns => 2, ColumnWidth => '1fr 1fr' }, Content => [ { Section => 'General Fields::ControlIdentity' } ] },
    ],
    Roles => {
        'General Fields' => { Name => 'ZRM ControlObjective' },
        'GovernanceDB Description' => { Name => 'GovernanceDB Description' },
    },
};

my $Merged = $Bootstrap->_StructureMerge( Current => $Current, Wanted => $Wanted );
is( $Merged->{Pages}[0]{Layout}{Columns}, 3, 'customer layout value is preserved' );
is( $Merged->{Pages}[0]{Layout}{ColumnWidth}, '1fr 1fr', 'missing packaged layout value is added' );
is( $Merged->{Roles}{'General Fields'}{Name}, 'Customer Role', 'customer role selection is preserved' );
is( $Merged->{Roles}{'GovernanceDB Description'}{Name}, 'GovernanceDB Description', 'missing packaged role is added' );
ok( grep( { ( $_->{Section} || '' ) eq 'Customer::Custom' } @{ $Merged->{Pages}[0]{Content} } ), 'customer section remains' );
ok( grep( { ( $_->{Section} || '' ) eq 'General Fields::ControlIdentity' } @{ $Merged->{Pages}[0]{Content} } ), 'missing packaged identity section is merged' );
ok( grep( { ( $_->{Name} || '' ) eq 'Customer Page' } @{ $Merged->{Pages} } ), 'customer page remains' );

my $Config = $Bootstrap->_StructureMerge(
    Current => { Tooltip => 'Customer wording', PossibleValues => { Existing => 'Custom' } },
    Wanted  => { Tooltip => 'Package wording', PossibleValues => { Existing => 'Default', Added => 'Added' }, MultiValue => '0' },
);
is( $Config->{Tooltip}, 'Customer wording', 'customer Dynamic Field configuration is preserved' );
is( $Config->{PossibleValues}{Existing}, 'Custom', 'customer option value is preserved' );
is( $Config->{PossibleValues}{Added}, 'Added', 'missing packaged option is added' );
is( $Config->{MultiValue}, '0', 'missing packaged configuration is added' );

done_testing;
