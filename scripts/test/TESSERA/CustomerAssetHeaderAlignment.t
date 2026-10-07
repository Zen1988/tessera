use strict;
use warnings;
use Test::More;
sub Translatable {$_[0]}
sub IsHashRefWithData {ref $_[0] eq 'HASH' && keys %{$_[0]}}
{
 package HeaderLayout;
 sub Translate {$_[1]}
 sub Block {my($S,%P)=@_;push @{$S->{Blocks}},\%P;}
 package HeaderView;
 sub _InitialColumnFilter {''}
}
open my $FH,'<','Kernel/Package/GovernanceDB/Kernel/Output/HTML/ITSMConfigItem/ZTSMCustomerOverviewSmall.pm' or die $!;
my $Source=do {local $/;<$FH>};
my ($Header)=$Source =~ /# show special config item columns, if needed\s*(.*?)\s*\$LayoutObject->Block\( Name => 'TableBody' \);/s;
# Read existing template block names to detect headers silently discarded by Layout.
open my $TF,'<','Kernel/Package/GovernanceDB/Kernel/Output/HTML/Templates/Standard/ZTSMCustomerITSMConfigItemOverviewSmall.tt' or die $!;
my $Template=do {local $/;<$TF>};
my %Available=map {$_=>1} $Template =~ /RenderBlockStart\("([^"]+)"\)/g;
for my $Broken (1,0) {
 my $Body=$Header;
 $Body =~ s/ && \$Column ne 'Name'// if $Broken;
 my @Col=qw(Name ZTSMAssetType ZTSMAssetTag ZTSMProductModel);
 my %Param=(SortBy=>'Age',OrderBy=>'Up',GetColumnFilter=>{});
 my %SpecialColumns=(Name=>1,Number=>1);
 my $Self=bless {ValidSortableColumns=>{Name=>1},ValidFiltrableColumns=>{map {$_=>1} @Col}},'HeaderView';
 my $LayoutObject=bless {Blocks=>[]},'HeaderLayout';$LayoutObject->{LanguageObject}=$LayoutObject;
 my $ColumnValues={};my $DynamicFieldBackendObject;my $CSS='';
 eval $Body; die $@ if $@;
 my @Headers=grep {$_->{Name} =~ /\AOverviewNavBarPage(?:Name|Column)\z/} @{$LayoutObject->{Blocks}};
 my @Rendered=map {$_->{Data}{ColumnName}} grep {$Available{$_->{Name}}} @Headers;
 if($Broken) {
  is_deeply(\@Rendered,[@Col[1..$#Col]],'old shared special-column path omits Name header and shifts labels');
 }else {
  is_deeply(\@Rendered,\@Col,'all header cells match linked Name and remaining row columns in order');
  ok(!grep({!$Available{$_->{Name}}} @Headers),'every generated header block exists in the owned template');
  my ($NameControls)=grep {$_->{Name} eq 'OverviewNavBarPageColumnFilterLink' && $_->{Data}{ColumnName} eq 'Name'} @{$LayoutObject->{Blocks}};
  ok($NameControls,'Name retains generic filter and sort controls');
 }
}
done_testing();
