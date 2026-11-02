#!/usr/bin/env perl
use strict;
use warnings;
use File::Spec ();
use JSON::PP ();
BEGIN {
    my $Source=shift @ARGV;
    die "Installed application path required\n" if !$Source || !File::Spec->file_name_is_absolute($Source);
    unshift @INC,"$Source/Custom","$Source/Kernel/cpan-lib",$Source;
}
my ($Output)=@ARGV;
die "Absolute output path required\n" if !$Output || !File::Spec->file_name_is_absolute($Output);
# Only package dependency metadata is exported. No configuration, business data,
# package payload, credentials or native diagnostic is written to the output.
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
    my $Package=$Kernel::OM->Get('Kernel::System::Package');
    for my $Row (@$Rows) {
        my $XML=$Package->RepositoryGet(Name=>$Row->[0],Version=>$Row->[1]);die if !$XML;
        my %Parsed=$Package->PackageParse(String=>$XML);die if !%Parsed;
        die if ($Parsed{Name}{Content} || '') ne $Row->[0] || ($Parsed{Version}{Content} || '') ne $Row->[1];
        my @Modules;
        for my $M (@{$Parsed{ModuleRequired} || []}) {
            die if ref $M ne 'HASH';
            push @Modules,{module=>$M->{Content},minimum=>defined $M->{Version}?"$M->{Version}":'0'};
        }
        push @Packages,{name=>$Row->[0],version=>$Row->[1],modules=>\@Modules};
    }
    my $JSON=JSON::PP->new->canonical;
    die if $JSON->encode($Rows) ne $JSON->encode($Registry->());
    open my $FH,'>:raw',$Output or die;
    print {$FH} $JSON->utf8->encode({schema=>1,packages=>\@Packages}),"\n" or die;
    close $FH or die;1;
};
exit($OK?0:1);
