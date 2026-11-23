use strict;
use warnings;
use Test::More;
use lib '.', 'Kernel/cpan-lib';
use Kernel::System::VariableCheck qw(:all);

sub Source {
    open my $FH, '<', $_[0] or die $!;
    local $/;
    return <$FH>;
}
sub LoadMethods {
    my ($Source, $Class, @Methods) = @_;
    for my $Method (@Methods) {
        my ($Code) = $Source =~ /(^sub \Q$Method\E \{.*?)(?=^sub |^1;|\z)/ms;
        die "Missing $Method" if !$Code;
        eval "package $Class; use Kernel::System::VariableCheck qw(:all); $Code";
        die $@ if $@;
    }
}
my $Database = Source('var/governancedb/runtime_overlay/Kernel/System/DynamicField/Driver/BaseDatabase.pm');
LoadMethods($Database, 'StableDatabase', qw(ValueGet ValueSet _TESSERADatabaseDisplayCacheInvalidate));
{
    package StableMockOM;
    sub Get { my ($S,$N)=@_; return $N eq 'Kernel::System::Cache' ? $S->{Cache} : $S->{Value} }
    package StableValue;
    sub ValueSet {my ($S,%P)=@_;$S->{Written}=\%P;return !$S->{Fail}}
    sub ValueGet {$_[0]{Written}{Value}}
    package StableCache;
    sub Delete {my ($S,%P)=@_;push @{$S->{Deleted}},$P{Key};1}
    package StableDatabase;
    sub ValueStructureToDB {
        my ($S,%P)=@_;
        $S->{Structure}=\%P;
        return [map {+{ValueText=>$_}} ref $P{Value} eq 'ARRAY' ? @{$P{Value}} : $P{Value}];
    }
}
my $Value = bless {}, 'StableValue';
my $Cache = bless {Deleted=>[]}, 'StableCache';
local $Kernel::OM = bless {Value=>$Value, Cache=>$Cache}, 'StableMockOM';
my $Driver = bless {}, 'StableDatabase';
my $Config = {ID=>17,Config=>{Multiselect=>1}};
my $Rows = [['one','two'],[],['three']];
ok($Driver->ValueSet(DynamicFieldConfig=>$Config,ObjectID=>1,UserID=>1,Set=>1,Value=>$Rows),
    'stable multiselect Set write succeeds');
is_deeply($Value->{Written}{Value},[
    {IndexSet=>0,ValueText=>'one'},{IndexSet=>0,ValueText=>'two'},{IndexSet=>2,ValueText=>'three'}
], 'stable storage retains Set row indices and empty positions');
is_deeply($Rows,[['one','two'],[],['three']], 'caller values are not modified');
is_deeply($Driver->ValueGet(DynamicFieldConfig=>$Config,ObjectID=>1,Set=>1),
    [['one','two'],undef,['three']], 'Set read restores row positions');
is_deeply($Cache->{Deleted},[
    '17-AgentInterface-one','17-CustomerInterface-one',
    '17-AgentInterface-two','17-CustomerInterface-two',
    '17-AgentInterface-three','17-CustomerInterface-three',
], 'extension invalidation uses real identifiers and both interfaces');
$Cache->{Deleted}=[];
$Value->{Fail}=1;
ok(!$Driver->ValueSet(DynamicFieldConfig=>$Config,ObjectID=>1,UserID=>1,Value=>['failed']),
    'storage failure propagates');
is_deeply($Cache->{Deleted},[], 'failed write does not invalidate display cache');
delete $Value->{Fail};
ok($Driver->ValueSet(DynamicFieldConfig=>{ID=>18,Config=>{}},ObjectID=>1,UserID=>1,Set=>1,Value=>['single']),
    'single-valued database field still stores via native conversion');
ok($Driver->{Structure}{Set}, 'native conversion receives Set flag');

my $Generic = Source('var/governancedb/runtime_overlay/Kernel/System/GenericAgent.pm');
LoadMethods($Generic,'StableGeneric',qw(ImportGenericAgents _TESSERATicketSearchArraySanitize));
{
    package StableGeneric;
    sub JobList {()}
    sub JobAdd {my ($S,%P)=@_;push @{$S->{Added}},$P{Data};1}
    package StableLookup;
    sub StateLookup {my ($S,%P)=@_;return $P{State} eq 'open' ? 2 : undef}
    sub Log {my ($S,%P)=@_;push @{$S->{Logs}},\%P;1}
    package StableGenericOM;
    sub Get {$_[0]{Lookup}}
}
my $Lookup=bless {}, 'StableLookup';
$Kernel::OM=bless {Lookup=>$Lookup},'StableGenericOM';
my $GenericDriver=bless {Added=>[]},'StableGeneric';
ok(!$GenericDriver->ImportGenericAgents(
    GenericAgents=>{
        Good=>{Name=>'Good',States=>['open']},
        Bad=>{Name=>'Bad',States=>['absent']},
    },UserID=>1), 'unknown named state causes overall import failure');
is(scalar @{$GenericDriver->{Added}},1,'valid job imported; unsafe widened job omitted');
is_deeply($GenericDriver->{Added}[0]{StateIDs},[2],'valid name resolves to native ID');
ok(!exists $GenericDriver->{Added}[0]{States},'transfer names removed from stored search');
my $Job={StateIDs=>'unsafe scalar',QueueIDs=>[1,'',undef],Types=>[]};
$GenericDriver->_TESSERATicketSearchArraySanitize(Job=>$Job,DynamicFieldSearchParameters=>{},JobName=>'test');
ok(!exists $Job->{StateIDs},'TESSERA scalar search guard preserved');
is_deeply($Job->{QueueIDs},[1],'TESSERA guard retains valid array members');
ok(!exists $Job->{Types},'TESSERA guard removes empty search arrays');
unlike($Generic,qr/require Kernel::Autoload::GenericAgentImportExport/,
    'merged GenericAgent no longer requires obsolete extension');
done_testing();
