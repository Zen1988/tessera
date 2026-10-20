use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use lib 'Custom';
use Kernel::System::TESSERA::Secrets ();

my $Root = tempdir( CLEANUP => 1 );
sub write_file {
    my ( $Path, $Value ) = @_;
    open my $FH, '>:raw', $Path or die 'fixture write failed';
    print {$FH} $Value;
    close $FH or die 'fixture close failed';
}
sub read_secret { Kernel::System::TESSERA::Secrets::_ReadAt( $Root, $_[0] ) }
write_file( "$Root/db-password", "fixture-alpha\n" );
is( read_secret('db-password'), "fixture-alpha\n", 'exact bytes, including newline' );
write_file( "$Root/db-password", 'fixture-beta' );
is( read_secret('db-password'), 'fixture-beta', 'rereads each call' );
for my $Name ( undef, '', '../db-password', '/etc/passwd', 'a/b', 'a\\b', '..data', "x\n", "x\0", 'a.b', 'a' x 129, [] ) {
    my $OK = eval { read_secret($Name); 1 };
    ok( !$OK && $@ eq "TESSERA secret: invalid name\n", 'reject malformed name without echoing input' );
}
for my $Case ( ['empty',''], ['nul',"fixture\0private"], ['large', 'x' x 65537] ) {
    write_file( "$Root/$Case->[0]", $Case->[1] );
    eval { read_secret( $Case->[0] ) };
    like( $@, qr/missing, unreadable or invalid file/, 'invalid content rejected without value' );
    unlike( $@, qr/private|xxxxx/, 'error contains no file content' );
}
eval { read_secret('missing') };
like( $@, qr/'missing': missing, unreadable or invalid file/, 'mandatory missing secret fails' );
make_path("$Root/directory");
eval { read_secret('directory') };
like( $@, qr/invalid file/, 'directory rejected' );
eval { Kernel::System::TESSERA::Secrets::Read('db-password', '/etc') };
like( $@, qr/expected one name/, 'public API cannot override root' );

SKIP: {
    skip 'Linux projection and permission checks', 7 if $^O ne 'linux';
    make_path( "$Root/..one", "$Root/..two" );
    write_file( "$Root/..one/key", 'fixture-one' );
    write_file( "$Root/..two/key", 'fixture-two' );
    symlink '..one', "$Root/..data" or die 'fixture symlink failed';
    symlink '..data/key', "$Root/projected" or die 'fixture symlink failed';
    is( read_secret('projected'), 'fixture-one', 'Kubernetes projection links supported' );
    symlink '..two', "$Root/..next" or die 'fixture symlink failed';
    rename "$Root/..next", "$Root/..data" or die 'fixture atomic rename failed';
    is( read_secret('projected'), 'fixture-two', 'atomic generation rotation read without restart' );
    my $Outside = tempdir( CLEANUP => 1 );
    write_file( "$Outside/key", 'outside-private' );
    symlink "$Outside/key", "$Root/escape" or die 'fixture symlink failed';
    eval { read_secret('escape') };
    like( $@, qr/invalid file/, 'external symlink denied' );
    unlike( $@, qr/outside-private/, 'external data not disclosed' );
    unlink "$Root/..two/key";
    eval { read_secret('projected') };
    like( $@, qr/invalid file/, 'removed generation fails safely' );
    SKIP: {
        skip 'run as non-root for unreadability checks', 2 if $> == 0;
        write_file( "$Root/denied", 'permission-private' );
        chmod 0000, "$Root/denied";
        eval { read_secret('denied') };
        like( $@, qr/invalid file/, 'unreadable secret fails' );
        unlike( $@, qr/permission-private/, 'permission error contains no secret' );
        chmod 0600, "$Root/denied";
    }
}
done_testing();
