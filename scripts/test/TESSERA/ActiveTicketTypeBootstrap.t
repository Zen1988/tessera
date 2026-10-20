use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::GovernanceDB::Bootstrap;

{
    package Local::TypeSeedOM;
    sub Get { $_[0] }
    sub FileRead {
        my ($S, %P) = @_;
        open my $F, '<:raw', $P{Location} or return;
        local $/; my $Content = <$F>; close $F;
        return \$Content;
    }
    sub Decode { my ($S,%P)=@_; JSON::PP::decode_json($P{Data}) }
    sub ValidLookup { 42 }
    sub TypeLookup { my ($S,%P)=@_; $S->{Existing}{$P{Type}} }
    sub TypeAdd {
        my ($S,%P)=@_;
        push @{$S->{Added}}, \%P;
        return if $S->{Fail};
        return $S->{Existing}{$P{Name}} = 100 + @{$S->{Added}};
    }
}
{
    package Local::TypeSeedConfig;
    our @ISA = ('Local::TypeSeedOM');
    sub Get { $_[1] eq 'Home' ? 'Kernel/Package/GovernanceDB' : $_[0] }
}
{
    package Local::TypeSeedRoot;
    sub Get { $_[1] eq 'Kernel::Config' ? bless({},'Local::TypeSeedConfig') : $_[0]{Backend} }
}
my $Backend = bless {Existing=>{Task=>9, 'Change::Major'=>10}}, 'Local::TypeSeedOM';
local $Kernel::OM = bless {Backend=>$Backend}, 'Local::TypeSeedRoot';
my $B = bless {}, 'Kernel::System::GovernanceDB::Bootstrap';
ok($B->_TicketTypesEnsure(), 'actual ensure succeeds');
my %Added = map {$_->{Name}=>$_} @{$Backend->{Added}};
ok(!$Added{Task}, 'existing type left unchanged, including administrator validity');
ok(!$Added{'Change::Major'} && !$Added{'Incident::Major'} && !$Added{IncidentAssessment}, 'inactive exported types never created');
ok($Added{Automation} && $Added{Clarification} && $Added{Confirmation} && $Added{Resolution}, 'current active types replace stale hardcoded list');
is($Added{Automation}{ValidID},42,'validity resolved through native lookup');
my $Count = @{$Backend->{Added}};
$B->_TicketTypesEnsure();
is(scalar @{$Backend->{Added}},$Count,'repeat does not duplicate records');
$Backend->{Existing} = {};
$Backend->{Fail} = 1;
eval {$B->_TicketTypesEnsure()};
like($@,qr/Cannot create required ticket type/,'creation failure stops installation');
done_testing;
