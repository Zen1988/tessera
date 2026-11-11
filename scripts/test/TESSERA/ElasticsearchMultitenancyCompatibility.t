use strict;
use warnings;
use Test::More;
{ package FakeGroups;
  sub PermissionUserGroupGet { return (7 => 'operators') }
  sub GroupList { return (7 => 'operators', 8 => 'admins') }
}
{ package FakeConfig;
  sub Get { return $_[0]->{management} }
}
{ package FakeOM;
  sub Get { return bless {}, 'FakeGroups' }
}
{ package Kernel; our $OM = bless {}, 'FakeOM' }
open my $SourceFH, '<', 'Custom/Kernel/System/Elasticsearch.pm' or die $!;
my $ModuleSource=do {local $/;<$SourceFH>};close $SourceFH;
my ($FilterBlock)=$ModuleSource=~/(# Rother OSS \/ ITSMConfigItemMultitenancy.*?)(?=# EO ITSMConfigItemMultitenancy)/s;
die 'Missing preserved multitenancy filter' if !defined $FilterBlock;
sub filter_for {
  my ($management) = @_;
  my $ConfigObject = bless {management => $management}, 'FakeConfig';
  my %Param = (UserID => 2);
  my $ClassList = {3 => 'Server'};
  my @Filters;
  eval $FilterBlock; die $@ if $@;

  return $Filters[0];
}
for my $case ([undef,[7]], ['operators',[7,8]], ['other',[7]]) {
  my $filter = filter_for($case->[0]);
  is_deeply($filter->{bool}{filter}[0]{terms}{ClassID},[3],'class scope retained');
  my $group_filter=$filter->{bool}{filter}[1]{bool};
  is_deeply([sort {$a <=> $b} @{$group_filter->{should}[0]{terms}{GroupID}}],$case->[1],'group scope retained');
  is($group_filter->{minimum_should_match},1,'group branch required');
  is($group_filter->{should}[1]{bool}{must_not}{exists}{field},'GroupID','unrestricted-class branch retained');
}
done_testing;
