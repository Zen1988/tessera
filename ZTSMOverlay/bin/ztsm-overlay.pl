#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Compare qw(compare);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use FindBin qw($Bin);

my $Root = '.';
my $Mode = 'check';

while ( my $Arg = shift @ARGV ) {
    if ( $Arg eq '--root' ) {
        $Root = shift @ARGV // die "--root needs a value\n";
        next;
    }
    if ( $Arg eq '--check' ) {
        $Mode = 'check';
        next;
    }
    if ( $Arg eq '--apply' ) {
        $Mode = 'apply';
        next;
    }
    die "Unknown option: $Arg\n";
}

$Root = abs_path($Root) // die "Cannot resolve root: $Root\n";

my $OverlayRoot = abs_path( File::Spec->catdir( $Bin, '..' ) )
    // die "Cannot resolve overlay root\n";
my $Manifest = File::Spec->catfile( $OverlayRoot, 'manifest.tsv' );

open my $ManifestFH, '<', $Manifest or die "Cannot open $Manifest: $!\n";

my $HadError = 0;
LINE:
while ( my $Line = <$ManifestFH> ) {
    chomp $Line;
    next LINE if $Line =~ m{\A\s*(?:#|\z)};

    my ( $Action, $Source, $Target ) = split /\t/, $Line;
    if ( !$Action || !$Source ) {
        warn "Invalid manifest line: $Line\n";
        $HadError = 1;
        next LINE;
    }

    if ( $Action eq 'copy' ) {
        my $SourcePath = File::Spec->catfile( $OverlayRoot, $Source );
        my $TargetPath = File::Spec->catfile( $Root,        $Target // '' );

        if ( !-f $SourcePath ) {
            warn "Missing overlay file: $Source\n";
            $HadError = 1;
            next LINE;
        }

        if ( $Mode eq 'check' ) {
            if ( !-f $TargetPath ) {
                print "copy needed: $Target\n";
            }
            elsif ( compare( $SourcePath, $TargetPath ) != 0 ) {
                print "copy differs: $Target\n";
            }
            next LINE;
        }

        make_path( dirname($TargetPath) );
        copy( $SourcePath, $TargetPath ) or die "Copy failed for $Target: $!\n";
        print "copied: $Target\n";
        next LINE;
    }

    if ( $Action eq 'patch' ) {
        my $PatchPath = File::Spec->catfile( $OverlayRoot, $Source );
        if ( !-f $PatchPath ) {
            warn "Missing patch: $Source\n";
            $HadError = 1;
            next LINE;
        }

        my @Command = $Mode eq 'check'
            ? ( 'git', '-C', $Root, 'apply', '--check', '--3way', $PatchPath )
            : ( 'git', '-C', $Root, 'apply', '--3way', $PatchPath );

        my $Exit = system @Command;
        if ($Exit) {
            warn "Patch failed: $Source\n";
            $HadError = 1;
            next LINE;
        }

        print $Mode eq 'check' ? "patch ok: $Source\n" : "patched: $Source\n";
        next LINE;
    }

    warn "Unknown action '$Action' in manifest\n";
    $HadError = 1;
}

close $ManifestFH;
exit $HadError ? 1 : 0;
