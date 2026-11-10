package Kernel::System::TESSERA::ReleasePackage;
use strict;
use warnings;
use parent qw(Kernel::System::Package);
our @ObjectDependencies = @Kernel::System::Package::ObjectDependencies;
# Preserve native package ordering/version filtering/file/config/hook semantics,
# but stop instead of publishing success when native helpers merely log failure.
sub _Code {
    my ($Self, %P) = @_;
    die "Package code hook failed.\n" if !$Self->SUPER::_Code(%P);
    return 1;
}
sub _ConfigurationDeploy {
    my ($Self, %P) = @_;
    die "Package configuration deployment failed.\n" if !$Self->SUPER::_ConfigurationDeploy(%P);
    return 1;
}
sub _FileInstall {
    my ($Self, %P) = @_;
    die "Package file installation failed.\n" if !$Self->SUPER::_FileInstall(%P);
    return 1;
}
sub _Database {
    my ($Self, %P) = @_;
    my $DB = $Kernel::OM->Get('Kernel::System::DB');
    die "Invalid package database program.\n" if ref $P{Database} ne 'ARRAY';
    my @SQL = $DB->SQLProcessor(Database => $P{Database});
    for my $SQL (@SQL, $DB->SQLProcessorPost()) {
        die "Package database upgrade failed.\n" if !$DB->Do(SQL => $SQL);
    }
    return 1;
}
1;
