#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Kernel::System::TESSERA::ReleaseUpgrade;
use Kernel::System::TESSERA::ReleasePackage;
my $Mode = shift @ARGV || 'check';
my $Resume = @ARGV == 1 && $ARGV[0] eq '--resume-config';
die "Invalid release-control arguments\n" if @ARGV && !$Resume;
my $OK = eval {
    open my $FH, '<:raw', '/opt/tessera/dependencies/release.json' or die;
    my $Meta = do {local $/; JSON::PP->new->decode(<$FH>)}; close $FH;
    die if $Meta->{package} ne 'TESSERA-Base';
    open $FH, '<:raw', '/opt/tessera/dependencies/package.opm' or die;
    my $Bytes = do {local $/; <$FH>}; close $FH;
    die if sha256_hex($Bytes) ne $Meta->{package_sha256};
    require Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
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
        require Encode;
        my $String = Encode::decode('UTF-8', $Bytes, Encode::FB_CROAK());
        my %Structure = $Package->PackageParse(String => $String);
        die if ($Structure{Name}{Content} || '') ne 'TESSERA-Base' || ($Structure{Version}{Content} || '') ne $Meta->{version};
        $Gate->Run(%Identity, FromVersions => $Meta->{upgrade_from}, ResumeConfig => $Resume,
            Upgrade => sub { $Package->PackageUpgrade(String => $String) },
            Configure => sub { $VerifyStorage->(); system('/usr/bin/python3', '/usr/local/lib/tessera/configure.py') == 0 });
    }
    else { die }
    1;
};
die "TESSERA release verification/upgrade failed; target may require the controlled upgrade Job or recovery.\n" if !$OK;
print "TESSERA release $Mode completed\n";
