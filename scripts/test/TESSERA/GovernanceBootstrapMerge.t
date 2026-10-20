use strict;
use warnings;
use Test::More;
use YAML::XS qw(LoadFile);

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

my $BootstrapPath = 'Kernel/Package/GovernanceDB/Kernel/System/GovernanceDB/Bootstrap.pm';
open my $BootstrapFH, '<:raw', $BootstrapPath or die "Cannot read $BootstrapPath: $!";
local $/;
my $BootstrapSource = <$BootstrapFH>;
close $BootstrapFH;

my $NonMigrationSource=$BootstrapSource;
$NonMigrationSource =~ s/DELETE FROM generic_agent_jobs WHERE job_name = \? AND job_key = \?//g;
unlike( $NonMigrationSource, qr{\b(?:DELETE\s+FROM|DROP\s+TABLE|TRUNCATE\s+TABLE)\b}i,
    'bootstrap removes only scoped legacy role type filters, no other rows or tables' );
like( $BootstrapSource, qr{ClassExists\s*=>\s*'IGNORE'},
    'ConfigItem class import preserves an existing class' );
like( $BootstrapSource, qr{StateLookup\(.*?next STATE if \$StateID;}s,
    'existing ticket states are never rewritten or reactivated' );
like( $BootstrapSource, qr{TypeLookup\(.*?next TYPE if \$TypeID;}s,
    'existing ticket types are never rewritten or reactivated' );
like( $BootstrapSource, qr{CreateOnly\s*=>\s*1},
    'General Catalog seed import is create-only' );
like( $BootstrapSource, qr{ItemList\(\s*Class\s*=>\s*\$Param\{Class\},\s*Valid\s*=>\s*0,}s,
    'General Catalog lookup includes invalid existing items' );
like( $BootstrapSource, qr{return 1 if \$CurrentDefinition && \$CurrentDefinition->\{DefinitionID\};},
    'existing GovernanceObject definitions are left unchanged' );
like( $BootstrapSource, qr{next ROLE if \$ExistingID;},
    'existing GovernanceRole objects are left unchanged' );
like( $BootstrapSource, qr{next FIELD if \$Existing;},
    'existing Dynamic Fields are left unchanged' );
unlike( $BootstrapSource, qr{InstallDefaults.*?_ReferenceDisplayTypesRepair\(\)}s,
    'installation does not repair existing reference Dynamic Fields' );
unlike( $BootstrapSource, qr{InstallDefaults.*?_TicketReferenceValuesRepair\(}s,
    'installation does not rewrite stored reference values' );
unlike( $BootstrapSource, qr{InstallDefaults.*?_CustomerBrandingEnsure\(\)}s,
    'installation does not overwrite existing customer branding settings' );
unlike( $BootstrapSource, qr{JobDelete\(},
    'bootstrap never deletes and recreates an existing GenericAgent job' );
like( $BootstrapSource, qr{JobGet\(.*?if \(%Existing\) \{.*?_RoleLookupUniversalTypesEnsure.*?next JOB;}s,
    'existing jobs receive only scoped role lookup filter migration' );
like( $BootstrapSource, qr{_ProcessNameExists\(.*?next FILE;}s,
    'existing processes are left unchanged regardless of activation state' );
unlike( $BootstrapSource, qr{sub _SysConfigDeploy.*?_DynamicFieldDriverObjectTypeEnsure\(}s,
    'SysConfig deployment does not merge into existing Dynamic Field driver settings' );

my $CatalogSeed = LoadFile('Kernel/Package/GovernanceDB/var/governancedb/default_general_catalog.yml');
my %CatalogClass = map {
    $_->{class} => { map { $_->{name} => $_ } @{ $_->{items} || [] } }
} @{ $CatalogSeed->{classes} || [] };
my $ClassSeed = do {
    open my $F, '<:raw', 'Kernel/Package/GovernanceDB/var/governancedb/default_classes.json' or die $!;
    local $/;
    require JSON::PP;
    JSON::PP::decode_json(<$F>);
};
my %SeedClass = map {$_->{Name}=>1} @{$ClassSeed->{Classes}};
my %SeedRole = map {$_->{Name}=>1} @{$ClassSeed->{Roles}};

for my $NewClass (qw(EventSeverity Severity)) {
    ok( $SeedClass{$NewClass},
        "new top-level GovernanceObject class $NewClass is seeded when missing" );
}
for my $NewRole ( 'EventSeverity', 'Policy', 'ZTSM Code' ) {
    ok( $SeedRole{$NewRole},
        "supporting GovernanceObject role $NewRole is seeded when missing" );
}
ok( $CatalogClass{'ZTSM::Type'}{RiskTreatment},
    'RiskTreatment is seeded in the BlueBook Ticket Type catalog' );
for my $Deprecated (
    [ 'ZTSM::GovernanceObject::Class', 'Control' ],
    [ 'ZTSM::GovernanceObject::Class', 'ControlRecommendation' ],
    [ 'ZTSM::GovernanceObject::Role',  'ZRM Control' ],
) {
    ok( !$CatalogClass{$Deprecated->[0]}{$Deprecated->[1]},
        "$Deprecated->[1] is excluded for a fresh installation" );
}

done_testing;
