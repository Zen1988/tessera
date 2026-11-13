#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec ();
use File::Path qw(make_path);
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Encode ();
use MIME::Base64 qw(decode_base64);
BEGIN {
    my $Source=shift @ARGV;
    die "Installed application path required\n" if !$Source || !File::Spec->file_name_is_absolute($Source);
    unshift @INC,"$Source/Custom","$Source/Kernel/cpan-lib",$Source;
}
my ($Output)=@ARGV;
die "Absolute output path required\n" if !$Output || !File::Spec->file_name_is_absolute($Output);
# Export installed package metadata and exact OPMs for controlled reconciliation.
# No configuration, business data, credentials or native diagnostic is exported.
open STDOUT,'>',File::Spec->devnull() or die;
open STDERR,'>',File::Spec->devnull() or exit 1;
my $OK=eval {
    require Kernel::System::ObjectManager;
    local $Kernel::OM=Kernel::System::ObjectManager->new();
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    my $Registry=sub {
        die if !$DB->Prepare(SQL=>q{SELECT name, version FROM package_repository WHERE install_status = ? ORDER BY name, version},Bind=>[\(my $Status='installed')]);
        my (@Rows,%Names);
        while (my @R=$DB->FetchrowArray()) {
            die if @Rows>=1000 || !$R[0] || !$R[1] || $Names{$R[0]}++;
            push @Rows,[$R[0],$R[1]];
        }
        die if !@Rows;return \@Rows;
    };
    my $Rows=$Registry->();my @Packages;
    my ($Volume,$Directory)=File::Spec->splitpath($Output);
    my $Artifacts=File::Spec->catdir($Volume.$Directory,"packages");
    make_path($Artifacts);
    my $Package=$Kernel::OM->Get('Kernel::System::Package');
    for my $Row (@$Rows) {
        die if !$DB->Prepare(SQL=>q{SELECT content FROM package_repository WHERE name = ? AND version = ? AND install_status = ?},Bind=>[\$Row->[0],\$Row->[1],\(my $Status='installed')]);
        my @Contents;while(my @R=$DB->FetchrowArray()){push @Contents,$R[0]}
        die if @Contents!=1 || !$Contents[0];
        my $XML=$Contents[0];
        $XML=decode_base64($XML) if !$DB->GetDatabaseFunction('DirectBlob') && $XML =~ /\A[a-zA-Z0-9+\/\n]+={0,2}[\n]?\z/;
        my %Parsed=$Package->PackageParse(String=>$XML);die if !%Parsed;
        die if ($Parsed{Name}{Content} || '') ne $Row->[0] || ($Parsed{Version}{Content} || '') ne $Row->[1];
        my @Modules;
        for my $M (@{$Parsed{ModuleRequired} || []}) {
            die if ref $M ne 'HASH';
            push @Modules,{module=>$M->{Content},minimum=>defined $M->{Version}?"$M->{Version}":'0'};
        }
        my $Bytes = utf8::is_utf8($XML) ? Encode::encode('UTF-8',$XML) : $XML;
        my $Hash=sha256_hex($Bytes);
        open my $OPM,'>:raw',File::Spec->catfile($Artifacts,"$Hash.opm") or die;
        print {$OPM} $Bytes or die; close $OPM or die;
        push @Packages,{name=>$Row->[0],version=>$Row->[1],package_sha256=>sha256_hex($Bytes),modules=>\@Modules};
    }
    my $JSON=JSON::PP->new->canonical;
    die if $JSON->encode($Rows) ne $JSON->encode($Registry->());
    open my $FH,'>:raw',$Output or die;
    print {$FH} $JSON->utf8->encode({schema=>1,packages=>\@Packages}),"\n" or die;
    close $FH or die;1;
};
exit($OK?0:1);
