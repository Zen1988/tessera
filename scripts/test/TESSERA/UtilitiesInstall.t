use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Find ();
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
our $UtilityHome=abs_path(tempdir(DIR=>'outputs',CLEANUP=>1));
{package UtilityInstallConfig;sub Get {$main::UtilityHome}}
{package UtilityInstallLog;sub Log {die $_[2]}}
{package UtilityInstallOM;sub Get {bless {},$_[1] eq 'Kernel::Config'?'UtilityInstallConfig':'UtilityInstallLog'}}
{package Kernel;our $OM=bless {},'UtilityInstallOM'}
open my $F,'<','Kernel/System/GovernanceDB/Bootstrap.pm' or die $!;
my $Source=do {local $/;<$F>};close $F;
my ($Method)=$Source=~/(sub _RuntimeOverlayInstall \{.*?)(?=\nsub _TicketReferenceValuesRepair)/s;
die 'Missing native overlay installer' if !$Method;eval $Method;die $@ if $@;
my @Paths=('Kernel/Output/HTML/CustomerDashboard/TileToolBox.pm','Kernel/Output/HTML/Templates/Standard/CustomerNavigationBar.tt');
my %Expected;
for my $Path (@Paths) {
    open $F,'<:raw','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/'.$Path or die $!;
    $Expected{$Path}=do {local $/;<$F>};close $F;
    my $Target="$UtilityHome/var/governancedb/runtime_overlay/$Path";my $Dir=$Target;$Dir=~s{/[^/]+$}{};make_path($Dir);
    open $F,'>:raw',$Target or die $!;print $F $Expected{$Path};close $F;
}
my $Self=bless {},'main';
for my $Phase ('fresh','upgrade','reinstall') {
    if ($Phase eq 'upgrade') {for my $Path (@Paths) {open $F,'>:raw',"$UtilityHome/Custom/$Path" or die $!;print $F 'old TESSERA customization';close $F}}
    ok($Self->_RuntimeOverlayInstall(),"$Phase actual installer succeeds");
    for my $Path (@Paths) {
        open $F,'<:raw',"$UtilityHome/Custom/$Path" or die $!;my $Actual=do {local $/;<$F>};close $F;
        is($Actual,$Expected{$Path},"$Phase deploys exact $Path into Custom");
        ok(!-e "$UtilityHome/$Path",'native source remains untouched');
    }
}
open $F,'<','Kernel/Package/GovernanceDB/TESSERA-Base.sopm' or die $!;my $SOPM=do {local $/;<$F>};close $F;
for my $Path (@Paths) {like($SOPM,qr{Location="var/governancedb/runtime_overlay/\Q$Path\E"},'package owns overlay');unlike($SOPM,qr{Location="(?:Custom/)?\Q$Path\E"},'no native/custom duplicate ownership')}
done_testing();
