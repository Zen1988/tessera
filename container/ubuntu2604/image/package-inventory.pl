#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Encode ();
use MIME::Base64 qw(decode_base64);

sub InstalledArtifactHash {
    my ($DB,$Name,$Version)=@_;
    die "Package artifact unavailable for $Name.\n" if !$DB->Prepare(
        SQL=>q{SELECT content FROM package_repository WHERE name = ? AND version = ? AND install_status = ?},
        Bind=>[\$Name,\$Version,\(my $Status='installed')]);
    my @Rows;while (my @R=$DB->FetchrowArray()) {push @Rows,$R[0]}
    die "Package artifact unavailable or ambiguous for $Name.\n" if @Rows!=1 || !defined $Rows[0];
    my $XML=$Rows[0];
    $XML=decode_base64($XML) if !$DB->GetDatabaseFunction('DirectBlob') && $XML =~ /\A[a-zA-Z0-9+\/\n]+={0,2}[\n]?\z/;
    return sha256_hex(utf8::is_utf8($XML)?Encode::encode('UTF-8',$XML):$XML);
}

# Read-only guard. Native package installs/upgrades belong in quiesced maintenance.
sub CheckInventory {
    my ($Manifest, $DB, $Package) = @_;
    die "Invalid image package inventory; prepare a fresh toolkit.\n"
        if ref $Manifest ne 'HASH' || ($Manifest->{schema} || 0) != 1
        || ref $Manifest->{packages} ne 'ARRAY' || !@{$Manifest->{packages}};
    die "Package upgrade journal unavailable.\n" if !$DB->Prepare(SQL=>q{SELECT data_key FROM system_data WHERE data_key LIKE 'TESSERA::PackageUpgrade::%'});
    my @Journal=$DB->FetchrowArray();
    die "Incomplete package upgrade; inspect maintenance journal.\n" if @Journal;
    my %Expected;
    for my $P (@{$Manifest->{packages}}) {
        die "Invalid image package inventory; prepare a fresh toolkit.\n"
            if ref $P ne 'HASH' || ($P->{name} || '') !~ /\A[A-Za-z0-9_.-]+\z/
            || ($P->{version} || '') !~ /\A[0-9][A-Za-z0-9_.-]*\z/
            || ($P->{package_sha256} || '') !~ /\A[a-f0-9]{64}\z/ || $Expected{$P->{name}};
        $Expected{$P->{name}} = $P;
    }
    die "Package registry unavailable.\n" if !$DB->Prepare(
        SQL => q{SELECT name, version FROM package_repository WHERE install_status = ? ORDER BY name, version},
        Bind => [\(my $Status = 'installed')]);
    my (%Seen, @Rows);
    while (my @R = $DB->FetchrowArray()) { push @Rows, [@R]; }
    my @Errors;
    for my $R (@Rows) {
        my ($Name, $Version) = @$R;
        if (!defined $Name || $Name !~ /\A[A-Za-z0-9_.-]+\z/) {
            push @Errors, 'invalid target package name'; next;
        }
        if ($Seen{$Name}++) { push @Errors, "$Name: ambiguous installed records"; next; }
        my $P = $Expected{$Name};
        if (!$P) { push @Errors, "$Name: installed in target but absent from image"; next; }
        if (!defined $Version || $Version ne $P->{version}) {
            push @Errors, "$Name: target version differs; image requires $P->{version}"; next;
        }
        push @Errors, "$Name: target package artifact differs from image"
            if InstalledArtifactHash($DB,$Name,$Version) ne $P->{package_sha256};
    }
    push @Errors, "$_: missing from target database" for sort grep {!$Seen{$_}} keys %Expected;
    die "Image/database package mismatch:\n" . join("\n", sort @Errors)
        . "\nReconcile using matching native OPM installs/upgrades in controlled maintenance, then rebuild configuration. Do not edit version records.\n" if @Errors;
    return 1;
}

unless (caller) {
    require Kernel::System::ObjectManager;
    open my $FH, '<:raw', '/opt/tessera/dependencies/package-modules.json' or die "Image package inventory unavailable.\n";
    my $Manifest = JSON::PP->new->utf8->decode(do {local $/; <$FH>});
    close $FH;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    CheckInventory($Manifest, $Kernel::OM->Get('Kernel::System::DB'), $Kernel::OM->Get('Kernel::System::Package'));
    print "Image/database package inventory matches\n";
}
1;
