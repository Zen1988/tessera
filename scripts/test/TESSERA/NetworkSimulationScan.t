use strict;use warnings;use Test::More;
use lib '.', 'Custom', 'Kernel/Package/GovernanceDB';
use Kernel::System::TESSERA::CustomerNetworkSimulation;
use Kernel::System::ITSMConfigItem::ConfigItemSearch;
{
 package NativeScanCI;our @ISA=('Kernel::System::ITSMConfigItem::ConfigItemSearch');
 package NativeScanDB;
 sub Quote {$_[1]}
 sub QueryInCondition {my($S,%P)=@_;return $P{Key}.' IN ('.join(',',@{$P{Values}}).')'}
 sub Prepare {
  my($S,%P)=@_;push @{$S->{calls}},\%P;
  my @IDs=(1..1205);
  if($P{SQL}=~/MAX\(ci.id\)/){$S->{rows}=[[1205]]}
  elsif($P{SQL}=~/SELECT ci.id FROM configitem/){
   die 'native scalar refs required' if grep {ref $_ ne 'SCALAR'} @{$P{Bind}};
   my($After,$Last)=map {$$_} @{$P{Bind}}[0,1];@IDs=grep {$_>$After && $_<=$Last} (@IDs,5000);
   splice @IDs,$P{Limit} if @IDs>$P{Limit};$S->{rows}=[map {[$_]} @IDs];
  } else {
   die 'ID filter missing' if $P{SQL}!~/ci\.id IN \(([0-9,]+)\)/;
   my @Selected=split /,/,$1;
   die 'class filter missing' if $P{SQL}!~/ci\.class_id IN \(1,2\)/;
   $S->{rows}=$P{SQL}=~/COUNT\(DISTINCT/?[[scalar @Selected]]:[map {[$_,'CI'.$_]} @Selected];
  }return 1;
 }
 sub FetchrowArray {my $R=shift @{$_[0]{rows}};return $R?@$R:()}
 package NativeScanCatalog;sub ItemList {{1=>'Workload',2=>'NetworkNode'}}
 package NativeScanConfig;sub Get {1}
 package NativeScanOM;
 sub Create {bless {},'NativeScanUnused'}
 sub Get {my($S,$Name)=@_;return $S->{db} if $Name eq 'Kernel::System::DB';return $S->{ci} if $Name eq 'Kernel::System::ITSMConfigItem';return bless({},'NativeScanCatalog') if $Name eq 'Kernel::System::GeneralCatalog';return bless({},'NativeScanConfig') if $Name eq 'Kernel::Config';return bless({},'NativeScanUnused') if $Name=~/\AKernel::System::DynamicField(?:::Backend)?\z/;die "Unexpected dependency $Name"}
}
my $DB=bless {},'NativeScanDB';local $Kernel::OM=bless {db=>$DB,ci=>bless({},'NativeScanCI')},'NativeScanOM';
my @IDs;my @Sizes;
Kernel::System::TESSERA::CustomerNetworkSimulation->new()->_candidatePages(sub {push @IDs,@{$_[0]};push @Sizes,scalar @{$_[0]}});
is_deeply(\@Sizes,[500,500,205],'real native search processes bounded page sizes');
is(scalar @IDs,1205,'real native COUNT and ARRAY contracts cover every candidate');
is_deeply(\@IDs,[1..1205],'no gaps or duplicates across native search pages');
ok(!(grep {$_==5000} @IDs),'new IDs beyond captured high-water mark wait for next model');
is(scalar(grep {$_->{SQL}=~/SELECT COUNT/} @{$DB->{calls}}),3,'real native COUNT validates every page');
is(scalar(grep {$_->{SQL}=~/ORDER BY.*ci.configitem_number/} @{$DB->{calls}}),3,'supported Number ordering is used by native search');
done_testing();
