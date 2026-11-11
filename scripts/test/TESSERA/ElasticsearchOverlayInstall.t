use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Find ();
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);
my $home = abs_path(tempdir(DIR => "outputs", CLEANUP => 1));
{ package OverlayConfig; sub Get { return $main::OverlayHome } }
{ package OverlayLog; sub Log { die $_[2] } }
{ package OverlayOM; sub Get { return bless {}, $_[1] eq 'Kernel::Config' ? 'OverlayConfig' : 'OverlayLog' } }
{ package Kernel; our $OM = bless {}, 'OverlayOM' }
our $OverlayHome = $home;
open my $fh, '<', 'Kernel/System/GovernanceDB/Bootstrap.pm' or die $!;
my $source = do {local $/; <$fh>}; close $fh;
my ($method) = $source =~ /(sub _RuntimeOverlayInstall \{.*?)(?=\nsub _TicketReferenceValuesRepair)/s;
die 'Missing runtime installer' unless $method;
eval $method; die $@ if $@;
my $relative = 'var/governancedb/runtime_overlay/Kernel/System/Elasticsearch.pm';
open $fh, '<:raw', "Kernel/Package/GovernanceDB/$relative" or die $!;
my $expected = do {local $/; <$fh>}; close $fh;
make_path("$home/var/governancedb/runtime_overlay/Kernel/System");
open $fh, '>:raw', "$home/$relative" or die $!; print {$fh} $expected; close $fh;
my $self = bless {}, 'main';
for my $phase ('fresh', 'upgrade', 'reinstall') {
    if ($phase eq 'upgrade') {
        open $fh, '>:raw', "$home/Custom/Kernel/System/Elasticsearch.pm" or die $!;
        print {$fh} 'stale multitenancy module'; close $fh;
    }
    ok($self->_RuntimeOverlayInstall(), "$phase install succeeds");
    open $fh, '<:raw', "$home/Custom/Kernel/System/Elasticsearch.pm" or die $!;
    my $actual = do {local $/; <$fh>}; close $fh;
    is($actual, $expected, "$phase deploys exact compatibility module to Custom");
}
ok(!-e "$home/Kernel/System/Elasticsearch.pm", 'framework module remains untouched');
open $fh, '<', 'Kernel/Package/GovernanceDB/TESSERA-Base.sopm' or die $!;
my $sopm = do {local $/; <$fh>}; close $fh;
unlike($sopm, qr{Location="Custom/Kernel/System/Elasticsearch.pm"}, 'no duplicate file ownership claim');
like($sopm, qr{Location="var/governancedb/runtime_overlay/Kernel/System/Elasticsearch.pm"}, 'compatibility payload belongs to TESSERA overlay');
make_path("$home/var/governancedb/runtime_overlay/Kernel/System", "$home/Kernel/System");
open $fh,'<:raw','Kernel/Package/GovernanceDB/var/governancedb/runtime_overlay/Kernel/System/User.pm' or die $!;
my $userSource=do {local $/;<$fh>};close $fh;
open $fh,'>:raw',"$home/var/governancedb/runtime_overlay/Kernel/System/User.pm" or die $!;print {$fh} $userSource;close $fh;
open $fh,'<:raw','Kernel/System/User.pm' or die $!;my $nativeUser=do {local $/;<$fh>};close $fh;
open $fh,'>:raw',"$home/Kernel/System/User.pm" or die $!;print {$fh} $nativeUser;close $fh;
open $fh,'>:raw',"$home/Custom/Kernel/System/User.pm" or die $!;print {$fh} 'unknown third-party User';close $fh;
ok(!eval {$self->_RuntimeOverlayInstall();1},'unknown third-party User override is not overwritten');
open $fh,'<:raw',"$home/Custom/Kernel/System/User.pm" or die $!;my $kept=do {local $/;<$fh>};close $fh;
is($kept,'unknown third-party User','conflicting customization remains intact');
open $fh,'>:raw',"$home/Custom/Kernel/System/User.pm" or die $!;print {$fh} $nativeUser;close $fh;
ok($self->_RuntimeOverlayInstall(),'unmodified native User can receive linked-password overlay');
ok($self->_RuntimeOverlayInstall(),'known TESSERA User overlay can be reinstalled');
open $fh,'>>:raw',"$home/Kernel/System/User.pm" or die $!;print {$fh} "\n# changed framework basis";close $fh;
ok(!eval {$self->_RuntimeOverlayInstall();1},'changed framework User basis requires compatibility review');
done_testing;
