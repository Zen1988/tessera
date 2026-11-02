#!/usr/bin/env perl
# Read the installed package registry; never print Config.pm or DB exceptions.
use strict;
use warnings;
use File::Spec ();
BEGIN {
    my $Source = shift @ARGV;
    die "Installed application path required\n" if !$Source || !File::Spec->file_name_is_absolute($Source);
    unshift @INC, "$Source/Custom", "$Source/Kernel/cpan-lib", $Source;
}
open my $Output, '>&', \*STDOUT or die "Output unavailable\n";
open STDOUT, '>', File::Spec->devnull() or die "Output unavailable\n";
open STDERR, '>', File::Spec->devnull() or exit 1;
my $Version;
my $OK = eval {
    require Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $DB = $Kernel::OM->Get('Kernel::System::DB');
    my $Name = 'TESSERA-Base';
    $DB->Prepare(
        SQL => 'SELECT version FROM package_repository WHERE name = ? AND install_status = ?',
        Bind => [ \$Name, \(my $Status = 'installed') ],
    ) or die 'Package query failed';
    my @Versions;
    while (my @Row = $DB->FetchrowArray()) { push @Versions, $Row[0] }
    die 'Missing or ambiguous installed TESSERA package' if @Versions != 1;
    $Version = $Versions[0];
    die 'Unsupported package version' if $Version !~ /\A[0-9]+\.[0-9]+\.[0-9]+\z/;
    1;
};
if (!$OK) {
    print {$Output} "TESSERA package version detection failed; verify installed package registry and source-host DB access.\n";
    exit 1;
}
print {$Output} "$Version\n";
