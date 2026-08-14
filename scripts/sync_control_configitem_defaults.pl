use strict;
use warnings;

use JSON::PP ();
use YAML::XS ();

my ( $ExportFile, $SeedFile ) = @ARGV;
die "Usage: $0 CONFIGITEM_EXPORT.yml default_control_configitem.json\n" if !$ExportFile || !$SeedFile;

my $Export = YAML::XS::LoadFile($ExportFile);
die "ConfigItem export must contain a YAML list.\n" if ref $Export ne 'ARRAY';

my @Selected = grep {
    ref $_ eq 'HASH'
        && ( ( $_->{RoleName} || '' ) eq 'Control'
            || ( ref $_->{Class} eq 'HASH' && ( $_->{Class}{Name} || '' ) eq 'Control' ) )
} @{$Export};

die "ConfigItem export must contain the Control role and class.\n" if @Selected != 2;

open my $OutputFH, '>:raw', $SeedFile or die "Cannot write $SeedFile: $!";
print {$OutputFH} JSON::PP->new->canonical->pretty->encode(\@Selected);
close $OutputFH;

print "Synchronized the ConfigItem Control role and class.\n";
