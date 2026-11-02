#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec ();
BEGIN {
    my $Source = shift @ARGV;
    die "Installed source required\n" if !$Source || !File::Spec->file_name_is_absolute($Source);
    unshift @INC, "$Source/Custom", "$Source/Kernel/cpan-lib", $Source;
}
my ($Version, $Output) = @ARGV;
die "Package export arguments invalid\n" if ($Version || '') !~ /\A[0-9]+\.[0-9]+\.[0-9]+\z/ || !$Output;
# This exports only the installed OPM code artifact, never business records,
# source Config.pm, Secrets, users, attachments or a database dump.
open STDOUT, '>', File::Spec->devnull() or die;
open STDERR, '>', File::Spec->devnull() or die;
my $OK = eval {
    require Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $Package = $Kernel::OM->Get('Kernel::System::Package')->RepositoryGet(Name => 'TESSERA-Base', Version => $Version);
    die if !$Package;
    open my $FH, '>:encoding(UTF-8)', $Output or die;
    print {$FH} $Package or die;
    close $FH or die;
    1;
};
exit($OK ? 0 : 1);
