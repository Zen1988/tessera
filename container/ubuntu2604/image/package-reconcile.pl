#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP ();
use Digest::SHA qw(sha256_hex);
use Encode ();

sub ReconcilePackages {
    my ($Manifest, $DB, $Package, $Directory, $PlanOnly) = @_;
    die "Incomplete package upgrade journal; inspect before retry.\n" if !$DB->Prepare(SQL=>q{SELECT data_key FROM system_data WHERE data_key LIKE 'TESSERA::PackageUpgrade::%'});
    my @Journal=$DB->FetchrowArray();
    die "Incomplete package upgrade journal; inspect before retry.\n" if @Journal;
    $Package->_RepositoryCacheClear() if !$PlanOnly;
    my (%Wanted, %Parsed, %Strings, %Current);
    die "Invalid package manifest.\n" if ref $Manifest->{packages} ne 'ARRAY' || !@{$Manifest->{packages}};
    for my $P (@{$Manifest->{packages}}) {
        my ($Name,$Version,$Hash)=@{$P}{qw(name version package_sha256)};
        die "Invalid package identity.\n" if !defined $Name || $Name !~ /\A[A-Za-z0-9_.-]+\z/
            || !defined $Version || $Version !~ /\A[0-9]+(?:\.[0-9]+)*\z/
            || !defined $Hash || $Hash !~ /\A[a-f0-9]{64}\z/ || $Wanted{$Name};
        open my $FH,'<:raw',"$Directory/$Hash.opm" or die "Missing bundled OPM for $Name.\n";
        my $Bytes=do {local $/;<$FH>};close $FH;
        die "Bundled OPM hash mismatch for $Name.\n" if sha256_hex($Bytes) ne $Hash;
        my $String=Encode::decode('UTF-8',$Bytes,Encode::FB_CROAK());
        my %Structure=$Package->PackageParse(String=>$String);
        die "Bundled OPM identity mismatch for $Name.\n" if ($Structure{Name}{Content} || '') ne $Name || ($Structure{Version}{Content} || '') ne $Version;
        $Wanted{$Name}=$P; $Parsed{$Name}=\%Structure; $Strings{$Name}=$String;
    }
    die "Package registry unavailable.\n" if !$DB->Prepare(SQL=>q{SELECT name, version FROM package_repository WHERE install_status = ? ORDER BY name, version},Bind=>[\(my $Status='installed')]);
    while (my @R=$DB->FetchrowArray()) {
        die "Extra or ambiguous target package; reconciliation stopped.\n" if !$Wanted{$R[0]} || exists $Current{$R[0]};
        $Current{$R[0]}=$R[1];
    }
    # Validate the complete plan before any hook executes; never downgrade.
    for my $Name (keys %Current) {
        my ($Old,$New)=($Current{$Name},$Wanted{$Name}{version});
        die "Unsupported target version for $Name.\n" if $Old !~ /\A[0-9]+(?:\.[0-9]+)*\z/;
        my @A=split /\./,$Old; my @B=split /\./,$New;
        for my $I (0..(@A>@B?$#A:$#B)) {
            die "Refusing package downgrade for $Name.\n" if ($A[$I]||0)>($B[$I]||0);
            last if ($A[$I]||0)<($B[$I]||0);
        }
        if ($Old eq $New) {
            die "Same-version artifact mismatch for $Name.\n" if InstalledArtifactHash($DB,$Name,$Old) ne $Wanted{$Name}{package_sha256};
        }
    }
    my (%Visiting,%Visited,@Order);
    my $Visit; $Visit=sub {
        my ($Name)=@_;return if $Visited{$Name};
        die "Cyclic package dependency at $Name.\n" if $Visiting{$Name}++;
        for my $D (@{$Parsed{$Name}{PackageRequired} || []}) {
            die "Missing bundled dependency for $Name.\n" if !$Wanted{$D->{Content}};
            $Visit->($D->{Content});
        }
        $Visited{$Name}=1;push @Order,$Name;
    };
    $Visit->($_) for sort keys %Wanted;
    undef $Visit;
    if ($PlanOnly) {
        for my $Name (@Order) {
            my $Action=!exists $Current{$Name}?'install':$Current{$Name} eq $Wanted{$Name}{version}?'skip':'upgrade';
            print "package_plan=$Name,$Action,$Wanted{$Name}{version}\n";
        }
        return 1;
    }
    for my $Name (@Order) {
        next if exists $Current{$Name} && $Current{$Name} eq $Wanted{$Name}{version};
        # Durable claim is never cleared on failure. Even a hook failure after
        # registry publication must not be mistaken for a completed upgrade.
        my $Key='TESSERA::PackageUpgrade::'.$Name;
        my $Value=JSON::PP->new->canonical->encode({phase=>'UPGRADING',version=>$Wanted{$Name}{version},hash=>$Wanted{$Name}{package_sha256}});
        my $Handle=$DB->Connect() or die "Package journal unavailable.\n";
        my $Rows=$Handle->do('INSERT INTO system_data (data_key,data_value,create_time,create_by,change_time,change_by) VALUES (?,?,current_timestamp,1,current_timestamp,1)',undef,$Key,$Value);
        die "Package upgrade already claimed; inspect journal for $Name.\n" if !defined $Rows || $Rows!=1;
        print "Reconciling package $Name to $Wanted{$Name}{version}\n";
        die "Native package reconciliation failed for $Name.\n" if !$Package->PackageUpgrade(String=>$Strings{$Name});
        $Package->_RepositoryCacheClear();
        die "Native package artifact verification failed for $Name.\n"
            if InstalledArtifactHash($DB,$Name,$Wanted{$Name}{version}) ne $Wanted{$Name}{package_sha256};
        $Rows=$Handle->do('DELETE FROM system_data WHERE data_key = ? AND data_value = ?',undef,$Key,$Value);
        die "Package journal changed for $Name.\n" if !defined $Rows || $Rows!=1;
    }
    return 1;
}
1;
