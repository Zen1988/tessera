#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Kernel::System::TESSERA::ReleaseUpgrade;
use Kernel::System::TESSERA::ReleasePackage;
require '/usr/local/lib/tessera/package-inventory.pl';
require '/usr/local/lib/tessera/package-reconcile.pl';
my $Mode = shift @ARGV || 'check';
my $Resume = @ARGV == 1 && $ARGV[0] eq '--resume-config';
die "Invalid release-control arguments\n" if @ARGV && !$Resume;
my $OK = eval {
    open my $FH, '<:raw', '/opt/tessera/dependencies/release.json' or die;
    my $Meta = do {local $/; JSON::PP->new->decode(<$FH>)}; close $FH;
    die if $Meta->{package} ne 'TESSERA-Base';
    require Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    open my $InventoryFH, '<:raw', '/opt/tessera/dependencies/package-modules.json' or die;
    my $Inventory=JSON::PP->new->utf8->decode(do {local $/;<$InventoryFH>});close $InventoryFH;
    my $Gate = $Kernel::OM->Get('Kernel::System::TESSERA::ReleaseUpgrade');
    my %Identity = (Version => $Meta->{version}, Hash => $Meta->{package_sha256});
    my $VerifyStorage=sub {
        my $DB=$Kernel::OM->Get('Kernel::System::DB');
        die "Execution history schema is incomplete.\n" if !$DB->Prepare(SQL=>'SELECT request_data, dispatch_data FROM ztsm_async_execution WHERE 1 = 0');
        $DB->FetchrowArray();
        return 1;
    };
    if ($Mode eq 'check') { $Gate->Check(%Identity); $VerifyStorage->(); }
    elsif ($Mode eq 'upgrade') {
        die if ($ENV{TESSERA_UPGRADE_QUIESCED} || '') ne '1' || !-w '/opt/otobo/Kernel/System';
        my $Package = $Kernel::OM->Get('Kernel::System::TESSERA::ReleasePackage');
        my $Directory='/opt/tessera/upgrade-bundle';
        system('/usr/bin/python3','/usr/local/lib/tessera/check-package-bundle.py',$Directory)==0 or die "Invalid external upgrade bundle\n";
        for my $Entry (['release.json',$Meta],['package-modules.json',$Inventory]) {
            open my $BundleFH,'<:raw',"$Directory/$Entry->[0]" or die;
            my $Bundled=JSON::PP->new->utf8->decode(do {local $/;<$BundleFH>});close $BundleFH;
            die "Upgrade bundle differs from image metadata\n" if JSON::PP->new->canonical->encode($Bundled) ne JSON::PP->new->canonical->encode($Entry->[1]);
        }
        my $Reconcile=sub { ReconcilePackages($Inventory,$Kernel::OM->Get('Kernel::System::DB'),$Package,"$Directory/packages"); };
        $Gate->Run(%Identity, FromVersions => $Meta->{upgrade_from}, ResumeConfig => $Resume,
            Upgrade => $Reconcile,
            Configure => sub { $Reconcile->(); CheckInventory($Inventory,$Kernel::OM->Get('Kernel::System::DB'),$Package); $VerifyStorage->(); system('/usr/bin/python3', '/usr/local/lib/tessera/configure.py') == 0 });
    }
    else { die }
    1;
};
die "TESSERA release verification/upgrade failed; target may require the controlled upgrade Job or recovery.\n" if !$OK;
print "TESSERA release $Mode completed\n";
