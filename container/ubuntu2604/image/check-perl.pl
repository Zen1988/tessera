#!/usr/bin/env perl
use strict;
use warnings;
use Module::CPANfile;
use Module::Metadata;
my $Requirements=Module::CPANfile->load('/opt/tessera/dependencies/combined.cpanfile')->prereqs->requirements_for('runtime','requires');
my @Versions;
my @Missing;
for my $Module (sort $Requirements->required_modules) {
    next if $Module eq 'perl';
    my $Meta=Module::Metadata->new_from_module($Module);
    my $Version=$Meta ? ($Meta->version($Module) // 0) : undef;
    if (!defined $Version || !$Requirements->accepts_module($Module,$Version)) { push @Missing,$Module; next }
    push @Versions,"$Module\t$Version";
}
die 'Missing/incompatible Perl dependencies: '.join(', ',@Missing)."\n" if @Missing;
open my $FH,'>','/opt/tessera/dependencies/perl-modules.tsv' or die "Cannot write dependency inventory\n";
print {$FH} join("\n",@Versions),"\n";
close $FH;
print "All declared runtime Perl requirements satisfied\n";
