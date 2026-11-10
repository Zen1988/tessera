package Kernel::System::TESSERA::ReleaseUpgrade;
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Encode qw(encode_utf8);
use MIME::Base64 qw(decode_base64);
our @ObjectDependencies = ('Kernel::System::DB', 'Kernel::System::Package', 'Kernel::System::Main');
my $Key = 'TESSERA::ContainerRelease';
sub new { return bless {}, $_[0] }
sub _DB { return $Kernel::OM->Get('Kernel::System::DB') }
sub _Version {
    my ($Self) = @_;
    my $Name = 'TESSERA-Base';
    my $DB = $Self->_DB();
    die "Package registry unavailable.\n" if !$DB->Prepare(SQL => 'SELECT version FROM package_repository WHERE name = ? AND install_status = ?', Bind => [\$Name, \(my $Status = 'installed')]);
    my @Versions; while (my @R = $DB->FetchrowArray()) { push @Versions, $R[0] }
    die "Missing or ambiguous installed package.\n" if @Versions != 1 || $Versions[0] !~ /\A[0-9]+\.[0-9]+\.[0-9]+\z/;
    return $Versions[0];
}
sub _Read {
    my ($Self) = @_;
    my $DB = $Self->_DB();
    die "Release state unavailable.\n" if !$DB->Prepare(SQL => 'SELECT data_value FROM system_data WHERE data_key = ?', Bind => [\$Key]);
    my @Rows; while (my @R = $DB->FetchrowArray()) { push @Rows, $R[0] }
    die "Ambiguous release state.\n" if @Rows > 1;
    return $Rows[0];
}
sub _Write {
    my ($Self, $Before, $After) = @_;
    # Native system_data has a primary key on data_key. A durable CAS claim,
    # unlike node-local advisory locks, works across MariaDB/Galera endpoints.
    my $Handle = $Self->_DB()->Connect() or die "Release database unavailable.\n";
    my $Rows;
    if (defined $Before) {
        $Rows = $Handle->do('UPDATE system_data SET data_value = ?, change_time = current_timestamp, change_by = 1 WHERE data_key = ? AND data_value = ?', undef, $After, $Key, $Before);
    }
    else {
        $Rows = $Handle->do('INSERT INTO system_data (data_key, data_value, create_time, create_by, change_time, change_by) VALUES (?, ?, current_timestamp, 1, current_timestamp, 1)', undef, $Key, $After);
    }
    die "Release claim conflicted or is unavailable.\n" if !defined $Rows || $Rows != 1;
    return $After;
}
sub _Decode {
    my ($Self, $Raw) = @_;
    return if !defined $Raw;
    my $S = eval { JSON::PP->new->decode($Raw) };
    die "Invalid release state.\n" if ref $S ne 'HASH' || ($S->{phase} || '') !~ /\A(?:UPGRADING|CONFIGURING|READY)\z/;
    return $S;
}
sub _Encode { return JSON::PP->new->canonical->encode($_[1]) }
sub _InstalledHash {
    my ($Self, $Version) = @_;
    # Read the actual installed registry artifact, not RepositoryGet's long-lived
    # cache. Match the native package storage's DirectBlob/Base64 contract.
    my $DB=$Self->_DB();
    my $Name='TESSERA-Base';my $Status='installed';
    die "Installed package artifact unavailable.\n" if !$DB->Prepare(
        SQL=>'SELECT content FROM package_repository WHERE name = ? AND version = ? AND install_status = ?',Bind=>[\$Name,\$Version,\$Status]);
    my @Rows;while(my @Row=$DB->FetchrowArray()){push @Rows,$Row[0]}
    die "Installed package artifact unavailable.\n" if @Rows!=1 || !$Rows[0];
    my $Text=$Rows[0];
    $Text=decode_base64($Text) if !$DB->GetDatabaseFunction('DirectBlob') && $Text =~ /\A[a-zA-Z0-9+\/\n]+={0,2}[\n]?\z/;
    return sha256_hex(utf8::is_utf8($Text) ? encode_utf8($Text) : $Text);
}
sub Check {
    my ($Self, %P) = @_;
    my $State = $Self->_Decode($Self->_Read());
    die "Target release receipt is missing or incomplete.\n" if !$State || $State->{phase} ne 'READY';
    die "Target package version differs from image.\n" if $Self->_Version() ne $P{Version};
    die "Target package artifact differs from image.\n" if $Self->_InstalledHash($P{Version}) ne $P{Hash};
    die "Target release receipt differs from image.\n" if $State && (($State->{version} || '') ne $P{Version} || ($State->{hash} || '') ne $P{Hash});
    return 1;
}
sub Run {
    my ($Self, %P) = @_;
    die "Invalid intended release.\n" if ($P{Version} || '') !~ /\A[0-9]+\.[0-9]+\.[0-9]+\z/ || ($P{Hash} || '') !~ /\A[a-f0-9]{64}\z/
        || ref $P{Upgrade} ne 'CODE' || ref $P{Configure} ne 'CODE' || ref $P{FromVersions} ne 'ARRAY';
    my $Raw = $Self->_Read();
    my $State = $Self->_Decode($Raw);
    my $Current = $Self->_Version();
    if ($State && $State->{phase} eq 'READY') {
        die "Recorded target release does not match its registry.\n" if ($State->{version} || '') ne $Current
            || ($State->{hash} || '') ne $Self->_InstalledHash($Current);
    }
    if ($State && $State->{phase} ne 'READY') {
        # No automatic stale-lock takeover: native package metadata is updated
        # before its hooks finish. An uncertain native upgrade must be reviewed.
        die "An upgrade is active or incomplete; inspect the saved release state.\n"
            if !$P{ResumeConfig} || $State->{phase} ne 'CONFIGURING' || $State->{version} ne $P{Version} || $State->{hash} ne $P{Hash} || $Current ne $P{Version};
    }
    elsif ($Current eq $P{Version}) {
        if ($State) { $Self->Check(%P) }
        else { die "Target package artifact differs from image.\n" if $Self->_InstalledHash($Current) ne $P{Hash} }
        # Same release is a database no-op; regenerate this image's config if
        # needed under the same durable claim, never reinstall its package.
    }
    else {
        my %Allowed = map { $_ => 1 } @{$P{FromVersions}};
        die "Unsupported upgrade path or target is ahead of image.\n" if !$Allowed{$Current};
    }
    my $Claim = {phase => $Current eq $P{Version} ? 'CONFIGURING' : 'UPGRADING', version => $P{Version}, hash => $P{Hash}, from => $Current,
        owner => $Kernel::OM->Get('Kernel::System::Main')->GenerateRandomString(Length => 40)};
    my $Owned = $Self->_Write($Raw, $Self->_Encode($Claim));
    # Recheck after winning CAS; all failures retain the durable phase.
    die "Target changed during release claim.\n" if $Self->_Version() ne $Current;
    if ($Current ne $P{Version}) {
        die "Native package upgrade failed.\n" if !$P{Upgrade}->();
        die "Native package version verification failed.\n" if $Self->_Version() ne $P{Version};
        die "Native package hash verification failed.\n" if $Self->_InstalledHash($P{Version}) ne $P{Hash};
        $Claim->{phase} = 'CONFIGURING';
        $Owned = $Self->_Write($Owned, $Self->_Encode($Claim));
    }
    die "Target changed before configuration.\n" if $Self->_Version() ne $P{Version} || $Self->_InstalledHash($P{Version}) ne $P{Hash};
    die "Target configuration deployment failed.\n" if !$P{Configure}->();
    die "Target changed during configuration.\n" if $Self->_Version() ne $P{Version} || $Self->_InstalledHash($P{Version}) ne $P{Hash};
    $Claim->{phase} = 'READY';
    $Self->_Write($Owned, $Self->_Encode($Claim));
    $Self->Check(%P);
    return {Success => 1, Version => $P{Version}, Upgraded => $Current ne $P{Version} ? 1 : 0};
}
1;
