use strict;
use warnings;
use Test::More;
use Template;
use Cwd qw(abs_path);

my $Root = $ENV{TESSERA_TEST_PACKAGE_ROOT} || 'Kernel/Package/GovernanceDB';
sub readfile {open my $F, '<:encoding(UTF-8)', $_[0] or die $!; return do {local $/; <$F>}}

# Exercise the actual native missing-field implementation, rather than assuming
# an undef response in the installer fixture again.
my $Native = readfile('Kernel/System/DynamicField.pm');
my ($Get) = $Native =~ /(sub DynamicFieldGet \{.*?)(?=\n=head2 DynamicFieldUpdate)/s;
eval "package NativeFieldLookup199; $Get; 1" or die $@;
{package MissingField199;
 sub Get {return}
 sub Prepare {1}
 sub FetchrowArray {return}
}
{package MissingFieldOM199;
 sub Get {return bless {}, 'MissingField199'}
}
local $Kernel::OM = bless {}, 'MissingFieldOM199';
my $Lookup = bless {}, 'NativeFieldLookup199';
my $Missing = $Lookup->DynamicFieldGet(Name => 'FAQApplication');
is(ref $Missing, 'HASH', 'native missing-field lookup returns hash reference');
is(scalar keys %$Missing, 0, 'native missing-field lookup returns empty hash');

my $Bootstrap = readfile("$Root/Kernel/System/GovernanceDB/Bootstrap.pm");
my ($Methods) = $Bootstrap =~ /(sub _FAQApplicationFieldEnsure.*?)(?=sub _CustomerUserPreferenceDynamicFieldsEnsure)/s;
eval "package Bootstrap199; $Methods; 1" or die $@;
{package FieldInstall199;
 sub DynamicFieldGet {my($S,%P)=@_;return $S->{Field} && ($S->{Field}{Name} || '') eq $P{Name} ? $S->{Field} : {}}
 sub ItemList {{32=>'Application'}}
 sub DynamicFieldAdd {my($S,%P)=@_;$S->{Field}={%P, ID=>77};$S->{Added}++;return 77}
 sub EventHandlerTransaction {1}
 sub SettingGet {my($S,%P)=@_;return (IsValid=>1,EffectiveValue=>{Module=>$P{Name} =~ /ObjectType/ ? 'Kernel::System::DynamicField::ObjectType::FAQ' : 'Kernel::System::DynamicField::Driver::GovernanceObject'})}
}
{package InstallOM199;
 sub Get {$_[0]{Fixture}}
}
my $F = bless {Added=>0},'FieldInstall199';
$Kernel::OM = bless {Fixture=>$F},'InstallOM199';
my $B = bless {}, 'Bootstrap199';
ok($B->_FAQApplicationFieldEnsure(),'missing field is created using native empty-hash semantics');
is($F->{Added},1,'field added exactly once');
is($F->{Field}{ObjectType},'FAQ','field belongs to FAQ');
is($F->{Field}{FieldType},'GovernanceObject','field is a governance reference');
is_deeply($F->{Field}{Config}{ClassIDs},[32],'Application class resolved from target catalog');
$F->{Field}{Config}{AdminOwned}='keep';
ok($B->_FAQApplicationFieldEnsure(),'reinstall accepts existing compatible field');
is($F->{Added},1,'reinstall does not duplicate field');
is($F->{Field}{Config}{AdminOwned},'keep','existing administrator configuration preserved');
$F->{Field}{FieldType}='Text';
eval {$B->_FAQApplicationFieldEnsure()};
like($@,qr/must be an FAQ GovernanceObject reference/,'genuine type conflict still stops installation');
is($F->{Field}{FieldType},'Text','genuine conflicting field is never overwritten');

for my $Template (qw(CustomerDashboard CustomerTicketOverview)) {
    my $Source = readfile("$Root/var/governancedb/runtime_overlay/Kernel/Output/HTML/Templates/Standard/$Template.tt");
    my ($Fragment) = $Source =~ /(<div id="oooSearchBox">.*?<\/form>)/s;
    ok($Fragment,"$Template native search box found");
    for my $Mode ([1,1,'Search'],[0,1,'Search'],[1,0,'Search']) {
        my $Out='';
        Template->new()->process(\$Fragment,{
            Config=>sub {$_[0] eq 'TESSERA::WorkplaceSearch' ? $Mode->[0] : $Mode->[1]},
            Env=>sub {''},Translate=>sub {$_[0]},
        },\$Out) or die Template->error();
        like($Out,qr/aria-label="Search tickets, CMDB, FAQ and people"/,"$Template accessible label describes complete intended scope");
        like($Out,qr/id='oooSearchLabel'>\Q$Mode->[2]\E</,"$Template visible label has no ticket-only fallback");
        unlike($Out,qr/Ticket Search/,"$Template never restores the old label");
        if ($Mode->[0] && $Mode->[1]) {like($Out,qr/data-workplace-search="1"/,'active Workplace form is marked for unified Enter handling')}
        else {unlike($Out,qr/data-workplace-search=/,'native ticket fallback retains form behavior')}
    }
}
my $SOPM = readfile("$Root/TESSERA-Base.sopm");
{package PackageHookFixture199;
 sub Ensure {1}
 sub InstallDefaults {$_[0]{BootstrapCalls}++;return $_[0]{BootstrapResult}}
 sub StorageEnsure {$_[0]{StorageCalls}++;return 1}
 sub ProviderEnsure {1}
}
{package PackageHookOM199;
 sub Get {$_[0]{Fixture}}
 sub ObjectsDiscard {my($S,%P)=@_;$S->{Discard}=\%P;return 1}
}
for my $Phase (qw(Install Upgrade Reinstall)) {
    my ($Code) = $SOPM =~ /<Code$Phase Type="post"><!\[CDATA\[(.*?)\]\]><\/Code$Phase>/s;
    like($Code,qr/die 'TESSERA governance bootstrap failed\.' if !\$BootstrapObject->InstallDefaults\(\)/,"$Phase reports bootstrap failure instead of silently continuing");
    my $Hook=bless {BootstrapResult=>1},'PackageHookFixture199';
    $Kernel::OM=bless {Fixture=>$Hook},'PackageHookOM199';
    ok(eval($Code . "\n1;"),"$Phase actual post-hook succeeds with successful bootstrap") or diag $@;
    is_deeply($Kernel::OM->{Discard},{Objects=>['Kernel::System::GovernanceDB::Bootstrap'],ForcePackageReload=>1},"$Phase reloads corrected bootstrap in persistent Package Manager worker");
    $Hook->{BootstrapResult}=0;$Hook->{StorageCalls}=0;
    eval($Code);
    like($@,qr/TESSERA governance bootstrap failed/,"$Phase actual post-hook fails on bootstrap failure");
    is($Hook->{StorageCalls},0,"$Phase does not continue after bootstrap failure");
}
done_testing;
