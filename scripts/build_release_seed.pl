use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TESSERA::ReleaseSeed;
use YAML::XS ();
use JSON::PP ();
use Digest::SHA qw(sha256_hex);

my ($Catalog, $CMDB, $Governance, $Types, $Output) = @ARGV;
die "Usage: $0 CATALOG.yml CMDB.yml GOVERNANCE.yml TYPES.yml OUTPUT.json\n" if @ARGV != 5;
die "Output already exists; choose a new output path\n" if -e $Output || -e "$Output.report.json";
my %Input = (Catalog => $Catalog, CMDB => $CMDB, Governance => $Governance, Types => $Types);
my (%Data, %Sources);
for my $Name (sort keys %Input) {
    open my $FH, '<:raw', $Input{$Name} or die "Cannot read $Name: $!";
    local $/;
    my $Bytes = <$FH>;
    close $FH;
    $Data{$Name} = YAML::XS::Load($Bytes);
    die "Invalid $Name export shape\n" if ref $Data{$Name} ne ($Name =~ /\A(?:CMDB|Governance)\z/ ? 'ARRAY' : 'HASH');
    $Sources{$Name} = { File => $Input{$Name}, SHA256 => sha256_hex($Bytes) };
}
my $Result = TESSERA::ReleaseSeed->Build(%Data);
my $Seed = delete $Result->{Seed};
$Result->{Sources} = \%Sources;
$Result->{Counts} = { map { $_ => scalar @{ $Seed->{$_} } } keys %$Seed };
my $JSON = JSON::PP->new->canonical->pretty->utf8;
open my $Report, '>:raw', "$Output.report.json" or die "Cannot write report: $!";
print {$Report} $JSON->encode($Result);
close $Report or die "Cannot close report: $!";
die "Seed blocked by " . scalar(@{ $Result->{Errors} }) . " validation errors; see $Output.report.json\n" if @{ $Result->{Errors} };
open my $FH, '>:raw', $Output or die "Cannot write seed: $!";
print {$FH} $JSON->encode({ FormatVersion => 1, Sources => \%Sources, %$Seed });
close $FH or die "Cannot close seed: $!";
print "Built validated active configuration seed: $Output\n";
