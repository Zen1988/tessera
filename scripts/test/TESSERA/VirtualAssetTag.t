use strict;
use warnings;
use Test::More;

# Exercise the actual Import method with isolated persistence/catalog adapters.
open my $FH, '<', 'Kernel/Package/GovernanceDB/Kernel/System/ITSMConfigItem/Document.pm' or die $!;
my $Source = do { local $/; <$FH> };
my ($Import) = $Source =~ /(sub Import\s*\{.*)\n1;/s;
die 'Import method missing' if !$Import;
{
    package ImportUnderTest;
    sub IsHashRefWithData { ref $_[0] eq 'HASH' && keys %{ $_[0] } }
    sub IsStringWithData { defined $_[0] && !ref $_[0] && length $_[0] }
    sub _ValueFromDocument { my ( $Self, %P ) = @_; return $P{Value} }
    eval $Import;
    die $@ if $@;
}
{
    package ImportAdapters;
    sub Get { $_[1] eq 'TESSERA::CMDB::VirtualAssetTag###Pattern' ? $_[0]->{Pattern} : $_[0] }
    sub ItemList {
        my ( $Self, %P ) = @_;
        return { 1 => 'Workload' } if $P{Class} eq 'ITSM::ConfigItem::Class';
        return { 2 => 'Production' } if $P{Class} eq 'ITSM::ConfigItem::DeploymentState';
        return { 3 => 'Operational' };
    }
    sub DefinitionGet { return { DynamicFieldRef => {
        'ZTAM-AssetTag' => { Name => 'ZTAM-AssetTag' },
        'ZTAM-Application' => { Name => 'ZTAM-Application' },
    } } }
    sub GovernanceObjectGet { $_[0]->{Application} }
    sub ConfigItemLookup { 42 }
    sub ConfigItemGet { $_[0]->{Existing} || { ConfigItemID => 42, VersionString => '7' } }
    sub ConfigItemAdd { $_[0]->{Writes}++; ++$_[0]->{NextID} }
    sub ConfigItemUpdate {
        my ( $Self, %P ) = @_;
        $Self->{Writes}++;
        $Self->{Tag} = $P{'DynamicField_ZTAM-AssetTag'};
        $Self->{Version} = $P{VersionString} if exists $P{VersionString};
        return 1;
    }
    sub ActivityAdd { 1 }
}
my $Importer = bless {}, 'ImportUnderTest';
for my $Case (
    [ 'Application with code', { 'DynamicField_ZTSM-Code' => 'APP' }, 7, '', '', 'APP-VT-101' ],
    [ 'Application without code', { Name => 'Application' }, 7, '', '', 'tessera-virtualtag-101' ],
    [ 'Application with whitespace code', { 'DynamicField_ZTSM-Code' => '  ' }, 7, '', '', 'tessera-virtualtag-101' ],
    [ 'Missing Application', {}, undef, '', '', undef ],
    [ 'Unresolved Application', {}, 7, '', '', undef ],
    [ 'Supplied tag needs no Application', {}, undef, 'PHYSICAL-1', 'CI42', 'PHYSICAL-1' ],
    [ 'Custom pattern retained', { 'DynamicField_ZTSM-Code' => 'APP' }, [7], '', '', 'custom-APP-101', 'custom-<ZTSM-Code>-<running id>' ],
    [ 'Fallback ignores code-dependent custom pattern', { Name => 'Application' }, 7, '', '', 'tessera-virtualtag-101', 'custom-<ZTSM-Code>' ],
    [ 'Update stable fallback', { Name => 'Application' }, 7, '', 'CI42', 'tessera-virtualtag-42' ],
) {
    my ( $Name, $App, $AppID, $Tag, $Number, $Expected, $Pattern ) = @{$Case};
    $Kernel::OM = bless { Application => $App, NextID => 100, Writes => 0, Pattern => $Pattern }, 'ImportAdapters';
    my $Result = $Importer->Import( UserID => 1, Data => {
        class => 'Workload', name => 'Test workload', number => $Number,
        deployment_state => 'Production', incident_state => 'Operational',
        fields => { 'ZTAM-Application' => $AppID, 'ZTAM-AssetTag' => $Tag },
    } );
    is( $Result->{Success}, defined $Expected ? 1 : 0, "$Name: outcome" );
    if ( defined $Expected ) {
        is( $Kernel::OM->{Tag}, $Expected, "$Name: tag" );
    }
    else {
        is( $Kernel::OM->{Writes}, 0, "$Name: rejected before persistence" );
        like( $Result->{Message}, qr/Application cannot be resolved/, "$Name: clear error" );
    }
}
for my $Incoming ( undef, '', '   ', '9' ) {
    $Kernel::OM = bless {
        Existing => { ConfigItemID => 42, VersionString => '7', 'DynamicField_ZTAM-AssetTag' => 'KEEP-42' },
        Application => {}, Writes => 0,
    }, 'ImportAdapters';
    my $Result = $Importer->Import( UserID => 1, Data => {
        class => 'Workload', name => 'Test', number => 'CI42', version => $Incoming,
        deployment_state => 'Production', incident_state => 'Operational',
        fields => { 'ZTAM-AssetTag' => $Incoming },
    } );
    ok( $Result->{Success}, 'Merge succeeds without Application when tag already exists' );
    is( $Kernel::OM->{Tag}, defined $Incoming && $Incoming eq '9' ? '9' : 'KEEP-42', 'Blank tag preserves existing; explicit tag replaces' );
    is( $Kernel::OM->{Version}, defined $Incoming && $Incoming eq '9' ? '9' : '7', 'Blank version preserves existing; explicit version replaces' );
    is( $Kernel::OM->{Writes}, 1, 'Merge does not regenerate an existing tag' );
}
open my $WorkbookFH, '<', 'Kernel/Package/GovernanceDB/Kernel/Modules/AgentITSMConfigItemWorkbook.pm' or die $!;
my $WorkbookSource = do { local $/; <$WorkbookFH> };
my ($PreviewMethods) = $WorkbookSource =~ /(sub _ClearFields.*)\n1;/s;
{ package PreviewUnderTest; eval $PreviewMethods; die $@ if $@; }
my $Preview = bless {}, 'PreviewUnderTest';
is_deeply( [ $Preview->_ClearFields(
    Existing => { version => '7', description => 'Keep warning', fields => { 'ZTAM-AssetTag' => 'KEEP-42' } },
    Incoming => { Version => '', 'ZTAM-AssetTag' => '' },
) ], ['Description'], 'Preview excludes merged identity fields but retains other destructive warnings' );
unlike( $WorkbookSource, qr/version\s*=>\s*\$Row->\{Version\}\s*\|\|/, 'Workbook passes blank version through to merge logic' );
done_testing();
