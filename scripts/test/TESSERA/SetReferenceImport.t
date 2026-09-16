use strict;
use warnings;
use Test::More;
use lib 'Kernel/Package/GovernanceDB', '.', 'Kernel/cpan-lib';
use Kernel::System::GovernanceObject::Document;

{
    package Local::SetDocument;
    use parent 'Kernel::System::GovernanceObject::Document';
    sub _IncludedDynamicFieldsGet {
        return {
            'ZState-Book' => { FieldType => 'GovernanceObject', Config => {} },
            'ZState-State' => { FieldType => 'GeneralCatalog', Config => {} },
            'ZState-Seq' => { FieldType => 'Text', Config => {} },
        };
    }
    # Isolate storage shape from name resolution, which runs before this step.
    sub _ValueFromDocument { my ($Self, %Param) = @_; return $Param{Value}; }
}

my $Document = Local::SetDocument->new();
my $Rows = $Document->_SetValueFromDocument(
    Value => [
        { 'ZState-Seq' => '1', 'ZState-State' => [10] },
        { 'ZState-Seq' => '2', 'ZState-State' => [11], 'ZState-Book' => '' },
        { 'ZState-Seq' => '3', 'ZState-State' => 12, 'ZState-Book' => 42 },
        { 'ZState-Seq' => '4', 'ZState-Book' => [43] },
    ],
);
is_deeply($Rows->[0]{'ZState-Book'}, [], 'omitted Book clears with an empty reference array');
is_deeply($Rows->[1]{'ZState-Book'}, [], 'explicit blank Book uses an empty reference array');
is_deeply($Rows->[2]{'ZState-Book'}, [42], 'scalar resolved reference becomes a selection array');
is_deeply($Rows->[3]{'ZState-Book'}, [43], 'existing selection array is preserved');
is_deeply($Rows->[2]{'ZState-State'}, [12], 'catalog scalar uses the same BaseEntity shape');
is_deeply($Rows->[3]{'ZState-State'}, [], 'omitted catalog child clears safely');
is($Rows->[0]{'ZState-Seq'}, '1', 'text child retains its scalar shape');
my @Flattened = map { $_->[0] } map { $_->{'ZState-Book'} } @$Rows;
is_deeply(\@Flattened, [undef, undef, 42, 43], 'BaseEntity Set flattening preserves empty row positions without crashing');
done_testing();
