#!/usr/bin/env perl
package TESSERA::MergeCPANfiles;
use strict;
use warnings;
use CPAN::Meta::Requirements;

sub Merge {
    my (@Manifests)=@_;my %Combined;
    for my $Manifest (@Manifests) {
        for my $Phase (keys %$Manifest) {
            next if $Phase eq 'develop';
            die "Unsupported dependency phase\n" if $Phase!~/\A(?:runtime|configure|build|test)\z/;
            for my $Relation (keys %{$Manifest->{$Phase}}) {
                die "Use required dependencies only in toolkit cpanfiles\n" if $Relation ne 'requires' && keys %{$Manifest->{$Phase}{$Relation}};
            }
            my $R=$Combined{$Phase} ||= CPAN::Meta::Requirements->new();
            for my $Module (keys %{$Manifest->{$Phase}{requires} || {}}) {
                die "Invalid Perl dependency name\n" if $Module!~/\A[A-Za-z][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)*\z/;
                $R->add_string_requirement($Module,$Manifest->{$Phase}{requires}{$Module});
            }
        }
    }
    my $Output="# Merged core, installed OPM and integration requirements; all constraints retained.\n";
    for my $Phase (sort keys %Combined) {
        my $R=$Combined{$Phase};$Output.="on '$Phase' => sub {\n" if $Phase ne 'runtime';
        for my $Module (sort $R->required_modules) {
            my $V=$R->requirements_for_module($Module);die "Unsafe version requirement\n" if $V=~/['\\\r\n]/;
            $Output.="requires '$Module', '$V';\n";
        }
        $Output.="};\n" if $Phase ne 'runtime';
    }
    return $Output;
}
unless (caller) {
    require Module::CPANfile;
    die "cpanfile inputs required\n" if !@ARGV;
    my @Manifests=map {Module::CPANfile->load($_)->prereqs->as_string_hash} @ARGV;
    print Merge(@Manifests);
}
1;
