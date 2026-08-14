use strict;
use warnings;

use JSON::PP ();
use YAML::XS ();

my ( $ExportFile, $SeedFile ) = @ARGV;
die "Usage: $0 GOVERNANCE_EXPORT.yml default_classes.json\n" if !$ExportFile || !$SeedFile;

my $Export = YAML::XS::LoadFile($ExportFile);
die "Governance export must contain a YAML list.\n" if ref $Export ne 'ARRAY';

open my $SeedFH, '<:raw', $SeedFile or die "Cannot read $SeedFile: $!";
local $/;
my $Seed = JSON::PP::decode_json(<$SeedFH>);
close $SeedFH;

my ( @Classes, @Roles );
for my $Item ( @{$Export} ) {
    next if ref $Item ne 'HASH';
    if ( ref $Item->{Class} eq 'HASH' && $Item->{Class}{Name} ) {
        my %Class = %{ $Item->{Class} };
        $Class{Definition}    = $Item->{Definition} // '';
        $Class{DynamicFields} = $Item->{DynamicFields} || {};
        $Class{Category}      = $Class{Categories}[0] if ref $Class{Categories} eq 'ARRAY' && @{ $Class{Categories} };
        push @Classes, \%Class;
    }
    elsif ( $Item->{RoleName} && defined $Item->{Definition} ) {
        push @Roles, { Name => $Item->{RoleName}, Definition => $Item->{Definition} };
    }
}

die "Governance export contains no classes.\n" if !@Classes;
die "Governance export contains no roles.\n" if !@Roles;

$Seed->{Classes} = [ sort { $a->{Name} cmp $b->{Name} } @Classes ];
$Seed->{Roles}   = [ sort { $a->{Name} cmp $b->{Name} } @Roles ];
my %Category = map { $_ => 1 } @{ $Seed->{Categories} || [] };
$Category{$_} = 1 for map { @{ $_->{Categories} || [] } } @Classes;
$Seed->{Categories} = [ sort keys %Category ];

open my $OutputFH, '>:raw', $SeedFile or die "Cannot write $SeedFile: $!";
print {$OutputFH} JSON::PP->new->canonical->pretty->encode($Seed);
close $OutputFH;

print "Synchronized ", scalar(@Classes), " classes and ", scalar(@Roles), " roles.\n";
