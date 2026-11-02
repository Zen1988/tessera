#!/usr/bin/env perl
use strict;
use warnings;
use Module::CPANfile;
use Module::Metadata;
use JSON::PP ();
use Config ();
my $CheckOnly=@ARGV==1 && $ARGV[0] eq '--check-only';
die "Use --check-only or no arguments\n" if @ARGV && !$CheckOnly;
my $Requirements=Module::CPANfile->load('/opt/tessera/dependencies/combined.cpanfile')->prereqs->requirements_for('runtime','requires');
my @Versions;
my @Missing;
for my $Module (sort $Requirements->required_modules) {
    if ($Module eq 'perl') {
        push @Missing,'perl' if !$Requirements->accepts_module('perl',"$^V");
        push @Versions,"perl\t$^V";next;
    }
    my $Meta=Module::Metadata->new_from_module($Module);
    my $Version=$Meta ? ($Meta->version($Module) // 0) : undef;
    if (!defined $Version || !$Requirements->accepts_module($Module,$Version)) { push @Missing,$Module; next }
    push @Versions,"$Module\t$Version";
}
die 'Missing/incompatible Perl dependencies: '.join(', ',@Missing)."\n" if @Missing;
if (!$CheckOnly) {
    open my $FH,'>','/opt/tessera/dependencies/perl-modules.tsv' or die "Cannot write dependency inventory\n";
    print {$FH} join("\n",@Versions),"\n";close $FH;
    open my $Runtime,'>','/opt/tessera/dependencies/perl-runtime.json' or die "Cannot write Perl runtime inventory\n";
    print {$Runtime} JSON::PP->new->canonical->encode({executable=>$^X,version=>"$^V",archname=>$Config::Config{archname},
        useithreads=>$Config::Config{useithreads},usemultiplicity=>$Config::Config{usemultiplicity},policy=>'target-os-system-perl'}),"\n";
    close $Runtime;
}
print "All declared runtime Perl requirements satisfied\n";
