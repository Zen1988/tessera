use strict;
use warnings;
use Test::More;
use File::Spec;

my $Root = File::Spec->rel2abs('.');
my $Base = File::Spec->catdir($Root, qw(Kernel Package GovernanceDB var governancedb runtime_overlay Kernel Modules));
sub LoadSource {
    my ($Name) = @_;
    open my $FH, '<', File::Spec->catfile($Base, $Name) or die $!;
    local $/;
    my $Source = <$FH>;
    $Source =~ s{^use Kernel::[^;]+;\r?\n}{}mg;
    $Source =~ s{^use parent[^;]+;\r?\n}{our \@ISA = ('Kernel::Modules::AdminDynamicFieldSet');\n}mg;
    eval $Source;
    die $@ if $@;
}
LoadSource('AdminDynamicFieldSet.pm');
LoadSource('AdminDynamicFieldGroup.pm');
{
    package NamespaceEditorOM;
    sub Get {
        my ($Self, $Name) = @_;
        die "Legacy config lookup is forbidden" if $Name ne 'Kernel::System::Namespace';
        return $Self;
    }
    sub NamespacesList {
        my ($Self, %Param) = @_;
        $Self->{Scope} = $Param{Scope};
        return @{$Self->{Namespaces}};
    }
}
local $Kernel::OM = bless {Namespaces => ['GLOBAL', 'ZRM', 'ZRM']}, 'NamespaceEditorOM';
for my $Class ('Kernel::Modules::AdminDynamicFieldSet', 'Kernel::Modules::AdminDynamicFieldGroup') {
    my $Editor = bless {}, $Class;
    is_deeply($Editor->_NamespaceListGet(), ['GLOBAL', 'ZRM'], "$Class uses current service and deduplicates namespaces");
    is($Kernel::OM->{Scope}, 'DynamicField', 'requests DynamicField scope');
    is_deeply($Editor->_NamespaceListGet(ExistingNamespace => 'OLDER'), ['GLOBAL', 'ZRM', 'OLDER'], 'existing prefix remains selectable when absent from current config');
    is($Editor->_EditNamespaceGet(ExistingName => 'ZRM-RiskAssessment'), 'ZRM', 'missing selector preserves the stored prefix');
    is($Editor->_EditNamespaceGet(ExistingName => 'ZRM-RiskAssessment', SubmittedNamespace => ''), '', 'explicit empty choice can remove the prefix');
    is($Editor->_EditNamespaceGet(ExistingName => 'RiskAssessment', SubmittedNamespace => 'ZRM'), 'ZRM', 'administrator can restore the ZRM prefix');
    is($Editor->_EditNamespaceGet(ExistingName => 'RiskAssessment'), '', 'unprefixed field stays unprefixed');
}
done_testing();
