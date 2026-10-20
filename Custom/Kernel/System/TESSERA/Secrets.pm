package Kernel::System::TESSERA::Secrets;

use strict;
use warnings;
use Cwd qw(abs_path);
use Fcntl qw(O_RDONLY S_ISREG);

our $ObjectManagerDisabled = 1;

# No ObjectManager dependency: Config.pm needs this before OM is available.
sub Read {
    die "TESSERA secret: expected one name\n" if @_ != 1;
    return _ReadAt( '/run/tessera-secrets', $_[0] );
}

# Private filesystem seam for tests. Production callers must use Read().
sub _ReadAt {
    my ( $Root, $Name ) = @_;
    die "TESSERA secret: invalid name\n"
        if !defined $Name || ref $Name || length($Name) > 128
        || $Name !~ /\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/;

    my $Fail = sub { die "TESSERA secret '$Name': missing, unreadable or invalid file\n" };
    my $Base = abs_path($Root);
    $Fail->() if !defined $Base || !-d $Base;
    # Follow the Kubernetes key -> ..data -> timestamp directory links, but only
    # inside the fixed mount. Open the resolved generation, not the moving link.
    my $Path = abs_path("$Base/$Name");
    $Fail->() if !defined $Path || index( $Path, "$Base/" ) != 0;
    my $Flags = O_RDONLY;
    $Flags |= Fcntl::O_NOFOLLOW() | Fcntl::O_NONBLOCK() if $^O eq 'linux';
    sysopen( my $FH, $Path, $Flags ) or $Fail->();
    binmode $FH;
    my @Stat = stat $FH;
    $Fail->() if !@Stat || !S_ISREG( $Stat[2] ) || $Stat[7] > 65536;
    my $Value = '';
    while (1) {
        my $Count = sysread( $FH, my $Chunk, 4096 );
        $Fail->() if !defined $Count;
        last if !$Count;
        $Value .= $Chunk;
        $Fail->() if length($Value) > 65536;
    }
    close $FH or $Fail->();
    # Preserve exact bytes; no chomp, whitespace or encoding transformations.
    $Fail->() if !length($Value) || index( $Value, "\0" ) >= 0;
    return $Value;
}

1;
